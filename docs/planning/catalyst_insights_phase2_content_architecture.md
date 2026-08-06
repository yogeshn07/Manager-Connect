# CATALYST INSIGHTS
## Phase 2 — Content Architecture & Data Platform

**Application:** The Catalysts  
**Feature:** Catalyst Insights  
**Document Phase:** Phase 2 — Content Architecture Lock  
**Status:** ARCHITECTURE ONLY — No code, no SQL, no migrations, no implementation  
**Depends On:** Phase 1 — `catalyst_insights_phase1_product_design.md` (LOCKED)  
**Date:** 2026-07-17  
**Author:** Principal Software Architect / Principal Backend Architect / Principal AI Systems Architect / Principal Flutter Architect / Senior Database Architect / Enterprise Solution Architect

---

## 1. EXECUTIVE SUMMARY

This document freezes the complete content architecture for Catalyst Insights before implementation begins. It defines every layer from trusted source registration through AI enrichment, database persistence, and Flutter consumption.

The architecture is grounded in the existing application's established patterns:

- **BaaS-first:** Supabase PostgREST handles all CRUD. Edge Functions (Deno) handle business logic requiring server-side trust, multi-table atomicity, or third-party integration.
- **Repository pattern in Flutter:** The `InsightsRepository` is the sole Supabase access point for the feature. Screens never touch the Supabase client directly.
- **Riverpod state management:** `InsightsNotifier` manages pagination, cache state, and refresh. No new patterns are introduced.
- **Additive isolation:** Every new database table, Edge Function, storage bucket, and Flutter file lives in its own namespace. No existing table, function, or widget is modified.

The pipeline moves content from trusted industry sources through validation, deduplication, AI enrichment, editorial review, and publication — all without any scraping or URL fetching from within the Flutter app.

---

## 2. ARCHITECTURE OVERVIEW

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                         CATALYST INSIGHTS PIPELINE                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 0: TRUSTED SOURCES                                                   │
│  Tier 1 (IEEE, IEA, CIGRÉ, Hitachi Energy) ─────────────────────────────── │
│  Tier 2 (Siemens Energy, GE Vernova, NREL, DOE) ──────────────────────────  │
│  Tier 3 (Utility Dive, EPRI, ASCE, regional energy agencies) ─────────────  │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           │  RSS feeds / admin-submitted URLs
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 1: CONTENT COLLECTOR                                                 │
│  Edge Function: collect_insight                                              │
│  • Fetches Open Graph metadata (title, description, og:image, publish date) │
│  • Does NOT fetch full article body — metadata only                          │
│  • Validates source domain against approved whitelist                        │
│  • Writes raw record to insights_raw table (status: pending)                 │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 2: QUALITY VALIDATION                                                │
│  Edge Function: validate_insight (triggered by DB webhook on insights_raw)  │
│  • Freshness check: reject if article older than 90 days                    │
│  • Completeness check: headline ≥ 10 chars, description ≥ 20 chars          │
│  • URL check: resolves to HTTP 200, is HTTPS                                │
│  • Source domain check: must match approved_domains in insights_sources     │
│  • Keyword relevance check: presence of engineering/energy keywords         │
│  → Rejected: status = rejected (with reason code)                           │
│  → Passed: status = validated                                                │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 3: DUPLICATE DETECTION                                               │
│  Part of validate_insight or separate dedup_insight function                │
│  • Exact URL match (normalized: strip UTM params, trailing slash)           │
│  • URL fingerprint: SHA-256 of normalized URL                                │
│  • Title similarity: normalized title hash comparison                        │
│  • Same-story cross-source detection: TF-IDF keyword overlap > 85%          │
│  → Duplicate detected: status = duplicate (stores original_insight_id ref)  │
│  → Unique: proceeds to AI layer                                              │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 4: AI PROCESSING                                                     │
│  Edge Function: enrich_insight (calls Anthropic Claude API)                 │
│  • Generates: executive summary, why_this_matters, key_takeaway             │
│  • Assigns: suggested_category, tags (3–5)                                  │
│  • Estimates: reading_time_minutes                                           │
│  • Scores: confidence (0.0–1.0)                                              │
│  • Stores results in insights_ai_metadata                                    │
│  → status = ai_processed                                                     │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 5: IMAGE HANDLING                                                    │
│  Edge Function: mirror_insight_image (called inside enrich_insight)         │
│  • Downloads og:image from source                                            │
│  • Validates: image > 400×200px, < 5MB, is JPEG/PNG/WebP                    │
│  • Uploads to Supabase Storage bucket: insights-images/{insight_id}.webp    │
│  • Sets hero_image_url = Supabase CDN URL                                   │
│  → If image download fails: uses category default image URL                 │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 6: ADMIN REVIEW QUEUE                                                │
│  Admin Dashboard (Flutter) → reads catalyst_insights where status=review    │
│  • Admin sees AI-generated fields pre-populated                              │
│  • Admin can edit: headline, summary, category, tags, reading_time          │
│  • Admin approves → status = scheduled or active                            │
│  • Admin rejects → status = rejected                                         │
│  • High-confidence (≥ 0.90) items are batch-displayable for 1-tap approve  │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 7: PUBLICATION & SUPABASE STORAGE                                   │
│  • status = active → visible in Flutter feed                                │
│  • status = scheduled → auto-activated at scheduled_at timestamp            │
│  • Scheduler: Edge Function cron job activate_scheduled_insights             │
│  • Ordered by published_at DESC in Flutter queries                           │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 8: FLUTTER API CONSUMPTION                                           │
│  InsightsRepository → Supabase PostgREST → catalyst_insights                │
│  • Filter: status = active                                                  │
│  • Order: published_at DESC                                                 │
│  • Pagination: 10 per page                                                  │
│  • Fields: all display-ready fields (no raw ingest fields exposed)          │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 9: EXPIRY                                                            │
│  Edge Function cron job: expire_old_insights (runs daily)                   │
│  • Auto-archives insights where published_at < NOW() - 30 days              │
│  • Except: is_evergreen = true                                               │
│  • Archived insights: status = archived, not returned by Flutter queries    │
│  • Archived insights are retained (never deleted) for audit                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. TRUSTED SOURCE HIERARCHY

The source hierarchy is enforced at the database level through the `insights_sources` table. No article from a domain not present in this table may enter the pipeline, regardless of who submits it.

### Tier 1 — Authoritative Domain Sources

The highest trust level. These are globally recognized standards bodies, intergovernmental organizations, and vertically integrated industry leaders with peer-reviewed or officially sanctioned publications.

| Source | Domain | Publication Type |
|--------|--------|-----------------|
| IEEE | ieee.org, spectrum.ieee.org, ieeexplore.ieee.org | Standards, research, news |
| IEEE Power & Energy Society | pes.ieee.org | Grid, power systems |
| CIGRÉ | cigre.org, e-cigre.org | Grid engineering, technical brochures |
| International Energy Agency | iea.org | Energy policy, statistics, reports |
| Hitachi Energy | hitachienergy.com/en/news | Corporate + grid technology |
| U.S. Department of Energy | energy.gov | Policy, R&D, grid programs |

**Tier 1 rule:** Articles from Tier 1 sources bypass keyword relevance check (they are presumed engineering-relevant). They still pass freshness, completeness, URL, and duplicate checks.

### Tier 2 — Major Industry Organizations & OEMs

Highly credible but occasionally publish marketing content that must be filtered by keyword relevance check.

| Source | Domain | Notes |
|--------|--------|-------|
| Siemens Energy | siemens-energy.com/global/en/news | OEM engineering news |
| GE Vernova | gevernova.com/news | Grid, turbines, energy transition |
| Schneider Electric | se.com/ww/en/insights | Grid automation, energy mgmt |
| ABB | new.abb.com/news/en | Power equipment, digital grid |
| NREL | nrel.gov/news | Renewable energy research |
| EPRI | epri.com/research | Power system research |
| Rocky Mountain Institute (RMI) | rmi.org/insights | Energy transition analysis |
| World Economic Forum (Energy) | weforum.org (energy tag only) | Energy policy, grid investment |
| European Commission (Energy) | ec.europa.eu/energy | EU energy regulation |
| U.S. EIA | eia.gov | Energy statistics, forecasts |

**Tier 2 rule:** Keyword relevance check applies. Articles must contain at least one keyword from the engineering relevance dictionary (see §9, Quality Policy).

### Tier 3 — Professional Industry Publications

Reputable industry journalism and professional society publications. Moderate editorial standards. Keyword relevance check applies. Admin spot-check recommended for new sources.

| Source | Domain | Notes |
|--------|--------|-------|
| Utility Dive | utilitydive.com | Grid, utilities, energy markets |
| Power Magazine | powermag.com | Power generation, transmission |
| T&D World | tdworld.com | Transmission and distribution |
| Electric Light & Power | elp.com | Utility management |
| Renewable Energy World | renewableenergyworld.com | Clean energy |
| ASCE Civil Engineering | asce.org/publications | Infrastructure engineering |
| Energy Monitor | energymonitor.ai | Energy transition coverage |
| PV Magazine | pv-magazine.com | Solar PV technology |
| Wind Power Engineering | windpowerengineering.com | Wind systems |
| S&P Global Commodity Insights | spglobal.com (energy tag) | Energy markets, pricing |

**Tier 3 rule:** Keyword relevance check applies. Admin may add new Tier 3 sources via the admin dashboard. New Tier 3 additions require admin confirmation (not auto-approved).

### Source Expansion Policy

- New sources may be added to any tier by admin only.
- Addition to Tier 1 requires review of at least 5 published articles for quality confirmation.
- Sources may be suspended (not deleted) if quality drops. Suspension prevents new ingestion but preserves existing insights.
- Removal from whitelist does not retroactively archive existing published insights.

---

## 4. CONTENT PIPELINE — DETAILED SPECIFICATION

### Stage 1: Discovery

**V1 — Manual Submission (Admin-curated)**

The admin directly provides article URLs through the Insights Management section of the Admin Dashboard. This is the only discovery mechanism in V1.

**V2 — Automated RSS Polling**

A scheduled Supabase Edge Function (`poll_rss_feeds`) runs every 4 hours and fetches RSS/Atom feeds from all approved Tier 1, 2, and 3 sources. New entries not already in the system are submitted to the collection stage automatically.

**V3 — Webhook / API Push**

Some sources (IEEE, IEA) offer newsletter or API subscriptions. In V3, webhooks from approved publisher APIs can push article metadata directly to the `collect_insight` Edge Function endpoint.

### Stage 2: Collection

**Input:** Article URL (admin-provided in V1, RSS item in V2).

**Process:**
1. Normalize URL: remove UTM parameters (`?utm_*`), trailing slash, lowercase hostname.
2. Fetch page metadata via HTTP HEAD + limited GET (first 8KB of HTML only — not full scrape).
3. Extract Open Graph tags: `og:title`, `og:description`, `og:image`, `article:published_time`.
4. Extract fallbacks: `<title>`, `<meta name="description">`, first `<img>` if no `og:image`.
5. Estimate reading time: if article word count is detectable from meta, use it; else use source-tier average (Tier 1 = 8 min average, Tier 2 = 5 min, Tier 3 = 4 min).
6. Write to `insights_raw` with status = `pending`.

**Flutter NEVER performs this step.** This is a pure backend operation.

### Stage 3: Quality Validation

Applied to every raw record with status = `pending`.

**Automated checks (all must pass):**

| Check | Rule | Reject Reason Code |
|-------|------|-------------------|
| Source domain | Domain must exist in `insights_sources.approved_domain` | `UNAUTHORIZED_SOURCE` |
| URL scheme | Must be `https://` | `INSECURE_URL` |
| URL resolution | HTTP response must be 200 or 301/302 resolving to 200 | `DEAD_LINK` |
| Headline length | ≥ 10 characters, ≤ 240 characters | `INVALID_HEADLINE` |
| Description length | ≥ 30 characters | `INSUFFICIENT_DESCRIPTION` |
| Freshness | `article:published_time` must be ≤ 90 days ago | `STALE_CONTENT` |
| Not paywalled | No paywall meta tag (`isAccessibleForFree: false`) | `PAYWALL_DETECTED` |

**Tier-specific check:**

| Tier | Additional Check |
|------|-----------------|
| Tier 1 | No additional check — content is presumed relevant |
| Tier 2 | Keyword relevance check (see §9) must return score ≥ 0.4 |
| Tier 3 | Keyword relevance check must return score ≥ 0.6 |

**Outcome:** Passes → status = `validated`. Fails → status = `rejected` + `rejection_reason` populated.

### Stage 4: Duplicate Detection

Applied immediately after validation.

**Three-level deduplication:**

**Level 1 — Exact URL match**  
Normalized URL fingerprint (SHA-256) compared against `insights_url_fingerprint` column across all records (not just active ones). Duplicates are rejected even if the original was archived.

**Level 2 — Title fingerprint**  
Normalized title (lowercase, punctuation stripped, stop words removed) compared via exact match. Catches the same article re-submitted with minor URL variation.

**Level 3 — Cross-source story detection (V2)**  
TF-IDF keyword vector of `{headline} + {description}` compared against the last 72 hours of `validated` records. If cosine similarity > 0.85, flag as a likely same-story duplicate. Admin decides which source to prefer. In V1, this check is a recommendation flag rather than an automatic rejection.

**Outcome:** Unique → proceeds to AI. Duplicate → status = `duplicate`, `duplicate_of_id` FK set.

### Stage 5: AI Processing

The core enrichment step. A Supabase Edge Function (`enrich_insight`) calls the Anthropic Claude API with a structured prompt. The model recommended is **Claude claude-haiku-4-5-20251001** for cost efficiency and speed. The prompt is strictly typed and requests a JSON response.

**Input to AI:** Article headline + meta description + source name + publication date.

**AI does NOT receive:** Full article text (not scraped). The AI works only with publicly available metadata.

**Output schema (structured JSON):**

```
{
  "executive_summary": string,     // max 80 words, 3-4 sentences
  "why_this_matters": string,      // max 50 words, professional relevance
  "key_takeaway": string,          // max 25 words, single crisp insight
  "suggested_category": string,    // one of 6 defined category codes
  "tags": string[],                // 3-5 sub-topic tags
  "reading_time_minutes": int,     // estimated, 1–20
  "confidence_score": float        // 0.0–1.0, AI's self-assessed relevance
}
```

**Field purposes:**

| Field | Why It Exists |
|-------|--------------|
| `executive_summary` | Time-poor managers need the core in 30 seconds. 80 words is a hard cap. |
| `why_this_matters` | Bridges the article to the manager's professional context. Prevents generic summaries. |
| `key_takeaway` | Single memorable point. Designed to be shareable in conversation or a meeting. |
| `suggested_category` | Enables future filtering and personalization. Admin retains override authority. |
| `tags` | Sub-topic granularity below category. Powers future recommendation engine. |
| `reading_time_minutes` | Sets time expectation before the user taps "Read Full Article." Respects their time. |
| `confidence_score` | Gates automatic processing. Low-confidence items enter admin review queue with a flag. Low confidence may indicate non-engineering content that passed keyword checks. |

**Confidence routing:**

| Score | Action |
|-------|--------|
| ≥ 0.90 | Enters admin review queue with "HIGH CONFIDENCE" badge. One-tap approve. |
| 0.70 – 0.89 | Enters admin review queue. Standard review. |
| < 0.70 | Enters admin review queue with "LOW CONFIDENCE" flag. Admin must explicitly approve. |

**AI is an enrichment layer, not a gatekeeper.** The admin always has final authority. AI output is presented as pre-populated suggestions, not immutable facts.

**AI transparency label:** The executive summary is stored with an `is_ai_generated = true` flag. The Flutter card displays an "AI SUMMARY" overline label (defined in Phase 1 spec). This is a transparency guarantee, not decorative.

### Stage 6: Image Handling

The `mirror_insight_image` subroutine runs within `enrich_insight`.

**Process:**
1. Attempt to download `og:image` URL.
2. Validate: minimum 400×200 pixels, maximum 5MB, format is JPEG/PNG/WebP/GIF.
3. Convert to WebP at 85% quality (reduces size by ~30–40% vs JPEG with no perceptible quality loss).
4. Upload to Supabase Storage bucket `insights-images` at path `insights/{insight_id}/hero.webp`.
5. Set `hero_image_url` = Supabase CDN public URL.

**Fallback hierarchy:**
1. Source OG image → mirrored to Storage ✓
2. Source OG image fails → category default image (pre-loaded in `insights-images/defaults/{category}.webp`)
3. Category default fails → solid-colour placeholder using category hex code (rendered by Flutter, no image request)

**Licensing consideration:** Using an article's Open Graph image for a thumbnail linking back to the original article is a standard, widely accepted practice in content aggregation and falls within editorial fair use norms. Every insight card displays the source name and links to the original article, satisfying attribution requirements.

**Why Supabase Storage (not direct source URL):**
- Source CDN URLs may expire, rotate, or become unavailable.
- Direct source URLs expose the app to third-party CDN failures.
- Supabase Storage gives us control over availability, resize, and cache headers.
- Enables future image optimization pipeline (WebP, responsive sizes) without app changes.

### Stage 7: Admin Review

The Insights Management section of the admin dashboard (a new section within the existing `AdminDashboardScreen`) displays records with `status = review`.

**Admin workflow:**

1. See batch of pending insights sorted by confidence score DESC.
2. For each insight: headline, source, date, AI summary, why_matters, key_takeaway, category, tags, reading_time are all pre-populated.
3. Admin actions available:
   - **Edit** any field inline.
   - **Approve** → sets `status = active` (immediate) or prompts for scheduled datetime.
   - **Reject** → sets `status = rejected`, prompts for optional rejection note.
   - **Batch approve** all HIGH CONFIDENCE items → single tap.

**The admin dashboard UI for this feature is entirely in the new Insights admin section. No existing admin screen is modified.**

### Stage 8: Publication

**Immediate publish:** Admin approves → `status = active`, `published_at = now()`.

**Scheduled publish:** Admin sets future datetime → `status = scheduled`, `scheduled_at = {datetime}`.

The scheduled activation cron (`activate_scheduled_insights`) checks every 15 minutes for records where `status = scheduled AND scheduled_at <= now()` and sets them to `active`.

**Ordering:** Flutter queries order by `published_at DESC`. Newly activated insights always appear at the top.

### Stage 9: Content Lifecycle

```
pending
  → validated (passes quality checks)
  → duplicate (duplicate detected)
  → rejected (failed validation or admin rejected)
  → ai_processed (AI enrichment complete)
  → review (ready for admin decision)
  → scheduled (admin approved with future date)
  → active (live in Flutter feed)
  → archived (auto-expired or admin-archived)
```

**Terminal states:** `archived`, `rejected`, `duplicate` — records in these states are never returned to Flutter. They are retained for audit (no hard deletes on insight records).

### Stage 10: Expiry

The `expire_old_insights` cron function runs daily at 02:00 UTC.

**Rules:**

| Condition | Action |
|-----------|--------|
| `published_at < NOW() - 30 days` AND `is_evergreen = false` | Set `status = archived` |
| `is_evergreen = true` | No action — retained indefinitely |
| `status = active AND source suspended` | Set `status = archived` |

**Evergreen content examples:** IEEE standards publications, CIGRÉ technical brochures, foundational IEA reports. These are marked `is_evergreen = true` by the admin at publish time.

---

## 5. DATA MODEL

This section defines the logical data model. No SQL, no migrations. Tables are named for reference. Implementation defines exact column types and constraints.

### Entity: `insights_sources`

The approved source whitelist. The single source of truth for which domains may enter the pipeline.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | PK |
| `name` | Text | Display name (e.g. "IEEE Spectrum") |
| `approved_domain` | Text | Domain to match (e.g. "spectrum.ieee.org") |
| `tier` | Integer | 1, 2, or 3 |
| `rss_feed_url` | Text | Nullable. RSS/Atom feed URL for V2 automated polling |
| `is_active` | Boolean | False = suspended, prevents new ingestion |
| `default_category` | Text | Suggested category code for this source |
| `added_by` | UUID | FK → profiles.id (admin who added) |
| `notes` | Text | Nullable. Internal admin notes |
| `created_at` | Timestamptz | |
| `updated_at` | Timestamptz | |

**Indexes:** `approved_domain` (UNIQUE), `tier`, `is_active`.

