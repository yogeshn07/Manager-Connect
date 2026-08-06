# CATALYST INSIGHTS
## Phase 3.5 — Implementation Specification

**Application:** The Catalysts  
**Feature:** Catalyst Insights  
**Document Phase:** Phase 3.5 — Implementation Specification  
**Status:** PLANNING ONLY — No production code, no SQL, no Flutter, no Edge Functions, no migrations  
**Depends On:** Phase 3 — `catalyst_insights_phase3_backend_engineering_blueprint.md` (LOCKED)  
**Date:** 2026-07-17  
**Purpose:** Day-to-day engineering manual during implementation. Every file, every dependency, every build order, every quality gate.

---

## 1. EXECUTIVE SUMMARY

This document converts the Phase 3 blueprint into a precise implementation map. It answers three questions for every component in the system:

1. **What file do I create?** Exact path, exact name.
2. **What does it own?** Its sole responsibility — one file, one job.
3. **When do I create it?** Relative to everything else in a strict, dependency-ordered sequence.

No implementation decision is left open. A developer can begin Sprint 1 immediately after reading §5. A Flutter engineer can begin Sprint 4 immediately after reading §7. Every build ordering question has a definitive answer in §3.

---

## 2. COMPLETE PROJECT STRUCTURE

Every file in this tree is either: `[existing]` (do not touch), `[existing — MODIFY]` (exact change described in §7.5), or `[Sprint N]` (create in that sprint).

```
office_project/
│
├── supabase/
│   ├── config.toml                                          [existing]
│   │
│   ├── migrations/
│   │   ├── ... (all existing migrations)                    [existing — do not touch]
│   │   ├── 20260717000001_insights_sources.sql             [Sprint 1]
│   │   ├── 20260717000002_insights_raw.sql                 [Sprint 1]
│   │   ├── 20260717000003_catalyst_insights.sql            [Sprint 1]
│   │   ├── 20260717000004_insights_v2_tables.sql           [Sprint 1]
│   │   ├── 20260717000005_insights_indexes.sql             [Sprint 1]
│   │   ├── 20260717000006_insights_rls.sql                 [Sprint 1]
│   │   └── 20260717000007_insights_rpc_functions.sql       [Sprint 1]
│   │
│   ├── seed/
│   │   └── insights_sources_seed.sql                       [Sprint 1]
│   │
│   └── functions/
│       │
│       ├── _shared/                    ← shared utilities imported by all functions
│       │   ├── types.ts                                     [Sprint 2 — first file]
│       │   ├── logger.ts                                    [Sprint 2]
│       │   ├── supabase_client.ts                          [Sprint 2]
│       │   ├── fingerprint.ts                              [Sprint 2]
│       │   ├── url_utils.ts                                [Sprint 2]
│       │   ├── og_extractor.ts                             [Sprint 2]
│       │   ├── domain_validator.ts                         [Sprint 2]
│       │   └── keyword_scorer.ts                           [Sprint 2]
│       │
│       ├── collect_insight/
│       │   └── index.ts                                     [Sprint 2]
│       │
│       ├── validate_insight/
│       │   ├── index.ts                                     [Sprint 2]
│       │   ├── structural_checks.ts                        [Sprint 2]
│       │   └── dedup.ts                                    [Sprint 2]
│       │
│       ├── enrich_insight/
│       │   ├── index.ts                                     [Sprint 3]
│       │   ├── ai_prompt.ts                                [Sprint 3]
│       │   ├── ai_client.ts                                [Sprint 3]
│       │   ├── ieee_client.ts                              [Sprint 3]
│       │   └── mirror_image.ts                             [Sprint 3]
│       │
│       ├── activate_scheduled_insights/
│       │   └── index.ts                                     [Sprint 4]
│       │
│       └── expire_old_insights/
│           └── index.ts                                     [Sprint 4]
│
├── supabase_tests/                     ← Edge Function test suite (top-level, not inside supabase/)
│   ├── unit/
│   │   ├── url_utils_test.ts                               [Sprint 2]
│   │   ├── fingerprint_test.ts                             [Sprint 2]
│   │   ├── og_extractor_test.ts                            [Sprint 2]
│   │   ├── keyword_scorer_test.ts                          [Sprint 2]
│   │   ├── domain_validator_test.ts                        [Sprint 2]
│   │   └── structural_checks_test.ts                       [Sprint 2]
│   ├── integration/
│   │   ├── collect_insight_test.ts                         [Sprint 2]
│   │   ├── validate_insight_test.ts                        [Sprint 2]
│   │   ├── enrich_insight_test.ts                          [Sprint 3]
│   │   └── schedulers_test.ts                              [Sprint 4]
│   └── fixtures/
│       ├── og_html/
│       │   ├── ieee_spectrum_valid.html                    [Sprint 2]
│       │   ├── iea_valid.html                              [Sprint 2]
│       │   ├── thin_metadata.html                          [Sprint 2]
│       │   ├── paywall_detected.html                       [Sprint 2]
│       │   └── dead_link_404.html                          [Sprint 2]
│       ├── ai_responses/
│       │   ├── high_confidence.json                        [Sprint 3]
│       │   ├── low_confidence.json                         [Sprint 3]
│       │   └── invalid_schema.json                         [Sprint 3]
│       └── test_urls.ts                                    [Sprint 2]
│
└── frontend/
    │
    ├── assets/
    │   └── images/
    │       └── insights/
    │           └── defaults/            ← source images for Storage upload (NOT Flutter assets)
    │               ├── grid_technology.webp                [Sprint 1 — design artifact]
    │               ├── energy_transition.webp              [Sprint 1 — design artifact]
    │               ├── industry_standards.webp             [Sprint 1 — design artifact]
    │               ├── engineering_leadership.webp         [Sprint 1 — design artifact]
    │               ├── policy_markets.webp                 [Sprint 1 — design artifact]
    │               └── innovation.webp                     [Sprint 1 — design artifact]
    │
    ├── pubspec.yaml                                         [existing — MODIFY Sprint 4]
    │
    └── lib/
        ├── features/
        │   │
        │   ├── insights/               ← NEW feature module — entirely new
        │   │   ├── data/
        │   │   │   ├── models/
        │   │   │   │   └── insight_dto.dart                [Sprint 4 — first Flutter file]
        │   │   │   └── repositories/
        │   │   │       └── insights_repository.dart        [Sprint 4]
        │   │   └── presentation/
        │   │       ├── providers/
        │   │       │   └── insights_provider.dart          [Sprint 4]
        │   │       ├── screens/
        │   │       │   └── insights_screen.dart            [Sprint 4]
        │   │       └── widgets/
        │   │           ├── insight_freshness_badge.dart    [Sprint 4]
        │   │           ├── insight_hero_image.dart         [Sprint 4]
        │   │           ├── insights_loading_skeleton.dart  [Sprint 4]
        │   │           ├── insight_card_header.dart        [Sprint 4]
        │   │           ├── insight_card_body.dart          [Sprint 4]
        │   │           ├── insight_card_footer.dart        [Sprint 4]
        │   │           ├── insight_card.dart               [Sprint 4]
        │   │           ├── insights_empty_state.dart       [Sprint 4]
        │   │           ├── insights_error_state.dart       [Sprint 4]
        │   │           ├── insights_end_of_batch_card.dart [Sprint 4]
        │   │           └── insights_stale_banner.dart      [Sprint 4]
        │   │
        │   └── admin/
        │       ├── data/               ← NEW sub-directory under existing admin feature
        │       │   ├── models/
        │       │   │   ├── insight_review_dto.dart         [Sprint 4]
        │       │   │   └── source_dto.dart                 [Sprint 4]
        │       │   └── repositories/
        │       │       └── insights_admin_repository.dart  [Sprint 4]
        │       └── presentation/
        │           ├── providers/
        │           │   └── insights_admin_provider.dart    [Sprint 4]
        │           ├── screens/
        │           │   ├── admin_dashboard_screen.dart     [existing — MODIFY Sprint 4]
        │           │   ├── insights_admin_screen.dart      [Sprint 4]
        │           │   ├── insights_review_screen.dart     [Sprint 4]
        │           │   └── insights_sources_screen.dart    [Sprint 4]
        │           └── widgets/
        │               ├── insights_review_card.dart       [Sprint 4]
        │               ├── insights_pipeline_health_widget.dart [Sprint 4]
        │               └── insights_source_tile.dart       [Sprint 4]
        │
        └── core/
            └── router/
                ├── app_router.dart                         [existing — MODIFY Sprint 4, last]
                ├── router_provider.dart                    [existing — MODIFY Sprint 4, last]
                └── router_provider.g.dart                  [existing — regenerate Sprint 4, last]
    │
    └── test/
        └── features/
            └── insights/
                ├── unit/
                │   ├── insight_dto_test.dart               [Sprint 4]
                │   └── insights_provider_test.dart         [Sprint 4]
                ├── integration/
                │   └── insights_repository_test.dart       [Sprint 4]
                └── widget/
                    ├── insight_card_test.dart              [Sprint 4]
                    └── insights_screen_test.dart           [Sprint 4]
```

**Note on default images:** The 6 WebP files under `frontend/assets/images/insights/defaults/` are design source files only. They are uploaded to Supabase Storage during Sprint 1 setup. They are NOT declared in `pubspec.yaml` flutter.assets and are NOT bundled into the app binary. The Flutter 3rd-level image fallback is a programmatic solid-colour placeholder widget (no asset file required).

---

## 3. FILE RESPONSIBILITY REGISTER

Every file has exactly one job. Every dependency is explicit.

---

### 3.1 — Edge Function Shared Utilities

---

#### `_shared/types.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 — first file created |
| **Path** | `supabase/functions/_shared/types.ts` |
| **Purpose** | Single source of truth for all TypeScript type definitions used across Edge Functions |
| **Consumers** | All Edge Functions and all `_shared/` modules |
| **Lifecycle** | Loaded at import time; never instantiated |

**Exported types:**

- `RawInsight` — shape of an `insights_raw` database row (all columns)
- `CatalystInsight` — shape of a `catalyst_insights` database row (all columns)
- `InsightsSource` — shape of an `insights_sources` database row
- `OGMetadata` — result of Open Graph extraction (`{title, description, imageUrl, publishedAt, author}`)
- `AiEnrichmentInput` — what the AI enrichment module receives (`{headline, description, sourceName, sourceTier, articleDate}`)
- `AiEnrichmentOutput` — validated structure of the Anthropic API response (`{executiveSummary, whyThisMatters, keyTakeaway, suggestedCategory, tags, readingTimeMinutes, confidenceScore}`)
- `CollectResult` — return type of collect_insight (`{rawId, status: 'queued' | 'already_exists' | 'rejected', reason?}`)
- `ValidationResult` — return type of structural_checks (`{passed: boolean, failureCode?, failureReason?}`)
- `DedupResult` — return type of dedup (`{isDuplicate: boolean, duplicateOfId?, level?}`)
- `ImageMirrorResult` — return type of mirror_image (`{heroImageUrl, source: 'mirrored' | 'category_default'}`)
- `LogEntry` — structure of a log record (see §9.3 of Phase 3)
- `ErrorClass` — union type: `'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G'`
- `InsightStatus` — union type of all valid status values

**Dependencies (imports):** None.

---

#### `_shared/logger.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/_shared/logger.ts` |
| **Purpose** | Structured JSON logging to Supabase Edge Function log stream; enforces the Phase 3 §9.3 log schema |
| **Consumers** | All Edge Function index.ts files and all modules that perform external calls |
| **Lifecycle** | Stateless; each call writes one log line |

**Exported functions:**

- `log(entry: Partial<LogEntry>): void` — writes a structured JSON line to stdout; auto-fills `timestamp`
- `logError(params: {functionName, errorClass, errorCode, rawId?, insightId?, sourceId?, message, stack?, retryAttempt?, durationMs}): void` — convenience wrapper that enforces all required error log fields
- `logPipelineEvent(params: {functionName, event, durationMs, ...metadata}): void` — for pipeline throughput metrics

**Private internals:**
- `formatLogEntry(entry)` — merges defaults with provided fields, serialises to JSON

**Dependencies:** `types.ts` (for `LogEntry`, `ErrorClass`)

---

#### `_shared/supabase_client.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/_shared/supabase_client.ts` |
| **Purpose** | Creates and exports a singleton Supabase service-role client for use by all Edge Functions |
| **Consumers** | `collect_insight/index.ts`, `validate_insight/index.ts`, `validate_insight/dedup.ts`, `enrich_insight/index.ts`, `enrich_insight/mirror_image.ts`, `activate_scheduled_insights/index.ts`, `expire_old_insights/index.ts` |
| **Lifecycle** | Instantiated once per Edge Function invocation (Deno isolate lifecycle) |

**Exported:**
- `supabase` — a Supabase JS client initialised with `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` environment variables

**Dependencies:** Supabase JS client (via Deno esm.sh CDN import); no `_shared/` dependencies.

**Environment variables consumed:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

---

#### `_shared/fingerprint.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/_shared/fingerprint.ts` |
| **Purpose** | SHA-256 hashing for URL and title deduplication fingerprints |
| **Consumers** | `collect_insight/index.ts`, `validate_insight/dedup.ts` |
| **Lifecycle** | Stateless pure functions |

**Exported functions:**
- `computeUrlFingerprint(normalizedUrl: string): Promise<string>` — SHA-256 hex digest of the normalised URL string
- `computeTitleFingerprint(normalizedTitle: string): Promise<string>` — SHA-256 hex digest of the normalised title

**Dependencies:** Deno standard library `std/crypto` (no `_shared/` imports)

---

#### `_shared/url_utils.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/_shared/url_utils.ts` |
| **Purpose** | URL normalisation: strips UTM parameters, tracking suffixes, normalises scheme and hostname |
| **Consumers** | `collect_insight/index.ts`, `validate_insight/structural_checks.ts` |
| **Lifecycle** | Stateless pure functions |

**Exported functions:**
- `normalizeUrl(rawUrl: string): string` — strips UTM params, removes trailing slash, lowercases hostname, removes `www.` prefix for domain matching only
- `extractDomain(url: string): string` — returns hostname only (e.g. `ieeexplore.ieee.org`)
- `isHttps(url: string): boolean` — true if URL scheme is `https:`
- `resolveUrl(url: string): Promise<{finalUrl: string, statusCode: number}>` — follows up to 3 redirects via HEAD request; 15s timeout

**Dependencies:** None (Deno built-in `URL`, `fetch`)

---

#### `_shared/og_extractor.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/_shared/og_extractor.ts` |
| **Purpose** | Fetches first 8KB of an article page's HTML `<head>` and extracts Open Graph and fallback metadata |
| **Consumers** | `collect_insight/index.ts` |
| **Lifecycle** | Stateless; one call per URL submission |

**Exported functions:**
- `fetchOGMetadata(url: string): Promise<OGMetadata | null>` — performs HEAD/GET (first 8KB), parses og: tags, falls back to `<title>` and `<meta name="description">`. Returns `null` if fetch fails entirely.
- `detectPaywall(htmlHead: string): boolean` — checks for `isAccessibleForFree: false` in JSON-LD schema embedded in the head HTML

**Private internals:**
- `parseOGTags(html: string): Record<string, string>` — regex-based OG tag extraction
- `parseJsonLd(html: string): Record<string, unknown> | null` — extracts and parses first `<script type="application/ld+json">` block

**Dependencies:** `types.ts` (for `OGMetadata`), `url_utils.ts` (for `resolveUrl`)

---

