-- Migration 031: RLS policies for polls (4 policies)

CREATE POLICY polls_select_authenticated ON public.polls
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY polls_insert_admin ON public.polls
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY polls_update_admin ON public.polls
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY polls_delete_blocked ON public.polls
  FOR DELETE USING (false);
