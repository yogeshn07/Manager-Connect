-- Migration 011: RLS policies for posts (6 policies)

CREATE POLICY posts_select_member ON public.posts
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND is_deleted = false
  );

CREATE POLICY posts_select_admin ON public.posts
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY posts_insert_own ON public.posts
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND author_id = auth.uid()
  );

CREATE POLICY posts_update_own ON public.posts
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND author_id = auth.uid() AND is_deleted = false
  );

CREATE POLICY posts_update_admin ON public.posts
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY posts_delete_blocked ON public.posts
  FOR DELETE USING (false);
