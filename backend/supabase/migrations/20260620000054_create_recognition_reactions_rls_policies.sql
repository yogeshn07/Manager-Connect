-- Migration 054: RLS policies for recognition_reactions (4 policies)

CREATE POLICY recognition_reactions_select_authenticated ON public.recognition_reactions
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY recognition_reactions_insert_own ON public.recognition_reactions
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY recognition_reactions_update_own ON public.recognition_reactions
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY recognition_reactions_delete_own ON public.recognition_reactions
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );
