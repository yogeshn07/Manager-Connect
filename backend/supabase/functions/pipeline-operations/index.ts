// pipeline-operations — Entry point
// S3-BE-009: Pipeline Operations & Recovery API for Catalyst Insights.
//
// Manual ops control plane for the Catalyst Insights pipeline.
// Provides visibility into failed/stalled jobs and manual recovery triggers.
// This supplements (never replaces) the automated CF-01 recover-stalled-insights cron.
//
// Auth: service_role only — called by ops tooling, never from the Flutter client.
//
// POST /functions/v1/pipeline-operations
// Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
// Body: { action, ...params } — see action table below
//
// Actions:
//   list_failed       { limit?: 1–100 }         → ListJobsResult
//   list_stalled      { limit?: 1–100 }         → ListJobsResult
//   get_status        { raw_id: uuid }           → JobStatusResult
//   retry_failed      { raw_id: uuid }           → RetryResult
//   bulk_retry        { raw_ids: uuid[max 20] }  → BulkRetryResult
//   trigger_recovery  {}                         → RecoveryResult
//
// HTTP status codes:
//   200 — operation completed (includes partial success in bulk operations)
//   401 — missing or invalid service role key
//   409 — retry_failed: job is not in ai_error state
//   422 — missing or invalid parameters
//   500 — DB query failure or enrich-insight invocation error

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { logger } from '../_shared/insights/logger.ts';
import { isPipelineError } from '../_shared/insights/errors.ts';
import {
  handleListFailed,
  handleListStalled,
  handleGetStatus,
  handleRetryFailed,
  handleBulkRetry,
  handleTriggerRecovery,
} from './use-case.ts';

const FN = 'pipeline_operations';

const VALID_ACTIONS = [
  'list_failed', 'list_stalled', 'get_status',
  'retry_failed', 'bulk_retry', 'trigger_recovery',
] as const;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    requireServiceRole(req);

    const body = await req.json() as { action?: string };

    switch (body?.action) {
      case 'list_failed':
        return jsonResponse(await handleListFailed(body));

      case 'list_stalled':
        return jsonResponse(await handleListStalled(body));

      case 'get_status':
        return jsonResponse(await handleGetStatus(body));

      case 'retry_failed':
        return jsonResponse(await handleRetryFailed(body));

      case 'bulk_retry':
        return jsonResponse(await handleBulkRetry(body));

      case 'trigger_recovery':
        return jsonResponse(await handleTriggerRecovery());

      default:
        throw new AppError(
          'VALIDATION_ERROR',
          `action must be one of: ${VALID_ACTIONS.join(', ')}`,
        );
    }
  } catch (error) {
    if (isPipelineError(error)) {
      logger.error('Pipeline operation failed', {
        fn:   FN,
        code: error.code,
        msg:  error.message,
      });
      return jsonResponse({ error: { code: error.code, message: error.message } }, 500);
    }
    // AppError (UNAUTHORIZED, FORBIDDEN, CONFLICT, VALIDATION_ERROR) → toErrorResponse
    if (!(error instanceof AppError)) {
      logger.error('Pipeline operation unhandled error', { fn: FN, error: String(error) });
    }
    return toErrorResponse(error);
  }
});
