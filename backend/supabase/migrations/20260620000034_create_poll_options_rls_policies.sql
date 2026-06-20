-- Migration 034: RLS policies for poll_options (4 policies)

CREATE POLICY poll_options_select_authenticated ON public.poll_options
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY poll_options_insert_admin ON public.poll_options
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY poll_options_update_blocked ON public.poll_options
  FOR UPDATE USING (false);

CREATE POLICY poll_options_delete_blocked ON public.poll_options
  FOR DELETE USING (false);
