// collect-insight — Use case
// Implements the Collect stage of the Catalyst Insights content pipeline.
//
// Responsibilities (scope-locked per S2-BE-002):
//   ✅ Request validation
//   ✅ URL normalization
//   ✅ URL fingerprint (SHA-256 of normalized URL)
//   ✅ Source lookup (active check only — domain validation is validate_insight's job)
//   ✅ Duplicate detection via url_fingerprint
//   ✅ insights_raw record creation (status='pending')
//   ✅ Structured logging + Result<T,E> pattern
//
//   ❌ Fetch webpage content
//   ❌ Domain / sub-path validation
//   ❌ OG metadata extraction
//   ❌ AI enrichment
//   ❌ catalyst_insights modification

import type { SupabaseClient } from '../_shared/insights/database.ts';
import type {
  CollectInsightPayload,
  CollectInsightResult,
} from '../_shared/insights/types.ts';
import { PipelineError, isPipelineError } from '../_shared/insights/errors.ts';
import { logger } from '../_shared/insights/logger.ts';
import { ok, err, type Result } from '../_shared/insights/result.ts';

const FN = 'collect_insight';

// ─── Tracking params stripped during URL normalization ────────────────────────
const TRACKING_PARAMS = new Set([
  'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
  'utm_id', 'fbclid', 'gclid', 'msclkid', 'mc_eid', '_hsenc', '_hsmi',
  'ref', 'source',
]);

// ─── URL normalization ────────────────────────────────────────────────────────
// Goal: produce a canonical URL so that the same article submitted via different
// tracking links produces the same fingerprint.
function normalizeUrl(rawUrl: string): string {
  const url = new URL(rawUrl.trim());

  // Scheme and host are always lowercase
  url.protocol = url.protocol.toLowerCase();
  url.hostname = url.hostname.toLowerCase();

  // Strip tracking / session query params
  for (const key of [...url.searchParams.keys()]) {
    if (TRACKING_PARAMS.has(key.toLowerCase())) {
      url.searchParams.delete(key);
    }
  }

  // Remove trailing slash from non-root paths (weforum.org/article/ → weforum.org/article)
  if (url.pathname !== '/' && url.pathname.endsWith('/')) {
    url.pathname = url.pathname.slice(0, -1);
  }

  // Fragment is not part of resource identity
  url.hash = '';

  return url.toString();
}

// ─── URL fingerprint (SHA-256 of normalized URL, hex-encoded) ────────────────
async function fingerprintUrl(normalizedUrl: string): Promise<string> {
  const buf = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(normalizedUrl),
  );
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

// ─── Request validation ───────────────────────────────────────────────────────
function validatePayload(body: unknown): asserts body is CollectInsightPayload {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new PipelineError('VALIDATION_FAILED', 'Request body must be a JSON object');
  }
  const b = body as Record<string, unknown>;

  if (typeof b.url !== 'string' || !b.url.trim()) {
    throw new PipelineError('VALIDATION_FAILED', 'url is required');
  }
  if (typeof b.source_id !== 'string' || !b.source_id.trim()) {
    throw new PipelineError('VALIDATION_FAILED', 'source_id is required');
  }

  // Validate URL format (scheme check only — domain validation is validate_insight's job)
  try {
    const parsed = new URL(b.url);
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
      throw new PipelineError('VALIDATION_FAILED', `URL must use http or https: ${b.url}`);
    }
  } catch (e) {
    if (isPipelineError(e)) throw e;
    throw new PipelineError('VALIDATION_FAILED', `Invalid URL: ${b.url}`);
  }
}

// ─── Source lookup ────────────────────────────────────────────────────────────
// Confirms the source exists and is active. Does NOT validate that the URL
// matches the source's approved_domain — that check is in validate_insight.
async function lookupSource(
  db: SupabaseClient,
  sourceId: string,
): Promise<Result<{ name: string }, PipelineError>> {
  const { data, error } = await db
    .from('insights_sources')
    .select('name, is_active')
    .eq('id', sourceId)
    .single();

  if (error || !data) {
    return err(new PipelineError('SOURCE_NOT_FOUND', `Source not found: ${sourceId}`));
  }
  if (!data.is_active) {
    return err(new PipelineError('SOURCE_NOT_FOUND', `Source is inactive: ${sourceId}`));
  }
  return ok({ name: data.name as string });
}

// ─── Duplicate detection ──────────────────────────────────────────────────────
// Checks insights_raw for an existing record with the same url_fingerprint.
// Returns the existing id if found, null if new.
async function findDuplicate(
  db: SupabaseClient,
  urlFingerprint: string,
): Promise<string | null> {
  const { data } = await db
    .from('insights_raw')
    .select('id')
    .eq('url_fingerprint', urlFingerprint)
    .maybeSingle();
  return (data as { id: string } | null)?.id ?? null;
}

// ─── Use case entry point ─────────────────────────────────────────────────────
export async function handleCollectInsight(
  body: unknown,
  db: SupabaseClient,
): Promise<CollectInsightResult> {

  // 1. Validate request
  validatePayload(body);
  const { url, source_id, submitted_by } = body;

  logger.info('Collecting insight', { fn: FN, url, source_id });

  // 2. Normalize URL
  let normalizedUrl: string;
  try {
    normalizedUrl = normalizeUrl(url);
  } catch (e) {
    if (isPipelineError(e)) throw e;
    throw new PipelineError('VALIDATION_FAILED', `URL cannot be normalized: ${url}`);
  }

  // 3. Generate fingerprint
  const urlFingerprint = await fingerprintUrl(normalizedUrl);
  logger.debug('URL fingerprinted', { fn: FN, url_fingerprint: urlFingerprint });

  // 4. Source lookup
  const sourceResult = await lookupSource(db, source_id);
  if (!sourceResult.ok) {
    logger.warn('Source lookup failed', {
      fn: FN,
      source_id,
      code: sourceResult.error.code,
    });
    throw sourceResult.error;
  }

  // 5. Duplicate detection
  const existingId = await findDuplicate(db, urlFingerprint);
  if (existingId) {
    logger.info('Duplicate URL detected — skipping insert', {
      fn: FN,
      url_fingerprint: urlFingerprint,
      existing_raw_id: existingId,
    });
    return {
      raw_id: existingId,
      status: 'duplicate',
      message: 'URL already exists in the Catalyst Insights pipeline',
    };
  }

  // 6. Create insights_raw record (status='pending')
  const { data: inserted, error: insertError } = await db
    .from('insights_raw')
    .insert({
      source_id,
      raw_url: normalizedUrl,
      url_fingerprint: urlFingerprint,
      submitted_by: submitted_by ?? null,
      status: 'pending',
    })
    .select('id')
    .single();

  if (insertError || !inserted) {
    throw new PipelineError(
      'DB_ERROR',
      `Failed to create insights_raw record: ${insertError?.message ?? 'unknown'}`,
    );
  }

  const rawId = (inserted as { id: string }).id;
  logger.info('insights_raw record created', {
    fn: FN,
    raw_id: rawId,
    url_fingerprint: urlFingerprint,
    source: sourceResult.value.name,
  });

  return {
    raw_id: rawId,
    status: 'pending',
    message: 'Insight queued for validation',
  };
}
