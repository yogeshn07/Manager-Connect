// enrich-insight — Use case
// Implements the Enrich stage of the Catalyst Insights content pipeline.
//
// Scope-locked per S3-BE-001:
//   ✅ Fetch validated insights_raw record (with embedded source JOIN)
//   ✅ Idempotency guard (if already ai_processed: return existing insight)
//   ✅ Open Graph metadata extraction (fetchWithTimeout + extractOgFromHtml)
//   ✅ IEEE abstract retrieval via IEEE Xplore API (spectrum.ieee.org, pes.ieee.org)
//   ✅ AI prompt construction (system + contextualized user prompt)
//   ✅ AI client invocation (OpenAI gpt-4o-mini, json_object response_format)
//   ✅ AI response validation (all 8 fields, types, ranges, enum membership)
//   ✅ Confidence scoring (0.0–1.0, validated against range)
//   ✅ Category assignment (one of 6 InsightCategory values)
//   ✅ OG fields written back to insights_raw (og_title, og_description, og_image_url)
//   ✅ catalyst_insights INSERT (all AI + metadata fields)
//   ✅ insights_raw.status → 'ai_processed' (conditional WHERE status='validated')
//   ✅ Structured logging at every stage
//   ✅ Retryable PipelineError on fetch/AI failures
//   ✅ Result<T,E> pattern for nullable lookups
//
//   ❌ Does NOT activate/schedule insights
//   ❌ Does NOT expire insights
//   ❌ Does NOT modify collect_insight or validate_insight
//   ❌ Does NOT implement admin approval flow
//   ❌ Does NOT call send-notification

import type { SupabaseClient } from '../_shared/insights/database.ts';
import type { InsightsPipelineConfig } from '../_shared/insights/config.ts';
import type {
  EnrichInsightPayload,
  EnrichInsightResult,
  InsightCategory,
  InsightStatus,
  AiEnrichmentResult,
  OgMetadata,
} from '../_shared/insights/types.ts';
import { PipelineError } from '../_shared/insights/errors.ts';
import { logger } from '../_shared/insights/logger.ts';
import { ok, err, type Result } from '../_shared/insights/result.ts';
import { INSIGHT_CATEGORIES, AI_TIMEOUT_MS, OG_FETCH_TIMEOUT_MS, HTTP_TIMEOUT_MS } from '../_shared/insights/constants.ts';
import { fetchWithTimeout, extractOgFromHtml } from '../_shared/insights/http.ts';
import { mirrorHeroImage } from '../_shared/insights/image.ts';
import { callAi } from '../_shared/insights/ai-client.ts';
import { buildPrompts } from '../_shared/insights/prompt-builder.ts';

const FN = 'enrich_insight';

// ─── External service constants ───────────────────────────────────────────────
// OpenAI config is owned by _shared/insights/ai-client.ts (S3-BE-003).

// IEEE Xplore API — queried for IEEE-domain sources when IEEE_XPLORE_API_KEY is set.
// Optional: gracefully degrades to OG metadata if key is absent or call fails.
const IEEE_XPLORE_URL = 'https://ieeexploreapi.ieee.org/api/v1/search/articles';
// Source approved_domains that trigger IEEE Xplore abstract retrieval.
const IEEE_DOMAINS    = new Set(['spectrum.ieee.org', 'pes.ieee.org']);

// ─── Private types ────────────────────────────────────────────────────────────

// Shape returned by the PostgREST embedded join:
//   insights_raw + insights_sources!source_id(name, tier, approved_domain)
interface RawWithSource {
  id:             string;
  source_id:      string;
  raw_url:        string;
  url_fingerprint: string;
  status:         string;
  og_title:       string | null;
  og_description: string | null;
  og_image_url:   string | null;
  insights_sources: {
    name:            string;
    tier:            number;
    approved_domain: string;
  } | null;
}

interface ExistingInsight {
  id:            string;
  status:        string;
  ai_confidence: number | null;
}

// ─── 1. Request validation ────────────────────────────────────────────────────

