-- Migration 20260717000004: V2 placeholder tables
-- Feature: Catalyst Insights — Content Pipeline
-- Domain: User Engagement (V2 scope — no data in V1)
-- Phase 3.5 §3.4 | Sprint 1 M04 | S1-DB-004
-- FK dependency: catalyst_insights (20260717000003)
-- Both tables are append-only: rows are inserted on action, deleted on undo — no updated_at
-- RLS and GRANT policies applied in 20260717000006_insights_rls.sql
-- Indexes deferred to 20260717000005_insights_indexes.sql

-- Tracks which insights a user has read (V2: powers 'mark as read' and unread badge count)
CREATE TABLE public.insights_read_state (
  id         uuid        NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  insight_id uuid        NOT NULL REFERENCES public.catalyst_insights(id) ON DELETE CASCADE,
  read_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, insight_id)
);

-- Tracks which insights a user has bookmarked (V2: powers saved/bookmark feed)
CREATE TABLE public.insights_bookmarks (
  id            uuid        NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  insight_id    uuid        NOT NULL REFERENCES public.catalyst_insights(id) ON DELETE CASCADE,
  bookmarked_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, insight_id)
);
