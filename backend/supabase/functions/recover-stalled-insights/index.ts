// recover-stalled-insights — Entry point
// CF-01: Cron-driven recovery for the Catalyst Insights pipeline.
//
// Finds insights_raw records stuck in 'validated' state and re-invokes
// enrich_insight for each one, recovering from fire-and-forget delivery
// failures that would otherwise leave records permanently stalled.
//
// Auth: service_role only — called by Supabase cron (pg_cron), never from the
//       Flutter client or the admin web UI.
// Cron: every 30 minutes (cron contract: "*/30 * * * *")
// Threshold: status='validated' AND updated_at < NOW() - INTERVAL '15 minutes'
//
// POST /functions/v1/recover-stalled-insights
// Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
// Body: none required (cron caller sends empty POST)
//
// 200: { total_stalled, recovered_count, failed_count,
//        raw_ids_recovered, raw_ids_failed, stale_before }
// 401: missing or invalid service role key
// 500: DB query failure / missing env config

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { loadConfig } from '../_shared/insights/config.ts';
import { createPipelineClient } from '../_shared/insights/database.ts';
import { logger } from '../_shared/insights/logger.ts';
import { isPipelineError } from '../_shared/insights/errors.ts';
import { handleRecoverStalledInsights } from './use-case.ts';

const FN = 'recover_stalled_insights';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    // Service-role gate — this function must never be callable by regular users.
    requireServiceRole(req);

    const config = loadConfig();
    const db     = createPipelineClient(config);

    const result = await handleRecoverStalledInsights(db, config);

    // WARN when recoveries were needed — this signals missed fire-and-forget calls
    // and is the primary observability signal for pipeline health monitoring.
    if (result.total_stalled > 0) {
      logger.warn('CF-01 recovery completed', {
        fn:              FN,
        total_stalled:   result.total_stalled,
        recovered_count: result.recovered_count,
        failed_count:    result.failed_count,
        stale_before:    result.stale_before,
      });
    } else {
      logger.info('CF-01 scan complete — no stalled insights', {
        fn:          FN,
        stale_before: result.stale_before,
      });
    }

    return jsonResponse(result, 200);
  } catch (error) {
    if (isPipelineError(error)) {
      logger.error('CF-01 pipeline error', { fn: FN, code: error.code, msg: error.message });
      return jsonResponse({ error: { code: error.code, message: error.message } }, 500);
    }
    // AppError from requireServiceRole → UNAUTHORIZED (401)
    if (!(error instanceof AppError)) {
      logger.error('CF-01 unhandled error', { fn: FN, error: String(error) });
    }
    return toErrorResponse(error);
  }
});
