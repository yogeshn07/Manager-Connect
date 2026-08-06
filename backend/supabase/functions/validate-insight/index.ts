// validate-insight — Entry point
// Validates a pending insights_raw record through the Catalyst Insights pipeline
// acceptance criteria: source check, approved-domain match, duplicate re-check.
//
// Auth: service_role only (called internally by cron, recover_stalled_insights,
//       or fire-and-forget from collect_insight).
// Pipeline role: pending → validated | duplicate | rejected
//
// POST /functions/v1/validate-insight
// Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
// Body: { raw_id: string }
//
// 200: { raw_id, status: 'validated'|'duplicate'|'rejected', message }
// 401: missing or invalid service role key
// 422: malformed request body
// 500: unexpected DB error

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { loadConfig } from '../_shared/insights/config.ts';
import { createPipelineClient } from '../_shared/insights/database.ts';
import { logger } from '../_shared/insights/logger.ts';
import { isPipelineError } from '../_shared/insights/errors.ts';
import { handleValidateInsight } from './use-case.ts';

const FN = 'validate_insight';

const PIPELINE_STATUS: Record<string, number> = {
  VALIDATION_FAILED: 422,
  DB_ERROR:          500,
  CONFIG_MISSING:    500,
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    // Service-role gate — this is an internal pipeline function
    requireServiceRole(req);

    const config = loadConfig();
    const db    = createPipelineClient(config);
    const body  = await req.json();

    const result = await handleValidateInsight(body, db);

    logger.info('validate_insight completed', {
      fn:     FN,
      raw_id: result.raw_id,
      status: result.status,
    });

    return jsonResponse(result, 200);
  } catch (error) {
    if (isPipelineError(error)) {
      const status = PIPELINE_STATUS[error.code] ?? 500;
      logger.warn('Pipeline error', { fn: FN, code: error.code, msg: error.message });
      return jsonResponse({ error: { code: error.code, message: error.message } }, status);
    }
    // AppError (UNAUTHORIZED from requireServiceRole) handled by toErrorResponse
    if (!(error instanceof AppError)) {
      logger.error('Unhandled error', { fn: FN, error: String(error) });
    }
    return toErrorResponse(error);
  }
});
