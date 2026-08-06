-- Migration 076: Make post-images storage bucket public for URL access
UPDATE storage.buckets SET public = true WHERE id = 'post-images';
