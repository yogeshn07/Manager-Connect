-- Migration 065: Attach updated_at trigger to flagged_content

CREATE TRIGGER set_flagged_content_updated_at
  BEFORE UPDATE ON public.flagged_content
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
