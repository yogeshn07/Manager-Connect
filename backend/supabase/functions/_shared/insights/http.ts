// Catalyst Insights Pipeline — HTTP utilities
// Used by validate_insight (article fetch + OG extraction) and
// enrich_insight (hero image verification).

import { OG_FETCH_TIMEOUT_MS } from './constants.ts';
import { PipelineError } from './errors.ts';
import type { OgMetadata } from './types.ts';

// ─── Fetch with timeout ───────────────────────────────────────────────────────

export async function fetchWithTimeout(
  url: string,
  options: RequestInit = {},
  timeoutMs = OG_FETCH_TIMEOUT_MS,
): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } catch (e) {
    if (e instanceof Error && e.name === 'AbortError') {
      throw new PipelineError(
        'FETCH_FAILED',
        `Request timed out after ${timeoutMs}ms: ${url}`,
        true, // retryable
      );
    }
    throw new PipelineError('FETCH_FAILED', `Fetch error for ${url}: ${String(e)}`, true);
  } finally {
    clearTimeout(timer);
  }
}

// ─── OG metadata extraction ───────────────────────────────────────────────────
// Parses Open Graph and Twitter Card meta tags from raw HTML.
// validate_insight calls this after fetching the article URL.

export function extractOgFromHtml(html: string): OgMetadata {
  function getMeta(property: string): string | null {
    // Handles both property="og:title" and name="twitter:title" attribute orders
    const patterns = [
      new RegExp(
        `<meta[^>]+(?:property|name)=["']${property}["'][^>]+content=["']([^"']+)["']`,
        'i',
      ),
      new RegExp(
        `<meta[^>]+content=["']([^"']+)["'][^>]+(?:property|name)=["']${property}["']`,
        'i',
      ),
    ];
    for (const re of patterns) {
      const m = re.exec(html);
      if (m) return m[1].trim();
    }
    return null;
  }

  const publishedTime =
    getMeta('article:published_time') ??
    getMeta('og:article:published_time') ??
    getMeta('datePublished');

  return {
    title:        getMeta('og:title')       ?? getMeta('twitter:title'),
    description:  getMeta('og:description') ?? getMeta('twitter:description'),
    image_url:    getMeta('og:image')       ?? getMeta('twitter:image'),
    // Store date only (YYYY-MM-DD) — time component is not needed
    article_date: publishedTime ? publishedTime.split('T')[0] : null,
  };
}

// ─── Sub-path domain matching ─────────────────────────────────────────────────
// WEF and EC use sub-path constraints (weforum.org/agenda/energy, ec.europa.eu/energy).
// A simple hostname check would incorrectly pass off-topic WEF pages.

export function urlMatchesDomain(url: string, approvedDomain: string): boolean {
  try {
    const parsed = new URL(url);
    // approvedDomain may be "hostname" or "hostname/path-prefix"
    const [host, ...pathParts] = approvedDomain.split('/');
    if (parsed.hostname !== host && parsed.hostname !== `www.${host}`) return false;
    if (pathParts.length === 0) return true;
    const requiredPath = '/' + pathParts.join('/');
    return parsed.pathname.startsWith(requiredPath);
  } catch {
    return false;
  }
}
