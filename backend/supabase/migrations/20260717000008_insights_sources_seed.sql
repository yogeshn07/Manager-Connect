-- Migration 20260717000008: Catalyst Insights — insights_sources seed data
-- Feature: Catalyst Insights — Content Pipeline
-- Phase 2.5 source validation + Phase 3.5 §5.5 | Sprint 1 M08 | S1-DB-008
-- Depends on: 20260717000006 (RLS — seed runs as postgres/service_role, bypasses RLS)
--
-- 25 rows: 5 Tier 1 + 10 Tier 2 + 10 Tier 3
-- Excluded: S&P Global Commodity Insights (RED — universal paywall + ToS incompatible, Phase 2.5 §3.26)
-- Reclassifications applied per Phase 2.5:
--   CIGRÉ:  Tier 1 → Tier 2 (§3.3 — public content only, technical brochures are members-only)
--   EPRI:   Tier 2 → Tier 3 (§3.12 — primary output is paywalled; public content is limited)
-- Sub-path domain constraint (Phase 2.5 §3.14, §3.15):
--   WEF:    approved_domain = 'weforum.org/agenda/energy'  (NOT the full weforum.org domain)
--   EC:     approved_domain = 'ec.europa.eu/energy'        (NOT the full ec.europa.eu domain)
--   validate_insight uses sub-path match: url.startsWith('https://' + approved_domain)
-- IEEE Xplore: handled via IEEE API within enrich_insight (§3.1 treated as one source entity)
-- No-RSS sources (admin manual submission only in V1): GE Vernova, IEEE PES, CIGRÉ, EPRI
--
-- Schema note: M01 (insights_sources) does NOT have rss_feed_url, default_category, or notes.
-- Seed inserts only into columns that exist: name, approved_domain, tier.
-- is_active defaults to true per M01 column definition.
--
-- Idempotent: ON CONFLICT (name) DO NOTHING — name is UNIQUE in M01.
-- S1-DB-009 verification checklist: count=25, CIGRÉ tier=2, EPRI tier=3,
--   WEF domain='weforum.org/agenda/energy', EC domain='ec.europa.eu/energy', all is_active=true

INSERT INTO public.insights_sources (name, approved_domain, tier) VALUES

-- ─── Tier 1: Premier engineering publications and government agencies ─────────

  -- §3.1 IEEE Spectrum — primary IEEE editorial source for engineering content
  -- RSS: spectrum.ieee.org/feeds/feed.rss | IEEE Xplore API used inside enrich_insight
  -- Attribution: "IEEE Spectrum"
  ('IEEE Spectrum',                          'spectrum.ieee.org',          1),

  -- §3.2 IEEE Power & Energy Society — PES Magazine, conference content
  -- RSS: limited (admin manual submission only in V1)
  -- Attribution: "IEEE Power & Energy Society"
  ('IEEE Power & Energy Society',            'pes.ieee.org',               1),

  -- §3.4 International Energy Agency — CC BY-NC 3.0; non-commercial use confirmed
  -- RSS: iea.org/news.rss | Rich OG descriptions; high AI enrichment quality
  -- Attribution: "International Energy Agency"
  ('International Energy Agency',            'iea.org',                    1),

  -- §3.5 Hitachi Energy — press releases, project and technology announcements
  -- RSS: confirmed
  -- Attribution: "Hitachi Energy"
  ('Hitachi Energy',                         'hitachienergy.com',          1),

  -- §3.6 U.S. Department of Energy — public domain content (17 U.S.C. § 105)
  -- RSS: multiple feeds at energy.gov
  -- Attribution: "U.S. Department of Energy"
  ('U.S. Department of Energy',              'energy.gov',                 1),

