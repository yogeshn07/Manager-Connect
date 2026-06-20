# Supabase Project Setup Guide

## Overview

This guide covers the complete Supabase project configuration for Manager Connect — from local development to cloud deployment. Follow every step in order. Each step depends on the previous.

---

## 1. Local Development Setup

### Prerequisites

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| Docker Desktop | Running | `docker info` |
| Supabase CLI | Latest | `supabase --version` |
| Node.js | 18+ | `node --version` |
| Git | Any | `git --version` |

### Initialize Local Project

```bash
cd backend/supabase
supabase init          # Creates config.toml if not present
supabase start         # Starts PostgreSQL, Auth, Storage, Realtime, Edge Functions
```

**`supabase start` output provides:**

| Credential | Where to Record |
|------------|----------------|
| API URL | `.env.local` as `SUPABASE_URL` (typically `http://127.0.0.1:54321`) |
| Anon key | `.env.local` as `SUPABASE_ANON_KEY` |
| Service role key | `.env.local` as `SUPABASE_SERVICE_ROLE_KEY` |
| Studio URL | Browser at `http://127.0.0.1:54323` |
| DB URL | `postgresql://postgres:postgres@127.0.0.1:54322/postgres` |
| Inbucket URL | `http://127.0.0.1:54324` (captures OTP emails locally) |

### .env.local File

```bash
cp .env.local.example .env.local
```

Fill in all values from `supabase start` output. **Never commit `.env.local`.**

---

## 2. Cloud Project Setup

### Create Supabase Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click **New Project**
3. Settings:
   - **Organization:** Your org
   - **Project name:** `manager-connect-dev` (or `staging` / `prod`)
   - **Database password:** Generate a strong password — record it securely
   - **Region:** Choose closest to your users
   - **Plan:** Free tier is sufficient for development (15–20 users)

4. Wait for project to provision (~2 minutes)

### Link Local to Cloud

```bash
supabase link --project-ref <your-project-ref>
```

The project ref is in the Supabase dashboard URL: `supabase.com/dashboard/project/<ref>`.

---

## 3. Authentication Configuration

### Dashboard: Authentication → Providers

#### Email Provider

| Setting | Value | Reason |
|---------|-------|--------|
| Enable Email Provider | **ON** | OTP delivery via email |
| Enable Email Confirmations | **OFF** | OTP flow handles verification |
| Enable Email Signup | **OFF** | Invite-only — no self-registration |
| Secure Email Change | ON | Default |
| Minimum Password Length | N/A | Passwordless — not used |

#### Phone Provider

| Setting | Value | Reason |
|---------|-------|--------|
| Enable Phone Provider | **ON** | OTP delivery via SMS |
| SMS Provider | Twilio (or MessageBird) | Delivers OTP codes |
| Enable Phone Confirmations | **OFF** | OTP flow handles verification |
| Enable Phone Signup | **OFF** | Invite-only — no self-registration |

**SMS Provider Credentials (Twilio):**

| Field | Value |
|-------|-------|
| Account SID | From Twilio dashboard |
| Auth Token | From Twilio dashboard |
| Message Service SID | From Twilio Messaging Service |

**For local development:** No Twilio needed. Supabase local captures OTPs via Inbucket at `http://127.0.0.1:54324`.

### Dashboard: Authentication → Settings

| Setting | Value | Reason |
|---------|-------|--------|
| Site URL | `http://localhost:3000` (dev) / app deep link (prod) | Redirect after auth |
| JWT Expiry | `3600` (1 hour) | Access token lifetime |
| Refresh Token Rotation | **ON** | Single-use rotation for security |
| Refresh Token Reuse Interval | `10` seconds | Grace period for concurrent requests |
| OTP Expiry | `600` (10 minutes) | Matches `AppConstants.otpExpiryMinutes` |
| Rate Limits | Keep defaults | 15–20 users, no scaling concern |

### Dashboard: Authentication → URL Configuration

| Setting | Value |
|---------|-------|
| Site URL | `http://localhost:3000` |
| Redirect URLs | `com.managerconnect.managerconnect://callback` (mobile deep link) |

### Invite-Only Enforcement

Supabase Auth allows self-registration by default. Manager Connect blocks it at two levels:

1. **Auth level:** Disable email signup and phone signup in providers (above)
2. **Database level:** `profiles` INSERT is blocked by RLS — only service-role Edge Functions can create profiles
3. **Application level:** The `create-profile` Edge Function re-validates the invite token before creating the profile

---

## 4. Storage Bucket Configuration

### Dashboard: Storage → New Bucket

**Bucket 1: `avatars`**

| Setting | Value |
|---------|-------|
| Bucket name | `avatars` |
| Public bucket | **Yes** |
| File size limit | 2 MB |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp` |

**Bucket 2: `post-images`**

| Setting | Value |
|---------|-------|
| Bucket name | `post-images` |
| Public bucket | **No** (authenticated read) |
| File size limit | 5 MB |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp` |

### Storage RLS Policies

Configure via Dashboard → Storage → Policies, or via SQL after bucket creation:

**`avatars` bucket:**

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Public read | SELECT | `true` (anyone can read — CDN delivery) |
| Owner write | INSERT | `auth.uid()::text = (storage.foldername(name))[1]` (user can only upload to their own folder) |
| Owner update | UPDATE | Same as INSERT |
| Owner delete | DELETE | Same as INSERT |

**`post-images` bucket:**

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Authenticated read | SELECT | `auth.role() = 'authenticated'` |
| Author write | INSERT | `auth.uid()::text = (storage.foldername(name))[1]` |
| No update | UPDATE | `false` (images are immutable after upload) |
| No delete | DELETE | `false` (images persist with soft-deleted posts) |

---

## 5. Database Settings

### Dashboard: Database → Settings

| Setting | Value | Reason |
|---------|-------|--------|
| Connection Pooling | **ON** (Supavisor) | Required for Edge Functions |
| SSL Enforcement | **ON** | Production security |
| Network Restrictions | Configure per environment | Restrict to known IPs in production |

### Realtime Configuration

| Setting | Value |
|---------|-------|
| Enable Realtime | **ON** |
| Max Channels per Client | `10` (sufficient for 8 app channels) |
| Broadcast | Enabled |
| Presence | Disabled (not used) |

Realtime tables that need replication enabled:

| Table | Events |
|-------|--------|
| `posts` | INSERT |
| `post_reactions` | INSERT, UPDATE, DELETE |
| `comments` | INSERT |
| `activity_rsvps` | INSERT, UPDATE, DELETE |
| `poll_votes` | INSERT |
| `progress_logs` | INSERT, UPDATE |
| `recognitions` | INSERT |
| `notification_inbox` | INSERT |

Enable via Dashboard → Database → Replication, or via SQL:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE post_reactions;
-- ... repeat for each table
```

---

## 6. Environment Variable Checklist

### Flutter App (`--dart-define`)

| Variable | Required | Source |
|----------|----------|--------|
| `SUPABASE_URL` | Yes | Supabase Dashboard → Settings → API |
| `SUPABASE_ANON_KEY` | Yes | Supabase Dashboard → Settings → API |

**Launch command:**
```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### Edge Functions (Supabase Secrets)

| Secret | Required | When | Source |
|--------|----------|------|--------|
| `SUPABASE_URL` | Auto-injected | Always | Supabase platform |
| `SUPABASE_ANON_KEY` | Auto-injected | Always | Supabase platform |
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-injected | Always | Supabase platform |
| `FCM_SERVER_KEY` | Yes | Sprint 5 (notifications) | Firebase Console → Project Settings → Cloud Messaging |

Set via CLI:
```bash
supabase secrets set FCM_SERVER_KEY=your-key-here
```

### Local Development (`.env.local`)

| Variable | Value |
|----------|-------|
| `SUPABASE_URL` | `http://127.0.0.1:54321` |
| `SUPABASE_ANON_KEY` | From `supabase start` output |
| `SUPABASE_SERVICE_ROLE_KEY` | From `supabase start` output |

### CI/CD (GitHub Actions Secrets)

| Secret | Purpose |
|--------|---------|
| `SUPABASE_ACCESS_TOKEN` | CLI authentication for `supabase link` |
| `SUPABASE_PROJECT_REF` | Target project reference |
| `SUPABASE_DB_PASSWORD` | Database password for migrations |

---

## 7. Connect Buddy System Account

The Connect Buddy profile requires an `auth.users` entry. This is created BEFORE the seed migration.

### Local Development

```bash
# Using Supabase Management API with service role key
curl -X POST 'http://127.0.0.1:54321/auth/v1/admin/users' \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "apikey: <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "00000000-0000-4000-8000-000000000001",
    "phone": "+00000000000",
    "phone_confirm": true,
    "user_metadata": {"is_system_account": true}
  }'
```

### Cloud Deployment

Same API call against the cloud project URL:
```bash
curl -X POST 'https://<ref>.supabase.co/auth/v1/admin/users' \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "apikey: <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "00000000-0000-4000-8000-000000000001",
    "phone": "+00000000000",
    "phone_confirm": true,
    "user_metadata": {"is_system_account": true}
  }'
```

**The UUID `00000000-0000-4000-8000-000000000001` must match:**
- `seed.sql` INSERT
- `_shared/constants.ts` → `CONNECT_BUDDY_PROFILE_ID`
- `app_constants.dart` → `connectBuddySystemAccountId`

---

## 8. Deployment Sequence (Per Environment)

Execute in this exact order for each new environment (dev, staging, prod):

```
 1. Create Supabase project (Dashboard)
 2. Link local: supabase link --project-ref <ref>
 3. Configure Auth providers (Dashboard)
 4. Configure Auth settings (Dashboard)
 5. Apply migrations: supabase db push --linked
 6. Create Connect Buddy auth.users entry (API call)
 7. Apply seed: supabase db push --linked (Phase 9 migration)
 8. Create storage buckets (Dashboard)
 9. Configure storage RLS policies (Dashboard)
10. Enable Realtime replication on 8 tables (Dashboard)
11. Deploy Edge Functions: supabase functions deploy
12. Set Edge Function secrets: supabase secrets set ...
13. Verify: 26 tables with RLS enabled
14. Verify: 2 storage buckets accessible
15. Verify: Edge Functions responding
16. Run RLS smoke tests
```
