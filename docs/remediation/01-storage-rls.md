# REM-01: Storage Bucket RLS Configuration

## Problem

Supabase Storage buckets `avatars` and `post-images` are defined in `supabase_constants.dart` but have no RLS policies configured. Any authenticated user (or anyone with the anon key) could upload arbitrary files. This blocks avatar upload and post image features.

## Severity: CRITICAL

## Risk: Security + Feature Blocker

Without storage RLS:
- No file upload features can ship safely
- Avatar upload on profile edit is blocked
- Post image upload is blocked
- Any client could upload/overwrite files in any bucket

## Affected Modules

- Profile (avatar upload)
- Feed (post image upload)
- Auth (profile creation avatar)

## Architecture

Supabase Storage uses PostgreSQL RLS on the `storage.objects` table. Policies must be created via SQL migration or Supabase dashboard.

### Required Policies

**Bucket: `avatars`**
- Public read (anyone can view avatars)
- Authenticated insert: user can upload to `avatars/{user_id}/` path only
- Authenticated update: user can update own avatar only
- Authenticated delete: user can delete own avatar only
- Admin delete: admin can delete any avatar (for remove-user flow)

**Bucket: `post-images`**
- Authenticated read (only active members can view)
- Authenticated insert: user can upload to `post-images/{user_id}/` path only
- No public access

### Required Migration

New migration file: `20260624000001_configure_storage_buckets.sql`

```sql
-- Create buckets if not exist
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('post-images', 'post-images', false) ON CONFLICT DO NOTHING;

-- Avatars: public read
CREATE POLICY "avatars_public_read" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

-- Avatars: authenticated upload to own folder
CREATE POLICY "avatars_auth_insert" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Avatars: owner update
CREATE POLICY "avatars_auth_update" ON storage.objects FOR UPDATE USING (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Avatars: owner delete
CREATE POLICY "avatars_auth_delete" ON storage.objects FOR DELETE USING (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Post images: authenticated read
CREATE POLICY "postimages_auth_read" ON storage.objects FOR SELECT USING (
  bucket_id = 'post-images' AND auth.role() = 'authenticated'
);

-- Post images: authenticated upload to own folder
CREATE POLICY "postimages_auth_insert" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'post-images' AND auth.uid()::text = (storage.foldername(name))[1]
);
```

## Files Impacted

| File | Change |
|------|--------|
| `backend/supabase/migrations/20260624000001_configure_storage_buckets.sql` | NEW — bucket creation + RLS |
| `frontend/lib/features/profile/presentation/screens/edit_profile_screen.dart` | ADD — image picker + upload |
| `frontend/lib/features/feed/presentation/screens/create_post_screen.dart` | ADD — image picker + upload |
| `frontend/lib/shared/services/image_upload_service.dart` | NEW — shared upload helper |

## Dependencies

- Docker must be running (for migration)
- `image_picker` package already in pubspec.yaml
- Supabase Storage client already available via `supabase_flutter`

## Validation Steps

1. Run `supabase db reset` — migration applies
2. Run `supabase db diff` — zero drift
3. Upload test file via REST: `POST /storage/v1/object/avatars/{userId}/test.jpg`
4. Verify public read: `GET /storage/v1/object/public/avatars/{userId}/test.jpg`
5. Verify cross-user blocked: user A cannot upload to user B's folder
6. Verify anon blocked: unauthenticated upload returns 403

## Rollback Plan

Delete the migration file. Run `supabase db reset`. Storage returns to unconfigured state.

## Estimated Effort: 1-2 hours
