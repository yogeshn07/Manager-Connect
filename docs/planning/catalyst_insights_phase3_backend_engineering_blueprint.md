# CATALYST INSIGHTS
## Phase 3 — Backend Engineering Blueprint

**Application:** The Catalysts  
**Feature:** Catalyst Insights  
**Document Phase:** Phase 3 — Backend Engineering Blueprint  
**Status:** ENGINEERING DESIGN ONLY — No production code, no SQL, no Flutter, no Edge Function implementation  
**Depends On:**  
- Phase 1 — `catalyst_insights_phase1_product_design.md` (LOCKED)  
- Phase 2 — `catalyst_insights_phase2_content_architecture.md` (LOCKED)  
- Phase 2.5 — `catalyst_insights_phase2_5_source_validation.md` (LOCKED)  
**Date:** 2026-07-17  
**Author:** Principal Backend Engineer / Principal Software Architect / Principal Supabase Architect / Principal Database Architect / Principal API Architect / Principal Flutter Integration Architect / Enterprise Systems Engineer

---

## 1. EXECUTIVE SUMMARY

This blueprint translates the locked architecture (Phase 2) and validated source strategy (Phase 2.5) into a concrete engineering specification. Every backend component is described precisely enough for implementation to begin without requiring architectural decisions during development.

The blueprint covers eight backend modules, nine Edge Functions, five database entities, one storage bucket, four scheduled jobs, a unified error taxonomy, an observability system, a security boundary map, performance targets, a seven-stage deployment plan, per-stage rollback procedures, a testing strategy across six test categories, and a four-sprint implementation roadmap.

**The existing application is not touched in any sprint. Catalyst Insights is deployed as a fully isolated additive module that shares only the Supabase project and authentication system with the existing application.**

---

## 2. SYSTEM OVERVIEW

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║               CATALYST INSIGHTS BACKEND — MODULE MAP                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝

  INGESTION LAYER                  PROCESSING LAYER              PUBLICATION LAYER
  ─────────────────                ─────────────────             ─────────────────
  [Insights Collector] ──────────► [Insights Validator] ──────► [AI Enrichment Service]
       │                                   │                           │
       │                                   ▼                           ▼
       │                          [Deduplication Service]    [Image Mirror Service]
       │                                   │                           │
       ▼                                   └───────────────────────────┘
  [insights_raw]                                     │
                                                     ▼
                                          [Admin Review Service]
                                                     │
                                                     ▼
                                          [Publication Service]
                                                     │
                                                     ▼
                                          [catalyst_insights]
                                                     │
                              ┌──────────────────────┼──────────────────────┐
                              ▼                      ▼                      ▼
                     [Scheduler Layer]      [Flutter API Layer]    [Expiry Service]
                    (cron jobs)             (PostgREST SELECT)    (cron job)
```

---

## 3. BACKEND MODULE SPECIFICATIONS

### Module 1: Insights Collector

**Purpose:** The single entry point for all content entering the pipeline. Accepts article URLs from admin submissions (V1) or the RSS poller (V2), normalises the URL, fetches only publicly available Open Graph metadata, and writes a raw record to the ingest queue.

**Responsibilities:**
- Accept a URL and optional source hint
- Normalise URL: strip UTM parameters, remove tracking suffixes, lowercase hostname, remove trailing slash
- Compute SHA-256 fingerprint of normalised URL
- Perform a fast pre-check: does this fingerprint already exist in `insights_raw`? If yes, return early with status `already_exists` — no duplicate write
- Fetch the page's HTML `<head>` section only (limited GET, first 8KB)
- Extract OG tags: `og:title`, `og:description`, `og:image`, `article:published_time`
- Extract fallbacks: `<title>`, `<meta name="description">`, `article:author`
- Estimate reading time using source-tier average if no word count is detectable
- Write single row to `insights_raw` with status `pending`
- Return the new `raw_id` to the caller

**Inputs:**
```
{
  url: string (required),
  source_id: string (optional, UUID of insights_sources row),
  submitted_via: 'manual' | 'rss' | 'webhook'
}
```

**Outputs:**
```
{
  raw_id: string,
  status: 'queued' | 'already_exists' | 'source_not_found',
  message: string
}
```

**Dependencies:**
- `insights_sources` table (read: verify source domain exists, retrieve tier)
- `insights_raw` table (write: new row)
- External HTTP: target article page (read-only, 8KB HEAD/GET)

**Failure modes:**
- Source domain not in whitelist → return `{status: 'rejected', reason: 'UNAUTHORIZED_SOURCE'}` without writing
- URL does not resolve (DNS failure, timeout) → write row with status `pending`, set `og_fetch_error = true`; let validator handle
- URL resolves but 4xx/5xx → write row, validator will reject with `DEAD_LINK`
- HTML parse fails → write row with partial metadata; validator runs completeness check

**Recovery strategy:** All failures are non-fatal. A failed collection writes a traceable row to `insights_raw` with enough metadata for an admin to investigate. No retry loop in the collector — each submission is a discrete event.

---

### Module 2: Insights Validator

**Purpose:** Quality gate. Runs every automated check defined in Phase 2 §4 Stage 3 against a newly created `insights_raw` row. Determines whether the content is fit to proceed to AI enrichment or should be rejected.

**Responsibilities:**
- Receive `raw_id` from DB webhook
- Load the full `insights_raw` row
- Load the corresponding `insights_sources` row (for tier and `is_active`)
- Run all structural checks in order (fail-fast: stop on first failure):
  1. Source `is_active = true`
  2. Source domain matches URL (with sub-path support for WEF/EC)
  3. URL scheme is HTTPS
  4. URL resolves to HTTP 200 (follow max 3 redirects)
  5. Headline length ≥ 10 chars, ≤ 240 chars
  6. Description length ≥ 30 chars
  7. Article date present and ≤ 90 days ago
  8. No paywall indicator (`isAccessibleForFree: false` in JSON-LD schema)
- Run tier-specific keyword relevance check (Tier 2 score ≥ 0.4, Tier 3 score ≥ 0.6; Tier 1 exempt)
- Invoke Deduplication Service
- On failure: update `insights_raw.status = 'rejected'`, set `rejection_reason` code, return
- On success: update `insights_raw.status = 'validated'`, invoke AI Enrichment Service

**Inputs:** DB webhook payload containing `raw_id`

**Outputs:** Updated `insights_raw` row (status + rejection_reason, or promotion to AI enrichment)

**Dependencies:**
- `insights_raw` table (read/write)
- `insights_sources` table (read)
- Deduplication Service (invoked inline)
- External HTTP: URL resolution check (HEAD request only)
- Keyword relevance dictionary (internal, loaded from config or hardcoded constants)

**Failure modes:**
- Validator crashes mid-run → `insights_raw` row remains in `pending` status; can be manually re-triggered by admin; will not block other records
- External URL check times out → treat as `DEAD_LINK` rejection; safe to reject
- `insights_sources` row not found → reject with `UNAUTHORIZED_SOURCE`; this should not occur if collector ran correctly

**Recovery strategy:** Each validation is stateless and idempotent. If a row remains stuck in `pending`, admin can re-trigger validation. No automatic retry for validation failures — human review is appropriate.

---

### Module 3: Deduplication Service

**Purpose:** Prevent the same article (or the same story from multiple sources) from entering the feed. Runs inside the Insights Validator immediately after structural checks pass.

**Responsibilities:**

**Level 1 — URL fingerprint match:**
- Query `insights_raw` for any existing row where `url_fingerprint = {current_fingerprint}` AND `id != {current_raw_id}`
- Also query `catalyst_insights` for `url_fingerprint` match (insights that were already promoted)
- If match found: mark current row as `duplicate`, set `duplicate_of_id`

**Level 2 — Title fingerprint match:**
- Normalise title: lowercase, strip punctuation, strip stop words (the, a, an, in, on, at, for, of, to, and, or, but, with, from, by)
- SHA-256 of normalised title
- Query `insights_raw` and `catalyst_insights` for matching `title_fingerprint`
- If exact match: mark as `duplicate`, set `duplicate_of_id`

**Level 3 — Cross-source story detection (V2 only):**
- Not implemented in V1
- Deferred to V2: TF-IDF vector comparison of `{headline} + {description}` against records from past 72 hours
- In V1 this check is skipped entirely

**Inputs:** `raw_id`, pre-computed `url_fingerprint`, title text

**Outputs:** `{is_duplicate: boolean, duplicate_of_id: string | null, level: 1 | 2 | null}`

**Dependencies:**
- `insights_raw` table (read: fingerprint queries)
- `catalyst_insights` table (read: fingerprint queries)
- No external calls

**Failure modes:**
- DB query timeout → treat as non-duplicate (let it proceed; admin may see near-duplicate in review queue, which is acceptable)
- Hash collision (SHA-256 on URLs) → statistically negligible; false negative is preferable to false positive

**Recovery strategy:** Deduplication errors are non-critical. A near-duplicate may occasionally reach the admin review queue. Admin recognises and rejects it. No retry needed.

---

### Module 4: AI Enrichment Service

**Purpose:** Transform raw article metadata into publication-ready structured content by calling the Anthropic Claude API. Produces the seven AI-generated fields that appear on the Catalyst Insights card.

**Responsibilities:**
- Load the validated `insights_raw` row
- Check if source is `ieeexplore.ieee.org` AND `IEEE_API_KEY` env var is present → fetch abstract via IEEE API; use abstract as description input instead of OG description
- Construct system prompt + user message:
  - System prompt: factual summarisation instructions, output format contract, word limits, restriction against opinion/political framing
  - User message: headline, description (or abstract), source name, publication date, source tier
- Call Anthropic Claude API (model: claude-haiku-4-5-20251001)
- Enforce structured JSON output (use Anthropic's structured output / JSON mode)
- Validate response against expected schema (all 7 fields present, types correct, word limits honoured)
- If AI response is invalid: retry once with explicit schema reminder; if still invalid: set status `ai_error`, queue for manual review
- Write result to a new `catalyst_insights` row with status `review`
- Invoke Image Mirror Service

**Inputs:** `raw_id` (UUID)

**Outputs:** New `catalyst_insights` row (status = `review`), populated with all AI fields

**Dependencies:**
- `insights_raw` table (read)
- `catalyst_insights` table (write: new row)
- Anthropic Claude API (external)
- IEEE API (external, optional)
- Image Mirror Service (invoked after row creation)
- Environment variables: `ANTHROPIC_API_KEY`, `IEEE_API_KEY` (optional)

**Failure modes:**
- Anthropic API unavailable: exponential back-off, 3 retries (2s, 4s, 8s); if all fail → set `insights_raw.status = 'ai_error'` for manual retry
- Anthropic API returns malformed JSON: retry with stricter prompt; if second attempt fails → `ai_error`
- IEEE API unavailable: fall back to OG metadata silently; log the fallback
- `catalyst_insights` row creation fails (DB error): log and set `insights_raw.status = 'ai_error'`

**Recovery strategy:** `ai_error` status in `insights_raw` is surfaced in the admin dashboard as a separate queue section ("Failed — Needs Attention"). Admin can trigger re-enrichment with a single tap. Re-enrichment re-runs the full AI step without re-validating or re-deduplicating.

---

### Module 5: Image Mirror Service

**Purpose:** Download the source article's Open Graph image, validate it, convert it to WebP, upload it to Supabase Storage, and return the CDN URL. Runs as a subroutine inside the AI Enrichment Service immediately after the `catalyst_insights` row is created.

**Responsibilities:**
- Receive `insight_id` and `og_image_url`
- Download the image (follow max 2 redirects, timeout 15 seconds)
- Validate:
  - File size ≤ 5MB
  - Dimensions ≥ 400 × 200px
  - Format is JPEG, PNG, WebP, or GIF
- Convert to WebP at 85% quality using server-side image processing (Deno's native Canvas API or a Deno WebAssembly image library)
- Upload to `insights-images/{insight_id}/hero.webp` in Supabase Storage (service role client)
- Retrieve the public CDN URL from Supabase Storage
- Update `catalyst_insights.hero_image_url` to the CDN URL
- If any step fails: update `hero_image_url` to the category default image CDN URL; log the failure reason

**Inputs:**
```
{
  insight_id: string,
  og_image_url: string | null,
  category: string (for fallback image selection)
}
```

**Outputs:**
```
{
  hero_image_url: string (CDN URL — always populated, either mirrored or fallback),
  source: 'mirrored' | 'category_default' | 'flutter_placeholder',
  error: string | null
}
```

**Dependencies:**
- External HTTP: OG image download (read-only)
- Supabase Storage: write (`insights-images` bucket, service role)
- `catalyst_insights` table (update: `hero_image_url`)
- Category default image CDN URLs (loaded from environment config or constants)

**Failure modes:**
- Image download timeout → use category default
- Image too small or too large → use category default
- Unsupported format → use category default
- Supabase Storage PUT fails → log the error; `hero_image_url` remains null temporarily; retry at admin's next approval step sets it to fallback; Flutter handles null `hero_image_url` with placeholder rendering

**Recovery strategy:** Image mirroring failure never blocks insight publication. The fallback hierarchy (mirrored → category default → Flutter placeholder) ensures the card always renders. Image failures are logged but do not require human intervention.

---

### Module 6: Admin Review Service

**Purpose:** The backend interface for the admin's review workflow. Provides endpoints for reading the review queue, approving, rejecting, editing, and batch-approving insights. Does not implement its own screen — the Flutter admin dashboard consumes these endpoints.

**Responsibilities:**
- Expose the review queue: `catalyst_insights` rows where `status = 'review'`, ordered by `ai_confidence DESC, created_at ASC`
- Expose batch of HIGH CONFIDENCE items: `ai_confidence >= 0.90`
- Accept approve action: set `status = 'active'` (immediate) or `status = 'scheduled'` with `scheduled_at` (future)
- Accept reject action: set `status = 'rejected'`, store optional `rejection_reason`
- Accept field edits: admin may update `headline`, `ai_summary`, `ai_why_matters`, `ai_key_takeaway`, `category`, `ai_tags`, `reading_time_minutes`; set `admin_edited = true` on any edit
- Accept batch approve: approve all items where `ai_confidence >= 0.90` and `status = 'review'` in a single operation
- All write operations require admin JWT (RLS enforces this at DB level)
- All write operations record `created_by` (admin's profile ID)

**Inputs (per endpoint):** See API Blueprint (§8) for full request/response contracts.

**Outputs:** Updated `catalyst_insights` rows; confirmation payload

**Dependencies:**
- `catalyst_insights` table (read/write)
- Supabase Auth (JWT validation + role check)
- Publication Service (invoked implicitly when status → active/scheduled)

**Failure modes:**
- Admin JWT expired → 401; Flutter shows re-authentication prompt
- Row modified by another session between read and write (optimistic concurrency) → 409; admin refreshes queue
- Batch approve partial failure → atomic: either all succeed or none; return error with count

**Recovery strategy:** All admin operations are synchronous and logged. Failures are surfaced immediately in the admin UI. No background retry for admin actions — human confirmation is part of the flow.

---

### Module 7: Publication Service

**Purpose:** Manages the status transitions that make an insight visible to Flutter users (`review → active` or `review → scheduled → active`). Also handles the reverse: `active → archived`.

**Responsibilities:**

**Immediate publication:**
- Admin approves → set `status = 'active'`, `published_at = now()`, `created_by = admin_id`

**Scheduled publication:**
- Admin sets future date → set `status = 'scheduled'`, `scheduled_at = {datetime}`, `published_at = null`
- Scheduler cron (`activate_scheduled_insights`) polls every 15 minutes for rows where `status = 'scheduled' AND scheduled_at <= now()` → sets `status = 'active'`, `published_at = now()`

**Expiry (archival):**
- Expiry cron (`expire_old_insights`) runs daily → sets `status = 'archived'` for rows where `published_at < NOW() - 30 days AND is_evergreen = false`
- Admin manual archive: admin may set `status = 'archived'` directly via admin endpoint at any time

**Ordering guarantee:** Flutter always receives insights ordered by `published_at DESC`. A newly activated scheduled insight (or a recently approved insight) always appears at the top of the feed.

**Dependencies:**
- `catalyst_insights` table (read/write)
- Scheduler (invokes activate and expire operations)

**Failure modes:**
- Scheduler cron fails one execution: next execution 15 minutes later catches any missed activations (idempotent)
- Expiry cron fails one execution: next day's execution catches missed archives (idempotent; 1-day delay in archival is not user-impacting)

**Recovery strategy:** All scheduler failures are self-healing on next execution. Neither publication nor expiry requires real-time precision. A 15-minute activation delay is acceptable. A 1-day archival delay is acceptable.

---

### Module 8: Expiry & Lifecycle Service

**Purpose:** Automated garbage collection. Moves non-evergreen insights older than 30 days from `active` to `archived`, and moves suspended-source insights to `archived`. Never hard-deletes records.

**Responsibilities:**
- Query: `SELECT id FROM catalyst_insights WHERE status = 'active' AND is_evergreen = false AND published_at < NOW() - INTERVAL '30 days'`
- Batch update: `SET status = 'archived', updated_at = now()` for all matching rows
- Query: insights where `source_id` points to a source with `is_active = false` and insight still has `status = 'active'` → archive these too
- Log count of archived records per execution
- Return count for monitoring

**Dependencies:**
- `catalyst_insights` table (read/write)
- `insights_sources` table (read: check `is_active`)

**Failure modes:** DB timeout → partial archival; next cron execution completes the remainder (idempotent).

---

### Module 9: Flutter API Layer

**Purpose:** The read interface between Flutter and the database. Not a custom Edge Function — implemented via Supabase PostgREST with RLS enforcing access. The Flutter repository pattern defines the exact query contracts this layer must satisfy.

**Responsibilities:**
- Expose `catalyst_insights` for authenticated Flutter reads (status = active only, enforced by RLS)
- Pagination: LIMIT 10 OFFSET {page × 10} (V1) → cursor-based (V3)
- Ordering: `published_at DESC` (always)
- Field projection: only display-ready fields (14 fields per Phase 2 §9.2)
- No joins required (all display fields are denormalized on `catalyst_insights`)

**Dependencies:**
- `catalyst_insights` table (read, RLS-filtered)
- Supabase Auth (JWT validation)

**Note:** The Flutter API Layer has no server-side code to write. It is entirely defined by the RLS policies on `catalyst_insights`, the PostgREST column selection in the Flutter repository, and the indexes that make the query efficient.

---

## 4. EDGE FUNCTION BLUEPRINTS

### EF-01: collect_insight

| Property | Specification |
|----------|--------------|
| **Purpose** | Accept article URL, extract OG metadata, write to insights_raw |
| **Trigger** | HTTP POST (admin-invoked in V1; called by poll_rss_feeds in V2) |
| **Authentication** | Bearer JWT with `app_role = 'admin'` OR internal service-role call from poll_rss_feeds |
| **Timeout** | 30 seconds |
| **Expected execution time** | 2–8 seconds (OG fetch is the variable component) |
| **Retry behaviour** | None — caller (admin or RSS poller) decides whether to retry |
| **Rate limit** | 60 requests / minute per authenticated caller (Supabase Edge Function default) |
| **Input** | `{url: string, source_id?: string, submitted_via: string}` |
| **Output (success 200)** | `{raw_id: string, status: 'queued', message: string}` |
| **Output (early exit 200)** | `{status: 'already_exists', raw_id: string}` |
| **Output (error 400)** | `{status: 'rejected', reason: string}` |
| **Output (error 500)** | `{error: string}` |
| **Dependencies** | `insights_sources` (read), `insights_raw` (write), external HTTP |
| **Logging requirements** | Log: raw_id, url_fingerprint, source_id, og_fetch_duration_ms, status, rejection_reason (if any) |
| **Failure handling** | OG fetch failure: write partial row, set `og_fetch_error = true`, return 200 with status `queued` — validator handles completeness |
| **Idempotency** | URL fingerprint pre-check prevents duplicate rows; safe to call twice with same URL |

---

### EF-02: validate_insight

| Property | Specification |
|----------|--------------|
| **Purpose** | Run all quality + compliance checks on a pending insights_raw row |
| **Trigger** | Supabase Database Webhook on `insights_raw` INSERT when `status = 'pending'` |
| **Authentication** | Service role (webhook fires with service role; no user JWT) |
| **Timeout** | 20 seconds |
| **Expected execution time** | 1–5 seconds (URL HEAD check is the variable component) |
| **Retry behaviour** | Webhook retries automatically up to 3 times with 5-second delay on non-2xx response |
| **Input** | `{type: 'INSERT', table: 'insights_raw', record: {id: string, ...}}` |
| **Output (success 200)** | `{}` — status updated in DB directly |
| **Output (error 500)** | `{error: string}` — webhook retries |
| **Dependencies** | `insights_raw` (read/write), `insights_sources` (read), Deduplication Service (inline), external HTTP (URL HEAD) |
| **Logging requirements** | Log: raw_id, checks_run, first_failure (check name + reason), final_status, duration_ms |
| **Failure handling** | Crash before DB write: row remains `pending`; admin can manually re-trigger; no data loss |
| **Idempotency** | Check `insights_raw.status != 'pending'` at start; if already processed, return 200 immediately |

---

### EF-03: enrich_insight

| Property | Specification |
|----------|--------------|
| **Purpose** | Generate AI-enriched fields for a validated insight; create catalyst_insights row |
| **Trigger** | Direct HTTP POST invocation from validate_insight after status → validated |
| **Authentication** | Service role (invoked from another Edge Function) |
| **Timeout** | 90 seconds (Anthropic API + IEEE API optional + image mirror) |
| **Expected execution time** | 10–30 seconds (AI call: 3–10s, image mirror: 5–15s) |
| **Retry behaviour** | AI API call: 3 retries (2s, 4s, 8s exponential back-off). Image mirror: 1 retry. Total retries never exceed timeout. |
| **Input** | `{raw_id: string}` |
| **Output (success 200)** | `{insight_id: string, status: 'review', ai_confidence: float}` |
| **Output (ai_error 200)** | `{status: 'ai_error', raw_id: string, error: string}` — sets raw_id status in DB |
| **Output (error 500)** | `{error: string}` |
| **Dependencies** | `insights_raw` (read), `catalyst_insights` (write), Anthropic Claude API (external), IEEE API (external, optional), Image Mirror Service (inline), `ANTHROPIC_API_KEY`, `IEEE_API_KEY` |
| **Logging requirements** | Log: raw_id, insight_id, ai_model, ai_confidence, ai_duration_ms, ieee_api_used (boolean), image_source ('mirrored'/'default'), image_duration_ms, total_duration_ms |
| **Failure handling** | AI failure after retries: set `insights_raw.status = 'ai_error'`. Image failure: use category default. Either failure is non-blocking to the other. |
| **Idempotency** | Check if `catalyst_insights` row already exists for this `raw_id`; if so, return existing `insight_id` |

---

### EF-04: mirror_insight_image (subroutine — not a standalone Edge Function)

| Property | Specification |
|----------|--------------|
| **Purpose** | Download OG image, validate, convert to WebP, upload to Supabase Storage |
| **Trigger** | Called inline from enrich_insight |
| **Timeout (budget)** | 30 seconds (out of enrich_insight's 90-second total) |
| **Expected execution time** | 5–15 seconds |
| **Retry behaviour** | 1 retry on download failure; no retry on Supabase Storage PUT failure (proceed to fallback) |
| **Input** | `{insight_id: string, og_image_url: string | null, category: string}` |
| **Output** | `{hero_image_url: string, source: 'mirrored' | 'category_default'}` |
| **Dependencies** | External HTTP (image download), Supabase Storage (write, service role), `insights-images` bucket |
| **Logging** | Log: image_url, download_size_bytes, dimensions, format, webp_size_bytes, upload_duration_ms, source |
| **Failure handling** | Any failure → return category default URL; never block insight creation |

---

### EF-05: activate_scheduled_insights

| Property | Specification |
|----------|--------------|
| **Purpose** | Promote `status = 'scheduled'` insights whose `scheduled_at` has passed to `status = 'active'` |
| **Trigger** | Supabase Edge Function Cron — every 15 minutes |
| **Authentication** | Service role |
| **Timeout** | 15 seconds |
| **Expected execution time** | < 1 second (rare non-empty result set) |
| **Retry behaviour** | N/A — cron fires again in 15 minutes on failure |
| **Input** | None |
| **Output** | `{activated_count: int, insight_ids: string[]}` |
| **Dependencies** | `catalyst_insights` (read/write) |
| **Logging requirements** | Log: activated_count, insight_ids (if any), duration_ms |
| **Failure handling** | DB timeout: cron fires again in 15 minutes; idempotent |
| **Alert condition** | Alert if `activated_count > 50` in a single run (suggests backlog build-up from prior failures) |

---

### EF-06: expire_old_insights

| Property | Specification |
|----------|--------------|
| **Purpose** | Archive active insights older than 30 days (non-evergreen) and insights from suspended sources |
| **Trigger** | Supabase Edge Function Cron — daily at 02:00 UTC |
| **Authentication** | Service role |
| **Timeout** | 30 seconds |
| **Expected execution time** | 1–5 seconds |
| **Retry behaviour** | N/A — cron fires next day on failure |
| **Input** | None |
| **Output** | `{archived_count: int, archived_ids: string[]}` |
| **Dependencies** | `catalyst_insights` (read/write), `insights_sources` (read) |
| **Logging requirements** | Log: archived_count, archived_ids, duration_ms, execution_timestamp |
| **Failure handling** | Partial execution: remaining rows archived next day; no data integrity risk |
| **Alert condition** | Alert if `archived_count > 100` (unexpected mass expiry; investigate) |

---

### EF-07: poll_rss_feeds (V2 — designed now, not in V1 implementation scope)

| Property | Specification |
|----------|--------------|
| **Purpose** | Fetch RSS/Atom feeds from all active Tier 1–3 sources with confirmed RSS; submit new items to collect_insight |
| **Trigger** | Supabase Edge Function Cron — every 4 hours (configurable per source via `insights_sources.poll_interval_hours`) |
| **Authentication** | Service role |
| **Timeout** | 120 seconds (multiple RSS fetches, concurrent) |
| **Expected execution time** | 20–60 seconds (21 feeds, concurrent fetch, deduplication check per item) |
| **Retry behaviour** | Per-source: 1 retry on RSS fetch failure; other sources continue regardless |
| **Input** | None (reads active sources with `rss_feed_url != null`) |
| **Output** | `{sources_polled: int, new_items_submitted: int, items_skipped_dedup: int, source_failures: string[]}` |
| **Dependencies** | `insights_sources` (read), external HTTP (RSS feeds), collect_insight (invoked per new item) |
| **Logging requirements** | Log: per-source item counts, per-source failures, total duration, submission success/failure counts |
| **Failure handling** | Individual source failure is isolated; logged and included in `source_failures` output; does not block other sources |
| **Alert condition** | Alert if `source_failures.length > 5` (systemic RSS availability problem) |

---

### EF-08: send_weekly_digest (V2 — designed now, not in V1 implementation scope)

| Property | Specification |
|----------|--------------|
| **Purpose** | Send a weekly email or push notification summarising the top 5 insights from the past 7 days |
| **Trigger** | Supabase Edge Function Cron — Monday 08:00 UTC |
| **Authentication** | Service role |
| **Timeout** | 60 seconds |
| **Expected execution time** | 10–30 seconds |
| **Input** | None |
| **Dependencies** | `catalyst_insights` (read), `profiles` (read: notification preferences), email service, push notification service |
| **Failure handling** | Email delivery failure: log and continue; no retry (weekly cadence absorbs one failure gracefully) |

---

### EF-09: dead_link_check (V2 — designed now, not in V1 implementation scope)

| Property | Specification |
|----------|--------------|
| **Purpose** | Ping `source_url` of all active insights; flag dead links for admin attention |
| **Trigger** | Supabase Edge Function Cron — weekly, Sunday 01:00 UTC |
| **Authentication** | Service role |
| **Timeout** | 120 seconds |
| **Expected execution time** | Varies by active insight count; concurrent HEAD requests |
| **Input** | None |
| **Dependencies** | `catalyst_insights` (read/write: flag field), external HTTP |
| **Output** | `{checked: int, dead: int, dead_insight_ids: string[]}` |
| **Failure handling** | Timeout on individual URL: count as unknown, not dead. Systemic failure: log and skip week. |

---

## 5. DATABASE BLUEPRINT

### 5.1 Table Ownership

| Table | Owner Module | Read Access | Write Access |
|-------|-------------|-------------|--------------|
| `insights_sources` | Admin Review Service | All authenticated users (for domain validation); service role | Admin JWT; service role |
| `insights_raw` | Insights Collector / Validator | Admin JWT; service role | Service role only |
| `catalyst_insights` | AI Enrichment Service / Publication Service | Authenticated users (active only, RLS); Admin JWT (all statuses) | Admin JWT; service role |
| `insights_tags` | V2 — empty in V1 | All authenticated | Service role |
| `insights_read_state` | V2 — empty in V1 | Per-user (user can only see own rows) | Authenticated user |
| `insights_bookmarks` | V2 — empty in V1 | Per-user | Authenticated user |

### 5.2 Data Flow Ownership

```
[External URL] ──► collect_insight ──► insights_raw (pending)
                                             │
                                    validate_insight
                                             │
                              ┌──────────────┴──────────────┐
                              ▼                             ▼
                    insights_raw (rejected)       insights_raw (validated)
                              (terminal)                    │
                                                  enrich_insight
                                                            │
                                                 catalyst_insights (review)
                                                            │
                                                  admin approves
                                                            │
                                                 catalyst_insights (active)
                                                            │
                                                  [Flutter reads]
                                                            │
                                              [30 days or admin archives]
                                                            │
                                                 catalyst_insights (archived)
                                                          (terminal)
