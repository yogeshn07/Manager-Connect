// Catalyst Insights Pipeline — environment configuration
// Validates all required env vars at startup so Edge Functions fail fast
// with a clear error message rather than a null-dereference mid-pipeline.

import { PipelineError } from './errors.ts';

export interface InsightsPipelineConfig {
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
  supabaseAnonKey: string;
  openAiApiKey: string;
}

function requireEnv(key: string): string {
  const val = Deno.env.get(key);
  if (!val) throw new PipelineError('CONFIG_MISSING', `${key} env var is not set`);
  return val;
}

export function loadConfig(): InsightsPipelineConfig {
  return {
    supabaseUrl:           requireEnv('SUPABASE_URL'),
    supabaseServiceRoleKey: requireEnv('SUPABASE_SERVICE_ROLE_KEY'),
    supabaseAnonKey:       requireEnv('SUPABASE_ANON_KEY'),
    openAiApiKey:          requireEnv('OPENAI_API_KEY'),
  };
}
