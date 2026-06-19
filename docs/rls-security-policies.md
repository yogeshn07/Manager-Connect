# RLS Security Policies

This document specifies the Row Level Security (RLS) policy design for all 26 tables in the Manager Connect PostgreSQL database. It is a design reference, not a migration script. Policies are described in plain English and pseudocode. No SQL is included.

---

## Overview

Row Level Security is a PostgreSQL feature that enforces access control at the database layer, independently of application code. When RLS is enabled on a table, every query against that table — regardless of which client or service issued it — is filtered through the applicable policies. A query that matches no policy returns zero rows (for SELECT) or fails silently (for INSERT/UPDATE/DELETE), rather than returning an error.

**Why RLS on all 26 tables:** Manager Connect uses Supabase's auto-generated REST and Realtime APIs, which allow clients to query the database directly using the `anon` or `authenticated` JWT keys. Without RLS, any authenticated user could read or write any row in any table. RLS ensures that even if application-layer validation is bypassed, the database itself enforces the access model.

**Supabase Auth integration:** Supabase Auth sets a PostgreSQL session variable `request.jwt.claims` on every request. The `auth.uid()` function reads the `sub` claim from this JWT and returns the authenticated user's UUID. All policies use `auth.uid()` as the identity of the requesting user.

**Role summary:**

| Role | `app_role` value | Access Level |
|---|---|---|
| Member | `'member'` | Read most content; write own content; react, vote, RSVP |
| Admin | `'admin'` | Full read (including deleted); moderate; create activities/challenges/polls; admin tools |
| System | `'system'` | Connect Buddy service account; writes via Edge Function (service_role) — not via RLS |
| Unauthenticated | (no JWT) | No access to any table |

**Edge Functions bypass RLS:** Edge Functions run with the Supabase `service_role` key, which bypasses RLS entirely. This is intentional — Edge Functions contain their own validation logic and are not subject to per-row policies. Any table that is marked "Service role only" for INSERT/UPDATE means those operations happen exclusively through Edge Functions.

---

## Helper Function: is_admin()

**Name:** `is_admin()`  
**Returns:** `boolean`  
**Logic:** Queries the `profiles` table for a row where `id = auth.uid()` and returns `true` if that row's `app_role` equals `'admin'`. Returns `false` for any other role value or if no profile exists.  
**Security:** Defined with `SECURITY DEFINER` so it executes under the privileges of its definer (typically a superuser or elevated role), bypassing the caller's own RLS restrictions to read the `profiles` table during policy evaluation. Without `SECURITY DEFINER`, a recursive RLS evaluation loop would occur when policies on other tables call `is_admin()` and that call triggers a `profiles` SELECT which itself requires an RLS check.  
**Usage:** Appears in admin-check conditions across policies on every table where admin access differs from member access.

---

## Active User Guard

Every policy on every table applies the following base condition before any table-specific logic:

```
auth.uid() IS NOT NULL
AND EXISTS (
  SELECT 1 FROM profiles
  WHERE id = auth.uid()
  AND is_active = true
)
```

This guard enforces two things simultaneously:
1. **Authentication:** `auth.uid() IS NOT NULL` blocks all unauthenticated requests (requests with no JWT or an expired JWT).
2. **Deactivation:** The `is_active = true` check ensures that a deactivated user — one whose account has been suspended by an admin — cannot access any data, even if they hold a valid JWT. Deactivated users fail this check on every table in the schema.

To avoid repetition in the policy tables below, this guard is referenced as **[active-user-guard]** in policy conditions.

---

## RLS Policies — Per Table

---

### profiles

Access model: every active member can read any profile (members need to see each other's names and avatars). Members can edit only their own profile. Admins can edit any profile (for deactivation and role changes). No client can INSERT or hard-DELETE profiles.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `profiles_select_authenticated` | SELECT | Any | [active-user-guard] | All active members see all profiles (needed for @mention search, member lists) |
| `profiles_update_own` | UPDATE | Member | [active-user-guard] AND `id = auth.uid()` | Member can only edit their own row |
| `profiles_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admin can edit any profile (deactivation, role promotion) |
| `profiles_insert_blocked` | INSERT | None | `false` | Profile creation is handled by an Edge Function trigger on auth.users |
| `profiles_delete_blocked` | DELETE | None | `false` | Profiles are never hard-deleted; deactivation is via `is_active = false` |

---

### invitations

Access model: only admins can create and manage invitations. Members can view only the invitation that used their own profile as `used_by`.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `invitations_select_admin` | SELECT | Admin | [active-user-guard] AND `is_admin()` | Admin sees all invitations |
| `invitations_select_own` | SELECT | Member | [active-user-guard] AND `used_by = auth.uid()` | Member sees only the invitation they redeemed |
| `invitations_insert_admin` | INSERT | Admin | [active-user-guard] AND `is_admin()` | Only admins can create invite tokens |
| `invitations_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admins can mark invites as used or cancel them |
| `invitations_delete_blocked` | DELETE | None | `false` | Invitations are not hard-deleted |

---

### posts

Access model: members see all non-deleted posts; admins see everything including deleted (for moderation). Members can create and soft-delete their own posts. Hard DELETE is blocked for all roles.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `posts_select_member` | SELECT | Member | [active-user-guard] AND `is_deleted = false` | Members see only live posts |
| `posts_select_admin` | SELECT | Admin | [active-user-guard] AND `is_admin()` | Admins see all posts including soft-deleted |
| `posts_insert_own` | INSERT | Member | [active-user-guard] AND `author_id = auth.uid()` | Author must be the authenticated user (WITH CHECK) |
| `posts_update_own` | UPDATE | Member | [active-user-guard] AND `author_id = auth.uid()` AND `is_deleted = false` | Members edit their own non-deleted posts |
| `posts_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admins can update any post (including soft-delete via `is_deleted = true`) |
| `posts_delete_blocked` | DELETE | None | `false` | No hard delete; soft delete via UPDATE `is_deleted = true` |

---

### post_images

Access model: image visibility follows the parent post's visibility. Images are immutable once uploaded. No hard delete.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `post_images_select_member` | SELECT | Member | [active-user-guard] AND `post_id IN (SELECT id FROM posts WHERE is_deleted = false)` | Images visible only when parent post is visible |
| `post_images_select_admin` | SELECT | Admin | [active-user-guard] AND `is_admin()` | Admins see all images including those on deleted posts |
| `post_images_insert_own` | INSERT | Member | [active-user-guard] AND `post_id IN (SELECT id FROM posts WHERE author_id = auth.uid())` | Only the post author can attach images |
| `post_images_update_blocked` | UPDATE | None | `false` | Images are immutable after upload |
| `post_images_delete_blocked` | DELETE | None | `false` | Deletion handled via Edge Function (service_role) when post is soft-deleted |

---

### post_reactions

Access model: any active member can read reactions. Any active member can react to any visible post (UNIQUE constraint prevents duplicates). Members can retract their own reaction. No UPDATE — reaction changes require delete + insert.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `post_reactions_select_authenticated` | SELECT | Any | [active-user-guard] | All members see all reactions |
| `post_reactions_insert_own` | INSERT | Member | [active-user-guard] AND `user_id = auth.uid()` | Member reacts as themselves |
| `post_reactions_update_blocked` | UPDATE | None | `false` | Reactions are changed by delete + insert only |
| `post_reactions_delete_own` | DELETE | Member | [active-user-guard] AND `user_id = auth.uid()` | Member can retract their own reaction |

---

### comments

Access model: mirrors posts. Members see non-deleted comments on non-deleted posts. Admins see all. Members can create and soft-delete own comments. Hard DELETE blocked.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `comments_select_member` | SELECT | Member | [active-user-guard] AND `is_deleted = false` AND `post_id IN (SELECT id FROM posts WHERE is_deleted = false)` | Comment and parent post must both be live |
| `comments_select_admin` | SELECT | Admin | [active-user-guard] AND `is_admin()` | Admins see all comments including deleted |
| `comments_insert_own` | INSERT | Member | [active-user-guard] AND `author_id = auth.uid()` | Author must be authenticated user |
| `comments_update_own` | UPDATE | Member | [active-user-guard] AND `author_id = auth.uid()` AND `is_deleted = false` | Members edit their own live comments |
| `comments_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admins can update any comment (including soft-delete) |
| `comments_delete_blocked` | DELETE | None | `false` | Soft delete only |

---

### post_mentions

Access model: mentions are metadata extracted from post content. Any member can read them. Only service_role (Edge Function) inserts them. No updates or deletes.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `post_mentions_select_authenticated` | SELECT | Any | [active-user-guard] | All members can see who was mentioned |
| `post_mentions_insert_blocked` | INSERT | None | `false` (client) | Service_role only — Edge Function inserts on post creation |
| `post_mentions_update_blocked` | UPDATE | None | `false` | Immutable |
| `post_mentions_delete_blocked` | DELETE | None | `false` | Immutable |

---

### activities

Access model: all members can view all activities. Only admins can create or modify activities. No hard delete (activities are cancelled via status field).

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `activities_select_authenticated` | SELECT | Any | [active-user-guard] | All members see all activities |
| `activities_insert_admin` | INSERT | Admin | [active-user-guard] AND `is_admin()` | Admin-only creation |
| `activities_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admin-only modification (includes status changes) |
| `activities_delete_blocked` | DELETE | None | `false` | Cancellation via `status = 'cancelled'` UPDATE |

---

### activity_rsvps

Access model: all members can see all RSVPs (transparency). Members can RSVP, update, or retract their own RSVP. No admin override needed.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `activity_rsvps_select_authenticated` | SELECT | Any | [active-user-guard] | All members see RSVPs for any activity |
| `activity_rsvps_insert_own` | INSERT | Member | [active-user-guard] AND `user_id = auth.uid()` | Members RSVP as themselves |
| `activity_rsvps_update_own` | UPDATE | Member | [active-user-guard] AND `user_id = auth.uid()` | Members change their own RSVP response |
| `activity_rsvps_delete_own` | DELETE | Member | [active-user-guard] AND `user_id = auth.uid()` | Members retract their RSVP |

---

### activity_updates

Access model: all members can read activity updates. Only admins can create or edit updates.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `activity_updates_select_authenticated` | SELECT | Any | [active-user-guard] | All members see event update posts |
| `activity_updates_insert_admin` | INSERT | Admin | [active-user-guard] AND `is_admin()` | Admins post updates to events |
| `activity_updates_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admins can edit update posts |
| `activity_updates_delete_blocked` | DELETE | None | `false` | No hard delete |

---

### polls

Access model: all members can view polls. Only admins can create or update polls.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `polls_select_authenticated` | SELECT | Any | [active-user-guard] | All members see all polls |
| `polls_insert_admin` | INSERT | Admin | [active-user-guard] AND `is_admin()` | Admin-only poll creation |
| `polls_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admin can open/close polls, edit questions |
| `polls_delete_blocked` | DELETE | None | `false` | Polls are closed via `is_active = false`, not deleted |

---

### poll_options

Access model: all members can view poll options. Only admins can create options (at poll creation time). Options are immutable after creation.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `poll_options_select_authenticated` | SELECT | Any | [active-user-guard] | All members see poll answer choices |
| `poll_options_insert_admin` | INSERT | Admin | [active-user-guard] AND `is_admin()` | Admin creates options when creating a poll |
| `poll_options_update_blocked` | UPDATE | None | `false` | Options cannot be changed after poll creation |
| `poll_options_delete_blocked` | DELETE | None | `false` | Options cannot be removed |

---

### poll_votes

Access model: all members can see all votes (transparent voting). Members can cast one vote per poll (UNIQUE constraint enforces this). Votes are immutable — no change or retraction.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `poll_votes_select_authenticated` | SELECT | Any | [active-user-guard] | All members see all votes |
| `poll_votes_insert_own` | INSERT | Member | [active-user-guard] AND `user_id = auth.uid()` | Members vote as themselves; UNIQUE(poll_id, user_id) prevents second vote |
| `poll_votes_update_blocked` | UPDATE | None | `false` | Votes cannot be changed |
| `poll_votes_delete_blocked` | DELETE | None | `false` | Votes cannot be retracted |

---

### event_attendance

Access model: all members can view attendance records. Only admins can create or update attendance records.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `event_attendance_select_authenticated` | SELECT | Any | [active-user-guard] | All members see attendance records |
| `event_attendance_insert_admin` | INSERT | Admin | [active-user-guard] AND `is_admin()` | Admin records attendance post-event |
| `event_attendance_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admin can correct attendance records |
| `event_attendance_delete_blocked` | DELETE | None | `false` | Attendance records are not deleted |

---

### challenges

Access model: all members can view challenges. Only admins can create or update them.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `challenges_select_authenticated` | SELECT | Any | [active-user-guard] | All members see all challenges |
| `challenges_insert_admin` | INSERT | Admin | [active-user-guard] AND `is_admin()` | Admin-only challenge creation |
| `challenges_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admin can update challenge details and status |
| `challenges_delete_blocked` | DELETE | None | `false` | Challenges end via `status` field, not deletion |

---

### challenge_participants

Access model: all members can see who has joined challenges. Members can join (INSERT) or leave (DELETE) for themselves only.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `challenge_participants_select_authenticated` | SELECT | Any | [active-user-guard] | All members see participation lists |
| `challenge_participants_insert_own` | INSERT | Member | [active-user-guard] AND `user_id = auth.uid()` | Members join as themselves |
| `challenge_participants_update_blocked` | UPDATE | None | `false` | Join is binary; leave by DELETE |
| `challenge_participants_delete_own` | DELETE | Member | [active-user-guard] AND `user_id = auth.uid()` | Members can leave a challenge |

---

### progress_logs

Access model: members can only see and manage their own logs. Admins can see all logs. No hard delete.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `progress_logs_select_own` | SELECT | Member | [active-user-guard] AND `user_id = auth.uid()` | Members see only their own progress |
| `progress_logs_select_admin` | SELECT | Admin | [active-user-guard] AND `is_admin()` | Admins see all logs (for challenge oversight) |
| `progress_logs_insert_own` | INSERT | Member | [active-user-guard] AND `user_id = auth.uid()` | Members log their own progress |
| `progress_logs_update_own` | UPDATE | Member | [active-user-guard] AND `user_id = auth.uid()` | Members can edit their own logs (same-day enforcement at app layer) |
| `progress_logs_delete_blocked` | DELETE | None | `false` | Logs are not deleted |

---

### recognitions

Access model: members see all non-deleted recognitions. Admins see all including deleted. Any member can give recognition. Only admins can soft-delete. No hard DELETE.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `recognitions_select_member` | SELECT | Member | [active-user-guard] AND `is_deleted = false` | Members see live recognitions only |
| `recognitions_select_admin` | SELECT | Admin | [active-user-guard] AND `is_admin()` | Admins see all including deleted |
| `recognitions_insert_own` | INSERT | Member | [active-user-guard] AND `giver_id = auth.uid()` | Any member can give recognition |
| `recognitions_update_blocked` | UPDATE | Member | `false` | Recognitions are immutable for the giver |
| `recognitions_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admins can soft-delete for moderation |
| `recognitions_delete_blocked` | DELETE | None | `false` | Soft delete only |

---

### recognition_recipients

Access model: any member can see recognition recipients. Insert follows recognition creation (handled by Edge Function). Immutable after creation.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `recognition_recipients_select_authenticated` | SELECT | Any | [active-user-guard] | All members see who was recognized |
| `recognition_recipients_insert_own` | INSERT | Member | [active-user-guard] AND recognition's `giver_id = auth.uid()` | Giver's recognition creation inserts recipients |
| `recognition_recipients_update_blocked` | UPDATE | None | `false` | Recipients are immutable |
| `recognition_recipients_delete_blocked` | DELETE | None | `false` | Recipients are immutable |

---

### recognition_reactions

Access model: any member can see reactions. Members can react (one per recognition via UNIQUE constraint). Members can remove their own reaction. No UPDATE.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `recognition_reactions_select_authenticated` | SELECT | Any | [active-user-guard] | All members see reactions |
| `recognition_reactions_insert_own` | INSERT | Member | [active-user-guard] AND `user_id = auth.uid()` | Members react as themselves |
| `recognition_reactions_update_blocked` | UPDATE | None | `false` | Change reaction by delete + insert |
| `recognition_reactions_delete_own` | DELETE | Member | [active-user-guard] AND `user_id = auth.uid()` | Members remove their own reaction |

---

### member_monthly_stats

Access model: all authenticated members can read all stats (required for Monthly Rankings FR-06.4 and All-Time Rankings FR-06.5). All writes are service_role only (Edge Function computed aggregates).

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `member_monthly_stats_select_authenticated` | SELECT | Any | [active-user-guard] | All members see all stats — required for rankings leaderboard |
| `member_monthly_stats_insert_blocked` | INSERT | None | `false` (client) | Service_role only — Edge Function writes |
| `member_monthly_stats_update_blocked` | UPDATE | None | `false` (client) | Service_role only — Edge Function updates |
| `member_monthly_stats_delete_blocked` | DELETE | None | `false` | Stats are not deleted |

---

### community_health_scores

Access model: all members can view community health scores. All writes are service_role only.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `community_health_scores_select_authenticated` | SELECT | Any | [active-user-guard] | All members see community-level scores |
| `community_health_scores_insert_blocked` | INSERT | None | `false` (client) | Service_role only — Edge Function writes |
| `community_health_scores_update_blocked` | UPDATE | None | `false` (client) | Service_role only — Edge Function updates |
| `community_health_scores_delete_blocked` | DELETE | None | `false` | Scores are not deleted |

---

### notification_inbox

Access model: members see only their own notifications. Members can mark their own as read. All inserts are service_role only. No deletes.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `notification_inbox_select_own` | SELECT | Member | [active-user-guard] AND `recipient_id = auth.uid()` | Members see only their own notifications |
| `notification_inbox_insert_blocked` | INSERT | None | `false` (client) | Service_role only — Edge Function dispatches notifications |
| `notification_inbox_update_own` | UPDATE | Member | [active-user-guard] AND `recipient_id = auth.uid()` | Members can mark their own notifications as read (only `is_read`, `read_at` columns) |
| `notification_inbox_delete_blocked` | DELETE | None | `false` | Notifications are never deleted |

---

### flagged_content

Access model: only admins can view the moderation queue. Any active member can submit a flag. Only admins can resolve flags. No hard delete.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `flagged_content_select_admin` | SELECT | Admin | [active-user-guard] AND `is_admin()` | Admin-only access to moderation queue |
| `flagged_content_insert_own` | INSERT | Member | [active-user-guard] AND `reporter_id = auth.uid()` | Any member can flag content |
| `flagged_content_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admins resolve flags and add resolution notes |
| `flagged_content_delete_blocked` | DELETE | None | `false` | Flags are not deleted |

---

### pinned_announcements

Access model: all members can view pinned posts. Only admins can pin or unpin. No hard delete (unpin via UPDATE `is_active = false`).

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `pinned_announcements_select_authenticated` | SELECT | Any | [active-user-guard] | All members see the active pin |
| `pinned_announcements_insert_admin` | INSERT | Admin | [active-user-guard] AND `is_admin()` | Admin-only pinning |
| `pinned_announcements_update_admin` | UPDATE | Admin | [active-user-guard] AND `is_admin()` | Admins change pin status |
| `pinned_announcements_delete_blocked` | DELETE | None | `false` | No hard delete; unpin via `is_active = false` |

---

### admin_audit_log

Access model: admins can view the audit log. The audit log is fully immutable — no client can insert, update, or delete rows. Service_role (Edge Function) inserts records.

| Policy Name | Operation | Role | Condition | Notes |
|---|---|---|---|---|
| `admin_audit_log_select_admin` | SELECT | Admin | [active-user-guard] AND `is_admin()` | Admin-only visibility into action history |
| `admin_audit_log_insert_blocked` | INSERT | None | `false` (client) | Service_role only — Edge Functions record all admin actions |
| `admin_audit_log_update_blocked` | UPDATE | None | `false` | Immutable — no updates ever |
| `admin_audit_log_delete_blocked` | DELETE | None | `false` | Immutable — no deletes ever |

---

## Security Contracts Summary

| Table | Member SELECT | Admin SELECT | Member INSERT | Admin INSERT | Member UPDATE | Admin UPDATE | DELETE (any) |
|---|---|---|---|---|---|---|---|
| `profiles` | ✓ All | ✓ All | ✗ | ✗ | Own only | ✓ Any | ✗ |
| `invitations` | Own only | ✓ All | ✗ | ✓ | ✗ | ✓ | ✗ |
| `posts` | Non-deleted | ✓ All | Own only | ✗ | Own non-deleted | ✓ Any | ✗ |
| `post_images` | Non-deleted posts | ✓ All | Post author | ✗ | ✗ | ✗ | ✗ |
| `post_reactions` | ✓ All | ✓ All | Own only | ✗ | ✗ | ✗ | Own only |
| `comments` | Non-deleted | ✓ All | Own only | ✗ | Own non-deleted | ✓ Any | ✗ |
| `post_mentions` | ✓ All | ✓ All | Service role only | Service role only | ✗ | ✗ | ✗ |
| `activities` | ✓ All | ✓ All | ✗ | ✓ | ✗ | ✓ | ✗ |
| `activity_rsvps` | ✓ All | ✓ All | Own only | ✗ | Own only | ✗ | Own only |
| `activity_updates` | ✓ All | ✓ All | ✗ | ✓ | ✗ | ✓ | ✗ |
| `polls` | ✓ All | ✓ All | ✗ | ✓ | ✗ | ✓ | ✗ |
| `poll_options` | ✓ All | ✓ All | ✗ | ✓ | ✗ | ✗ | ✗ |
| `poll_votes` | ✓ All | ✓ All | Own only | ✗ | ✗ | ✗ | ✗ |
| `event_attendance` | ✓ All | ✓ All | ✗ | ✓ | ✗ | ✓ | ✗ |
| `challenges` | ✓ All | ✓ All | ✗ | ✓ | ✗ | ✓ | ✗ |
| `challenge_participants` | ✓ All | ✓ All | Own only | ✗ | ✗ | ✗ | Own only |
| `progress_logs` | Own only | ✓ All | Own only | ✗ | Own only | ✗ | ✗ |
| `recognitions` | Non-deleted | ✓ All | Own only | ✗ | ✗ | ✓ (soft-delete) | ✗ |
| `recognition_recipients` | ✓ All | ✓ All | Giver only | ✗ | ✗ | ✗ | ✗ |
| `recognition_reactions` | ✓ All | ✓ All | Own only | ✗ | ✗ | ✗ | Own only |
| `member_monthly_stats` | ✓ All | ✓ All | Service role only | Service role only | Service role only | Service role only | ✗ |
| `community_health_scores` | ✓ All | ✓ All | Service role only | Service role only | Service role only | Service role only | ✗ |
| `notification_inbox` | Own only | ✓ All | Service role only | Service role only | Own only (is_read) | ✗ | ✗ |
| `flagged_content` | ✗ | ✓ All | Own only | ✗ | ✗ | ✓ | ✗ |
| `pinned_announcements` | ✓ All | ✓ All | ✗ | ✓ | ✗ | ✓ | ✗ |
| `admin_audit_log` | ✗ | ✓ All | Service role only | Service role only | ✗ | ✗ | ✗ |

---

## Edge Cases and Threat Model

### Deactivated User Attempting Access
A user whose `is_active = false` holds a valid Supabase JWT (they haven't logged out). Every policy's [active-user-guard] includes `is_active = true`. The deactivated user fails this check on every single table — they cannot SELECT, INSERT, UPDATE, or DELETE any row anywhere in the schema. Deactivation takes effect immediately without requiring a JWT revocation.

### Member Reading Another Member's Notification Inbox
A member queries `notification_inbox`. The `notification_inbox_select_own` policy filters with `WHERE recipient_id = auth.uid()`. A member cannot see another member's notifications regardless of the query they issue — the database silently returns zero rows for any row not owned by them.

### Member Casting a Second Vote
A member attempts to INSERT a second `poll_votes` row for the same poll. The `poll_votes_insert_own` RLS policy permits it (it only checks `user_id = auth.uid()`), but the UNIQUE(poll_id, user_id) database constraint fires before the row is inserted, returning a constraint violation error. RLS and schema constraints work together — RLS does not need to duplicate constraint logic.

### Member Reading the Admin Audit Log
The `admin_audit_log_select_admin` policy requires `is_admin()` to return `true`. For a member, `is_admin()` returns `false`. The policy condition fails, and the member receives zero rows with no error. The existence and structure of the audit log is not revealed.

### Unauthenticated Request (No JWT)
`auth.uid()` returns `null`. Every policy's [active-user-guard] begins with `auth.uid() IS NOT NULL`. Null fails this check immediately. The EXISTS subquery never executes. All tables return zero rows or block operations for unauthenticated requests.

### Service Role Key (Edge Functions)
Requests made with the `service_role` JWT bypass RLS entirely — PostgreSQL does not evaluate any policy for service_role. This is intentional. Edge Functions validate their own inputs (checking that referenced content exists, that the acting user has appropriate permissions via their profile, etc.) before writing to the database. Tables like `notification_inbox`, `admin_audit_log`, `member_monthly_stats`, and `community_health_scores` are only writable via Edge Functions, making service_role the only write path.

### Member Escalating Their Own Role to Admin
A member attempts to UPDATE their own profile row and set `app_role = 'admin'`. The `profiles_update_own` policy permits a member to UPDATE their own row (`id = auth.uid()`). However, the `WITH CHECK` clause on this policy restricts which column values are allowed post-update — specifically, `app_role` must remain `'member'` for a member UPDATE. Only the `profiles_update_admin` policy (which requires `is_admin()`) permits changing `app_role`.

### Soft-Delete Bypass Attempt
A member attempts to hard-DELETE a `posts` row. There is no DELETE policy on `posts` for any role (`posts_delete_blocked` evaluates to `false`). PostgreSQL silently returns zero rows affected — no error, no deletion. The soft-delete pattern is enforced by the absence of a permissive DELETE policy, not by application-layer validation.

### Flagged Content Visibility
A member attempts to SELECT from `flagged_content`. The only SELECT policy on this table is `flagged_content_select_admin`, which requires `is_admin()`. For a member, this returns false. The member receives zero rows — they cannot see the moderation queue or know which content has been flagged.

---

## RLS Testing Strategy

RLS policies should be validated against each persona before any migration is deployed to staging or production. The following testing approach applies to all 26 tables.

### Test Setup
Supabase's SQL editor supports setting the JWT context for a query session. For each test, set the session to impersonate a specific user UUID before running the test query. Use separate test users: one active member, one active admin, one deactivated member, and no auth (anon).

### Test Matrix (per table)
Each table requires at minimum four test scenarios:

1. **Active member read** — confirm the member can see rows they are entitled to and cannot see rows they are not entitled to (e.g., no deleted posts, no other members' notifications, no audit log)
2. **Active admin read** — confirm the admin can see all rows including soft-deleted content
3. **Member write** — confirm members can INSERT/UPDATE their own rows and cannot INSERT/UPDATE rows belonging to others or rows requiring admin role
4. **Blocked operation** — confirm that operations with `false` policies (hard DELETE, INSERT on service_role-only tables) silently return zero rows affected with no error

### Key Assertions
- A member querying `notification_inbox` without a `WHERE recipient_id = auth.uid()` clause still receives only their own rows (the policy adds the filter automatically)
- A member attempting to INSERT into `admin_audit_log` or `member_monthly_stats` returns zero rows inserted with no error (not a permission error — RLS is silent)
- A deactivated user with a valid JWT gets zero rows on every table
- An unauthenticated request (null JWT) gets zero rows on every table
- Changing `app_role` via a member UPDATE attempt is rejected (WITH CHECK violation)

### Environment Testing Order
1. Test on local Docker (via `supabase start`) — fast iteration, destructive resets allowed
2. Test on staging Supabase project — shared with integration tests
3. Do not test RLS on production — policies are validated before promotion
