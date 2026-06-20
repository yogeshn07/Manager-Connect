# Database Execution Plan

## Overview

This document specifies the exact order to execute all 72 database migrations, the verification checkpoints after each phase, and the safety procedures for each environment. It is the operational runbook for database deployment.

**Source of truth for SQL content:** `database-schema-design.md`
**Source of truth for execution order:** `database-migrations-plan.md`
**Source of truth for RLS policies:** `rls-security-policies.md`

---

## Execution Prerequisites

Before creating any migration file:

- [ ] Docker Desktop running
- [ ] `supabase start` completed successfully
- [ ] Supabase Studio accessible at `http://127.0.0.1:54323`
- [ ] `.env.local` populated with credentials from `supabase status`
- [ ] `backend/supabase/migrations/` directory exists

---

## Migration Creation Workflow

For each migration:

```bash
# 1. Create the migration file (Supabase CLI assigns timestamp)
supabase migration new <descriptive_name>

# 2. Write SQL in the created file
#    Reference: database-schema-design.md for columns/constraints
#    Reference: rls-security-policies.md for policy conditions

# 3. Apply to local
supabase db push

# 4. Verify in Studio (http://127.0.0.1:54323)

# 5. If wrong, reset and fix
supabase db reset    # drops and replays all migrations
```

---

## Phase 0: Foundation (Migrations 1–3)

### Execution

| Order | CLI Command | SQL Content |
|-------|-------------|-------------|
| 1 | `supabase migration new enable_extensions` | `CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; CREATE EXTENSION IF NOT EXISTS "pgcrypto";` |
| 2 | `supabase migration new create_update_timestamp_trigger` | Create `update_updated_at_column()` function |
| 3 | `supabase migration new create_is_admin_helper` | Create `is_admin()` function with `SECURITY DEFINER` |

### Apply

```bash
supabase db push
```

### Verification Checkpoint 0

| Check | How | Expected |
|-------|-----|----------|
| Extensions enabled | `SELECT extname FROM pg_extension;` | `uuid-ossp` and `pgcrypto` present |
| UUID generation works | `SELECT gen_random_uuid();` | Returns a UUID |
| Trigger function exists | `SELECT proname FROM pg_proc WHERE proname = 'update_updated_at_column';` | 1 row |
| Admin helper exists | `SELECT is_admin();` | Returns `false` (no profiles yet) |

### Rollback

```bash
supabase db reset   # Replays from scratch — acceptable in Phase 0
```

---

## Phase 1: Identity Layer (Migrations 4–9)

### Execution

| Order | Migration Name | Creates |
|-------|---------------|---------|
| 4 | `create_profiles_table` | `profiles` table + `ALTER TABLE profiles ENABLE ROW LEVEL SECURITY` |
| 5 | `create_profiles_rls_policies` | 5 RLS policies |
| 6 | `create_profiles_updated_at_trigger` | Trigger attachment |
| 7 | `create_invitations_table` | `invitations` table + RLS enabled |
| 8 | `create_invitations_rls_policies` | 4 RLS policies |
| 9 | `create_invitations_updated_at_trigger` | Trigger attachment |

### Apply

```bash
supabase db push
```

### Verification Checkpoint 1

| Check | How | Expected |
|-------|-----|----------|
| Tables exist | Studio → Table Editor | `profiles` and `invitations` visible |
| RLS enabled | Studio → Table Editor → RLS badge | Both tables show "RLS Enabled" |
| Trigger works | INSERT a profile row, UPDATE it, check `updated_at` | `updated_at` > `created_at` |
| RLS blocks anon | Query profiles with anon key | 0 rows returned |
| Policy count | `SELECT count(*) FROM pg_policies WHERE tablename IN ('profiles','invitations');` | 9 |

### Rollback

```bash
supabase db reset   # Safe — no user data yet
```

---

## Phase 2: Feed Layer (Migrations 10–21)

### Execution

