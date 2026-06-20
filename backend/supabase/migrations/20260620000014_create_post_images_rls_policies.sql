-- Migration 014: RLS policies for post_images (5 policies)

CREATE POLICY post_images_select_member ON public.post_images
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND post_id IN (SELECT id FROM public.posts WHERE is_deleted = false)
  );

CREATE POLICY post_images_select_admin ON public.post_images
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY post_images_insert_own ON public.post_images
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND post_id IN (SELECT id FROM public.posts WHERE author_id = auth.uid())
  );

CREATE POLICY post_images_update_blocked ON public.post_images
  FOR UPDATE USING (false);

CREATE POLICY post_images_delete_blocked ON public.post_images
  FOR DELETE USING (false);
