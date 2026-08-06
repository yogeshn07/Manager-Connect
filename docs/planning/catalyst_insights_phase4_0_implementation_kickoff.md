# CATALYST INSIGHTS — PHASE 4.0
# IMPLEMENTATION KICKOFF & SPRINT EXECUTION GUIDE

**Classification:** Engineering Execution Manual  
**Status:** APPROVED FOR IMPLEMENTATION  
**Predecessor:** Phase 3.8 Engineering Readiness Review (Score: 84/100 — GO)  
**Mandatory Findings Incorporated:** CF-01, MF-01 through MF-07  
**Total Duration:** 5.5 weeks / 27 working days  
**Sprint Count:** 4  
**No-Code Constraint:** This document contains no production code, SQL, Flutter, Edge Functions, or migrations.

---

## PHASE 3.8 MANDATORY FINDINGS — DISPOSITION SUMMARY

All 8 mandatory findings from the Engineering Readiness Review are incorporated into this plan. Teams must not begin any sprint until the findings gating that sprint are marked resolved.

| Finding | Title | Gating Sprint | Status |
|---------|-------|---------------|--------|
| CF-01 | recover_stalled_insights cron | Sprint 2, Day 1 | OPEN — must resolve before S2 begins |
| MF-01 | HMAC webhook verification | Sprint 2, Day 1 | OPEN — must resolve before S2 begins |
| MF-03 | ai_error recovery UI | Sprint 4, Day 1 | OPEN — must resolve before S4 begins |
| MF-04 | is_evergreen mechanism | Sprint 1, Day 1 | OPEN — must resolve before S1 begins |
| MF-05 | Image dimension validation | Sprint 3, Day 1 | OPEN — must resolve before S3 begins |
| MF-06 | reviewed_by / reviewed_at audit trail | Sprint 1, Day 1 | OPEN — must resolve before S1 begins |
| MF-07 | Prompt injection defenses | Sprint 3, Day 1 | OPEN — must resolve before S3 begins |

**MF-04 and MF-06 are Sprint 1 blockers.** These mandate additions to migration M03 and must be agreed by the database engineer before any migration is written.

**MF-05 and MF-07 are Sprint 3 blockers.** The approved implementation approach (binary header parsing; input sanitization + output anomaly detection) is specified in Phase 3.8. Engineering agreement is sufficient — no additional design document required.

---

## SECTION 1 — IMPLEMENTATION READINESS CHECKLIST

Complete every item in this checklist before allowing any engineer to write a single line of implementation code. Sprint 1 is gated on the entire checklist.

### 1.1 Repository Readiness

| # | Item | Owner | Verified |
|---|------|-------|---------|
| R-01 | Git repository is accessible to all team members | Engineering Director | ☐ |
| R-02 | `main` branch is protected — direct push disabled | Engineering Director | ☐ |
| R-03 | Branch naming convention agreed and documented | Tech Lead | ☐ |
| R-04 | PR template created at `.github/pull_request_template.md` | Tech Lead | ☐ |
| R-05 | Issue labels created: `sprint-1` through `sprint-4`, `bug`, `finding`, `blocked`, `critical-path` | Engineering Director | ☐ |
| R-06 | `docs/planning/` directory contains all 6 phase documents | Tech Lead | ☐ |
| R-07 | All team members have cloned and verified local build passes | All Engineers | ☐ |

### 1.2 Git Branches

All branches must be created from `main` before Sprint 1 begins. Do not create branches mid-sprint.

| # | Branch Name | Created From | Purpose | Owner |
|---|-------------|--------------|---------|-------|
| B-01 | `feature/insights-sprint-1-database` | `main` | Migrations M01–M07 + seed | Database Engineer |
| B-02 | `feature/insights-sprint-2-pipeline` | `main` | `_shared/` + `collect_insight` + `validate_insight` + CF-01 | Backend Engineer |
| B-03 | `feature/insights-sprint-3-enrichment` | `main` | `enrich_insight` + schedulers | Backend Engineer |
| B-04 | `feature/insights-sprint-4-flutter` | `main` | Flutter data layer + state layer + UI + admin | Flutter Engineer |
| B-05 | `feature/insights-sprint-4-nav` | `feature/insights-sprint-4-flutter` | GoRouter `ShellRoute` wiring only — kept separate for rollback | Flutter Engineer |

**B-05 is a child branch of B-04.** It is created at the start of Sprint 4, Day 6. GoRouter conflict risk (Phase 3.8 mf-07) is isolated here so it can be reverted without touching the rest of the Flutter implementation.

### 1.3 Supabase Project

| # | Item | Owner | Verified |
|---|------|-------|---------|
| SB-01 | Supabase project created and accessible | DevOps Lead | ☐ |
| SB-02 | Supabase Pro plan confirmed active (Phase 3.8 mf-08 — required for custom cron, log retention >7 days, storage egress) | Engineering Director | ☐ |
| SB-03 | Supabase project URL noted and distributed to team | DevOps Lead | ☐ |
| SB-04 | `anon` key and `service_role` key extracted from Dashboard → Settings → API | DevOps Lead | ☐ |
| SB-05 | Supabase CLI installed locally (`supabase --version`) | All Engineers | ☐ |
| SB-06 | `supabase login` completed on all developer machines | All Engineers | ☐ |
| SB-07 | Local Supabase dev stack starts cleanly (`supabase start`) | Database Engineer | ☐ |
| SB-08 | Database webhook endpoint configured: `validate_insight` URL registered in Dashboard → Database → Webhooks | Backend Engineer | ☐ |
| SB-09 | Webhook secret generated (cryptographically random, ≥32 bytes) and stored in Supabase secrets (MF-01) | DevOps Lead | ☐ |
| SB-10 | `insights-images` Storage bucket created, visibility: `public` | DevOps Lead | ☐ |
| SB-11 | Storage Image Transformation enabled on project (required for WebP CDN URL params) | DevOps Lead | ☐ |
| SB-12 | Realtime enabled on the project | DevOps Lead | ☐ |
| SB-13 | pg_cron extension enabled in Dashboard → Database → Extensions | DevOps Lead | ☐ |

### 1.4 Anthropic API

| # | Item | Owner | Verified |
|---|------|-------|---------|
| AN-01 | Anthropic API account created | Engineering Director | ☐ |
| AN-02 | API key procured and stored in password manager | Engineering Director | ☐ |
| AN-03 | API key added to Supabase Edge Function secrets as `ANTHROPIC_API_KEY` | DevOps Lead | ☐ |
| AN-04 | Rate limits reviewed and noted: requests/min, tokens/min for `claude-haiku-4-5-20251001` | Principal AI Systems Engineer | ☐ |
| AN-05 | Spend alert configured at $10/month threshold | Engineering Director | ☐ |
| AN-06 | Test invocation of `claude-haiku-4-5-20251001` succeeds with minimal prompt | Backend Engineer | ☐ |

### 1.5 Environment Variables

All variables below must be populated in Supabase Dashboard → Edge Functions → Secrets before Sprint 2 begins. Variables marked CRITICAL PATH must be procured during Sprint 1.

| Variable | Functions | Sprint Required | Priority |
|----------|-----------|-----------------|----------|
| `SUPABASE_URL` | All Edge Functions | Sprint 1 | CRITICAL PATH |
| `SUPABASE_SERVICE_ROLE_KEY` | All Edge Functions | Sprint 1 | CRITICAL PATH |
| `ANTHROPIC_API_KEY` | `enrich_insight` | Sprint 1 (procure), Sprint 3 (use) | CRITICAL PATH |
| `WEBHOOK_SECRET` | `validate_insight` | Sprint 2 (MF-01) | CRITICAL PATH |
| `IEEE_API_KEY` | `enrich_insight` (optional) | V2 only | DEFER |

Environment variable verification procedure:  
1. DevOps Lead sets all variables in Supabase Secrets dashboard  
2. Backend Engineer verifies each variable is readable from a test Edge Function invocation  
3. Variables are never committed to git or logged in application logs  

### 1.6 Developer Tooling

| # | Tool | Version | Owner |
|---|------|---------|-------|
| T-01 | Dart SDK | 3.11.5 | Flutter Engineer |
| T-02 | Flutter SDK | 3.41.7 | Flutter Engineer |
| T-03 | Deno | Latest stable | Backend Engineer |
| T-04 | Supabase CLI | Latest stable | All Engineers |
| T-05 | Postman or equivalent (API testing) | Any | Backend Engineer |
| T-06 | Node.js (for Supabase CLI dependency) | ≥18 LTS | All Engineers |
| T-07 | Git | ≥2.40 | All Engineers |

### 1.7 Flutter Project

| # | Item | Owner | Verified |
|---|------|-------|---------|
| FL-01 | `flutter pub get` passes with zero errors | Flutter Engineer | ☐ |
| FL-02 | `flutter analyze` produces zero errors on current codebase | Flutter Engineer | ☐ |
| FL-03 | App builds and runs on Android and iOS simulators | Flutter Engineer | ☐ |
| FL-04 | Riverpod 3.0.3 confirmed in `pubspec.yaml` | Flutter Engineer | ☐ |
| FL-05 | GoRouter version confirmed in `pubspec.yaml` | Flutter Engineer | ☐ |
| FL-06 | `cached_network_image` dependency confirmed in `pubspec.yaml` | Flutter Engineer | ☐ |
| FL-07 | `shared_preferences` dependency confirmed in `pubspec.yaml` | Flutter Engineer | ☐ |
| FL-08 | Existing admin portal navigation verified working (baseline smoke test) | Flutter Engineer | ☐ |

### 1.8 Pre-Sprint 1 Phase 3.8 Mandatory Finding Verification

These two findings gate Sprint 1. No migration work begins until both are signed off.

| Finding | Requirement | Sign-off |
|---------|-------------|---------|
| MF-04 | Migration M03 will include `is_evergreen BOOLEAN NOT NULL DEFAULT false`; admin review card will include evergreen toggle; `InsightReviewDto` will include `isEvergreen: bool`; `editInsight()` will PATCH `is_evergreen` | Database Eng + Flutter Eng ☐ |
| MF-06 | Migration M03 will include `reviewed_by UUID REFERENCES auth.users(id)` and `reviewed_at TIMESTAMPTZ`; all three admin action methods (approve, reject, edit) will populate both columns | Database Eng + Backend Eng ☐ |

**Sprint 1 does not begin until all of Section 1 is verified complete.**

---

## SECTION 2 — SPRINT EXECUTION PLAN

### Sprint 1 — Database & Migrations
**Branch:** `feature/insights-sprint-1-database`  
**Duration:** 8 working days  
**Objective:** All database migrations applied and verified in local Supabase dev environment; seed data loaded; schema matches Phase 3.5 specification including MF-04 and MF-06 additions; database engineer signs off on all indexes, RLS policies, and RPC.

#### Sprint 1 Objectives

1. Apply migrations M01 through M07 in sequence on local dev stack
2. Verify every table, column, index, RLS policy, and RPC matches the Phase 3.5 specification (with MF-04 and MF-06 additions)
3. Load 25-row seed data for `insights_sources`
4. Verify seed data against the Phase 3.5 §5.5 checklist
5. Confirm all migrations are idempotent (can be re-run safely)
6. Pass Gate 1 quality gate

#### Daily Work Plan

