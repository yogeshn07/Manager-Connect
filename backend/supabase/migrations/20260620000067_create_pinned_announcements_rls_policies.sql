-- Migration 067: RLS policies for pinned_announcements (4 policies)

CREATE POLICY pinned_announcements_select_authenticated ON public.pinned_announcements
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY pinned_announcements_insert_admin ON public.pinned_announcements
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY pinned_announcements_update_admin ON public.pinned_announcements
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY pinned_announcements_delete_blocked ON public.pinned_announcements
  FOR DELETE USING (false);
