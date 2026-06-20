-- Migration 008: RLS policies for invitations
-- 5 policies: SELECT(2), INSERT(1), UPDATE(1), DELETE(1 blocked)
-- Uses is_active_user() and is_admin() SECURITY DEFINER helpers

-- SELECT: admin sees all invitations
CREATE POLICY invitations_select_admin ON public.invitations
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- SELECT: member sees only the invitation they accepted
CREATE POLICY invitations_select_own ON public.invitations
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND is_active_user()
    AND accepted_by = auth.uid()
  );

-- INSERT: only admins can create invitations
CREATE POLICY invitations_insert_admin ON public.invitations
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- UPDATE: only admins can update invitations (mark accepted, revoke)
CREATE POLICY invitations_update_admin ON public.invitations
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- DELETE: blocked for all clients
CREATE POLICY invitations_delete_blocked ON public.invitations
  FOR DELETE
  USING (false);
