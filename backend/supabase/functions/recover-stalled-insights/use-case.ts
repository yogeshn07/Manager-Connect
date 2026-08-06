// recover-stalled-insights — Use case
// CF-01: Recovery mechanism for the Catalyst Insights pipeline.
//
// Scope-locked per S2-BE-004:
//   ✅ Query insights_raw WHERE status='validated' AND updated_at < NOW()-15min
//   ✅ Invoke enrich_insight once per qualifying raw_id
//   ✅ Continue processing when one invocation fails (no early exit)
//   ✅ Collect recovery statistics (total / recovered / failed)
//   ✅ Structured WARN logging when recoveries occur
//   ✅ Idempotent — stalled records are in 'validated'; once enrich_insight
//      processes them they advance state, so re-running finds nothing
//
//   ❌ Does NOT modify insights_raw directly
//   ❌ Does NOT implement AI enrichment logic
//   ❌ Does NOT implement OG fetching
//   ❌ Does NOT touch catalyst_insights
//   ❌ Does NOT modify collect_insight or validate_insight

import type { SupabaseClient } from '../_shared/insights/database.ts';
import type { InsightsPipelineConfig } from '../_shared/insights/config.ts';
import { PipelineError, isPipelineError } from '../_shared/insights/errors.ts';
import { STALE_VALIDATED_MINUTES, HTTP_TIMEOUT_MS } from '../_shared/insights/constants.ts';
import { logger } from '../_shared/insights/logger.ts';
import { fetchWithTimeout } from '../_shared/insights/http.ts';

const FN = 'recover_stalled_insights';

// ─── Result type ──────────────────────────────────────────────────────────────

export interface RecoveryResult {
  total_stalled:     number;    // qualifying 'validated' records found
  recovered_count:   number;    // enrich_insight invocations that returned 2xx
  failed_count:      number;    // enrich_insight invocations that failed
  raw_ids_recovered: string[];  // raw_ids where invocation succeeded
  raw_ids_failed:    string[];  // raw_ids where invocation failed (for alerting)
  stale_before:      string;    // ISO cutoff timestamp used in the DB query
}

// ─── DB: fetch stalled validated records ─────────────────────────────────────

async function fetchStalledInsights(
  db: SupabaseClient,
  staleBeforeISO: string,
): Promise<string[]> {
  const { data, error } = await db
    .from('insights_raw')
    .select('id')
    .eq('status', 'validated')
    .lt('updated_at', staleBeforeISO)
    .order('updated_at', { ascending: true }); // oldest first — prioritize most-delayed

  if (error) {
    throw new PipelineError(
      'DB_ERROR',
      `Failed to query stalled insights: ${error.message}`,
    );
  }

  return ((data ?? []) as Array<{ id: string }>).map((row) => row.id);
}

// ─── HTTP: invoke enrich_insight for one raw_id ────────────────────────────
//
// Uses HTTP_TIMEOUT_MS (10s) — enough to confirm the Edge Function accepted
// the request, without blocking for the full AI enrichment duration.
// Errors are captured and returned rather than thrown so the caller can
// continue processing remaining records.

async function invokeEnrichInsight(
  config: InsightsPipelineConfig,
  rawId: string,
): Promise<{ ok: boolean; error?: string }> {
  const url = `${config.supabaseUrl}/functions/v1/enrich-insight`;

  try {
    const response = await fetchWithTimeout(
      url,
      {
        method:  'POST',
        headers: {
          'Authorization': `Bearer ${config.supabaseServiceRoleKey}`,
          'Content-Type':  'application/json',
        },
        body: JSON.stringify({ raw_id: rawId }),
      },
      HTTP_TIMEOUT_MS,
    );

    if (!response.ok) {
      // Read a short excerpt of the body for diagnostics without blocking on large bodies
      const text = await response.text().catch(() => '<unreadable>');
      return { ok: false, error: `HTTP ${response.status}: ${text.slice(0, 200)}` };
    }

    return { ok: true };
  } catch (e) {
    // PipelineError (timeout/fetch failure) or any unexpected error
    const msg = isPipelineError(e) ? `${e.code}: ${e.message}` : String(e);
    return { ok: false, error: msg };
  }
}

// ─── Use case entry point ─────────────────────────────────────────────────────

export async function handleRecoverStalledInsights(
  db: SupabaseClient,
  config: InsightsPipelineConfig,
): Promise<RecoveryResult> {

  // Compute cutoff timestamp on the JS side so PostgREST's .lt() can use it.
  // Records with updated_at strictly before this timestamp qualify as stalled.
  const staleBeforeISO = new Date(
    Date.now() - STALE_VALIDATED_MINUTES * 60 * 1_000,
  ).toISOString();

  logger.info('CF-01 scanning for stalled insights', {
    fn:                FN,
    threshold_minutes: STALE_VALIDATED_MINUTES,
    stale_before:      staleBeforeISO,
  });

  // fetchStalledInsights throws PipelineError(DB_ERROR) on DB failure;
  // this propagates up to index.ts and returns 500.
  const stalledIds = await fetchStalledInsights(db, staleBeforeISO);

  if (stalledIds.length === 0) {
    return {
      total_stalled:     0,
      recovered_count:   0,
      failed_count:      0,
      raw_ids_recovered: [],
      raw_ids_failed:    [],
      stale_before:      staleBeforeISO,
    };
  }

  logger.warn('CF-01 stalled insights detected — initiating recovery', {
    fn:           FN,
    total_stalled: stalledIds.length,
    stale_before:  staleBeforeISO,
    raw_ids:       stalledIds,
  });

  const rawIdsRecovered: string[] = [];
  const rawIdsFailed:    string[] = [];

  // Process sequentially. Failure of one invocation never prevents the rest.
  // Idempotency note: enrich_insight will re-check the record status at runtime;
  // if the record was already advanced by a concurrent call, it will no-op.
  for (const rawId of stalledIds) {
    logger.info('CF-01 invoking enrich_insight', { fn: FN, raw_id: rawId });

    const invocation = await invokeEnrichInsight(config, rawId);

    if (invocation.ok) {
      rawIdsRecovered.push(rawId);
      logger.info('CF-01 recovery invocation accepted', { fn: FN, raw_id: rawId });
    } else {
      rawIdsFailed.push(rawId);
      logger.error('CF-01 recovery invocation failed', {
        fn:     FN,
        raw_id: rawId,
        error:  invocation.error,
      });
      // Continue to next record — non-blocking, always.
    }
  }

  return {
    total_stalled:     stalledIds.length,
    recovered_count:   rawIdsRecovered.length,
    failed_count:      rawIdsFailed.length,
    raw_ids_recovered: rawIdsRecovered,
    raw_ids_failed:    rawIdsFailed,
    stale_before:      staleBeforeISO,
  };
}
