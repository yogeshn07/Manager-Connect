-- Migration 20260717000005: Catalyst Insights — All Indexes
-- Feature: Catalyst Insights — Content Pipeline
-- Phase 3.5 §3.5 + CF-01 addition | Sprint 1 M05 | S1-DB-005
-- Depends on: 20260717000001 (insights_sources), 20260717000002 (insights_raw),
--             20260717000003 (catalyst_insights), 20260717000004 (v2_placeholder)
--
-- Index count breakdown:
--   4 implicit already created by PRIMARY KEY and UNIQUE in M02/M03
--   9 explicit from Phase 3.5 §3.5 (indexes 1-3, 5-10 below)
--   1 explicit CF-01 addition (index 4 below)
--   Total in pg_indexes for insights_raw + catalyst_insights = 14

-- ─── insights_raw indexes (4 explicit) ───────────────────────────────────────

-- Pipeline status queries: validate_insight, recover_stalled_insights
CREATE INDEX idx_insights_raw_status
  ON public.insights_raw (status);

-- FK index: admin filter by source; source-level pipeline analytics
CREATE INDEX idx_insights_raw_source_id
  ON public.insights_raw (source_id);

-- Admin queue ordering: most recent submissions first
CREATE INDEX idx_insights_raw_created_at
  ON public.insights_raw (created_at DESC);

-- CF-01: recover_stalled_insights queries WHERE status='validated'
--        AND updated_at < now() - interval '15 minutes'
--        Without this, the recovery cron performs a full table scan
CREATE INDEX idx_insights_raw_updated_at
  ON public.insights_raw (updated_at);

-- ─── catalyst_insights indexes (6 explicit) ──────────────────────────────────

-- General status filter: admin review queue, pipeline health queries
CREATE INDEX idx_catalyst_insights_status
  ON public.catalyst_insights (status);

-- Primary Flutter feed query: WHERE status = 'active' ORDER BY published_at DESC
-- Composite covers filter + sort in a single index scan — no heap sort needed
CREATE INDEX idx_catalyst_insights_status_published_at
  ON public.catalyst_insights (status, published_at DESC);

-- Category-filtered feed: WHERE status = 'active' AND category = $1
CREATE INDEX idx_catalyst_insights_category
  ON public.catalyst_insights (category);

-- FK index: admin filter by source; pipeline traceability
CREATE INDEX idx_catalyst_insights_source_id
  ON public.catalyst_insights (source_id);

-- activate_scheduled_insights cron:
--   WHERE status = 'scheduled' AND (scheduled_for IS NULL OR scheduled_for <= now())
-- Partial index: only indexes rows that need activation; omits review/active/archived
CREATE INDEX idx_catalyst_insights_scheduled_for
  ON public.catalyst_insights (scheduled_for)
  WHERE status = 'scheduled';

-- batch_approve_high_confidence RPC:
--   WHERE status = 'review' AND ai_confidence >= $threshold ORDER BY ai_confidence DESC
-- Partial index: only indexes review-status rows; DESC order matches RPC sort direction
CREATE INDEX idx_catalyst_insights_ai_confidence
  ON public.catalyst_insights (ai_confidence DESC)
  WHERE status = 'review';
