-- Migration 064: RLS policies for flagged_content (4 policies)

CREATE POLICY flagged_content_select_admin ON public.flagged_content
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY flagged_content_insert_own ON public.flagged_content
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND reporter_id = auth.uid()
  );

CREATE POLICY flagged_content_update_admin ON public.flagged_content
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY flagged_content_delete_blocked ON public.flagged_content
  FOR DELETE USING (false);
