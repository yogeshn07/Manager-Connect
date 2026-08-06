// pipeline-diagnostics — Entry point
// S3-BE-010: End-to-End Pipeline Validation & Diagnostics for Catalyst Insights.
//
// Read-only operational health gate that verifies the complete pipeline is wired
// correctly before enabling production traffic. Safe to call at any time — it
// never modifies any database rows or invokes other pipeline modules.
//
// Auth: service_role only — exposes sensitive configuration status and internal
//       table connectivity details that must not be visible to regular users.
//
// POST /functions/v1/pipeline-diagnostics
// Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
// Body: none required
//
// 200: DiagnosticsReport — see use-case.ts for full type definition
//   {
//     checked_at: ISO UTC string
//     readiness:  'ready' | 'degraded' | 'blocked'
//     env:        { ok, checks: { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY } }
//     database:   { ok, latency_ms, tables: { insights_sources, insights_raw,
//                   catalyst_insights, admin_audit_log } }
//     storage:    { ok, checks: { insights_bucket } }
//     ai:         { ok, provider, model, checks: { api_key_present, api_key_format } }
//     modules:    ModuleDiagnostics[10]
//     scheduler:  { ok, crons: CronDiagnostics[3] }
//     summary:    { total_checks, passed, warned, failed, blocking_issues }
//   }
//
// 401: missing or invalid service role key
// 500: unexpected error during diagnostics execution

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireServiceRole } from '../_shared/auth.ts';
import { logger } from '../_shared/insights/logger.ts';
import { isPipelineError } from '../_shared/insights/errors.ts';
import { handlePipelineDiagnostics } from './use-case.ts';

const FN = 'pipeline_diagnostics';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    requireServiceRole(req);

    const report = await handlePipelineDiagnostics();

    // Surface readiness and summary at the log level so ops can confirm
    // health check runs in Supabase logs without parsing the full response body.
    logger.info('Pipeline diagnostics complete', {
      fn:              FN,
      checked_at:      report.checked_at,
      readiness:       report.readiness,
      total_checks:    report.summary.total_checks,
      passed:          report.summary.passed,
      warned:          report.summary.warned,
      failed:          report.summary.failed,
      blocking_issues: report.summary.blocking_issues,
    });

    return jsonResponse(report, 200);
  } catch (error) {
    if (isPipelineError(error)) {
      logger.error('Pipeline diagnostics — pipeline error', {
        fn:   FN,
        code: error.code,
        msg:  error.message,
      });
      return jsonResponse({ error: { code: error.code, message: error.message } }, 500);
    }
    // AppError from requireServiceRole → UNAUTHORIZED (401) via toErrorResponse
    if (!(error instanceof AppError)) {
      logger.error('Pipeline diagnostics — unhandled error', { fn: FN, error: String(error) });
    }
    return toErrorResponse(error);
  }
});
