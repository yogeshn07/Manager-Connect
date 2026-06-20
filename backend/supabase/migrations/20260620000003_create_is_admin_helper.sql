-- Migration 003: Create is_admin() helper function
-- Used in RLS policy conditions across all tables where admin access
-- differs from member access.
--
-- SECURITY DEFINER: executes under the privileges of the function owner,
-- bypassing the caller's RLS restrictions. Without this, calling is_admin()
-- from an RLS policy on another table would trigger a recursive RLS check
-- on the profiles table, causing an infinite loop.
--
-- Returns true if the authenticated user's profile has app_role = 'admin'
-- AND is_active = true. Returns false for any other role, inactive users,
-- or if no profile exists for the caller.

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