| Order | Migration Name | Creates |
|-------|---------------|---------|
| 10 | `create_posts_table` | `posts` table |
| 11 | `create_posts_rls_policies` | 6 RLS policies |
| 12 | `create_posts_updated_at_trigger` | Trigger |
| 13 | `create_post_images_table` | `post_images` table |
| 14 | `create_post_images_rls_policies` | 4 RLS policies |
| 15 | `create_post_reactions_table` | `post_reactions` table (with `updated_at`) |
| 16 | `create_post_reactions_rls_policies` | 4 RLS policies |
| 16b | `create_post_reactions_updated_at_trigger` | Trigger |
| 17 | `create_comments_table` | `comments` table |
| 18 | `create_comments_rls_policies` | 6 RLS policies |
| 19 | `create_comments_updated_at_trigger` | Trigger |
| 20 | `create_post_mentions_table` | `post_mentions` table |
| 21 | `create_post_mentions_rls_policies` | 4 RLS policies (service_role only INSERT) |

### Apply

```bash
supabase db push
```

### Verification Checkpoint 2

| Check | How | Expected |
|-------|-----|----------|
| Tables exist | Studio | 5 new tables: posts, post_images, post_reactions, comments, post_mentions |
| RLS on all | Studio badges | All 5 show "RLS Enabled" |
| Soft delete works | INSERT post, set `is_deleted=true`, SELECT as member | Post not visible |
| UNIQUE enforced | INSERT two reactions for same (post_id, user_id) | Constraint violation |
| FK cascade | DELETE a post, check post_images | Images deleted (CASCADE) |
| Cumulative table count | `SELECT count(*) FROM information_schema.tables WHERE table_schema='public';` | 7 |

### Rollback

```bash
supabase db reset
```

---

## Phase 3: Events Layer (Migrations 22–39b)

### Execution

| Order | Migration Name | Creates |
|-------|---------------|---------|
| 22 | `create_activities_table` | `activities` table |
| 23 | `create_activities_rls_policies` | 4 RLS policies |
| 24 | `create_activities_updated_at_trigger` | Trigger |
| 25 | `create_activity_rsvps_table` | `activity_rsvps` table |
| 26 | `create_activity_rsvps_rls_policies` | 4 RLS policies |
| 27 | `create_activity_rsvps_updated_at_trigger` | Trigger |
| 28 | `create_activity_updates_table` | `activity_updates` table (no trigger — append-only) |
| 29 | `create_activity_updates_rls_policies` | 4 RLS policies |
| 30 | `create_polls_table` | `polls` table |
| 32 | `create_polls_rls_policies` | 4 RLS policies |
| 33 | `create_polls_updated_at_trigger` | Trigger |
| 34 | `create_poll_options_table` | `poll_options` table |
| 35 | `create_poll_options_rls_policies` | 4 RLS policies |
| 36 | `create_poll_votes_table` | `poll_votes` table |
| 37 | `create_poll_votes_rls_policies` | 4 RLS policies |
| 38 | `create_event_attendance_table` | `event_attendance` table (with `updated_at`) |
| 39 | `create_event_attendance_rls_policies` | 4 RLS policies |
| 39b | `create_event_attendance_updated_at_trigger` | Trigger |

### Apply

```bash
supabase db push
```

### Verification Checkpoint 3

| Check | How | Expected |
|-------|-----|----------|
| Tables exist | Studio | 7 new tables |
| RSVP UNIQUE | INSERT duplicate (activity_id, user_id) | Constraint violation |
| Poll vote UNIQUE | INSERT duplicate (poll_id, user_id) | Constraint violation |
| Event category CHECK | INSERT activity with `event_category='invalid'` | CHECK violation |
| Attendance status CHECK | INSERT attendance with `status='invalid'` | CHECK violation |
| `is_closed` default | INSERT poll without `is_closed` | Defaults to `false` |
| Cumulative table count | Count | 14 |

### Rollback

```bash
supabase db reset
```

---

## Phase 4: Growth Layer (Migrations 40–46b)

### Execution

| Order | Migration Name | Creates |
|-------|---------------|---------|
| 40 | `create_challenges_table` | `challenges` table |
| 41 | `create_challenges_rls_policies` | 4 RLS policies |
| 42 | `create_challenges_updated_at_trigger` | Trigger |
| 43 | `create_challenge_participants_table` | `challenge_participants` table |
| 44 | `create_challenge_participants_rls_policies` | 4 RLS policies |
| 45 | `create_progress_logs_table` | `progress_logs` table (with `updated_at`) |
| 46 | `create_progress_logs_rls_policies` | 5 RLS policies |
| 46b | `create_progress_logs_updated_at_trigger` | Trigger |

### Verification Checkpoint 4

| Check | How | Expected |
|-------|-----|----------|
| Tables exist | Studio | 3 new tables |
| End date CHECK | INSERT challenge with `end_date < start_date` | CHECK violation |
| Progress value CHECK | INSERT progress_log with `value = -1` | CHECK violation |
| Daily log UNIQUE | INSERT two logs for same (challenge_id, user_id, log_date) | Constraint violation |
| Cumulative table count | Count | 17 |

---

## Phase 5: Recognition Layer (Migrations 47–53b)

### Execution

| Order | Migration Name | Creates |
|-------|---------------|---------|
| 47 | `create_recognitions_table` | `recognitions` table |
| 48 | `create_recognitions_rls_policies` | 6 RLS policies |
| 49 | `create_recognitions_updated_at_trigger` | Trigger |
| 50 | `create_recognition_recipients_table` | `recognition_recipients` table |
| 51 | `create_recognition_recipients_rls_policies` | 4 RLS policies |
| 52 | `create_recognition_reactions_table` | `recognition_reactions` table (with `updated_at`) |
| 53 | `create_recognition_reactions_rls_policies` | 4 RLS policies |
| 53b | `create_recognition_reactions_updated_at_trigger` | Trigger |

### Verification Checkpoint 5

| Check | How | Expected |
|-------|-----|----------|
| Tables exist | Studio | 3 new tables |
| Category tag CHECK | INSERT recognition with `category_tag='invalid'` | CHECK violation |
| Valid category tags | INSERT with `category_tag='fitness_champion'` | Succeeds |
| Cumulative table count | Count | 20 |

---

## Phase 6: Analytics Layer (Migrations 54–58)

### Execution

| Order | Migration Name | Creates |
|-------|---------------|---------|
| 54 | `create_member_monthly_stats_table` | `member_monthly_stats` table |
| 55 | `create_member_monthly_stats_rls_policies` | 4 RLS policies (SELECT all authenticated; INSERT/UPDATE/DELETE blocked) |
| 56 | `create_member_monthly_stats_updated_at_trigger` | Trigger |
| 57 | `create_community_health_scores_table` | `community_health_scores` table (no `updated_at`) |
| 58 | `create_community_health_scores_rls_policies` | 4 RLS policies |

### Verification Checkpoint 6

| Check | How | Expected |
|-------|-----|----------|
| Tables exist | Studio | 2 new tables |
| Member can read all stats | SELECT as non-admin member | All rows visible (rankings requirement) |
| Client INSERT blocked | INSERT as authenticated user | RLS blocks (service_role only) |
| Score range CHECK | INSERT health score with `score=150` | CHECK violation (max 100) |
| Cumulative table count | Count | 22 |

---

## Phase 7: Notifications Layer (Migrations 60–61)

### Execution

| Order | Migration Name | Creates |
|-------|---------------|---------|
| 60 | `create_notification_inbox_table` | `notification_inbox` table (no `updated_at`) |
| 61 | `create_notification_inbox_rls_policies` | 4 RLS policies |

### Verification Checkpoint 7

| Check | How | Expected |
|-------|-----|----------|
| Table exists | Studio | 1 new table |
| Own rows only | SELECT as user A, check for user B's rows | 0 rows from user B |
| Type CHECK | INSERT with `type='invalid'` | CHECK violation |
| Client INSERT blocked | INSERT as authenticated user | RLS blocks |
| Cumulative table count | Count | 23 |

---

## Phase 8: Admin Layer (Migrations 62–69)

### Execution

| Order | Migration Name | Creates |
|-------|---------------|---------|
| 62 | `create_flagged_content_table` | `flagged_content` table |
| 63 | `create_flagged_content_rls_policies` | 4 RLS policies |
| 64 | `create_flagged_content_updated_at_trigger` | Trigger |
| 65 | `create_pinned_announcements_table` | `pinned_announcements` table |
| 66 | `create_pinned_announcements_rls_policies` | 4 RLS policies |
| 67 | `create_pinned_announcements_updated_at_trigger` | Trigger |
| 68 | `create_admin_audit_log_table` | `admin_audit_log` table (no `updated_at`, no `created_at`) |
| 69 | `create_admin_audit_log_rls_policies` | 4 RLS policies |

