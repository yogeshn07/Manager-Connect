// validate-insight — Use case
// Implements the Validate stage of the Catalyst Insights content pipeline.
//
// Scope-locked per S2-BE-003:
//   ✅ Pending record selection (fetches the specific raw record by raw_id)
//   ✅ Source validation (active check)
//   ✅ Approved domain verification (urlMatchesDomain — handles sub-path constraints)
//   ✅ URL normalization consistency (fingerprint re-check for race-condition duplicates)
//   ✅ Duplicate re-check (any OTHER record with same url_fingerprint)
//   ✅ Raw status transitions (pending → validated | duplicate | rejected)
//   ✅ Idempotency guard (conditional UPDATE WHERE status='pending')
//   ✅ Structured logging + Result<T,E> pattern
//
//   ❌ Webpage fetch / content download
//   ❌ Open Graph metadata extraction
//   ❌ AI enrichment
//   ❌ catalyst_insights modification
//   ❌ Scheduling / invoking enrich_insight
//
// NOTE: Once validated, enrich_insight fire-and-forget will be wired here in
// a later task. recover_stalled_insights (S2-BE-004) recovers records that
// reach 'validated' but whose enrich_insight call was never received.

import type { SupabaseClient } from '../_shared/insights/database.ts';
import type {
  ValidateInsightPayload,
  ValidateInsightResult,
  RawStatus,
} from '../_shared/insights/types.ts';
import { PipelineError } from '../_shared/insights/errors.ts';
import { logger } from '../_shared/insights/logger.ts';
import { ok, err, type Result } from '../_shared/insights/result.ts';
import { urlMatchesDomain } from '../_shared/insights/http.ts';

const FN = 'validate_insight';

// ─── Request validation ───────────────────────────────────────────────────────

function validatePayload(body: unknown): asserts body is ValidateInsightPayload {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new PipelineError('VALIDATION_FAILED', 'Request body must be a JSON object');
  }
  const b = body as Record<string, unknown>;
  if (typeof b.raw_id !== 'string' || !b.raw_id.trim()) {
    throw new PipelineError('VALIDATION_FAILED', 'raw_id is required');
  }
}

// ─── DB helpers ───────────────────────────────────────────────────────────────

interface RawRecord {
  id: string;
  source_id: string;
  raw_url: string;
  url_fingerprint: string;
  status: string;
}

async function fetchRawRecord(
  db: SupabaseClient,
  rawId: string,
): Promise<RawRecord> {
  const { data, error } = await db
    .from('insights_raw')
    .select('id, source_id, raw_url, url_fingerprint, status')
    .eq('id', rawId)
    .single();

  if (error || !data) {
    throw new PipelineError('DB_ERROR', `insights_raw record not found: ${rawId}`);
  }
  return data as RawRecord;
}

interface SourceRecord {
  name: string;
  approved_domain: string;
  is_active: boolean;
}

async function fetchSource(
  db: SupabaseClient,
  sourceId: string,
): Promise<Result<SourceRecord, PipelineError>> {
  const { data, error } = await db
    .from('insights_sources')
    .select('name, approved_domain, is_active')
    .eq('id', sourceId)
    .single();

  if (error || !data) {
    return err(new PipelineError('SOURCE_NOT_FOUND', `Source not found: ${sourceId}`));
  }
  return ok(data as SourceRecord);
}

// Checks if any OTHER record (not the current one) already has the same fingerprint.
// This catches the race condition where collect_insight was invoked concurrently
// for the same URL before the first fingerprint was committed.
async function hasDuplicateFingerprint(
  db: SupabaseClient,
  urlFingerprint: string,
  currentId: string,
): Promise<boolean> {
  const { data } = await db
    .from('insights_raw')
    .select('id')
    .eq('url_fingerprint', urlFingerprint)
    .neq('id', currentId)
    .maybeSingle();

  return data !== null;
}

// Conditional status transition: only updates if record is still 'pending'.
// Returns true if the transition happened, false if another invocation already
// handled it (race condition — idempotent).
async function transitionStatus(
  db: SupabaseClient,
  rawId: string,
  newStatus: RawStatus,
): Promise<boolean> {
  const { data } = await db
    .from('insights_raw')
    .update({ status: newStatus })
    .eq('id', rawId)
    .eq('status', 'pending') // guard: only update if still pending
    .select('id');

  return Array.isArray(data) && (data as unknown[]).length > 0;
}

