-- Migration 027: Attach updated_at trigger to activity_rsvps

CREATE TRIGGER set_activity_rsvps_updated_at
  BEFORE UPDATE ON public.activity_rsvps
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