-- ─── Tier 2: Reclassified and validated Tier 2 sources ───────────────────────

  -- §3.3 CIGRÉ — RECLASSIFIED Tier 1 → Tier 2
  -- Scope: cigre.org/news only; e-cigre.org (members-only technical brochures) excluded
  -- RSS: none confirmed — admin manual submission only
  -- Attribution: "CIGRÉ"
  ('CIGRÉ',                                  'cigre.org',                  2),

  -- §3.7 Siemens Energy — press releases, grid and energy transition announcements
  -- RSS: confirmed | Admin keyword filter: grid, transmission, energy storage
  -- Attribution: "Siemens Energy"
  ('Siemens Energy',                         'siemens-energy.com',         2),

  -- §3.8 GE Vernova — press releases and project announcements
  -- RSS: unconfirmed — admin manual submission only until RSS confirmed (Phase 2.5 §3.8)
  -- Attribution: "GE Vernova"
  ('GE Vernova',                             'gevernova.com',              2),

  -- §3.9 Schneider Electric — insights and press releases
  -- RSS: confirmed | Admin filter: grid automation, energy management
  -- Attribution: "Schneider Electric"
  ('Schneider Electric',                     'se.com',                     2),

  -- §3.10 ABB — news and press releases (grid and power content only)
  -- RSS: confirmed | Admin filter: power grid, substation, HVDC, smart grid
  -- Attribution: "ABB"
  ('ABB',                                    'abb.com',                    2),

  -- §3.11 NREL — DOE national laboratory; open-access research content
  -- RSS: nrel.gov feeds | High AI enrichment quality (technical descriptions)
  -- Attribution: "NREL"
  ('NREL',                                   'nrel.gov',                   2),

  -- §3.13 Rocky Mountain Institute — CC BY-NC-SA 4.0; non-commercial use confirmed
  -- RSS: rmi.org/insights
  -- Attribution: "Rocky Mountain Institute"
  ('Rocky Mountain Institute',               'rmi.org',                    2),

  -- §3.14 World Economic Forum — CRITICAL: sub-path constraint (energy content only)
  -- RSS: weforum.org/agenda/energy/feed | Full weforum.org domain is NOT approved
  -- validate_insight sub-path match: url.startsWith('https://weforum.org/agenda/energy')
  -- Attribution: "World Economic Forum"
  ('World Economic Forum',                   'weforum.org/agenda/energy',  2),

  -- §3.15 European Commission — CRITICAL: sub-path constraint (energy content only)
  -- RSS: ec.europa.eu energy topic feeds | EU open licence
  -- validate_insight sub-path match: url.startsWith('https://ec.europa.eu/energy')
  -- Attribution: "© European Union / European Commission"
  ('European Commission',                    'ec.europa.eu/energy',        2),

  -- §3.16 U.S. Energy Information Administration — public domain (17 U.S.C. § 105)
  -- RSS: eia.gov/rss/news.xml | Today in Energy feed; ideal Catalyst Insights format
  -- Attribution: "U.S. Energy Information Administration"
  ('U.S. Energy Information Administration', 'eia.gov',                    2),

-- ─── Tier 3: Trade publications and EPRI (reclassified) ──────────────────────

  -- §3.12 EPRI — RECLASSIFIED Tier 2 → Tier 3
  -- Scope: epri.com news/press releases only; member-only technical reports excluded
  -- RSS: none confirmed — admin manual submission only; admin verification required
  -- Attribution: "EPRI"
  ('EPRI',                                   'epri.com',                   3),

  -- §3.17 Utility Dive — primary U.S. utility sector trade publication
  -- RSS: utilitydive.com/feeds/news | High volume; admin curation required
  -- Attribution: "Utility Dive"
  ('Utility Dive',                           'utilitydive.com',            3),

  -- §3.18 Power Magazine — power generation and grid
  -- RSS: confirmed | Admin filter: grid reliability, storage, clean generation
  -- Attribution: "Power Magazine"
  ('Power Magazine',                         'powermag.com',               3),

  -- §3.19 T&D World — transmission and distribution focus
  -- RSS: confirmed (Endeavor Business Media)
  -- Attribution: "T&D World"
  ('T&D World',                              'tdworld.com',                3),

  -- §3.20 Electric Light & Power — utility management and infrastructure
  -- RSS: confirmed (PennWell/Endeavor Business Media)
  -- Attribution: "Electric Light & Power"
  ('Electric Light & Power',                 'elp.com',                    3),

  -- §3.21 Renewable Energy World — solar, wind, storage projects
  -- RSS: confirmed | Admin filter: grid integration, utility-scale projects
  -- Attribution: "Renewable Energy World"
  ('Renewable Energy World',                 'renewableenergyworld.com',   3),

  -- §3.22 ASCE Civil Engineering — infrastructure engineering content
  -- RSS: confirmed for CE magazine | Scope: Civil Engineering magazine only
  -- Attribution: "ASCE Civil Engineering"
  ('ASCE Civil Engineering',                 'asce.org',                   3),

  -- §3.23 Energy Monitor (GlobalData) — energy transition and grid policy
  -- RSS: confirmed | Soft-paywall caution: admin verification required per article
  -- Attribution: "Energy Monitor"
  ('Energy Monitor',                         'energymonitor.ai',           3),

  -- §3.24 PV Magazine — solar energy trade publication; international edition
  -- RSS: excellent structured feeds | Admin filter: grid-scale solar, storage integration
  -- Attribution: "PV Magazine"
  ('PV Magazine',                            'pv-magazine.com',            3),

  -- §3.25 Wind Power Engineering — wind turbine and project engineering
  -- RSS: confirmed (WTWH Media) | Admin filter: offshore wind, grid integration
  -- Attribution: "Wind Power Engineering"
  ('Wind Power Engineering',                 'windpowerengineering.com',   3)

ON CONFLICT (name) DO NOTHING;
