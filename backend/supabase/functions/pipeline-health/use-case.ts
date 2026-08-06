// pipeline-health — Use case
// S3-BE-008: Pipeline Health & Monitoring for the Catalyst Insights pipeline.
//
// Responsibilities:
//   ✅ Raw queue counts — all 10 status values (pending → archived, ai_error)
//   ✅ Catalyst insight counts — all 4 status values (review, scheduled, active, archived)
//   ✅ Failed enrichment count  — insights_raw.status = 'ai_error'
//   ✅ Stalled validation count — insights_raw.status='validated'
//          AND updated_at < now() - STALE_VALIDATED_MINUTES
//          (reuses constant from constants.ts — consistent with recover-stalled-insights)
//   ✅ Scheduled publication count — catalyst_insights.status = 'scheduled'
//   ✅ Archived insight count      — catalyst_insights.status = 'archived'
//   ✅ 24h ingestion throughput    — insights_raw.created_at >= now() - 24h
//   ✅ Processing latency (time-to-publish) — avg(published_at - created_at) for
//          the 50 most recently published active catalyst_insights
//   ✅ All queries run in parallel via Promise.all — single wall-clock round trip
//   ✅ Structured PipelineHealthResult response with typed sub-objects
//
//   ❌ Does NOT modify any records
//   ❌ Does NOT retry failed jobs or recover stalled insights
//   ❌ Does NOT invoke external APIs
//   ❌ Does NOT require a database schema change — all metrics derived from
//          existing columns (status, created_at, updated_at, published_at)
//
// Query strategy: each metric is a separate SELECT COUNT(*) with head:true.
// All 17 queries run concurrently — total latency ≈ single slowest query.
// Indexes used:
//   insights_raw:        idx_insights_raw_status       (status filter)
//                        idx_insights_raw_updated_at   (stalled query, updated_at range)
//                        idx_insights_raw_created_at   (24h ingestion, created_at range)
//   catalyst_insights:   idx_catalyst_insights_status  (status filter)
//                        idx_catalyst_insights_status_published_at  (latency sample)

import { createAdminClient } from '../_shared/supabase-client.ts';
import { PipelineError } from '../_shared/insights/errors.ts';
import { logger } from '../_shared/insights/logger.ts';
import { STALE_VALIDATED_MINUTES } from '../_shared/insights/constants.ts';

const FN = 'pipeline_health';

// Number of recently published insights sampled for latency calculation.
// 50 gives a statistically stable average without fetching excessive data.
const LATENCY_SAMPLE_SIZE = 50;

// ─── Result types ──────────────────────────────────────────────────────────────

export interface RawQueueStats {
  by_status: {
    pending:      number;
    validated:    number;
    duplicate:    number;
    rejected:     number;
    ai_processed: number;
    review:       number;
    scheduled:    number;
    active:       number;
    archived:     number;
    ai_error:     number;
  };
  total: number;
}

export interface CatalystInsightStats {
  by_status: {
    review:    number;
    scheduled: number;
    active:    number;
    archived:  number;
  };
  total: number;
}

export interface HealthSignals {
  failed_enrichment_count:   number;  // insights_raw.status = 'ai_error'
  stalled_validation_count:  number;  // validated AND updated_at < now()-STALE_VALIDATED_MINUTES
  scheduled_for_publication: number;  // catalyst_insights.status = 'scheduled'
  archived_count:            number;  // catalyst_insights.status = 'archived'
  ingested_last_24h:         number;  // insights_raw.created_at >= now()-24h
}

export interface LatencyMetrics {
  // Average milliseconds from catalyst_insight.created_at (enrichment completion)
  // to published_at (admin approval or scheduled activation).
  // null when no published insights exist in the sample window.
  avg_time_to_publish_ms: number | null;
  // Number of active insights sampled for this calculation (max LATENCY_SAMPLE_SIZE).
  sample_size:            number;
}

