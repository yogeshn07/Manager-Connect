-- Migration 039: Attach updated_at trigger to event_attendance

CREATE TRIGGER set_event_attendance_updated_at
  BEFORE UPDATE ON public.event_attendance
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
