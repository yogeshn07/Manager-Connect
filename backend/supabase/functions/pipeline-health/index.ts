// pipeline-health — Entry point
// S3-BE-008: Pipeline Health & Monitoring for the Catalyst Insights pipeline.
//
// Returns a structured snapshot of pipeline queue depths, health signals,
// and processing latency metrics. Read-only — does not modify any records.
//
// Auth: service_role only — called by ops/admin tooling, never from the
//       Flutter client. Returns sensitive pipeline internals.
//
// POST /functions/v1/pipeline-health
// Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
// Body: none required
//
// 200: PipelineHealthResult (see use-case.ts for full schema)
// 401: missing or invalid service role key
// 500: DB query failure

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { logger } from '../_shared/insights/logger.ts';
import { isPipelineError } from '../_shared/insights/errors.ts';
import { handlePipelineHealth } from './use-case.ts';

const FN = 'pipeline_health';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    requireServiceRole(req);

    const result = await handlePipelineHealth();

    // Surface key health signals in the Edge Function log so ops can correlate
    // health check runs with pipeline anomalies without parsing the full response.
    logger.info('Pipeline health check complete', {
      fn:                       FN,
      checked_at:               result.checked_at,
      raw_total:                result.raw_queue.total,
      catalyst_total:           result.catalyst_insights.total,
      active_count:             result.catalyst_insights.by_status.active,
      failed_enrichment_count:  result.health_signals.failed_enrichment_count,
      stalled_validation_count: result.health_signals.stalled_validation_count,
      ingested_last_24h:        result.health_signals.ingested_last_24h,
      avg_time_to_publish_ms:   result.latency.avg_time_to_publish_ms,
    });

    return jsonResponse(result, 200);
  } catch (error) {
    if (isPipelineError(error)) {
      logger.error('Pipeline health check failed', {
        fn:   FN,
        code: error.code,
        msg:  error.message,
      });
      return jsonResponse({ error: { code: error.code, message: error.message } }, 500);
    }
    // AppError from requireServiceRole → UNAUTHORIZED (401) via toErrorResponse
    if (!(error instanceof AppError)) {
      logger.error('Pipeline health unhandled error', { fn: FN, error: String(error) });
    }
    return toErrorResponse(error);
  }
});
