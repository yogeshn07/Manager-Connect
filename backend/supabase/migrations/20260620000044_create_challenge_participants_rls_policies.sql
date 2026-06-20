-- Migration 044: RLS policies for challenge_participants (4 policies)

CREATE POLICY challenge_participants_select_authenticated ON public.challenge_participants
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY challenge_participants_insert_own ON public.challenge_participants
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY challenge_participants_update_blocked ON public.challenge_participants
  FOR UPDATE USING (false);

CREATE POLICY challenge_participants_delete_own ON public.challenge_participants
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );
