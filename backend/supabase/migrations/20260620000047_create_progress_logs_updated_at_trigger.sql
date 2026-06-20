-- Migration 047: Attach updated_at trigger to progress_logs

CREATE TRIGGER set_progress_logs_updated_at
  BEFORE UPDATE ON public.progress_logs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