```

### 5.3 Read vs Write Responsibilities

**`insights_raw`:**
- Writes: service role only (collect_insight, validate_insight)
- Reads: service role (validate, enrich), admin JWT (review dashboard)
- Flutter: NEVER reads this table

**`catalyst_insights`:**
- Writes: service role (enrich_insight creates row), admin JWT (approve/reject/edit)
- Reads: authenticated users (active only, RLS), admin JWT (all statuses)
- Flutter: reads `status = 'active'` rows only via PostgREST

**`insights_sources`:**
- Writes: admin JWT only (add/edit sources via admin dashboard)
- Reads: service role (domain validation in collect_insight/validate_insight), admin JWT

### 5.4 Index Strategy

**`insights_raw` indexes:**
- `url_fingerprint` UNIQUE — Level 1 deduplication lookup
- `status` — validator queue queries
- `(source_id, status)` composite — source-filtered admin queries
- `article_published_at` — freshness check performance

**`catalyst_insights` indexes:**
- `(status, published_at DESC)` composite UNIQUE-eligibility — primary Flutter query index; index scan, no table scan
- `category` — future category filtering
- `url_fingerprint` UNIQUE — cross-table deduplication
- `title_fingerprint` — Level 2 deduplication lookup
- `ai_confidence` — admin review queue sorting

**`insights_sources` indexes:**
- `approved_domain` UNIQUE — domain validation lookup
- `is_active` — filter for active sources in RSS poller

### 5.5 Soft Delete Policy

No hard deletes on any insights table. Lifecycle is managed entirely through status transitions:

| Status | Terminal? | Returned to Flutter? | Returned to Admin? |
|--------|-----------|---------------------|-------------------|
| `pending` | No | No | Admin ingest queue |
| `validated` | No | No | No (transitional) |
| `duplicate` | Yes | No | Admin can view |
| `rejected` | Yes | No | Admin can view |
| `ai_error` | No | No | Admin error queue |
| `ai_processed` | No | No | No (transitional) |
| `review` | No | No | Admin review queue |
| `scheduled` | No | No | Admin publishing queue |
| `active` | No | Yes | Admin can view/edit |
| `archived` | Yes | No | Admin can view |

### 5.6 Archival Strategy

- `archived` status insights remain in `catalyst_insights` indefinitely
- They are excluded from Flutter queries by the `status = 'active'` filter (enforced by both RLS and repository query)
- `insights_raw` rows with `rejected` or `duplicate` status older than 90 days may be hard-deleted by a future cleanup job (V3)
- `insights_raw` rows with `promoted` status are retained indefinitely for audit trail

### 5.7 Concurrency Considerations

- `catalyst_insights` rows may be read by many Flutter clients simultaneously while being written by the admin — Supabase / PostgreSQL MVCC handles this safely
- Admin batch-approve must be wrapped in a database transaction to ensure atomicity
- The `activate_scheduled_insights` cron must use `FOR UPDATE SKIP LOCKED` semantics if two cron executions overlap (Supabase guarantees single-instance cron execution, but defensive coding is required)

---

## 6. API BLUEPRINT

### 6.1 Flutter-Facing API (Read-Only)

#### GET /rest/v1/catalyst_insights (Flutter primary feed)

| Property | Specification |
|----------|--------------|
| **Purpose** | Return paginated active insights for Flutter feed |
| **Consumer** | `InsightsRepository` in Flutter |
| **Authentication** | Bearer JWT (any authenticated user) |
| **RLS enforcement** | `status = 'active'` filter is enforced at RLS level — cannot be bypassed |
| **Request parameters** | `select=id,headline,ai_summary,ai_why_matters,ai_key_takeaway,hero_image_url,source_name,source_url,article_date,reading_time_minutes,category,ai_tags,published_at,ai_is_generated&order=published_at.desc&limit=10&offset={page*10}` |
| **Response model** | Array of 14-field InsightDto objects |
| **Pagination** | LIMIT 10 OFFSET {page × 10} (V1). Cursor-based (`&cursor=published_at.lt.{cursor_value}`) in V3. |
| **Filtering** | `status=eq.active` (RLS-enforced, not required in Flutter query) |
| **Sorting** | `published_at DESC` (always) |
| **Caching** | No server-side caching in V1. Flutter `SharedPreferences` caches page 0. |
| **Rate limits** | Supabase project defaults (up to 500 req/s on Pro plan) |
| **Success response** | 200 `[{...InsightDto}]` |
| **Empty response** | 200 `[]` (not an error; Flutter renders empty state) |
| **Auth error** | 401 `{message: "JWT expired"}` |
| **Server error** | 500 `{message: "..."}` |

---

### 6.2 Admin-Facing APIs

#### POST /functions/v1/collect_insight (submit article URL)

| Property | Specification |
|----------|--------------|
| **Purpose** | Submit an article URL for ingestion |
| **Consumer** | Admin dashboard Flutter screen; RSS poller (V2) |
| **Authentication** | Bearer JWT with `app_role = 'admin'` |
| **Request model** | `{url: string, source_id?: string}` |
| **Response (200 queued)** | `{raw_id: string, status: 'queued', message: string}` |
| **Response (200 exists)** | `{raw_id: string, status: 'already_exists'}` |
| **Response (400 rejected)** | `{status: 'rejected', reason: 'UNAUTHORIZED_SOURCE' \| 'INVALID_URL'}` |
| **Response (401)** | `{error: 'Unauthorized'}` |
| **Response (500)** | `{error: string}` |
| **Rate limits** | 30 requests / minute per admin |

---

#### GET /rest/v1/catalyst_insights (admin review queue)

| Property | Specification |
|----------|--------------|
| **Purpose** | Return insights in review queue, ordered by confidence DESC |
| **Consumer** | Admin dashboard Flutter screen |
| **Authentication** | Bearer JWT with `app_role = 'admin'` |
| **Request parameters** | `select=*&status=eq.review&order=ai_confidence.desc,created_at.asc` |
| **Additional filter** | Admin may filter by `ai_confidence=gte.0.90` for batch-approve queue |
| **Response** | Full `catalyst_insights` row including pipeline fields |
| **Pagination** | 20 per page (admin processes batches) |

---

#### PATCH /rest/v1/catalyst_insights?id=eq.{id} (approve / reject / edit)

| Property | Specification |
|----------|--------------|
| **Purpose** | Update a single insight's status or content fields |
| **Consumer** | Admin dashboard |
| **Authentication** | Bearer JWT with `app_role = 'admin'` |
| **Request model (approve immediate)** | `{status: 'active', published_at: now()}` |
| **Request model (schedule)** | `{status: 'scheduled', scheduled_at: ISO8601 timestamp}` |
| **Request model (reject)** | `{status: 'rejected', rejection_reason: string (optional)}` |
| **Request model (edit fields)** | `{headline?: string, ai_summary?: string, ai_why_matters?: string, ai_key_takeaway?: string, category?: string, ai_tags?: string[], reading_time_minutes?: int, admin_edited: true}` |
| **Response (200)** | Updated row |
| **Response (401)** | Unauthorized |
| **Response (403)** | RLS violation — admin role not present |
| **Response (409)** | Optimistic concurrency conflict (row modified elsewhere) |

---

#### POST /rest/v1/rpc/batch_approve_high_confidence (batch approve)

| Property | Specification |
|----------|--------------|
| **Purpose** | Approve all insights with `ai_confidence >= 0.90 AND status = 'review'` in one operation |
| **Consumer** | Admin dashboard (batch approve button) |
| **Authentication** | Bearer JWT with `app_role = 'admin'` |
| **Request model** | `{}` (no body; acts on all matching rows) |
| **Response** | `{approved_count: int, insight_ids: string[]}` |
| **Atomicity** | Full transaction — all succeed or none |
| **Response (partial failure 500)** | `{error: string, approved_count: 0}` |

---

#### GET /rest/v1/insights_sources (source management)

| Property | Specification |
|----------|--------------|
| **Purpose** | List all sources for admin source management screen |
| **Consumer** | Admin dashboard |
| **Authentication** | Bearer JWT with `app_role = 'admin'` |
| **Request parameters** | `select=*&order=tier.asc,name.asc` |
| **Response** | Array of all `insights_sources` rows |

---

#### PATCH /rest/v1/insights_sources?id=eq.{id} (suspend/unsuspend source)

| Property | Specification |
|----------|--------------|
| **Purpose** | Suspend or re-activate a source |
| **Consumer** | Admin dashboard |
| **Authentication** | Bearer JWT with `app_role = 'admin'` |
| **Request model** | `{is_active: boolean, notes?: string}` |
| **Side effect** | Suspending a source does NOT auto-archive existing active insights. Admin must run manual archive sweep if needed. |

---

## 7. STORAGE BLUEPRINT

### 7.1 Bucket: `insights-images`

| Property | Specification |
|----------|--------------|
| **Bucket name** | `insights-images` |
| **Access level** | Public (CDN-delivered, no authentication required for GET) |
| **Write access** | Service role only (Edge Functions) |
| **Read access** | Public (Flutter loads images via CDN URL without JWT) |

### 7.2 Folder Structure

```
insights-images/
├── insights/
│   ├── {insight_id}/
│   │   └── hero.webp                  ← mirrored OG image
│   └── {insight_id}/
│       └── hero.webp
└── defaults/
    ├── grid_technology.webp            ← category fallback images
    ├── energy_transition.webp
    ├── industry_standards.webp
    ├── engineering_leadership.webp
    ├── policy_markets.webp
    └── innovation.webp
```

### 7.3 Naming Conventions

| Asset Type | Path Pattern | Format |
|-----------|-------------|--------|
| Mirrored hero image | `insights/{insight_id}/hero.webp` | WebP, 85% quality |
| Category default | `defaults/{category_code}.webp` | WebP, 85% quality, 1200×630px |
| Admin-replaced image | `insights/{insight_id}/hero.webp` | Overwrites; same path |

### 7.4 Image Lifecycle

| Event | Action |
|-------|--------|
| Insight created | hero.webp uploaded to `insights/{id}/` |
| Admin replaces image | New upload overwrites same path |
| Insight archived | Image file retained (never deleted) |
| Insight rejected | Image was never uploaded (rejected before enrichment) |

### 7.5 CDN Strategy

- Supabase Storage is backed by a global CDN (CloudFlare)
- Public bucket images are served with long cache TTL by default
- No custom cache headers required in V1 — Supabase defaults are adequate at current scale
- V3: Set `Cache-Control: max-age=86400, public` explicitly for hero images to reduce origin requests

### 7.6 Retention

- No images are ever deleted in V1
- V3: A cleanup job may delete images for `archived` insights older than 365 days if storage costs become relevant
- Default category images (`defaults/`) are never deleted

### 7.7 Size Budget

- Estimated: 25 sources × 3 insights/week × 52 weeks = 3,900 insights/year × 200KB average WebP = ~780MB/year
- Well within Supabase Pro plan Storage allocation
- Default category images: 6 files × ~500KB = ~3MB (negligible)

---

## 8. BACKGROUND JOBS SPECIFICATION

### Job 1: activate_scheduled_insights

| Property | Specification |
|----------|--------------|
| **Execution frequency** | Every 15 minutes |
| **Trigger** | Supabase Edge Function cron (`0/15 * * * *`) |
| **Purpose** | Promote scheduled insights to active when their scheduled_at time has passed |
| **Query** | `WHERE status = 'scheduled' AND scheduled_at <= NOW()` |
| **Action** | Batch UPDATE: `status = 'active', published_at = now(), updated_at = now()` |
| **Dependencies** | `catalyst_insights` table only |
| **Failure recovery** | Idempotent — next execution at +15 minutes processes any remaining rows |
| **Retry strategy** | No explicit retry; cron cadence is the retry mechanism |
| **Monitoring** | Log `activated_count` per execution; alert if `activated_count > 50` (backlog indicator) |
| **Alert conditions** | `activated_count > 50` OR execution time > 10 seconds |

---

### Job 2: expire_old_insights

| Property | Specification |
|----------|--------------|
| **Execution frequency** | Daily at 02:00 UTC |
| **Trigger** | Supabase Edge Function cron (`0 2 * * *`) |
| **Purpose** | Archive insights older than 30 days (non-evergreen) and from suspended sources |
| **Query 1** | `WHERE status = 'active' AND is_evergreen = false AND published_at < NOW() - INTERVAL '30 days'` |
| **Query 2** | `WHERE status = 'active' AND source_id IN (SELECT id FROM insights_sources WHERE is_active = false)` |
| **Action** | Batch UPDATE: `status = 'archived', updated_at = now()` |
| **Dependencies** | `catalyst_insights`, `insights_sources` |
| **Failure recovery** | Idempotent — next day's execution processes remaining rows |
| **Monitoring** | Log `archived_count` per execution; alert on unusual counts |
| **Alert conditions** | `archived_count > 100` (investigate cause — expected maximum is ~30–50 items/day at full scale) |

---

### Job 3: poll_rss_feeds (V2)

| Property | Specification |
|----------|--------------|
| **Execution frequency** | Every 4 hours (configurable per source) |
| **Trigger** | Supabase Edge Function cron (`0 */4 * * *`) |
| **Purpose** | Fetch all active source RSS feeds; submit new items to collect_insight |
| **Per-source process** | Fetch RSS → parse items → check each item's URL fingerprint against insights_raw → submit new items only |
| **Concurrency** | Fetch all feeds concurrently (Promise.allSettled) |
| **Dependencies** | `insights_sources` (read active sources with `rss_feed_url != null`), collect_insight (invoked per new item) |
| **Failure recovery** | Per-source failure is isolated; logged; other sources continue |
| **Monitoring** | Log per-source: items_found, items_submitted, items_skipped_dedup, error (if any) |
| **Alert conditions** | More than 5 source failures in a single run; or total submission rate drops > 50% vs 7-day average |

---

### Job 4: send_weekly_digest (V2)

| Property | Specification |
|----------|--------------|
| **Execution frequency** | Weekly — Monday 08:00 UTC |
| **Trigger** | Supabase Edge Function cron (`0 8 * * 1`) |
| **Purpose** | Send top 5 insights from past 7 days to users with digest notifications enabled |
| **Selection query** | `WHERE status = 'active' AND published_at > NOW() - INTERVAL '7 days' ORDER BY published_at DESC LIMIT 5` |
| **Delivery** | Email (via existing email service) and/or push notification (per user's `notification_preferences`) |
| **Dependencies** | `catalyst_insights`, `profiles`, email service, push notification service |
| **Failure recovery** | Log delivery failures per user; no retry (weekly cadence); failures are acceptable |

---

## 9. ERROR ARCHITECTURE

### 9.1 Error Classification Taxonomy

**Class A — Validation Errors (Expected, Rejections)**

| Code | Description | Recovery |
|------|-------------|----------|
| `UNAUTHORIZED_SOURCE` | Domain not in insights_sources whitelist | Admin adds source or submits different URL |
| `INSECURE_URL` | URL is HTTP, not HTTPS | Admin corrects URL |
| `DEAD_LINK` | URL returns 4xx/5xx | Admin submits different article |
| `INVALID_HEADLINE` | Headline < 10 or > 240 chars | Admin submits different article or manually enters headline |
| `INSUFFICIENT_DESCRIPTION` | Description < 30 chars | See thin metadata handling (§8.2 of Phase 2.5) |
| `STALE_CONTENT` | Article published > 90 days ago | Admin submits more recent article |
| `PAYWALL_DETECTED` | `isAccessibleForFree: false` | Admin submits different article |
| `DUPLICATE_URL` | URL fingerprint already exists | Duplicate — no action needed |
| `DUPLICATE_TITLE` | Title fingerprint already exists | Near-duplicate — admin may still approve if different enough |

**Class B — AI Errors (Unexpected, Retryable)**

| Code | Description | Recovery |
|------|-------------|----------|
| `AI_API_UNAVAILABLE` | Anthropic API returned 5xx or timed out | Exponential back-off × 3; then `ai_error` status |
| `AI_INVALID_RESPONSE` | Response not valid JSON or missing fields | Retry with stricter prompt × 1; then `ai_error` status |
| `AI_CONFIDENCE_TOO_LOW` | Not an error — routes to LOW CONFIDENCE flag in admin queue | Admin reviews carefully |
| `AI_CONTEXT_WINDOW_EXCEEDED` | Input too long (extremely rare with metadata-only input) | Truncate input description to 1000 chars; retry |

**Class C — Storage Errors (Non-blocking)**

| Code | Description | Recovery |
|------|-------------|----------|
| `IMAGE_DOWNLOAD_FAILED` | OG image URL returns error or times out | Use category default; log; non-blocking |
| `IMAGE_TOO_SMALL` | Dimensions < 400×200px | Use category default |
| `IMAGE_TOO_LARGE` | File > 5MB | Use category default |
| `IMAGE_FORMAT_UNSUPPORTED` | Not JPEG/PNG/WebP/GIF | Use category default |
| `STORAGE_PUT_FAILED` | Supabase Storage write error | Use category default; log for retry |

**Class D — Network Errors (Per-operation retryable)**

| Code | Description | Recovery |
|------|-------------|----------|
| `SOURCE_DOMAIN_TIMEOUT` | OG fetch timed out | Write partial row; validator runs completeness check |
| `RSS_FEED_TIMEOUT` | RSS fetch timed out during polling | Skip this source for this poll cycle; log |
| `IEEE_API_TIMEOUT` | IEEE abstract API timed out | Fall back to OG description; log |

**Class E — Publisher Errors (Operational)**

| Code | Description | Recovery |
|------|-------------|----------|
| `SOURCE_SUSPENDED` | Source `is_active = false` | Insights from this source are no longer collected; existing insights unaffected |
| `SOURCE_PAYWALL_CHANGE` | Previously free article now gated | Admin detects when users get empty article page; admin archives |
| `DEAD_LINK_POST_PUBLISH` | Source URL dies after publication | V2 dead_link_check detects; admin archives |

**Class F — Admin Errors (User-facing)**

| Code | Description | Recovery |
|------|-------------|----------|
| `ADMIN_AUTH_EXPIRED` | Admin JWT expired during session | Flutter shows re-auth prompt |
| `CONCURRENT_EDIT_CONFLICT` | Row modified between admin's read and write | 409 response; Flutter refreshes admin queue |
| `INVALID_SCHEDULED_DATE` | `scheduled_at` is in the past | Flutter validation prevents; Edge Function validates if bypassed |

**Class G — Database Errors (System)**

| Code | Description | Recovery |
|------|-------------|----------|
| `DB_TIMEOUT` | Supabase query timed out | Exponential back-off × 3; alert on repeated occurrence |
| `DB_CONSTRAINT_VIOLATION` | UNIQUE constraint hit (e.g. duplicate url_fingerprint) | Expected for deduplication; return `already_exists` gracefully |
| `DB_RLS_VIOLATION` | User attempted access beyond their RLS policy | 403 response; log (possible security concern if repeated) |

### 9.2 Error Propagation Rules

1. Class A errors are final — record rejection, no retry, no admin alert needed (admin sees in dashboard naturally)
2. Class B errors retry per EF-03 spec; admin sees `ai_error` queue if all retries fail
3. Class C errors are always non-blocking — fallback applied silently, logged for monitoring
4. Class D errors retry once at the network level; then Class A or B handling applies
5. Class E errors are operational — trigger admin dashboard notification in V2
6. Class F errors surface to the Flutter admin UI immediately
7. Class G errors are system-level — logged, alerted, and escalated if persistent

### 9.3 Error Log Schema

Every logged error must include:

```
{
  timestamp: ISO8601,
  function_name: string,
  error_class: 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G',
  error_code: string,
  raw_id: string | null,
  insight_id: string | null,
  source_id: string | null,
  message: string,
  stack_trace: string | null,
  retry_attempt: int | null,
  duration_ms: int
}
```

---

## 10. OBSERVABILITY BLUEPRINT

### 10.1 Pipeline Health Dashboard

The admin dashboard must include a Pipeline Health section visible only to admins. It displays:

| Metric | Data Source | Alert Threshold |
|--------|-------------|----------------|
| Pending raw items (stuck > 30 min) | `insights_raw WHERE status='pending' AND created_at < NOW()-30min` | > 5 items |
| AI error queue depth | `insights_raw WHERE status='ai_error'` | > 3 items |
| Review queue depth | `catalyst_insights WHERE status='review'` | Informational only |
| Active insights count | `catalyst_insights WHERE status='active'` | < 5 items (low stock warning) |
| Last publish timestamp | Max `published_at` from active insights | > 7 days ago |

### 10.2 Pipeline Throughput Metrics

Collected per Edge Function execution and logged:

| Metric | Unit | Target |
|--------|------|--------|
| collect_insight success rate | % | > 95% |
| validate_insight pass rate | % | > 70% (rejections are expected) |
| duplicate rate | % of validated | < 30% in V1 (higher in V2 RSS mode) |
| AI enrichment success rate | % | > 98% |
| AI confidence score distribution | Mean + P10/P90 | Mean > 0.75 |
| Image mirror success rate | % | > 90% (fallback covers remainder) |
| End-to-end pipeline time (submit → review) | seconds | < 120 seconds |

### 10.3 Source Health Metrics (V2)

Per-source metrics logged by poll_rss_feeds:

| Metric | Description |
|--------|-------------|
| Items submitted per source per day | Discovery rate |
| Items rejected per source (validation failure) | Quality indicator |
| Items duplicated per source | Churn indicator |
| Last successful fetch per source | Staleness indicator |

### 10.4 Flutter Consumption Metrics

Logged by the Flutter InsightsRepository (V2 analytics integration):

| Event | When |
|-------|------|
| `insights_feed_opened` | User opens Insights tab |
| `insight_card_viewed` | Each card rendered (card index in session) |
| `insight_article_opened` | "Read Full Article" tapped |
| `insights_feed_refreshed` | Pull-down refresh triggered |
| `insights_end_of_batch` | End-of-batch card shown |

### 10.5 Infrastructure Metrics

Standard Supabase project metrics monitored via Supabase Dashboard:

- Edge Function invocation count and duration trends
- Database connection pool usage
- Storage bucket total size
- Supabase Storage egress (CDN delivery volume)

### 10.6 Alert Escalation Policy

| Severity | Condition | Action |
|----------|-----------|--------|
| P1 (Critical) | Anthropic API unavailable > 30 minutes | Immediately investigate; admin cannot enrich new insights |
| P1 (Critical) | `activate_scheduled_insights` has not run in > 30 minutes | Investigate cron failure |
| P2 (High) | AI error queue depth > 10 | Admin manually retries; investigate AI prompt stability |
| P2 (High) | Active insights count < 3 | Admin publishes new batch urgently |
| P3 (Medium) | Image mirror success rate < 75% over 24 hours | Review source OG image quality; category defaults covering users |
| P3 (Medium) | > 5 RSS source failures in one poll cycle (V2) | Investigate network / RSS feed changes |
| P4 (Low) | Duplicate rate > 50% in RSS mode | Tune deduplication window; sources may be over-publishing |

---

## 11. SECURITY BLUEPRINT

### 11.1 Authentication Boundary Map

```
╔═════════════════════════════════════════════════════════════╗
║  AUTHENTICATION ZONES                                        ║
╠═════════════════════════════════════════════════════════════╣
║                                                             ║
║  PUBLIC (no auth)                                           ║
║  └── Supabase Storage CDN reads (hero images)              ║
║                                                             ║
║  AUTHENTICATED USER (any valid JWT)                         ║
║  └── GET /rest/v1/catalyst_insights (status=active only)   ║
║  └── GET /rest/v1/insights_sources (read only)             ║
║                                                             ║
║  ADMIN (JWT with app_role = 'admin')                        ║
║  └── POST /functions/v1/collect_insight                    ║
║  └── GET /rest/v1/catalyst_insights (all statuses)         ║
║  └── PATCH /rest/v1/catalyst_insights                      ║
║  └── GET /rest/v1/insights_raw                             ║
║  └── PATCH /rest/v1/insights_sources                       ║
║  └── POST /rest/v1/rpc/batch_approve_high_confidence       ║
║                                                             ║
║  SERVICE ROLE (Edge Functions — no user JWT)               ║
║  └── validate_insight (DB webhook)                         ║
║  └── enrich_insight                                        ║
║  └── activate_scheduled_insights (cron)                    ║
║  └── expire_old_insights (cron)                            ║
║  └── Supabase Storage PUT (image mirror)                   ║
║                                                             ║
╚═════════════════════════════════════════════════════════════╝
```

### 11.2 RLS Policy Ownership

**`insights_sources`:**
- Policy: `SELECT FOR ALL authenticated users` (all can read source list)
- Policy: `INSERT, UPDATE FOR admin role only`
- No `DELETE` policy — use `is_active = false`

**`insights_raw`:**
- Policy: `SELECT FOR admin role only` (no user visibility)
- Policy: `INSERT FOR service role only` (Edge Functions only)
- Policy: `UPDATE FOR service role only`

**`catalyst_insights` (user-facing):**
- Policy: `SELECT FOR authenticated WHERE status = 'active'`
- Policy: `SELECT FOR admin role (all statuses)`
- Policy: `INSERT FOR service role only`
- Policy: `UPDATE FOR admin role only`
- No `DELETE` policy

**`insights_sources` sub-path constraint:**
- The domain validation logic in `validate_insight` enforces sub-path matching (WEF, EC) in Edge Function code, not in RLS (RLS cannot enforce URL content rules)

### 11.3 Secret Management

| Secret | Stored Where | Access Pattern |
|--------|-------------|----------------|
| `ANTHROPIC_API_KEY` | Supabase Edge Function secrets | `enrich_insight` only; never logged |
| `IEEE_API_KEY` | Supabase Edge Function secrets (optional) | `enrich_insight` only; never logged |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Edge Function secrets | All Edge Functions; never logged |
| `SUPABASE_URL` | Environment variable | All Edge Functions |

**Rules:**
- No secret is ever returned in an API response
- No secret is ever written to log output
- No secret is embedded in Flutter app code
- Secrets are rotated by updating Supabase Edge Function secrets (zero downtime rotation)

### 11.4 Input Sanitisation

| Input | Sanitisation Required |
|-------|----------------------|
| Admin-submitted URL | Normalise (collect_insight), HEAD-verify (validate_insight), domain whitelist check |
| Admin-edited text fields | Strip HTML tags; enforce character limits; UTF-8 safe |
| AI-generated text | Stored as-is (trusted output from Anthropic); displayed with "AI SUMMARY" label |
| RSS feed content | Treat as untrusted; run same validation pipeline as manual submissions |
| OG metadata from source pages | Treat as untrusted; validate all fields before writing to DB |

### 11.5 Audit Logging

Every admin action is logged to a queryable audit trail (implemented via `updated_at` + `created_by` + `admin_edited` fields on `catalyst_insights`). In V2, a dedicated `insights_audit_log` table captures: `{user_id, action, resource_type, resource_id, old_value, new_value, timestamp}` for every admin write.

### 11.6 Supply Chain Security

- Deno Edge Functions run in an isolated sandbox (Supabase default)
- No npm packages are allowed in V1 Edge Functions — Deno standard library and Supabase JS client only
- External HTTP calls in Edge Functions are limited to explicitly listed hostnames (no open SSRF surface)
  - `collect_insight`: allows any HTTPS URL (required for URL fetch) — mitigated by domain whitelist check before fetch
  - `enrich_insight`: allows `api.anthropic.com`, `ieeexplore.ieee.org` (optional), Supabase Storage endpoint

---

## 12. PERFORMANCE SPECIFICATIONS

### 12.1 Flutter API Latency Targets

| Operation | P50 Target | P95 Target | Budget Buster Threshold |
|-----------|-----------|-----------|------------------------|
| Initial insights load (page 0, 10 items) | < 300ms | < 800ms | > 2000ms |
| Pagination fetch (page N) | < 300ms | < 800ms | > 2000ms |
| Pull-to-refresh | < 400ms | < 1000ms | > 2000ms |
| Admin review queue load | < 500ms | < 1200ms | > 3000ms |

These targets are achievable with the composite `(status, published_at)` index and `SELECT` of specific fields (no `SELECT *`).

### 12.2 Edge Function Execution Targets

| Edge Function | Expected P50 | Maximum Timeout |
|--------------|-------------|----------------|
| `collect_insight` | 3 seconds | 30 seconds |
| `validate_insight` | 2 seconds | 20 seconds |
| `enrich_insight` | 20 seconds | 90 seconds |
| `activate_scheduled_insights` | < 1 second | 15 seconds |
| `expire_old_insights` | 2 seconds | 30 seconds |

### 12.3 Database Query Expectations

| Query | Expected Plan | Maximum Acceptable Duration |
|-------|-------------|----------------------------|
| Flutter primary feed (status=active, limit 10) | Index scan on `(status, published_at)` | < 20ms |
| Admin review queue (status=review, order by ai_confidence) | Index scan on `status`, sort by `ai_confidence` | < 50ms |
| URL fingerprint dedup check | Index scan on `url_fingerprint` UNIQUE | < 5ms |
| Title fingerprint dedup check | Index scan on `title_fingerprint` | < 5ms |
| Scheduler: activate scheduled | Index scan on `(status, scheduled_at)` | < 10ms |
| Scheduler: expire old | Index scan on `(status, published_at)` | < 20ms |

### 12.4 Image Optimization Goals

| Property | Target |
|----------|--------|
| WebP conversion quality | 85% (optimal size/quality ratio) |
| Output file size target | < 200KB per hero image |
| Maximum output size | 500KB (reject and use category default if conversion produces > 500KB) |
| Image delivery CDN cache hit rate | > 95% (Supabase Storage CDN default) |

### 12.5 Flutter Memory Budget

| Component | Memory Budget |
|-----------|-------------|
| `InsightsNotifier` state (20 insights) | < 500KB |
| `CachedNetworkImage` disk cache | Managed by plugin (default: 200MB — shared with existing app) |
| `SharedPreferences` insights cache | < 50KB |
| PageView rendered cards (3 active) | < 10MB (images lazy-loaded by CachedNetworkImage) |

### 12.6 Startup Impact Budget

**Zero additional startup cost is required.** Validation:
- `InsightsNotifier` is a lazy Riverpod provider — instantiated only on first Insights tab open
- No database query runs at startup
- No Edge Function is called at startup
- CachedNetworkImage memory cache is not pre-warmed

---

## 13. DEPLOYMENT PLAN

### Deployment Stage 1: Database

**What:** Create all 6 tables (`insights_sources`, `insights_raw`, `catalyst_insights`, `insights_tags`, `insights_read_state`, `insights_bookmarks`) with all columns, all indexes, and all constraints.

**Why first:** Every subsequent component depends on the database schema existing. Edge Functions cannot be tested without tables. RLS cannot be applied without tables.

**Order within stage:**
1. Create `insights_sources` (no foreign keys to other new tables)
2. Create `insights_raw` (FK → insights_sources)
3. Create `catalyst_insights` (FK → insights_sources, FK → profiles)
4. Create `insights_tags`, `insights_read_state`, `insights_bookmarks` (V2 tables — created empty)
5. Apply all indexes
6. Apply all constraints (CHECK on status values, length constraints)

**Verification:** Run a SELECT on each table. Confirm indexes exist via `\d` (Supabase Table Editor).

**Rollback trigger:** Any CREATE TABLE or CREATE INDEX failure.
**Rollback method:** DROP all newly created tables in reverse order. Existing tables are untouched. Zero risk to production data.

---

### Deployment Stage 2: RLS Policies

**What:** Apply Row Level Security policies to all 6 tables.

**Why after database:** Policies cannot be applied to non-existent tables.

**Why before Edge Functions:** Edge Functions must be tested with correct RLS in place, not after.

**Order within stage:**
1. Enable RLS on each table (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`)
2. Apply `insights_sources` policies (3 policies: select-all-auth, insert-admin, update-admin)
3. Apply `insights_raw` policies (3 policies: select-admin, insert-service, update-service)
4. Apply `catalyst_insights` policies (4 policies: select-user-active, select-admin-all, insert-service, update-admin)
5. Apply V2 table policies (`insights_read_state`: select/insert/update per-user; `insights_bookmarks`: select/insert/delete per-user)

**Verification:** Test each policy:
- Authenticated non-admin user can SELECT active insights; cannot SELECT non-active insights; cannot INSERT
- Admin user can SELECT all statuses; can UPDATE
- Unauthenticated request: 401

**Rollback trigger:** Policy misconfigurations (user can see non-active records, or active records are hidden).
**Rollback method:** DROP all RLS policies on new tables; tables are still accessible with no RLS (safe since no production data yet).

---

### Deployment Stage 3: Supabase Storage

**What:** Create `insights-images` bucket; upload 6 category default images.

**Why after database:** Bucket creation is independent of tables, but the 6 default images need to be ready before Edge Functions process their first insight.

**Order within stage:**
1. Create `insights-images` bucket with public access
2. Set bucket policy: max file size 5MB; allowed MIME types: image/webp, image/jpeg, image/png
3. Upload 6 category default WebP images to `defaults/` folder
4. Verify all 6 default images are publicly accessible via CDN URL

**Verification:** Access each default image URL in a browser. Confirm HTTP 200 and correct WebP format.

**Rollback trigger:** Bucket creation failure or default images fail accessibility check.
**Rollback method:** Delete bucket. No impact on database or application.

---

### Deployment Stage 4: Edge Functions — Core Pipeline

**What:** Deploy the four core pipeline functions in dependency order.

**Why after storage:** `enrich_insight` calls `mirror_insight_image` which writes to Storage. Storage must exist first.

**Order within stage:**
1. Deploy `collect_insight` (no inbound dependencies other than DB)
2. Deploy `validate_insight` (depends on collect_insight having written to insights_raw)
3. Deploy `enrich_insight` + `mirror_insight_image` subroutine (depends on validate_insight)
4. Configure DB webhook on `insights_raw` INSERT → invoke `validate_insight`

**Verification (per function):**
- `collect_insight`: POST a test URL with admin JWT → expect `{status: 'queued', raw_id: string}` → confirm row in `insights_raw`
- `validate_insight`: Manually invoke with a known raw_id → confirm status transitions to `validated` or `rejected`
- `enrich_insight`: Manually invoke with a validated raw_id → confirm `catalyst_insights` row created with AI fields
- End-to-end smoke test: Submit one URL, observe full pipeline progression from `pending` → `validated` → `ai_processed` → `review`

**Rollback trigger:** Any function fails smoke test.
**Rollback method:** Disable the failing function. Other functions continue. Delete test rows from DB. No production impact (no insights are active yet).

---

### Deployment Stage 5: Scheduled Jobs

**What:** Deploy and enable the two V1 cron jobs.

**Why after Edge Functions:** Cron jobs call the pipeline functions. Functions must exist and be verified first.

**Order:**
1. Deploy `activate_scheduled_insights` with cron schedule (`0/15 * * * *`)
2. Deploy `expire_old_insights` with cron schedule (`0 2 * * *`)
3. Manually trigger each job once → verify execution → confirm 0-count response (no data to process yet)

**Verification:** Both jobs execute without error. Logs show expected output.

**Rollback trigger:** Cron job crashes on first execution.
**Rollback method:** Disable cron schedule. No data impact.

---

### Deployment Stage 6: Admin APIs

**What:** Confirm all admin API endpoints are functional. Deploy the `batch_approve_high_confidence` RPC function.

**Why after pipeline:** Admin review endpoints only make sense after the pipeline can produce records to review.

**Order:**
1. Deploy `batch_approve_high_confidence` PostgreSQL function (via Supabase SQL editor — this is a DB-level stored function, not an Edge Function)
2. Test all admin API endpoints with admin JWT:
   - POST collect_insight ✓
   - GET review queue ✓
   - PATCH approve ✓
   - PATCH reject ✓
   - PATCH field edit ✓
   - POST batch approve ✓
   - GET sources list ✓
   - PATCH suspend source ✓

**Verification:** Process 2–3 test insights through the full pipeline including admin approve → confirm they appear in the Flutter API response with `status=active`.

