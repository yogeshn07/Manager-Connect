// enrich-insight — Entry point
// Third and heaviest stage of the Catalyst Insights content pipeline.
// Takes a validated raw insight and produces an AI-enriched catalyst_insight record.
//
// Steps: OG metadata extraction → (IEEE abstract retrieval) → AI enrichment →
//         insights_raw update → catalyst_insights INSERT → status transition
//
// Auth: service_role only — called internally by:
//   - recover_stalled_insights (CF-01 cron, every 30 min)
//   - validate_insight (fire-and-forget, wired in a later task per use-case.ts note)
//
// POST /functions/v1/enrich-insight
// Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
// Body: { raw_id: string }
//
// 200: { insight_id, status: 'review', ai_confidence }
// 401: missing or invalid service role key
// 422: malformed body, or record not in 'validated' state
// 502: OG fetch failure or AI enrichment failure (retryable)
// 500: DB error / missing required env config

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { loadConfig } from '../_shared/insights/config.ts';
import { createPipelineClient } from '../_shared/insights/database.ts';
import { logger } from '../_shared/insights/logger.ts';
import { isPipelineError } from '../_shared/insights/errors.ts';
import { handleEnrichInsight } from './use-case.ts';

const FN = 'enrich_insight';

const PIPELINE_STATUS: Record<string, number> = {
  VALIDATION_FAILED:    422,
  FETCH_FAILED:         502,
  OG_EXTRACTION_FAILED: 502,
  AI_ENRICHMENT_FAILED: 502,
  DB_ERROR:             500,
  CONFIG_MISSING:       500,
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    // Service-role gate — enrich_insight is an internal pipeline function.
    // Never called by a Flutter client JWT.
    requireServiceRole(req);

    const config = loadConfig();
    const db     = createPipelineClient(config);
    const body   = await req.json();

    const result = await handleEnrichInsight(body, db, config);

    logger.info('enrich_insight completed', {
      fn:            FN,
      insight_id:    result.insight_id,
      ai_confidence: result.ai_confidence,
      status:        result.status,
    });

    return jsonResponse(result, 200);
  } catch (error) {
    if (isPipelineError(error)) {
      const status = PIPELINE_STATUS[error.code] ?? 500;
      logger.warn('Pipeline error', {
        fn:        FN,
        code:      error.code,
        msg:       error.message,
        retryable: error.retryable,
      });
      return jsonResponse({ error: { code: error.code, message: error.message } }, status);
    }
    // AppError (UNAUTHORIZED from requireServiceRole) → 401 via toErrorResponse
    if (!(error instanceof AppError)) {
      logger.error('Unhandled error', { fn: FN, error: String(error) });
    }
    return toErrorResponse(error);
  }
});