function validatePayload(body: unknown): asserts body is EnrichInsightPayload {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new PipelineError('VALIDATION_FAILED', 'Request body must be a JSON object');
  }
  const b = body as Record<string, unknown>;
  if (typeof b.raw_id !== 'string' || !b.raw_id.trim()) {
    throw new PipelineError('VALIDATION_FAILED', 'raw_id is required');
  }
}

// ─── 2. DB: fetch raw record with embedded source ─────────────────────────────

async function fetchRawWithSource(
  db: SupabaseClient,
  rawId: string,
): Promise<RawWithSource> {
  const { data, error } = await db
    .from('insights_raw')
    .select(`
      id,
      source_id,
      raw_url,
      url_fingerprint,
      status,
      og_title,
      og_description,
      og_image_url,
      insights_sources!source_id (
        name,
        tier,
        approved_domain
      )
    `)
    .eq('id', rawId)
    .single();

  if (error || !data) {
    throw new PipelineError('DB_ERROR', `insights_raw record not found: ${rawId}`);
  }
  return data as unknown as RawWithSource;
}

// ─── 3. DB: idempotency — find existing catalyst_insight by raw_id ────────────

async function findExistingInsight(
  db: SupabaseClient,
  rawId: string,
): Promise<Result<ExistingInsight, null>> {
  const { data } = await db
    .from('catalyst_insights')
    .select('id, status, ai_confidence')
    .eq('raw_id', rawId)
    .maybeSingle();

  return data ? ok(data as ExistingInsight) : err(null);
}

// ─── 4. DB: mark ai_error (conditional — only if still 'validated') ───────────

async function markAiError(db: SupabaseClient, rawId: string): Promise<void> {
  await db
    .from('insights_raw')
    .update({ status: 'ai_error' })
    .eq('id', rawId)
    .eq('status', 'validated'); // guard: no-op if already transitioned
}

// ─── 5. HTTP: fetch article page and extract OG metadata ──────────────────────

async function fetchArticleOg(rawUrl: string): Promise<OgMetadata> {
  const response = await fetchWithTimeout(
    rawUrl,
    { headers: { 'User-Agent': 'CatalystInsights/1.0 (content-pipeline)' } },
    OG_FETCH_TIMEOUT_MS,
  );

  if (!response.ok) {
    throw new PipelineError(
      'FETCH_FAILED',
      `Article fetch returned HTTP ${response.status}: ${rawUrl}`,
      true, // retryable
    );
  }

  // Non-HTML responses (PDFs, feeds) — return empty metadata; AI uses URL + source context
  const contentType = response.headers.get('content-type') ?? '';
  if (!contentType.includes('text/html')) {
    logger.info('Non-HTML content type — skipping OG extraction', { fn: FN, url: rawUrl, contentType });
    return { title: null, description: null, image_url: null, article_date: null };
  }

  const html = await response.text();
  return extractOgFromHtml(html);
}

// ─── 6. HTTP: optional IEEE Xplore abstract retrieval ─────────────────────────
// Queries IEEE Xplore by article title for an authoritative technical abstract.
// Non-fatal: returns null on any failure so the AI falls back to OG description.

function isIeeeDomain(approvedDomain: string): boolean {
  // approvedDomain may be bare host ('spectrum.ieee.org') or host+path
  const host = approvedDomain.split('/')[0];
  return IEEE_DOMAINS.has(host);
}

async function tryFetchIeeeAbstract(
  title: string | null,
  ieeeApiKey: string,
): Promise<string | null> {
  if (!title?.trim()) return null;

  try {
    const url = new URL(IEEE_XPLORE_URL);
    url.searchParams.set('querytext', `"${title.trim()}"`);
    url.searchParams.set('max_records', '1');
    url.searchParams.set('apikey', ieeeApiKey);

    const response = await fetchWithTimeout(url.toString(), {}, HTTP_TIMEOUT_MS);
    if (!response.ok) return null;

    const payload = await response.json() as {
      articles?: Array<{ abstract?: string }>;
    };

    return payload?.articles?.[0]?.abstract ?? null;
  } catch {
    // Log non-fatally — IEEE Xplore is an optional enrichment signal
    logger.warn('IEEE Xplore lookup failed (non-fatal, continuing without abstract)', { fn: FN });
    return null;
  }
}

