# Migration Preflight Check

## Audit Metadata

| Field | Value |
|-------|-------|
| Audit Date | 2026-06-19 |
| Documents Cross-Referenced | `database-migrations-plan.md` (source), `database-schema-design.md` (authoritative schema), `database-entity-catalogue.md`, `rls-security-policies.md` |
| Method | Line-by-line verification of all 68 declared migrations against the authoritative schema design |

---

## Verdict Summary

| Check | Result |
|-------|--------|
| Total migrations declared | 68 |
| Total migrations listed | 68 (count verified ✓) |
| Duplicate tables | **0** — all 26 tables unique ✓ |
| Circular FK dependencies | **0** — DAG verified ✓ |
| RLS ordering issues | **0** — every RLS policy follows its table ✓ |
| Trigger ordering issues | **0** — every trigger follows its function + table ✓ |
| Missing trigger migrations | **4 found** |
| Column name mismatches vs schema | **6 migrations affected** |
| Column missing/extra vs schema | **5 migrations affected** |
| RLS policy description mismatch | **1 migration affected** |
| **Total issues** | **Critical: 1, High: 7, Medium: 1** |

---

## Check 1: Execution Order — PASS

All 68 migrations are ordered by ascending timestamp prefix. Every FK dependency is satisfied before the referencing table is created.

**FK dependency chain verified:**

```
#1  Extensions
#2  update_updated_at_column() function
#3  is_admin() function (queries profiles — but function creation doesn't require the table)
#4  profiles ← foundation table, referenced by nearly every other table
#7  invitations → profiles ✓ (profiles exists at #4)
#10 posts → profiles ✓
#13 post_images → posts ✓ (posts exists at #10)
#15 post_reactions → posts, profiles ✓
#17 comments → posts, profiles ✓
#20 post_mentions → posts, profiles ✓
#22 activities → profiles ✓
#25 activity_rsvps → activities, profiles ✓
#28 activity_updates → activities, profiles ✓
#30 polls → activities (nullable FK), profiles ✓
#34 poll_options → polls ✓ (polls exists at #30)
#36 poll_votes → polls, poll_options, profiles ✓ (poll_options exists at #34)
#38 event_attendance → activities, profiles ✓
#40 challenges → profiles ✓
#43 challenge_participants → challenges, profiles ✓
#45 progress_logs → challenges, challenge_participants, profiles ✓ (challenge_participants at #43)
#47 recognitions → profiles ✓
#50 recognition_recipients → recognitions, profiles ✓
#52 recognition_reactions → recognitions, profiles ✓
#54 member_monthly_stats → profiles ✓
#57 community_health_scores → (no FKs) ✓
#60 notification_inbox → profiles ✓
#62 flagged_content → profiles ✓ (content_id polymorphic, no FK)
#65 pinned_announcements → posts, profiles ✓ (posts at #10)
#68 admin_audit_log → profiles ✓ (target_id polymorphic, no FK)
#70 seed → profiles ✓ (profiles at #4)
```

No out-of-order dependencies. ✓

---

## Check 2: Duplicate Tables — PASS

26 unique tables created across 9 phases. No table name appears in more than one CREATE migration.

| Phase | Tables Created | Count |
|-------|---------------|-------|
| 0 | (functions only) | 0 |
| 1 | profiles, invitations | 2 |
| 2 | posts, post_images, post_reactions, comments, post_mentions | 5 |
| 3 | activities, activity_rsvps, activity_updates, polls, poll_options, poll_votes, event_attendance | 7 |
| 4 | challenges, challenge_participants, progress_logs | 3 |
| 5 | recognitions, recognition_recipients, recognition_reactions | 3 |
| 6 | member_monthly_stats, community_health_scores | 2 |
| 7 | notification_inbox | 1 |
| 8 | flagged_content, pinned_announcements, admin_audit_log | 3 |
| **Total** | | **26 ✓** |

---

## Check 3: Circular Dependencies — PASS

The FK reference graph is a directed acyclic graph (DAG). `profiles` is the root node referenced by 24 of 25 remaining tables. No table references itself or creates a cycle through any chain of FKs.

---

## Check 4: Migration Conflicts — PASS (structural)

