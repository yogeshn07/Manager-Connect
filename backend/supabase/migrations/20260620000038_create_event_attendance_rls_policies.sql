-- Migration 038: RLS policies for event_attendance (4 policies)

CREATE POLICY event_attendance_select_authenticated ON public.event_attendance
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY event_attendance_insert_admin ON public.event_attendance
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY event_attendance_update_admin ON public.event_attendance
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY event_attendance_delete_blocked ON public.event_attendance
  FOR DELETE USING (false);
