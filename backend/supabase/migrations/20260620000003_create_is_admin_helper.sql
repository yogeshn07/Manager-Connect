-- Migration 003: Create helper functions for RLS policies
-- Both use SECURITY DEFINER to bypass RLS when checking the caller's profile.
-- Without SECURITY DEFINER, querying profiles from within an RLS policy on
-- profiles (or any other table) would trigger recursive RLS evaluation.

-- is_active_user(): Returns true if the caller has an active profile.
-- Used as the base guard in every RLS policy on every table.
CREATE OR REPLACE FUNCTION public.is_active_user()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- is_admin(): Returns true if the caller is an active admin.
-- Used in admin-elevated RLS policies.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND app_role = 'admin'
      AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