#### `_shared/domain_validator.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/_shared/domain_validator.ts` |
| **Purpose** | Validates article URLs against the `insights_sources` whitelist; implements sub-path matching for WEF and European Commission |
| **Consumers** | `collect_insight/index.ts`, `validate_insight/structural_checks.ts` |
| **Lifecycle** | Stateless pure functions; source list is passed in (not loaded internally) |

**Exported functions:**
- `findMatchingSource(url: string, sources: InsightsSource[]): InsightsSource | null` — iterates sources, returns the first whose `approved_domain` satisfies either full-domain match or sub-path match
- `isSubPathMatch(url: string, approvedDomain: string): boolean` — returns true if `url` starts with `https://{approvedDomain}`; used when `approved_domain` contains a path segment (e.g. `weforum.org/agenda/energy`)
- `isFullDomainMatch(url: string, approvedDomain: string): boolean` — returns true if URL hostname equals `approved_domain`

**Dependencies:** `types.ts` (for `InsightsSource`)

---

#### `_shared/keyword_scorer.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/_shared/keyword_scorer.ts` |
| **Purpose** | Computes a relevance score (0.0–1.0) for an article against the energy/power engineering domain, used for Tier 2 and Tier 3 source validation |
| **Consumers** | `validate_insight/structural_checks.ts` |
| **Lifecycle** | Stateless pure function; keyword dictionary is hardcoded in this file |

**Exported functions:**
- `computeRelevanceScore(headline: string, description: string): number` — returns 0.0–1.0; scores based on keyword frequency against the hardcoded energy/engineering keyword dictionary

**Private internals:**
- `ENERGY_KEYWORDS: string[]` — primary keyword list (grid, power, transmission, renewable, voltage, watt, substation, transformer, inverter, HVDC, smart grid, SCADA, IEC 61850, protection relay, energy storage, battery, solar, wind, load flow, fault current, generator, turbine, frequency, dispatch, utility, microgrid, DER, interconnection, carbon capture, efficiency)
- `normalizeText(text: string): string` — lowercase + strip punctuation for token matching
- `countKeywordHits(tokens: string[], keywords: string[]): number`

**Dependencies:** None

---

### 3.2 — Edge Function: collect_insight

---

#### `collect_insight/index.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/collect_insight/index.ts` |
| **Purpose** | HTTP POST handler — the sole entry point for submitting article URLs into the pipeline |
| **Trigger** | HTTP POST `/functions/v1/collect_insight` |
| **Authentication** | Bearer JWT with `app_role = 'admin'` (or service-role for V2 RSS poller) |
| **Consumers** | Admin dashboard Flutter (direct HTTP), poll_rss_feeds V2 (internal) |
| **Lifecycle** | One invocation per URL submission; stateless |

**Execution flow (ordered):**
1. Parse and validate request body (`url` required; `source_id` optional; `submitted_via` required)
2. Validate URL is parseable and scheme is HTTPS
3. Call `normalizeUrl()` → produce normalized URL
4. Call `computeUrlFingerprint()` → produce SHA-256 fingerprint
5. Query `insights_raw` for existing row with same `url_fingerprint` → if found, return `already_exists`
6. Load all active `insights_sources` from DB (cached per cold-start within same isolate)
7. Call `findMatchingSource()` → if no match, return `UNAUTHORIZED_SOURCE` rejection
8. Call `fetchOGMetadata()` → produces OGMetadata or null
9. Estimate `reading_time_minutes` using source tier average (Tier 1: 8, Tier 2: 6, Tier 3: 5) if OG provides no word count signal
10. INSERT row into `insights_raw` with `status = 'pending'`, all extracted fields, fingerprint
11. Return `{raw_id, status: 'queued', message}`

**Exported:** Deno `serve()` handler — no named exports

**Dependencies:** `_shared/types.ts`, `_shared/logger.ts`, `_shared/supabase_client.ts`, `_shared/url_utils.ts`, `_shared/og_extractor.ts`, `_shared/fingerprint.ts`, `_shared/domain_validator.ts`

**Environment variables:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

---

### 3.3 — Edge Function: validate_insight

---

#### `validate_insight/structural_checks.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/validate_insight/structural_checks.ts` |
| **Purpose** | Runs all 8 ordered structural checks (fail-fast) against a raw insight row |
| **Consumers** | `validate_insight/index.ts` |
| **Lifecycle** | Stateless; called once per validation run |

**Exported functions:**
- `runStructuralChecks(raw: RawInsight, source: InsightsSource): Promise<ValidationResult>` — runs all checks in order:
  1. Source `is_active` check
  2. Sub-path/full-domain URL match (calls `domain_validator.ts`)
  3. HTTPS scheme check (calls `url_utils.ts`)
  4. URL resolution HTTP 200 check (calls `url_utils.ts` `resolveUrl()`)
  5. Headline length check (≥10, ≤240 chars)
  6. Description length check (≥30 chars)
  7. Article date check (present and ≤90 days ago)
  8. Paywall detection check (JSON-LD `isAccessibleForFree`)
  
  Returns `{passed: true}` if all pass; `{passed: false, failureCode: ErrorCode, failureReason: string}` on first failure.
- `runRelevanceCheck(raw: RawInsight, source: InsightsSource): ValidationResult` — applies tier-specific keyword threshold: Tier 1 exempt; Tier 2 requires score ≥ 0.4; Tier 3 requires score ≥ 0.6. Calls `computeRelevanceScore()`.

**Dependencies:** `_shared/types.ts`, `_shared/domain_validator.ts`, `_shared/url_utils.ts`, `_shared/keyword_scorer.ts`

---

#### `validate_insight/dedup.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/validate_insight/dedup.ts` |
| **Purpose** | Level 1 (URL fingerprint) and Level 2 (title fingerprint) deduplication against both `insights_raw` and `catalyst_insights` |
| **Consumers** | `validate_insight/index.ts` |
| **Lifecycle** | Stateless; called once per validation run after structural checks pass |

**Exported functions:**
- `runDeduplication(rawId: string, urlFingerprint: string, title: string): Promise<DedupResult>` — runs Level 1 then Level 2 (short-circuits at first match):
  - Level 1: queries `insights_raw` and `catalyst_insights` for matching `url_fingerprint` excluding current `rawId`
  - Level 2: normalises title (lowercase, strip punctuation, strip stop words), computes `title_fingerprint` SHA-256, queries both tables for match
  - On timeout/error: returns `{isDuplicate: false}` (fail-open — see Phase 3 §3.3)
- `normalizeTitle(title: string): string` — lowercase, strip punctuation, strip stop words list

**Private stop words list:** `['the','a','an','in','on','at','for','of','to','and','or','but','with','from','by','is','are','was','were','has','have','will','its','this','that','these','those']`

**Dependencies:** `_shared/supabase_client.ts`, `_shared/fingerprint.ts`, `_shared/types.ts`

---

#### `validate_insight/index.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 2 |
| **Path** | `supabase/functions/validate_insight/index.ts` |
| **Purpose** | DB webhook handler — orchestrates the complete validation pipeline for a newly inserted `insights_raw` row |
| **Trigger** | Supabase Database Webhook on `insights_raw` INSERT (status = 'pending') |
| **Authentication** | Service role (webhook fires automatically; no user JWT) |
| **Consumers** | Supabase DB webhook system (not called directly by any user code) |
| **Lifecycle** | One invocation per new `insights_raw` INSERT |

**Execution flow (ordered):**
1. Parse webhook payload; extract `raw_id` from `record.id`
2. Load `insights_raw` row — if `status != 'pending'`, return 200 immediately (idempotency guard)
3. Load corresponding `insights_sources` row via `raw.source_id`
4. Call `runStructuralChecks(raw, source)` — on failure: UPDATE `insights_raw` status = 'rejected', set rejection_reason, return 200
5. Call `runRelevanceCheck(raw, source)` — on failure: UPDATE status = 'rejected', return 200
6. Call `runDeduplication(raw.id, raw.url_fingerprint, raw.title)` — if duplicate: UPDATE status = 'duplicate', set duplicate_of_id, return 200
7. UPDATE `insights_raw` status = 'validated'
8. Invoke `enrich_insight` Edge Function via HTTP POST (service-role call) with `{raw_id}`
9. Log pipeline event: raw_id, checks_run, final_status, duration_ms
10. Return 200 `{}`

**Exported:** Deno `serve()` handler

**Dependencies:** `_shared/types.ts`, `_shared/logger.ts`, `_shared/supabase_client.ts`, `./structural_checks.ts`, `./dedup.ts`

---

### 3.4 — Edge Function: enrich_insight

---

#### `enrich_insight/ai_prompt.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 3 |
| **Path** | `supabase/functions/enrich_insight/ai_prompt.ts` |
| **Purpose** | Builds the exact Anthropic Messages API payload (system prompt + user message) from article metadata |
| **Consumers** | `enrich_insight/ai_client.ts` |
| **Lifecycle** | Stateless pure function |

**Exported functions:**
- `buildEnrichmentPrompt(input: AiEnrichmentInput): {system: string, messages: AnthropicMessage[]}` — constructs the full prompt payload

**System prompt content (description only — not the literal text):** Instructs the model to act as a factual technical summariser; specifies strict output JSON schema; enforces word limits per field (executive_summary ≤80 words, why_this_matters ≤50 words, key_takeaway ≤25 words); prohibits opinion, prediction, and political framing; requires the response be valid JSON only with no surrounding text.

**User message content (description only):** Contains the article headline, description or abstract, source name, source tier label (authoritative / industry / trade), and article date. Formatted as a structured block for reliable parsing.

**Dependencies:** `_shared/types.ts` (for `AiEnrichmentInput`)

---

#### `enrich_insight/ieee_client.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 3 |
| **Path** | `supabase/functions/enrich_insight/ieee_client.ts` |
| **Purpose** | Optional IEEE Xplore API client for fetching article abstracts to use as richer input for AI enrichment |
| **Consumers** | `enrich_insight/index.ts` |
| **Lifecycle** | Instantiated only when `IEEE_API_KEY` env var is present and source domain is `ieeexplore.ieee.org` |

**Exported functions:**
- `fetchIEEEAbstract(articleUrl: string, apiKey: string): Promise<string | null>` — extracts article number from URL, calls IEEE Xplore API, returns abstract text; returns `null` on any failure (timeout, 4xx, parse error, rate limit)

**Private internals:**
- `extractArticleNumber(url: string): string | null` — parses IEEE URL format to extract the numeric article ID
- `callIEEEApi(articleNumber: string, apiKey: string): Promise<Record<string, unknown> | null>` — makes the API call with 10s timeout; respects 429 by returning null

**Dependencies:** `_shared/types.ts`, `_shared/logger.ts`

**Environment variables:** `IEEE_API_KEY` (optional)

---

#### `enrich_insight/ai_client.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 3 |
| **Path** | `supabase/functions/enrich_insight/ai_client.ts` |
| **Purpose** | Wraps the Anthropic Messages API call with retry logic, response validation, and schema enforcement |
| **Consumers** | `enrich_insight/index.ts` |
| **Lifecycle** | Stateless; called once per enrichment (with up to 3 internal retries) |

**Exported functions:**
- `enrichArticle(input: AiEnrichmentInput, apiKey: string): Promise<AiEnrichmentOutput | null>` — calls Anthropic API, parses and validates JSON response, retries up to 3 times with exponential back-off (2s, 4s, 8s); returns `null` if all retries fail

**Private internals:**
- `callAnthropicApi(prompt, apiKey, attempt): Promise<string>` — single API call; model: `claude-haiku-4-5-20251001`; max_tokens: 1024; temperature: 0 (deterministic output)
- `parseAndValidateResponse(responseText: string): AiEnrichmentOutput | null` — JSON.parse, validates all 7 required fields are present with correct types, enforces word limit validation
- `buildRetryPrompt(originalPrompt, failureReason): prompt` — on second attempt, adds explicit JSON-only reminder

**Dependencies:** `./ai_prompt.ts`, `_shared/types.ts`, `_shared/logger.ts`

**Environment variables:** `ANTHROPIC_API_KEY`

---

#### `enrich_insight/mirror_image.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 3 |
| **Path** | `supabase/functions/enrich_insight/mirror_image.ts` |
| **Purpose** | Downloads source OG image, validates it, uploads it to Supabase Storage, returns CDN URL with WebP transform parameters |
| **Consumers** | `enrich_insight/index.ts` |
| **Lifecycle** | Stateless subroutine; called once per enrichment |

**Exported functions:**
- `mirrorHeroImage(params: {insightId, ogImageUrl, category}): Promise<ImageMirrorResult>` — full mirror pipeline; returns CDN URL on success, category default CDN URL on any failure

**Private internals:**
- `downloadImage(url): Promise<{buffer: ArrayBuffer, contentType: string, size: number} | null>` — 15s timeout, max 2 redirects, returns null on failure
- `validateImageDimensions(buffer, contentType): Promise<boolean>` — validates ≥400×200px; see Implementation Risk §12.1 for dimension-check approach
- `uploadToStorage(buffer, contentType, path): Promise<string | null>` — uploads to `insights-images/{insightId}/hero.{ext}` via service role; returns public CDN URL or null
- `appendTransformParams(cdnUrl): string` — appends `?width=1200&quality=85&format=webp` to CDN URL (uses Supabase Storage Image Transformation — see §12.1)
- `getCategoryDefaultUrl(category): string` — maps category code to default image CDN URL from hardcoded constants

**Dependencies:** `_shared/supabase_client.ts`, `_shared/types.ts`, `_shared/logger.ts`

**⚠ Implementation Risk (see §12.1):** WebP conversion is performed via Supabase Storage Image Transformation (URL transform parameters), not in-function. The original image is uploaded in its source format; the CDN URL stored in the database includes `?format=webp&quality=85` transform parameters. This is functionally equivalent — clients receive WebP — but must be confirmed against the Supabase plan's Image Transformation availability.

---

#### `enrich_insight/index.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 3 |
| **Path** | `supabase/functions/enrich_insight/index.ts` |
| **Purpose** | HTTP POST handler — orchestrates AI enrichment and image mirroring; creates the `catalyst_insights` row |
| **Trigger** | HTTP POST from `validate_insight/index.ts` (internal service-role call) |
| **Authentication** | Service role |
| **Consumers** | `validate_insight/index.ts` (only caller) |
| **Lifecycle** | One invocation per validated `insights_raw` row |

**Execution flow (ordered):**
1. Parse request body; extract `raw_id`
2. Check idempotency: query `catalyst_insights` for existing row with `raw_id` — if found, return existing `insight_id`
3. Load `insights_raw` row (must be in `validated` status)
4. Load `insights_sources` row for source metadata
5. If source domain is `ieeexplore.ieee.org` AND `IEEE_API_KEY` is set: call `fetchIEEEAbstract()` → use as description if successful
6. Call `enrichArticle(input)` → on null return after retries: UPDATE `insights_raw.status = 'ai_error'`; return 200 with error payload
7. Map `AiEnrichmentOutput` fields to `catalyst_insights` column names
8. INSERT `catalyst_insights` row with `status = 'review'`, all AI fields, `raw_id`, `source_id`, denormalised source fields, confidence score
9. Call `mirrorHeroImage({insightId, ogImageUrl, category})` — result's `heroImageUrl` is used regardless of success/failure
10. UPDATE `catalyst_insights.hero_image_url` to mirrored or default URL
11. Log all timing metrics (ai_duration_ms, image_duration_ms, total_duration_ms, ai_confidence, image_source)
12. Return 200 `{insight_id, status: 'review', ai_confidence}`

**Exported:** Deno `serve()` handler

