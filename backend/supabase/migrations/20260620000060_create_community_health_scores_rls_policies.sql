-- Migration 060: RLS policies for community_health_scores (4 policies)

CREATE POLICY community_health_scores_select_authenticated ON public.community_health_scores
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY community_health_scores_insert_blocked ON public.community_health_scores
  FOR INSERT WITH CHECK (false);

CREATE POLICY community_health_scores_update_blocked ON public.community_health_scores
  FOR UPDATE USING (false);

CREATE POLICY community_health_scores_delete_blocked ON public.community_health_scores
  FOR DELETE USING (false);