// ─── Rejection helper ─────────────────────────────────────────────────────────

async function reject(
  db: SupabaseClient,
  rawId: string,
  reason: string,
  logCtx: Record<string, unknown>,
): Promise<ValidateInsightResult> {
  logger.warn(`Rejecting: ${reason}`, { fn: FN, raw_id: rawId, ...logCtx });
  await transitionStatus(db, rawId, 'rejected');
  return { raw_id: rawId, status: 'rejected', message: reason };
}

// ─── Use case entry point ─────────────────────────────────────────────────────

export async function handleValidateInsight(
  body: unknown,
  db: SupabaseClient,
): Promise<ValidateInsightResult> {

  // 1. Validate request
  validatePayload(body);
  const { raw_id: rawId } = body;

  logger.info('Validating insight', { fn: FN, raw_id: rawId });

  // 2. Fetch the insights_raw record
  const raw = await fetchRawRecord(db, rawId);

  // 3. Idempotency: if not pending, return current state without reprocessing
  if (raw.status !== 'pending') {
    logger.info('Record not pending — skipping (idempotent)', {
      fn: FN,
      raw_id: rawId,
      current_status: raw.status,
    });
    return {
      raw_id: rawId,
      status: raw.status as RawStatus,
      message: `Record is already in state '${raw.status}'`,
    };
  }

  // 4. Source existence check
  const sourceResult = await fetchSource(db, raw.source_id);
  if (!sourceResult.ok) {
    return reject(db, rawId, `Source not found: ${raw.source_id}`, {
      source_id: raw.source_id,
      error_code: sourceResult.error.code,
    });
  }
  const source = sourceResult.value;

  // 5. Source active check
  if (!source.is_active) {
    return reject(db, rawId, `Source is inactive: ${source.name}`, {
      source_name: source.name,
    });
  }

  // 6. Approved domain verification (handles sub-path constraints for WEF, EC)
  //    e.g. approved_domain='weforum.org/agenda/energy' must match URL path prefix
  if (!urlMatchesDomain(raw.raw_url, source.approved_domain)) {
    return reject(db, rawId, `URL does not match approved domain '${source.approved_domain}'`, {
      url: raw.raw_url,
      approved_domain: source.approved_domain,
      source_name: source.name,
    });
  }

  // 7. Duplicate re-check — detects race conditions where the same URL was
  //    submitted concurrently before the first fingerprint was committed
  const isDuplicate = await hasDuplicateFingerprint(
    db,
    raw.url_fingerprint,
    rawId,
  );
  if (isDuplicate) {
    logger.info('Duplicate fingerprint detected — marking as duplicate', {
      fn: FN,
      raw_id: rawId,
      url_fingerprint: raw.url_fingerprint,
    });
    await transitionStatus(db, rawId, 'duplicate');
    return {
      raw_id: rawId,
      status: 'duplicate',
      message: 'URL fingerprint already exists in the Catalyst Insights pipeline',
    };
  }

  // 8. All checks passed — transition to validated
  const transitioned = await transitionStatus(db, rawId, 'validated');
  if (!transitioned) {
    // A concurrent invocation already updated this record; return validated state
    logger.info('Concurrent transition detected — record already handled', {
      fn: FN,
      raw_id: rawId,
    });
    return {
      raw_id: rawId,
      status: 'validated',
      message: 'Insight validated (concurrent invocation handled it first)',
    };
  }

  logger.info('Insight validated successfully', {
    fn: FN,
    raw_id: rawId,
    source: source.name,
    approved_domain: source.approved_domain,
  });

  // NOTE: enrich_insight fire-and-forget will be added here in a later task.
  // Until then, recover_stalled_insights (S2-BE-004) recovers records stuck
  // in 'validated' state via the CF-01 recovery cron (every 30 min).

  return {
    raw_id: rawId,
    status: 'validated',
    message: 'Insight validated and queued for AI enrichment',
  };
}