**Dependencies:** `_shared/types.ts`, `_shared/logger.ts`, `_shared/supabase_client.ts`, `./ai_client.ts`, `./ieee_client.ts`, `./mirror_image.ts`

**Environment variables:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`, `IEEE_API_KEY` (optional)

---

### 3.5 — Edge Function: activate_scheduled_insights

---

#### `activate_scheduled_insights/index.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `supabase/functions/activate_scheduled_insights/index.ts` |
| **Purpose** | Cron job — promotes insights from `scheduled` to `active` when their `scheduled_at` time has passed |
| **Trigger** | Supabase Edge Function Cron, every 15 minutes (`0/15 * * * *`) |
| **Authentication** | Service role |
| **Consumers** | Cron scheduler only |
| **Lifecycle** | Fires every 15 minutes; fast execution expected (<1s on typical run) |

**Execution flow:**
1. Query `catalyst_insights` WHERE `status = 'scheduled' AND scheduled_at <= now()`
2. If zero rows: log 0-count, return 200
3. Batch UPDATE: set `status = 'active'`, `published_at = now()`, `updated_at = now()`
4. Log `activated_count` and `insight_ids`
5. Return 200 `{activated_count, insight_ids}`

**Alert condition:** `activated_count > 50` — log as P1 alert

**Dependencies:** `_shared/supabase_client.ts`, `_shared/logger.ts`

---

### 3.6 — Edge Function: expire_old_insights

---

#### `expire_old_insights/index.ts`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `supabase/functions/expire_old_insights/index.ts` |
| **Purpose** | Cron job — archives non-evergreen insights older than 30 days and insights from suspended sources |
| **Trigger** | Supabase Edge Function Cron, daily at 02:00 UTC (`0 2 * * *`) |
| **Authentication** | Service role |
| **Consumers** | Cron scheduler only |
| **Lifecycle** | Fires once daily; execution time 1–5 seconds |

**Execution flow:**
1. Query 1: `catalyst_insights` WHERE `status = 'active' AND is_evergreen = false AND published_at < now() - 30 days`
2. Query 2: `catalyst_insights` WHERE `status = 'active' AND source_id IN (SELECT id FROM insights_sources WHERE is_active = false)`
3. Merge both result sets (deduplicate by insight ID)
4. Batch UPDATE: set `status = 'archived'`, `updated_at = now()`
5. Log `archived_count` and `archived_ids`
6. Return 200 `{archived_count, archived_ids}`

**Alert condition:** `archived_count > 100` — investigate unexpected mass expiry

**Dependencies:** `_shared/supabase_client.ts`, `_shared/logger.ts`

---

### 3.7 — Flutter Data Layer

---

#### `insights/data/models/insight_dto.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 — first Flutter file |
| **Path** | `frontend/lib/features/insights/data/models/insight_dto.dart` |
| **Purpose** | Immutable data model for a single Catalyst Insight as returned by the Flutter API query |
| **Consumers** | `InsightsRepository`, `InsightsNotifier`, all widgets in `insights/presentation/widgets/`, `InsightCard` |
| **Lifecycle** | Instantiated by repository from Supabase JSON; passed through provider to widgets; immutable |

**Class: `InsightDto`** (immutable, const constructor)

Fields (14 total — matches Phase 2 §9.2 query contract):
- `id: String`
- `headline: String`
- `summary: String` (maps from `ai_summary`)
- `whyItMatters: String` (maps from `ai_why_matters`)
- `keyTakeaway: String` (maps from `ai_key_takeaway`)
- `heroImageUrl: String?` (maps from `hero_image_url`; nullable — Flutter handles null with placeholder)
- `sourceName: String` (maps from `source_name`)
- `sourceUrl: String` (maps from `source_url`)
- `articleDate: DateTime` (maps from `article_date`)
- `readingTimeMinutes: int` (maps from `reading_time_minutes`)
- `category: String` (maps from `category`)
- `tags: List<String>` (maps from `ai_tags`)
- `publishedAt: DateTime` (maps from `published_at`)
- `isAiGenerated: bool` (maps from `ai_is_generated`)

Named constructors:
- `InsightDto.fromJson(Map<String, dynamic> json)` — maps all 14 fields from Supabase PostgREST JSON response

Computed getters:
- `bool get isNew` — true if `publishedAt` is within the last 24 hours
- `bool get isFromToday` — true if `articleDate` is today (for display label)
- `String get formattedReadingTime` — returns `'${readingTimeMinutes} min read'`

No `toJson()` required (read-only model).

**Dependencies:** Dart core only (no Flutter, no Supabase, no Riverpod)

---

#### `insights/data/repositories/insights_repository.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/data/repositories/insights_repository.dart` |
| **Purpose** | Single access point for all insights data operations — fetches from Supabase PostgREST and manages SharedPreferences cache |
| **Consumers** | `InsightsNotifier` (sole consumer) |
| **Lifecycle** | Instantiated once by Riverpod provider; lives for the provider's lifetime |

**Class: `InsightsRepository`**

Constructor: `InsightsRepository({required SupabaseClient supabase, required SharedPreferences prefs})`

Public interface:
- `Future<List<InsightDto>> fetchInsights({required int page, int limit = 10})` — executes the Phase 3 §6.1 PostgREST query: SELECT 14 fields, WHERE status=active (RLS-enforced), ORDER BY published_at DESC, LIMIT/OFFSET pagination
- `Future<List<InsightDto>?> getCachedInsights()` — reads page-0 cache from SharedPreferences; returns null if no cache exists or cache is stale (>60 minutes)
- `Future<void> cacheInsights(List<InsightDto> insights)` — serialises first page (max 10 items) to SharedPreferences JSON; records cache timestamp
- `bool isCacheStale()` — true if `lastCachedAt` is null or more than 60 minutes ago
- `Future<void> clearCache()` — removes all insights cache keys from SharedPreferences

**Private constants:**
- `_cacheKey = 'insights_cache_v1'`
- `_cacheTimestampKey = 'insights_cache_ts_v1'`
- `_cacheTtlMinutes = 60`
- `_selectedColumns = 'id,headline,ai_summary,...'` — the exact 14-column select string

**Private internals:**
- `_deserializeCache(String jsonString): List<InsightDto>` — parses cached JSON

**Dependencies:** `insight_dto.dart`, Supabase Flutter client (existing), `shared_preferences` package (existing)

---

### 3.8 — Flutter State Layer

---

#### `insights/presentation/providers/insights_provider.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/presentation/providers/insights_provider.dart` |
| **Purpose** | Riverpod NotifierProvider managing the complete state of the Insights feed — loading, pagination, caching, offline, error handling |
| **Consumers** | `InsightsScreen` (primary), `InsightsStaleBanner`, `InsightsEndOfBatchCard` |
| **Lifecycle** | Lazy provider — instantiated only on first Insights tab open; destroyed on app exit |

**Class: `InsightsState`** (immutable value class)

Fields:
- `insights: List<InsightDto>` — all currently loaded insights
- `isLoading: bool` — initial load in progress (before any insights are available)
- `isFetchingMore: bool` — background pagination fetch in progress
- `hasMore: bool` — whether more pages exist (false when last page returned < 10 items)
- `currentPage: int` — next page index to fetch
- `lastFetchedAt: DateTime?` — timestamp of last successful network fetch
- `error: InsightsError?` — null when no error
- `isOffline: bool` — true when showing cache because network is unavailable

`InsightsState.initial()` factory — all fields at default/empty values

**Sealed class: `InsightsError`** with variants:
- `InsightsError.network()` — no connectivity
- `InsightsError.server()` — Supabase returned error response
- `InsightsError.unknown(message: String)` — unexpected failure

**Class: `InsightsNotifier extends Notifier<InsightsState>`**

Public methods:
- `Future<void> fetchInitial()` — checks cache first; if cache is fresh, show cache; always attempt network in background; replaces state on success
- `Future<void> fetchMore()` — guard: returns immediately if `isFetchingMore` or `!hasMore`; appends to `state.insights`; increments `currentPage`
- `Future<void> refresh()` — force network fetch of page 0, ignoring cache; updates cache on success
- `void clearError()` — sets `state.error = null` without re-fetching
- `void _onNetworkError(Object e)` — internal: if cache available, sets `isOffline = true`; otherwise sets `error`

**Provider declaration:**
- `final insightsProvider = NotifierProvider<InsightsNotifier, InsightsState>(InsightsNotifier.new)`

**Riverpod pattern:** `Notifier<InsightsState>` (not `AsyncNotifier` — state is managed synchronously with explicit loading flags; async operations update state mid-execution)

**Pre-fetch trigger:** `InsightsScreen` calls `fetchMore()` when `onPageChanged(index)` fires and `index >= state.insights.length - 2` (2 cards before end of current loaded list)

**Dependencies:** `insight_dto.dart`, `insights_repository.dart`, Riverpod 3.0.3

---

### 3.9 — Flutter UI Layer

---

#### `widgets/insight_freshness_badge.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/presentation/widgets/insight_freshness_badge.dart` |
| **Purpose** | Renders the red "NEW" pill badge for insights published within the last 24 hours |
| **Consumers** | `InsightCard` |

**Widget: `InsightFreshnessBadge`** (StatelessWidget)

Constructor: `InsightFreshnessBadge({required bool isNew})`

Renders: a small rounded pill with red background and white "NEW" label. Returns `SizedBox.shrink()` when `isNew == false`.

**Dependencies:** Flutter only

---

#### `widgets/insight_hero_image.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/presentation/widgets/insight_hero_image.dart` |
| **Purpose** | Full-screen background image using CachedNetworkImage with gradient overlay and programmatic colour placeholder fallback |
| **Consumers** | `InsightCard` |

**Widget: `InsightHeroImage`** (StatelessWidget)

Constructor: `InsightHeroImage({required String? heroImageUrl, required String category})`

Renders:
- `CachedNetworkImage` filling the full card area when `heroImageUrl` is non-null
- A bottom-to-top gradient overlay (dark → transparent) for text legibility
- Programmatic colour placeholder (solid colour mapped from `category` string; no network request) as both the `placeholder` and `errorWidget` of CachedNetworkImage, and the only widget when `heroImageUrl` is null

**Category colour map (6 entries):**
- `grid_technology` → deep navy `#1A2744`
- `energy_transition` → forest green `#1B4332`
- `industry_standards` → dark slate `#2D3748`
- `engineering_leadership` → dark teal `#1A3C4D`
- `policy_markets` → dark burgundy `#3D1A2F`
- `innovation` → dark indigo `#1A1A3D`

**Dependencies:** `cached_network_image` (existing in pubspec), Flutter

---

#### `widgets/insights_loading_skeleton.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/presentation/widgets/insights_loading_skeleton.dart` |
| **Purpose** | Animated shimmer-effect placeholder shown during initial load before first data arrives |
| **Consumers** | `InsightsScreen` |

**Widget: `InsightsLoadingSkeleton`** (StatelessWidget)

Renders a full-screen skeleton that mirrors the InsightCard layout: placeholder for hero image area, placeholder bars for headline, summary, footer. Uses `AnimatedOpacity` pulsing between 0.3 and 0.7 opacity to simulate shimmer without an external package.

**Dependencies:** Flutter only

---

#### `widgets/insight_card_header.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/presentation/widgets/insight_card_header.dart` |
| **Purpose** | Source name and category chip displayed at the top of the card content area |
| **Consumers** | `InsightCard` |

**Widget: `InsightCardHeader`** (StatelessWidget)

Constructor: `InsightCardHeader({required String sourceName, required String category})`

Renders: source name text (small, white, muted) + category chip (rounded pill, category accent colour, white label text).

**Dependencies:** Flutter only

---

#### `widgets/insight_card_body.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/presentation/widgets/insight_card_body.dart` |
| **Purpose** | Main content area — headline, AI summary, "Why it matters", key takeaway |
| **Consumers** | `InsightCard` |

**Widget: `InsightCardBody`** (StatelessWidget)

Constructor: `InsightCardBody({required String headline, required String summary, required String whyItMatters, required String keyTakeaway})`

Renders: headline (large, bold, white), then three labelled sections. Labels are small-caps all-white muted text; body text is white at reduced opacity. Uses `Flexible` + `SingleChildScrollView` within the card's content column to handle occasional long content without overflow.

**Dependencies:** Flutter only

---

#### `widgets/insight_card_footer.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/presentation/widgets/insight_card_footer.dart` |
| **Purpose** | Reading time, article date, AI badge, and "Read Full Article" action button |
| **Consumers** | `InsightCard` |

**Widget: `InsightCardFooter`** (StatelessWidget)

Constructor: `InsightCardFooter({required InsightDto insight})`

Renders: reading time chip + article date text (left side), "AI" badge if `isAiGenerated` (centre), "Read Full Article →" text button (right side).

**"Read Full Article" action:** calls `url_launcher`'s `launchUrl(Uri.parse(insight.sourceUrl), mode: LaunchMode.externalApplication)`. Must check `canLaunchUrl()` first; shows SnackBar if URL cannot be launched.

**Dependencies:** `insight_dto.dart`, `url_launcher` package (add to pubspec.yaml before this file)

---

#### `widgets/insight_card.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/presentation/widgets/insight_card.dart` |
| **Purpose** | Full-screen swipeable card composing all sub-widgets; wrapped in RepaintBoundary for rendering performance |
| **Consumers** | `InsightsScreen` (rendered in PageView) |

**Widget: `InsightCard`** (StatelessWidget)

Constructor: `InsightCard({required InsightDto insight})`

Structure:
```
RepaintBoundary
  └── Stack (fills screen)
      ├── InsightHeroImage (background)
      └── Positioned.fill
          └── Column (bottom-aligned content)
              ├── InsightFreshnessBadge (conditional on insight.isNew)
              ├── InsightCardHeader
              ├── InsightCardBody (Expanded — scrollable)
              └── InsightCardFooter
```

**Dependencies:** `insight_dto.dart`, `insight_hero_image.dart`, `insight_freshness_badge.dart`, `insight_card_header.dart`, `insight_card_body.dart`, `insight_card_footer.dart`

---

#### `widgets/insights_empty_state.dart`

**Widget: `InsightsEmptyState`** (StatelessWidget) — replaces PageView when 0 insights are active. Shows a message indicating no content is available yet and a refresh button. No data dependencies.

---

#### `widgets/insights_error_state.dart`

**Widget: `InsightsErrorState`** (StatelessWidget) — constructor: `InsightsErrorState({required InsightsError error, required VoidCallback onRetry})`. Displays error message and retry button. Maps each `InsightsError` variant to user-facing copy.

---

#### `widgets/insights_end_of_batch_card.dart`

**Widget: `InsightsEndOfBatchCard`** (StatelessWidget) — shown as the last item in the PageView when `!state.hasMore`. Displays a message like "You're all caught up" with the Catalysts branding. Includes a refresh button.

---

#### `widgets/insights_stale_banner.dart`

**Widget: `InsightsStaleBanner`** (StatelessWidget) — constructor: `InsightsStaleBanner({required DateTime? lastFetchedAt})`. Shown at the top of InsightsScreen when `state.isOffline == true`. Displays "Showing cached content from {relative time ago}" and a retry indicator. Hidden when not offline.

---

#### `screens/insights_screen.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/insights/presentation/screens/insights_screen.dart` |
| **Purpose** | Root screen for the Catalyst Insights tab — manages the PageView, pagination trigger, loading/error/empty states, and stale banner |
| **Consumers** | `app_router.dart` (registered as the `/insights` route); `MCMainScaffold` bottom nav index 1 |
| **Lifecycle** | Instantiated when user navigates to Insights tab; full-screen, no scaffold/app bar of its own (it lives inside `MCMainScaffold`) |

**Widget: `InsightsScreen`** (ConsumerStatefulWidget)

State: `InsightsScreenState extends ConsumerState<InsightsScreen>`

`initState()`: calls `ref.read(insightsProvider.notifier).fetchInitial()` on the next frame (post-frame callback — avoids calling during build)

`build()`:
1. Watch `insightsProvider` state
2. Show `InsightsLoadingSkeleton` if `isLoading && insights.isEmpty`
3. Show `InsightsErrorState` if `error != null && insights.isEmpty` (no cache to show)
4. Show `InsightsEmptyState` if `!isLoading && insights.isEmpty && error == null`
5. Show `Stack`:
   - `PageView.builder` (vertical scroll, clip: `Clip.none`)
     - Item count: `insights.length + (hasMore ? 0 : 1)` (extra slot for end-of-batch card)
     - `onPageChanged(index)`: if `index >= insights.length - 2 && hasMore && !isFetchingMore` → call `fetchMore()`
     - Items: `InsightCard(insight: insights[index])` or `InsightsEndOfBatchCard`
   - `Positioned(top: 0)`: `InsightsStaleBanner` (visible only when `isOffline`)
   - `Positioned(bottom: 0)` (optional): subtle loading indicator when `isFetchingMore`

**Dependencies:** `insight_card.dart`, `insights_empty_state.dart`, `insights_error_state.dart`, `insights_end_of_batch_card.dart`, `insights_loading_skeleton.dart`, `insights_stale_banner.dart`, `insights_provider.dart`, Riverpod

---

### 3.10 — Flutter Admin Layer

---

#### `admin/data/models/insight_review_dto.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/admin/data/models/insight_review_dto.dart` |
| **Purpose** | Full `catalyst_insights` row model for admin review — includes all pipeline fields, confidence score, AI fields, and edit flags |
| **Consumers** | `InsightsAdminRepository`, `InsightsReviewScreen`, `InsightsReviewCard` |

**Class: `InsightReviewDto`**

Key fields (in addition to all InsightDto fields):
- `status: String`
- `aiConfidence: double` (maps from `ai_confidence`)
- `aiIsGenerated: bool`
- `aiModel: String`
- `aiProcessedAt: DateTime?`
- `adminEdited: bool`
- `rawId: String?`
- `rejectionReason: String?`
- `scheduledAt: DateTime?`
- `createdBy: String?`

Factory: `InsightReviewDto.fromJson(Map<String, dynamic> json)`

Computed getters:
- `bool get isHighConfidence` → `aiConfidence >= 0.90`
- `bool get isLowConfidence` → `aiConfidence < 0.70`
- `String get confidenceLabel` → `'HIGH' | 'STANDARD' | 'LOW'`

**Dependencies:** Dart core only

---

#### `admin/data/models/source_dto.dart`

**Class: `SourceDto`** — maps `insights_sources` row: `{id, name, approvedDomain, tier, rssUrl, isActive, defaultCategory, notes}`. Factory: `SourceDto.fromJson(json)`.

---

#### `admin/data/repositories/insights_admin_repository.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/admin/data/repositories/insights_admin_repository.dart` |
| **Purpose** | All admin-facing data operations: review queue reads, approve/reject/edit writes, source management, pipeline health queries |
| **Consumers** | `InsightsAdminProvider` (sole consumer) |

**Class: `InsightsAdminRepository`**

Constructor: `InsightsAdminRepository({required SupabaseClient supabase})`

Public interface:
- `Future<List<InsightReviewDto>> fetchReviewQueue()` — SELECT `*` WHERE status='review' ORDER BY ai_confidence DESC, created_at ASC; limit 50
- `Future<List<InsightReviewDto>> fetchHighConfidenceQueue()` — SELECT `*` WHERE status='review' AND ai_confidence >= 0.90
- `Future<void> approveInsight({required String id, DateTime? scheduledAt})` — PATCH status='active' + published_at=now(), or status='scheduled' + scheduled_at
- `Future<void> rejectInsight({required String id, String? reason})` — PATCH status='rejected' + rejection_reason
- `Future<void> editInsight({required String id, required Map<String, dynamic> fields})` — PATCH allowed fields + admin_edited=true
- `Future<BatchApproveResult> batchApproveHighConfidence()` — calls `/rest/v1/rpc/batch_approve_high_confidence`
- `Future<List<SourceDto>> fetchSources()` — SELECT `*` ORDER BY tier, name
- `Future<void> setSouceActiveState({required String id, required bool isActive})` — PATCH is_active
- `Future<PipelineHealth> fetchPipelineHealth()` — runs the 5 health queries from Phase 3 §10.1

**Type: `BatchApproveResult`** — `{approvedCount: int, insightIds: List<String>}`
**Type: `PipelineHealth`** — `{pendingStuck: int, aiErrorDepth: int, reviewDepth: int, activeCount: int, lastPublishedAt: DateTime?}`

**Dependencies:** `insight_review_dto.dart`, `source_dto.dart`, Supabase Flutter client

---

#### `admin/presentation/providers/insights_admin_provider.dart`

| Property | Value |
|----------|-------|
| **Sprint** | Sprint 4 |
| **Path** | `frontend/lib/features/admin/presentation/providers/insights_admin_provider.dart` |
| **Purpose** | Riverpod provider for admin insights state — review queue, source list, pipeline health, and all write operations |
| **Consumers** | `InsightsReviewScreen`, `InsightsSourcesScreen`, `InsightsAdminScreen` |

Three providers declared in this file:
1. `insightsReviewProvider` — `AsyncNotifierProvider` for review queue state (refresh on approve/reject/edit)
2. `insightsSourcesProvider` — `AsyncNotifierProvider` for sources list
3. `insightsPipelineHealthProvider` — `AsyncNotifierProvider` for pipeline health, auto-refreshed every 60 seconds

**Dependencies:** `insights_admin_repository.dart`, `insight_review_dto.dart`, `source_dto.dart`, Riverpod

---

#### Admin screens and widgets (brief specifications)

**`insights_review_card.dart`** — `InsightsReviewCard({required InsightReviewDto insight, required VoidCallback onApprove, required VoidCallback onReject, required VoidCallback onEdit})`. Shows headline, AI summary, source, confidence badge (HIGH/STANDARD/LOW with colour coding), tags, and action buttons. HIGH CONFIDENCE shows one-tap approve. LOW CONFIDENCE shows warning label requiring explicit confirmation.

**`insights_pipeline_health_widget.dart`** — `InsightsPipelineHealthWidget({required PipelineHealth health})`. Shows 5 metric tiles from Phase 3 §10.1 with alert colouring when thresholds are exceeded.

**`insights_source_tile.dart`** — `InsightsSourceTile({required SourceDto source, required VoidCallback onToggleActive})`. Shows source name, tier badge, domain, RSS indicator, and active/suspended toggle.

**`insights_review_screen.dart`** — Scrollable list of `InsightsReviewCard` widgets; batch approve button at top when HIGH CONFIDENCE items exist; pull-to-refresh.

**`insights_sources_screen.dart`** — List of `InsightsSourceTile` grouped by tier (Tier 1, 2, 3 sections); count per tier.

**`insights_admin_screen.dart`** — Tab or navigation shell with two routes: Review Queue and Sources. Shows `InsightsPipelineHealthWidget` at the top.

**Modification to `admin_dashboard_screen.dart`:** Add a new navigation tile "Catalyst Insights" that pushes to `InsightsAdminScreen`. This is the only modification to any existing admin screen.

---

### 3.11 — Database Migration Files

---

#### `migrations/20260717000001_insights_sources.sql`

**Creates:** `insights_sources` table with all columns per Phase 2 §3 Entity 1 definition.
**Creates:** `UNIQUE` constraint on `approved_domain`.
**No foreign keys to other new tables.**
**Must run first.**

---

#### `migrations/20260717000002_insights_raw.sql`

**Creates:** `insights_raw` table with all columns per Phase 2 §3 Entity 2 definition.
**Creates:** `FK → insights_sources(id)` on `source_id`. `FK → auth.users(id)` on `submitted_by`.
**Depends on:** migration 001.

---

#### `migrations/20260717000003_catalyst_insights.sql`

**Creates:** `catalyst_insights` table with all columns per Phase 2 §3 Entity 3 definition.
**Creates:** `FK → insights_sources(id)` on `source_id`. `FK → insights_raw(id)` on `raw_id`. `FK → auth.users(id)` on `created_by`.
**Creates:** `CHECK` constraint on `status` column (enum values: pending, validated, duplicate, rejected, ai_error, ai_processed, review, scheduled, active, archived).
**Depends on:** migrations 001, 002.

---

#### `migrations/20260717000004_insights_v2_tables.sql`

**Creates:** `insights_tags`, `insights_read_state`, `insights_bookmarks` tables (all empty V2 tables — schema defined now, used in V2).
**Depends on:** migration 003.

---

#### `migrations/20260717000005_insights_indexes.sql`

**Creates all indexes** in this order:

`insights_sources` indexes (2):
1. `UNIQUE INDEX` on `approved_domain`
2. `INDEX` on `is_active`

`insights_raw` indexes (4):
1. `UNIQUE INDEX` on `url_fingerprint`
2. `INDEX` on `status`
3. `COMPOSITE INDEX` on `(source_id, status)`
4. `INDEX` on `article_published_at`

`catalyst_insights` indexes (5):
1. `COMPOSITE INDEX` on `(status, published_at DESC)` — PRIMARY performance index for Flutter query
2. `INDEX` on `category`
3. `UNIQUE INDEX` on `url_fingerprint`
4. `INDEX` on `title_fingerprint`
5. `INDEX` on `ai_confidence`

`insights_read_state` index (1): `COMPOSITE INDEX` on `(user_id, insight_id)` (PK)
`insights_bookmarks` index (1): `COMPOSITE INDEX` on `(user_id, insight_id)` (PK)

**Depends on:** migrations 001–004.

---

#### `migrations/20260717000006_insights_rls.sql`

**Enables RLS** on all 6 tables.
**Creates all RLS policies** per Phase 3 §11.2:

`insights_sources` (3 policies): select-all-authenticated, insert-admin, update-admin
`insights_raw` (3 policies): select-admin-only, insert-service-role, update-service-role
`catalyst_insights` (4 policies): select-authenticated-active, select-admin-all-statuses, insert-service-role, update-admin
`insights_tags` (1 policy): select-all-authenticated
`insights_read_state` (3 policies): select-own-rows, insert-own-rows, update-own-rows
`insights_bookmarks` (3 policies): select-own-rows, insert-own-rows, delete-own-rows

**Depends on:** migrations 001–005.

---

#### `migrations/20260717000007_insights_rpc_functions.sql`

**Creates:** `batch_approve_high_confidence()` PostgreSQL function. Behaviour: within a single transaction, SELECT all `catalyst_insights` rows WHERE `status = 'review' AND ai_confidence >= 0.90`, UPDATE each to `status = 'active', published_at = now(), updated_at = now()`, RETURN `{approved_count, insight_ids}`. Caller must have admin role (enforced by SECURITY DEFINER + role check or by RLS).

**Depends on:** migration 003.

---

#### `seed/insights_sources_seed.sql`

**Inserts:** 25 rows into `insights_sources` — all 25 validated sources from Phase 2.5 with correct tier assignments:
- CIGRÉ: `tier = 2` (reclassified from Tier 1 per Phase 2.5)
- EPRI: `tier = 3` (reclassified from Tier 2 per Phase 2.5)
- S&P Global: NOT seeded (excluded per Phase 2.5)
- All others: as specified in Phase 2.5 classification matrix

Each row includes: `name`, `approved_domain`, `tier`, `rss_feed_url` (or null for the 4 without confirmed RSS), `is_active = true`, `default_category`, `notes` (includes compliance notes for IEA and RMI, sub-path note for WEF and EC).

**Run after:** migration 006 (RLS must exist; seed is run via service role).

---

## 4. DEPENDENCY GRAPHS

### 4.1 Backend (Edge Functions)

Read left → right; arrows mean "imports" / "depends on":

```
                            ┌─ types.ts ◄────────────────────────────────────────┐
                            │                                                     │
                            ▼                                                     │
                         logger.ts ◄────────────────────────────────────────┐   │
                            │                                                │   │
                            ▼                                                │   │
                  supabase_client.ts ◄─────────────────────────────────┐   │   │
                            │                                           │   │   │
          ┌─────────────────┼──────────────────────────────────┐       │   │   │
          ▼                 ▼                 ▼                ▼       │   │   │
   fingerprint.ts     url_utils.ts    keyword_scorer.ts    (no deps)   │   │   │
          │                │                 │                          │   │   │
          │                ▼                 │                          │   │   │
          │          og_extractor.ts         │                          │   │   │
          │                │                 │                          │   │   │
          │                ▼                 ▼                          │   │   │
          │        domain_validator.ts  structural_checks.ts            │   │   │
          │                                  │                          │   │   │
          ├────────────────────────────────► │                          │   │   │
          │               dedup.ts ◄─────────┤                         │   │   │
          │                  │               │                          │   │   │
          │                  └───────────────┘                          │   │   │
          │                        │                                    │   │   │
          ▼                        ▼                                    │   │   │
collect_insight/             validate_insight/                          │   │   │
   index.ts ─────────────── index.ts ──────────────► enrich_insight/   │   │   │
                                                          index.ts ─────┘   │   │
                                                       (also imports:)       │   │
                                                      ai_prompt.ts ──────────┘   │
                                                      ai_client.ts ──────────────┘
                                                      ieee_client.ts
                                                      mirror_image.ts

activate_scheduled_insights/index.ts → supabase_client, logger
expire_old_insights/index.ts         → supabase_client, logger
```

**No circular dependencies.** Verified: `types.ts` has no imports from `_shared/`; `fingerprint.ts` has no imports from `_shared/`; `keyword_scorer.ts` has no imports from `_shared/`.

---

### 4.2 Flutter — Features/Insights

```
insight_dto.dart (no deps on new files)
        │
        ├──────────────────────────────────────────────────────────────────┐
        ▼                                                                  │
insights_repository.dart                                                   │
        │                                                                  │
        ▼                                                                  │
insights_provider.dart                                                     │
        │                                                                  │
        ▼                                                                  │
insights_screen.dart ◄─────────────────────────────────────────┐          │
        │                                                       │          │
        ├── insight_card.dart ◄──────────────────────┐         │          │
        │       ├── insight_hero_image.dart           │         │          │
        │       ├── insight_freshness_badge.dart ─────┤         │          │
        │       ├── insight_card_header.dart ──────────────────────────────┘
        │       ├── insight_card_body.dart ──────────────────────┘
        │       └── insight_card_footer.dart (also: url_launcher, insight_dto)
        ├── insights_empty_state.dart (no deps)
        ├── insights_error_state.dart (depends: insights_provider.dart for InsightsError type)
        ├── insights_end_of_batch_card.dart (no deps)
        ├── insights_loading_skeleton.dart (no deps)
        └── insights_stale_banner.dart (depends: InsightsState.lastFetchedAt field type)
```

---

### 4.3 Flutter — Features/Admin (Insights extension)

```
insight_review_dto.dart (no deps on other new files)
source_dto.dart         (no deps on other new files)
        │
        ▼
insights_admin_repository.dart
        │
        ▼
insights_admin_provider.dart
        │
        ├── insights_review_screen.dart ← insights_review_card.dart
        ├── insights_sources_screen.dart ← insights_source_tile.dart
        └── insights_admin_screen.dart
                └── insights_pipeline_health_widget.dart
```

**Admin dependency on insights module:** `insights_admin_screen.dart` does NOT import from `lib/features/insights/` — admin is fully isolated. It queries `catalyst_insights` directly via its own repository. No cross-feature imports.

---

### 4.4 Testing

```
supabase_tests/fixtures/test_urls.ts
supabase_tests/fixtures/og_html/*.html
        │
        ▼
supabase_tests/unit/*.ts ──► imports _shared/* directly (not via Edge Function index.ts)
        │
        ▼
supabase_tests/integration/*.ts ──► imports Edge Function index.ts via test harness
                                     requires: local Supabase instance OR staging project
```

```
frontend/test/features/insights/unit/*.dart
        ──► imports lib/features/insights/** + MockInsightsRepository
frontend/test/features/insights/integration/*.dart
        ──► imports InsightsRepository + real or mock Supabase client
frontend/test/features/insights/widget/*.dart
        ──► imports InsightsScreen/InsightCard + ProviderScope with mock provider
```

---

## 5. DATABASE IMPLEMENTATION MAP

### 5.1 Migration Execution Sequence

The 7 migration files must be applied in this exact order. Each depends on all prior migrations.

| Step | File | Creates | Prerequisite |
|------|------|---------|-------------|
| M01 | `20260717000001_insights_sources.sql` | `insights_sources` table | None — first migration |
| M02 | `20260717000002_insights_raw.sql` | `insights_raw` table | M01 (FK to insights_sources) |
| M03 | `20260717000003_catalyst_insights.sql` | `catalyst_insights` table | M01, M02 (FKs to both) |
| M04 | `20260717000004_insights_v2_tables.sql` | 3 V2 empty tables | M03 (FKs to catalyst_insights) |
| M05 | `20260717000005_insights_indexes.sql` | All 13 indexes | M01–M04 (tables must exist) |
| M06 | `20260717000006_insights_rls.sql` | All RLS policies | M01–M05 (indexes must exist) |
| M07 | `20260717000007_insights_rpc_functions.sql` | batch_approve function | M03, M06 (table + RLS must exist) |

### 5.2 Table Creation Order (within M01–M04)

1. `insights_sources` — no cross-references to other new tables; creates the whitelist
2. `insights_raw` — FK to `insights_sources` (M01 must precede)
3. `catalyst_insights` — FK to `insights_sources` and `insights_raw` (M01 and M02 must precede)
4. `insights_tags` — standalone; no FKs to other new tables
5. `insights_read_state` — FK to `catalyst_insights` and `auth.users`
6. `insights_bookmarks` — FK to `catalyst_insights` and `auth.users`

### 5.3 Index Creation Order (within M05)

Indexes must be created on existing tables only. Order within M05:
1. All `insights_sources` indexes (table created in M01)
2. All `insights_raw` indexes (table created in M02)
3. All `catalyst_insights` indexes (table created in M03)
4. All V2 table indexes (tables created in M04)

**Critical index:** `(status, published_at DESC)` composite on `catalyst_insights` is the single most important index in the system — the Flutter primary feed query uses only this index. It must be created before any Edge Function is deployed.

### 5.4 RLS Policy Creation Order (within M06)

1. Enable RLS on all 6 tables (one statement each, in dependency order)
2. Apply `insights_sources` policies (3)
3. Apply `insights_raw` policies (3)
4. Apply `catalyst_insights` policies (4)
5. Apply V2 table policies (7)

**Verification step (after M06, before M07):** Run the Phase 3 §15.6 security test checklist against a staging project. Do not proceed to Edge Function deployment until all security tests pass.

### 5.5 Seed Execution

The `insights_sources_seed.sql` seed is executed after M06 (RLS is in place) using the service role client (bypasses RLS). It is a one-time operation.

**Seed verification:** After execution, confirm:
- Row count: 25 (not 26 — S&P Global excluded)
- CIGRÉ row: `tier = 2` (not 1)
- EPRI row: `tier = 3` (not 2)
- WEF row: `approved_domain` contains the sub-path (`weforum.org/agenda/energy`)
- EC row: `approved_domain` contains the sub-path (`ec.europa.eu/energy`)
- All rows: `is_active = true`

### 5.6 DB Webhook Configuration

After M06 and Edge Function deployment, configure in Supabase Dashboard:

**Webhook name:** `insights_raw_insert_validate`  
**Table:** `insights_raw`  
**Event:** INSERT  
**Condition:** `status = 'pending'` (filter — only fire when status is pending)  
**Target:** Edge Function `validate_insight`  
**Headers:** include `Authorization: Bearer {SERVICE_ROLE_KEY}`  
**Retry:** 3 retries, 5-second delay  

This is a manual Supabase Dashboard configuration step, not a migration. Document in Sprint 2 deployment checklist.

---

---

## 6. EDGE FUNCTION IMPLEMENTATION MAP

For every Edge Function, this section defines: exact folder layout, which file to create first, internal validation flow, shared utilities used, logging events emitted, environment variables, and test approach.

---

### 6.1 Shared Utilities — Implementation Order

All `_shared/` files must be created before any Edge Function `index.ts`. The order within the shared utilities is:

```
Step 1:  _shared/types.ts          (no imports — must be first)
Step 2:  _shared/logger.ts         (imports types.ts)
Step 3:  _shared/supabase_client.ts (imports nothing from _shared — only env vars + Supabase SDK)
Step 4:  _shared/fingerprint.ts    (imports nothing from _shared — only Deno std/crypto)
Step 5:  _shared/url_utils.ts      (imports nothing from _shared — only Deno built-ins)
Step 6:  _shared/og_extractor.ts   (imports types.ts, url_utils.ts)
Step 7:  _shared/domain_validator.ts (imports types.ts)
Step 8:  _shared/keyword_scorer.ts (imports nothing)
```

Unit tests for each `_shared/` utility are written immediately after the utility is created (test-alongside approach). No utility proceeds to "done" until its unit test file passes.

**Deno import style:** All Supabase SDK imports use the versioned CDN path (e.g. `https://esm.sh/@supabase/supabase-js@2`). Deno standard library imports use `jsr:@std/crypto`. No npm specifiers. No import maps file needed — all imports are explicit URLs.

---

### 6.2 collect_insight — Implementation Map

**Folder:** `supabase/functions/collect_insight/`  
**Files:** single `index.ts` (no sub-modules needed — logic is linear)

**Internal validation flow:**
```
Request arrives
    │
    ├── (1) Parse body → validate url is present and well-formed
    │         fail → 400 {status: 'rejected', reason: 'INVALID_URL'}
    │
    ├── (2) normalizeUrl() → compute fingerprint
    │
    ├── (3) Check insights_raw for existing url_fingerprint
    │         match → 200 {status: 'already_exists', raw_id}
    │
    ├── (4) Load insights_sources → findMatchingSource()
    │         no match → 200 {status: 'rejected', reason: 'UNAUTHORIZED_SOURCE'}
    │
    ├── (5) fetchOGMetadata() — non-blocking; partial metadata acceptable
    │         failure → og_fetch_error = true; continue with partial
    │
    ├── (6) Estimate reading_time_minutes from tier if no OG signal
    │
    ├── (7) INSERT insights_raw row (status = 'pending')
    │
    └── (8) Return 200 {status: 'queued', raw_id, message}
```

**Logging events emitted:**
- On success: `{event: 'collect_insight.queued', raw_id, source_id, og_fetch_duration_ms, url_fingerprint}`
- On duplicate: `{event: 'collect_insight.duplicate', url_fingerprint, existing_raw_id}`
- On unauthorized: `{event: 'collect_insight.unauthorized_source', domain, error_class: 'A', error_code: 'UNAUTHORIZED_SOURCE'}`
- On OG fetch failure: `{event: 'collect_insight.og_fetch_error', url, reason}` (non-blocking)

**Environment variables used:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

**Test approach:** Integration test with staging DB — 5 test cases: valid URL from whitelisted source, duplicate URL, unauthorized domain, URL with broken OG (page returns 404), URL with valid OG metadata.

---

### 6.3 validate_insight — Implementation Map

**Folder:** `supabase/functions/validate_insight/`  
**Files:** `index.ts`, `structural_checks.ts`, `dedup.ts`

**File creation order within this function:**
1. `structural_checks.ts` — pure logic, no DB calls (unit testable in isolation)
2. `dedup.ts` — DB calls via supabase_client
3. `index.ts` — orchestrates the above two

**Internal validation flow:**
```
Webhook fires (insights_raw INSERT)
    │
    ├── (1) Parse webhook payload → extract raw_id
    │
    ├── (2) Load insights_raw row
    │         status != 'pending' → return 200 immediately (idempotency)
    │
    ├── (3) Load insights_sources row via source_id
    │         not found → UPDATE rejected (UNAUTHORIZED_SOURCE); return 200
    │
    ├── (4) runStructuralChecks(raw, source) — 8 checks, fail-fast
    │         │
    │         ├── Check 1: source.is_active == true
    │         ├── Check 2: findMatchingSource(url, [source]) succeeds
    │         ├── Check 3: isHttps(url)
    │         ├── Check 4: resolveUrl(url) returns 200 (HEAD request, max 3 redirects, 10s timeout)
    │         ├── Check 5: headline.length >= 10 && <= 240
    │         ├── Check 6: description.length >= 30
    │         ├── Check 7: articleDate is present && <= 90 days ago
    │         └── Check 8: detectPaywall(htmlHead) == false
    │         fail → UPDATE rejected + rejection_reason; return 200
    │
    ├── (5) runRelevanceCheck(raw, source) — keyword scoring
    │         fail (Tier 2 < 0.4 or Tier 3 < 0.6) → UPDATE rejected (LOW_RELEVANCE); return 200
    │
    ├── (6) runDeduplication(rawId, urlFingerprint, title)
    │         duplicate → UPDATE duplicate + duplicate_of_id; return 200
    │
    ├── (7) UPDATE insights_raw.status = 'validated'
    │
    ├── (8) HTTP POST to enrich_insight with {raw_id} (fire-and-forget with timeout)
    │         enrich_insight failure does NOT cause validate_insight to fail
    │
    └── (9) Return 200 {}
```

**Logging events emitted:**
- `{event: 'validate_insight.result', raw_id, final_status, first_failure_check?, duration_ms}`
- `{event: 'validate_insight.relevance_check', raw_id, score, tier, passed}`
- `{event: 'validate_insight.dedup', raw_id, is_duplicate, level?, duplicate_of_id?}`
- On enrich invocation failure: `{event: 'validate_insight.enrich_invoke_error', raw_id, error}` (non-fatal)

**Note on Check 4 (URL resolution):** The HEAD request in structural_checks must use a 10-second timeout and follow max 3 redirects. Sites that return 405 Method Not Allowed for HEAD (rare but possible) should be retried with GET (first 1KB only).

**Environment variables used:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

---

### 6.4 enrich_insight — Implementation Map

**Folder:** `supabase/functions/enrich_insight/`  
**Files:** `index.ts`, `ai_prompt.ts`, `ai_client.ts`, `ieee_client.ts`, `mirror_image.ts`

**File creation order within this function:**
1. `ai_prompt.ts` — pure prompt builder (no external calls, immediately unit testable)
2. `ieee_client.ts` — optional API client (can be tested with mock)
3. `ai_client.ts` — depends on ai_prompt.ts (unit testable with mocked fetch)
4. `mirror_image.ts` — depends on supabase_client (integration testable with staging Storage)
5. `index.ts` — orchestrates all of the above

**AI prompt engineering checklist** (validate during Sprint 3 before finalising ai_prompt.ts):
- [ ] System prompt specifies output must be ONLY valid JSON — no surrounding text, no markdown
- [ ] System prompt includes the exact 7-field JSON schema with field names matching `AiEnrichmentOutput`
- [ ] System prompt enforces word limits per field in a machine-readable way (e.g. "MUST NOT EXCEED 80 words")
- [ ] User message template tested against 10+ real articles from varied sources (IEEE, IEA, Utility Dive)
- [ ] Confidence score definition is included in the prompt: "Rate your confidence in the accuracy and relevance of your summary as a float from 0.0 (no confidence) to 1.0 (very high confidence)"
- [ ] Category codes are enumerated explicitly: `grid_technology | energy_transition | industry_standards | engineering_leadership | policy_markets | innovation`
- [ ] Prompt tested against a Tier 3 trade publication article to ensure non-commercial editorial framing is maintained

**Internal execution flow:**
```
Request arrives: {raw_id}
    │
    ├── (1) Idempotency: check catalyst_insights for existing row with raw_id
    │         found → return 200 {insight_id, status: 'review', ai_confidence}
    │
    ├── (2) Load insights_raw row (must be status='validated')
    │
    ├── (3) Load insights_sources row (for tier, source_name, source_url)
    │
    ├── (4) Optional IEEE abstract fetch
    │         if source.domain == 'ieeexplore.ieee.org' AND IEEE_API_KEY env var present:
    │             call fetchIEEEAbstract() → use as description if non-null
    │             log: {ieee_api_used: true/false, reason_if_false}
    │
    ├── (5) Build AiEnrichmentInput {headline, description, sourceName, sourceTier, articleDate}
    │
    ├── (6) Call enrichArticle(input) — up to 3 attempts with exponential back-off
    │         Attempt 1: standard prompt
    │         Attempt 2 (if invalid JSON response): retry with explicit schema reminder appended
    │         Attempt 3 (if still invalid): retry with stricter system prompt
    │         All fail → UPDATE insights_raw.status = 'ai_error'
    │                   → return 200 {status: 'ai_error', raw_id, error}
    │
    ├── (7) Validate AiEnrichmentOutput fields (all 7 required, types correct)
    │         fail → treat as AI failure; go to step 6 retry path
    │
    ├── (8) INSERT catalyst_insights row:
    │         - Map all AiEnrichmentOutput fields to DB columns
    │         - Set status = 'review'
    │         - Copy raw_id, source_id, source_name, source_url from raw row
    │         - Set ai_model = 'claude-haiku-4-5-20251001'
    │         - Set ai_processed_at = now()
    │         - Set hero_image_url = null (set in next step)
    │
    ├── (9) Call mirrorHeroImage({insightId, ogImageUrl, category})
    │         Returns CDN URL (mirrored or category default) — never null
    │
    ├── (10) UPDATE catalyst_insights.hero_image_url = mirrorResult.heroImageUrl
    │
    ├── (11) Log all timing metrics
    │
    └── (12) Return 200 {insight_id, status: 'review', ai_confidence}
```

**Anthropic API call specification:**
- Model: `claude-haiku-4-5-20251001`
- Max tokens: 1024 (sufficient for all 7 fields within word limits)
- Temperature: 0 (deterministic; consistent summaries)
- Stop sequences: none (rely on structured output)
- Timeout: 30 seconds per attempt
- Total budget for AI calls: 3 attempts × 30s = 90s max (within the 90s function timeout)

**Logging events emitted:**
- `{event: 'enrich_insight.start', raw_id}`
- `{event: 'enrich_insight.ieee_fetch', raw_id, used: bool, abstract_length?}`
- `{event: 'enrich_insight.ai_call', raw_id, attempt, duration_ms, success}`
- `{event: 'enrich_insight.ai_confidence', raw_id, insight_id, confidence}`
- `{event: 'enrich_insight.image_mirror', raw_id, insight_id, source, duration_ms}`
- `{event: 'enrich_insight.complete', raw_id, insight_id, total_duration_ms}`
- On failure: standard error log per Phase 3 §9.3

