// Catalyst Insights Pipeline — pipeline error types
// Distinct from the app-level _shared/errors.ts (which is HTTP-status-oriented).
// PipelineError models failures within the 10-stage content pipeline:
//   collect → validate → enrich → review → publish
// These errors are caught inside Edge Function handlers and translated to
// database status updates (e.g. status='rejected', status='ai_error') rather
// than HTTP error responses.

export type PipelineErrorCode =
  | 'SOURCE_NOT_FOUND'     // insights_sources row missing or inactive
  | 'DOMAIN_MISMATCH'      // URL host doesn't match approved_domain
  | 'DUPLICATE_URL'        // url_fingerprint already exists in insights_raw
  | 'FETCH_FAILED'         // HTTP fetch of article URL timed out or errored
  | 'OG_EXTRACTION_FAILED' // Could not extract meaningful OG metadata
  | 'AI_ENRICHMENT_FAILED' // OpenAI call failed or returned invalid JSON
  | 'VALIDATION_FAILED'    // validate_insight rejected content (short, paywalled, etc.)
  | 'DB_ERROR'             // Supabase query error
  | 'CONFIG_MISSING';      // Required env var absent

export class PipelineError extends Error {
  readonly code: PipelineErrorCode;
  // retryable=true → cron / recover_stalled_insights may attempt again
  readonly retryable: boolean;

  constructor(code: PipelineErrorCode, message: string, retryable = false) {
    super(message);
    this.name = 'PipelineError';
    this.code = code;
    this.retryable = retryable;
  }
}

export function isPipelineError(e: unknown): e is PipelineError {
  return e instanceof PipelineError;
}

// Maps a PipelineError to the raw_status that should be written to the DB.
export function pipelineErrorToRawStatus(
  e: PipelineError,
): 'rejected' | 'ai_error' | 'duplicate' {
  switch (e.code) {
    case 'DUPLICATE_URL':        return 'duplicate';
    case 'AI_ENRICHMENT_FAILED': return 'ai_error';
    default:                     return 'rejected';
  }
}
