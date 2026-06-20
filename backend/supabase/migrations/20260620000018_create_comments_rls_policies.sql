-- Migration 018: RLS policies for comments (6 policies)

CREATE POLICY comments_select_member ON public.comments
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND is_deleted = false
    AND post_id IN (SELECT id FROM public.posts WHERE is_deleted = false)
  );

CREATE POLICY comments_select_admin ON public.comments
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY comments_insert_own ON public.comments
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND author_id = auth.uid()
  );

CREATE POLICY comments_update_own ON public.comments
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND author_id = auth.uid() AND is_deleted = false
  );

CREATE POLICY comments_update_admin ON public.comments
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY comments_delete_blocked ON public.comments
  FOR DELETE USING (false);
