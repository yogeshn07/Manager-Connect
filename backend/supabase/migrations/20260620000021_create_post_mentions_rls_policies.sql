-- Migration 021: RLS policies for post_mentions (4 policies)
-- Service_role only for INSERT — Edge Function writes mentions on post creation

CREATE POLICY post_mentions_select_authenticated ON public.post_mentions
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY post_mentions_insert_blocked ON public.post_mentions
  FOR INSERT WITH CHECK (false);

CREATE POLICY post_mentions_update_blocked ON public.post_mentions
  FOR UPDATE USING (false);

CREATE POLICY post_mentions_delete_blocked ON public.post_mentions
  FOR DELETE USING (false);