**RLS:** SELECT by authenticated users (to support domain validation in Edge Functions). INSERT/UPDATE by admin only.

---

### Entity: `insights_raw`

The ingest queue. Holds articles from the moment they enter the system until they are promoted to `catalyst_insights` or rejected.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | PK |
| `source_id` | UUID | FK → insights_sources.id |
| `original_url` | Text | Raw submitted URL |
| `normalized_url` | Text | UTM-stripped, lowercase |
| `url_fingerprint` | Text | SHA-256 of normalized URL |
| `title` | Text | OG or page title |
| `description` | Text | OG or meta description |
| `og_image_url` | Text | Nullable. Raw OG image URL |
| `article_published_at` | Timestamptz | Nullable. From article:published_time |
| `status` | Text | pending / validated / duplicate / rejected / promoted |
| `rejection_reason` | Text | Nullable. Error code |
| `duplicate_of_id` | UUID | Nullable. FK → insights_raw.id or catalyst_insights.id |
| `relevance_score` | Float | Keyword relevance score (0.0–1.0) |
| `submitted_by` | UUID | Nullable. Admin profile ID if manually submitted |
| `submitted_via` | Text | manual / rss / webhook |
| `promoted_to_id` | UUID | Nullable. FK → catalyst_insights.id on promotion |
| `created_at` | Timestamptz | |
| `updated_at` | Timestamptz | |

**Indexes:** `url_fingerprint` (UNIQUE), `status`, `source_id`, `article_published_at`.

**Retention:** Records older than 90 days with terminal status (rejected/duplicate) may be hard-deleted in a future cleanup job. `promoted` records are retained indefinitely for audit.

**RLS:** INSERT by Edge Functions only (service role). SELECT by admin only.

---

### Entity: `catalyst_insights` ← PRIMARY TABLE (Flutter reads this)

The published insights table. This is the only table Flutter queries directly.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | PK |
| `raw_id` | UUID | Nullable. FK → insights_raw.id (traceability) |
| `source_id` | UUID | FK → insights_sources.id |
| `source_name` | Text | Denormalized for query efficiency |
| `source_url` | Text | Direct link to original article (url_launcher target) |
| `headline` | Text | Admin-confirmed headline (max 240 chars) |
| `hero_image_url` | Text | Supabase Storage CDN URL |
| `category` | Text | One of: grid_technology / energy_transition / industry_standards / engineering_leadership / policy_markets / innovation |
| `is_evergreen` | Boolean | True = exempt from auto-expiry |
| `status` | Text | pending / ai_processed / review / scheduled / active / archived / rejected |
| `scheduled_at` | Timestamptz | Nullable. Auto-activation datetime |
| `published_at` | Timestamptz | Set when status → active |
| `article_date` | Date | Publication date of the original article |
| `reading_time_minutes` | Integer | Admin-confirmed reading estimate |
| `ai_summary` | Text | AI-generated executive summary (max 500 chars) |
| `ai_why_matters` | Text | AI-generated professional relevance note (max 300 chars) |
| `ai_key_takeaway` | Text | AI-generated single sentence takeaway (max 200 chars) |
| `ai_suggested_category` | Text | AI's category suggestion (admin may override) |
| `ai_tags` | Text[] | AI-generated sub-topic tags (array of strings) |
| `ai_confidence` | Float | 0.0–1.0 confidence score |
| `ai_is_generated` | Boolean | True for all AI-enriched fields |
| `ai_model` | Text | Model identifier (e.g. "claude-haiku-4-5-20251001") |
| `ai_processed_at` | Timestamptz | When AI enrichment completed |
| `admin_edited` | Boolean | True if admin manually edited any AI field |
| `created_by` | UUID | FK → profiles.id (admin who created/approved) |
| `created_at` | Timestamptz | |
| `updated_at` | Timestamptz | |

**Indexes:**
- `status` — filtered by Flutter queries
- `published_at DESC` — ordering
- `category` — future category filtering
- `source_id` — source-based queries
- `(status, published_at)` composite — primary Flutter query index

**RLS:**
- `SELECT`: authenticated users, `status = active` only
- `INSERT`: admin only
- `UPDATE`: admin only (status transitions, field edits)
- `DELETE`: never (soft lifecycle only)

---

### Entity: `insights_tags` (V2 — defined now for schema compatibility)

Tag taxonomy. Defined in Phase 2 to ensure V1 data model does not foreclose V2 tag filtering.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | PK |
| `tag` | Text | UNIQUE. e.g. "SCADA", "hydrogen", "FERC" |
| `category` | Text | Parent category code |
| `created_at` | Timestamptz | |

**Note:** In V1, tags are stored as `Text[]` inline on `catalyst_insights`. The `insights_tags` table is created empty in V1 for schema consistency. V2 normalizes the relationship.

---

### Entity: `insights_read_state` (V2 — defined for schema compatibility)

Tracks which insights a user has read. Not implemented in V1 but defined to prevent breaking migrations later.

| Field | Type | Notes |
|-------|------|-------|
| `user_id` | UUID | FK → profiles.id |
| `insight_id` | UUID | FK → catalyst_insights.id |
| `read_at` | Timestamptz | |
| `article_opened` | Boolean | True if "Read Full Article" was tapped |

**PK:** Composite `(user_id, insight_id)`.

---

### Entity: `insights_bookmarks` (V2 — defined for schema compatibility)

| Field | Type | Notes |
|-------|------|-------|
| `user_id` | UUID | FK → profiles.id |
| `insight_id` | UUID | FK → catalyst_insights.id |
| `saved_at` | Timestamptz | |

**PK:** Composite `(user_id, insight_id)`.

---

### Relationship Diagram

```
insights_sources ──< catalyst_insights >── insights_read_state ─── profiles
                          │                        (V2)
                     insights_raw ──────────────────────────────────────────
                          │
                    insights_tags (V2 normalization of ai_tags array)
```

---

### Retention Policy

| Table | Retention Rule |
|-------|---------------|
| `insights_sources` | Permanent (suspension, not deletion) |
| `insights_raw` (rejected/duplicate) | 90 days, then hard delete |
| `insights_raw` (promoted) | Indefinite (audit trail) |
| `catalyst_insights` (all statuses) | Indefinite (soft lifecycle only) |
| `insights_read_state` | Indefinite |
| `insights_bookmarks` | Until user deletes bookmark |

---

## 6. FRESHNESS POLICY

Every active insight is assigned a freshness classification based on the time elapsed since `published_at`. This drives the Flutter card's freshness badge display.

### Freshness Tiers

| Tier | Name | Age Condition | Flutter Badge |
|------|------|--------------|---------------|
| F1 | Breaking | `published_at` within 24 hours | Red pill: "NEW" |
| F2 | Fresh | 24 hours – 7 days | No badge (standard display) |
| F3 | Recent | 7 – 30 days | No badge |
| F4 | Evergreen | `is_evergreen = true`, any age | Small leaf icon (optional, V2) |
| F5 | Expiring | 25–30 days (approaching archival) | No badge — internal signal only |

