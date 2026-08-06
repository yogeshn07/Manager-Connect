-- Migration 20260717000003: catalyst_insights
-- Feature: Catalyst Insights — Content Pipeline
-- Domain: Processed & Published Insights
-- Phase 3.5 §3.3 | Sprint 1 M03 | S1-DB-003
-- FK dependencies: insights_raw (20260717000002), insights_sources (20260717000001)
-- Phase 3.8 MF-04: is_evergreen column — protects active insights from expire cron
-- Phase 3.8 MF-06: reviewed_by + reviewed_at columns — admin action audit trail
-- RLS and GRANT policies applied in 20260717000006_insights_rls.sql

CREATE TABLE public.catalyst_insights (
  id                   uuid        NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign key references
  raw_id               uuid        NOT NULL REFERENCES public.insights_raw(id),
  source_id            uuid        NOT NULL REFERENCES public.insights_sources(id),

  -- Deduplication key (mirrors insights_raw.url_fingerprint)
  url_fingerprint      text        NOT NULL UNIQUE,

  -- AI-generated content fields (nullable: set during enrich_insight, absent if enrichment incomplete)
  ai_headline          text,
  ai_summary           text,
  ai_why_matters       text,
  ai_key_takeaway      text,
  ai_tags              text[]      NOT NULL DEFAULT '{}',
  ai_confidence        real,

  -- Article metadata (denormalised for single-table PostgREST query)
  source_name          text,
  source_url           text,
  article_date         date,
  reading_time_minutes smallint,
  hero_image_url       text,
  category             text        NOT NULL
                                   CHECK (category IN (
                                     'grid_technology',
                                     'energy_transition',
                                     'industry_standards',
                                     'engineering_leadership',
                                     'policy_markets',
                                     'innovation'
                                   )),
  is_ai_generated      boolean     NOT NULL DEFAULT true,

  -- Publication lifecycle
  status               text        NOT NULL DEFAULT 'review'
                                   CHECK (status IN ('review', 'scheduled', 'active', 'archived')),
  scheduled_for        timestamptz,
  published_at         timestamptz,

  -- Phase 3.8 MF-04: Evergreen protection
  -- expire_old_insights filters WHERE is_evergreen = false; true rows are never auto-archived
  is_evergreen         boolean     NOT NULL DEFAULT false,

  -- Phase 3.8 MF-06: Admin review audit trail
  -- Set on every admin write: approveInsight, rejectInsight, editInsight
  reviewed_by          uuid        REFERENCES auth.users(id),
  reviewed_at          timestamptz,

  -- Timestamps
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER set_catalyst_insights_updated_at
  BEFORE UPDATE ON public.catalyst_insights
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