**Rollback trigger:** Any admin endpoint returns unexpected error.
**Rollback method:** Debug at DB or Edge Function level. No production users are impacted yet.

---

### Deployment Stage 7: Flutter Integration

**What:** Connect the Flutter `InsightsRepository` to the live Supabase PostgREST endpoint. Wire the Insights tab navigation (replace Explore tab at index 1 with Insights as designed in Phase 1). Enable the `InsightsScreen`.

**Why last:** The Flutter layer connects to backend components that must all be live and verified first.

**Order:**
1. Confirm `InsightsRepository.fetchInsights()` returns data from production database
2. Confirm `InsightsNotifier` correctly manages pagination and cache
3. Confirm `InsightsScreen` renders cards correctly with real data
4. Wire navigation: update `MCMainScaffold`'s `MCBottomNav` to show Insights at index 1 (replacing Explore)
5. Update `AppRouter` / `GoRouter` to add `/insights` route
6. Test end-to-end on device: swipe cards, check hero images, tap "Read Full Article"
7. Confirm zero regression on Home (index 0), Challenges (index 2), Analytics (index 3), Profile (index 4)

**Verification:** At least 5 published insights visible in Flutter. Hero images loading. Reading time displayed. Source attribution visible. "Read Full Article" opens browser. Pull-to-refresh works. End-of-batch card appears after last insight.

**Rollback trigger:** Flutter crashes on Insights tab open, or existing tabs regress.
**Rollback method (Flutter):** Remove navigation wiring (revert Insights tab to Explore). Backend remains unaffected.

---

### First Content Batch (Post-Deployment Operational Step)

**What:** Admin curates and publishes the first 5–10 insights.

**Why this is an operational step, not a deployment step:** Content curation is ongoing admin work, not a one-time deployment.

**Recommended first batch:** 
- 2 from IEEE Spectrum (engineering or grid topic)
- 2 from IEA (energy policy or statistics)
- 1 from DOE or NREL
- 1 from Hitachi Energy or Siemens Energy
- Ensure at least one insight qualifies for the "NEW" badge (published within last 24 hours)

---

## 14. ROLLBACK PLAN

### Stage 1 (Database) Rollback

| Property | Specification |
|----------|--------------|
| **Trigger** | Table creation fails; constraint error; indexes not created |
| **Method** | `DROP TABLE insights_bookmarks; DROP TABLE insights_read_state; DROP TABLE insights_tags; DROP TABLE catalyst_insights; DROP TABLE insights_raw; DROP TABLE insights_sources;` (reverse dependency order) |
| **Data safety** | No production data in these tables at this stage |
| **Recovery** | Fix schema definition; re-run Stage 1 |

### Stage 2 (RLS) Rollback

| Property | Specification |
|----------|--------------|
| **Trigger** | Policy allows incorrect access or blocks correct access |
| **Method** | `DROP POLICY {policy_name} ON {table_name}` for each new policy |
| **Data safety** | Tables without RLS are inaccessible via JWT (Supabase default behavior is deny-all when RLS is enabled but no policies exist) — safe |
| **Recovery** | Fix policy definitions; re-apply |

### Stage 3 (Storage) Rollback

| Property | Specification |
|----------|--------------|
| **Trigger** | Bucket creation fails; default images not accessible |
| **Method** | Delete `insights-images` bucket (no files yet if rollback is at creation time) |
| **Data safety** | Zero risk — no production data |
| **Recovery** | Re-create bucket; re-upload default images |

### Stage 4 (Edge Functions) Rollback

| Property | Specification |
|----------|--------------|
| **Trigger** | Smoke test failure; pipeline does not progress records correctly |
| **Method** | Disable failing Edge Function in Supabase dashboard; disable DB webhook |
| **Data safety** | Test rows in `insights_raw` and `catalyst_insights` can be deleted manually; no production insights exist yet |
| **Recovery** | Fix function code; redeploy; re-run smoke tests |

### Stage 5 (Schedulers) Rollback

| Property | Specification |
|----------|--------------|
| **Trigger** | Cron job crashes on execution |
| **Method** | Disable cron schedule in Supabase Edge Function settings |
| **Data safety** | No data impact — cron jobs read/write only from Insights tables with no production data yet |
| **Recovery** | Fix function; re-enable cron |

### Stage 6 (Admin APIs) Rollback

| Property | Specification |
|----------|--------------|
| **Trigger** | Admin endpoint returns unexpected errors consistently |
| **Method** | Identify which specific endpoint or RPC function is failing; fix and redeploy or patch |
| **Data safety** | Test insights created during admin API testing can be deleted or left as archived |
| **Recovery** | Fix endpoint; re-test |

### Stage 7 (Flutter Integration) Rollback

| Property | Specification |
|----------|--------------|
| **Trigger** | Flutter crash on Insights tab; regression on any existing tab |
| **Method (Flutter)** | Revert navigation wiring commit. Insights tab reverts to Explore. Backend remains live and unaffected. |
| **Method (Backend)** | None required — backend is operational and correct |
| **Data safety** | All published insights remain safe in database |
| **Recovery time** | Flutter revert: deploy new Flutter build. Backend: no action required. |
| **Critical property** | The backend can remain fully deployed even if Flutter is rolled back. The Insights tab is the only Flutter surface wired to the backend — reverting navigation wiring is a clean, safe rollback with zero data loss. |

---

## 15. TESTING BLUEPRINT

### 15.1 Unit Tests

**Scope:** Individual pure functions within Edge Functions.

| Test | Description |
|------|-------------|
| URL normaliser | Input: URL with UTM params, trailing slash, uppercase hostname → Output: clean, lowercase, no UTM, no trailing slash |
| SHA-256 fingerprint | Deterministic: same input → same hash; different input → different hash |
| OG metadata extractor | HTML fixtures with complete OG tags → correct field extraction; with missing OG → fallback extraction |
| Keyword relevance scorer | Engineering keywords → correct score; non-engineering text → score below threshold |
| Title normaliser | Title with punctuation, stop words → correct normalised output |
| Freshness check | Article dates: today, 30d ago, 89d ago (pass), 91d ago (fail) |
| Paywall detector | JSON-LD with `isAccessibleForFree: false` → detected; without → not detected |
| Sub-path domain matcher | `weforum.org/agenda/energy/article` matching `weforum.org/agenda/energy` → match; `weforum.org/health/` → no match |

### 15.2 Integration Tests

**Scope:** Full Edge Function execution against a staging Supabase project.

| Test | Description |
|------|-------------|
| collect_insight → insights_raw | Submit valid URL → row written with correct fields and status = pending |
| collect_insight duplicate guard | Submit same URL twice → second call returns `already_exists`, no duplicate row |
| collect_insight unauthorised domain | Submit URL from unlisted domain → 400 UNAUTHORIZED_SOURCE |
| validate_insight pass | Trigger on valid raw row → status transitions to `validated` |
| validate_insight reject (each Class A code) | Trigger with each rejection scenario → correct rejection code written |
| deduplication Level 1 | Two rows with same URL fingerprint → second marked duplicate |
| deduplication Level 2 | Two rows with same title fingerprint, different URL → second marked duplicate |
| enrich_insight → AI output | Trigger on validated row → catalyst_insights created with all 7 AI fields present |
| enrich_insight AI confidence routing | Mock AI response with confidence 0.60 → LOW CONFIDENCE flag set |
| image mirror success | Valid OG image URL → WebP uploaded to Storage; hero_image_url = CDN URL |
| image mirror failure | Invalid OG image URL → category default URL used; no crash |
| activate_scheduled_insights | Create scheduled row with `scheduled_at = NOW() - 1 minute` → cron activates it |
| expire_old_insights | Create active row with `published_at = NOW() - 31 days` → cron archives it |
| Flutter API read | Authenticated user SELECT → only active insights returned |
| Flutter API non-auth | Unauthenticated SELECT → 401 |
| Admin approve | Admin JWT PATCH status=active → insight visible in Flutter API |
| Admin reject | Admin JWT PATCH status=rejected → insight not visible in Flutter API |
| Admin cannot read insights_raw | Non-admin JWT SELECT on insights_raw → 0 rows (RLS blocks) |

### 15.3 Pipeline Tests (End-to-End)

**Scope:** Full pipeline from URL submission to Flutter API visibility.

| Test | Steps |
|------|-------|
| Happy path V1 | Submit URL → validate → enrich → admin approve → verify visible in Flutter query |
| Rejection path | Submit URL from unlisted domain → verify rejection in insights_raw; not visible anywhere |
| Duplicate path | Submit same URL twice → first processed normally; second marked duplicate immediately |
| Low confidence path | Submit URL producing low AI confidence → verify LOW CONFIDENCE flag in admin queue; verify admin must explicitly approve |
| Image failure path | Submit URL with broken OG image → verify category default URL in hero_image_url; card renders |
| Schedule and activate | Admin approves with scheduled_at 1 minute in future → wait 15 min → verify insight becomes active |
| Expiry | Create insight with `published_at = 31 days ago` (direct DB insert for test) → run expire job → verify archived; not in Flutter API |

### 15.4 Failure Injection Tests

**Scope:** Verify graceful degradation when dependencies fail.

| Injection | Expected behaviour |
|-----------|-------------------|
| Block Anthropic API (mock 503) | enrich_insight retries 3× with back-off; then sets ai_error; no crash; raw row trackable |
| Block Anthropic API for 10 minutes | Queue depth grows; on API recovery, admin re-triggers failed items; all data intact |
| Block source website (collect_insight target) | OG fetch fails; row written with og_fetch_error=true; validator runs completeness check; article rejected cleanly |
| Supabase Storage unreachable (image mirror) | category default URL used; insight proceeds to review; admin sees NO HERO IMAGE flag |
| DB timeout during validate | Row remains pending; no crash; admin can manually re-trigger; no data loss |
| activate_scheduled_insights crashes | Next cron run (15 min) processes any missed activations; idempotent |
| expire_old_insights crashes | Next day's run processes; 1-day delay acceptable |

### 15.5 Performance Tests

**Scope:** Verify Flutter API latency targets under expected load.

| Test | Scenario | Pass Criteria |
|------|----------|--------------|
| Primary feed query | 50 concurrent Flutter clients querying active insights | P95 < 800ms |
| Primary feed query (larger dataset) | 500 active insights in DB; same query | P95 < 800ms |
| Admin review queue | Admin queries 100 records in review status | P95 < 1200ms |
| Deduplication query | 10,000 rows in insights_raw; fingerprint lookup | P95 < 10ms |
| Pipeline throughput | Submit 20 URLs in rapid succession; observe queue progression | All 20 reach review queue within 5 minutes |

### 15.6 Security Tests

**Scope:** Verify RLS and authentication boundaries hold under adversarial inputs.

