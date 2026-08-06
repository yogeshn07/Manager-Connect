// pipeline-operations — Use case
// S3-BE-009: Pipeline Operations & Recovery API for Catalyst Insights.
//
// Provides the full set of manual pipeline control operations:
//
//   list_failed      — surface ai_error jobs for ops review
//   list_stalled     — surface validated-but-stuck jobs (> STALE_VALIDATED_MINUTES)
//   get_status       — full details for a specific raw insight record
//   retry_failed     — reset ai_error → validated and invoke enrich-insight (single)
//   bulk_retry       — same as retry_failed but for up to 20 raw_ids
//   trigger_recovery — on-demand analogue of CF-01: invoke enrich-insight for all
//                      currently stalled validated records
//
// Retry pattern:
//   ai_error records require a status reset (ai_error → validated) before
//   enrich-insight will accept them — enrich-insight guards on status='validated'.
//   stalled validated records need no reset; they are already in the correct
//   status for enrich-insight.
//
// Result<T,E> is used for the per-item retryOne() helper so that bulk_retry
// can accumulate typed per-item outcomes (retried / skipped / failed) without
// try/catch wrappers inside the loop. Top-level handlers throw on hard errors.
//
// Audit strategy: structured pipeline logger (not admin_audit_log).
// This function uses service_role auth — there is no human admin_id to reference
// in admin_audit_log.admin_id (NOT NULL REFERENCES profiles.id).
//
// ─── Env deps (read directly — no loadConfig() which requires OPENAI_API_KEY) ─
//   SUPABASE_URL                — base URL for enrich-insight HTTP invocation
//   SUPABASE_SERVICE_ROLE_KEY   — createAdminClient + enrich-insight auth
//
// ─── Imported constants ────────────────────────────────────────────────────────
//   STALE_VALIDATED_MINUTES — canonical stall threshold (constants.ts)
//   HTTP_TIMEOUT_MS         — HTTP timeout for enrich-insight calls (constants.ts)

import { createAdminClient } from '../_shared/supabase-client.ts';
import { PipelineError, isPipelineError } from '../_shared/insights/errors.ts';
import { AppError } from '../_shared/errors.ts';
import { logger } from '../_shared/insights/logger.ts';
import { ok, err, type Result } from '../_shared/insights/result.ts';
import { fetchWithTimeout } from '../_shared/insights/http.ts';
import { STALE_VALIDATED_MINUTES, HTTP_TIMEOUT_MS } from '../_shared/insights/constants.ts';

const FN = 'pipeline_operations';

// ─── Configuration ─────────────────────────────────────────────────────────────

const DEFAULT_LIST_LIMIT = 50;
const MAX_LIST_LIMIT     = 100;
const MAX_BULK_RETRY     = 20;

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ─── Status constants ──────────────────────────────────────────────────────────

const STATUS_AI_ERROR  = 'ai_error'   as const;
const STATUS_VALIDATED = 'validated'  as const;

// ─── Result types ──────────────────────────────────────────────────────────────

export interface PipelineJob {
  id:         string;
  raw_url:    string;
  status:     string;
  source_id:  string;
  created_at: string;
  updated_at: string;
}

export interface ListJobsResult {
  jobs:       PipelineJob[];
  count:      number;
  checked_at: string;
}

export interface JobStatusResult {
  raw_id:     string;
  job:        Record<string, unknown> | null;
  found:      boolean;
  checked_at: string;
}

export interface RetryResult {
  raw_id:     string;
  enqueued:   boolean;
  retried_at: string;
}

interface BulkItemResult {
  raw_id:   string;
  outcome:  'retried' | 'skipped' | 'failed';
  error?:   string;
}

export interface BulkRetryResult {
  total_requested: number;
  retried_count:   number;
  skipped_count:   number;
  failed_count:    number;
  results:         BulkItemResult[];
  retried_at:      string;
}

export interface RecoveryResult {
  total_stalled:     number;
  triggered_count:   number;
  failed_count:      number;
  raw_ids_triggered: string[];
  raw_ids_failed:    string[];
  stale_before:      string;
  triggered_at:      string;
}

// ─── Internal: typed per-item retry outcome ────────────────────────────────────

interface RetryOutcome {
  raw_id:         string;
  status_reset:   boolean;
  enrich_invoked: boolean;
}

// ─── Input validators ──────────────────────────────────────────────────────────

function parseLimit(body: Record<string, unknown>): number {
  const raw = typeof body.limit === 'number' ? body.limit : DEFAULT_LIST_LIMIT;
  return Math.min(Math.max(1, Math.floor(raw)), MAX_LIST_LIMIT);
}

