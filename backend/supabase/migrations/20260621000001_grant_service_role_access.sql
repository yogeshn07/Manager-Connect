-- Migration: Grant service_role access to all public tables
-- The service_role user bypasses RLS but still needs table-level GRANTs.
-- Supabase's default roles.sql grants to existing tables at init time,
-- but tables created by subsequent migrations don't inherit those grants.
-- This migration ensures service_role (used by Edge Functions via
-- createAdminClient) can access all current and future public tables.

GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Ensure future tables also get the grant automatically
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;
