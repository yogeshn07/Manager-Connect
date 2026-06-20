# Database Implementation Checklist

## Audit Summary

| Artifact | Count | Source of Truth |
|----------|-------|----------------|
| Tables | **26** | `database-schema-design.md` |
| Migrations | **72** (across 10 phases) | `database-migrations-plan.md` |
| Functions | **2** (`update_updated_at_column`, `is_admin`) | `database-schema-design.md` Trigger Specification |
| Extensions | **2** (`uuid-ossp`, `pgcrypto`) | Migration #1 |
| Triggers | **16** (one per mutable table) | `database-schema-design.md` Trigger Specification |
| Tables without triggers | **10** (append-only or immutable) | `database-schema-design.md` |
| RLS policies | **26 tables covered** (120 individual policy rules) | `rls-security-policies.md` |
| Storage buckets | **2** (`avatars`, `post-images`) | `database-schema-design.md` Storage Buckets |
| Edge Functions | **21** | `backend-api-contracts.md` |
| Seed data | **1** (Connect Buddy profile) | Migration #70 |

---

## Step-by-Step Execution Plan

### Pre-Implementation (One-Time Setup)

| Step | Action | Verification |
|------|--------|-------------|
| P1 | Install Supabase CLI: `npm install -g supabase` | `supabase --version` returns version |
| P2 | Start local Supabase: `supabase start` | All services healthy in terminal output |
| P3 | Record local credentials from `supabase status` output: API URL, anon key, service role key | Copy to `backend/supabase/.env.local` |
| P4 | Verify PostgreSQL is accessible: `psql` or Supabase Studio at `http://localhost:54323` | Can query `SELECT 1` |
| P5 | Link to cloud project: `supabase link --project-ref <ref>` (if cloud project exists) | Link confirmation message |

---

### Phase 0: Foundation (3 migrations)

| # | Migration | What It Creates | Depends On |
|---|-----------|----------------|-----------|
| 1 | `enable_extensions.sql` | `uuid-ossp`, `pgcrypto` extensions | Nothing |
| 2 | `create_update_timestamp_trigger.sql` | `update_updated_at_column()` function | Nothing |
| 3 | `create_is_admin_helper.sql` | `is_admin()` SECURITY DEFINER function | Nothing |

**Verification:** Run `SELECT is_admin();` — should return false (no profiles yet). Run `SELECT gen_random_uuid();` — should return a UUID.

---

### Phase 1: Identity Layer (6 migrations)

| # | Migration | What It Creates | Depends On |
|---|-----------|----------------|-----------|
| 4 | `create_profiles_table.sql` | `profiles` table + RLS enabled | Extensions (#1) |
| 5 | `create_profiles_rls_policies.sql` | 5 RLS policies on `profiles` | `profiles` (#4), `is_admin()` (#3) |
| 6 | `create_profiles_updated_at_trigger.sql` | Trigger on `profiles` | `update_updated_at_column()` (#2), `profiles` (#4) |
| 7 | `create_invitations_table.sql` | `invitations` table + RLS enabled | `profiles` (#4) |
| 8 | `create_invitations_rls_policies.sql` | 4 RLS policies on `invitations` | `invitations` (#7), `is_admin()` (#3) |
| 9 | `create_invitations_updated_at_trigger.sql` | Trigger on `invitations` | `update_updated_at_column()` (#2), `invitations` (#7) |

**Verification:** Insert a test profile row via service role. Verify `updated_at` auto-updates on `UPDATE`. Verify RLS blocks anonymous SELECT.

---

### Phase 2: Feed Layer (13 migrations)

| # | Migration | What It Creates | Depends On |
|---|-----------|----------------|-----------|
| 10 | `create_posts_table.sql` | `posts` table + RLS enabled | `profiles` (#4) |
| 11 | `create_posts_rls_policies.sql` | 6 RLS policies on `posts` | `posts` (#10), `is_admin()` (#3) |
| 12 | `create_posts_updated_at_trigger.sql` | Trigger on `posts` | #2, #10 |
| 13 | `create_post_images_table.sql` | `post_images` table + RLS enabled | `posts` (#10) |
| 14 | `create_post_images_rls_policies.sql` | 4 RLS policies on `post_images` | #13, #10 |
| 15 | `create_post_reactions_table.sql` | `post_reactions` table + RLS enabled | `posts` (#10), `profiles` (#4) |
| 16 | `create_post_reactions_rls_policies.sql` | 4 RLS policies on `post_reactions` | #15 |
| 16b | `create_post_reactions_updated_at_trigger.sql` | Trigger on `post_reactions` | #2, #15 |
| 17 | `create_comments_table.sql` | `comments` table + RLS enabled | `posts` (#10), `profiles` (#4) |
| 18 | `create_comments_rls_policies.sql` | 6 RLS policies on `comments` | #17, #10, `is_admin()` (#3) |
| 19 | `create_comments_updated_at_trigger.sql` | Trigger on `comments` | #2, #17 |
| 20 | `create_post_mentions_table.sql` | `post_mentions` table + RLS enabled | `posts` (#10), `profiles` (#4) |
| 21 | `create_post_mentions_rls_policies.sql` | 4 RLS policies on `post_mentions` | #20 |

**Verification:** 5 tables created. Insert a post, add a reaction, verify soft-delete hides from member SELECT.

---

### Phase 3: Events Layer (18 migrations)

| # | Migration | What It Creates | Depends On |
|---|-----------|----------------|-----------|
| 22 | `create_activities_table.sql` | `activities` table | `profiles` (#4) |
| 23 | `create_activities_rls_policies.sql` | 4 RLS policies | #22, #3 |
| 24 | `create_activities_updated_at_trigger.sql` | Trigger | #2, #22 |
| 25 | `create_activity_rsvps_table.sql` | `activity_rsvps` table | `activities` (#22), `profiles` (#4) |
| 26 | `create_activity_rsvps_rls_policies.sql` | 4 RLS policies | #25 |
| 27 | `create_activity_rsvps_updated_at_trigger.sql` | Trigger | #2, #25 |
| 28 | `create_activity_updates_table.sql` | `activity_updates` table (no updated_at) | `activities` (#22), `profiles` (#4) |
| 29 | `create_activity_updates_rls_policies.sql` | 4 RLS policies | #28, #3 |
| 30 | `create_polls_table.sql` | `polls` table | `activities` (#22), `profiles` (#4) |
| 32 | `create_polls_rls_policies.sql` | 4 RLS policies | #30, #3 |
| 33 | `create_polls_updated_at_trigger.sql` | Trigger | #2, #30 |
| 34 | `create_poll_options_table.sql` | `poll_options` table | `polls` (#30) |
| 35 | `create_poll_options_rls_policies.sql` | 4 RLS policies | #34, #3 |
| 36 | `create_poll_votes_table.sql` | `poll_votes` table | `polls` (#30), `poll_options` (#34), `profiles` (#4) |
| 37 | `create_poll_votes_rls_policies.sql` | 4 RLS policies | #36 |
| 38 | `create_event_attendance_table.sql` | `event_attendance` table | `activities` (#22), `profiles` (#4) |
| 39 | `create_event_attendance_rls_policies.sql` | 4 RLS policies | #38, #3 |
| 39b | `create_event_attendance_updated_at_trigger.sql` | Trigger | #2, #38 |

**Verification:** 7 tables created. Create activity, RSVP, verify UNIQUE constraint on (activity_id, user_id).

---

### Phase 4: Growth Layer (8 migrations)

| # | Migration | Depends On |
|---|-----------|-----------|
| 40 | `create_challenges_table.sql` | `profiles` (#4) |
| 41 | `create_challenges_rls_policies.sql` | #40, #3 |
| 42 | `create_challenges_updated_at_trigger.sql` | #2, #40 |
| 43 | `create_challenge_participants_table.sql` | `challenges` (#40), `profiles` (#4) |
| 44 | `create_challenge_participants_rls_policies.sql` | #43 |
| 45 | `create_progress_logs_table.sql` | `challenges` (#40), `challenge_participants` (#43), `profiles` (#4) |
| 46 | `create_progress_logs_rls_policies.sql` | #45 |
| 46b | `create_progress_logs_updated_at_trigger.sql` | #2, #45 |

**Verification:** 3 tables. Join challenge, log progress, verify UNIQUE(challenge_id, user_id, log_date).

---

### Phase 5: Recognition Layer (8 migrations)

| # | Migration | Depends On |
|---|-----------|-----------|
| 47 | `create_recognitions_table.sql` | `profiles` (#4) |
| 48 | `create_recognitions_rls_policies.sql` | #47, #3 |
| 49 | `create_recognitions_updated_at_trigger.sql` | #2, #47 |
| 50 | `create_recognition_recipients_table.sql` | `recognitions` (#47), `profiles` (#4) |
| 51 | `create_recognition_recipients_rls_policies.sql` | #50 |
| 52 | `create_recognition_reactions_table.sql` | `recognitions` (#47), `profiles` (#4) |
| 53 | `create_recognition_reactions_rls_policies.sql` | #52 |
| 53b | `create_recognition_reactions_updated_at_trigger.sql` | #2, #52 |

**Verification:** 3 tables. Give recognition, verify category_tag CHECK constraint.

---

### Phase 6: Analytics Layer (5 migrations)

| # | Migration | Depends On |
|---|-----------|-----------|
| 54 | `create_member_monthly_stats_table.sql` | `profiles` (#4) |
| 55 | `create_member_monthly_stats_rls_policies.sql` | #54 |
| 56 | `create_member_monthly_stats_updated_at_trigger.sql` | #2, #54 |
| 57 | `create_community_health_scores_table.sql` | Nothing (no FKs) |
| 58 | `create_community_health_scores_rls_policies.sql` | #57 |

**Verification:** 2 tables. Verify member can SELECT all member_monthly_stats rows (rankings). Verify service_role-only INSERT.

---

### Phase 7: Notifications Layer (2 migrations)

| # | Migration | Depends On |
|---|-----------|-----------|
| 60 | `create_notification_inbox_table.sql` | `profiles` (#4) |
| 61 | `create_notification_inbox_rls_policies.sql` | #60 |

**Verification:** 1 table. Verify member can only SELECT own notifications.

---

### Phase 8: Admin Layer (8 migrations)

| # | Migration | Depends On |
|---|-----------|-----------|
| 62 | `create_flagged_content_table.sql` | `profiles` (#4) |
| 63 | `create_flagged_content_rls_policies.sql` | #62, #3 |
| 64 | `create_flagged_content_updated_at_trigger.sql` | #2, #62 |
| 65 | `create_pinned_announcements_table.sql` | `posts` (#10), `profiles` (#4) |
| 66 | `create_pinned_announcements_rls_policies.sql` | #65, #3 |
| 67 | `create_pinned_announcements_updated_at_trigger.sql` | #2, #65 |
| 68 | `create_admin_audit_log_table.sql` | `profiles` (#4) |
| 69 | `create_admin_audit_log_rls_policies.sql` | #68, #3 |

**Verification:** 3 tables. Verify admin_audit_log has no UPDATE/DELETE policies. Verify flagged_content SELECT is admin-only.

---

### Phase 9: Seed Data (1 migration)

| # | Migration | Depends On |
|---|-----------|-----------|
| 70 | `seed_connect_buddy_profile.sql` | `profiles` (#4) |

**Verification:** `SELECT * FROM profiles WHERE is_system_account = true` returns 1 row with id `00000000-0000-4000-8000-000000000001`.

---

### Post-Migration: Storage Buckets

| Order | Bucket | Public? | Max File Size | Allowed MIME Types | Write Access |
|-------|--------|---------|---------------|-------------------|-------------|
| 1 | `avatars` | Yes (public read) | 2 MB | image/jpeg, image/png, image/webp | Owner only (`auth.uid() = user_id` in path) |
| 2 | `post-images` | No (authenticated read) | 5 MB | image/jpeg, image/png, image/webp | Post author only |

**Creation method:** Supabase Dashboard → Storage → New Bucket, or via SQL in a migration:
```
-- Not a migration — manual or via Supabase Dashboard
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('post-images', 'post-images', false);
```

Storage RLS policies are separate from table RLS — they are configured on `storage.objects` via the Dashboard or SQL.

**Verification:** Upload a test file to each bucket. Verify public URL works for `avatars`. Verify unauthenticated access is blocked for `post-images`.

---

### Post-Migration: Edge Function Deployment Order

Edge Functions are deployed AFTER all migrations. The deployment order follows sprint alignment and internal dependency chains.

**Sprint 1 (Auth + Feed):**

| Order | Function | Auth | Called By |
|-------|----------|------|----------|
| 1 | `send-notification` | Service role only | All other EFs (internal) |
| 2 | `validate-invite-token` | Public (no JWT) | Mobile app |
| 3 | `send-invitation` | Admin JWT | Admin panel |
| 4 | `create-profile` | User JWT | Mobile app |
| 5 | `post-connect-buddy-message` | Service role only | Other EFs (internal) |
| 6 | `create-post` | User JWT | Mobile app |

**Sprint 2 (Events):**

| Order | Function | Auth |
|-------|----------|------|
| 7 | `cancel-activity` | Creator/Admin JWT |
| 8 | `post-activity-update` | Creator JWT |
| 9 | `create-poll` | User JWT |
| 10 | `close-poll` | Service role / Admin |

**Sprint 3 (Growth + Attendance):**

| Order | Function | Auth |
|-------|----------|------|
| 11 | `close-challenge` | Service role / Admin |
| 12 | `record-attendance` | Admin JWT |

**Sprint 4 (Analytics + Recognition + CB):**

| Order | Function | Auth |
|-------|----------|------|
| 13 | `create-recognition` | User JWT |
| 14 | `compute-monthly-stats` | Service role (scheduled) |
| 15 | `scheduled-connect-buddy` | Service role (scheduled) |

**Sprint 5 (Admin + System):**

| Order | Function | Auth |
|-------|----------|------|
| 16 | `resolve-flag` | Admin JWT |
| 17 | `pin-announcement` | Admin JWT |
| 18 | `deactivate-user` | Admin JWT |
| 19 | `remove-user` | Admin JWT |
| 20 | `revoke-invitation` | Admin JWT |
| 21 | `scheduled-cleanup` | Service role (scheduled) |

**Deployment command:** `supabase functions deploy <function-name>` (one at a time) or `supabase functions deploy` (all at once).

---

## Supabase Setup Sequence (Complete)

Execute these steps in order. Each step depends on the previous.

```
1.  supabase init                              ← if not done
2.  supabase start                             ← start local stack
3.  supabase migration new enable_extensions   ← create migration #1
    ... write SQL ...
4.  Repeat for all 72 migrations (Phases 0–9)
5.  supabase db push                           ← apply all migrations to local
6.  supabase db seed                           ← run seed.sql (Connect Buddy)
7.  Create storage buckets (Dashboard or SQL)
8.  Configure storage RLS policies
9.  Enable Supabase Auth Phone/OTP provider
10. Deploy Edge Functions: supabase functions deploy
11. Set Edge Function secrets (FCM key, etc.)
12. Verify: supabase db dump --schema public   ← confirm 26 tables
13. Verify: RLS enabled badge on all tables
14. Run RLS smoke tests
15. Push to cloud: supabase db push --linked
```

---

## Rollback Strategy

| Scenario | Action |
|----------|--------|
| **Local development** | `supabase db reset` — drops and replays all migrations |
| **Bad migration on staging** | Create a compensating forward migration (new file that reverses the change) |
| **Wrong RLS policy** | New migration: `DROP POLICY name ON table;` then `CREATE POLICY ...` |
| **Wrong CHECK constraint** | New migration: `ALTER TABLE DROP CONSTRAINT name;` then `ALTER TABLE ADD CONSTRAINT ...` |
| **Wrong column type** | New migration: `ALTER TABLE ALTER COLUMN type;` or create new column + migrate data |
| **Production** | Never rollback. Deploy backward-compatible app code → apply compensating migration → deploy final app code |

---

## Coverage Verification Checklist

### Tables (26/26)

| # | Table | Created | RLS Enabled | RLS Policies | Trigger | Verified |
|---|-------|---------|-------------|-------------|---------|----------|
| 1 | profiles | ☐ | ☐ | ☐ 5 policies | ☐ | ☐ |
| 2 | invitations | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 3 | posts | ☐ | ☐ | ☐ 6 policies | ☐ | ☐ |
| 4 | post_images | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |
| 5 | post_reactions | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 6 | comments | ☐ | ☐ | ☐ 6 policies | ☐ | ☐ |
| 7 | post_mentions | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |
| 8 | activities | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 9 | activity_rsvps | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 10 | activity_updates | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |
| 11 | polls | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 12 | poll_options | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |
| 13 | poll_votes | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |
| 14 | event_attendance | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 15 | challenges | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 16 | challenge_participants | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |
| 17 | progress_logs | ☐ | ☐ | ☐ 5 policies | ☐ | ☐ |
| 18 | recognitions | ☐ | ☐ | ☐ 6 policies | ☐ | ☐ |
| 19 | recognition_recipients | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |
| 20 | recognition_reactions | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 21 | member_monthly_stats | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 22 | community_health_scores | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |
| 23 | notification_inbox | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |
| 24 | flagged_content | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 25 | pinned_announcements | ☐ | ☐ | ☐ 4 policies | ☐ | ☐ |
| 26 | admin_audit_log | ☐ | ☐ | ☐ 4 policies | N/A | ☐ |

### Storage Buckets (2/2)

| Bucket | Created | Public | RLS Configured | Verified |
|--------|---------|--------|---------------|----------|
| avatars | ☐ | Yes | ☐ | ☐ |
| post-images | ☐ | No | ☐ | ☐ |

### Functions (2/2)

| Function | Created | Verified |
|----------|---------|----------|
| `update_updated_at_column()` | ☐ | ☐ |
| `is_admin()` | ☐ | ☐ |

### Seed Data (1/1)

| Seed | Applied | Verified |
|------|---------|----------|
| Connect Buddy profile | ☐ | ☐ |

### Edge Functions (21/21)

| # | Function | Deployed | Tested |
|---|----------|----------|--------|
| 1 | send-notification | ☐ | ☐ |
| 2 | validate-invite-token | ☐ | ☐ |
| 3 | send-invitation | ☐ | ☐ |
| 4 | create-profile | ☐ | ☐ |
| 5 | post-connect-buddy-message | ☐ | ☐ |
| 6 | create-post | ☐ | ☐ |
| 7 | cancel-activity | ☐ | ☐ |
| 8 | post-activity-update | ☐ | ☐ |
| 9 | create-poll | ☐ | ☐ |
| 10 | close-poll | ☐ | ☐ |
| 11 | close-challenge | ☐ | ☐ |
| 12 | record-attendance | ☐ | ☐ |
| 13 | create-recognition | ☐ | ☐ |
| 14 | compute-monthly-stats | ☐ | ☐ |
| 15 | scheduled-connect-buddy | ☐ | ☐ |
| 16 | resolve-flag | ☐ | ☐ |
| 17 | pin-announcement | ☐ | ☐ |
| 18 | deactivate-user | ☐ | ☐ |
| 19 | remove-user | ☐ | ☐ |
| 20 | revoke-invitation | ☐ | ☐ |
| 21 | scheduled-cleanup | ☐ | ☐ |
