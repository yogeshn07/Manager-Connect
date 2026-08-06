-- Migration 20260717000006: Catalyst Insights — RLS Policies
-- Feature: Catalyst Insights — Content Pipeline
-- Phase 3 §11.2 + Phase 3.5 §3.6 | Sprint 1 M06 | S1-DB-006
-- Depends on: 20260717000001–20260717000005
--
-- PHASE 10 FINDING — insights_tags omitted:
-- Phase 5 spec references an insights_tags table (1 select policy). That table
-- was never created; tags are stored as ai_tags text[] on catalyst_insights.
-- No policy is created for a non-existent table. Tables protected: 5 (not 6).
--
-- service_role bypasses all RLS automatically — no explicit service_role policies.
-- "insert-blocked" / "update-blocked" policies block authenticated and anon only;
-- pipeline Edge Functions use service_role and are unaffected.
--
-- Policy count: 16 across 5 tables
--   insights_sources    (3): select-authenticated, insert-admin, update-admin
--   insights_raw        (3): select-admin, insert-blocked, update-blocked
--   catalyst_insights   (4): select-active (public), select-admin-all, insert-blocked, update-admin
--   insights_read_state (3): select-own, insert-own, update-own
--   insights_bookmarks  (3): select-own, insert-own, delete-own

-- ─── Enable RLS (dependency order) ──────────────────────────────────────────

ALTER TABLE public.insights_sources    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insights_raw        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.catalyst_insights   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insights_read_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insights_bookmarks  ENABLE ROW LEVEL SECURITY;

-- ─── Grant role access ───────────────────────────────────────────────────────

-- Sources: authenticated users can read; admins can write
GRANT SELECT, INSERT, UPDATE ON public.insights_sources TO authenticated;

-- Raw queue: admin Flutter can SELECT for monitoring; no authenticated writes
-- (pipeline writes via service_role which bypasses RLS)
GRANT SELECT ON public.insights_raw TO authenticated;

-- Published feed: anon can SELECT (public browsing); admin can UPDATE via authenticated
GRANT SELECT ON public.catalyst_insights TO anon;
GRANT SELECT, UPDATE ON public.catalyst_insights TO authenticated;

-- V2 engagement tables: authenticated users manage their own rows
GRANT SELECT, INSERT, UPDATE ON public.insights_read_state TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.insights_bookmarks TO authenticated;

-- ─── insights_sources policies (3) ───────────────────────────────────────────

-- All active authenticated members and admins can read the approved source list
CREATE POLICY insights_sources_select_authenticated ON public.insights_sources
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND is_active_user()
  );

-- Only admins can register new sources
CREATE POLICY insights_sources_insert_admin ON public.insights_sources
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- Only admins can modify sources (tier changes, deactivation)
CREATE POLICY insights_sources_update_admin ON public.insights_sources
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- ─── insights_raw policies (3) ───────────────────────────────────────────────

-- Only admins can view the pipeline ingestion queue
CREATE POLICY insights_raw_select_admin ON public.insights_raw
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- INSERT reserved for Edge Function pipeline via service_role (bypasses RLS)
CREATE POLICY insights_raw_insert_blocked ON public.insights_raw
  FOR INSERT
  WITH CHECK (false);

-- UPDATE reserved for Edge Function pipeline via service_role (bypasses RLS)
CREATE POLICY insights_raw_update_blocked ON public.insights_raw
  FOR UPDATE
  USING (false);

-- ─── catalyst_insights policies (4) ──────────────────────────────────────────

-- Public feed: any role including anon can read status='active' rows
-- Intentionally no auth.uid() guard — supports anonymous feed browsing
CREATE POLICY catalyst_insights_select_active ON public.catalyst_insights
  FOR SELECT
  USING (status = 'active');

-- Admin override: admins see all statuses (review, scheduled, active, archived)
-- Combined with select_active via OR logic — admin gets complete visibility
CREATE POLICY catalyst_insights_select_admin ON public.catalyst_insights
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- INSERT reserved for enrich_insight Edge Function via service_role (bypasses RLS)
CREATE POLICY catalyst_insights_insert_blocked ON public.catalyst_insights
  FOR INSERT
  WITH CHECK (false);

-- Only admins can UPDATE: approve, reject, edit, schedule insights
CREATE POLICY catalyst_insights_update_admin ON public.catalyst_insights
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- ─── insights_read_state policies (3) ────────────────────────────────────────

CREATE POLICY insights_read_state_select_own ON public.insights_read_state
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
  );

CREATE POLICY insights_read_state_insert_own ON public.insights_read_state
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
  );

-- V2: allows updating read metadata (e.g. read_count, last_read_at) without
-- permitting row hijacking — WITH CHECK prevents user_id reassignment
CREATE POLICY insights_read_state_update_own ON public.insights_read_state
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
  )
  WITH CHECK (
    user_id = auth.uid()
  );

-- ─── insights_bookmarks policies (3) ─────────────────────────────────────────

CREATE POLICY insights_bookmarks_select_own ON public.insights_bookmarks
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
  );

CREATE POLICY insights_bookmarks_insert_own ON public.insights_bookmarks
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
  );

-- DELETE allows the unbookmark action
CREATE POLICY insights_bookmarks_delete_own ON public.insights_bookmarks
  FOR DELETE
  USING (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
  );