// ─── 10. AI: validate response and return typed AiEnrichmentResult ────────────
// Sections 7 and 8 (buildSystemPrompt / buildUserPrompt) extracted to
// _shared/insights/prompt-builder.ts (S3-BE-004).

function parseAndValidateAiResponse(raw: unknown): AiEnrichmentResult {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new PipelineError('AI_ENRICHMENT_FAILED', 'AI response is not a JSON object');
  }
  const d = raw as Record<string, unknown>;

  // Validate required string fields
  for (const field of ['ai_headline', 'ai_summary', 'ai_why_matters', 'ai_key_takeaway'] as const) {
    if (typeof d[field] !== 'string' || !(d[field] as string).trim()) {
      throw new PipelineError('AI_ENRICHMENT_FAILED', `AI response missing or empty: ${field}`);
    }
  }

  // Validate ai_tags: array of 1–10 non-empty strings
  if (!Array.isArray(d.ai_tags) || d.ai_tags.length < 1 || d.ai_tags.length > 10) {
    throw new PipelineError('AI_ENRICHMENT_FAILED', 'ai_tags must be an array with 1–10 items');
  }
  if (!(d.ai_tags as unknown[]).every((t) => typeof t === 'string' && (t as string).trim())) {
    throw new PipelineError('AI_ENRICHMENT_FAILED', 'ai_tags must contain only non-empty strings');
  }

  // Validate ai_confidence: float in [0, 1]
  const confidence = Number(d.ai_confidence);
  if (isNaN(confidence) || confidence < 0 || confidence > 1) {
    throw new PipelineError(
      'AI_ENRICHMENT_FAILED',
      `ai_confidence out of range [0, 1]: ${String(d.ai_confidence)}`,
    );
  }

  // Validate category: must be one of the 6 InsightCategory values
  if (!(INSIGHT_CATEGORIES as readonly string[]).includes(d.category as string)) {
    throw new PipelineError(
      'AI_ENRICHMENT_FAILED',
      `Invalid category '${String(d.category)}'. Must be one of: ${INSIGHT_CATEGORIES.join(', ')}`,
    );
  }

  // Validate reading_time_minutes: integer in [1, 20]
  const readingTime = Math.round(Number(d.reading_time_minutes));
  if (isNaN(readingTime) || readingTime < 1 || readingTime > 20) {
    throw new PipelineError(
      'AI_ENRICHMENT_FAILED',
      `reading_time_minutes out of range [1, 20]: ${String(d.reading_time_minutes)}`,
    );
  }

  return {
    ai_headline:          (d.ai_headline as string).trim(),
    ai_summary:           (d.ai_summary  as string).trim(),
    ai_why_matters:       (d.ai_why_matters  as string).trim(),
    ai_key_takeaway:      (d.ai_key_takeaway as string).trim(),
    ai_tags:              (d.ai_tags as string[]).map((t) => t.toLowerCase().trim()),
    ai_confidence:        confidence,
    category:             d.category as InsightCategory,
    reading_time_minutes: readingTime,
  };
}

// ─── 11. DB: write OG metadata + transition insights_raw to ai_processed ──────

async function updateRawRecord(
  db: SupabaseClient,
  rawId: string,
  ogMeta: OgMetadata,
): Promise<void> {
  // Conditional: only updates if still in 'validated' — guards concurrent calls.
  // The updated_at trigger fires automatically (set_insights_raw_updated_at).
  const { error } = await db
    .from('insights_raw')
    .update({
      og_title:       ogMeta.title,
      og_description: ogMeta.description,
      og_image_url:   ogMeta.image_url,
      status:         'ai_processed',
    })
    .eq('id', rawId)
    .eq('status', 'validated');

  if (error) {
    throw new PipelineError('DB_ERROR', `Failed to update insights_raw: ${error.message}`);
  }
}