**The "NEW" badge** is the only freshness indicator visible to users in V1. It signals content from the past 24 hours. This gives admins a tool for timeliness: publishing a major IEEE announcement on the day it drops earns the red pill and signals editorial responsiveness.

### Stale Content Handling

- Auto-archival at 30 days (except `is_evergreen`).
- Archived content is never returned to Flutter (status filter ensures this).
- Admin may manually archive any insight at any time via the review dashboard.
- Admin may extend an insight's active period by adjusting `published_at` forward (re-dating — only for evergreen-class content, to be used sparingly).
- The Flutter feed never shows an explicit "this content is old" warning. Stale content simply disappears from the feed.

### Minimum Active Batch Size

If fewer than 5 active insights exist, the Flutter client displays the reduced feed normally (no artificial padding). The end-of-batch screen appears sooner. Admins should receive a low-stock alert (V2 feature) when fewer than 10 active insights remain.

---

## 7. MEDIA POLICY

### Hero Image Requirements

| Property | Requirement |
|----------|------------|
| Minimum dimensions | 400×200px |
| Maximum file size | 5MB before processing |
| Accepted input formats | JPEG, PNG, WebP, GIF (first frame only) |
| Output format | WebP at 85% quality |
| Stored at | `insights-images/{insight_id}/hero.webp` |
| Delivered via | Supabase Storage CDN public URL |

### Image Fallback Hierarchy

```
1. OG image from source article → mirrored to Supabase Storage ✓
       │
       └──► Download fails or validation fails
                      │
                      ▼
           2. Category default image
              (pre-loaded, one per category)
              Path: insights-images/defaults/{category_code}.webp
                      │
                      └──► Missing (configuration error)
                                     │
                                     ▼
                         3. Flutter-rendered placeholder
                            Solid fill: category hex colour
                            + centred category icon (Material Icon)
                            No network request required
```

### Category Default Images

One default image per category is pre-designed, uploaded to Supabase Storage, and used as a fallback. These are abstract, royalty-free editorial images. They are never served as hero images for insights that have a valid OG image.

| Category | Placeholder Description |
|----------|------------------------|
| grid_technology | Abstract power grid topology visualization |
| energy_transition | Wind turbines / solar panels panoramic |
| industry_standards | Engineering blueprint / circuit diagram |
| engineering_leadership | Professional team meeting / whiteboard |
| policy_markets | Government building / power exchange floor |
| innovation | Abstract light/circuit technology concept |

### Licensing Policy