| Day | Work Items | Owner | Exit Condition |
|-----|-----------|-------|---------------|
| S1-D1 | Pre-flight: complete Section 1 checklist; create all 5 git branches; create Sprint 1 issues in tracker; run `supabase start`; verify local DB accessible | All | `supabase start` succeeds; all branches exist; all issues created |
| S1-D2 | Write and apply M01 (`insights_sources` table); verify column types, constraints, defaults; write unit test: insert valid row, verify returns cleanly | DB Engineer | M01 applied; test passes locally |
| S1-D3 | Write and apply M02 (`insights_raw` table); verify FK constraint to `insights_sources`; verify `status` enum values; write unit test: insert row with FK, test cascade behavior | DB Engineer | M02 applied; FK test passes |
| S1-D4 | Write and apply M03 (`catalyst_insights` table); **verify MF-04 column** (`is_evergreen BOOLEAN NOT NULL DEFAULT false`); **verify MF-06 columns** (`reviewed_by UUID`, `reviewed_at TIMESTAMPTZ`); verify all FK constraints | DB Engineer | M03 applied; MF-04 and MF-06 columns present; `DESCRIBE catalyst_insights` reviewed |
| S1-D5 | Write and apply M04 (V2 placeholder tables); write and apply M05 (all 13 indexes + CF-01 addition: index on `insights_raw(updated_at)`); verify each index exists with `\d+` | DB Engineer | M04 + M05 applied; all 14 indexes confirmed |
| S1-D6 | Write and apply M06 (RLS enable + all policies); test each policy: anon access to `catalyst_insights` allowed, anon access to `insights_raw` denied, service role bypasses RLS; document policy matrix | DB Engineer | M06 applied; all 6 policy tests pass |
| S1-D7 | Write and apply M07 (batch_approve_high_confidence RPC, SECURITY INVOKER); write and load seed data (25 rows); verify against Phase 3.5 §5.5 checklist (row count=25, CIGRÉ tier=2, EPRI tier=3, WEF domain, EC domain, all rows active) | DB Engineer | M07 applied; seed checklist passes all 6 checks |
| S1-D8 | Gate 1 review: full schema review against Phase 3.5 spec; run complete migration sequence from scratch on fresh local DB; open Sprint 1 PR; resolve review comments; merge | DB Engineer + Tech Lead | Gate 1 passed; PR merged to `main`; no migration drift |

#### Sprint 1 Dependencies

- Section 1 checklist complete (hard dependency — no migration work without this)
- MF-04 and MF-06 signed off before S1-D4
- `ANTHROPIC_API_KEY` procurement initiated during Sprint 1 (delivery required before Sprint 3)

#### Sprint 1 Deliverables

- Migrations M01–M07 merged to `main`
- 25-row `insights_sources` seed loaded
- Schema documentation updated (column-by-column verification against Phase 3.5 spec)
- Sprint 1 PR reviewed and merged

#### Sprint 1 Exit Criteria (Gate 1)

- All 7 migrations apply cleanly on fresh local Supabase stack in M01–M07 sequence
- Zero migration errors
- All 14 indexes confirmed
- All RLS policies verified (anon read on `catalyst_insights`, deny on others)
- `batch_approve_high_confidence` RPC callable without error
- Seed: exactly 25 rows, all `is_active = true`, all required domain values correct
- MF-04: `is_evergreen DEFAULT false` confirmed
- MF-06: `reviewed_by` and `reviewed_at` confirmed nullable, correct types
- CF-01 index on `insights_raw(updated_at)` confirmed

#### Sprint 1 Risk Checkpoints

- **Risk S1-R1:** `ANTHROPIC_API_KEY` not procured by S1-D8 → escalate to Engineering Director immediately; Sprint 3 is blocked without it
- **Risk S1-R2:** Migration sequence fails due to FK ordering → resolve by confirming M01 before M02 before M03
- **Risk S1-R3:** Supabase Pro plan not confirmed → Sprint 2 cron setup blocked; escalate immediately

---

### Sprint 2 — Backend Pipeline (Collect + Validate + Shared)
**Branch:** `feature/insights-sprint-2-pipeline`  
**Duration:** 8 working days  
**Objective:** All `_shared/` utilities implemented and tested; `collect_insight` Edge Function operational; `validate_insight` Edge Function operational with MF-01 HMAC verification; `recover_stalled_insights` cron implemented (CF-01); all three functions integration-tested end to end.

#### Sprint 2 Objectives

1. Implement all 8 `_shared/` utilities in dependency order
2. Implement `collect_insight/index.ts` with deduplication, domain validation, status=pending write
3. Implement `validate_insight/index.ts` with HMAC webhook verification (MF-01), domain check, relevance scoring, dedup check, status transition to `validated` or `rejected`
4. Implement `recover_stalled_insights/index.ts` (CF-01) — 30-min cron recovery for orphaned `validated` insights
5. Pass Gate 2 quality gate

#### Pre-Sprint 2 Mandatory Checks

Before a single line of Sprint 2 code is written:

| Check | Requirement |
|-------|-------------|
| CF-01 spec agreed | Team agrees: `recover_stalled_insights` queries `insights_raw WHERE status = 'validated' AND updated_at < now() - interval '15 minutes'` every 30 min |
| MF-01 spec agreed | Team agrees: `validate_insight` verifies `x-supabase-signature` HMAC-SHA256 header against `WEBHOOK_SECRET`; 401 on failure |
| Sprint 1 Gate 1 passed | Migration branch merged to `main` |
| `WEBHOOK_SECRET` generated and in Supabase Secrets | DevOps Lead confirmed |

#### Daily Work Plan

| Day | Work Items | Owner | Exit Condition |
|-----|-----------|-------|---------------|
| S2-D1 | Create Sprint 2 issues; implement `_shared/types.ts` (all shared TypeScript interfaces — InsightRaw, InsightSource, ValidationResult, EnrichmentResult, PipelineStatus enum); unit test: import types, verify no TS errors | Backend Engineer | types.ts compiles; types importable |
| S2-D2 | Implement `_shared/logger.ts` (structured JSON logger with levels INFO/WARN/ERROR, timestamp, function_name, execution_id fields per Phase 3.8 observability spec); implement `_shared/supabase_client.ts` (singleton Supabase client from SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY env vars); unit tests for both | Backend Engineer | Logger outputs correct JSON structure; client initialises without error |
| S2-D3 | Implement `_shared/fingerprint.ts` (SHA-256 fingerprint of normalized URL for deduplication); implement `_shared/url_utils.ts` (URL normalization: strip UTM params, trailing slashes, fragment identifiers); unit tests: known URL → known fingerprint; UTM stripping verified | Backend Engineer | fingerprint test vectors pass; URL normalization test vectors pass |
| S2-D4 | Implement `_shared/og_extractor.ts` (fetch URL, parse Open Graph meta tags: title, description, image, published_time); implement `_shared/domain_validator.ts` (check submitted domain against `insights_sources.approved_domain` — including sub-path matching for WEF and EC domains) | Backend Engineer | OG extraction from test URL returns correct fields; domain validator correctly handles sub-path domains |
| S2-D5 | Implement `_shared/keyword_scorer.ts` (keyword relevance scoring: count energy/grid keyword hits in title+description, return normalized 0.0–1.0 score); write comprehensive unit tests against Phase 2 validated source categories | Backend Engineer | Keyword scorer test suite passes all 15+ test cases |
| S2-D6 | Implement `collect_insight/index.ts`: receive POST with article URL, check domain against `insights_sources`, generate SHA-256 fingerprint, check `insights_raw` for existing fingerprint (dedup), write row with `status=pending`, emit `collect_insight.queued` log event; **test: full round trip submission** | Backend Engineer | Submission creates `insights_raw` row with `status=pending`; duplicate submission returns 409; unknown domain returns 400 |
| S2-D7 | Implement `validate_insight/` (3 files): `validation.ts` (relevance threshold ≥0.3, domain check, format check), `dedup.ts` (fingerprint collision check against `catalyst_insights`), `index.ts` (HMAC-SHA256 signature verify using `WEBHOOK_SECRET` header MF-01, orchestrate validation, transition status to `validated` or `rejected`, emit log events); implement `recover_stalled_insights/index.ts` (CF-01: query insights_raw status=validated AND updated_at older than 15 min, re-invoke enrich_insight, log recovered_count) | Backend Engineer | validate_insight: valid webhook with correct signature succeeds; tampered signature returns 401; low-relevance article transitions to `rejected`; high-relevance transitions to `validated`. recover_stalled: no-op when queue empty; recovers row when stuck >15min |
| S2-D8 | Register `recover_stalled_insights` as cron job (every 30 min: `*/30 * * * *`); end-to-end integration test: submit article → validate → check `validated` status; Gate 2 review; open Sprint 2 PR | Backend Engineer + Tech Lead | Cron registered; E2E test passes; Gate 2 passed; PR merged |

#### Sprint 2 Dependencies

