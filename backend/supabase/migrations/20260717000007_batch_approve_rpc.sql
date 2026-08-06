-- Migration 20260717000007: Catalyst Insights — batch_approve_high_confidence RPC
-- Feature: Catalyst Insights — Content Pipeline
-- Phase 3.5 §3.11 | Sprint 1 M07 | S1-DB-007
-- Depends on: 20260717000003 (catalyst_insights table), 20260717000006 (RLS policies)
--
-- SECURITY INVOKER rationale (Phase 3.5 Risk 8):
-- Running as SECURITY INVOKER means the function inherits the caller's JWT.
-- The catalyst_insights_update_admin RLS policy (M06) gates all UPDATEs on is_admin().
-- Non-admin callers: UPDATE touches 0 rows — RLS silently blocks. No privilege escalation.
-- Admin callers: UPDATE proceeds normally — RLS allows.
-- This is safer than SECURITY DEFINER, which would bypass RLS entirely.
--
-- Usage:
--   POST /rest/v1/rpc/batch_approve_high_confidence
--   Body (default):  {}                                → uses threshold 0.90
--   Body (override): {"confidence_threshold": 0.85}   → custom threshold (testing/ops)
--   Returns: {"approved_count": N, "insight_ids": ["uuid1", "uuid2", ...]}
--
-- Operational note: Documented as disabled for first 4 production weeks.
-- Admin dashboard gates this feature behind a manual enable flag.

CREATE OR REPLACE FUNCTION public.batch_approve_high_confidence(
  confidence_threshold real DEFAULT 0.90
)
RETURNS json
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  _updated_ids uuid[];
BEGIN
  -- Single CTE UPDATE RETURNING: atomic within implicit transaction.
  -- Index used: idx_catalyst_insights_ai_confidence (partial: WHERE status='review')
  -- makes the WHERE clause a fast index-only scan on the review subset.
  WITH updated AS (
    UPDATE public.catalyst_insights
    SET
      status       = 'active',
      published_at = now(),
      updated_at   = now()
    WHERE status         = 'review'
      AND ai_confidence >= confidence_threshold
    RETURNING id
  )
  SELECT ARRAY_AGG(id) INTO _updated_ids FROM updated;

  RETURN json_build_object(
    'approved_count', COALESCE(array_length(_updated_ids, 1), 0),
    'insight_ids',   COALESCE(_updated_ids, ARRAY[]::uuid[])
  );
END;
$$;
