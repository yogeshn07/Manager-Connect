// activate-scheduled-insights — Entry point
// CF-02: Cron-driven scheduled publication for the Catalyst Insights pipeline.
//
// Finds catalyst_insights records whose status is 'scheduled' and whose
// scheduled_for timestamp has passed (or is null), then transitions them to
// 'active' in a single atomic UPDATE, setting published_at to the current UTC time.
//
// Auth: service_role only — called by Supabase cron (pg_cron). Never exposed
//       to Flutter clients or the admin UI.
// Cron: every minute ("* * * * *") — fine-grained enough for accurate publication
//       timing without excessive DB load (query uses partial index).
//
// POST /functions/v1/activate-scheduled-insights
// Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
// Body: none required (cron caller sends empty POST)
//
// 200: { activated_count, insight_ids, checked_at }
// 401: missing or invalid service role key
// 500: DB query failure

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { logger } from '../_shared/insights/logger.ts';
import { isPipelineError } from '../_shared/insights/errors.ts';
import { handleActivateScheduledInsights } from './use-case.ts';

const FN = 'activate_scheduled_insights';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    // Service-role gate — this function must never be callable by regular users.
    requireServiceRole(req);

    const result = await handleActivateScheduledInsights();

    // Structured audit: log every run so cron history is visible in Supabase logs.
    // activated_count = 0 is normal (most runs between publication times).
    if (result.activated_count > 0) {
      logger.info('CF-02 scheduled insights activated', {
        fn:              FN,
        activated_count: result.activated_count,
        insight_ids:     result.insight_ids,
        checked_at:      result.checked_at,
      });
    } else {
      logger.info('CF-02 scan complete — no insights due for publication', {
        fn:         FN,
        checked_at: result.checked_at,
      });
    }

    return jsonResponse(result, 200);
  } catch (error) {
    if (isPipelineError(error)) {
      logger.error('CF-02 pipeline error', {
        fn:   FN,
        code: error.code,
        msg:  error.message,
      });
      return jsonResponse({ error: { code: error.code, message: error.message } }, 500);
    }
    // AppError from requireServiceRole → UNAUTHORIZED (401) via toErrorResponse
    if (!(error instanceof AppError)) {
      logger.error('CF-02 unhandled error', { fn: FN, error: String(error) });
    }
    return toErrorResponse(error);
  }
});
