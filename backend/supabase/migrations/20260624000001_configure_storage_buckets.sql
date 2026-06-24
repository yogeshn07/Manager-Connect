-- REM-01: Storage Bucket RLS Configuration
-- Creates avatars (public) and post-images (private) buckets with secure policies.

-- Step 1: Create buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 2097152, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('post-images', 'post-images', false, 5242880, ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO NOTHING;

-- Step 2: Avatars policies (public bucket)

-- Anyone can view avatars (public read)
CREATE POLICY "avatars_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Authenticated users can upload to their own folder only
CREATE POLICY "avatars_auth_insert"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner can update their own avatar
CREATE POLICY "avatars_auth_update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner can delete their own avatar
CREATE POLICY "avatars_auth_delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Step 3: Post-images policies (private bucket)

-- Authenticated members can view post images
CREATE POLICY "postimages_auth_read"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'post-images'
  AND auth.role() = 'authenticated'
);

-- Authenticated users can upload to their own folder only
CREATE POLICY "postimages_auth_insert"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'post-images'
  AND auth.role() = 'authenticated'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner can update their own images
CREATE POLICY "postimages_auth_update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'post-images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner can delete their own images
CREATE POLICY "postimages_auth_delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'post-images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