// ─── 12. DB: insert catalyst_insights ─────────────────────────────────────────
// Returns the new insight's id.
// ON CONFLICT (url_fingerprint): a concurrent enrichment call already inserted this
// row — look up and return the existing record rather than failing.

async function insertCatalystInsight(
  db: SupabaseClient,
  raw: RawWithSource,
  source: NonNullable<RawWithSource['insights_sources']>,
  ogMeta: OgMetadata,
  aiResult: AiEnrichmentResult,
  heroImageUrl: string | null,
): Promise<string> {
  const { data: inserted, error: insertError } = await db
    .from('catalyst_insights')
    .insert({
      raw_id:               raw.id,
      source_id:            raw.source_id,
      url_fingerprint:      raw.url_fingerprint,
      ai_headline:          aiResult.ai_headline,
      ai_summary:           aiResult.ai_summary,
      ai_why_matters:       aiResult.ai_why_matters,
      ai_key_takeaway:      aiResult.ai_key_takeaway,
      ai_tags:              aiResult.ai_tags,
      ai_confidence:        aiResult.ai_confidence,
      source_name:          source.name,
      source_url:           raw.raw_url,
      article_date:         ogMeta.article_date ?? null,
      reading_time_minutes: aiResult.reading_time_minutes,
      hero_image_url:       heroImageUrl,
      category:             aiResult.category,
      is_ai_generated:      true,
      // status defaults to 'review' (M03 column default)
      // is_evergreen defaults to false (MF-04 default)
      // reviewed_by / reviewed_at: null — set by admin approval flow
    })
    .select('id')
    .single();

  if (!insertError && inserted) {
    return (inserted as { id: string }).id;
  }

  // PostgreSQL UNIQUE violation on url_fingerprint (error code 23505):
  // a concurrent invocation already completed enrichment for this URL.
  if (insertError?.code === '23505') {
    logger.info('UNIQUE conflict on url_fingerprint — concurrent enrichment already completed', {
      fn:              FN,
      raw_id:          raw.id,
      url_fingerprint: raw.url_fingerprint,
    });
    const { data: existing } = await db
      .from('catalyst_insights')
      .select('id')
      .eq('url_fingerprint', raw.url_fingerprint)
      .single();
    if (existing) return (existing as { id: string }).id;
  }

  throw new PipelineError(
    'DB_ERROR',
    `Failed to insert catalyst_insights: ${insertError?.message ?? 'unknown error'}`,
  );
}

// ─── Use case entry point ─────────────────────────────────────────────────────

