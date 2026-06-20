-- Migration 068: Attach updated_at trigger to pinned_announcements

CREATE TRIGGER set_pinned_announcements_updated_at
  BEFORE UPDATE ON public.pinned_announcements
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