**Open Graph thumbnail use** (using a source article's OG image as a small thumbnail that links to the original article) is a universally accepted editorial practice, comparable to how Google News, Apple News, Feedly, and similar aggregators operate. Key controls that keep this within acceptable use:

1. Source attribution is mandatory and prominently displayed on every card.
2. The card links directly to the original article. Traffic is directed to the publisher, not retained in the app.
3. Only the metadata image (OG image) is used, not any full article body.
4. Images are resized and converted — they are not served at original resolution.
5. Admin may replace any OG image with a licensed alternative at any time.

**In the event a source requests removal:** Admin can set `is_active = false` on the source and manually archive affected insights within minutes. No architectural changes required.

---

## 8. CONTENT QUALITY POLICY

### Validation Rules

**Automatic rejection (no admin review):**

| Rule | Reason |
|------|--------|
| Source domain not in `insights_sources` | Unauthorized source |
| URL does not resolve to HTTP 200 | Dead link |
| URL is HTTP (not HTTPS) | Security |
| Headline is fewer than 10 characters | Incomplete |
| Description is fewer than 30 characters | Insufficient context for AI |
| Article published more than 90 days ago | Stale content |
| Article is behind paywall (`isAccessibleForFree: false` meta) | Not publicly accessible |
| Exact URL fingerprint already in database | Duplicate |

**Admin-flagged items (shown with warning, not auto-rejected):**

| Flag | Indicator |
|------|-----------|
| AI confidence < 0.70 | "LOW CONFIDENCE — Review carefully" |
| Title similarity match (Level 2 dedup) | "POSSIBLE DUPLICATE" |
| Cross-source story match (Level 3, V2) | "SAME STORY from other source" |
| No OG image available | "NO HERO IMAGE — Category default will be used" |

### Engineering Relevance Keyword Dictionary

Used for Tier 2 and Tier 3 sources to confirm engineering/energy relevance. A weighted dictionary of terms. Relevance score = weighted term frequency across `{headline} + {description}`.

**High-weight terms (score += 0.3 each):**
grid, power system, transmission, distribution, substation, SCADA, smart grid, HVDC, renewable energy, energy storage, battery, photovoltaic, wind turbine, hydrogen, fuel cell, microgrid, DER, virtual power plant, demand response, IEEE, CIGRÉ, IEC, NERC, FERC, energy transition, decarbonization

**Medium-weight terms (score += 0.15 each):**
utility, infrastructure, capacity, metering, inverter, transformer, switchgear, relay protection, cybersecurity (energy context), electrification, EV charging, offshore, interconnection, tariff (energy context), carbon, emissions

**Low-weight terms (score += 0.05 each):**
engineering, technology, innovation, digital, automation, software, management, policy, regulation, investment

**Minimum score threshold:** Tier 2 ≥ 0.4, Tier 3 ≥ 0.6. This is tunable without architectural changes (stored as config in `insights_sources.tier` defaults or a config table).

### Clickbait Detection

Headlines that match clickbait patterns are flagged for admin review (not auto-rejected in V1):

- Contains "You Won't Believe", "This Is Why", "The Secret To", numbered list without context (e.g. "7 Things About...")
- Excessive punctuation (!!! or ???)
- All-caps headline

In practice, Tier 1 sources never produce clickbait. This filter is primarily a safeguard for Tier 3 sources.

---

## 9. FLUTTER INTEGRATION ARCHITECTURE

The Flutter application consumes Catalyst Insights through a self-contained feature module. No existing Flutter code is called from within the Insights feature, and the Insights feature is not called from any existing Flutter code until Phase 3 (navigation integration).

### 9.1 Feature Module Structure

```
lib/
└── features/
    └── insights/
        ├── data/
        │   ├── models/
        │   │   └── insight_dto.dart         ← Dart model for catalyst_insights row
        │   └── repositories/
        │       └── insights_repository.dart ← Single Supabase access point
        └── presentation/
            ├── providers/
            │   └── insights_provider.dart   ← NotifierProvider with pagination
            └── screens/
                └── insights_screen.dart     ← Full-screen PageView
```

### 9.2 InsightDto — Field Mapping

Maps `catalyst_insights` columns to Dart fields. Only display-ready fields are included. Internal pipeline fields (`raw_id`, `ai_suggested_category`, `ai_model`, `ai_processed_at`) are not returned in the Flutter query.

| Dart Field | DB Column | Notes |
|-----------|-----------|-------|
| `id` | `id` | UUID |
| `headline` | `headline` | Display title |
| `summary` | `ai_summary` | The AI executive summary |
| `whyItMatters` | `ai_why_matters` | AI professional context |
| `keyTakeaway` | `ai_key_takeaway` | AI single-sentence takeaway |
| `heroImageUrl` | `hero_image_url` | Supabase Storage CDN URL |
| `sourceName` | `source_name` | Denormalized source display name |
| `sourceUrl` | `source_url` | url_launcher target |
| `articleDate` | `article_date` | Original article publication date |
| `readingTimeMinutes` | `reading_time_minutes` | Integer |
| `category` | `category` | Category code string |
| `tags` | `ai_tags` | List<String> |
| `publishedAt` | `published_at` | Used to compute freshness badge |
| `isAiGenerated` | `ai_is_generated` | Boolean transparency flag |

### 9.3 InsightsRepository — Query Contract

**Primary fetch (paginated):**

```
SELECT
  id, headline, ai_summary, ai_why_matters, ai_key_takeaway,
  hero_image_url, source_name, source_url, article_date,
  reading_time_minutes, category, ai_tags, published_at, ai_is_generated
FROM catalyst_insights
WHERE status = 'active'
ORDER BY published_at DESC
LIMIT 10
OFFSET {page * 10}
```

**Characteristics:**
- No joins required — all display fields are denormalized on `catalyst_insights`.
- RLS ensures non-active records are never returned even if status filter were removed.
- `OFFSET` pagination is acceptable at current scale (< 1000 insights). Cursor-based pagination is specified for V3 (see §13).

**Refresh fetch (same query, page 0 only):**

Triggered on: app foreground if cache age > 60 minutes, or pull-down gesture.

**Admin fetch (additional fields):**

The admin dashboard query includes pipeline fields: `status`, `ai_confidence`, `ai_suggested_category`, `ai_model`, `rejection_reason`, `raw_id`. Admin queries filter by all statuses, not just `active`.

### 9.4 InsightsNotifier — State Contract

A Riverpod `Notifier<InsightsState>` managing:

```
InsightsState {
  List<InsightDto> insights       // Loaded insights, accumulated across pages
  bool isLoading                  // Initial load in progress
  bool isFetchingMore             // Pagination fetch in progress
  bool hasMore                    // Whether more pages exist
  int currentPage                 // Next page to fetch
  DateTime? lastFetchedAt         // Cache timestamp
  InsightsError? error            // Null if no error
  bool isOffline                  // True if loaded from cache with no network
}
```

**Notifier methods:**
- `loadInitial()` — fetch page 0, populate cache
- `fetchMore()` — fetch next page, append to `insights` list
- `refresh()` — reset to page 0, force network fetch, update cache
- `markAllRead()` — V2 stub (no-op in V1)

**Provider initialization:** The `InsightsNotifier` is NOT initialized on app startup. It is a lazy provider — instantiated the first time the Insights tab is tapped. This ensures zero startup cost for the existing application's cold launch.

### 9.5 Caching Strategy

**Cache storage:** `SharedPreferences` (already available via `shared_preferences` package — confirm in pubspec during implementation phase).

**What is cached:**
- JSON serialization of the first page (10 insights) of the last successful network fetch.
- Cache timestamp.
- NOT cached: page 2+ (pagination content is ephemeral by design).

**Cache read policy:**
- On app launch + first Insights tab open: if cache exists and age < 60 minutes → show cache immediately, trigger background refresh.
- If cache age ≥ 60 minutes → show loading skeleton, await network fetch.
- If network fetch fails and cache exists → show cache with stale banner.
- If network fetch fails and no cache → show error state.

**Cache invalidation:**
- Any successful `refresh()` call overwrites the cache.
- Cache is NOT invalidated across app restarts — it persists to disk.
- Cache maximum size: 10 insights × ~2KB each ≈ 20KB. Negligible.

### 9.6 Pagination Architecture

| Event | Action |
|-------|--------|
| User reaches card 8 of 10 | Trigger `fetchMore()` silently |
| `fetchMore()` in progress | Show subtle progress indicator below last card |
| Response returns < 10 items | Set `hasMore = false` — display end-of-batch card |
| Response returns 0 items | Set `hasMore = false` |
| `fetchMore()` fails | Retry once. On second failure: show inline retry button |

### 9.7 Offline Behaviour

| Scenario | Behaviour |
|----------|-----------|
| Cache fresh (<60 min), no network | Show cache, no banner |
| Cache stale (≥60 min), no network | Show cache + stale banner: "Offline — last updated {relative time}" |
| Cache missing, no network | Show offline error state with retry button |
| Mid-session network loss | User continues swiping through already-loaded cards. `fetchMore()` fails gracefully — retry button appears at card 8 |
| Network restored | Pull-down or tap retry triggers `refresh()` — cache and UI updated |

### 9.8 Retry Behaviour

- All repository errors are caught and surfaced to `InsightsState.error`.
- `InsightsNotifier` exposes a `retry()` method that re-runs the last failed operation.
- Max automatic retry: 1 attempt with 3-second delay.
- After 1 failed auto-retry: error state presented to user with manual retry button.
- Exponential back-off is not applied in V1 (insufficient request frequency to justify complexity).

### 9.9 Error Classification

| Error Type | User Message | Action Available |
|-----------|-------------|-----------------|
| Network timeout | "Could not load insights. Check your connection." | Retry button |
| Supabase 4xx | "Something went wrong. Please try again." | Retry button |
| Supabase 5xx | "Our servers are having issues. Try again shortly." | Retry button |
| Empty active results | Renders empty state (not an error) | None — empty state UX |
| url_launcher failure | Silent (browser handles it) | None |

---

## 10. PERFORMANCE ARCHITECTURE

### 10.1 Zero Startup Impact

Catalyst Insights must not affect the cold launch time of the existing application.

**Guarantees:**
- `InsightsNotifier` is a lazy Riverpod provider. It is not instantiated until the Insights tab is first opened.
- No Supabase query for insights runs at app startup.
- No image prefetch occurs at startup.
- The Insights Supabase Storage bucket is not touched until the Insights tab is opened.

**Startup sequence (confirmed unchanged):**
```
App launch → SplashScreen → Auth check → MCFeedScreen (Home tab)
```
No Insights-related code executes in this path.

### 10.2 Memory Management

- `PageView` renders only the current card and its immediate neighbours (default Flutter `PageView` behaviour — `keepPage: false`).
- `RepaintBoundary` wraps each `_InsightCard` widget to isolate repaints.
- `CachedNetworkImage` manages its own disk and memory cache independently.
- Maximum in-memory insights: 20 (2 pages of 10). After page 3 is loaded, page 1 records may be evicted from the provider state list if `hasMore = false` on pages 3+. In V1 with few insights, this is a non-issue.

### 10.3 Network Efficiency

| Optimisation | Method |
|-------------|--------|
| Hero images | `CachedNetworkImage` — disk cached after first load |
| Insight text data | Cached in `SharedPreferences` — re-used across launches |
| Background prefetch | Triggered at card 8, not card 10 — ensures no loading state between cards |
| No Realtime subscription | Insights do not use WebSocket. Static content requires REST only. Eliminates a persistent connection. |
| Request size | SELECT of only display-ready fields. No `SELECT *`. Pipeline fields excluded. |

### 10.4 Battery Impact

- No background polling in V1. Refresh only occurs on foreground resume (60-minute interval) or explicit user action.
- No WebSocket connection for Insights.
- CachedNetworkImage uses system-managed HTTP cache, not a custom polling mechanism.
- Net additional battery impact: negligible.

### 10.5 Database Read Optimisation

The `(status, published_at)` composite index makes the Flutter query (status = 'active' ORDER BY published_at DESC LIMIT 10) a pure index scan. No table scan required. This remains efficient up to millions of rows.

---

## 11. SECURITY ARCHITECTURE

### 11.1 Row Level Security

**`insights_sources` RLS:**
- `SELECT`: authenticated users (Edge Functions need to validate domains)
- `INSERT / UPDATE`: `app_role = 'admin'`
- `DELETE`: Never (use `is_active = false`)

**`insights_raw` RLS:**
- `SELECT`: `app_role = 'admin'`
- `INSERT`: Service role only (Edge Functions)
- `UPDATE`: Service role only
- `DELETE`: Service role (cleanup job only)

**`catalyst_insights` RLS:**
- `SELECT`: authenticated users + `status = 'active'` filter
- `SELECT (admin)`: `app_role = 'admin'` + all statuses
- `INSERT / UPDATE`: `app_role = 'admin'`
- `DELETE`: Never

### 11.2 Source URL Verification

Every URL processed by the pipeline must:
1. Match an approved domain in `insights_sources`.
2. Be `https://` (not `http://`).
3. Resolve to HTTP 200 (verified by Edge Function, not Flutter).
4. Not be a redirect chain longer than 3 hops.

Flutter NEVER verifies URLs. URL safety validation is a backend-only concern.

### 11.3 Image URL Safety

`hero_image_url` values stored in `catalyst_insights` must always point to the Supabase Storage CDN domain (`{project-id}.supabase.co/storage/v1/object/public/insights-images/...`). The mirroring step guarantees this — the original source image URL is never persisted to `hero_image_url` after mirroring succeeds.

If mirroring fails and a category default is used, the URL points to the same Storage CDN. In neither case does Flutter ever load an image from an arbitrary external URL through `hero_image_url`.

### 11.4 Broken Link Handling

Source URLs (`source_url`) point to external article pages. These may become dead over time. Handling:
- Dead links are not detected automatically in V1 (low priority — dead links auto-archive within 30 days anyway).
- If the admin notices a dead link, they archive the insight manually.
- `url_launcher` silently fails to a browser error page if the link is dead — no app crash.
- V2: A scheduled Edge Function pings active `source_url` values weekly and flags dead links for admin attention.

### 11.5 Rate Limiting

The Catalyst Insights feature introduces these new outbound calls from the Edge Function layer:

| Operation | Frequency | Rate Limit Concern |
|-----------|-----------|-------------------|
| OG metadata fetch | Per submitted article | Low (manual submission in V1) |
| Anthropic Claude API | Per article (AI enrichment) | Budget: ~$0.001 per insight at claude-haiku-4-5-20251001 rates. 100 insights/month ≈ $0.10/month |
| Supabase Storage PUT | Per article (image mirror) | Low |

No rate limiting concern exists at V1 scale. V2 automated RSS polling introduces higher frequency — a 4-hour polling interval with deduplication ensures the pipeline processes only genuinely new articles.

### 11.6 AI Output Safety

AI-generated summaries are displayed to users. The following safeguards apply:

1. AI output is a structured JSON response (not free-form text). Fields have defined max lengths.
2. Admin reviews AI output before activation. Admin can edit any AI field.
3. The `ai_is_generated` flag ensures the UI always displays the "AI SUMMARY" transparency label.
4. AI is instructed via system prompt to: remain factual, not editorialize, cite no claims the source article does not make, avoid opinion, avoid political framing.
5. AI output is never displayed in V1 without at least one admin having reviewed and approved the insight.

---

## 12. SCALABILITY DESIGN

The architecture is designed to scale through three discrete growth phases without redesign.

### Scale Phase 1: Current (5–20 insights/day, 50–200 users)

| Component | Behaviour at this scale |
|-----------|------------------------|
| `catalyst_insights` rows | < 1,000 active rows. Trivial for PostgreSQL. |
| Flutter pagination | 10-item pages; rarely reach page 2. |
| AI calls | < 20/day. Negligible cost and rate limit pressure. |
| Image storage | < 100MB. Within Supabase free Storage limits. |
| Edge Function invocations | < 50/day. Zero concern. |

**No scaling actions required.**

### Scale Phase 2: Growth (50–100 insights/day, 500–5,000 users)

| Component | Action Required |
|-----------|----------------|
| `catalyst_insights` | Composite index already defined. No migration needed. |
| Flutter pagination | Cursor-based pagination replaces OFFSET (no breaking change — repository update only). |
| AI processing | Parallel processing (batch multiple insights per Edge Function call). |
| Image storage | Supabase Storage scales automatically. CDN handles delivery. |
| RSS polling | 4-hour cron with per-source deduplication. Ingestion queue handles bursts. |

### Scale Phase 3: Enterprise (100+ insights/day, 10,000+ users)

| Component | Action Required |
|-----------|----------------|
| Database | Supabase read replicas. Flutter routes SELECT queries to replica endpoint. |
| AI processing | Dedicated Supabase Edge Function for AI enrichment with queue (Postgres LISTEN/NOTIFY or external queue). |
| Image pipeline | Image transformation layer (Supabase Image Transformations or Cloudflare Images). |
| CDN | Enable aggressive CDN caching headers on `insights-images` bucket (cache-control: max-age=86400). |
| API layer | Consider a dedicated Supabase Edge Function `GET /insights` replacing direct PostgREST access for cache control and response shaping. |

**No architectural redesign is required for any of these three phases.** Each is an incremental capacity expansion on the same design.

---

## 13. FUTURE FEATURE ENABLEMENT

The following V2/V3 features are explicitly out of scope for Phase 1 implementation but are designed-in at the architecture level. None require schema redesign if the Phase 2 data model is implemented as specified.

### Bookmarks

**Enabled by:** `insights_bookmarks` table (defined in §5).  
**Flutter addition:** `InsightsRepository.bookmark(insightId)` / `unbookmark(insightId)`. Bookmarks screen reads from `insights_bookmarks` joined with `catalyst_insights`.  
**No schema changes required if Phase 2 model implemented.**

### Weekly Digest (Email / Push)

**Enabled by:** `catalyst_insights` ordered by `published_at DESC` + `profiles.notification_preferences`.  
**Implementation:** Scheduled Edge Function (`send_weekly_digest`) runs every Monday 08:00. Reads top 5 insights from past week. Sends via email service (already integrated) and/or push notification.  
**No schema changes required.**

### Personalized Feed

**Enabled by:** `insights_bookmarks`, `insights_read_state`, user `interest_tags` in `profiles`.  
**Implementation:** A scoring query weights `category` against user's `interest_tags` and weights down already-read insights.  
**No schema changes required.**

### AI Chat on Insight (Ask Follow-up Questions)

**Enabled by:** `insight_id` as context for an Anthropic API call.  
**Implementation:** "Ask AI" button on a card opens a chat sheet. The insight's headline + summary + why_matters are injected as context. Response is ephemeral (not stored).  
**New table required:** `insights_chat_sessions` (V3) — but not needed for the base architecture.

### Recommendations ("You Might Also Like")

**Enabled by:** `ai_tags` array on `catalyst_insights`.  
**Implementation:** At end-of-batch card, query `catalyst_insights` where `ai_tags && {current_insight.ai_tags}` AND `id != {current_insight.id}` ORDER BY published_at DESC LIMIT 3.  
**No schema changes required.**

### Internal Discussions on Insights

**Enabled by:** A `discussions` table linking `catalyst_insights.id` to comments (similar to existing `comments` on `posts`).  
**Implementation:** Requires a new `insight_discussions` table. The insight card gains a "Discuss" button.  
**One new table required — no existing tables modified.**

### Saved Articles (Offline Reading)

**Enabled by:** `insights_bookmarks` + local Flutter persistence.  
**Implementation:** Bookmarked insight data is saved to device storage (Hive/ObjectBox). "Saved" tab in Insights screen shows offline-readable cards.  
**No backend schema changes required.**

### AI-Assisted Admin Publishing

**Enabled by:** Existing AI pipeline + admin UI additions.  
**Implementation:** Admin pastes a URL into the admin dashboard. The `collect_insight` + `enrich_insight` pipeline runs and pre-populates all fields. Admin reviews + approves in seconds.  
**No schema changes required — this is the intended flow, just with admin UI integration.**

---

## 14. EDGE FUNCTION REGISTRY

A complete catalogue of new Edge Functions introduced by Catalyst Insights. None modify existing Edge Functions.

| Function Name | Trigger | Purpose |
|--------------|---------|---------|
| `collect_insight` | Admin HTTP POST or RSS poller | Fetches OG metadata, writes to `insights_raw` |
| `validate_insight` | DB webhook on `insights_raw` INSERT | Quality + source validation |
| `dedup_insight` | Called within `validate_insight` | Duplicate detection |
| `enrich_insight` | Called after validation passes | AI processing + image mirror |
| `mirror_insight_image` | Called within `enrich_insight` | OG image → Supabase Storage |
| `activate_scheduled_insights` | Cron: every 15 minutes | Activates `status=scheduled` rows past their `scheduled_at` |
| `expire_old_insights` | Cron: daily at 02:00 UTC | Archives insights older than 30 days |
| `poll_rss_feeds` (V2) | Cron: every 4 hours | Polls RSS feeds of active Tier 1–3 sources |
| `send_weekly_digest` (V2) | Cron: Monday 08:00 UTC | Email/push weekly summary |

**No existing Edge Functions are modified.**

---

## 15. STORAGE BUCKET SPECIFICATION

One new Supabase Storage bucket: `insights-images`.

| Property | Value |
|----------|-------|
| Bucket name | `insights-images` |
| Access | Public (CDN-delivered, no auth required for reads) |
| Folder structure | `insights/{insight_id}/hero.webp` |
| Default images | `defaults/{category_code}.webp` (6 files) |
| Max file size | 5MB (enforced by bucket policy) |
| Allowed MIME types | image/webp, image/jpeg, image/png |
| Write access | Service role only (Edge Functions) |
| Delete policy | Never delete (insight images are immutable after upload) |

**No existing buckets are modified.**

---

## 16. FINAL VALIDATION

Before this document was marked complete, every recommendation was verified against all 8 required principles:

| Principle | Verification |
|-----------|-------------|
| 1. Existing application remains untouched | ✓ No existing table, function, screen, provider, or repository modified |
| 2. Catalyst Insights is fully isolated | ✓ All new entities in `insights_*` namespace. New Flutter module in `features/insights/`. New Storage bucket `insights-images`. |
| 3. Architecture is scalable | ✓ Three-phase scalability roadmap defined. Each phase is incremental. No redesign required at any phase. |
| 4. Performance is preserved | ✓ Lazy provider initialization. Zero startup impact. CachedNetworkImage. No Realtime subscription. RepaintBoundary per card. |
| 5. Trusted sources remain controlled | ✓ Domain whitelist enforced at DB level (`insights_sources`). Admin-only modifications. Tier system with differentiated validation rules. |
| 6. Flutter never scrapes websites | ✓ All metadata fetching performed by Supabase Edge Functions. Flutter only reads structured data from `catalyst_insights` via PostgREST. |
| 7. AI is used only as an enrichment layer | ✓ AI generates suggestions only. Admin reviews and approves all AI output before activation. `ai_is_generated` flag ensures UI transparency. Admin retains full edit authority over every AI field. |
| 8. The platform remains maintainable | ✓ Follows existing repository pattern, Riverpod convention, feature module structure, Edge Function architecture, and RLS policy patterns. No new architectural patterns introduced. |

---

## 🟢 PHASE 2 COMPLETE — CONTENT ARCHITECTURE LOCKED

**All Phase 2 conditions satisfied:**

✓ Content pipeline fully specified (10 stages, Stage 1–10)  
✓ Trusted source hierarchy defined (Tier 1, 2, 3 with named sources)  
✓ Source expansion policy defined  
✓ AI processing platform designed (model, prompt schema, routing, transparency)  
✓ Duplicate detection designed (3 levels)  
✓ Data model defined (5 entities, retention policy, RLS, indexes)  
✓ Freshness policy defined (F1–F5 tiers)  
✓ Media policy defined (mirror strategy, fallback hierarchy, licensing rationale)  
✓ Content quality policy defined (validation rules, keyword dictionary, clickbait detection)  
✓ Flutter integration architecture defined (module structure, DTO, repository, notifier, cache, pagination, offline, retry, error handling)  
✓ Performance architecture defined (zero startup impact, memory, network, battery, database)  
✓ Security architecture defined (RLS, URL verification, image safety, broken links, AI safety)  
✓ Three-phase scalability roadmap defined  
✓ Future features enabled without schema redesign  
✓ Edge Function registry defined (8 functions, 0 existing functions modified)  
✓ Storage bucket specification defined (1 new bucket, 0 existing buckets modified)  
✓ Existing application baseline confirmed unaffected  

**Implementation (Phase 3) may begin when this document has been reviewed and approved.**
