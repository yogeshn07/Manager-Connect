// activate-scheduled-insights — Use case
// CF-02: Scheduled publication for the Catalyst Insights pipeline.
//
// Responsibilities:
//   ✅ Query catalyst_insights WHERE status='scheduled'
//          AND (scheduled_for IS NULL OR scheduled_for <= checkedAt)
//   ✅ Batch UPDATE (single atomic statement): status='active', published_at=checkedAt
//   ✅ Optimistic lock: WHERE status='scheduled' in the UPDATE ensures that
//          concurrent executions can never double-activate the same row
//   ✅ Return structured ActivationResult: activated_count, insight_ids[], checked_at
//   ✅ Per-row structured logging at info level (audit trail in Supabase logs)
//   ✅ Idempotent: a second run within the same minute finds status='active' → 0 rows
//   ✅ Uses partial index idx_catalyst_insights_scheduled_for (WHERE status='scheduled')
//          for an efficient index-range scan — no full table scan
//
//   ❌ Does NOT publish 'review' insights (review-insight handles that)
//   ❌ Does NOT invoke external APIs (no AI, no OG fetching)
//   ❌ Does NOT write to admin_audit_log (no human admin_id — automated cron action)
//   ❌ Does NOT touch insights_raw
//   ❌ Does NOT touch collect_insight, validate_insight, enrich_insight, review_insight
//
// UTC note: new Date().toISOString() produces a UTC timestamp with 'Z' suffix in Deno.
// catalyst_insights.scheduled_for is timestamptz — PostgreSQL compares in UTC regardless
// of session timezone. The JS-side checkedAt and DB-side scheduled_for are UTC-compatible.
//
// scheduled_for IS NULL handling: insights placed in 'scheduled' state without a
// scheduled_for time are treated as "publish immediately". This matches the query
// pattern documented in migration 20260717000005 (idx_catalyst_insights_scheduled_for).

import { createAdminClient } from '../_shared/supabase-client.ts';
import { PipelineError } from '../_shared/insights/errors.ts';
import { logger } from '../_shared/insights/logger.ts';

const FN = 'activate_scheduled_insights';

// ─── Status constants (mirror catalyst_insights CHECK constraint) ──────────────
const STATUS_SCHEDULED = 'scheduled' as const;
const STATUS_ACTIVE    = 'active'    as const;

// ─── Result type ──────────────────────────────────────────────────────────────

export interface ActivationResult {
  activated_count: number;    // insights transitioned from scheduled → active
  insight_ids:     string[];  // UUIDs of activated insights (for downstream callers)
  checked_at:      string;    // ISO UTC timestamp used for the scheduled_for comparison
}

// ─── DB row projection ────────────────────────────────────────────────────────

interface ScheduledInsightRow {
  id:            string;
  ai_headline:   string | null;
  scheduled_for: string | null;
}

// ─── Use case entry point ─────────────────────────────────────────────────────

// Activates all catalyst_insights that are scheduled and due for publication.
// Throws PipelineError(DB_ERROR) if the Supabase UPDATE fails; caller (index.ts)
// converts this to a 500 response.
export async function handleActivateScheduledInsights(): Promise<ActivationResult> {
  const adminClient = createAdminClient();

  // Capture comparison timestamp on the JS side so the same value is used for:
  //   (a) the WHERE predicate (scheduled_for <= checkedAt)
  //   (b) the published_at column value for every activated row
  // This makes all rows in a single cron run share the same published_at, which
  // makes cron run boundaries trivially correlatable in analytics/logs.
  const checkedAt = new Date().toISOString();  // UTC — Deno's Date is always UTC

  logger.info('CF-02 scanning for scheduled insights due', {
    fn:         FN,
    checked_at: checkedAt,
  });

  // Single atomic UPDATE with RETURNING — equivalent to:
  //
  //   UPDATE public.catalyst_insights
  //   SET    status = 'active', published_at = $checkedAt
  //   WHERE  status       = 'scheduled'
  //   AND   (scheduled_for IS NULL OR scheduled_for <= $checkedAt)
  //   RETURNING id, ai_headline, scheduled_for;
  //
  // Optimistic-lock property: the WHERE status='scheduled' clause means a concurrent
  // execution that already activated these rows will find status='active' and match
  // 0 rows — no double-activation is possible.
  //
  // Index used: idx_catalyst_insights_scheduled_for (partial: WHERE status='scheduled')
  // → fast index-range scan on scheduled_for; avoids touching active/archived/review rows.
  const { data: activated, error } = await adminClient
    .from('catalyst_insights')
    .update({
      status:       STATUS_ACTIVE,
      published_at: checkedAt,
    })
    .eq('status', STATUS_SCHEDULED)
    .or(`scheduled_for.is.null,scheduled_for.lte.${checkedAt}`)
    .select('id, ai_headline, scheduled_for');

  if (error) {
    throw new PipelineError(
      'DB_ERROR',
      `Failed to activate scheduled insights: ${error.message}`,
    );
  }

  const rows = (activated ?? []) as ScheduledInsightRow[];

  if (rows.length === 0) {
    return { activated_count: 0, insight_ids: [], checked_at: checkedAt };
  }

  // Per-row audit log entry — insight_id + scheduled_for preserved for traceability.
  // written to Supabase Edge Function logs (structured JSON, correlatable by insight_id).
  for (const row of rows) {
    logger.info('CF-02 insight activated', {
      fn:            FN,
      insight_id:    row.id,
      ai_headline:   row.ai_headline ?? '<untitled>',
      scheduled_for: row.scheduled_for ?? 'null (immediate)',
      published_at:  checkedAt,
      status_from:   STATUS_SCHEDULED,
      status_to:     STATUS_ACTIVE,
    });
  }

  return {
    activated_count: rows.length,
    insight_ids:     rows.map((r) => r.id),
    checked_at:      checkedAt,
  };
}
