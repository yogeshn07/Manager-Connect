-- Migration 036: RLS policies for poll_votes (4 policies)

CREATE POLICY poll_votes_select_authenticated ON public.poll_votes
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY poll_votes_insert_own ON public.poll_votes
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY poll_votes_update_blocked ON public.poll_votes
  FOR UPDATE USING (false);

CREATE POLICY poll_votes_delete_blocked ON public.poll_votes
  FOR DELETE USING (false);
