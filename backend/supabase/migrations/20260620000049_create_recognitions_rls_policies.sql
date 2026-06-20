-- Migration 049: RLS policies for recognitions (6 policies)

CREATE POLICY recognitions_select_member ON public.recognitions
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND is_deleted = false
  );

CREATE POLICY recognitions_select_admin ON public.recognitions
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY recognitions_insert_own ON public.recognitions
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND giver_id = auth.uid()
  );

CREATE POLICY recognitions_update_blocked ON public.recognitions
  FOR UPDATE USING (false);

CREATE POLICY recognitions_update_admin ON public.recognitions
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY recognitions_delete_blocked ON public.recognitions
  FOR DELETE USING (false);
