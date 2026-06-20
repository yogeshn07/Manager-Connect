-- Migration 032: Attach updated_at trigger to polls

CREATE TRIGGER set_polls_updated_at
  BEFORE UPDATE ON public.polls
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