**Environment variables used:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`, `IEEE_API_KEY` (optional)

---

### 6.5 activate_scheduled_insights — Implementation Map

**Folder:** `supabase/functions/activate_scheduled_insights/`  
**Files:** single `index.ts`

**Implementation notes:**
- The cron trigger expression `0/15 * * * *` (every 15 minutes) is configured in Supabase Dashboard → Edge Functions → Settings for this function, not in the code
- The function must be idempotent: if two executions overlap (should not occur — Supabase guarantees single-instance cron — but as defence), the second execution finds 0 rows to activate (already activated) and exits cleanly
- Batch size: no artificial limit — activates all due rows in one UPDATE (expected maximum: 5–10 rows per execution in steady state)

**Logging:** `{event: 'activate_scheduled.run', activated_count, insight_ids, duration_ms}`

---

### 6.6 expire_old_insights — Implementation Map

**Folder:** `supabase/functions/expire_old_insights/`  
**Files:** single `index.ts`

**Implementation notes:**
- Runs two queries and merges results before the UPDATE to avoid updating twice
- The 30-day window is calculated as `new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()`
- Suspended-source archival: uses a subquery or join on `insights_sources` — confirm Supabase PostgREST supports this or use raw SQL via `supabase.rpc()` if needed
- The cron trigger `0 2 * * *` (daily 02:00 UTC) is configured in Supabase Dashboard

**Logging:** `{event: 'expire_insights.run', archived_count, from_age: age_expired_count, from_suspended_sources: suspended_count, duration_ms}`

---

## 7. FLUTTER IMPLEMENTATION MAP

### 7.1 Data Layer — Implementation Order

```
Step 1:  pubspec.yaml — add url_launcher (^6.3.0 or latest)
Step 2:  insight_dto.dart
Step 3:  insights_repository.dart
```

**pubspec.yaml modification (Sprint 4, Step 1):**
Add under `dependencies:`:
```yaml
url_launcher: ^6.3.0
```
Run `flutter pub get` immediately after. Verify `url_launcher` is available in the project before writing `insight_card_footer.dart`.

**No other new pubspec dependencies.** `cached_network_image` and `shared_preferences` are already present. `riverpod` / `flutter_riverpod` are already present.

**Supabase column select string** (hardcoded in `insights_repository.dart` as a private constant):
```
id,headline,ai_summary,ai_why_matters,ai_key_takeaway,hero_image_url,
source_name,source_url,article_date,reading_time_minutes,category,
ai_tags,published_at,ai_is_generated
```
This is a single comma-joined string with no spaces, matching the Phase 2 §9.2 query contract exactly.

**SharedPreferences key strategy:**
- `insights_cache_v1` — JSON string of serialised `List<InsightDto>` (first 10 items only)
- `insights_cache_ts_v1` — ISO 8601 string of cache write timestamp
- Version suffix (`_v1`) allows future cache invalidation by changing the key

**Error handling in repository:**
- Network errors: throw `InsightsNetworkException` (custom class defined in insights_repository.dart)
- Supabase errors: throw `InsightsServerException` with message
- Provider catches these and maps to `InsightsError` sealed class variants

---

### 7.2 State Layer — Implementation Order

```
Step 4:  insights_provider.dart
```

**InsightsNotifier.fetchInitial() — exact behaviour:**
1. Set `state = state.copyWith(isLoading: true, error: null)`
2. Try: call `repository.getCachedInsights()`
3. If cache hit AND fresh: set `state.insights = cached`, `isLoading = false`, `isOffline = false` (show cache immediately; still fetch from network below)
4. If cache hit AND stale: show cache with `isOffline = true` while network fetch runs
5. Try network: `repository.fetchInsights(page: 0)`
6. On network success: update `state.insights`, `isLoading = false`, `isOffline = false`, `currentPage = 1`, `hasMore = result.length == 10`, `lastFetchedAt = now()`; call `repository.cacheInsights(result)`
7. On network failure: if cache was shown in step 3/4, set `isOffline = true` and `isLoading = false` (stale banner visible); if no cache, set `error = InsightsError.network()` and `isLoading = false`

**InsightsNotifier.fetchMore() — exact behaviour:**
1. Guard: if `isFetchingMore || !hasMore` return immediately
2. Set `state = state.copyWith(isFetchingMore: true)`
3. Call `repository.fetchInsights(page: state.currentPage)`
4. On success: append to `state.insights`, increment `currentPage`, update `hasMore`, set `isFetchingMore = false`
5. On failure: set `isFetchingMore = false`, set `error` (do not clear existing insights)

**InsightsNotifier.refresh() — exact behaviour:**
1. Set `state = state.copyWith(isLoading: state.insights.isEmpty, isFetchingMore: !state.insights.isEmpty, error: null)`
2. Call `repository.fetchInsights(page: 0)`
3. On success: replace ALL insights with new result, reset `currentPage = 1`, update `hasMore`, set loading flags false, `isOffline = false`, cache the result
4. On failure: restore loading flags, set error if no insights; keep existing insights if they exist

---

### 7.3 UI Layer — Implementation Order

```
Step 5:   insight_freshness_badge.dart
Step 6:   insight_hero_image.dart
Step 7:   insights_loading_skeleton.dart
Step 8:   insight_card_header.dart
Step 9:   insight_card_body.dart
Step 10:  insight_card_footer.dart          ← requires url_launcher (Step 1)
Step 11:  insight_card.dart                 ← requires Steps 5–10
Step 12:  insights_empty_state.dart
Step 13:  insights_error_state.dart
Step 14:  insights_end_of_batch_card.dart
Step 15:  insights_stale_banner.dart
Step 16:  insights_screen.dart              ← requires Steps 5–15 + Step 4 (provider)
```

**Widget hierarchy inside InsightsScreen:**
```
InsightsScreen (ConsumerStatefulWidget)
  └── Stack (full-screen)
      ├── [if isLoading && insights.isEmpty]
      │       InsightsLoadingSkeleton()
      ├── [if error != null && insights.isEmpty]
      │       InsightsErrorState(error: state.error!, onRetry: notifier.fetchInitial)
      ├── [if !isLoading && insights.isEmpty && error == null]
      │       InsightsEmptyState()
      ├── [otherwise]
      │   ├── PageView.builder (vertical, itemCount = insights.length + endCardSlot)
      │   │     item builder:
      │   │       if index < insights.length:
      │   │         RepaintBoundary → InsightCard(insight: insights[index])
      │   │       else:
      │   │         InsightsEndOfBatchCard()
      │   │     onPageChanged: prefetch trigger
      │   ├── Positioned(top: 0): InsightsStaleBanner(lastFetchedAt: state.lastFetchedAt)
      │   │     [only visible when state.isOffline == true]
      │   └── Positioned(bottom: 0): [subtle linear progress when isFetchingMore]
      └── (nothing when loading is done)
```

**PageView configuration:**
- `scrollDirection: Axis.vertical`
- `controller: PageController(viewportFraction: 1.0)` (full-screen cards)
- `physics: const PageScrollPhysics()` (snap to cards; no over-scroll momentum)
- Clip: none (allow cards to peek over edges — requires careful overflow handling)

**Pre-fetch trigger in onPageChanged:**
```
if (index >= state.insights.length - 2
    && state.hasMore
    && !state.isFetchingMore) {
  ref.read(insightsProvider.notifier).fetchMore();
}
```

---

### 7.4 Admin Layer — Implementation Order

```
Step 17:  insight_review_dto.dart
Step 18:  source_dto.dart
Step 19:  insights_admin_repository.dart    ← requires Steps 17, 18
Step 20:  insights_admin_provider.dart      ← requires Step 19
Step 21:  insights_pipeline_health_widget.dart
Step 22:  insights_review_card.dart         ← requires Step 17
Step 23:  insights_source_tile.dart         ← requires Step 18
Step 24:  insights_review_screen.dart       ← requires Steps 20, 22
Step 25:  insights_sources_screen.dart      ← requires Steps 20, 23
Step 26:  insights_admin_screen.dart        ← requires Steps 21, 24, 25
```

**Confidence badge colouring in InsightsReviewCard:**
- HIGH (`>= 0.90`): green background, "HIGH CONFIDENCE — One-tap approve available"
- STANDARD (`0.70–0.89`): neutral/grey background, no special label
- LOW (`< 0.70`): amber/orange background, "LOW CONFIDENCE — Review carefully before approving"

**Edit flow in admin review:** Admin taps "Edit" on a review card → inline edit mode (text fields replace display text in the same card). On confirm → PATCH via repository → card refreshes. No navigation away from the review screen.

**Batch approve UI:** Button appears at top of review screen only when `batchApproveQueue.length > 0`. Tapping shows a confirmation dialog: "Approve {N} high-confidence insights?" → on confirm, calls `batchApproveHighConfidence()` → shows result snackbar "Approved {count} insights."

---

### 7.5 Navigation Wiring — Implementation Order (Last)

Navigation wiring is the final Sprint 4 step. It makes the feature visible to users. All preceding files must be complete and tested before this step.

**Steps (in order):**

**Step 27 — pubspec.yaml platform config for url_launcher:**
Add required Android and iOS configuration for `url_launcher` per the package's README (queries element for Android, LSApplicationQueriesSchemes for iOS in `Info.plist`).

**Step 28 — app_router.dart:**
Add the `/insights` route. The Insights feature uses a `ShellRoute` pattern consistent with existing tab routes. The new route:
- Path: `/insights`
- Widget: `InsightsScreen()`
- Parent shell: existing `MCMainScaffold` shell route (same shell as `/home`, `/challenges`, etc.)
- No transition (uses `NoTransitionPage` consistent with all other tab roots)

**Step 29 — router_provider.g.dart:**
Regenerate via `dart run build_runner build --delete-conflicting-outputs` after modifying `app_router.dart`.

**Step 30 — MCMainScaffold bottom nav:**
Replace the "Explore" tab (index 1) with "Insights" tab. The MCBottomNav item:
- Label: `'Insights'`
- Icon: `Icons.electric_bolt` or equivalent energy-themed icon (to be confirmed with design)
- Active route: `/insights`

**Step 31 — admin_dashboard_screen.dart:**
Add a navigation tile for "Catalyst Insights" that pushes to `InsightsAdminScreen`. This tile goes after existing admin tiles. Modify only the tile list — no other changes to this file.

**Regression test (immediately after Step 31):**
Before committing navigation changes, manually verify all 4 other tabs still navigate correctly:
- Index 0: Home (`/home`) ✓
- Index 1: Insights (`/insights`) ← new
- Index 2: Challenges (`/challenges`) — was index 2, must remain index 2 ✓
- Index 3: Analytics (`/analytics`) ✓
- Index 4: Profile (`/profile`) ✓

**Existing tab indices are not disturbed.** Only index 1 changes content (Explore → Insights).

---

## 8. STORAGE IMPLEMENTATION MAP

### 8.1 Bucket Setup Sequence

Executed during Sprint 1, after database migrations:

```
Step S1: Create bucket 'insights-images' via Supabase Dashboard → Storage
          - Public access: YES
          - File size limit: 5MB
          - Allowed MIME types: image/webp, image/jpeg, image/png, image/gif

Step S2: Verify bucket appears in Supabase Storage dashboard

Step S3: Upload 6 category default images to 'defaults/' folder:
          - defaults/grid_technology.webp
          - defaults/energy_transition.webp
          - defaults/industry_standards.webp
          - defaults/engineering_leadership.webp
          - defaults/policy_markets.webp
          - defaults/innovation.webp

Step S4: Verify each default image is publicly accessible via CDN URL
          URL format: {SUPABASE_URL}/storage/v1/object/public/insights-images/defaults/{name}.webp
          Expected: HTTP 200, Content-Type: image/webp

Step S5: Record all 6 CDN URLs → add them as constants to mirror_image.ts CATEGORY_DEFAULT_URLS map
```

### 8.2 Default Image Specifications

The 6 category default images must be created before Sprint 3 (needed by `mirror_image.ts`). They are design artifacts created outside the codebase:

| Category Code | File | Dimensions | Size Target |
|--------------|------|-----------|-------------|
| `grid_technology` | `grid_technology.webp` | 1200×630px | <300KB |
| `energy_transition` | `energy_transition.webp` | 1200×630px | <300KB |
| `industry_standards` | `industry_standards.webp` | 1200×630px | <300KB |
| `engineering_leadership` | `engineering_leadership.webp` | 1200×630px | <300KB |
| `policy_markets` | `policy_markets.webp` | 1200×630px | <300KB |
| `innovation` | `innovation.webp` | 1200×630px | <300KB |

**Design requirement:** Each image should be a dark, branded abstract with a colour accent matching the category palette defined in `insight_hero_image.dart`. No photographic elements — abstract geometric or typographic only. Must remain legible when Flutter renders text over them.

**Deadline:** Must be uploaded to Storage before Sprint 3 smoke tests begin.

### 8.3 Hero Image Storage Paths

Images written by Edge Function during enrichment:

| Asset | Path | Notes |
|-------|------|-------|
| Mirrored OG image | `insights/{insight_id}/hero.{original_ext}` | Original format; served with transform params |
| Admin-replaced image | `insights/{insight_id}/hero.{ext}` | Overwrites previous; same path |

**CDN URL format with transforms:**  
`{SUPABASE_URL}/storage/v1/object/public/insights-images/insights/{id}/hero.jpg?width=1200&quality=85&format=webp`

The transform parameters (`?width=1200&quality=85&format=webp`) are appended by `mirror_image.ts` when building the `hero_image_url` to store in the database. Flutter clients receive this full URL including transform params and load the WebP version via CDN.

---

## 9. TEST IMPLEMENTATION MAP

### 9.1 Edge Function Test Files

All Edge Function tests use Deno's built-in `Deno.test()` with `@std/assert`. Tests are in `supabase_tests/` (top-level, not inside `supabase/functions/`).

**Unit test files — test against shared utilities directly:**

| File | Tests |
|------|-------|
| `unit/url_utils_test.ts` | normalizeUrl strips UTM params; normalizeUrl lowercases hostname; resolveUrl follows redirects; isHttps detects scheme |
| `unit/fingerprint_test.ts` | computeUrlFingerprint is deterministic; different URLs produce different hashes; normalised URL produces same hash |
| `unit/og_extractor_test.ts` | Extracts og:title, og:description, og:image from valid HTML fixture; falls back to `<title>` when og:title absent; detectPaywall catches `isAccessibleForFree: false` |
| `unit/keyword_scorer_test.ts` | Engineering text scores high; general news scores low; threshold boundary tests |
| `unit/domain_validator_test.ts` | Full domain match; sub-path match (WEF and EC); sub-path non-match (different path); unauthorised domain |
| `unit/structural_checks_test.ts` | Each of the 8 checks triggers the correct failure code in isolation |

**Fixtures used by unit tests:**
- `fixtures/og_html/ieee_spectrum_valid.html` — typical IEEE Spectrum article head (og:title, og:description, og:image, article:published_time)
- `fixtures/og_html/iea_valid.html` — IEA article with thin og:description (tests fallback extraction)
- `fixtures/og_html/thin_metadata.html` — page with no OG tags at all (tests meta description fallback)
- `fixtures/og_html/paywall_detected.html` — page with `isAccessibleForFree: false` in JSON-LD
- `fixtures/og_html/dead_link_404.html` — empty body (simulates 404 response)
- `fixtures/test_urls.ts` — exports test URL constants: `VALID_IEEE_URL`, `VALID_IEA_URL`, `UNAUTHORIZED_DOMAIN_URL`, `HTTP_URL`, `DUPLICATE_URL_1`, `DUPLICATE_URL_2`

**Integration test files — require running Supabase instance (local or staging):**

| File | Tests |
|------|-------|
| `integration/collect_insight_test.ts` | Submit valid URL → row in insights_raw with status pending; duplicate URL → already_exists; unauthorized domain → rejected; OG fetch failure → partial row with og_fetch_error |
| `integration/validate_insight_test.ts` | Each Class A rejection code; pass-through to validated status; dedup Level 1; dedup Level 2 |
| `integration/enrich_insight_test.ts` | AI fields populated on review row; confidence score present; hero_image_url set; ai_error on mocked Anthropic failure |
| `integration/schedulers_test.ts` | activate_scheduled: scheduled insight promoted after scheduled_at passes; expire_old: active insight archived after 30 days |

### 9.2 Flutter Test Files

**Unit tests (no Flutter context required — pure Dart):**

| File | Tests |
|------|-------|
| `unit/insight_dto_test.dart` | `fromJson` maps all 14 fields correctly; `isNew` returns true for <24h publishedAt; `isNew` returns false for >24h; `formattedReadingTime` returns correct string |
| `unit/insights_provider_test.dart` | `fetchInitial` sets isLoading during fetch; success populates insights; network failure with no cache sets error; network failure with cache sets isOffline; `fetchMore` appends to existing list; `fetchMore` does not fire when isFetchingMore; `hasMore` becomes false when < 10 items returned |

**Integration tests (real or mocked Supabase):**

| File | Tests |
|------|-------|
| `integration/insights_repository_test.dart` | `fetchInsights` returns correctly typed List<InsightDto>; pagination OFFSET is correct; `getCachedInsights` returns null before any cache write; `cacheInsights` then `getCachedInsights` returns same data; stale cache (>60 min) returns null |

**Widget tests (Flutter test with ProviderScope):**

| File | Tests |
|------|-------|
| `widget/insight_card_test.dart` | InsightCard renders headline; InsightFreshnessBadge visible when isNew; InsightFreshnessBadge absent when !isNew; InsightHeroImage renders placeholder when heroImageUrl is null; InsightCardFooter shows reading time |
| `widget/insights_screen_test.dart` | Shows loading skeleton during initial load; shows error state when error and no insights; shows empty state when 0 insights and no error; shows cards when insights available; fetchMore called when scrolled to card n-2 |

### 9.3 Mock Strategy

**Edge Function mocks (Deno):**
- Anthropic API: `fetch` is intercepted via a test helper that returns the JSON fixture at `fixtures/ai_responses/{scenario}.json`
- Supabase DB calls: unit tests use a local Supabase instance (via `supabase start`); no in-process mocking
- External URL fetch (OG extraction): return fixture HTML strings directly to `og_extractor.ts` via dependency injection (pass `fetchFn` as a parameter in unit test mode)
- IEEE API: same pattern as Anthropic mock

**Flutter mocks:**
- `MockInsightsRepository` — implements `InsightsRepository` interface; returns hardcoded `List<InsightDto>` with predefined values; can be configured per test to throw specific exceptions
- `SharedPreferences.setMockInitialValues({})` — standard Flutter test pattern; clear before each test
- `MockUrlLauncherPlatform` — registers as `UrlLauncherPlatform.instance`; captures `launchUrl` calls; returns true by default
- `MockCachedNetworkImageProvider` — not needed: tests use `Image.network` interception via `HttpClientMock` OR use `InsightHeroImage` with a null `heroImageUrl` (renders placeholder synchronously, no network)

**Riverpod mocking pattern in widget tests:**
```
// Test provider override pattern (not code — description):
ProviderScope(
  overrides: [
    insightsProvider.overrideWith(() => MockInsightsNotifier(
      initialState: InsightsState(insights: testInsights, isLoading: false, ...)
    )),
  ],
  child: InsightsScreen(),
)
```

### 9.4 Fixture Strategy

**Fixture `InsightDto` factory** (defined in `test/features/insights/unit/insight_dto_test.dart` and shared via import):
- `InsightDto testInsight({String? headline, bool isNew = false, ...})` — returns a complete, valid `InsightDto` with all fields populated; optional named parameters override specific fields
- Used across all Flutter widget and unit tests for consistent test data

**Fixture `InsightReviewDto` factory:** same pattern in admin test directory.

**Fixture HTML files (for OG extractor tests):** static `.html` files stored in `supabase_tests/fixtures/og_html/`; contain only the `<head>` section (no full page needed).

**Fixture AI response files:** static `.json` files at `supabase_tests/fixtures/ai_responses/` containing:
- `high_confidence.json` — all 7 fields, confidenceScore: 0.95, word counts within limits
- `low_confidence.json` — all 7 fields, confidenceScore: 0.62
- `invalid_schema.json` — missing `key_takeaway` field (tests validation rejection)

### 9.5 CI Execution Order

Tests are executed in this order in CI (each step must pass before the next begins):

```
Stage 1 — Database (Sprint 1):
  supabase db reset --local
  supabase db push --local (applies all migrations)
  supabase seed (runs seed file)
  → Manual verification: table counts, RLS spot checks

Stage 2 — Edge Function Unit Tests (Sprint 2):
  deno test supabase_tests/unit/ --allow-read --allow-env
  → Must pass: 100%

Stage 3 — Edge Function Integration Tests (Sprint 2, 3, 4):
  supabase start (or use staging)
  deno test supabase_tests/integration/ --allow-net --allow-env
  → Must pass: 100%

Stage 4 — Flutter Static Analysis (Sprint 4):
  flutter analyze
  → Must pass: 0 errors, 0 warnings

Stage 5 — Flutter Unit Tests (Sprint 4):
  flutter test test/features/insights/unit/
  → Must pass: 100%

Stage 6 — Flutter Widget Tests (Sprint 4):
  flutter test test/features/insights/widget/
  → Must pass: 100%

Stage 7 — Flutter Integration Tests (Sprint 4):
  flutter test test/features/insights/integration/
  → Must pass: 100%

Stage 8 — Full Flutter Test Suite (Sprint 4, pre-release):
  flutter test
  → ALL tests must pass (including existing tests — regression check)

Stage 9 — Build Verification (Sprint 4):
  flutter build apk --release (or ios equivalent)
  → Must succeed: 0 build errors
```

---

## 10. DEVELOPMENT WORKFLOW

### 10.1 Branch Strategy

All Catalyst Insights work happens on feature branches. No direct commits to `main`.

| Branch | Sprint | Purpose |
|--------|--------|---------|
| `feature/insights-sprint-1-database` | Sprint 1 | All migration files, seed file, default image creation |
| `feature/insights-sprint-2-pipeline` | Sprint 2 | Shared utilities, collect_insight, validate_insight, unit tests |
| `feature/insights-sprint-3-enrichment` | Sprint 3 | enrich_insight, mirror_image, AI prompt, integration tests |
| `feature/insights-sprint-4-flutter` | Sprint 4 | All Flutter files, admin screens, schedulers |
| `feature/insights-sprint-4-nav` | Sprint 4 | Navigation wiring only (last PR, separate for easy rollback) |

**The nav wiring branch (`insights-sprint-4-nav`) is a separate PR** so that navigation can be reverted independently without reverting Flutter feature code. This implements the Stage 7 rollback plan from Phase 3.

**PR rules:**
- Every PR requires at least one reviewer
- No PR may be merged if CI fails
- No PR may be merged if `flutter analyze` reports errors
- PRs for Sprints 1–3 do not include any Flutter code

### 10.2 Commit Strategy

Every commit is atomic — one logical unit of change. Prefix all Catalyst Insights commits with `[insights]`.

**Good commit messages:**
- `[insights] Add insights_sources migration with UNIQUE domain constraint`
- `[insights] Implement keyword_scorer with energy domain dictionary`
- `[insights] Add validate_insight structural check 4 — URL resolution with HEAD`
- `[insights] InsightCard renders freshness badge when publishedAt < 24h`

**Bad commit messages:**
- `[insights] Work in progress`
- `[insights] Fix bugs`
- `[insights] Add multiple files`

**Never commit:**
- API keys (ANTHROPIC_API_KEY, SUPABASE_SERVICE_ROLE_KEY, IEEE_API_KEY) — all are environment variables
- Partially-implemented functions (stub implementations only if test still compiles and fails expectedly)
- Failing tests (a test that is intentionally failing must be marked `// TODO:` and skipped, not committed as a failure)

### 10.3 Daily Implementation Sequence

**Sprint 1 (1 week):**
```
Day 1:  Write M01 (insights_sources), M02 (insights_raw), M03 (catalyst_insights) migrations
         Apply to local Supabase; verify tables
Day 2:  Write M04 (V2 tables), M05 (indexes), M06 (RLS) migrations
         Apply; run §9.5 Stage 1 verification
Day 3:  Write M07 (RPC function), seed file
         Apply; verify seed: 25 rows, correct tiers, correct domains
Day 4:  Create Supabase Storage bucket; upload 6 default images; verify CDN URLs
         Create frontend/assets/images/insights/defaults/ with source image files
Day 5:  Sprint 1 Quality Gate review (see §11)
```

**Sprint 2 (1 week):**
```
Day 1:  Create _shared/types.ts, _shared/logger.ts, _shared/supabase_client.ts
         Write url_utils_test.ts (unit tests first for url_utils)
Day 2:  Create _shared/fingerprint.ts, _shared/url_utils.ts, _shared/og_extractor.ts
         Write fingerprint_test.ts, og_extractor_test.ts
Day 3:  Create _shared/domain_validator.ts, _shared/keyword_scorer.ts
         Write domain_validator_test.ts, keyword_scorer_test.ts; run all unit tests
Day 4:  Create collect_insight/index.ts
         Write collect_insight integration test; run against local Supabase
Day 5:  Create validate_insight/structural_checks.ts, validate_insight/dedup.ts
         Write structural_checks_test.ts
Day 6:  Create validate_insight/index.ts
         Configure DB webhook; write validate_insight integration test; run full pipeline (collect → validate)
Day 7:  Sprint 2 Quality Gate review; fix any failing tests
```

**Sprint 3 (1.5 weeks):**
```
Day 1:  Create enrich_insight/ai_prompt.ts
         Test prompt against 5 real articles manually (call Anthropic API directly with test script)
         Iterate prompt until all 5 articles produce valid JSON with correct field structure
Day 2:  Create enrich_insight/ieee_client.ts (with IEEE_API_KEY if available)
         Test IEEE abstract fetch against a real IEEE Xplore article URL
Day 3:  Create enrich_insight/ai_client.ts
         Write mock-based unit test for retry logic; verify 3-attempt back-off works
Day 4:  Create enrich_insight/mirror_image.ts
         Test Storage upload against staging bucket; verify CDN URL with ?format=webp returns WebP
Day 5:  Create enrich_insight/index.ts
         Write enrich_insight integration test; run full pipeline (collect → validate → enrich → review queue)
Day 6:  Test AI enrichment with 10 diverse real articles from different sources/tiers
         Measure: confidence score distribution, word limit compliance, category assignment accuracy
         Iterate prompt if mean confidence < 0.70
Day 7–8: Fix AI prompt issues; finalise enrich integration test; Sprint 3 Quality Gate review
```

**Sprint 4 (1.5 weeks):**
```
Day 1:  Add url_launcher to pubspec.yaml; run flutter pub get
         Create insight_dto.dart; write insight_dto_test.dart; run tests
Day 2:  Create insights_repository.dart; write insights_repository_test.dart (with mock Supabase)
Day 3:  Create insights_provider.dart; write insights_provider_test.dart (all state machine tests)
Day 4:  Create widget files (Steps 5–15: badges, hero image, skeleton, card sub-widgets)
Day 5:  Create insight_card.dart; write insight_card_test.dart; run widget tests
Day 6:  Create insights_screen.dart; write insights_screen_test.dart; run all Flutter tests
Day 7:  Create activate_scheduled_insights, expire_old_insights; configure crons
         Run schedulers_test.ts integration test
Day 8:  Create admin data models, repository, provider (Steps 17–20)
         Create admin widgets and screens (Steps 21–26)
Day 9:  Run full flutter test suite; fix any failures; flutter analyze
Day 10: Navigation wiring (Steps 27–31) on separate branch
         Manual regression test of all 5 tabs
         Run full flutter test suite again; build APK
         Sprint 4 Quality Gate review → Release
```

### 10.4 Review Checklist

Use this checklist for every PR review:

**Database PRs (Sprint 1):**
- [ ] Migration files are numbered in dependency order
- [ ] No hard DELETEs — only soft deletes via status or `is_active`
- [ ] All FK constraints reference correct tables
- [ ] All CHECK constraints cover full enum value set
- [ ] Index on `(status, published_at DESC)` composite exists on `catalyst_insights`
- [ ] RLS: authenticated non-admin CANNOT select `insights_raw`
- [ ] RLS: authenticated non-admin CAN only select active `catalyst_insights`
- [ ] Seed: 25 rows, CIGRÉ tier=2, EPRI tier=3

**Edge Function PRs (Sprints 2–4):**
- [ ] No hardcoded API keys, URLs, or secrets — all via environment variables
- [ ] No npm packages — Deno standard library and Supabase SDK only
- [ ] All external HTTP calls have explicit timeouts
- [ ] All error paths return a 200 response (Edge Functions should not return 5xx to webhook system unless intentionally triggering retry)
- [ ] Logger called at start and end of every significant operation
- [ ] Idempotency guard present in validate_insight and enrich_insight
- [ ] AI_error status set (not thrown) when Anthropic API fails
- [ ] Image mirror failure uses category default (never blocks insight creation)

**Flutter PRs (Sprint 4):**
- [ ] `InsightDto` has no dependencies outside Dart core
- [ ] `InsightsRepository` never called from a widget directly — always via provider
- [ ] No `select *` in repository queries — explicit field list only
- [ ] `RepaintBoundary` wraps each `InsightCard` in PageView
- [ ] `url_launcher` uses `LaunchMode.externalApplication`
- [ ] Offline state shows stale banner, never an error state when cache exists
- [ ] Pre-fetch triggers at `insights.length - 2`, not at end
- [ ] No Supabase imports in any widget file
- [ ] All widget tests run without a network connection (no real Supabase calls)

**Navigation PR (Sprint 4, last):**
- [ ] Insights at index 1 (not index 0, 2, 3, or 4)
- [ ] Existing tabs at correct indices: Home=0, Challenges=2, Analytics=3, Profile=4
- [ ] `/insights` route declared in app_router.dart
- [ ] `router_provider.g.dart` regenerated
- [ ] Admin dashboard has Insights tile

### 10.5 Definition of Done

A file or component is "Done" when all of the following are true:

1. **Written:** File exists at the specified path with the specified responsibility
2. **Compiles:** `flutter analyze` (Flutter) or `deno check` (Edge Function) reports no errors
3. **Tested:** At least one test exists for it; all tests for it pass
4. **Reviewed:** At least one other person has reviewed the PR containing it
5. **Deployed:** Deployed to the staging environment (Edge Functions via `supabase functions deploy`; Flutter via test build)
6. **Verified:** Manually verified against its Exit Criteria (see Phase 3 §16 sprint exit criteria)
7. **Isolated:** Changes to this file do not modify any file outside the `insights_*` namespace (with the single exception of navigation wiring in Sprint 4, which modifies only 3 designated files)

---

## 11. QUALITY GATES

Mandatory checkpoints. Work in the next sprint cannot begin until the gate for the current sprint is passed.

---

### Gate 1 — Sprint 1 → Sprint 2

**Prerequisite:** Database, RLS, Storage, and default images are complete.

| Check | Pass Condition |
|-------|---------------|
| All 6 tables exist | `SELECT count(*) FROM information_schema.tables WHERE table_name LIKE 'insights%' OR table_name = 'catalyst_insights'` returns 6 |
| Critical composite index exists | `EXPLAIN` on Flutter primary feed query shows Index Scan on `(status, published_at)` |
| RLS blocks non-admin from insights_raw | Authenticated non-admin JWT: `SELECT count(*) FROM insights_raw` returns 0 rows (not error) |
| RLS blocks non-admin from inactive insights | Authenticated non-admin JWT: `SELECT count(*) FROM catalyst_insights WHERE status = 'review'` returns 0 rows |
| 25 source rows seeded | `SELECT count(*) FROM insights_sources` returns 25 |
| CIGRÉ tier correct | `SELECT tier FROM insights_sources WHERE name = 'CIGRÉ'` returns 2 |
| EPRI tier correct | `SELECT tier FROM insights_sources WHERE name = 'EPRI'` returns 3 |
| All 6 default images accessible | HTTP GET to each of the 6 default CDN URLs returns 200 |
| Storage bucket public | A CDN URL is accessible without any Authorization header |

**Gate 1 sign-off:** Engineering Manager and Supabase Architect both review the checklist. Document results.

---

### Gate 2 — Sprint 2 → Sprint 3

**Prerequisite:** Collector and Validator are deployed and passing all tests.

| Check | Pass Condition |
|-------|---------------|
| All unit tests pass | `deno test supabase_tests/unit/` — 100% pass rate |
| collect_insight smoke test | POST valid URL → 200 `{status: 'queued'}` → row in insights_raw |
| validate_insight fires on INSERT | DB webhook fires; insights_raw row transitions from pending to validated or rejected within 30 seconds |
| Sub-path domain matching works | POST WEF energy URL → not rejected as UNAUTHORIZED_SOURCE |
| Sub-path domain blocking works | POST non-energy WEF URL → rejected as UNAUTHORIZED_SOURCE |
| URL dedup works | POST same URL twice → second returns `already_exists` |
| Title dedup works | Two different URLs with near-identical titles → second marked duplicate |
| All Class A rejection codes tested | Each of the 9 rejection codes triggers correctly |
| Pipeline smoke: pending → validated | Submit valid IEEE Spectrum URL → row reaches `validated` status |

**Gate 2 sign-off:** Principal Backend Engineer signs off. Staging test log archived.

---

### Gate 3 — Sprint 3 → Sprint 4

**Prerequisite:** Full pipeline to review queue is working.

| Check | Pass Condition |
|-------|---------------|
| AI enrichment produces valid output | 10 test articles all produce valid AiEnrichmentOutput JSON |
| All 7 AI fields populated | No null fields in review queue rows (except nullable ones) |
| Mean confidence ≥ 0.70 | Average confidence across 10 test articles ≥ 0.70 |
| Hero image mirrored | CDN URL in hero_image_url; URL returns 200; WebP format confirmed |
| Category default fallback works | Submit URL with broken OG image → category default CDN URL in hero_image_url |
| ai_error status set on AI failure | Mock Anthropic returning 503 → insights_raw status = ai_error after 3 retries |
| Full pipeline: URL → review queue | Submit URL → within 3 minutes, row appears in catalyst_insights with status=review |
| enrich_insight integration test passes | All test cases in enrich_insight_test.ts pass |
| All prior unit + integration tests still pass | No regression from Sprint 3 changes |

**Gate 3 sign-off:** Principal Backend Engineer and AI Systems Engineer sign off. AI confidence distribution logged.

---

### Gate 4 — Sprint 4 → Release

**Prerequisite:** All Flutter components, admin screens, and schedulers complete.

| Check | Pass Condition |
|-------|---------------|
| `flutter analyze` passes | Zero errors, zero warnings |
| All unit tests pass | `flutter test test/features/insights/unit/` — 100% |
| All widget tests pass | `flutter test test/features/insights/widget/` — 100% |
| Full test suite passes | `flutter test` — 100% (including ALL existing tests) |
| Flutter build succeeds | `flutter build apk --release` exits 0 |
| Insights tab renders | Device: Insights tab shows at index 1; tapping opens InsightsScreen |
| Cards render with real data | 5+ active insights visible; hero images loading; reading time shown |
| Pagination works | Swipe to card 8 → background fetch starts; swipe to card 11+ → works seamlessly |
| "Read Full Article" works | Tapping opens external browser with correct URL |
| Offline works | Disable network after cache populated → stale banner visible, cards browseable |
| End-of-batch card appears | Swipe through all insights → end-of-batch card shows |
| NEW badge appears | Publish insight with publishedAt < 1h ago → red NEW badge visible |
| All existing tabs work | Home, Challenges, Analytics, Profile tabs navigate correctly; no regression |
| Admin review queue works | Admin user: open admin screen → Insights tile → review queue loads |
| Admin approve publishes | Admin approves insight → appears in Flutter feed within 15 minutes |
| Scheduler activate works | scheduled insight activated within 15 minutes of scheduled_at |
| Scheduler expire works | Active insight with publishedAt 31 days ago → archived by expire cron |

**Gate 4 sign-off:** Principal Flutter Engineer, Technical Lead, and Engineering Manager. All acceptance tests (Phase 3 §15.7) documented as passed.

---

## 12. RISK CHECKPOINTS & MITIGATIONS

### Risk 1 — WebP Image Conversion in Deno (HIGH likelihood if not addressed early)

**Risk:** Deno's runtime does not include a native image manipulation API. In-function WebP conversion (as described in Phase 3 §5 Module 5) requires a WASM-based image library, which adds complexity, cold-start latency, and a binary dependency to the Edge Function.

**Mitigation:** Use Supabase Storage Image Transformation instead. When `mirror_image.ts` uploads the original OG image (JPEG/PNG) to Storage, the CDN URL stored in the database includes Supabase transform query parameters: `?width=1200&quality=85&format=webp`. Supabase Storage (on Pro plan) converts the image to WebP at CDN edge on first request and caches it. This is functionally equivalent to in-function conversion but simpler and faster.

**Verification required BEFORE Sprint 3 begins:** Confirm that the Supabase project's plan includes Image Transformation (available on Pro plan and above). Test by uploading a JPEG to the staging `insights-images` bucket and accessing the CDN URL with `?format=webp` — confirm HTTP 200 returns a WebP image.

**Fallback if Image Transformation unavailable:** Upload original format; store original CDN URL; Flutter's `CachedNetworkImage` handles all formats. No WebP conversion. Acceptable for V1.

**Fallback if even the original OG image is a WebP:** Skip conversion entirely — upload as-is; append `?quality=85` only.

---

### Risk 2 — Anthropic API Key Procurement (CRITICAL — blocks Sprint 3)

**Risk:** `ANTHROPIC_API_KEY` must be provisioned and added to Supabase Edge Function secrets before Sprint 3 begins. If procurement is delayed, Sprint 3 cannot start.

**Mitigation:** 
- Initiate API key procurement in Week 1 (Sprint 1), not Sprint 3
- The API key is set in Supabase Dashboard → Edge Functions → Secrets as `ANTHROPIC_API_KEY`
- For Sprint 3 AI prompt development (Day 1), use the API key directly in a local Deno test script — does not require it to be in Supabase yet
- Deadline: API key must be in Supabase secrets by Sprint 3 Day 4

---

### Risk 3 — Category Default Images Not Ready (BLOCKS Sprint 3 smoke test)

**Risk:** The 6 default WebP images must be uploaded to Storage before `mirror_image.ts` can be tested end-to-end. If the design team has not created them by Sprint 3, the smoke test will fail (null category default URL).

**Mitigation:**
- Create placeholder solid-colour WebP images programmatically during Sprint 1 (a single 1200×630 WebP filled with the category colour — no design required) for testing purposes
- Replace with designed versions before Sprint 4 Gate 4
- Deadline for designed images: Sprint 3 Day 4 (uploaded to staging bucket)

---

### Risk 4 — DB Webhook Firing Behaviour (MEDIUM — validate in Sprint 2)

**Risk:** Supabase Database Webhooks fire on INSERT events, but the webhook configuration supports a filter condition (`status = 'pending'`). If the filter is not supported or not working as expected, `validate_insight` may fire on every INSERT regardless of status (causing duplicate validations).

**Mitigation:**
- Validate webhook filter in Sprint 2 Day 6 by inserting a row with `status = 'validated'` directly and confirming `validate_insight` does NOT fire
- `validate_insight` has an idempotency guard (check status != 'pending' at entry; return 200 if already processed) — even if the filter fails, the function handles duplicate fires gracefully
- If webhook filters are not supported: remove the filter; rely on the idempotency guard alone

---

### Risk 5 — Admin Flutter Screens Require `admin` Feature Restructuring (LOW impact)

**Risk:** The existing `admin` feature may not have a `data/` subdirectory. Creating `admin/data/models/` and `admin/data/repositories/` introduces a new directory structure.

**Mitigation:** Creating new subdirectories under an existing feature is safe and non-breaking. Existing admin screens in `admin/presentation/screens/` are not moved or modified (except `admin_dashboard_screen.dart` which gets one new tile). No existing admin files are renamed or deleted.

---

### Risk 6 — GoRouter Route Conflict (LOW — validate before Step 28)

**Risk:** The `/insights` route may conflict with existing routes if Explore was at `/explore` (index 1). After replacement, the Explore route must be removed or redirected.

**Mitigation:**
- Before adding `/insights`, check `app_router.dart` for any existing `/explore` route
- If found: remove it entirely (Explore is being replaced, not hidden)
- If any existing screen has a GoRouter link to `/explore` (deep link or programmatic): update that link to point to a different screen or remove it
- Check `route_names.dart` (seen in git status as modified) for any `explore` constant — update or remove

---

### Risk 7 — `router_provider.g.dart` Code Generation (LOW — known workflow)

**Risk:** After modifying `app_router.dart`, `router_provider.g.dart` must be regenerated. Forgetting this step or committing a stale `.g.dart` file causes build failures.

**Mitigation:** 
- Step 29 in the navigation wiring sequence explicitly regenerates this file
- The PR checklist includes checking that `router_provider.g.dart` is regenerated (not stale)
- Run `dart run build_runner build --delete-conflicting-outputs` in `frontend/` directory after any route change

---

### Risk 8 — Supabase RLS Policy for `batch_approve_high_confidence` RPC (MEDIUM)

**Risk:** The `batch_approve_high_confidence` PostgreSQL function needs to run UPDATE operations on `catalyst_insights`. If the function is defined with `SECURITY INVOKER` (default), it inherits the caller's JWT permissions — requiring the calling admin JWT to have UPDATE permission on `catalyst_insights`. If defined with `SECURITY DEFINER`, it runs as the function owner (typically the Supabase postgres superuser) — bypassing RLS.

**Mitigation:** 
- Define as `SECURITY INVOKER` (not `SECURITY DEFINER`) so that:
  - Admin JWT must have UPDATE permission on `catalyst_insights` (which it does, per RLS policy)
  - Non-admin JWT calling this RPC gets 403 (RLS blocks the UPDATE)
- This is the safer approach — no privilege escalation
- Test: non-admin JWT calling `/rest/v1/rpc/batch_approve_high_confidence` → 0 rows updated (RLS blocks)

---

## 13. FINAL VALIDATION

### File Ownership Completeness

Every file in §2 has an assigned sprint and a defined responsibility in §3. No file is listed without purpose.

| Section | Files defined | All have owners? |
|---------|-------------|-----------------|
| §3.1 Shared utilities | 8 files | ✓ |
| §3.2 collect_insight | 1 file | ✓ |
| §3.3 validate_insight | 3 files | ✓ |
| §3.4 enrich_insight | 5 files | ✓ |
| §3.5 activate_scheduled | 1 file | ✓ |
| §3.6 expire_old_insights | 1 file | ✓ |
| §3.7 Flutter data layer | 2 files | ✓ |
| §3.8 Flutter state layer | 1 file | ✓ |
| §3.9 Flutter UI layer | 12 files | ✓ |
| §3.10 Flutter admin layer | 8 files | ✓ |
| §3.11 Database migrations | 7 migrations + 1 seed | ✓ |
| **Total new files** | **49 files** | ✓ All owned |

Existing files modified: 5 (`pubspec.yaml`, `app_router.dart`, `router_provider.dart`, `router_provider.g.dart`, `admin_dashboard_screen.dart`)

### Dependency Acyclicity

All dependency graphs in §4 are directed acyclic graphs (DAGs). Verified:
- No `_shared/` file imports from an Edge Function
- No Flutter widget imports from `InsightsRepository` directly
- No `insight_dto.dart` imports from Flutter or Riverpod
- No admin feature imports from `lib/features/insights/`
- No `collect_insight/index.ts` imports from `validate_insight/`
- No `validate_insight/index.ts` imports from `enrich_insight/`

### Build Order Validity

The implementation order in §7.3 (Steps 5–16) has been verified: each file is listed after all files it imports from. No step in the sequence requires a file that doesn't yet exist.

### Isolation Guarantee

Files created in this project:
- All backend: `supabase/functions/collect_insight/`, `validate_insight/`, `enrich_insight/`, `activate_scheduled_insights/`, `expire_old_insights/`, `_shared/`
- All Flutter: `lib/features/insights/`, `lib/features/admin/data/`, `lib/features/admin/presentation/providers/`, `lib/features/admin/presentation/screens/insights_*`, `lib/features/admin/presentation/widgets/insights_*`
- All tests: `supabase_tests/`, `test/features/insights/`
- All migrations: 7 new files in `supabase/migrations/`, 1 seed file

**Zero existing file modifications** except: `pubspec.yaml` (one new dependency), `app_router.dart` (one new route), `router_provider.dart` (route registration), `router_provider.g.dart` (regenerated), `admin_dashboard_screen.dart` (one new navigation tile).

The feature can be entirely disabled by reverting the `feature/insights-sprint-4-nav` branch — no backend changes are required.

---

## 🟢 PHASE 3.5 COMPLETE — IMPLEMENTATION SPECIFICATION LOCKED

**All requirements satisfied:**

✓ Every file has an owner (49 new files, each with defined purpose, interface, dependencies, consumers, lifecycle)  
✓ Every dependency is known (§3 and §4 — all imports declared; acyclicity verified)  
✓ Build order is fixed (§7 — strict total ordering; no file requires a file created after it)  
✓ No circular dependencies (§4 — all dependency graphs are DAGs)  
✓ Existing application remains isolated (5 targeted modifications to existing files only; all other changes are additive new files)  
✓ Database implementation map complete (§5 — 7 migrations in dependency order, seed order, RLS verification step, webhook config step)  
✓ Edge Function implementation map complete (§6 — validation flows, logging events, env vars, test approach per function)  
✓ Flutter implementation map complete (§7 — 31-step ordered sequence; exact state machine behaviour for InsightsNotifier; widget hierarchy specified)  
✓ Storage implementation map complete (§8 — 5-step bucket setup, image specs, CDN URL format with transforms)  
✓ Test implementation map complete (§9 — unit tests, integration tests, widget tests, mock strategy, fixture strategy, CI execution order)  
✓ Development workflow complete (§10 — branch strategy, commit strategy, daily sequence per sprint, review checklist, definition of done)  
✓ Quality gates defined (§11 — 4 gates with explicit pass/fail conditions; sign-off requirements)  
✓ Risk checkpoints complete (§12 — 8 identified risks with likelihood, mitigation, and verification steps)  

**Implementation teams may begin Sprint 1 immediately.**

