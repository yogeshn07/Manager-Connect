// collect-insight — Entry point
// Accepts an admin-submitted article URL and queues it for the Catalyst Insights
// content pipeline by creating an insights_raw record with status='pending'.
//
// Auth: requires authenticated admin (app_role='admin' in profiles).
// Pipeline: service_role client bypasses RLS for the INSERT into insights_raw.
//
// POST /functions/v1/collect-insight
// Body: { url: string, source_id: string, submitted_by?: string }
// 201:  { raw_id, status, message }
// 404:  source not found or inactive
// 409:  URL already in pipeline (duplicate fingerprint)
// 422:  invalid URL / missing required fields

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireAuth, requireAdmin } from '../_shared/auth.ts';
import { loadConfig } from '../_shared/insights/config.ts';
import { createPipelineClient } from '../_shared/insights/database.ts';
import { logger } from '../_shared/insights/logger.ts';
import { isPipelineError } from '../_shared/insights/errors.ts';
import { handleCollectInsight } from './use-case.ts';

const FN = 'collect_insight';

// HTTP status mapping for pipeline errors
const PIPELINE_STATUS: Record<string, number> = {
  SOURCE_NOT_FOUND:     404,
  DUPLICATE_URL:        409,
  DOMAIN_MISMATCH:      422,
  VALIDATION_FAILED:    422,
  DB_ERROR:             500,
  CONFIG_MISSING:       500,
  FETCH_FAILED:         502,
  OG_EXTRACTION_FAILED: 422,
  AI_ENRICHMENT_FAILED: 502,
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    // Auth: admin only
    const { userId, client } = await requireAuth(req);
    await requireAdmin(userId, client);

    // Pipeline config + service-role client (bypasses RLS for insights_raw INSERT)
    const config = loadConfig();
    const db = createPipelineClient(config);

    const body = await req.json();
    const result = await handleCollectInsight(body, db);

    logger.info('collect_insight succeeded', {
      fn: FN,
      raw_id: result.raw_id,
      status: result.status,
    });

    return jsonResponse(result, 201);
  } catch (error) {
    if (isPipelineError(error)) {
      const status = PIPELINE_STATUS[error.code] ?? 500;
      logger.warn('Pipeline error', { fn: FN, code: error.code, msg: error.message });
      return jsonResponse({ error: { code: error.code, message: error.message } }, status);
    }
    // AppError (UNAUTHORIZED, FORBIDDEN) and unknown errors
    if (!(error instanceof AppError)) {
      logger.error('Unhandled error', { fn: FN, error: String(error) });
    }
    return toErrorResponse(error);
  }
});
