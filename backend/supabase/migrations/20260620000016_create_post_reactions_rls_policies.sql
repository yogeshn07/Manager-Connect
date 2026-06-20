-- Migration 016: RLS policies for post_reactions (4 policies)

CREATE POLICY post_reactions_select_authenticated ON public.post_reactions
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY post_reactions_insert_own ON public.post_reactions
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY post_reactions_update_own ON public.post_reactions
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY post_reactions_delete_own ON public.post_reactions
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );
