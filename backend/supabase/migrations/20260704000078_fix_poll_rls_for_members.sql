-- Migration 078: Allow active members to create polls and change votes

-- Allow any active member (not just admins) to create their own polls
DROP POLICY IF EXISTS polls_insert_admin ON public.polls;
CREATE POLICY polls_insert_member ON public.polls
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND created_by = auth.uid()
  );

-- Allow any active member to insert poll options for polls they created
DROP POLICY IF EXISTS poll_options_insert_admin ON public.poll_options;
CREATE POLICY poll_options_insert_member ON public.poll_options
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND EXISTS (
      SELECT 1 FROM public.polls p
      WHERE p.id = poll_id AND p.created_by = auth.uid()
    )
  );

-- Replace blocked update/delete on poll_votes with own-row policies
-- (so users can change their vote by deleting old + inserting new)
DROP POLICY IF EXISTS poll_votes_update_blocked ON public.poll_votes;
DROP POLICY IF EXISTS poll_votes_delete_blocked ON public.poll_votes;

CREATE POLICY poll_votes_update_own ON public.poll_votes
  FOR UPDATE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

CREATE POLICY poll_votes_delete_own ON public.poll_votes
  FOR DELETE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
