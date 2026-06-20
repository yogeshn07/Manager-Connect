-- Migration 041: RLS policies for challenges (4 policies)
-- INSERT: any active member per FR-05.1/FR-05.2

CREATE POLICY challenges_select_authenticated ON public.challenges
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY challenges_insert_authenticated ON public.challenges
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND created_by = auth.uid()
  );

CREATE POLICY challenges_update_admin ON public.challenges
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY challenges_delete_blocked ON public.challenges
  FOR DELETE USING (false);