function parseRawId(body: Record<string, unknown>): string {
  const id = body.raw_id;
  if (typeof id !== 'string' || !id.trim() || !UUID_REGEX.test(id.trim())) {
    throw new AppError('VALIDATION_ERROR', 'raw_id must be a valid UUID');
  }
  return id.trim();
}

function parseRawIds(body: Record<string, unknown>): string[] {
  const ids = body.raw_ids;
  if (!Array.isArray(ids) || ids.length === 0) {
    throw new AppError('VALIDATION_ERROR', 'raw_ids must be a non-empty array');
  }
  if (ids.length > MAX_BULK_RETRY) {
    throw new AppError('VALIDATION_ERROR', `raw_ids must not exceed ${MAX_BULK_RETRY} items`);
  }
  const validated: string[] = [];
  for (const id of ids) {
    if (typeof id !== 'string' || !UUID_REGEX.test(id.trim())) {
      throw new AppError('VALIDATION_ERROR', `Invalid UUID in raw_ids: ${String(id)}`);
    }
    validated.push(id.trim());
  }
  return validated;
}

// ─── Env: enrich-insight endpoint ─────────────────────────────────────────────
//
// Reads only the two vars needed for HTTP invocation.
// Deliberately avoids loadConfig() which requires OPENAI_API_KEY — pipeline-operations
// never calls OpenAI directly, and failing at startup because that env var is absent
// would make the ops API unavailable exactly when it is most needed (incident response).

function getEnrichEndpoint(): { enrichUrl: string; serviceRoleKey: string } {
  const supabaseUrl    = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) {
    throw new PipelineError(
      'CONFIG_MISSING',
      'SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set',
    );
  }
  return {
    enrichUrl:      `${supabaseUrl}/functions/v1/enrich-insight`,
    serviceRoleKey,
  };
}

// ─── HTTP: invoke enrich-insight for one raw_id ───────────────────────────────

async function invokeEnrichInsight(
  enrichUrl:      string,
  serviceRoleKey: string,
  rawId:          string,
): Promise<{ ok: boolean; error?: string }> {
  try {
    const response = await fetchWithTimeout(
      enrichUrl,
      {
        method:  'POST',
        headers: {
          'Authorization': `Bearer ${serviceRoleKey}`,
          'Content-Type':  'application/json',
        },
        body: JSON.stringify({ raw_id: rawId }),
      },
      HTTP_TIMEOUT_MS,
    );

    if (!response.ok) {
      const text = await response.text().catch(() => '<unreadable>');
      return { ok: false, error: `HTTP ${response.status}: ${text.slice(0, 200)}` };
    }

    return { ok: true };
  } catch (e) {
    const msg = isPipelineError(e) ? `${e.code}: ${e.message}` : String(e);
    return { ok: false, error: msg };
  }
}

// ─── Core: reset ai_error → validated, then invoke enrich-insight ─────────────
//
// Returns Result<RetryOutcome, PipelineError>:
//   ok()  — status was reset and enrich-insight accepted the invocation
//   err() — two distinct failure modes, distinguished by PipelineError.code:
//     VALIDATION_FAILED — record is not in ai_error state (ineligible, not an error)
//     DB_ERROR          — UPDATE failed (hard failure)
//     FETCH_FAILED      — enrich-insight HTTP call failed after a successful reset
//
// Using Result<T,E> here (rather than throwing) lets bulk_retry aggregate per-item
// outcomes without try/catch wrapping each iteration.
//
// Optimistic lock: .eq('status', STATUS_AI_ERROR) in the UPDATE means a concurrent
// reset on the same row produces 0 RETURNING rows — detected as VALIDATION_FAILED.

async function retryOne(
  adminClient:    ReturnType<typeof createAdminClient>,
  enrichUrl:      string,
  serviceRoleKey: string,
  rawId:          string,
): Promise<Result<RetryOutcome, PipelineError>> {
  const { data: reset, error: resetError } = await adminClient
    .from('insights_raw')
    .update({ status: STATUS_VALIDATED })
    .eq('id', rawId)
    .eq('status', STATUS_AI_ERROR)   // optimistic lock: only transitions from ai_error
    .select('id');

  if (resetError) {
    return err(new PipelineError('DB_ERROR', `Status reset failed for ${rawId}: ${resetError.message}`));
  }
  if (!reset || reset.length === 0) {
    // 0 rows returned — record exists but is not in ai_error state (or does not exist)
    return err(new PipelineError('VALIDATION_FAILED', `${rawId} is not in ai_error state`));
  }

  const invocation = await invokeEnrichInsight(enrichUrl, serviceRoleKey, rawId);
  if (!invocation.ok) {
    // Status was successfully reset to 'validated' but invocation failed.
    // The record is now in 'validated' and will be picked up by CF-01 within
    // STALE_VALIDATED_MINUTES — no compensating rollback needed.
    return err(new PipelineError(
      'FETCH_FAILED',
      `enrich-insight invocation failed for ${rawId}: ${invocation.error}`,
      true,   // retryable
    ));
  }

  return ok({ raw_id: rawId, status_reset: true, enrich_invoked: true });
}

// ─── stall threshold ──────────────────────────────────────────────────────────

function stalledBefore(): string {
  return new Date(Date.now() - STALE_VALIDATED_MINUTES * 60 * 1_000).toISOString();
}

// ─── Handlers ─────────────────────────────────────────────────────────────────

export async function handleListFailed(body: unknown): Promise<ListJobsResult> {
  const b = body as Record<string, unknown>;
  const limit = parseLimit(b);
  const adminClient = createAdminClient();
  const checkedAt = new Date().toISOString();

  const { data, error } = await adminClient
    .from('insights_raw')
    .select('id, raw_url, status, source_id, created_at, updated_at')
    .eq('status', STATUS_AI_ERROR)
    .order('updated_at', { ascending: false })
    .limit(limit);

  if (error) throw new PipelineError('DB_ERROR', `Failed to list failed jobs: ${error.message}`);

  const jobs = (data ?? []) as PipelineJob[];
  logger.info('Ops: list_failed', { fn: FN, count: jobs.length, limit });
  return { jobs, count: jobs.length, checked_at: checkedAt };
}

export async function handleListStalled(body: unknown): Promise<ListJobsResult> {
  const b = body as Record<string, unknown>;
  const limit = parseLimit(b);
  const adminClient = createAdminClient();
  const checkedAt = new Date().toISOString();
  const staleThreshold = stalledBefore();

  const { data, error } = await adminClient
    .from('insights_raw')
    .select('id, raw_url, status, source_id, created_at, updated_at')
    .eq('status', STATUS_VALIDATED)
    .lt('updated_at', staleThreshold)
    .order('updated_at', { ascending: true })   // oldest stall surfaces first
    .limit(limit);

  if (error) throw new PipelineError('DB_ERROR', `Failed to list stalled jobs: ${error.message}`);

  const jobs = (data ?? []) as PipelineJob[];
  logger.info('Ops: list_stalled', { fn: FN, count: jobs.length, limit, stale_before: staleThreshold });
  return { jobs, count: jobs.length, checked_at: checkedAt };
}

// Returns full insights_raw row (all columns) for the given raw_id.
// Returns { found: false, job: null } instead of throwing when the record does not exist.
export async function handleGetStatus(body: unknown): Promise<JobStatusResult> {
  const b = body as Record<string, unknown>;
  const rawId = parseRawId(b);
  const adminClient = createAdminClient();
  const checkedAt = new Date().toISOString();

  const { data, error } = await adminClient
    .from('insights_raw')
    .select('*')
    .eq('id', rawId)
    .single();

  // PGRST116 = PostgREST "no rows returned" — treat as found:false, not a server error
  if (error && error.code !== 'PGRST116') {
    throw new PipelineError('DB_ERROR', `Failed to fetch job status: ${error.message}`);
  }

  logger.info('Ops: get_status', { fn: FN, raw_id: rawId, found: !!data });
  return {
    raw_id:     rawId,
    job:        data as Record<string, unknown> | null,
    found:      !!data,
    checked_at: checkedAt,
  };
}

export async function handleRetryFailed(body: unknown): Promise<RetryResult> {
  const b = body as Record<string, unknown>;
  const rawId = parseRawId(b);
  const adminClient = createAdminClient();
  const retriedAt = new Date().toISOString();

  const { enrichUrl, serviceRoleKey } = getEnrichEndpoint();
  const result = await retryOne(adminClient, enrichUrl, serviceRoleKey, rawId);

  if (!result.ok) {
    if (result.error.code === 'VALIDATION_FAILED') {
      // Not in ai_error state — 409 CONFLICT so the caller knows it was an eligibility issue
      throw new AppError('CONFLICT', result.error.message);
    }
    // DB_ERROR or FETCH_FAILED — hard pipeline failure
    throw result.error;
  }

  logger.info('Ops: retry_failed', { fn: FN, raw_id: rawId, outcome: 'retried', retried_at: retriedAt });
  return { raw_id: rawId, enqueued: true, retried_at: retriedAt };
}

// Retries up to MAX_BULK_RETRY ai_error jobs.
// Processes sequentially — avoids overwhelming enrich-insight with concurrent cold starts
// and matches the sequential pattern used by recover-stalled-insights.
// Per-item outcomes are typed (retried / skipped / failed); the overall 200 response
// always returns even when some items fail or are skipped.
export async function handleBulkRetry(body: unknown): Promise<BulkRetryResult> {
  const b = body as Record<string, unknown>;
  const rawIds = parseRawIds(b);
  const adminClient = createAdminClient();
  const retriedAt = new Date().toISOString();

  const { enrichUrl, serviceRoleKey } = getEnrichEndpoint();
  const results: BulkItemResult[] = [];

  for (const rawId of rawIds) {
    const result = await retryOne(adminClient, enrichUrl, serviceRoleKey, rawId);

    if (result.ok) {
      results.push({ raw_id: rawId, outcome: 'retried' });
      logger.info('Ops: bulk_retry item retried', { fn: FN, raw_id: rawId });
    } else if (result.error.code === 'VALIDATION_FAILED') {
      // Not in ai_error — ineligible, not an error condition in a bulk context
      results.push({ raw_id: rawId, outcome: 'skipped', error: result.error.message });
      logger.info('Ops: bulk_retry item skipped', { fn: FN, raw_id: rawId, reason: result.error.message });
    } else {
      // DB_ERROR or FETCH_FAILED — record it and continue with the rest of the batch
      results.push({ raw_id: rawId, outcome: 'failed', error: result.error.message });
      logger.warn('Ops: bulk_retry item failed', { fn: FN, raw_id: rawId, error: result.error.message });
    }
  }

  const retriedCount = results.filter((r) => r.outcome === 'retried').length;
  const skippedCount = results.filter((r) => r.outcome === 'skipped').length;
  const failedCount  = results.filter((r) => r.outcome === 'failed').length;

  logger.info('Ops: bulk_retry complete', {
    fn:              FN,
    total_requested: rawIds.length,
    retried_count:   retriedCount,
    skipped_count:   skippedCount,
    failed_count:    failedCount,
  });

  return {
    total_requested: rawIds.length,
    retried_count:   retriedCount,
    skipped_count:   skippedCount,
    failed_count:    failedCount,
    results,
    retried_at:      retriedAt,
  };
}

// On-demand analogue of CF-01 (recover-stalled-insights).
// Finds ALL currently stalled validated records (no limit) and invokes
// enrich-insight for each. No status reset needed — stalled records are already
// in 'validated' state, which enrich-insight accepts directly.
// Use when CF-01 has fallen behind or an immediate sweep is required.
export async function handleTriggerRecovery(): Promise<RecoveryResult> {
  const adminClient = createAdminClient();
  const triggeredAt = new Date().toISOString();
  const staleThreshold = stalledBefore();

  const { data: stalled, error: fetchError } = await adminClient
    .from('insights_raw')
    .select('id')
    .eq('status', STATUS_VALIDATED)
    .lt('updated_at', staleThreshold)
    .order('updated_at', { ascending: true });   // oldest first for predictable ordering

  if (fetchError) {
    throw new PipelineError('DB_ERROR', `Failed to query stalled jobs: ${fetchError.message}`);
  }

  const stalledIds = ((stalled ?? []) as Array<{ id: string }>).map((r) => r.id);

  if (stalledIds.length === 0) {
    logger.info('Ops: trigger_recovery — no stalled jobs found', { fn: FN, stale_before: staleThreshold });
    return {
      total_stalled:     0,
      triggered_count:   0,
      failed_count:      0,
      raw_ids_triggered: [],
      raw_ids_failed:    [],
      stale_before:      staleThreshold,
      triggered_at:      triggeredAt,
    };
  }

  const { enrichUrl, serviceRoleKey } = getEnrichEndpoint();
  const rawIdsTriggered: string[] = [];
  const rawIdsFailed:    string[] = [];

  for (const rawId of stalledIds) {
    const invocation = await invokeEnrichInsight(enrichUrl, serviceRoleKey, rawId);
    if (invocation.ok) {
      rawIdsTriggered.push(rawId);
      logger.info('Ops: recovery invocation accepted', { fn: FN, raw_id: rawId });
    } else {
      rawIdsFailed.push(rawId);
      logger.warn('Ops: recovery invocation failed', {
        fn:     FN,
        raw_id: rawId,
        error:  invocation.error,
      });
    }
  }

  logger.info('Ops: trigger_recovery complete', {
    fn:              FN,
    total_stalled:   stalledIds.length,
    triggered_count: rawIdsTriggered.length,
    failed_count:    rawIdsFailed.length,
    stale_before:    staleThreshold,
  });

  return {
    total_stalled:     stalledIds.length,
    triggered_count:   rawIdsTriggered.length,
    failed_count:      rawIdsFailed.length,
    raw_ids_triggered: rawIdsTriggered,
    raw_ids_failed:    rawIdsFailed,
    stale_before:      staleThreshold,
    triggered_at:      triggeredAt,
  };
}
