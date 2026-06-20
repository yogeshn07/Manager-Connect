-- Migration 029: RLS policies for activity_updates (4 policies)
-- Insert/update restricted to admin (Edge Function handles creator check)

CREATE POLICY activity_updates_select_authenticated ON public.activity_updates
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY activity_updates_insert_admin ON public.activity_updates
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY activity_updates_update_admin ON public.activity_updates
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY activity_updates_delete_blocked ON public.activity_updates
  FOR DELETE USING (false);