export async function handleEnrichInsight(
  body: unknown,
  db: SupabaseClient,
  config: InsightsPipelineConfig,
): Promise<EnrichInsightResult> {

  // 1. Validate request
  validatePayload(body);
  const { raw_id: rawId } = body;

  logger.info('Starting enrichment', { fn: FN, raw_id: rawId });

  // 2. Fetch record + embedded source
  const raw = await fetchRawWithSource(db, rawId);
  if (!raw.insights_sources) {
    throw new PipelineError('DB_ERROR', `No source found for raw_id ${rawId} — FK integrity issue`);
  }
  const source = raw.insights_sources;

  // 3. Idempotency: if already enriched, return existing insight
  if (raw.status === 'ai_processed') {
    logger.info('Already ai_processed — returning existing insight (idempotent)', {
      fn: FN, raw_id: rawId,
    });
    const existingResult = await findExistingInsight(db, rawId);
    if (existingResult.ok) {
      const e = existingResult.value;
      return {
        insight_id:    e.id,
        status:        e.status as InsightStatus,
        ai_confidence: e.ai_confidence ?? 0,
      };
    }
    throw new PipelineError('DB_ERROR', `insights_raw is 'ai_processed' but no catalyst_insights found for raw_id ${rawId}`);
  }

  // 4. Guard: only process 'validated' records
  if (raw.status !== 'validated') {
    throw new PipelineError(
      'VALIDATION_FAILED',
      `Cannot enrich record with status '${raw.status}' — must be 'validated'`,
    );
  }

  // 5. Fetch article OG metadata
  let ogMeta: OgMetadata;
  try {
    ogMeta = await fetchArticleOg(raw.raw_url);
    logger.info('OG metadata extracted', {
      fn:     FN,
      raw_id: rawId,
      has_title:       ogMeta.title !== null,
      has_description: ogMeta.description !== null,
      has_image:       ogMeta.image_url !== null,
    });
  } catch (e) {
    await markAiError(db, rawId);
    throw e; // re-throw (already a PipelineError)
  }

  // 6. Optional IEEE Xplore abstract retrieval (spectrum.ieee.org, pes.ieee.org)
  let ieeeAbstract: string | null = null;
  const ieeeApiKey = Deno.env.get('IEEE_XPLORE_API_KEY');
  if (isIeeeDomain(source.approved_domain) && ieeeApiKey) {
    logger.info('Querying IEEE Xplore for abstract', { fn: FN, raw_id: rawId, domain: source.approved_domain });
    ieeeAbstract = await tryFetchIeeeAbstract(ogMeta.title, ieeeApiKey);
    if (ieeeAbstract) {
      logger.info('IEEE abstract retrieved', { fn: FN, raw_id: rawId, abstract_length: ieeeAbstract.length });
    }
  }

  // 7–8. Build prompts via prompt-builder.ts and invoke AI client
  const promptPair = buildPrompts({
    raw_url:       raw.raw_url,
    source_name:   source.name,
    source_tier:   source.tier,
    og:            ogMeta,
    ieee_abstract: ieeeAbstract,
  });
  logger.info('Prompts assembled', {
    fn: FN, raw_id: rawId, prompt_version: promptPair.version,
  });

  let aiResult: AiEnrichmentResult;
  try {
    logger.info('Invoking AI client', { fn: FN, raw_id: rawId });
    const aiResponse = await callAi(
      {
        messages: [
          { role: 'system', content: promptPair.system },
          { role: 'user',   content: promptPair.user   },
        ],
        temperature: 0.3,
        max_tokens:  1200,
      },
      config.openAiApiKey,
      AI_TIMEOUT_MS,
    );
    aiResult = parseAndValidateAiResponse(JSON.parse(aiResponse.content));
    logger.info('AI enrichment succeeded', {
      fn:            FN,
      raw_id:        rawId,
      category:      aiResult.category,
      ai_confidence: aiResult.ai_confidence,
      tag_count:     aiResult.ai_tags.length,
      tokens_used:   aiResponse.usage?.total_tokens ?? null,
    });
  } catch (e) {
    await markAiError(db, rawId);
    throw e; // re-throw (PipelineError from callAi)
  }

  // 9. Persist: update insights_raw OG fields + transition to 'ai_processed'
  await updateRawRecord(db, rawId, ogMeta);

  // 10. Mirror hero image to Supabase Storage CDN (never throws — falls back to category default)
  const mirrorResult = await mirrorHeroImage(db, ogMeta.image_url, raw.url_fingerprint, aiResult.category);
  logger.info('Hero image mirror completed', {
    fn: FN, raw_id: rawId, source: mirrorResult.source,
  });

  // 11. Persist: insert catalyst_insights row (status='review' by default)
  const insightId = await insertCatalystInsight(db, raw, source, ogMeta, aiResult, mirrorResult.hero_image_url);

  logger.info('Enrichment complete — catalyst_insights created', {
    fn:            FN,
    raw_id:        rawId,
    insight_id:    insightId,
    ai_confidence: aiResult.ai_confidence,
    category:      aiResult.category,
  });

  return {
    insight_id:    insightId,
    status:        'review',
    ai_confidence: aiResult.ai_confidence,
  };
}