| Test | Attack Scenario | Expected Outcome |
|------|----------------|-----------------|
| Non-admin reads insights_raw | Regular user JWT selects from insights_raw | 0 rows returned (RLS blocks) |
| Non-admin updates catalyst_insights | Regular user JWT patches insight status | 403 or 0 rows updated |
| Unauthenticated reads active insights | No JWT selects from catalyst_insights | 401 |
| User reads other user's bookmarks | User A's JWT selects insights_bookmarks with user B's user_id | 0 rows (RLS filters to own rows) |
| Admin reads non-active insights | Admin JWT selects all statuses | Full result set returned |
| URL injection in collect_insight | Submit URL with path traversal or script content | Treated as URL string; OG fetch returns 404 or content; normal pipeline rejection |
| Oversized payload to collect_insight | POST body > 1MB | Supabase Edge Function request size limit returns 413 |
| Repeated collect_insight calls (rate limit) | 100 rapid POSTs from same JWT | Rate limiter triggers; 429 after limit exceeded |

### 15.7 Acceptance Tests

**Scope:** Confirm product behaviour matches Phase 1 specification.

| Acceptance Criteria | Verification Method |
|--------------------|---------------------|
| Admin can publish a new insight in under 5 minutes | Timed walkthrough: submit URL → pipeline completes → admin approves → insight live |
| Zero insights linked to unapproved domains | Attempt to submit URLs from 5 non-whitelisted domains; confirm all rejected |
| No performance regression on existing screens | Run Flutter integration tests on MCFeedScreen, ChallengeListScreen, AnalyticsScreen before and after Insights integration |
| Hero images load on first card view | Open Insights tab, swipe first card → hero image loads; no broken image state |
| "Read Full Article" opens browser with correct URL | Tap button on each of 3 test insights; confirm correct source URL opens |
| Offline state shows stale cache, not error | Disable network after cache populated; open Insights tab → stale banner visible, cards browseable |
| End-of-batch card appears after last insight | Swipe through all available insights → end-of-batch card renders |
| "NEW" badge appears on insights < 24h old | Publish test insight with `published_at = 1 hour ago` → "NEW" badge visible on card |
| Admin LOW CONFIDENCE flag visible | Submit insight producing AI confidence < 0.70 → admin review shows LOW CONFIDENCE warning |
| Category default image used when OG fails | Submit insight with no valid OG image → card renders with correct category image |

---

## 16. IMPLEMENTATION ROADMAP

### Sprint 1: Foundation — Database, Storage, RLS

**Duration:** 1 week  
**Scope:** All database tables, all indexes, all RLS policies, Supabase Storage bucket, category default images.

**Deliverables:**
- All 6 tables created with correct schema
- All indexes applied and verified via EXPLAIN ANALYZE
- All RLS policies applied and verified via security test checklist (§15.6)
- `insights-images` bucket created with public access
- 6 category default WebP images uploaded and publicly accessible
- `insights_sources` seeded with all 25 validated sources (correct tier per Phase 2.5 corrections)

**Dependencies:** None (first sprint). Supabase project already exists.

**Exit criteria:**
- [ ] All tables accessible with correct RLS behaviour
- [ ] Indexes confirmed via Supabase Table Editor
- [ ] All 6 default images return HTTP 200 on CDN URL
- [ ] 25 source rows in `insights_sources` with correct tier and domain

---

### Sprint 2: Core Pipeline — Collector, Validator, Deduplication

**Duration:** 1 week  
**Scope:** `collect_insight` Edge Function, `validate_insight` Edge Function (including deduplication logic), DB webhook configuration.

**Deliverables:**
- `collect_insight` deployed and passing all unit tests and integration tests
- `validate_insight` deployed with all validation rules implemented
- Deduplication Level 1 (URL fingerprint) and Level 2 (title fingerprint) implemented within `validate_insight`
- DB webhook configured: `insights_raw` INSERT → `validate_insight`
- Sub-path domain matching implemented for WEF and EC (Phase 2.5 Change 1)
- End-to-end smoke test: URL → `pending` → `validated` (or correct rejection code)

**Dependencies:** Sprint 1 complete (tables and RLS must exist).

**Exit criteria:**
- [ ] `collect_insight` passes all integration tests (§15.2 rows 1–3)
- [ ] `validate_insight` passes all Class A rejection tests
- [ ] Deduplication correctly catches duplicate URLs
- [ ] Sub-path domain check blocks non-energy WEF URLs
- [ ] DB webhook fires correctly on `insights_raw` INSERT

---

### Sprint 3: AI & Image — Enrichment, Image Mirror, Review Queue Entry

**Duration:** 1.5 weeks  
**Scope:** `enrich_insight` Edge Function, `mirror_insight_image` subroutine, AI prompt engineering, IEEE API optional path, full pipeline from validated → review queue.

**Deliverables:**
- `enrich_insight` deployed with Anthropic API integration
- AI prompt finalised and tested across 10+ real article examples
- Structured JSON output parsing with schema validation
- AI retry logic (3 attempts, exponential back-off) implemented
- `mirror_insight_image` subroutine implemented with WebP conversion
- 3-level image fallback working (mirrored → category default → Flutter placeholder signal)
- IEEE API optional path: when `IEEE_API_KEY` present and domain is `ieeexplore.ieee.org`, fetch abstract
- End-to-end: URL → `validated` → `ai_processed` → `review` with all 7 AI fields populated

**Dependencies:** Sprint 2 complete (validate_insight must be working).

**Exit criteria:**
- [ ] AI enrichment produces valid JSON for 10+ diverse test articles
- [ ] Confidence score distribution: mean ≥ 0.70 across test set
- [ ] Image mirrored to Storage and CDN URL stored in `hero_image_url`
- [ ] Category default used when OG image fails
- [ ] `ai_error` status correctly set when Anthropic API is mocked to fail after retries
- [ ] IEEE abstract path works when API key is present; falls back cleanly when absent
- [ ] All pipeline integration tests passing (§15.2 rows 7–14)

---

### Sprint 4: Admin APIs, Schedulers, Flutter Consumer

**Duration:** 1.5 weeks  
**Scope:** Admin review endpoints (approve/reject/edit/batch), scheduled job deployment, Flutter InsightsRepository + InsightsNotifier + InsightsScreen, navigation wiring.

**Deliverables:**
- All admin API endpoints functional (§6.2)
- `batch_approve_high_confidence` RPC function deployed
- `activate_scheduled_insights` cron deployed and verified
- `expire_old_insights` cron deployed and verified
- Flutter `InsightsRepository` implemented against live production query contract
- Flutter `InsightsNotifier` implemented with pagination, cache, refresh, offline handling
- Flutter `InsightsScreen` rendering correctly with real data (full-screen PageView)
- Navigation wiring: Insights at index 1, Explore removed from bottom nav
- Full end-to-end acceptance test: submit URL → pipeline → admin approve → visible in Flutter
- Zero regression on all 5 existing screens (Home, [replaced], Challenges, Analytics, Profile)

**Dependencies:** Sprint 3 complete. Phase 1 Flutter design decisions followed exactly.

**Exit criteria:**
- [ ] Admin can publish 5 insights in under 5 minutes total (acceptance test)
- [ ] Flutter shows 5+ active insights with hero images loading
- [ ] Pagination: swipe past card 8 → silent background fetch → cards continue without interruption
- [ ] Offline: cache shows stale banner; no crash
- [ ] Pull-to-refresh triggers network fetch
- [ ] All 7 acceptance tests passing (§15.7)
- [ ] All existing screen regression tests passing
- [ ] Deploy plan Stage 7 verification complete

---

## 17. FINAL VALIDATION

### Engineering Ownership Verification

| Component | Owner Module | Owner Sprint | Status |
|-----------|-------------|-------------|--------|
| `insights_sources` table | Admin Review Service | Sprint 1 | ✓ Defined |
| `insights_raw` table | Insights Collector | Sprint 1 | ✓ Defined |
| `catalyst_insights` table | AI Enrichment / Publication | Sprint 1 | ✓ Defined |
| All RLS policies | Security Blueprint | Sprint 1 | ✓ Defined |
| `insights-images` bucket | Image Mirror Service | Sprint 1 | ✓ Defined |
| `collect_insight` EF | Insights Collector | Sprint 2 | ✓ Defined |
| `validate_insight` EF | Insights Validator + Dedup | Sprint 2 | ✓ Defined |
| `enrich_insight` EF | AI Enrichment Service | Sprint 3 | ✓ Defined |
| `mirror_insight_image` subroutine | Image Mirror Service | Sprint 3 | ✓ Defined |
| `activate_scheduled_insights` cron | Publication Service | Sprint 4 | ✓ Defined |
| `expire_old_insights` cron | Expiry & Lifecycle Service | Sprint 4 | ✓ Defined |
| Admin API endpoints | Admin Review Service | Sprint 4 | ✓ Defined |
| Flutter `InsightsRepository` | Flutter API Layer | Sprint 4 | ✓ Defined |
| Flutter `InsightsNotifier` | Flutter API Layer | Sprint 4 | ✓ Defined |

### Architecture Regression Check

| Check | Result |
|-------|--------|
| Existing application tables modified | ✗ No — only new `insights_*` tables created |
| Existing Edge Functions modified | ✗ No — 9 new Edge Functions, all named with `insight`/`insights` prefix |
| Existing Supabase Storage buckets modified | ✗ No — one new `insights-images` bucket |
| Existing Flutter screens modified | ✗ No — only navigation wiring updated (index 1 tab replacement) |
| Existing providers / repositories modified | ✗ No — all new files in `lib/features/insights/` |
| Existing Riverpod providers modified | ✗ No |
| Existing GoRouter routes modified | Navigation only: index 1 route updated, `/insights` route added |
| New patterns introduced | ✗ No — all patterns follow existing codebase conventions |

### Isolation Guarantee

All new components share a consistent namespace:
- DB tables: `insights_*` or `catalyst_insights`
- Edge Functions: `*_insight` or `*_insights`
- Storage: `insights-images` bucket
- Flutter: `lib/features/insights/`

No other feature in The Catalysts touches these namespaces. The feature can be fully disabled by reverting the navigation wiring without touching any other code.

---

## 🟢 PHASE 3 COMPLETE — BACKEND ENGINEERING BLUEPRINT LOCKED

**All requirements satisfied:**

✓ Existing application untouched (zero regressions by design)  
✓ No architectural regressions (all patterns follow existing conventions)  
✓ Catalyst Insights fully isolated (`insights_*` namespace, `features/insights/` module)  
✓ Engineering ownership clearly defined (per module, per table, per Edge Function, per sprint)  
✓ Deployment strategy complete (7 stages with explicit ordering rationale)  
✓ Rollback strategy complete (per-stage trigger, method, data safety, recovery)  
✓ Testing strategy complete (unit / integration / pipeline / failure injection / performance / security / acceptance — 7 categories, 50+ specific tests)  
✓ Implementation order finalised (4 sprints, sequential dependency chain, clear exit criteria)  
✓ Error architecture complete (7 error classes, 26 error codes, propagation rules, log schema)  
✓ Observability complete (pipeline health dashboard, throughput metrics, Flutter consumption events, alert escalation policy)  
✓ Security complete (authentication boundary map, RLS ownership, secret management, input sanitisation, audit logging, supply chain policy)  
✓ Performance specifications complete (latency targets, execution time budgets, query plan expectations, memory budget, startup impact: zero)  

**Implementation teams may begin Sprint 1.**
