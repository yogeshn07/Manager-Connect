// expire-old-insights — Use case
// CF-03: Insight expiration and archival for the Catalyst Insights pipeline.
//
// Responsibilities:
//   ✅ Archive active insights older than ACTIVE_INSIGHT_EXPIRY_DAYS (30 days)
//          WHERE status='active' AND is_evergreen=false
//          AND published_at IS NOT NULL AND published_at < expiryThreshold
//   ✅ Evergreen protection: is_evergreen=true rows are NEVER touched (Phase 3.8 MF-04)
//   ✅ Batch UPDATE (single atomic statement): status='archived'
//   ✅ Optimistic lock: WHERE status='active' in the UPDATE ensures that concurrent
//          executions can never double-archive the same row
//   ✅ Return structured ExpirationResult: expired_count, insight_ids[], expiry_threshold
//   ✅ Per-row structured logging at info level (audit trail in Supabase logs)
//   ✅ Idempotent: a second run immediately after finds status='archived' → 0 rows matched
//   ✅ published_at IS NOT NULL guard: defensively skips rows without a publication date
//
//   ❌ Does NOT delete insights — archival is soft; archived rows remain in the DB
//   ❌ Does NOT archive is_evergreen=true insights regardless of age
//   ❌ Does NOT invoke external APIs
//   ❌ Does NOT touch insights_raw
//   ❌ Does NOT touch collect_insight, validate_insight, enrich_insight,
//          review_insight, or activate_scheduled_insights
//
// "expires_at" concept: the task spec refers to an expires_at comparison.
// The catalyst_insights schema has no expires_at column (locked per Phase 9).
// expires_at is computed: published_at + ACTIVE_INSIGHT_EXPIRY_DAYS.
// Equivalently: published_at < (now() - ACTIVE_INSIGHT_EXPIRY_DAYS) → insight expired.
// expiryThreshold (= now() - 30 days) is the concrete timestamp used in the WHERE clause.
//
// Index used: idx_catalyst_insights_status_published_at (status, published_at DESC)
// — existing composite index covers the status='active' AND published_at < threshold query.
//
// UTC note: new Date().toISOString() produces UTC ('Z' suffix) in Deno.
// published_at is timestamptz — PostgreSQL comparison is UTC-safe.

import { createAdminClient } from '../_shared/supabase-client.ts';
import { PipelineError } from '../_shared/insights/errors.ts';
import { logger } from '../_shared/insights/logger.ts';

const FN = 'expire_old_insights';

// ─── Expiry policy ─────────────────────────────────────────────────────────────
// Non-evergreen active insights older than this many days are archived.
// is_evergreen=true insights are protected regardless of age (Phase 3.8 MF-04).
const ACTIVE_INSIGHT_EXPIRY_DAYS = 30;

// ─── Status constants (mirror catalyst_insights CHECK constraint) ──────────────
const STATUS_ACTIVE   = 'active'   as const;
const STATUS_ARCHIVED = 'archived' as const;

// ─── Result type ──────────────────────────────────────────────────────────────

export interface ExpirationResult {
  expired_count:    number;    // insights transitioned from active → archived
  insight_ids:      string[];  // UUIDs of archived insights
  expiry_threshold: string;    // ISO UTC timestamp: insights published before this were archived
}

// ─── DB row projection ────────────────────────────────────────────────────────

interface ActiveInsightRow {
  id:            string;
  ai_headline:   string | null;
  published_at:  string | null;
  is_evergreen:  boolean;
}

// ─── Use case entry point ─────────────────────────────────────────────────────

// Archives all non-evergreen active insights older than ACTIVE_INSIGHT_EXPIRY_DAYS.
// Throws PipelineError(DB_ERROR) if the Supabase UPDATE fails; caller (index.ts)
// converts this to a 500 response.
export async function handleExpireOldInsights(): Promise<ExpirationResult> {
  const adminClient = createAdminClient();

  // Compute the expiry threshold in UTC.
  // Insights with published_at strictly before this timestamp are eligible for archival.
  // This is the concrete implementation of the "expires_at < now()" concept:
  //   expires_at (virtual) = published_at + ACTIVE_INSIGHT_EXPIRY_DAYS
  //   expires_at < now()  ↔  published_at < now() - ACTIVE_INSIGHT_EXPIRY_DAYS
  const expiryThreshold = new Date(
    Date.now() - ACTIVE_INSIGHT_EXPIRY_DAYS * 24 * 60 * 60 * 1_000,
  ).toISOString();

  logger.info('CF-03 scanning for expired insights', {
    fn:               FN,
    expiry_days:      ACTIVE_INSIGHT_EXPIRY_DAYS,
    expiry_threshold: expiryThreshold,
  });

  // Single atomic UPDATE with RETURNING — equivalent to:
  //
  //   UPDATE public.catalyst_insights
  //   SET    status = 'archived'
  //   WHERE  status       = 'active'
  //   AND    is_evergreen = false
  //   AND    published_at IS NOT NULL
  //   AND    published_at < $expiryThreshold
  //   RETURNING id, ai_headline, published_at, is_evergreen;
  //
  // Optimistic-lock property: the WHERE status='active' clause ensures that
  // a concurrent execution that already archived a row will find status='archived'
  // and match 0 rows for that row — no double-archival is possible.
  //
  // Evergreen protection: is_evergreen=false in WHERE means rows with
  // is_evergreen=true are NEVER matched, regardless of published_at age.
  //
  // Index used: idx_catalyst_insights_status_published_at (status, published_at DESC)
  // → seek to status='active', then range-scan published_at < expiryThreshold.
  const { data: archived, error } = await adminClient
    .from('catalyst_insights')
    .update({ status: STATUS_ARCHIVED })
    .eq('status', STATUS_ACTIVE)
    .eq('is_evergreen', false)
    .not('published_at', 'is', null)
    .lt('published_at', expiryThreshold)
    .select('id, ai_headline, published_at, is_evergreen');

  if (error) {
    throw new PipelineError(
      'DB_ERROR',
      `Failed to archive expired insights: ${error.message}`,
    );
  }

  const rows = (archived ?? []) as ActiveInsightRow[];

  if (rows.length === 0) {
    return { expired_count: 0, insight_ids: [], expiry_threshold: expiryThreshold };
  }

  // Per-row audit log entry — insight_id and published_at preserved for lifecycle tracing.
  for (const row of rows) {
    logger.info('CF-03 insight archived', {
      fn:               FN,
      insight_id:       row.id,
      ai_headline:      row.ai_headline ?? '<untitled>',
      published_at:     row.published_at,
      expiry_threshold: expiryThreshold,
      status_from:      STATUS_ACTIVE,
      status_to:        STATUS_ARCHIVED,
    });
  }

  return {
    expired_count:    rows.length,
    insight_ids:      rows.map((r) => r.id),
    expiry_threshold: expiryThreshold,
  };
}
