// Catalyst Insights Pipeline — mirror_image service (S3-BE-002)
// Downloads the article hero image, validates it (MIME type, file size),
// converts to WebP, and uploads to Supabase Storage.
// Falls back to a per-category default image on any failure.
//
// Never throws — all error paths return { source: 'fallback' }.
// Caller: enrich_insight (use-case.ts step 10)

import { Image } from 'https://esm.sh/imagescript@1.2.15';
import type { SupabaseClient } from './database.ts';
import type { InsightCategory } from './types.ts';
import { PipelineError } from './errors.ts';
import { logger } from './logger.ts';
import { fetchWithTimeout } from './http.ts';
import { HTTP_TIMEOUT_MS } from './constants.ts';

const FN = 'mirror_hero_image';

// ─── Storage config ───────────────────────────────────────────────────────────

const INSIGHTS_BUCKET    = 'insights';
const HERO_PREFIX        = 'hero';
const DEFAULTS_PREFIX    = 'defaults';
const MAX_SOURCE_BYTES   = 5 * 1024 * 1024;  // 5 MB hard limit
const WEBP_QUALITY       = 85;                // 0–100; 85 balances size vs. quality
const WEBP_MAX_DIMENSION = 1200;              // px — standard OG hero size

// ─── MIME validation ──────────────────────────────────────────────────────────

const ACCEPTED_MIME_TYPES = new Set<string>([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
]);

// Validates image format via magic byte signatures, independent of Content-Type.
function detectMimeFromBytes(bytes: Uint8Array): string | null {
  if (bytes.length < 12) return null;
  // JPEG: FF D8 FF
  if (bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF) return 'image/jpeg';
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E && bytes[3] === 0x47) return 'image/png';
  // WebP: RIFF????WEBP
  if (
    bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x46 &&
    bytes[8] === 0x57 && bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50
  ) return 'image/webp';
  // GIF87a / GIF89a
  if (bytes[0] === 0x47 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x38) return 'image/gif';
  return null;
}

// ─── Category defaults ────────────────────────────────────────────────────────
// Seeded in Supabase Storage at `insights/defaults/` during deployment.

const CATEGORY_DEFAULTS: Record<InsightCategory, string> = {
  grid_technology:         'grid_technology.webp',
  energy_transition:       'energy_transition.webp',
  industry_standards:      'industry_standards.webp',
  engineering_leadership:  'engineering_leadership.webp',
  policy_markets:          'policy_markets.webp',
  innovation:              'innovation.webp',
};

// ─── Public result type ───────────────────────────────────────────────────────

export interface MirrorImageResult {
  hero_image_url: string;           // Supabase Storage public CDN URL
  source:         'mirrored' | 'fallback';
}

// ─── Private helpers ──────────────────────────────────────────────────────────

function mimeToExt(mimeType: string): string {
  const map: Record<string, string> = {
    'image/webp': 'webp',
    'image/jpeg': 'jpg',
    'image/png':  'png',
    'image/gif':  'gif',
  };
  return map[mimeType] ?? 'bin';
}

// Downloads the image, validates Content-Type + magic bytes + file size.
// Throws PipelineError on any failure; caught by mirrorHeroImage.
async function downloadAndValidate(
  sourceUrl: string,
): Promise<{ bytes: Uint8Array; mimeType: string }> {
  const response = await fetchWithTimeout(
    sourceUrl,
    { headers: { 'User-Agent': 'CatalystInsights/1.0 (content-pipeline)' } },
    HTTP_TIMEOUT_MS,
  );

  if (!response.ok) {
    throw new PipelineError(
      'FETCH_FAILED',
      `Image fetch HTTP ${response.status}: ${sourceUrl}`,
      true, // retryable
    );
  }

  // Content-Length pre-check — avoids downloading oversized images
  const contentLength = parseInt(response.headers.get('content-length') ?? '0', 10);
  if (contentLength > MAX_SOURCE_BYTES) {
    throw new PipelineError(
      'VALIDATION_FAILED',
      `Image Content-Length ${contentLength} exceeds ${MAX_SOURCE_BYTES} byte limit`,
    );
  }

  // Validate declared MIME type from Content-Type header
  const declaredMime = (response.headers.get('content-type') ?? '').split(';')[0].trim();
  if (!ACCEPTED_MIME_TYPES.has(declaredMime)) {
    throw new PipelineError(
      'VALIDATION_FAILED',
      `Unsupported image MIME type: '${declaredMime}'`,
    );
  }

  const bytes = new Uint8Array(await response.arrayBuffer());

  // Final size check — Content-Length may be absent, wrong, or lying
  if (bytes.length > MAX_SOURCE_BYTES) {
    throw new PipelineError(
      'VALIDATION_FAILED',
      `Image body ${bytes.length} bytes exceeds ${MAX_SOURCE_BYTES} byte limit`,
    );
  }

  // Magic byte validation — guards against Content-Type spoofing
  const detectedMime = detectMimeFromBytes(bytes);
  if (!detectedMime) {
    throw new PipelineError(
      'VALIDATION_FAILED',
      'Image bytes do not match any supported format signature (JPEG/PNG/WebP/GIF)',
    );
  }
  if (detectedMime !== declaredMime) {
    // Trust magic bytes over Content-Type
    logger.warn('Content-Type / magic byte mismatch — trusting magic bytes', {
      fn: FN, declared: declaredMime, detected: detectedMime,
    });
  }

  return { bytes, mimeType: detectedMime };
}

// Converts image to WebP using imagescript. Falls back to original bytes/mime on failure.
async function processToWebp(
  bytes: Uint8Array,
  inputMime: string,
): Promise<{ bytes: Uint8Array; mimeType: string }> {
  // Source already WebP — no conversion required
  if (inputMime === 'image/webp') return { bytes, mimeType: 'image/webp' };

  try {
    const img = await Image.decode(bytes);

    // Resize to fit within WEBP_MAX_DIMENSION on the longest side (maintain aspect ratio)
    if (img.width > WEBP_MAX_DIMENSION || img.height > WEBP_MAX_DIMENSION) {
      if (img.width >= img.height) {
        img.resize(WEBP_MAX_DIMENSION, Image.RESIZE_AUTO);
      } else {
        img.resize(Image.RESIZE_AUTO, WEBP_MAX_DIMENSION);
      }
    }

    const webpBytes = await img.encodeWebp(WEBP_QUALITY);
    return { bytes: new Uint8Array(webpBytes), mimeType: 'image/webp' };
  } catch (e) {
    // Decode or encode failure — upload original format rather than failing the pipeline
    logger.warn('WebP conversion failed — uploading original format', {
      fn: FN, input_mime: inputMime, error: String(e),
    });
    return { bytes, mimeType: inputMime };
  }
}

// Uploads bytes to the `insights` Storage bucket and returns the public CDN URL.
async function uploadToStorage(
  db:          SupabaseClient,
  storagePath: string,
  bytes:       Uint8Array,
  mimeType:    string,
): Promise<string> {
  const blob = new Blob([bytes], { type: mimeType });

  const { error } = await db.storage
    .from(INSIGHTS_BUCKET)
    .upload(storagePath, blob, {
      contentType: mimeType,
      upsert:      true, // idempotent on retry — same fingerprint → same path
    });

  if (error) {
    throw new PipelineError('DB_ERROR', `Storage upload failed: ${error.message}`);
  }

  const { data: { publicUrl } } = db.storage
    .from(INSIGHTS_BUCKET)
    .getPublicUrl(storagePath);

  return publicUrl;
}

// Returns the public CDN URL for the category default image (assumed seeded at deployment).
function categoryFallbackUrl(db: SupabaseClient, category: InsightCategory): string {
  const path = `${DEFAULTS_PREFIX}/${CATEGORY_DEFAULTS[category]}`;
  const { data: { publicUrl } } = db.storage.from(INSIGHTS_BUCKET).getPublicUrl(path);
  return publicUrl;
}

// ─── Exported service function ────────────────────────────────────────────────

// Downloads, validates, converts to WebP, and uploads the article hero image to
// Supabase Storage. Falls back to the per-category default on any failure.
// Never throws — all failure paths return { source: 'fallback' }.
export async function mirrorHeroImage(
  db:          SupabaseClient,
  sourceUrl:   string | null,
  fingerprint: string,
  category:    InsightCategory,
): Promise<MirrorImageResult> {
  // No source URL → immediate fallback
  if (!sourceUrl?.trim()) {
    logger.info('No hero image URL — using category fallback', { fn: FN, category });
    return { hero_image_url: categoryFallbackUrl(db, category), source: 'fallback' };
  }

  try {
    const { bytes, mimeType: inputMime } = await downloadAndValidate(sourceUrl);
    logger.info('Hero image downloaded', {
      fn: FN, url: sourceUrl, bytes: bytes.length, mime: inputMime,
    });

    const processed    = await processToWebp(bytes, inputMime);
    const storagePath  = `${HERO_PREFIX}/${fingerprint}.${mimeToExt(processed.mimeType)}`;
    const cdnUrl       = await uploadToStorage(db, storagePath, processed.bytes, processed.mimeType);

    logger.info('Hero image mirrored', {
      fn:           FN,
      storage_path: storagePath,
      bytes_in:     bytes.length,
      bytes_out:    processed.bytes.length,
      mime:         processed.mimeType,
    });

    return { hero_image_url: cdnUrl, source: 'mirrored' };

  } catch (e) {
    logger.warn('Hero image mirror failed — using category fallback', {
      fn:         FN,
      category,
      source_url: sourceUrl,
      error:      String(e),
    });
    return { hero_image_url: categoryFallbackUrl(db, category), source: 'fallback' };
  }
}
