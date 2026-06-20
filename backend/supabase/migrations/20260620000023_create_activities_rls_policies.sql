-- Migration 023: RLS policies for activities (4 policies)

CREATE POLICY activities_select_authenticated ON public.activities
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY activities_insert_authenticated ON public.activities
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND created_by = auth.uid()
  );

CREATE POLICY activities_update_admin ON public.activities
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY activities_delete_blocked ON public.activities
  FOR DELETE USING (false);
