// Catalyst Insights Pipeline — database client factory
// Returns a service-role Supabase client for pipeline Edge Functions.
// service_role bypasses all RLS (confirmed in Sprint 1 M06 design).
// Distinct from the app-level _shared/supabase-client.ts which also
// exposes createUserClient() — the pipeline never acts as a specific user.

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import type { InsightsPipelineConfig } from './config.ts';

export function createPipelineClient(config: InsightsPipelineConfig): SupabaseClient {
  return createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

// Convenience re-export so callers only need to import from this module.
export type { SupabaseClient };