export interface PipelineHealthResult {
  checked_at:        string;
  raw_queue:         RawQueueStats;
  catalyst_insights: CatalystInsightStats;
  health_signals:    HealthSignals;
  latency:           LatencyMetrics;
}

// ─── Private helpers ──────────────────────────────────────────────────────────

type AdminClient = ReturnType<typeof createAdminClient>;

// COUNT(*) for a given table + status. Uses head:true — no rows transferred.
async function countByStatus(
  client:  AdminClient,
  table:   'insights_raw' | 'catalyst_insights',
  status:  string,
): Promise<number> {
  const { count, error } = await client
    .from(table)
    .select('*', { count: 'exact', head: true })
    .eq('status', status);
  if (error) {
    throw new PipelineError(
      'DB_ERROR',
      `Count failed: ${table}.status=${status} — ${error.message}`,
    );
  }
  return count ?? 0;
}

// COUNT of stalled validated records (status='validated' AND updated_at < threshold).
// Uses idx_insights_raw_updated_at for the range scan.
async function countStalled(client: AdminClient, stalledThreshold: string): Promise<number> {
  const { count, error } = await client
    .from('insights_raw')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'validated')
    .lt('updated_at', stalledThreshold);
  if (error) {
    throw new PipelineError('DB_ERROR', `Stalled count failed: ${error.message}`);
  }
  return count ?? 0;
}

// COUNT of raw insights collected in the last 24 hours.
// Uses idx_insights_raw_created_at for the range scan.
async function countIngested24h(client: AdminClient, since: string): Promise<number> {
  const { count, error } = await client
    .from('insights_raw')
    .select('*', { count: 'exact', head: true })
    .gte('created_at', since);
  if (error) {
    throw new PipelineError('DB_ERROR', `24h ingestion count failed: ${error.message}`);
  }
  return count ?? 0;
}

// Fetches the LATENCY_SAMPLE_SIZE most recently published active insights.
// Returns only (created_at, published_at) — minimal projection, no large payloads.
// Index: idx_catalyst_insights_status_published_at (status, published_at DESC)
// → seek status='active', descending published_at scan, LIMIT 50.
interface LatencyRow { created_at: string; published_at: string | null; }

async function fetchLatencySample(client: AdminClient): Promise<LatencyRow[]> {
  const { data, error } = await client
    .from('catalyst_insights')
    .select('created_at, published_at')
    .eq('status', 'active')
    .not('published_at', 'is', null)
    .order('published_at', { ascending: false })
    .limit(LATENCY_SAMPLE_SIZE);
  if (error) {
    throw new PipelineError('DB_ERROR', `Latency sample fetch failed: ${error.message}`);
  }
  return (data ?? []) as LatencyRow[];
}

// ─── Latency computation ──────────────────────────────────────────────────────

// Computes average milliseconds from created_at (enrichment done) to published_at.
// Represents: time an insight spends waiting for admin review + any scheduling delay.
// Uses only rows where published_at is confirmed non-null (filter + TypeScript narrowing).
function computeAvgLatencyMs(rows: LatencyRow[]): number | null {
  const latencies = rows
    .filter((r): r is { created_at: string; published_at: string } => r.published_at !== null)
    .map((r) => new Date(r.published_at).getTime() - new Date(r.created_at).getTime())
    .filter((ms) => ms >= 0);  // guard against clock skew producing negative values

  if (latencies.length === 0) return null;
  return Math.round(latencies.reduce((sum, ms) => sum + ms, 0) / latencies.length);
}

// ─── Entry point ──────────────────────────────────────────────────────────────

