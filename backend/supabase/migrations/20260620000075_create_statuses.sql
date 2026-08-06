-- Migration 075: Statuses (Instagram-style stories, expire after 24 h)
CREATE TABLE IF NOT EXISTS public.statuses (
  id         uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  image_url  text,
  caption    text,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '24 hours')
);

CREATE INDEX IF NOT EXISTS idx_statuses_active ON public.statuses (expires_at DESC);

ALTER TABLE public.statuses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "statuses_read" ON public.statuses
  FOR SELECT TO authenticated USING (expires_at > now());

CREATE POLICY "statuses_insert" ON public.statuses
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "statuses_delete" ON public.statuses
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

GRANT SELECT, INSERT, DELETE ON public.statuses TO authenticated;

-- Storage bucket for status images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('statuses', 'statuses', false, 10485760, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "statuses_storage_read" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'statuses');

CREATE POLICY "statuses_storage_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'statuses'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "statuses_storage_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'statuses'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