- Gate 1 passed and Sprint 1 branch merged (hard dependency)
- `WEBHOOK_SECRET` in Supabase Secrets (hard dependency for MF-01)
- `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in Supabase Secrets

#### Sprint 2 Deliverables

- All 8 `_shared/` utilities implemented and unit tested
- `collect_insight` Edge Function deployed and integration tested
- `validate_insight` Edge Function with HMAC verification deployed
- `recover_stalled_insights` cron registered and verified
- Sprint 2 PR reviewed and merged

#### Sprint 2 Exit Criteria (Gate 2)

- All 8 `_shared/` utility unit tests pass
- `collect_insight`: valid submission creates row; duplicate returns 409; unknown domain returns 400
- `validate_insight`: correct HMAC → processes; incorrect HMAC → 401; no HMAC header → 401 (MF-01 verified)
- `validate_insight`: relevance <0.3 → `rejected`; relevance ≥0.3 + valid domain → `validated`
- `recover_stalled_insights`: verifiably picks up insights stuck in `validated` >15 min
- CF-01 cron registered at `*/30 * * * *` schedule
- Zero `console.log` statements (all logging through `_shared/logger.ts`)
- No environment variables hardcoded in source
- All log events emitted: `collect_insight.queued`, `collect_insight.duplicate`, `collect_insight.rejected`, `validate_insight.result`, `validate_insight.relevance`, `validate_insight.dedup`

#### Sprint 2 Risk Checkpoints

- **Risk S2-R1:** `ANTHROPIC_API_KEY` still not procured by end of S2 → Sprint 3 blocked; escalate immediately
- **Risk S2-R2:** Webhook signature verification incorrect → verify test vector against Supabase webhook documentation
- **Risk S2-R3:** OG extraction fails for paywalled sources → implement graceful fallback; article title from URL domain + path; do not fail the pipeline

---

### Sprint 3 — AI Enrichment Pipeline
**Branch:** `feature/insights-sprint-3-enrichment`  
**Duration:** 5 working days  
**Objective:** `enrich_insight` Edge Function operational with Anthropic API integration, prompt injection defenses (MF-07), image dimension validation (MF-05), and WebP mirroring; `activate_scheduled_insights` and `expire_old_insights` schedulers implemented and crons registered; full pipeline (collect → validate → enrich → active) verified end to end.

#### Pre-Sprint 3 Mandatory Checks

| Check | Requirement |
|-------|-------------|
| MF-05 spec agreed | Team agrees: binary header parsing approach for JPEG (SOF0/SOF2 markers), PNG (IHDR chunk bytes 16–23), WebP (VP8X header bytes 24–31); unknown format = fail-open |
| MF-07 spec agreed | Team agrees: input sanitization (strip `<INST>`, `[INST]`, `<system>` prefixes from article content before AI prompt); output anomaly detection (flag if AI summary begins with "Ignore", "Disregard", "Instead", "Actually" → set confidence = 0.0) |
| Gate 2 passed | Sprint 2 branch merged to `main` |
| `ANTHROPIC_API_KEY` confirmed in Supabase Secrets | Backend Engineer confirmed |

#### Daily Work Plan

| Day | Work Items | Owner | Exit Condition |
|-----|-----------|-------|---------------|
| S3-D1 | Implement `enrich_insight/ai_prompt.ts`: construct structured JSON prompt for `claude-haiku-4-5-20251001`; **implement MF-07 input sanitization** (strip injection prefixes before prompt construction); **implement MF-07 output anomaly detection** (check first word of ai_summary, set confidence=0.0 if anomaly detected); implement `enrich_insight/image_validator.ts`: **MF-05 binary header parsing** for JPEG/PNG/WebP dimension extraction; 400×200px minimum validation; fail-open for unknown formats | Backend Engineer | Sanitization strips `<INST>` correctly; output anomaly detector catches "Ignore..." prefix; JPEG/PNG/WebP dimension parsing returns correct width/height from binary |
| S3-D2 | Implement `enrich_insight/ai_client.ts`: Anthropic SDK invocation with `claude-haiku-4-5-20251001`; temperature=0; max_tokens=1024; **per-attempt timeout 25 seconds** (not 30 — Phase 3.8 correction); retry logic: 3 attempts, exponential backoff (2s, 4s, 8s); structured JSON response parsing | Backend Engineer | Client invokes Anthropic API successfully; 25s timeout enforced; 3-retry cycle verifiable |
| S3-D3 | Implement `enrich_insight/enrichment.ts`: orchestrate AI prompt, parse response into InsightEnrichment type (ai_summary, ai_why_matters, ai_key_takeaway, ai_tags, category, confidence_score, reading_time_minutes); implement `enrich_insight/index.ts`: receive trigger (from validate_insight), fetch raw insight, call enrichment, call image_validator, update `insights_raw` with enrichment fields + `status=ai_processed`, emit log events | Backend Engineer | Enrichment round-trip produces all 8 AI fields; status transitions from `validated` → `ai_processed`; `enrich_insight.complete` log emitted |
| S3-D4 | Implement `mirror_insight_image/index.ts`: fetch source image URL, validate binary headers (reuse image_validator), reject if <400×200px, store in `insights-images/insights/{id}/hero.jpg`, update `hero_image_url` with CDN URL (`{SUPABASE_URL}/storage/v1/object/public/insights-images/insights/{id}/hero.jpg?width=1200&quality=85&format=webp`); implement `activate_scheduled_insights/index.ts`: query `catalyst_insights WHERE status='scheduled' AND scheduled_for <= now()`, transition to `active`, emit log; implement `expire_old_insights/index.ts`: query active insights older than 30 days (excluding is_evergreen=true), transition to `archived`, sample 10% for HEAD check (is_link_verified) | Backend Engineer | Image mirror stores file and writes CDN URL; activation cron promotes scheduled→active correctly; expiry cron archives old insights, correctly skips evergreen |
| S3-D5 | Register crons: `activate_scheduled_insights` every 15 min (`0/15 * * * *`); `expire_old_insights` daily 02:00 UTC (`0 2 * * *`); confirm `recover_stalled_insights` still active; full pipeline E2E test: submit URL → validate → enrich → mirror image → check ai_processed → schedule → activate; Gate 3 review; open Sprint 3 PR | Backend Engineer + Tech Lead | All 3 crons registered and active; full pipeline E2E passes; ai_processed row contains all 8 AI fields; Gate 3 passed; PR merged |

#### Sprint 3 Dependencies

- Gate 2 passed and Sprint 2 branch merged (hard dependency)
- `ANTHROPIC_API_KEY` confirmed accessible from Edge Functions (hard dependency)
- `insights-images` Storage bucket exists with public access (Sprint 1 prerequisite)

#### Sprint 3 Deliverables

- `enrich_insight` Edge Function with MF-05 and MF-07 implementations
- `mirror_insight_image` subroutine
- `activate_scheduled_insights` and `expire_old_insights` schedulers
- All 3 cron schedules registered
- Full pipeline integration test passing

#### Sprint 3 Exit Criteria (Gate 3)

- Full pipeline E2E test passes: `pending → validated → ai_processed → scheduled/active`
- AI enrichment produces all 8 fields: `ai_summary`, `ai_why_matters`, `ai_key_takeaway`, `ai_tags`, `category`, `confidence_score`, `reading_time_minutes`, `is_ai_generated`
- MF-07: test case "article with `<INST>` prefix" → sanitization strips it; test case "AI returns 'Ignore previous instructions'" → confidence_score = 0.0
- MF-05: 300×100px test image → rejected; 400×200px test image → accepted; unknown format → fail-open accepted
- Per-attempt timeout is 25s (verified by timing test against slow mock)
- All 5 log events emitted: `enrich_insight.ai_call`, `enrich_insight.image_mirror`, `enrich_insight.complete`, `enrich_insight.ai_error`, `activate_scheduled.run`, `expire_insights.run`
- `is_evergreen=true` insights survive `expire_old_insights` run
- CDN URL format matches: `{SUPABASE_URL}/storage/v1/object/public/insights-images/insights/{id}/hero.jpg?width=1200&quality=85&format=webp`
- Batch approve (`batch_approve_high_confidence` RPC) disabled — DO NOT call it. Phase 3.8 mandate: disable for first 4 weeks of production until confidence reliability is empirically validated.

#### Sprint 3 Risk Checkpoints

- **Risk S3-R1:** Anthropic API rate limit hit during testing → use a single test article; do not run bulk tests; track token spend
- **Risk S3-R2:** AI response fails JSON structure validation → implement fallback: status=`ai_error`, emit error log; insight goes to admin review queue
- **Risk S3-R3:** Image binary parsing fails for edge-case headers → fail-open per MF-05 spec; log WARN; do not block pipeline

---

### Sprint 4 — Flutter Feature + Admin Portal
**Branch:** `feature/insights-sprint-4-flutter` (primary)  
**Branch:** `feature/insights-sprint-4-nav` (GoRouter wiring, created Sprint 4 Day 6)  
**Duration:** 8 working days  
**Objective:** Complete Flutter implementation — data layer, state layer, feed UI, admin extensions including MF-03 ai_error screen, and GoRouter navigation wiring — integrated with live Supabase backend.

#### Pre-Sprint 4 Mandatory Checks

| Check | Requirement |
|-------|-------------|
| MF-03 spec agreed | Team agrees: `InsightsAdminRepository.fetchAiErrorQueue()` + `retryEnrichment({required String rawId})` + `InsightsAiErrorScreen` (third tab in `InsightsAdminScreen`) + `ai_error_count` in `PipelineHealth` type |
| Gate 3 passed | Sprint 3 branch merged to `main`; full pipeline verified |
| Supabase URL accessible from Flutter | Verified in Supabase settings |

#### Daily Work Plan

| Day | Work Items | Owner | Exit Condition |
|-----|-----------|-------|---------------|
| S4-D1 | Implement data layer: `InsightDto` (14 fields from PostgREST), `InsightReviewDto` (including `isEvergreen: bool` — MF-04), `InsightsError` sealed class; implement `InsightsRepository` interface; no Supabase calls in this step — interfaces only | Flutter Engineer | All DTOs compile; `InsightDto` has all 14 fields; `InsightReviewDto` includes `isEvergreen` |
| S4-D2 | Implement `InsightsRepository` concrete class: `fetchFeed({required int page})` — PostgREST query on `catalyst_insights WHERE status=active ORDER BY published_at DESC` with LIMIT 10 OFFSET page×10; `fetchById({required String id})`; `markRead({required String id})`; `toggleBookmark({required String id, required bool value})`; SharedPreferences cache (page 0, 60-min TTL, `_v1` key suffix) | Flutter Engineer | `fetchFeed(page: 0)` returns list of InsightDto; cache write/read/invalidation verified |
| S4-D3 | Implement `InsightsState` (8 fields: insights, isLoading, isFetchingMore, hasMore, currentPage, lastFetchedAt, error, isOffline); implement `InsightsNotifier` as `Notifier<InsightsState>` (NOT AsyncNotifier); implement `loadFeed()`, `fetchMore()` with pre-fetch trigger at `index >= state.insights.length - 2`, `refreshFeed()`, `markRead()`, `toggleBookmark()`; implement `InsightsProvider` as `NotifierProvider` (lazy) | Flutter Engineer | `loadFeed()` populates state; `fetchMore()` appends; pre-fetch trigger fires at correct index; cache-first verified |
| S4-D4 | Implement `InsightCard` widget: full-screen (height = MediaQuery.of(context).size.height), category color background (6-color map from Phase 3.8), hero image with `CachedNetworkImage` (`memCacheWidth: 1200, memCacheHeight: 900` — mf-02), headline, summary, why-it-matters, key-takeaway, source chip, reading time, bookmark icon; implement `InsightFeedPage`: `PageView.builder` vertically scrollable; read-on-scroll trigger | Flutter Engineer | InsightCard renders all fields; CachedNetworkImage uses correct memory constraints; vertical swipe advances card |
| S4-D5 | Implement admin extensions: `InsightsAdminRepository` with `fetchReviewQueue()`, `approveInsight()`, `rejectInsight()`, `editInsight()`, `fetchPipelineHealth()`, **`fetchAiErrorQueue()` (MF-03)**, **`retryEnrichment()` (MF-03)**; all approve/reject/edit calls include `reviewed_by` (current user id) and `reviewed_at` (now()) — MF-06; implement `InsightsReviewCard` with evergreen toggle (MF-04); implement `PipelineHealthCard`; implement **`InsightsAiErrorScreen`** (third tab — MF-03) | Flutter Engineer | Review queue loads; approve/reject transitions status; ai_error tab shows backlog count; retry triggers Edge Function; evergreen toggle updates `is_evergreen` |
| S4-D6 | **Create branch `feature/insights-sprint-4-nav` from `feature/insights-sprint-4-flutter`**; implement GoRouter `ShellRoute` for Insights tab: root path `/insights`, sub-paths `/insights/detail/:id`; add tab entry to existing bottom nav shell; verify existing app tabs still navigate correctly (regression check) | Flutter Engineer | `/insights` route renders `InsightFeedPage`; `/insights/detail/:id` renders single card detail; existing tabs unaffected |
| S4-D7 | Integration testing on device/simulator: load feed → swipe cards → mark read → bookmark → admin review → approve → verify insight goes active; load cached feed offline; force cache expiry and verify stale banner; ai_error queue → retry → verify edge function called; submit via admin → full pipeline round trip | Flutter Engineer + QA Lead | All 8 integration test scenarios pass; no regression in existing app features |
| S4-D8 | Gate 4 final review; resolve all open PR comments; performance check (cold start <2s P95 on network; <500ms P95 from cache); merge `feature/insights-sprint-4-nav` into `feature/insights-sprint-4-flutter`; open Sprint 4 PR to `main`; complete go-live checklist | Flutter Eng + Tech Lead | Gate 4 passed; performance SLOs met; Sprint 4 PR merged; go-live checklist complete |

#### Sprint 4 Dependencies

- Gate 3 passed and Sprint 3 branch merged (hard dependency)
- Live Supabase backend with active insights in database (at least 10 rows for testing)
- `insights_sources` seed loaded

#### Sprint 4 Deliverables

- Complete Flutter Insights feature (data layer + state + UI)
- Admin portal extensions (review queue, pipeline health, ai_error screen — MF-03)
- GoRouter integration (isolated in sprint-4-nav branch)
- Full integration test suite passing on device
- Sprint 4 PR reviewed and merged

#### Sprint 4 Exit Criteria (Gate 4)

- `InsightFeedPage` loads and vertically swipes through insights
- Pre-fetch fires at correct index (length - 2)
- Cache-first load works; stale banner appears after 60 min
- Offline mode: cached page 0 loads; error state shown for network failure
- `CachedNetworkImage` uses `memCacheWidth` and `memCacheHeight` (mf-02 verified)
- Admin review queue: approve, reject, and edit all function
- MF-03: `InsightsAiErrorScreen` accessible as third admin tab; retry button calls `retryEnrichment()`
- MF-04: Evergreen toggle visible in review card; persists correctly
- MF-06: `reviewed_by` and `reviewed_at` populated on every admin action
- GoRouter integration: `/insights` and `/insights/detail/:id` routes work; no regression in existing routes
- Performance: first load from cache <500ms P95; from network <2s P95; PostgREST query <50ms P95
- `flutter analyze` produces zero errors
- All existing app smoke tests still pass

#### Sprint 4 Risk Checkpoints

- **Risk S4-R1:** GoRouter `ShellRoute` conflict with existing navigation — isolated to `sprint-4-nav` branch; if conflict unresolvable in 1 day, defer navigation wiring and deliver feature as standalone route
- **Risk S4-R2:** `InsightsState.copyWith` ambiguity — must confirm Freezed vs manual implementation; Freezed preferred; if Freezed, run `dart run build_runner build` before state layer coding
- **Risk S4-R3:** `memCacheWidth` / `memCacheHeight` not available in installed version of `cached_network_image` — verify package version; update if needed

---

## SECTION 3 — TASK BREAKDOWN

### Sprint 1 Tasks

| Task ID | Description | Owner | Dependencies | Expected Output | Verification |
|---------|-------------|-------|-------------|-----------------|-------------|
| S1-OPS-001 | Complete Section 1 pre-flight checklist | DevOps Lead | None | All 40+ checklist items checked | Checklist document signed off |
| S1-OPS-002 | Create all 5 git branches from main | Tech Lead | S1-OPS-001 | 5 branches in remote | `git branch -a` shows all 5 |
| S1-OPS-003 | Create Sprint 1 issues in tracker | Engineering Director | S1-OPS-002 | All S1 tasks as issues with sprint-1 label | Issue tracker shows Sprint 1 board |
| S1-DB-001 | Apply migration M01 — `insights_sources` | DB Engineer | S1-OPS-001 | Table created with all columns and constraints | `\d insights_sources` matches Phase 3.5 spec |
| S1-DB-002 | Apply migration M02 — `insights_raw` | DB Engineer | S1-DB-001 | Table created with FK to `insights_sources`, status enum | `\d insights_raw` matches spec; FK constraint verified |
| S1-DB-003 | Apply migration M03 — `catalyst_insights` with MF-04 and MF-06 | DB Engineer | S1-DB-002 | Table with `is_evergreen DEFAULT false`, `reviewed_by UUID`, `reviewed_at TIMESTAMPTZ` | `\d catalyst_insights` shows all 3 new columns |
| S1-DB-004 | Apply migration M04 — V2 placeholder tables | DB Engineer | S1-DB-003 | Empty V2 tables exist | `\dt` shows V2 tables |
| S1-DB-005 | Apply migration M05 — all 14 indexes (13 original + CF-01 `insights_raw.updated_at`) | DB Engineer | S1-DB-004 | All 14 indexes present | `\di` shows all indexes by name |
| S1-DB-006 | Apply migration M06 — RLS enable + all policies | DB Engineer | S1-DB-005 | RLS enabled; anon policy on `catalyst_insights`; deny policies on `insights_raw` | Anon PostgREST call to `catalyst_insights` succeeds; call to `insights_raw` returns 403 |
| S1-DB-007 | Apply migration M07 — `batch_approve_high_confidence` RPC | DB Engineer | S1-DB-006 | RPC callable from service role | `SELECT batch_approve_high_confidence(0.85)` returns without error |
| S1-DB-008 | Load seed data — 25 `insights_sources` rows | DB Engineer | S1-DB-007 | 25 rows in table | `SELECT COUNT(*) FROM insights_sources` = 25 |
| S1-DB-009 | Verify seed against Phase 3.5 §5.5 checklist | DB Engineer + Tech Lead | S1-DB-008 | All 6 checklist items pass | Written verification: CIGRÉ tier=2, EPRI tier=3, WEF domain, EC domain, all active |
| S1-QA-001 | Write migration regression test: apply all 7 migrations from scratch, verify final schema | QA Lead | S1-DB-009 | Test passes on fresh DB | `supabase db reset && supabase db push` exits clean |
| S1-QA-002 | RLS policy test matrix: 6 tests covering anon/service-role × 3 tables | QA Lead | S1-DB-006 | All 6 tests pass | Test results document |

### Sprint 2 Tasks

| Task ID | Description | Owner | Dependencies | Expected Output | Verification |
|---------|-------------|-------|-------------|-----------------|-------------|
| S2-BE-001 | Implement `_shared/types.ts` | Backend Engineer | Gate 1 | All shared TS interfaces | Deno type-check passes |
| S2-BE-002 | Implement `_shared/logger.ts` | Backend Engineer | S2-BE-001 | Structured JSON logger | Logger output matches Phase 3.8 log event schema |
| S2-BE-003 | Implement `_shared/supabase_client.ts` | Backend Engineer | S2-BE-001 | Supabase singleton client | Client initialises; insert test row succeeds |
| S2-BE-004 | Implement `_shared/fingerprint.ts` | Backend Engineer | S2-BE-001 | SHA-256 URL fingerprint | Known URL → known hash (test vector) |
| S2-BE-005 | Implement `_shared/url_utils.ts` | Backend Engineer | None | URL normalizer | UTM params stripped; trailing slash removed |
| S2-BE-006 | Implement `_shared/og_extractor.ts` | Backend Engineer | S2-BE-001, S2-BE-005 | OG meta tag parser | Test URL returns title, description, image |
| S2-BE-007 | Implement `_shared/domain_validator.ts` | Backend Engineer | S2-BE-001 | Domain allow-list checker | WEF sub-path match; EC sub-path match; unknown domain rejected |
| S2-BE-008 | Implement `_shared/keyword_scorer.ts` | Backend Engineer | None | Energy keyword relevance scorer | Score ≥ 0.3 for energy-adjacent article; < 0.3 for off-topic |
| S2-BE-009 | Implement `collect_insight/index.ts` | Backend Engineer | S2-BE-001 through S2-BE-008 | Article submission endpoint | Valid URL creates `insights_raw` row with `status=pending` |
| S2-BE-010 | Implement `validate_insight/validation.ts` | Backend Engineer | S2-BE-007, S2-BE-008 | Validation logic | Threshold checks produce correct ValidatedResult |
| S2-BE-011 | Implement `validate_insight/dedup.ts` | Backend Engineer | S2-BE-004 | Fingerprint dedup check | Duplicate fingerprint → `isDuplicate=true` |
| S2-BE-012 | Implement `validate_insight/index.ts` with MF-01 HMAC | Backend Engineer | S2-BE-010, S2-BE-011 | Webhook handler with HMAC verification | Valid signature processes; tampered signature → 401 |
| S2-SEC-001 | Verify HMAC test: correct secret, incorrect secret, missing header (MF-01) | Backend Engineer | S2-BE-012 | 3 test cases documented and passing | Test results: 200, 401, 401 respectively |
| S2-BE-013 | Implement `recover_stalled_insights/index.ts` (CF-01) | Backend Engineer | S2-BE-002, S2-BE-003 | 30-min recovery cron | Stalled `validated` insight recovered within 30 min |
| S2-OPS-001 | Register `recover_stalled_insights` cron (`*/30 * * * *`) | DevOps Lead | S2-BE-013 | Cron active in Supabase | Cron visible in Supabase Dashboard → Edge Functions |
| S2-QA-001 | E2E pipeline test: submit → validate → check `validated` status | QA Lead | S2-BE-012 | Full test documented | `insights_raw.status = 'validated'` after test run |
| S2-QA-002 | CF-01 integration test: force insight to `validated` status; wait >15 min; verify recovery | QA Lead | S2-OPS-001 | Recovery confirmed | `recovered_count > 0` in cron logs |

### Sprint 3 Tasks

| Task ID | Description | Owner | Dependencies | Expected Output | Verification |
|---------|-------------|-------|-------------|-----------------|-------------|
| S3-AI-001 | Implement `enrich_insight/ai_prompt.ts` with MF-07 input sanitization | Backend Engineer | Gate 2 | Prompt builder with injection stripping | `<INST>` prefix stripped from article content in prompt |
| S3-AI-002 | Implement MF-07 output anomaly detection | Backend Engineer | S3-AI-001 | Anomaly detector function | "Ignore..." summary → confidence = 0.0 |
| S3-AI-003 | Implement `enrich_insight/image_validator.ts` — MF-05 binary header parsing | Backend Engineer | None | Dimension extractor | JPEG SOF markers, PNG IHDR, WebP VP8X all return correct dimensions |
| S3-AI-004 | Implement `enrich_insight/ai_client.ts` — Anthropic SDK, 25s timeout, 3-retry | Backend Engineer | S3-AI-001 | AI invocation client | 25s timeout enforced; retry cycle correct |
| S3-AI-005 | Implement `enrich_insight/enrichment.ts` — orchestrate AI + parse response | Backend Engineer | S3-AI-001, S3-AI-002, S3-AI-004 | Enrichment orchestrator | All 8 AI fields populated from response |
| S3-AI-006 | Implement `enrich_insight/index.ts` — trigger, fetch raw, enrich, update, log | Backend Engineer | S3-AI-005, S3-AI-003 | Edge Function entry point | Status transitions `validated → ai_processed` |
| S3-AI-007 | Implement `mirror_insight_image/index.ts` — fetch, validate dimensions, store, write CDN URL | Backend Engineer | S3-AI-003 | Image mirror subroutine | CDN URL written to `hero_image_url`; WebP params appended |
| S3-AI-008 | Implement `activate_scheduled_insights/index.ts` | Backend Engineer | Gate 2 | Scheduler: scheduled → active | Insight with `scheduled_for <= now()` transitions to `active` |
| S3-AI-009 | Implement `expire_old_insights/index.ts` with is_evergreen guard | Backend Engineer | Gate 2 | Scheduler: active → archived | is_evergreen=true insight survives; old insight archived |
| S3-OPS-001 | Register `activate_scheduled_insights` cron (`0/15 * * * *`) | DevOps Lead | S3-AI-008 | Cron active | Cron visible in dashboard |
| S3-OPS-002 | Register `expire_old_insights` cron (`0 2 * * *`) | DevOps Lead | S3-AI-009 | Cron active | Cron visible in dashboard |
| S3-QA-001 | Full pipeline E2E: submit → validate → enrich → image mirror → activate | QA Lead | S3-AI-006, S3-AI-007, S3-OPS-001 | Complete flow documented | Final status = `active`; all AI fields present; CDN URL populated |
| S3-QA-002 | MF-07 injection test: article with `<INST>` prefix; article with "Ignore..." AI output | QA Lead | S3-AI-002 | Injection defenses verified | confidence = 0.0 on anomaly detection |
| S3-QA-003 | MF-05 dimension test: 300×100px image; 400×200px image; unknown format file | QA Lead | S3-AI-003 | All 3 test cases pass | Under-size rejected; minimum accepted; unknown = fail-open |

### Sprint 4 Tasks

| Task ID | Description | Owner | Dependencies | Expected Output | Verification |
|---------|-------------|-------|-------------|-----------------|-------------|
| S4-FL-001 | Implement `InsightDto` — 14 fields, PostgREST field mapping | Flutter Engineer | Gate 3 | Dart model class | fromJson maps all 14 fields including renamed fields (ai_summary → summary) |
| S4-FL-002 | Implement `InsightReviewDto` — including `isEvergreen: bool` (MF-04) | Flutter Engineer | S4-FL-001 | Dart review DTO | `isEvergreen` field present; maps to `is_evergreen` |
| S4-FL-003 | Implement `InsightsError` sealed class (7 cases) | Flutter Engineer | None | Error type hierarchy | All 7 error cases available |
| S4-FL-004 | Implement `InsightsRepository` interface | Flutter Engineer | S4-FL-001, S4-FL-003 | Abstract repository | Interface defines all 6 methods |
| S4-FL-005 | Implement `InsightsRepository` concrete — PostgREST + SharedPreferences cache | Flutter Engineer | S4-FL-004 | Working repository | `fetchFeed(page:0)` returns DTOs; cache write/read verified |
| S4-FL-006 | Implement `InsightsState` (8 fields) | Flutter Engineer | S4-FL-001 | State class with copyWith | All 8 fields present; copyWith works correctly (mf-01: Freezed or manual) |
| S4-FL-007 | Implement `InsightsNotifier` as `Notifier<InsightsState>` | Flutter Engineer | S4-FL-005, S4-FL-006 | State notifier | loadFeed populates state; fetchMore appends; pre-fetch at length-2 |
| S4-FL-008 | Implement `InsightsProvider` as `NotifierProvider` (lazy) | Flutter Engineer | S4-FL-007 | Riverpod provider | Provider accessible from widget tree |
| S4-FL-009 | Implement `InsightCard` widget — full-screen, category colors, CachedNetworkImage with memCache | Flutter Engineer | S4-FL-001, S4-FL-008 | Widget renders | Card shows all fields; image uses `memCacheWidth: 1200, memCacheHeight: 900` |
| S4-FL-010 | Implement `InsightFeedPage` — vertical `PageView.builder` | Flutter Engineer | S4-FL-009 | Feed page | Swipe advances card; pre-fetch fires; cache-first verified |
| S4-AD-001 | Implement `InsightsAdminRepository` — full admin method suite | Flutter Engineer | S4-FL-005 | Admin repository | All 8 methods implemented including MF-03 methods |
| S4-AD-002 | Verify MF-06: approve/reject/edit all include `reviewed_by` + `reviewed_at` | Flutter Engineer | S4-AD-001 | PATCH calls verified | Supabase logs show `reviewed_by` and `reviewed_at` populated |
| S4-AD-003 | Implement `InsightsReviewCard` with evergreen toggle (MF-04) | Flutter Engineer | S4-AD-001 | Review card widget | Toggle visible; PATCH updates `is_evergreen` |
| S4-AD-004 | Implement `PipelineHealthCard` | Flutter Engineer | S4-AD-001 | Health card widget | Shows all 6 pipeline health metrics |
| S4-AD-005 | Implement `InsightsAiErrorScreen` (MF-03) — third tab in admin | Flutter Engineer | S4-AD-001 | AI error management screen | ai_error queue loads; retry button calls `retryEnrichment()` |
| S4-AD-006 | Integrate admin screens into `InsightsAdminScreen` (3-tab layout) | Flutter Engineer | S4-AD-003, S4-AD-004, S4-AD-005 | Admin tabbed screen | All 3 tabs accessible |
| S4-NAV-001 | Create branch `feature/insights-sprint-4-nav`; implement GoRouter `ShellRoute` for Insights | Flutter Engineer | S4-FL-010, S4-AD-006 | Navigation wiring | `/insights` and `/insights/detail/:id` routes work |
| S4-NAV-002 | Regression test: all existing app routes still navigate correctly | Flutter Engineer + QA Lead | S4-NAV-001 | Zero regressions | Existing tab navigation unaffected |
| S4-QA-001 | Integration test suite (8 scenarios) on device/simulator | QA Lead | S4-NAV-002 | All 8 scenarios pass | Test results document |
| S4-QA-002 | Performance check: cold start timing, PostgREST query timing | QA Lead | S4-QA-001 | SLO results documented | Meets Phase 3.8 SLOs |

---

## SECTION 4 — ENGINEERING CHECKLISTS

### 4.1 Database Checklist

Before Sprint 1 PR is opened:

- [ ] All 7 migrations apply on fresh local Supabase stack in sequence
- [ ] All 7 migrations apply cleanly after `supabase db reset` (idempotency via Supabase migration versioning)
- [ ] `insights_sources` table: all columns present, correct types, `is_active DEFAULT true`
- [ ] `insights_raw` table: FK to `insights_sources`, status enum contains all 10 values, `fingerprint` column unique index
- [ ] `catalyst_insights` table: FK to `insights_sources`, FK to `insights_raw`, `is_evergreen DEFAULT false` (MF-04), `reviewed_by UUID NULL`, `reviewed_at TIMESTAMPTZ NULL` (MF-06)
- [ ] V2 placeholder tables exist and are empty
- [ ] All 14 indexes present by name (13 original + CF-01 `insights_raw.updated_at`)
- [ ] RLS enabled on all 6 tables
- [ ] Anon policy on `catalyst_insights` (SELECT active insights only)
- [ ] Deny-all for anon on `insights_raw`, `insights_sources` (write tables)
- [ ] `batch_approve_high_confidence` RPC created with SECURITY INVOKER
- [ ] Seed: exactly 25 rows, all `is_active = true`
- [ ] Seed: CIGRÉ `tier = 2`; EPRI `tier = 3`
- [ ] Seed: WEF `approved_domain = 'weforum.org/agenda/energy'`
- [ ] Seed: EC `approved_domain = 'ec.europa.eu/energy'`

### 4.2 Backend Checklist

Before Sprint 2 PR is opened:

- [ ] All 8 `_shared/` utilities created in dependency order (types → logger → supabase_client → fingerprint → url_utils → og_extractor → domain_validator → keyword_scorer)
- [ ] No `console.log` in any file — all logging via `_shared/logger.ts`
- [ ] No hardcoded URLs, keys, or secrets in any file
- [ ] `collect_insight`: accepts POST, validates domain, deduplicates, writes `status=pending`
- [ ] `validate_insight`: verifies HMAC-SHA256 `x-supabase-signature` header (MF-01); 401 on failure
- [ ] `validate_insight`: transitions to `validated` (score ≥ 0.3 + valid domain) or `rejected`
- [ ] `recover_stalled_insights`: recovers insights in `validated` status for > 15 minutes (CF-01)
- [ ] All cron jobs registered: `recover_stalled_insights` at `*/30 * * * *`
- [ ] All Edge Functions handle CORS correctly
- [ ] All Edge Functions return structured error responses (never raw exceptions)

Before Sprint 3 PR is opened:

- [ ] `enrich_insight`: input sanitization strips `<INST>`, `[INST]`, `<system>` (MF-07)
- [ ] `enrich_insight`: output anomaly detection sets confidence = 0.0 for injection responses (MF-07)
- [ ] `enrich_insight`: per-attempt timeout is 25 seconds (NOT 30)
- [ ] `enrich_insight`: retry count = 3; exponential backoff 2s, 4s, 8s
- [ ] `enrich_insight`: on 3 consecutive failures, transitions status to `ai_error`
- [ ] `mirror_insight_image`: binary header parsing for JPEG/PNG/WebP (MF-05)
- [ ] `mirror_insight_image`: rejects images < 400×200px; fail-open for unknown format
- [ ] `mirror_insight_image`: CDN URL includes WebP transform params (`?width=1200&quality=85&format=webp`)
- [ ] `activate_scheduled_insights`: cron registered at `0/15 * * * *`
- [ ] `expire_old_insights`: cron registered at `0 2 * * *`; is_evergreen=true insights excluded from archival
- [ ] All observability log events emitted per Phase 3.8 specification
- [ ] Batch approve (`batch_approve_high_confidence`) NOT called — deferred 4 weeks post-launch

### 4.3 Flutter Checklist

Before Sprint 4 PR is opened:

- [ ] `InsightDto` has all 14 fields with correct PostgREST field mapping
- [ ] `InsightReviewDto` includes `isEvergreen: bool` (MF-04)
- [ ] `InsightsState` has all 8 fields; `copyWith` implemented (Freezed or manual — mf-01)
- [ ] `InsightsNotifier` is `Notifier<InsightsState>` (NOT `AsyncNotifier`)
- [ ] `InsightsProvider` is `NotifierProvider` (lazy)
- [ ] `InsightsRepository` is the sole Supabase access point — no screen touches Supabase client directly
- [ ] Pre-fetch triggers at `index >= state.insights.length - 2`
- [ ] SharedPreferences cache: page 0 only, 60-min TTL, `_v1` versioned keys
- [ ] Stale cache banner shown when serving expired cache
- [ ] Offline mode: cache serves; error state shown when no cache
- [ ] `CachedNetworkImage` uses `memCacheWidth: 1200, memCacheHeight: 900` (mf-02)
- [ ] Category color map applied correctly (6 categories × 6 colors)
- [ ] `flutter analyze` produces zero errors
- [ ] `flutter build apk --debug` and `flutter build ios --debug` succeed without warnings

### 4.4 Admin Portal Checklist

Before Sprint 4 PR is opened:

- [ ] `InsightsAdminRepository`: `fetchReviewQueue()`, `approveInsight()`, `rejectInsight()`, `editInsight()`, `fetchPipelineHealth()`
- [ ] `InsightsAdminRepository`: `fetchAiErrorQueue()` and `retryEnrichment()` implemented (MF-03)
- [ ] All admin write actions include `reviewed_by: currentUser.id` and `reviewed_at: DateTime.now()` (MF-06)
- [ ] `InsightsReviewCard`: evergreen toggle visible; PATCH updates `is_evergreen` (MF-04)
- [ ] `InsightsAiErrorScreen`: accessible as third tab in `InsightsAdminScreen` (MF-03)
- [ ] `InsightsAiErrorScreen`: retry button calls `retryEnrichment(rawId)` (MF-03)
- [ ] `PipelineHealth` type includes `ai_error_count` field (MF-03)
- [ ] `PipelineHealthCard`: all 6 health metrics displayed
- [ ] Admin screens accessible only to authenticated users with `is_admin = true`

### 4.5 Testing Checklist

| Category | Required Tests | Sprint | Done |
|----------|---------------|--------|------|
| Migration regression | All 7 migrations apply clean on fresh DB | S1 | ☐ |
| RLS policy matrix | 6 policy tests (anon/service × 3 key tables) | S1 | ☐ |
| Fingerprint unit test | Known URL → known SHA-256 | S2 | ☐ |
| Domain validator | Sub-path matching (WEF, EC) | S2 | ☐ |
| Keyword scorer | 15+ test cases (energy yes/no) | S2 | ☐ |
| HMAC verification | 3 test cases: valid/invalid/missing (MF-01) | S2 | ☐ |
| CF-01 recovery | Force stuck insight; verify recovery in <30min | S2 | ☐ |
| Injection sanitization | `<INST>` prefix stripped (MF-07) | S3 | ☐ |
| Output anomaly detection | "Ignore..." → confidence = 0.0 (MF-07) | S3 | ☐ |
| Image dimension validation | 3 test cases per MF-05 | S3 | ☐ |
| Full pipeline E2E | submit → validate → enrich → activate | S3 | ☐ |
| Evergreen expiry guard | is_evergreen=true survives expire cron | S3 | ☐ |
| Flutter integration (8 scenarios) | See S4-QA-001 | S4 | ☐ |
| GoRouter regression | All existing routes still work | S4 | ☐ |
| Performance SLOs | Cold start, PostgREST, feed query | S4 | ☐ |

### 4.6 Deployment Checklist

Before any Edge Function is deployed to production:

- [ ] All Supabase Secrets verified populated (not empty)
- [ ] Edge Function deployed via `supabase functions deploy {function_name}`
- [ ] Deployment succeeds with zero errors in Supabase CLI output
- [ ] Function invocable from Postman/curl with correct auth header
- [ ] Log output appears in Supabase Dashboard → Edge Functions → Logs
- [ ] Cron jobs visible in Dashboard after deployment

Before Flutter build is released:

- [ ] `flutter analyze` zero errors
- [ ] Debug build passes on Android and iOS
- [ ] Supabase URL and anon key correctly set in `core/config/env.dart`
- [ ] No API keys or secrets in Flutter source code

### 4.7 Documentation Checklist

- [ ] Phase 3.5 Implementation Specification: note MF-04 (is_evergreen) and MF-06 (audit trail) as applied to M03
- [ ] Phase 3.5 Implementation Specification: note CF-01 (`recover_stalled_insights`) as added to Sprint 2 scope
- [ ] Phase 3.5 Implementation Specification: note AI timeout correction (25s per attempt, not 30s)
- [ ] Sprint retrospective notes filed after each sprint
- [ ] Any deviations from Phase 3.5 spec documented in PR description with rationale

---

## SECTION 5 — QUALITY GATES

### Gate 1 — Sprint 1 → Sprint 2

**Conducted by:** Tech Lead + Database Engineer  
**Timing:** End of Sprint 1 Day 8

| Check | Criteria | Pass |
|-------|---------|------|
| Migration regression | All 7 migrations apply from scratch without errors | ☐ |
| Schema completeness | All tables/columns match Phase 3.5 spec (plus MF-04, MF-06) | ☐ |
| Index coverage | 14 indexes confirmed (including CF-01 `updated_at` index) | ☐ |
| RLS correctness | Anon can SELECT active insights; anon cannot write/read raw pipeline tables | ☐ |
| RPC callable | `batch_approve_high_confidence` executes without error | ☐ |
| Seed verified | 25 rows, all active, correct tier/domain values | ☐ |
| MF-04 confirmed | `is_evergreen DEFAULT false` present in M03 | ☐ |
| MF-06 confirmed | `reviewed_by UUID`, `reviewed_at TIMESTAMPTZ` present in M03 | ☐ |
| PR merged | Sprint 1 branch merged to `main` | ☐ |

**Performance check:** N/A — no network calls in Sprint 1  
**Security check:** RLS policies verified; no secrets in migration files  
**Rollback readiness:** `supabase db reset` restores clean state; no production data at this stage

**Gate 1 BLOCKED if:** Any migration fails; any RLS test fails; MF-04 or MF-06 not present

---

### Gate 2 — Sprint 2 → Sprint 3

**Conducted by:** Tech Lead + Backend Engineer + QA Lead  
**Timing:** End of Sprint 2 Day 8

| Check | Criteria | Pass |
|-------|---------|------|
| Shared utilities | All 8 `_shared/` utilities pass unit tests | ☐ |
| collect_insight | Valid submission creates `pending` row; duplicate → 409; unknown domain → 400 | ☐ |
| validate_insight HMAC | Correct HMAC → 200; tampered → 401; missing header → 401 (MF-01) | ☐ |
| validate_insight logic | Relevance <0.3 → `rejected`; ≥0.3 + valid domain → `validated` | ☐ |
| CF-01 recovery | Stalled `validated` insight recovered within 30 min | ☐ |
| CF-01 cron registered | `*/30 * * * *` schedule active in Supabase | ☐ |
| Log events | All 8 Sprint 2 log events emitted with correct fields | ☐ |
| No hardcoded secrets | Grep of Sprint 2 code confirms zero hardcoded env values | ☐ |
| E2E test documented | submit → validate → `validated` status verified | ☐ |
| PR merged | Sprint 2 branch merged to `main` | ☐ |

**Performance check:** `validate_insight` round-trip < 10s on test invocation  
**Security check:** MF-01 HMAC test (3 cases); no secrets in source  
**Rollback readiness:** Edge Functions can be rolled back by redeploying previous version; `insights_raw` rows deletable

**Gate 2 BLOCKED if:** MF-01 HMAC test fails; CF-01 cron not registered; any E2E test fails

---

### Gate 3 — Sprint 3 → Sprint 4

**Conducted by:** Tech Lead + Backend Engineer + QA Lead  
**Timing:** End of Sprint 3 Day 5

| Check | Criteria | Pass |
|-------|---------|------|
| Full pipeline E2E | submit → validate → enrich → mirror → activate completes | ☐ |
| All 8 AI fields | ai_summary, ai_why_matters, ai_key_takeaway, ai_tags, category, confidence_score, reading_time_minutes, is_ai_generated present | ☐ |
| MF-07 injection test | `<INST>` stripped; "Ignore..." → confidence = 0.0 | ☐ |
| MF-05 dimension test | Under-size rejected; minimum accepted; unknown format = fail-open | ☐ |
| CDN URL format | `hero_image_url` matches storage URL format with WebP params | ☐ |
| 25s timeout enforced | Timing test against slow mock confirms 25s cutoff (not 30s) | ☐ |
| Retry cycle | 3 attempts; ai_error status on 3rd failure | ☐ |
| Evergreen guard | is_evergreen=true insight survives `expire_old_insights` run | ☐ |
| Both schedulers | activate cron at `0/15 * * * *`; expire cron at `0 2 * * *` | ☐ |
| Batch approve disabled | `batch_approve_high_confidence` NOT called; documented as deferred | ☐ |
| All 13 log events | All Sprint 3 log events emitted | ☐ |
| PR merged | Sprint 3 branch merged to `main` | ☐ |

**Performance check:** `enrich_insight` P50 < 20s, P95 < 60s on test invocations  
**Security check:** MF-07 injection tests (2 cases); CDN URLs do not expose service role key  
**Rollback readiness:** Edge Functions redeployable; `insights_raw` `ai_processed` rows revert to `validated` for re-enrichment

**Gate 3 BLOCKED if:** Full pipeline E2E fails; MF-07 or MF-05 tests fail; timeout not 25s; batch approve called

---

### Gate 4 — Sprint 4 → Release

**Conducted by:** Engineering Director + Tech Lead + QA Lead  
**Timing:** End of Sprint 4 Day 8

| Check | Criteria | Pass |
|-------|---------|------|
| Feed loads | `InsightFeedPage` renders from live backend | ☐ |
| Vertical swipe | `PageView.builder` advances cards on swipe | ☐ |
| Pre-fetch | Pre-fetch fires at `index >= length - 2` | ☐ |
| Cache-first | Page 0 served from cache; stale banner after 60 min | ☐ |
| Offline mode | Cached data serves; error state shown when no cache | ☐ |
| Admin review | Approve, reject, edit all transition status correctly | ☐ |
| MF-03 ai_error screen | Third admin tab loads; retry button calls `retryEnrichment()` | ☐ |
| MF-04 evergreen toggle | Toggle visible in review card; PATCH updates `is_evergreen` | ☐ |
| MF-06 audit trail | `reviewed_by` and `reviewed_at` populated on every admin action | ☐ |
| GoRouter | `/insights` and `/insights/detail/:id` routes work | ☐ |
| GoRouter regression | All existing app routes still navigate correctly | ☐ |
| memCacheWidth/Height | `CachedNetworkImage` uses correct memory constraints | ☐ |
| flutter analyze | Zero errors | ☐ |
| Performance SLOs | Feed cold start <2s P95; from cache <500ms P95; PostgREST <50ms P95 | ☐ |
| 8 integration scenarios | All pass on device/simulator | ☐ |
| Go-live checklist | Section 9 complete | ☐ |
| PR merged | Sprint 4 branch merged to `main` | ☐ |

**Security check:** Admin screens require `is_admin = true`; no service role key in Flutter bundle; no secrets in `env.dart`  
**Rollback readiness:** Navigation branch can be reverted without touching feed; feature flag can disable Insights tab entry

**Gate 4 BLOCKED if:** Any MF-03/MF-04/MF-06 test fails; GoRouter regression found; performance SLOs not met; `flutter analyze` errors

---

## SECTION 6 — RISK TRACKING

### 6.1 Open Risks

| Risk ID | Description | Probability | Impact | Mitigation | Owner | Sprint |
|---------|-------------|-------------|--------|-----------|-------|--------|
| RISK-001 | `ANTHROPIC_API_KEY` not procured before Sprint 3 | LOW (procurement initiated S1) | CRITICAL — Sprint 3 blocked | Procurement initiated on S1-D1; escalate immediately if delayed | Engineering Director | S1 |
| RISK-002 | Supabase Pro plan not activated | MEDIUM (requires billing) | HIGH — cron + log retention blocked | Confirm billing in S1 pre-flight | Engineering Director | S1 |
| RISK-003 | GoRouter `ShellRoute` conflict with existing nav | MEDIUM | MEDIUM — isolated to sprint-4-nav branch; revertable | Branch isolation; 1-day resolution window before deferral | Flutter Engineer | S4 |
| RISK-004 | Anthropic API rate limit during integration testing | MEDIUM | LOW — testing uses single articles | Test with one article at a time; never bulk test | Backend Engineer | S3 |
| RISK-005 | Supabase cron extension unavailable | LOW (Pro plan required) | HIGH — CF-01 and schedulers blocked | Confirm extension availability on Pro plan before S2 | DevOps Lead | S2 |
| RISK-006 | `cached_network_image` version doesn't support `memCacheWidth/Height` | LOW | LOW — update package version | Verify package version in `pubspec.yaml` on S4-D1 | Flutter Engineer | S4 |
| RISK-007 | OG extraction fails for paywalled/JS-rendered pages | HIGH | LOW — graceful fallback specified | Fallback: use domain + URL path as title; do not fail pipeline | Backend Engineer | S2 |
| RISK-008 | Anthropic API changes `claude-haiku-4-5-20251001` response format | VERY LOW | HIGH — all AI parsing breaks | Output schema validation on parse; alert on schema mismatch; update prompt if needed | Backend Engineer | S3 |

### 6.2 Mitigated Risks

| Risk ID | Description | Resolution | Sprint Mitigated |
|---------|-------------|-----------|-----------------|
| R-MF-01 | Webhook spoofing (no signature verification) | HMAC-SHA256 verification added in `validate_insight` (MF-01) | S2 |
| R-CF-01 | Orphaned `validated` insights (fire-and-forget handoff) | `recover_stalled_insights` cron every 30 min (CF-01) | S2 |
| R-MF-04 | `is_evergreen` never set (default unspecified) | `DEFAULT false` in M03; admin toggle; DTO field; PATCH method (MF-04) | S1 + S4 |
| R-MF-05 | Image dimension validation approach unresolved | Binary header parsing: JPEG SOF, PNG IHDR, WebP VP8X (MF-05) | S3 |
| R-MF-06 | No moderation audit trail | `reviewed_by UUID`, `reviewed_at TIMESTAMPTZ` in M03; all admin writes include both (MF-06) | S1 + S4 |
| R-MF-07 | Prompt injection undefended | Input sanitization + output anomaly detection (MF-07) | S3 |
| R-MF-03 | ai_error recovery UI missing | `InsightsAiErrorScreen` + `fetchAiErrorQueue` + `retryEnrichment` (MF-03) | S4 |
| R-TIMEOUT | 3×30s = 90s = edge function timeout (no headroom) | Per-attempt timeout corrected to 25s; leaves 15s overhead | S3 |
| R-WEBP | WebP conversion required WASM library | Solved via Supabase Storage Image Transformation URL params (no WASM needed) | S3 |
| R-BATCH | Batch approve confidence not empirically validated | Batch approve disabled for first 4 weeks post-launch | S3 |

### 6.3 Deferred Risks

| Item | Reason for Deferral | V2 Milestone |
|------|---------------------|-------------|
| `dead_link_check` cron | V2 feature; V1 mitigation: `is_link_verified` 10% HEAD sample in expire cron | V2 |
| RSS feed polling (`poll_rss_feeds`) | V2 automated ingestion | V2 |
| Weekly digest (`send_weekly_digest`) | V2 engagement feature | V2 |
| `IEEE_API_KEY` integration | Optional; not required for V1 | V2 |
| Cursor pagination beyond page 100 | Required only at 100,000+ insights (Phase 3.8 mf-05) | V2 |
| Rate limiting hard enforcement on `collect_insight` | V1 soft limit (admin UI warning >5/session); hard enforcement V2 (MF-02) | V2 |
| Log retention policy automation | Manual cleanup until pg_cron + partition pruning configured (Phase 3.8 mf-04) | V2 |

### 6.4 Critical Path

Items on the critical path block the next sprint if delayed.

```
[Pre-flight checklist complete] → SPRINT 1
[MF-04 + MF-06 signed off] → S1-DB-003 (M03)
SPRINT 1 complete (Gate 1) → SPRINT 2
[WEBHOOK_SECRET in Supabase Secrets] → S2-BE-012 (MF-01)
SPRINT 2 complete (Gate 2) → SPRINT 3
[ANTHROPIC_API_KEY confirmed in Supabase Secrets] → S3-AI-004 (AI client)
SPRINT 3 complete (Gate 3) → SPRINT 4
[At least 10 active insights in Supabase] → S4-QA-001 (integration tests)
SPRINT 4 complete (Gate 4) → RELEASE
```

**The single highest-risk item on the critical path is `ANTHROPIC_API_KEY` procurement.** Initiate on Sprint 1 Day 1. Sprint 3 cannot begin without it.

---

## SECTION 7 — TEAM COORDINATION

### 7.1 Branch Strategy

```
main
├── feature/insights-sprint-1-database     (DB Engineer — Sprint 1)
├── feature/insights-sprint-2-pipeline     (Backend Engineer — Sprint 2)
├── feature/insights-sprint-3-enrichment   (Backend Engineer — Sprint 3)
└── feature/insights-sprint-4-flutter      (Flutter Engineer — Sprint 4)
    └── feature/insights-sprint-4-nav      (Flutter Engineer — Sprint 4 Day 6)
                                            ← child of sprint-4-flutter
```

**Rules:**
- All branches created from `main` at the start of the project (before S1-D1) except `sprint-4-nav` which is created from `sprint-4-flutter` on S4-D6
- No engineer pushes directly to `main`
- No engineer merges without a passing gate review
- Sprints merge sequentially: S1 merges first, then S2 (which can reference S1 schema), then S3, then S4
- `sprint-4-nav` merges into `sprint-4-flutter` before the Sprint 4 PR to `main`

### 7.2 Pull Request Workflow

1. Engineer opens PR from sprint branch to `main` on the final day of the sprint
2. PR title format: `[S{N}] {component}: {one-line description}` — e.g. `[S1] Database: Apply migrations M01–M07 with MF-04 and MF-06`
3. PR body must include:
   - List of tasks completed (Task IDs)
   - Gate checklist results (paste from Section 5)
   - Any deviations from Phase 3.5 spec with rationale
   - Known issues or follow-up tasks
4. Minimum 1 approval from Tech Lead before merge
5. All CI checks must pass (if CI is configured)
6. Gate review must be documented before approval is given

### 7.3 Code Review Checklist

For every PR, reviewers must verify:

**Security**
- [ ] No API keys, secrets, or passwords in source code
- [ ] No `console.log` of sensitive values (tokens, user IDs in plaintext)
- [ ] HMAC verification present in `validate_insight` (S2 PR only)
- [ ] Injection defenses present in `enrich_insight` prompt builder (S3 PR only)

**Correctness**
- [ ] Status transitions match Phase 3.5 state machine (`pending → validated → ai_processed → review → scheduled/active → archived`)
- [ ] Error cases explicitly handled (no silent failures)
- [ ] `is_evergreen = true` insights excluded from expiry logic

**Observability**
- [ ] All required log events emitted with correct fields (timestamp, function_name, execution_id)
- [ ] No logs silently swallowed

**Performance**
- [ ] No N+1 queries
- [ ] No unbounded SELECT * (all queries have explicit column lists or LIMIT)
- [ ] Image memory constraints set in Flutter (`memCacheWidth`, `memCacheHeight`)

**Phase 3.8 findings**
- [ ] MF-04 (is_evergreen): migration column present; admin toggle wires correctly (S1/S4 PRs)
- [ ] MF-06 (audit trail): admin write methods include `reviewed_by` and `reviewed_at` (S4 PR)
- [ ] MF-01 (HMAC): webhook signature verified (S2 PR)
- [ ] MF-07 (injection): input sanitized; output checked (S3 PR)
- [ ] CF-01 (recovery): cron registered; test case added (S2 PR)
- [ ] MF-03 (ai_error UI): third admin tab implemented (S4 PR)
- [ ] MF-05 (dimension): binary header parsing implemented (S3 PR)

### 7.4 Commit Standards

Format: `{type}({scope}): {description}`

**Types:** `feat`, `fix`, `test`, `chore`, `docs`  
**Scopes:** `db`, `pipeline`, `enrichment`, `flutter`, `admin`, `nav`, `shared`, `security`

Examples:
- `feat(db): apply M03 catalyst_insights with MF-04 is_evergreen and MF-06 audit columns`
- `feat(security): add HMAC-SHA256 webhook signature verification to validate_insight (MF-01)`
- `feat(pipeline): implement recover_stalled_insights cron for CF-01 orphaned insight recovery`
- `feat(flutter): implement InsightsAiErrorScreen third admin tab (MF-03)`
- `test(pipeline): add CF-01 integration test for stalled validated insight recovery`

**Rules:**
- One commit per logical unit of work
- Never commit commented-out code
- Never commit `.env` files, secrets, or local config
- Commit message body (if needed) explains WHY not WHAT

### 7.5 Issue Tracking Conventions

| Label | Usage |
|-------|-------|
| `sprint-1` through `sprint-4` | Issue belongs to that sprint |
| `finding` | Phase 3.8 mandatory finding tracked as issue |
| `critical-path` | Issue blocks the next sprint |
| `blocked` | Issue blocked by external dependency (API key, billing, etc.) |
| `bug` | Implementation defect found during testing |
| `deferred` | Explicitly deferred to V2 |

Every Phase 3.8 finding (CF-01, MF-01 through MF-07) should have a corresponding issue tagged `finding` with its gating sprint.

### 7.6 Definition of Ready (DoR)

A task is ready to begin when:

1. Task ID assigned and issue created in tracker
2. Dependencies all completed (or explicitly not required for this task)
3. The gating sprint's Quality Gate has passed
4. Any Phase 3.8 findings that gate this task have been signed off
5. Required secrets/env vars are available in Supabase Secrets
6. The engineer has read the relevant section of Phase 3.5 for this task

### 7.7 Definition of Done (DoD)

A task is done when:

1. Implementation matches Phase 3.5 specification (or deviation is documented)
2. All Phase 3.8 findings that apply to this task are incorporated
3. Unit test written and passing (where applicable per Section 4.5)
4. No `flutter analyze` errors introduced (Flutter tasks)
5. No hardcoded secrets introduced
6. Log events emitted as specified in Phase 3.8 observability section
7. Task issue updated to `Done` in tracker
8. Code reviewed by at least one other engineer (or Tech Lead for critical-path tasks)

---

## SECTION 8 — IMPLEMENTATION DASHBOARD

Track the following metrics continuously throughout implementation. Update daily at the end of each working day.

### 8.1 Sprint Progress

| Sprint | Total Days | Days Complete | Tasks Total | Tasks Done | Tasks Blocked | Status |
|--------|-----------|---------------|-------------|------------|---------------|--------|
| Sprint 1 — Database | 8 | — | 14 | — | — | NOT STARTED |
| Sprint 2 — Pipeline | 8 | — | 17 | — | — | NOT STARTED |
| Sprint 3 — Enrichment | 5 | — | 13 | — | — | NOT STARTED |
| Sprint 4 — Flutter | 8 | — | 21 | — | — | NOT STARTED |
| **Total** | **29** | — | **65** | — | — | |

*(Day count includes Gate review days; task count from Section 3)*

### 8.2 Phase 3.8 Finding Resolution Dashboard

| Finding | Title | Gating Sprint | Resolution Sprint | Status |
|---------|-------|---------------|-------------------|--------|
| CF-01 | recover_stalled_insights | S2 | S2-D7 | OPEN |
| MF-01 | HMAC webhook verification | S2 | S2-D7 | OPEN |
| MF-03 | ai_error recovery UI | S4 | S4-D5 | OPEN |
| MF-04 | is_evergreen mechanism | S1 | S1-D4 (M03) + S4-D2/D5 | OPEN |
| MF-05 | Image dimension validation | S3 | S3-D1 | OPEN |
| MF-06 | Audit trail columns | S1 | S1-D4 (M03) + S4-D5 | OPEN |
| MF-07 | Prompt injection defenses | S3 | S3-D1 | OPEN |

### 8.3 Test Coverage Tracker

| Suite | Tests Written | Tests Passing | Coverage Target | Status |
|-------|--------------|--------------|-----------------|--------|
| Migration regression | — | — | 100% (7 migrations) | — |
| RLS policy matrix | — | — | 100% (6 policies) | — |
| `_shared/` unit tests | — | — | 15+ test cases | — |
| MF-01 HMAC tests | — | — | 3 cases | — |
| CF-01 recovery test | — | — | 1 integration case | — |
| MF-07 injection tests | — | — | 2 cases | — |
| MF-05 dimension tests | — | — | 3 cases | — |
| Full pipeline E2E | — | — | 1 complete flow | — |
| Flutter integration | — | — | 8 scenarios | — |
| GoRouter regression | — | — | All existing routes | — |

### 8.4 Defect Tracker

| ID | Sprint | Description | Severity | Status | Owner |
|----|--------|-------------|----------|--------|-------|
| *(no defects yet)* | | | | | |

Add rows as defects are discovered. Severity: P0 (blocks sprint), P1 (blocks gate), P2 (tracked, no blocker), P3 (nice-to-fix).

### 8.5 Performance SLO Tracker

Populate after Gate 3 (S3) and Gate 4 (S4) measurements.

| Metric | SLO P50 | SLO P95 | Actual P50 | Actual P95 | Gate | Pass |
|--------|---------|---------|-----------|-----------|------|------|
| `collect_insight` round-trip | <3s | <8s | — | — | G2 | — |
| `validate_insight` round-trip | <2s | <10s | — | — | G2 | — |
| `enrich_insight` round-trip | <20s | <60s | — | — | G3 | — |
| Flutter feed cold start (network) | <2s | <4s | — | — | G4 | — |
| Flutter feed cold start (cache) | <500ms | <1s | — | — | G4 | — |
| PostgREST feed query | <20ms | <50ms | — | — | G4 | — |

### 8.6 Security Findings Tracker

| ID | Finding | Phase 3.8 Reference | Status |
|----|---------|---------------------|--------|
| SEC-01 | Webhook spoofing via unauthenticated endpoint | MF-01 | OPEN → resolved in S2 |
| SEC-02 | Prompt injection in AI pipeline | MF-07 | OPEN → resolved in S3 |
| SEC-03 | Batch approve confidence threshold not validated | Phase 3.8 AI recommendation | DEFERRED (4 weeks post-launch) |

### 8.7 Technical Debt Tracker

| ID | Description | Created Sprint | Target Sprint |
|----|-------------|---------------|---------------|
| TD-01 | MF-02: Rate limiting on `collect_insight` is soft (admin UI warning only) — hard limit deferred to V2 | S2 | V2 |
| TD-02 | MF-08: `dead_link_check` is V2 only; V1 has 10% HEAD sample only | S3 | V2 |
| TD-03 | mf-04: Log retention policy needs automated pg_cron pruning at scale | S2 | V2 |
| TD-04 | mf-05: OFFSET pagination ceiling at 100,000 insights — cursor pagination needed at V2 scale | S1 | V2 |
| TD-05 | mf-06: Sources load on each navigation (cold start) — cache/eager-load at V2 scale | S4 | V2 |

---

## SECTION 9 — GO-LIVE CRITERIA

All criteria below must be met before production deployment is authorized. No exceptions.

### 9.1 Functional Completion

| # | Requirement | Verified By | Pass |
|---|-------------|-------------|------|
| F-01 | All 7 migrations applied to production Supabase project | DB Engineer | ☐ |
| F-02 | 25-row seed data loaded in production `insights_sources` | DB Engineer | ☐ |
| F-03 | All 5 Edge Functions deployed to production (`collect_insight`, `validate_insight`, `enrich_insight`, `activate_scheduled_insights`, `expire_old_insights`, `recover_stalled_insights`) | DevOps Lead | ☐ |
| F-04 | All 3 cron jobs active in production Supabase (`activate_scheduled_insights` 15-min, `expire_old_insights` daily, `recover_stalled_insights` 30-min) | DevOps Lead | ☐ |
| F-05 | At least 10 manually submitted and admin-approved active insights in production for initial user experience | Tech Lead | ☐ |
| F-06 | Flutter app loads `InsightFeedPage` from production Supabase | Flutter Engineer | ☐ |
| F-07 | Admin portal: review queue, pipeline health, and AI error screen accessible to admin users | Flutter Engineer | ☐ |
| F-08 | Full pipeline test in production: submit article → validate → enrich → image mirror → admin approve → active → visible in feed | Tech Lead + QA Lead | ☐ |
| F-09 | `batch_approve_high_confidence` RPC confirmed NOT called — documented as deferred 4 weeks | Engineering Director | ☐ |

### 9.2 Testing Completion

| # | Requirement | Verified By | Pass |
|---|-------------|-------------|------|
| T-01 | All 15 test categories from Section 4.5 complete and passing | QA Lead | ☐ |
| T-02 | All 4 Quality Gates passed and documented | Tech Lead | ☐ |
| T-03 | MF-01 HMAC test: 3 cases passing in production | Backend Engineer | ☐ |
| T-04 | MF-07 injection test: 2 cases verified in production | Backend Engineer | ☐ |
| T-05 | MF-05 dimension test: 3 cases verified | Backend Engineer | ☐ |
| T-06 | CF-01 recovery test: stalled insight recovered in production environment | Backend Engineer | ☐ |
| T-07 | Flutter integration test suite (8 scenarios) passing against production backend | QA Lead | ☐ |
| T-08 | GoRouter regression: all existing app routes working in production build | Flutter Engineer | ☐ |

### 9.3 Security Review

| # | Requirement | Verified By | Pass |
|---|-------------|-------------|------|
| S-01 | All Supabase production secrets populated (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, ANTHROPIC_API_KEY, WEBHOOK_SECRET) | DevOps Lead | ☐ |
| S-02 | No secrets present in git history (grep all branches) | Tech Lead | ☐ |
| S-03 | No secrets present in Flutter bundle (decompile/inspect) | Flutter Engineer | ☐ |
| S-04 | `validate_insight` HMAC verification active in production | Backend Engineer | ☐ |
| S-05 | Prompt injection defenses active in production `enrich_insight` | Backend Engineer | ☐ |
| S-06 | Admin routes accessible only to `is_admin = true` users in production | Flutter Engineer | ☐ |
| S-07 | RLS policies verified in production: anon cannot read `insights_raw` or `insights_sources`; anon can only read active `catalyst_insights` | DB Engineer | ☐ |
| S-08 | Anthropic API spend alert active at $10/month | Engineering Director | ☐ |

### 9.4 Performance Validation

| # | Metric | SLO P95 | Actual (Production) | Pass |
|---|--------|---------|---------------------|------|
| P-01 | Flutter feed cold start from network | < 4s | — | ☐ |
| P-02 | Flutter feed cold start from cache | < 1s | — | ☐ |
| P-03 | PostgREST feed query | < 50ms | — | ☐ |
| P-04 | `collect_insight` round-trip | < 8s | — | ☐ |
| P-05 | `enrich_insight` round-trip | < 60s | — | ☐ |

### 9.5 Documentation Completion

| # | Requirement | Owner | Pass |
|---|-------------|-------|------|
| D-01 | Phase 3.5 specification annotated with all Phase 3.8 finding resolutions (MF-04, MF-06 in M03; CF-01 in Sprint 2; timeout correction to 25s) | Tech Lead | ☐ |
| D-02 | Sprint retrospective notes filed for all 4 sprints | Engineering Director | ☐ |
| D-03 | All Phase 3.8 finding issues closed in issue tracker | Tech Lead | ☐ |
| D-04 | Production environment variables documented in team password manager | DevOps Lead | ☐ |
| D-05 | Deferred V2 items documented in issue tracker with `deferred` label | Tech Lead | ☐ |

### 9.6 Rollback Validation

A production rollback must be executable within 15 minutes for any component. Verify each rollback path before go-live.

| # | Component | Rollback Method | Time Target | Verified |
|---|-----------|----------------|-------------|---------|
| RB-01 | Flutter app | Re-publish previous build (Android/iOS rollback) | < 30 min (store propagation) | ☐ |
| RB-02 | Edge Functions | `supabase functions deploy {name}@{previous-version}` | < 5 min | ☐ |
| RB-03 | Database schema | Supabase Dashboard rollback (point-in-time recovery; Pro plan required) | < 15 min | ☐ |
| RB-04 | Cron jobs | Disable in Dashboard → Edge Functions | < 2 min | ☐ |
| RB-05 | Insights tab (feature isolation) | Set `showInsights = false` in admin or route guard config | < 5 min (app update) | ☐ |

**Go-live is authorized only when all items in Sections 9.1 through 9.6 are checked.**

---

## APPENDIX A — IMPLEMENTATION TIMELINE

```
Week 1–2: Sprint 1 — Database
  Day 1:   Pre-flight + branches + issue creation
  Days 2–4: Migrations M01, M02, M03 (MF-04 + MF-06)
  Days 5–6: Migrations M04, M05, M06
  Day 7:   M07 + seed data
  Day 8:   Gate 1 review + PR merge

Week 2–4: Sprint 2 — Backend Pipeline
  Days 1–5: _shared/ utilities (8 files in dependency order)
  Day 6:   collect_insight
  Day 7:   validate_insight (MF-01 HMAC) + recover_stalled_insights (CF-01)
  Day 8:   Cron registration + E2E test + Gate 2 + PR merge

Week 4–5: Sprint 3 — AI Enrichment
  Day 1:   ai_prompt (MF-07) + image_validator (MF-05)
  Day 2:   ai_client (25s timeout, retry)
  Day 3:   enrichment + enrich_insight index
  Day 4:   mirror_image + schedulers
  Day 5:   Cron registration + E2E test + Gate 3 + PR merge

Week 5–7: Sprint 4 — Flutter + Admin
  Days 1–2: Data layer (DTOs + repository)
  Day 3:   State layer (InsightsNotifier, InsightsState)
  Day 4:   UI layer (InsightCard + InsightFeedPage)
  Day 5:   Admin (MF-03 ai_error screen, MF-04 toggle, MF-06 audit)
  Day 6:   Navigation wiring (sprint-4-nav branch)
  Day 7:   Integration testing (8 scenarios)
  Day 8:   Gate 4 + performance check + PR merge
```

Total estimated duration: 27 working days across 5.5 calendar weeks

---

## APPENDIX B — CRON SCHEDULE REFERENCE

| Function | Schedule | Trigger | Note |
|----------|----------|---------|------|
| `recover_stalled_insights` | `*/30 * * * *` (every 30 min) | pg_cron | CF-01 — registered Sprint 2 |
| `activate_scheduled_insights` | `0/15 * * * *` (every 15 min) | pg_cron | Registered Sprint 3 |
| `expire_old_insights` | `0 2 * * *` (daily 02:00 UTC) | pg_cron | Registered Sprint 3 |

---

## APPENDIX C — ENVIRONMENT VARIABLE REFERENCE

| Variable | Required By | Sprint Set | Source |
|----------|-------------|------------|--------|
| `SUPABASE_URL` | All Edge Functions | Pre-Sprint 1 | Supabase Dashboard → Settings → API |
| `SUPABASE_SERVICE_ROLE_KEY` | All Edge Functions | Pre-Sprint 1 | Supabase Dashboard → Settings → API |
| `ANTHROPIC_API_KEY` | `enrich_insight` | Pre-Sprint 1 (procure); Sprint 3 (use) | Anthropic console |
| `WEBHOOK_SECRET` | `validate_insight` | Pre-Sprint 2 | Generate: `openssl rand -hex 32` |
| `IEEE_API_KEY` | `enrich_insight` (optional) | V2 | IEEE Xplore API portal |

---

## APPENDIX D — STORAGE CDN URL FORMAT

The canonical format for all `hero_image_url` values written to `catalyst_insights`:

```
{SUPABASE_URL}/storage/v1/object/public/insights-images/insights/{id}/hero.jpg?width=1200&quality=85&format=webp
```

Where `{id}` is the `catalyst_insights.id` UUID. This format enables Supabase Storage Image Transformation to serve WebP at 1200px width with 85% quality — no WASM conversion in the Edge Function.

---

## SPRINT 1 AUTHORIZATION

Sprint 1 is authorized to begin when:

- [ ] Section 1 Implementation Readiness Checklist — 100% complete
- [ ] MF-04 signed off (is_evergreen in M03)
- [ ] MF-06 signed off (reviewed_by, reviewed_at in M03)
- [ ] All 5 git branches created
- [ ] All Sprint 1 issues created in tracker
- [ ] `ANTHROPIC_API_KEY` procurement initiated (Sprint 3 critical path)
- [ ] Supabase Pro plan confirmed active

**Authorizing parties:** Engineering Director + Tech Lead

Signature: _____________________ Date: _____________________  
Signature: _____________________ Date: _____________________

---

🟢 PHASE 4.0 COMPLETE — IMPLEMENTATION READY
