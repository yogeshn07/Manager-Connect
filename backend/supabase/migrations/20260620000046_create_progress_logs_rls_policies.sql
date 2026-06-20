-- Migration 046: RLS policies for progress_logs (5 policies)
-- SELECT: all authenticated (leaderboard requires all-member access)

CREATE POLICY progress_logs_select_authenticated ON public.progress_logs
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY progress_logs_select_admin ON public.progress_logs
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY progress_logs_insert_own ON public.progress_logs
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY progress_logs_update_own ON public.progress_logs
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY progress_logs_delete_blocked ON public.progress_logs
  FOR DELETE USING (false);
