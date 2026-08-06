-- Migration 20260717000002: insights_raw
-- Feature: Catalyst Insights — Content Pipeline
-- Domain: Raw Article Ingestion
-- Phase 3.5 §3.2 | Sprint 1 M02 | S1-DB-002
-- FK dependency: insights_sources (20260717000001)
-- 10-state status machine; UNIQUE url_fingerprint enforces deduplication at DB level
-- updated_at trigger required: CF-01 recover_stalled_insights queries
--   WHERE status = 'validated' AND updated_at < now() - interval '15 minutes'
-- RLS and GRANT policies applied in 20260717000006_insights_rls.sql

CREATE TABLE public.insights_raw (
  id                uuid        NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id         uuid        NOT NULL REFERENCES public.insights_sources(id),
  raw_url           text        NOT NULL,
  url_fingerprint   text        NOT NULL UNIQUE,
  title_fingerprint text,
  status            text        NOT NULL DEFAULT 'pending'
                                CHECK (status IN (
                                  'pending', 'validated', 'duplicate', 'rejected',
                                  'ai_processed', 'review', 'scheduled', 'active',
                                  'archived', 'ai_error'
                                )),
  og_title          text,
  og_description    text,
  og_image_url      text,
  submitted_by      uuid        REFERENCES auth.users(id),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER set_insights_raw_updated_at
  BEFORE UPDATE ON public.insights_raw
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
