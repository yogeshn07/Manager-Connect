-- Migration 005: RLS policies for profiles
-- 5 policies: SELECT(1), UPDATE(2), INSERT(1 blocked), DELETE(1 blocked)
-- Uses is_active_user() SECURITY DEFINER function to avoid infinite recursion
-- when checking the caller's is_active status on the profiles table itself.

-- SELECT: all active authenticated users can read all profiles
CREATE POLICY profiles_select_authenticated ON public.profiles
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND is_active_user()
  );

-- UPDATE: member can edit only their own profile
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND is_active_user()
    AND id = auth.uid()
  )
  WITH CHECK (
    id = auth.uid()
  );

-- UPDATE: admin can edit any profile (deactivation, role changes)
CREATE POLICY profiles_update_admin ON public.profiles
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- INSERT: blocked for all clients (Edge Function via service_role creates profiles)
CREATE POLICY profiles_insert_blocked ON public.profiles
  FOR INSERT
  WITH CHECK (false);

-- DELETE: blocked for all clients (profiles are never hard-deleted)
CREATE POLICY profiles_delete_blocked ON public.profiles
  FOR DELETE
  USING (false);