Removed migration gaps (#31, #59) are correctly explained and do not break the sequence. The timestamp ordering is monotonically increasing with no collisions.

---

## Check 5: RLS Dependency Issues — PASS (ordering)

Every RLS policy migration has a higher timestamp than its table creation migration. The `is_admin()` function (#3) is created before any RLS policy that calls it. The `profiles` table (#4) exists before `is_admin()` is invoked at policy evaluation time (runtime, not creation time).

**One RLS description mismatch found** — see MED-01 below.

---

## Check 6: Trigger Dependency Issues — CRITICAL

The `update_updated_at_column()` function is created in migration #2, before any table. All 12 existing trigger attachment migrations reference tables that exist earlier in the sequence. **However, 4 required trigger migrations are missing entirely.**

---

## Issues Found

### CRIT-01: Four updated_at trigger migrations are missing

The authoritative schema design (`database-schema-design.md`, Trigger Specification section) lists **16 tables** that receive the `update_updated_at_column()` trigger. The migration plan contains only **12** trigger attachment migrations. Four tables that have an `updated_at` column in the schema design have no migration to attach the trigger.

**Tables with trigger migration present (12):**

| # | Table | Trigger Migration |
|---|-------|------------------|
| 1 | profiles | #6 ✓ |
| 2 | invitations | #9 ✓ |
| 3 | posts | #12 ✓ |
| 4 | comments | #19 ✓ |
| 5 | activities | #24 ✓ |
| 6 | activity_rsvps | #27 ✓ |
| 7 | polls | #33 ✓ |
| 8 | challenges | #42 ✓ |
| 9 | recognitions | #49 ✓ |
| 10 | member_monthly_stats | #56 ✓ |
| 11 | flagged_content | #64 ✓ |
| 12 | pinned_announcements | #67 ✓ |

**Tables MISSING trigger migration (4):**

| Table | Schema has updated_at? | Trigger in schema list? | Migration exists? |
|-------|----------------------|------------------------|------------------|
| **post_reactions** | Yes — "Updated when the user changes their emoji on re-react" | Yes | **NO** |
| **event_attendance** | Yes — "Updated if the admin re-submits a corrected attendance record" | Yes | **NO** |
| **progress_logs** | Yes — "Updated on upsert when a member re-logs on the same date" | Yes | **NO** |
| **recognition_reactions** | Yes — "Updated when the user changes their emoji on re-react" | Yes | **NO** |

**Impact:** Without the trigger, `updated_at` will remain frozen at the `created_at` value on every UPDATE. UPSERT operations on these tables (reaction emoji changes, attendance corrections, progress re-logs) will show stale timestamps. Queries that depend on `updated_at` for ordering or cache invalidation will return incorrect results.

**Required fix:** Add 4 new migration files:
- `_create_post_reactions_updated_at_trigger.sql` (after #16)
- `_create_event_attendance_updated_at_trigger.sql` (after #39)
- `_create_progress_logs_updated_at_trigger.sql` (after #46)
- `_create_recognition_reactions_updated_at_trigger.sql` (after #53)

This raises the total from 68 to **72 migration files**.

---

### HIGH-01: Migration #10 (posts) — spurious `post_type` column

**Migration says:** `Adds post_type CHECK (member_post, connect_buddy_post).`

**Schema design says:** No `post_type` column exists. Connect Buddy posts are identified by checking `author.isSystemAccount` from the joined profiles row — not by a type discriminator on the posts table.

**Impact:** Extra column in the database that no application code reads or writes. Wastes storage and confuses developers.

**Fix:** Remove `post_type` column and its CHECK constraint from migration #10.

---

### HIGH-02: Migration #25 (activity_rsvps) — wrong column name `response`

**Migration says:** `response CHECK IN (going, not_going, maybe)`

**Schema design says:** Column is named `status`, not `response`.

**Cross-references affected:** `backend-api-contracts.md` uses `status`, `flutter-implementation-plan.md` uses `status`, `database-entity-catalogue.md` uses `status` in the constraint description.

**Impact:** All application code (Flutter datasources, Edge Functions, RLS policies) references `status`. If the column is created as `response`, every query fails.

**Fix:** Rename column from `response` to `status` in migration #25.

---

### HIGH-03: Migration #30 (polls) — `is_active` should be `is_closed`, `closes_at` nullability

**Migration says:** `is_active (boolean), closes_at (timestamptz nullable)`

**Schema design says:** `is_closed (boolean NOT NULL, default false)`, `closes_at (timestamptz NOT NULL)`

**Issues:**
1. Column name: `is_active` vs `is_closed` — inverted semantics
2. `closes_at` is nullable in migration but NOT NULL in schema

**Impact:** Application code references `is_closed`. The `close-poll` Edge Function sets `is_closed = true`. If column is `is_active`, every poll query and mutation breaks.

**Fix:** Change `is_active` to `is_closed` (boolean NOT NULL default false). Change `closes_at` to NOT NULL.

---

### HIGH-04: Migration #38 (event_attendance) — missing `status` column, wrong column name, missing `updated_at`

**Migration says:** Columns include `attended_at (timestamptz)`. No `status` column. No `updated_at`.

**Schema design says:** Columns include `status CHECK IN ('attended','absent')`, `recorded_at (timestamptz NOT NULL)`, `updated_at (timestamptz NOT NULL)`.

**Issues:**
1. Missing `status` column — the core data column that records Attended vs Absent
2. `attended_at` should be `recorded_at`
3. Missing `updated_at` column (table is in the 16-table trigger list)

**Impact:** Without `status`, the attendance feature cannot function. The `record-attendance` Edge Function writes `status = 'attended'` or `'absent'`. Personal analytics counts `WHERE status = 'attended'`. Everything breaks.

**Fix:** Add `status CHECK IN ('attended','absent')` column, rename `attended_at` to `recorded_at`, add `updated_at` column to migration #38.

---

### HIGH-05: Migration #15 (post_reactions) — missing `updated_at` column

**Migration says:** Columns: `id, post_id, user_id, emoji, created_at`

**Schema design says:** Includes `updated_at (timestamptz NOT NULL, auto-trigger)` — "Updated when the user changes their emoji on re-react"

**Impact:** Without `updated_at`, the UPSERT reaction flow cannot track when a reaction was last changed. The missing trigger (CRIT-01) becomes moot since the column itself doesn't exist.

**Fix:** Add `updated_at` column to migration #15. Add the corresponding trigger migration (from CRIT-01).

---

### HIGH-06: Migration #28 (activity_updates) — spurious `updated_at` column

**Migration says:** `created_at, updated_at`

**Schema design says:** Only `created_at`. Activity updates are append-only — "updates are not edited after posting."

**Note:** The trigger for this table was correctly removed (#31). But the column itself is still described in the migration.

**Impact:** An unnecessary `updated_at` column that nothing writes to. Minor waste but creates confusion about whether the table is mutable.

**Fix:** Remove `updated_at` from migration #28.

---

### HIGH-07: Migration #54 (member_monthly_stats) — column name and column set mismatches

**Migration says:**

| Migration column | Schema design column | Match? |
|-----------------|---------------------|--------|
| `events_attended` | `events_attended` | ✓ |
| `challenges_completed` | `challenges_joined` | ✗ name |
| `recognitions_given` | `recognitions_given` | ✓ |
| `recognitions_received` | `recognitions_received` | ✓ |
| `posts_authored` | `posts_count` | ✗ name |
| `comments_made` | *(not in schema)* | ✗ extra |
| *(not in migration)* | `attendance_rate` | ✗ missing |
| *(not in migration)* | `progress_logs_count` | ✗ missing |

**Issues:**
1. `challenges_completed` should be `challenges_joined`
2. `posts_authored` should be `posts_count`
3. `comments_made` is not in the schema design — remove it
4. `attendance_rate (numeric(5,2))` is missing — required for personal analytics
5. `progress_logs_count (integer)` is missing — required for personal analytics

**Impact:** The `compute-monthly-stats` Edge Function writes to the schema-design column names. Flutter reads the schema-design column names. If migrations use different names, every analytics query fails.

**Fix:** Align migration #54 columns exactly with `database-schema-design.md`.

---

### MED-01: Migration #55 (member_monthly_stats RLS) — description contradicts corrected policy

**Migration says:** `RLS policies: SELECT own (member) + all (admin)`

**Corrected rls-security-policies.md says:** `member_monthly_stats_select_authenticated | SELECT | Any | [active-user-guard] | All members see all stats — required for rankings leaderboard`

This was corrected during the project readiness audit (CRIT-02 fix). The migration plan description was not updated.

**Impact:** If a developer writes RLS SQL from the migration plan description, the Rankings feature breaks for non-admin members.

**Fix:** Update migration #55 description to: "RLS policies: SELECT all authenticated active users; INSERT/UPDATE/DELETE blocked for clients (service_role only)."

---

## Tables Without updated_at — Correctly Excluded from Triggers

The following 10 tables correctly have NO trigger migration and NO `updated_at` column, matching the schema design's "Tables without updated_at" list:

| Table | Reason (per schema design) | Trigger migration? | Correct? |
|-------|---------------------------|-------------------|----------|
| post_images | Append-only | None | ✓ |
| post_mentions | Append-only | None | ✓ |
| activity_updates | Append-only | #31 removed | ✓ |
| poll_options | Append-only | None | ✓ |
| poll_votes | Append-only | None | ✓ |
| challenge_participants | Append-only | None | ✓ |
| recognition_recipients | Append-only | None | ✓ |
| notification_inbox | is_read tracked separately | None | ✓ |
| community_health_scores | Upserted, not updated | #59 removed | ✓ |
| admin_audit_log | Immutable | None | ✓ |

---

## Complete Migration Execution Matrix

| # | File | Object | Depends On | Issues |
|---|------|--------|-----------|--------|
| 1 | enable_extensions | uuid-ossp, pgcrypto | — | ✓ |
| 2 | create_update_timestamp_trigger | Function | — | ✓ |
| 3 | create_is_admin_helper | Function | — | ✓ |
| 4 | create_profiles_table | Table + RLS on | — | ✓ |
| 5 | create_profiles_rls_policies | Policies | #3, #4 | ✓ |
| 6 | create_profiles_updated_at_trigger | Trigger | #2, #4 | ✓ |
| 7 | create_invitations_table | Table + RLS on | #4 | ✓ |
| 8 | create_invitations_rls_policies | Policies | #3, #7 | ✓ |
| 9 | create_invitations_updated_at_trigger | Trigger | #2, #7 | ✓ |
| 10 | create_posts_table | Table + RLS on | #4 | **HIGH-01** |
| 11 | create_posts_rls_policies | Policies | #3, #10 | ✓ |
| 12 | create_posts_updated_at_trigger | Trigger | #2, #10 | ✓ |
| 13 | create_post_images_table | Table + RLS on | #10 | ✓ |
| 14 | create_post_images_rls_policies | Policies | #10, #13 | ✓ |
| 15 | create_post_reactions_table | Table + RLS on | #4, #10 | **HIGH-05** |
| 16 | create_post_reactions_rls_policies | Policies | #15 | ✓ |
| — | **MISSING: post_reactions trigger** | — | #2, #15 | **CRIT-01** |
| 17 | create_comments_table | Table + RLS on | #4, #10 | ✓ |
| 18 | create_comments_rls_policies | Policies | #3, #10, #17 | ✓ |
| 19 | create_comments_updated_at_trigger | Trigger | #2, #17 | ✓ |
| 20 | create_post_mentions_table | Table + RLS on | #4, #10 | ✓ |
| 21 | create_post_mentions_rls_policies | Policies | #20 | ✓ |
| 22 | create_activities_table | Table + RLS on | #4 | ✓ |
| 23 | create_activities_rls_policies | Policies | #3, #22 | ✓ |
| 24 | create_activities_updated_at_trigger | Trigger | #2, #22 | ✓ |
| 25 | create_activity_rsvps_table | Table + RLS on | #4, #22 | **HIGH-02** |
| 26 | create_activity_rsvps_rls_policies | Policies | #25 | ✓ |
| 27 | create_activity_rsvps_updated_at_trigger | Trigger | #2, #25 | ✓ |
| 28 | create_activity_updates_table | Table + RLS on | #4, #22 | **HIGH-06** |
| 29 | create_activity_updates_rls_policies | Policies | #3, #28 | ✓ |
| 30 | create_polls_table | Table + RLS on | #4, #22 | **HIGH-03** |
| 32 | create_polls_rls_policies | Policies | #3, #30 | ✓ |
| 33 | create_polls_updated_at_trigger | Trigger | #2, #30 | ✓ |
| 34 | create_poll_options_table | Table + RLS on | #30 | ✓ |
| 35 | create_poll_options_rls_policies | Policies | #3, #34 | ✓ |
| 36 | create_poll_votes_table | Table + RLS on | #4, #30, #34 | ✓ |
| 37 | create_poll_votes_rls_policies | Policies | #36 | ✓ |
| 38 | create_event_attendance_table | Table + RLS on | #4, #22 | **HIGH-04** |
| 39 | create_event_attendance_rls_policies | Policies | #3, #38 | ✓ |
| — | **MISSING: event_attendance trigger** | — | #2, #38 | **CRIT-01** |
| 40 | create_challenges_table | Table + RLS on | #4 | ✓ |
| 41 | create_challenges_rls_policies | Policies | #3, #40 | ✓ |
| 42 | create_challenges_updated_at_trigger | Trigger | #2, #40 | ✓ |
| 43 | create_challenge_participants_table | Table + RLS on | #4, #40 | ✓ |
| 44 | create_challenge_participants_rls_policies | Policies | #43 | ✓ |
| 45 | create_progress_logs_table | Table + RLS on | #4, #40, #43 | ✓ |
| 46 | create_progress_logs_rls_policies | Policies | #3, #45 | ✓ |
| — | **MISSING: progress_logs trigger** | — | #2, #45 | **CRIT-01** |
| 47 | create_recognitions_table | Table + RLS on | #4 | ✓ |
| 48 | create_recognitions_rls_policies | Policies | #3, #47 | ✓ |
| 49 | create_recognitions_updated_at_trigger | Trigger | #2, #47 | ✓ |
| 50 | create_recognition_recipients_table | Table + RLS on | #4, #47 | ✓ |
| 51 | create_recognition_recipients_rls_policies | Policies | #50 | ✓ |
| 52 | create_recognition_reactions_table | Table + RLS on | #4, #47 | ✓ |
| 53 | create_recognition_reactions_rls_policies | Policies | #52 | ✓ |
| — | **MISSING: recognition_reactions trigger** | — | #2, #52 | **CRIT-01** |
| 54 | create_member_monthly_stats_table | Table + RLS on | #4 | **HIGH-07** |
| 55 | create_member_monthly_stats_rls_policies | Policies | #3, #54 | **MED-01** |
| 56 | create_member_monthly_stats_trigger | Trigger | #2, #54 | ✓ |
| 57 | create_community_health_scores_table | Table + RLS on | — | ✓ |
| 58 | create_community_health_scores_rls_policies | Policies | #57 | ✓ |
| 60 | create_notification_inbox_table | Table + RLS on | #4 | ✓ |
| 61 | create_notification_inbox_rls_policies | Policies | #60 | ✓ |
| 62 | create_flagged_content_table | Table + RLS on | #4 | ✓ |
| 63 | create_flagged_content_rls_policies | Policies | #3, #62 | ✓ |
| 64 | create_flagged_content_updated_at_trigger | Trigger | #2, #62 | ✓ |
| 65 | create_pinned_announcements_table | Table + RLS on | #4, #10 | ✓ |
| 66 | create_pinned_announcements_rls_policies | Policies | #3, #65 | ✓ |
| 67 | create_pinned_announcements_trigger | Trigger | #2, #65 | ✓ |
| 68 | create_admin_audit_log_table | Table + RLS on | #4 | ✓ |
| 69 | create_admin_audit_log_rls_policies | Policies | #3, #68 | ✓ |
| 70 | seed_connect_buddy_profile | Data | #4 | ✓ |

---

## Corrected Migration Count

| Category | Declared | After Fix |
|----------|---------|-----------|
| Table creation migrations | 26 | 26 (unchanged) |
| RLS policy migrations | 26 | 26 (unchanged) |
| Trigger migrations | 12 | **16** (+4) |
| Function/extension migrations | 3 | 3 (unchanged) |
| Seed migrations | 1 | 1 (unchanged) |
| **Total** | **68** | **72** |

---

## Issue Summary

| ID | Severity | Migration | Issue |
|----|----------|-----------|-------|
| CRIT-01 | Critical | (missing) | 4 updated_at trigger migrations missing: post_reactions, event_attendance, progress_logs, recognition_reactions |
| HIGH-01 | High | #10 | posts: spurious `post_type` column not in schema design |
| HIGH-02 | High | #25 | activity_rsvps: column `response` should be `status` |
| HIGH-03 | High | #30 | polls: `is_active` should be `is_closed`; `closes_at` should be NOT NULL |
| HIGH-04 | High | #38 | event_attendance: missing `status` column; `attended_at` should be `recorded_at`; missing `updated_at` |
| HIGH-05 | High | #15 | post_reactions: missing `updated_at` column |
| HIGH-06 | High | #28 | activity_updates: spurious `updated_at` column (append-only table) |
| HIGH-07 | High | #54 | member_monthly_stats: 3 wrong column names, 2 missing columns |
| MED-01 | Medium | #55 | member_monthly_stats RLS description says "own only" — should be "all authenticated" per corrected policy |

**Totals: 1 Critical, 7 High, 1 Medium**

---

## Action Required Before Writing SQL

All issues are in the `database-migrations-plan.md` descriptions. The authoritative source of truth is `database-schema-design.md`. When writing actual SQL migration files:

1. **Always derive column names, types, constraints, and nullability from `database-schema-design.md`** — not from the migration plan descriptions
2. **Always derive RLS policies from `rls-security-policies.md`** — not from the migration plan descriptions
3. **Add the 4 missing trigger migrations** to the plan before writing SQL
4. **Ignore the migration plan's column lists** where they conflict with the schema design

The migration plan correctly captures table ordering, FK dependencies, and phase grouping. Its column-level descriptions are unreliable for 6 of 26 tables.