### Verification Checkpoint 8

| Check | How | Expected |
|-------|-----|----------|
| Tables exist | Studio | 3 new tables |
| Audit log immutable | UPDATE audit_log row | RLS blocks |
| Audit log member-blocked | SELECT as member | 0 rows |
| Flagged content admin-only SELECT | SELECT as member | 0 rows |
| Action type CHECK | INSERT audit with `action_type='invalid'` | CHECK violation |
| Cumulative table count | Count | **26** (all tables complete) |

---

## Phase 9: Seed Data (Migration 70)

### Pre-Seed Requirement

Before applying the seed migration, create the Connect Buddy `auth.users` entry:

```bash
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

### Execution

| Order | Migration Name | Creates |
|-------|---------------|---------|
| 70 | `seed_connect_buddy_profile` | 1 row in `profiles` |

### Apply

```bash
supabase db push
```

### Verification Checkpoint 9 (Final)

| Check | How | Expected |
|-------|-----|----------|
| CB profile exists | `SELECT * FROM profiles WHERE is_system_account = true;` | 1 row |
| CB UUID correct | Check `id` column | `00000000-0000-4000-8000-000000000001` |
| CB role correct | Check `app_role` | `system` |
| CB is active | Check `is_active` | `true` |
| CB onboarding done | Check `onboarding_completed` | `true` |

---

## Post-Migration Verification (Complete Schema)

Run after all 72 migrations are applied:

### Table Count

```sql
SELECT count(*) FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
```
**Expected: 26**

### RLS Coverage

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND tablename NOT LIKE 'pg_%';
```
**Expected: All 26 rows show `rowsecurity = true`**

### Trigger Count

```sql
SELECT count(DISTINCT trigger_name)
FROM information_schema.triggers
WHERE trigger_schema = 'public';
```
**Expected: 16**

### Policy Count

```sql
SELECT count(*) FROM pg_policies WHERE schemaname = 'public';
```
**Expected: ~110** (varies by exact policy count — at least 4 per table)

### Function Count

```sql
SELECT proname FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND proname IN ('update_updated_at_column', 'is_admin');
```
**Expected: 2 rows**

---

## Production Safety Checklist

Before pushing migrations to production:

- [ ] All migrations applied and verified on local (`supabase db reset` + `supabase db push`)
- [ ] All migrations applied and verified on staging
- [ ] RLS smoke tests pass on staging (member, admin, deactivated, anon personas)
- [ ] No migration contains `DROP TABLE`, `TRUNCATE`, or `DELETE` statements
- [ ] No migration modifies `auth.users` (managed by Supabase Auth, not migrations)
- [ ] Every table creation includes `ENABLE ROW LEVEL SECURITY`
- [ ] Every FK reference targets a table created in an earlier migration
- [ ] Every CHECK constraint value matches the application-layer enum (case-sensitive)
- [ ] `supabase db diff` shows no drift between migration files and live schema
- [ ] Connect Buddy `auth.users` entry created before seed migration
- [ ] Edge Functions deployed AFTER all migrations (functions depend on tables)
- [ ] Team notified of deployment window (if production)

---

## Quick Reference: Migration Summary

| Phase | Migrations | Tables Created | Triggers | RLS Policy Files | Cumulative Tables |
|-------|-----------|---------------|----------|-----------------|-------------------|
| 0 | 1–3 | 0 | 0 | 0 | 0 |
| 1 | 4–9 | 2 | 2 | 2 | 2 |
| 2 | 10–21 | 5 | 4 | 5 | 7 |
| 3 | 22–39b | 7 | 4 | 7 | 14 |
| 4 | 40–46b | 3 | 3 | 3 | 17 |
| 5 | 47–53b | 3 | 3 | 3 | 20 |
| 6 | 54–58 | 2 | 1 | 2 | 22 |
| 7 | 60–61 | 1 | 0 | 1 | 23 |
| 8 | 62–69 | 3 | 3 | 3 | 26 |
| 9 | 70 | 0 (seed) | 0 | 0 | 26 |
| **Total** | **72** | **26** | **16** | **26** | **26** |
