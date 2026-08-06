// expire-old-insights — Entry point
// CF-03: Cron-driven expiration and archival for the Catalyst Insights pipeline.
//
// Archives active insights that have been published for more than
// ACTIVE_INSIGHT_EXPIRY_DAYS (30) days and are not marked as evergreen.
// Insights with is_evergreen = true are NEVER archived by this function.
//
// Auth: service_role only — called by Supabase cron (pg_cron). Never exposed
//       to Flutter clients or the admin UI.
// Cron: daily at 02:00 UTC ("0 2 * * *") — expiry is not time-critical to the minute.
//
// POST /functions/v1/expire-old-insights
// Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
// Body: none required (cron caller sends empty POST)
//
// 200: { expired_count, insight_ids, expiry_threshold }
// 401: missing or invalid service role key
// 500: DB query failure

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { logger } from '../_shared/insights/logger.ts';
import { isPipelineError } from '../_shared/insights/errors.ts';
import { handleExpireOldInsights } from './use-case.ts';

const FN = 'expire_old_insights';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    // Service-role gate — this function must never be callable by regular users.
    requireServiceRole(req);

    const result = await handleExpireOldInsights();

    // Structured audit: log every run so cron history is queryable in Supabase logs.
    if (result.expired_count > 0) {
      logger.info('CF-03 insights archived', {
        fn:               FN,
        expired_count:    result.expired_count,
        insight_ids:      result.insight_ids,
        expiry_threshold: result.expiry_threshold,
      });
    } else {
      logger.info('CF-03 scan complete — no insights eligible for expiration', {
        fn:               FN,
        expiry_threshold: result.expiry_threshold,
      });
    }

    return jsonResponse(result, 200);
  } catch (error) {
    if (isPipelineError(error)) {
      logger.error('CF-03 pipeline error', {
        fn:   FN,
        code: error.code,
        msg:  error.message,
      });
      return jsonResponse({ error: { code: error.code, message: error.message } }, 500);
    }
    // AppError from requireServiceRole → UNAUTHORIZED (401) via toErrorResponse
    if (!(error instanceof AppError)) {
      logger.error('CF-03 unhandled error', { fn: FN, error: String(error) });
    }
    return toErrorResponse(error);
  }
});