export async function handlePipelineHealth(): Promise<PipelineHealthResult> {
  const adminClient = createAdminClient();
  const checkedAt = new Date().toISOString();

  // Pre-compute time boundaries used across multiple queries.
  // Both use Deno's Date (UTC) — consistent with all other pipeline functions.
  const stalledThreshold = new Date(
    Date.now() - STALE_VALIDATED_MINUTES * 60 * 1_000,
  ).toISOString();

  const since24h = new Date(Date.now() - 24 * 60 * 60 * 1_000).toISOString();

  logger.info('Pipeline health check initiated', {
    fn:                FN,
    checked_at:        checkedAt,
    stalled_threshold: stalledThreshold,
    since_24h:         since24h,
  });

  // ─── 17 queries — all in parallel ─────────────────────────────────────────
  // No query depends on another's result. Promise.all ensures the total wall-clock
  // time equals the slowest single query, not the sum of all queries.
  const [
    rawPending,
    rawValidated,
    rawDuplicate,
    rawRejected,
    rawAiProcessed,
    rawReview,
    rawScheduled,
    rawActive,
    rawArchived,
    rawAiError,
    catalystReview,
    catalystScheduled,
    catalystActive,
    catalystArchived,
    stalledCount,
    ingested24h,
    latencySample,
  ] = await Promise.all([
    // ── insights_raw — 10 status counts ──────────────────────────────────────
    countByStatus(adminClient, 'insights_raw', 'pending'),
    countByStatus(adminClient, 'insights_raw', 'validated'),
    countByStatus(adminClient, 'insights_raw', 'duplicate'),
    countByStatus(adminClient, 'insights_raw', 'rejected'),
    countByStatus(adminClient, 'insights_raw', 'ai_processed'),
    countByStatus(adminClient, 'insights_raw', 'review'),
    countByStatus(adminClient, 'insights_raw', 'scheduled'),
    countByStatus(adminClient, 'insights_raw', 'active'),
    countByStatus(adminClient, 'insights_raw', 'archived'),
    countByStatus(adminClient, 'insights_raw', 'ai_error'),
    // ── catalyst_insights — 4 status counts ──────────────────────────────────
    countByStatus(adminClient, 'catalyst_insights', 'review'),
    countByStatus(adminClient, 'catalyst_insights', 'scheduled'),
    countByStatus(adminClient, 'catalyst_insights', 'active'),
    countByStatus(adminClient, 'catalyst_insights', 'archived'),
    // ── health signals ────────────────────────────────────────────────────────
    countStalled(adminClient, stalledThreshold),
    countIngested24h(adminClient, since24h),
    // ── latency sample (data fetch, not a count) ──────────────────────────────
    fetchLatencySample(adminClient),
  ]);

  // ─── Derive totals ─────────────────────────────────────────────────────────
  const rawTotal = rawPending + rawValidated + rawDuplicate + rawRejected + rawAiProcessed
    + rawReview + rawScheduled + rawActive + rawArchived + rawAiError;

  const catalystTotal = catalystReview + catalystScheduled + catalystActive + catalystArchived;

  // ─── Compute latency ──────────────────────────────────────────────────────
  const avgTimeToPublishMs = computeAvgLatencyMs(latencySample);

  return {
    checked_at: checkedAt,

    raw_queue: {
      by_status: {
        pending:      rawPending,
        validated:    rawValidated,
        duplicate:    rawDuplicate,
        rejected:     rawRejected,
        ai_processed: rawAiProcessed,
        review:       rawReview,
        scheduled:    rawScheduled,
        active:       rawActive,
        archived:     rawArchived,
        ai_error:     rawAiError,
      },
      total: rawTotal,
    },

    catalyst_insights: {
      by_status: {
        review:    catalystReview,
        scheduled: catalystScheduled,
        active:    catalystActive,
        archived:  catalystArchived,
      },
      total: catalystTotal,
    },

    health_signals: {
      failed_enrichment_count:   rawAiError,
      stalled_validation_count:  stalledCount,
      scheduled_for_publication: catalystScheduled,
      archived_count:            catalystArchived,
      ingested_last_24h:         ingested24h,
    },

    latency: {
      avg_time_to_publish_ms: avgTimeToPublishMs,
      sample_size:            latencySample.length,
    },
  };
}
