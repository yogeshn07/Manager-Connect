-- Migration 20260717000001: insights_sources
-- Feature: Catalyst Insights — Content Pipeline
-- Domain: Source Allow-List (root table — no FK dependencies)
-- Phase 3.5 §3.1 | Sprint 1 M01 | S1-DB-001
-- RLS and GRANT policies applied in 20260717000006_insights_rls.sql

CREATE TABLE public.insights_sources (
  id              uuid        NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text        NOT NULL UNIQUE,
  approved_domain text        NOT NULL,
  tier            smallint    NOT NULL CHECK (tier IN (1, 2, 3)),
  is_active       boolean     NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now()
);
