# Pre-Supabase Implementation Audit

## Audit Metadata

| Field | Value |
|-------|-------|
| Audit Date | 2026-06-20 |
| Documents Audited | 6 (`supabase-project-setup.md`, `database-execution-plan.md`, `database-schema-design.md`, `database-migrations-plan.md`, `rls-security-policies.md`, `backend-api-contracts.md`) |
| Method | Line-by-line cross-reference of every count, reference, and dependency |

---

## Issue Summary

| Severity | Count |
|----------|-------|
| **Critical** | 0 |
| **High** | 0 |
| **Medium** | 2 |
| **Total** | 2 |

---

## Verification Results

### 1. Every migration in execution plan exists in migrations plan — PASS

All 72 migration numbers in `database-execution-plan.md` were matched against `database-migrations-plan.md`. Zero mismatches. The diff of migration reference numbers between both documents produced no orphans in either direction.

### 2. Migration count matches exactly — PASS

| Document | Count |
|----------|-------|
| `database-migrations-plan.md` (Migration Count Summary) | **72** |
| `database-execution-plan.md` (Quick Reference table total) | **72** |
| `database-execution-plan.md` (individual migration rows counted) | **72** |
| `database-implementation-checklist.md` | **72** |

### 3. Trigger count matches exactly — PASS

| Source | Count |
|--------|-------|
| `database-schema-design.md` (Trigger Specification: "Applied to 16 of 26 tables") | **16** |
| `database-migrations-plan.md` (trigger migration files) | **16** |
| `database-execution-plan.md` (trigger rows in execution tables) | **16** |
| `database-execution-plan.md` (Quick Reference Triggers column total) | **16** |

Tables without triggers (10): post_images, post_mentions, activity_updates, poll_options, poll_votes, challenge_participants, recognition_recipients, notification_inbox, community_health_scores, admin_audit_log — all confirmed append-only or immutable per schema design.

### 4. Table count matches exactly — PASS

| Source | Count |
|--------|-------|
| `database-schema-design.md` ("26 application tables") | **26** |
| `database-migrations-plan.md` (table creation migrations) | **26** |
| `database-execution-plan.md` (Phase 8 cumulative: "26 — all tables complete") | **26** |
| `database-execution-plan.md` (Post-Migration Verification expected) | **26** |
| `rls-security-policies.md` (table sections) | **26** |

### 5. RLS deployment order is valid — PASS

Every RLS policy migration follows its table creation migration:

| Table | Created At | RLS Policies At | Valid? |
|-------|-----------|----------------|--------|
| profiles | #4 | #5 | ✓ |
| invitations | #7 | #8 | ✓ |
| posts | #10 | #11 | ✓ |
| post_images | #13 | #14 | ✓ |
| post_reactions | #15 | #16 | ✓ |
| comments | #17 | #18 | ✓ |
| post_mentions | #20 | #21 | ✓ |
| activities | #22 | #23 | ✓ |
| activity_rsvps | #25 | #26 | ✓ |
| activity_updates | #28 | #29 | ✓ |
| polls | #30 | #32 | ✓ |
| poll_options | #34 | #35 | ✓ |
| poll_votes | #36 | #37 | ✓ |
| event_attendance | #38 | #39 | ✓ |
| challenges | #40 | #41 | ✓ |
| challenge_participants | #43 | #44 | ✓ |
| progress_logs | #45 | #46 | ✓ |
| recognitions | #47 | #48 | ✓ |
| recognition_recipients | #50 | #51 | ✓ |
| recognition_reactions | #52 | #53 | ✓ |
| member_monthly_stats | #54 | #55 | ✓ |
| community_health_scores | #57 | #58 | ✓ |
| notification_inbox | #60 | #61 | ✓ |
| flagged_content | #62 | #63 | ✓ |
| pinned_announcements | #65 | #66 | ✓ |
| admin_audit_log | #68 | #69 | ✓ |

`is_admin()` function created at #3, before any RLS policy that calls it. ✓

### 6. Storage bucket configuration matches schema requirements — PASS

| Property | `database-schema-design.md` | `supabase-project-setup.md` | Match? |
|----------|---------------------------|----------------------------|--------|
| Bucket 1 name | `avatars` | `avatars` | ✓ |
| Bucket 1 access | Public read; authenticated write (owner) | Public: Yes; Owner write | ✓ |
| Bucket 1 path | `avatars/{user_id}/profile.jpg` | Documented | ✓ |
| Bucket 2 name | `post-images` | `post-images` | ✓ |
| Bucket 2 access | Authenticated read; authenticated write (author) | Public: No; Author write | ✓ |
| Bucket 2 path | `post-images/{user_id}/{uuid}.jpg` | Documented | ✓ |
| File size (avatars) | Not specified in schema | 2 MB in setup guide | ✓ (reasonable) |
| File size (post-images) | Not specified in schema | 5 MB in setup guide | ✓ (reasonable) |

### 7. Edge Function prerequisites are complete — PASS

| Prerequisite | Documented In | Status |
|-------------|---------------|--------|
| 21 Edge Functions listed | `backend-api-contracts.md` (21 `POST /` entries) | ✓ |
| Deployment order defined | `database-implementation-checklist.md` (Sprint-aligned order) | ✓ |
| `send-notification` first (internal dependency) | Checklist: order #1 | ✓ |
| Auth requirements per function | `backend-api-contracts.md` (each contract specifies auth) | ✓ |
| Shared infrastructure | `backend/supabase/functions/_shared/` (6 TypeScript files exist) | ✓ |
| Function directories | All 21 directories created in bootstrap | ✓ |
| Edge Function secrets | `supabase-project-setup.md` Section 6 | ✓ |

### 8. Environment variables are complete — PASS

| Variable | Flutter App | Edge Functions | Local Dev | CI/CD | Documented? |
|----------|------------|---------------|----------|-------|-------------|
| `SUPABASE_URL` | `--dart-define` | Auto-injected | `.env.local` | — | ✓ |
| `SUPABASE_ANON_KEY` | `--dart-define` | Auto-injected | `.env.local` | — | ✓ |
| `SUPABASE_SERVICE_ROLE_KEY` | Never | Auto-injected | `.env.local` | — | ✓ |
| `FCM_SERVER_KEY` | Never | `supabase secrets set` | `.env.local` | — | ✓ |
| `SUPABASE_ACCESS_TOKEN` | — | — | — | GitHub Secret | ✓ |
| `SUPABASE_PROJECT_REF` | — | — | — | GitHub Secret | ✓ |
| `SUPABASE_DB_PASSWORD` | — | — | — | GitHub Secret | ✓ |

### 9. No execution step references a missing document — PASS

| Reference | From Document | Target Document | Exists? |
|-----------|--------------|----------------|---------|
| `database-schema-design.md` | `database-execution-plan.md` line 7 | ✓ | ✓ |
| `database-migrations-plan.md` | `database-execution-plan.md` line 8 | ✓ | ✓ |
| `rls-security-policies.md` | `database-execution-plan.md` line 9 | ✓ | ✓ |
| `backend-api-contracts.md` | `database-implementation-checklist.md` | ✓ | ✓ |
| `.env.local.example` | `supabase-project-setup.md` | `backend/supabase/.env.local.example` | ✓ |
| `_shared/constants.ts` | `supabase-project-setup.md` (CB UUID) | `backend/supabase/functions/_shared/constants.ts` | ✓ |

### 10. No deployment dependency is missing — PASS

Deployment sequence from `supabase-project-setup.md` verified:

| Step | Dependency | Satisfied? |
|------|-----------|-----------|
| 1. Create Supabase project | Dashboard access | External |
| 2. Link local | Project ref | Step 1 |
| 3. Configure Auth | Dashboard | Step 1 |
| 4. Configure Auth settings | Dashboard | Step 1 |
| 5. Apply migrations | Migrations exist | Migration files (to be written) |
| 6. Create CB auth.users | Service role key | Step 2 |
| 7. Apply seed | CB auth.users exists | Step 6 |
| 8. Create storage buckets | Dashboard | Step 1 |
| 9. Configure storage RLS | Buckets exist | Step 8 |
| 10. Enable Realtime | Tables exist | Step 5 |
| 11. Deploy Edge Functions | Tables exist + shared infra | Step 5 + files exist |
| 12. Set secrets | Functions deployed | Step 11 |
| 13–16. Verification | All above | Steps 1–12 |

No circular dependencies. All prerequisites are met by earlier steps.

---

## Medium Issues

### MED-01: Realtime replication table list missing `recognitions`

**Affected document:** `supabase-project-setup.md`, Section 5 (Realtime Configuration)

**The discrepancy:** The setup guide lists 7 tables for Realtime replication. The `backend-architecture.md` Realtime Channel Catalogue defines 8 channels, including `recognition:wall` which requires INSERT replication on the `recognitions` table.

| Setup Guide (7 tables) | Backend Architecture (8 channels) |
|------------------------|----------------------------------|
| posts | ✓ feed:posts |
| post_reactions | ✓ feed:reactions:{post_id} |
| comments | ✓ feed:comments:{post_id} |
| activity_rsvps | ✓ activities:rsvps:{activity_id} |
| poll_votes | ✓ events:poll_votes:{poll_id} |
| progress_logs | ✓ growth:leaderboard:{challenge_id} |
| notification_inbox | ✓ notifications:inbox:{user_id} |
| **missing** | ✗ **recognition:wall** (INSERT on `recognitions`) |

**Fix:** Add `recognitions | INSERT` to the Realtime replication table list in `supabase-project-setup.md`.

---

### MED-02: member_monthly_stats RLS policy count mismatch

**Affected documents:**
- `database-execution-plan.md` line 274: "3 RLS policies"
- `database-migrations-plan.md` migration #55: "3 policies"
- `rls-security-policies.md` lines 339–342: **4 policies** (SELECT + INSERT + UPDATE + DELETE)

**The discrepancy:** The RLS source of truth (`rls-security-policies.md`) defines 4 policies for `member_monthly_stats`:

| Policy | Operation |
|--------|-----------|
| `member_monthly_stats_select_authenticated` | SELECT |
| `member_monthly_stats_insert_blocked` | INSERT (false) |
| `member_monthly_stats_update_blocked` | UPDATE (false) |
| `member_monthly_stats_delete_blocked` | DELETE (false) |

The execution plan and migrations plan both say "3 policies" — they are undercounting by 1.

**Fix:** Change "3 RLS policies" to "4 RLS policies" in both `database-execution-plan.md` (line 274) and `database-migrations-plan.md` (migration #55).

---

## Final Verdict

| Criteria | Value | Required |
|----------|-------|----------|
| Critical issues | **0** | 0 |
| High issues | **0** | 0 |
| Medium issues | **2** | 0 |

### **NOT YET READY — 2 medium issues require resolution**

Both issues are documentation count errors, not architectural problems. They can be fixed in under 2 minutes:

1. Add `recognitions | INSERT` to the Realtime table list in `supabase-project-setup.md`
2. Change "3 policies" → "4 policies" for `member_monthly_stats` in both `database-execution-plan.md` and `database-migrations-plan.md`

After these two fixes, the verdict will be **READY FOR SUPABASE IMPLEMENTATION**.
