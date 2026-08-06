# Production Supabase Setup

## 1. Project Creation

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. **Organization:** Create or select your org
4. **Project name:** `manager-connect-prod`
5. **Database password:** Generate strong password, store in password manager
6. **Region:** Choose closest to your users (e.g., `ap-south-1` for India)
7. **Pricing plan:** Pro ($25/month) recommended for pilot

Record these values immediately:

| Value | Where to Find | Store In |
|-------|--------------|----------|
| Project URL | Settings → API → Project URL | `.env`, CI/CD secrets |
| Anon Key | Settings → API → `anon` `public` | `.env`, CI/CD secrets, dart-define |
| Service Role Key | Settings → API → `service_role` `secret` | CI/CD secrets ONLY, never in client |
| Database Password | Set during creation | Password manager |
| JWT Secret | Settings → API → JWT Secret | Edge Function secrets |

## 2. Auth Configuration

### Settings → Authentication → Providers

| Setting | Value |
|---------|-------|
| Enable Email | ON |
| Enable Phone | OFF (unless SMS provider configured) |
| Confirm Email | ON |
| Enable Sign Up | OFF (invite-only — users register via invitation flow) |
| Minimum Password Length | N/A (OTP-based, no passwords) |

### Settings → Authentication → URL Configuration

| Setting | Value |
|---------|-------|
| Site URL | `https://your-domain.com` |
| Redirect URLs | `https://your-domain.com`, `http://localhost:4200` (dev) |

### Settings → Authentication → Email Templates

Customize the OTP email template to include a 6-digit code instead of magic link:

**Subject:** `Your Manager Connect verification code`
**Body:** Include `{{ .Token }}` as the OTP code

## 3. Storage Configuration

Buckets are created by migration. Verify after deployment:

| Bucket | Public | Size Limit |
|--------|--------|-----------|
| `avatars` | Yes | 2 MB |
| `post-images` | No | 5 MB |

## 4. Migration Deployment

### First-time setup

```bash
# Link to production project
supabase link --project-ref <project-ref>

# Push all migrations
supabase db push

# Verify
supabase db diff --linked
```

### Subsequent migrations

```bash
# Create migration locally
supabase migration new <name>

# Test locally
supabase db reset

# Push to production
supabase db push
```

### Edge Function deployment

```bash
# Deploy all functions
supabase functions deploy --project-ref <project-ref>

# Deploy single function
supabase functions deploy send-notification --project-ref <project-ref>
```

### Edge Function secrets

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<key> --project-ref <ref>
supabase secrets set FCM_SERVER_KEY=<key> --project-ref <ref>
```

## 5. RLS Verification

After `db push`, verify:

```sql
-- Run via Supabase SQL Editor
SELECT schemaname, tablename, count(*) 
FROM pg_policies 
WHERE schemaname IN ('public', 'storage')
GROUP BY schemaname, tablename 
ORDER BY schemaname, tablename;
```

Expected: 114 public policies + 8 storage policies = 122 total.

## 6. Rollback Strategy

### Database rollback

Supabase cloud provides point-in-time recovery (Pro plan):
- RPO: 1 minute
- Restore to any point in last 7 days

### Migration rollback

Migrations are forward-only. To "rollback":
1. Create a new migration that reverses the changes
2. Push the reversal migration

### Edge Function rollback

```bash
# Redeploy previous version from git
git checkout <previous-commit> -- backend/supabase/functions/<function-name>
supabase functions deploy <function-name>
```

## 7. Production Checklist

- [ ] Project created on Supabase cloud
- [ ] Database password stored securely
- [ ] All API keys recorded
- [ ] Auth settings configured (email, site URL, redirects)
- [ ] Migrations pushed (`supabase db push`)
- [ ] Edge Functions deployed (all 21)
- [ ] Edge Function secrets set (service role key, FCM key)
- [ ] Storage buckets verified (avatars + post-images)
- [ ] RLS policy count verified (122)
- [ ] Realtime publication verified (8 tables)
- [ ] Connect Buddy seed data applied
- [ ] Test login with admin account
