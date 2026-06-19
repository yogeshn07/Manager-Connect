# Backend Implementation Plan

## Overview

This document is the implementation blueprint for the Manager Connect backend. It covers folder structure, Edge Function design, repository and service layers, API roadmap, Realtime channels, and notification architecture. No production code is written here — this is a planning reference for implementation.

**Backend stack:** PostgreSQL v15+ via Supabase Pro · Deno 1.x Edge Functions · TypeScript strict mode · Supabase Auth · Supabase Realtime · Supabase Storage

**Architecture principle:** BaaS-first. PostgreSQL + RLS handles all standard CRUD. Edge Functions are used exclusively where server-side trust is required: multi-table atomic operations, 3rd-party integrations, scheduled work, and admin actions that bypass RLS.

---

## 1. Supabase Project Structure

```
supabase/
├── config.toml                    # Supabase CLI project config (project ref, port, auth settings)
├── seed.sql                       # One-time seed: Connect Buddy system profile
├── .env.local                     # Local dev secrets (never committed)
│
├── migrations/                    # 68 SQL migration files, 9 phases
│   ├── 20240101000001_create_profiles.sql
│   ├── 20240101000002_create_invitations.sql
│   ├── ... (see database-migrations-plan.md for full list)
│   └── 20240101000068_create_scheduled_cleanup_function.sql
│
└── functions/                     # All Deno Edge Functions
    ├── _shared/                   # Cross-function shared infrastructure
    │   ├── supabase-client.ts     # Admin client (service role) and user client factories
    │   ├── cors.ts                # CORS headers for all responses
    │   ├── errors.ts              # AppError class, error response serializer
    │   ├── crypto.ts              # SHA-256 token hashing (invite tokens)
    │   ├── auth.ts                # JWT extraction, requireAuth(), requireAdmin() guards
    │   ├── types.ts               # Shared TypeScript types and interfaces
    │   │
    │   ├── validators/            # Input validation (per-domain)
    │   │   ├── auth.validators.ts
    │   │   ├── feed.validators.ts
    │   │   ├── events.validators.ts
    │   │   ├── polls.validators.ts
    │   │   ├── growth.validators.ts
    │   │   ├── recognition.validators.ts
    │   │   ├── admin.validators.ts
    │   │   └── notifications.validators.ts
    │   │
    │   ├── repositories/          # Data access layer (one file per domain entity)
    │   │   ├── profiles.repository.ts
    │   │   ├── invitations.repository.ts
    │   │   ├── posts.repository.ts
    │   │   ├── post-mentions.repository.ts
    │   │   ├── activities.repository.ts
    │   │   ├── activity-updates.repository.ts
    │   │   ├── polls.repository.ts
    │   │   ├── attendance.repository.ts
    │   │   ├── challenges.repository.ts
    │   │   ├── recognitions.repository.ts
    │   │   ├── analytics.repository.ts
    │   │   ├── connect-buddy.repository.ts
    │   │   ├── notifications.repository.ts
    │   │   ├── flagged-content.repository.ts
    │   │   ├── pinned-announcements.repository.ts
    │   │   └── cleanup.repository.ts
    │   │
    │   ├── constants.ts           # Project-wide constants (CONNECT_BUDDY_PROFILE_ID)
    │   │
    │   └── services/              # External integrations and cross-cutting concerns
    │       ├── notification.service.ts   # Expo Push API dispatch
    │       └── audit.service.ts          # Admin audit log writes
    │
    ├── send-invitation/
    │   ├── index.ts               # HTTP handler
    │   └── use-case.ts            # Application logic
    ├── validate-invite-token/
    │   ├── index.ts
    │   └── use-case.ts
    ├── create-profile/
    │   ├── index.ts
    │   └── use-case.ts
    ├── create-post/
    │   ├── index.ts
    │   └── use-case.ts
    ├── post-connect-buddy-message/
    │   ├── index.ts
    │   └── use-case.ts
    ├── cancel-activity/
    │   ├── index.ts
    │   └── use-case.ts
    ├── post-activity-update/
    │   ├── index.ts
    │   └── use-case.ts
    ├── create-poll/
    │   ├── index.ts
    │   └── use-case.ts
    ├── close-poll/
    │   ├── index.ts
    │   └── use-case.ts
    ├── record-attendance/
    │   ├── index.ts
    │   └── use-case.ts
    ├── close-challenge/
    │   ├── index.ts
    │   └── use-case.ts
    ├── create-recognition/
    │   ├── index.ts
    │   └── use-case.ts
    ├── compute-monthly-stats/
    │   ├── index.ts
    │   └── use-case.ts
    ├── send-notification/
    │   ├── index.ts
    │   └── use-case.ts
    ├── scheduled-connect-buddy/
    │   ├── index.ts
    │   └── use-case.ts
    ├── resolve-flag/
    │   ├── index.ts
    │   └── use-case.ts
    ├── pin-announcement/
    │   ├── index.ts
    │   └── use-case.ts
    ├── deactivate-user/
    │   ├── index.ts
    │   └── use-case.ts
    ├── remove-user/
    │   ├── index.ts
    │   └── use-case.ts
    ├── revoke-invitation/
    │   ├── index.ts
    │   └── use-case.ts
    └── scheduled-cleanup/
        ├── index.ts
        └── use-case.ts
```

**Total: 21 Edge Functions × 2 files = 42 function files + 33 shared files**

---

## 2. Seed Data

`supabase/seed.sql` contains exactly one operation:

```sql
-- Connect Buddy system profile
-- Must run after migrations complete (profiles table must exist)
-- UUID matches the CONNECT_BUDDY_PROFILE_ID constant in _shared/constants.ts

INSERT INTO profiles (
  id, auth_user_id, full_name, app_role,
  is_system_account, is_active, onboarding_completed, created_at, updated_at
) VALUES (
  '00000000-0000-4000-8000-000000000001',
  NULL,                       -- no auth.users row; system account
  'Connect Buddy',
  'system',
  true, true, true,
  now(), now()
)
ON CONFLICT (id) DO NOTHING;
```

The Connect Buddy UUID `00000000-0000-4000-8000-000000000001` is a deliberate, recognizable constant. It is defined once in `_shared/constants.ts` and referenced by `connect-buddy.repository.ts`. It is never looked up from the database at runtime.

**Why hardcoded, not an environment variable:** The Connect Buddy profile is a singleton infrastructure constant, not a runtime configuration value. Using an environment variable adds an operational dependency — the env var must be set after every seed on every environment. A mismatch between the DB row's UUID and the env var causes a silent wrong-author bug. The hardcoded UUID eliminates this class of error entirely. The UUID is not a secret and carries no security risk in source code.

---

## 3. Shared Infrastructure Design

### 3.1 constants.ts

```typescript
// _shared/constants.ts
export const CONNECT_BUDDY_PROFILE_ID = '00000000-0000-4000-8000-000000000001';
```

The only project-wide constant file. Additional constants (e.g., pagination defaults, max image count) are added here as the implementation proceeds. Never import from this file into database migrations — the UUID must be kept in sync with `seed.sql` manually and is documented as such.

### 3.2 supabase-client.ts

Two client factories:
- `createAdminClient()` — uses `SUPABASE_SERVICE_ROLE_KEY`; bypasses RLS; used only in Edge Functions that require service-role access
- `createUserClient(jwt: string)` — uses caller's JWT; RLS enforced; used in all member-facing operations

The user client is preferred in all use cases where the caller is authenticated. The admin client is used for:
- Scheduled functions (no caller JWT)
- Cross-user admin operations (deactivate-user, remove-user)
- Notification dispatch (reads push tokens for other users)
- send-notification (writes inbox rows for other users)

### 3.3 cors.ts

Returns a CORS headers object for all responses. Allowed origins are configured per environment (dev: `*`; prod: explicit app domain or native scheme). All OPTIONS preflight requests return 200 with CORS headers and no body.

### 3.4 errors.ts

```
AppError {
  code: 'UNAUTHORIZED' | 'FORBIDDEN' | 'NOT_FOUND' | 'CONFLICT' | 'VALIDATION_ERROR' | 'SERVER_ERROR'
  message: string
  httpStatus: 401 | 403 | 404 | 409 | 422 | 500
}
```

`toErrorResponse(error: AppError): Response` — serializes to standard error envelope:
```json
{ "error": { "code": "...", "message": "..." } }
```

All unhandled errors are caught in `index.ts` and converted to `SERVER_ERROR` with status 500. Errors are never swallowed silently.

### 3.5 crypto.ts

`hashToken(rawToken: string): Promise<string>` — SHA-256 hex digest using Web Crypto API (Deno-native, no npm dependency). Used exclusively by `send-invitation` (to store) and `validate-invite-token` (to compare).

### 3.6 auth.ts

Three guards, each throws `AppError` if the condition is not met:
- `requireAuth(req: Request): Promise<{ userId: string; jwt: string }>` — extracts and verifies Bearer JWT
- `requireAdmin(userId: string, client: SupabaseClient): Promise<void>` — checks `profiles.app_role = 'admin'` and `is_active = true`
- `requireServiceRole(req: Request): void` — checks `Authorization: Bearer <SERVICE_ROLE_KEY>`

### 3.7 types.ts

Shared TypeScript interfaces matching the database schema. Key types:
- `Profile`, `Invitation`, `Post`, `Activity`, `Poll`, `PollOption`, `Challenge`, `Recognition`, `NotificationInbox`
- `NotificationType` enum (15 values)
- `AppRole`: `'member' | 'admin' | 'system'`
- Edge Function request/response shapes (referenced by both index.ts and use-case.ts)

---

## 4. Repository Layer Design

Each repository file in `_shared/repositories/` exports a class or plain functions that execute Supabase queries. Repositories do not contain business logic — they are pure data access with no conditional branching.

### Repository Responsibilities

| Repository | Key Operations |
|---|---|
| `profiles.repository.ts` | findById, findAllActive, findAllMembers (excl. system), update, anonymize (remove-user flow) |
| `invitations.repository.ts` | insert, findByTokenHash, findById, updateStatus (accepted/revoked/expired) |
| `posts.repository.ts` | insert, findFeed (paginated), findById, softDelete |
| `post-mentions.repository.ts` | insertMany (batch), findByPostId |
| `activities.repository.ts` | insert, findUpcoming, findById, cancel, findRsvpdUserIds (for notifications) |
| `activity-updates.repository.ts` | insert, findByActivityId |
| `polls.repository.ts` | insert (with options), findById, findExpired, close, findVoterIds |
| `attendance.repository.ts` | upsertMany (batch), findByActivityId, findByUserId |
| `challenges.repository.ts` | insert, findActive, findById, close, findParticipantIds |
| `recognitions.repository.ts` | insert (with recipients), findFeed, findById, softDelete |
| `analytics.repository.ts` | upsertMemberStats, upsertHealthScore, findStatsByMonth |
| `connect-buddy.repository.ts` | getSystemProfileId (returns hardcoded UUID constant) |
| `notifications.repository.ts` | insertMany (batch for inbox), findRecipientTokens, findUnvotedMembers |
| `flagged-content.repository.ts` | insert, findById, updateStatus |
| `pinned-announcements.repository.ts` | deactivateAll, insert, findActive |
| `cleanup.repository.ts` | hardDeleteOldPosts, hardDeleteOldComments, expireInvitations, pruneNotifications |

### Repository Pattern

Each repository accepts a `SupabaseClient` as its first argument (dependency injection). This makes repositories testable — tests can pass a mock client.

```typescript
// Pattern for all repository functions
export async function findProfileById(
  client: SupabaseClient,
  id: string
): Promise<Profile | null>
```

No repository function throws on "not found" — it returns `null`. The use case layer decides whether `null` is an error.

---

## 5. Service Layer Design

Services encapsulate 3rd-party integrations and audit concerns. There are two services: push notification dispatch and audit log writes.

**Email and SMS services are not included.** FR-01.1 requires that the admin can invite users by supplying an email or mobile number (to identify and record the invitee). It does not require the system to automatically deliver the invite link. For a 15–20 person community where the admin knows every member personally, `send-invitation` returns the raw invite URL in its response and the admin shares it via any channel (WhatsApp, direct message, etc.). This eliminates Resend, Twilio, and their associated failure modes. OTP delivery for login (FR-01.3) is handled natively by Supabase Auth — it is not custom code.

### 5.1 notification.service.ts

**Purpose:** Dispatch push notifications via Expo Push API.

**Key function:** `sendPushNotifications(messages: ExpoPushMessage[]): Promise<void>`

Implementation plan:
1. Accept an array of Expo push messages (each has `to`, `title`, `body`, `data`)
2. Chunk into batches of 100 (Expo API limit)
3. POST each batch to `https://exp.host/--/api/v2/push/send`
4. Inspect receipt for `DeviceNotRegistered` errors → nullify that push token in `profiles`
5. Log failed deliveries (do not retry in V1 — fire-and-forget for non-critical notifications)

**Called by:** `send-notification` use case only. No other use case calls Expo directly.

### 5.2 audit.service.ts

**Purpose:** Write to `admin_audit_log` for all admin actions. Always uses the admin Supabase client (service role) to ensure writes are never blocked by RLS.

**Key function:** `writeAuditEntry(client: SupabaseClient, entry: AuditEntry): Promise<void>`

```typescript
interface AuditEntry {
  admin_id: string
  action_type: AuditActionType   // 13 values from schema CHECK constraint
  target_type: string
  target_id: string
  metadata?: Record<string, unknown>
}
```

`writeAuditEntry` never throws — audit failures are logged to Edge Function stderr but do not fail the parent operation. Audit integrity is enforced by RLS (no DELETE, no UPDATE on audit log) not by application guarantees.

**Called by:** resolve-flag, pin-announcement, deactivate-user, remove-user, revoke-invitation, record-attendance, close-poll use cases.

---

## 6. Edge Function Implementation Plan

### 6.1 Internal Structure per Function

Every Edge Function follows the same internal pattern:

```
index.ts (HTTP handler)
  1. Parse method — return 405 if wrong method
  2. Handle OPTIONS (CORS preflight) — return 200
  3. Parse request body (JSON)
  4. Call use-case.ts with parsed input
  5. Return response with CORS headers

use-case.ts (Application logic)
  1. Auth guard (requireAuth / requireAdmin / requireServiceRole)
  2. Input validation (call validator from _shared/validators/)
  3. Business logic (call repositories and services)
  4. Return result object or throw AppError
```

The `index.ts` never contains business logic. The `use-case.ts` never constructs HTTP responses.

### 6.2 Function Catalog

#### Auth Module (Sprint 1)

**`send-invitation`**
- Auth: requireAdmin
- Flow: validate input → check no pending invite for email/phone → generate UUID token → hash token → insert invitation row → write audit entry → return invite_url (raw token embedded in deep-link) in response
- The admin copies the returned `invite_url` and delivers it via any channel (WhatsApp, direct message, etc.) — no automated email or SMS dispatch
- Idempotency: 409 if pending invite exists for same contact

**`validate-invite-token`**
- Auth: none (public)
- Flow: hash raw token → findByTokenHash → check status (pending) → check not expired → return invitation metadata (name, email, phone)
- No side effects

**`create-profile`**
- Auth: requireAuth (newly registered user, no profile yet)
- Flow: re-validate invite token → check no existing profile for auth user → insert profile row → update invitation status to 'accepted', accepted_by = new user id → trigger scheduled-connect-buddy with trigger_type='welcome' → write audit entry (member_registered)
- Atomicity: profile insert + invitation update in sequence; if either fails, both are retried

#### Feed Module (Sprint 2)

**`create-post`**
- Auth: requireAuth (active member)
- Flow: validate content (min 1 char, max 4 images) → insert post row → if image_storage_paths: insert post_images rows → parse content for @{uuid} mention patterns → insert post_mentions rows for each valid mention → call send-notification for each mentioned user (type: mention) → return post_id
- Side effects: post_mentions, send-notification (mentions only; feed updates arrive via Realtime)

**`post-connect-buddy-message`**
- Auth: requireServiceRole
- Flow: get Connect Buddy system profile ID from constant → insert post row (author_id = CB id) → if image_storage_paths: insert post_images rows → if notify_all=true: fetch all active member IDs → call send-notification (type: connect_buddy_update)
- Called internally by: create-profile (welcome), scheduled-connect-buddy

#### Events Module (Sprint 3)

**`cancel-activity`**
- Auth: requireAuth; verify caller is activity creator OR admin
- Flow: findActivityById → check not already cancelled → update status='cancelled', cancelled_at=now() → find all Going+Maybe RSVP user IDs → call send-notification (type: activity_cancelled)
- 409 if already cancelled

**`post-activity-update`**
- Auth: requireAuth; verify caller is activity creator
- Flow: findActivityById → check not cancelled → insert activity_updates row → find all Going+Maybe RSVP user IDs → call send-notification (type: activity_updated)

**`create-poll`**
- Auth: requireAdmin
- Flow: validate (question, min 2 options, max 10 options, closes_at in future) → if activity_id: verify activity exists and is active → insert poll row → insert poll_options rows (display_order 0-based) → call send-notification to all active members (type: poll_reminder) → return poll_id
- Atomicity: poll + options inserted together; if options insert fails, poll insert is rolled back

**`close-poll`**
- Auth: requireServiceRole OR requireAdmin
- Flow (single poll): findById → check not already closed → update is_closed=true, closed_at=now() → find voter IDs → call send-notification (type: poll_reminder, "results are in") → write audit entry
- Flow (batch): find all polls where closes_at < now() and is_closed=false → process each → return closed_count
- Idempotency: skips already-closed polls in batch mode

#### Growth Module (Sprint 4)

**`record-attendance`**
- Auth: requireAdmin
- Flow: validate records array (non-empty, valid statuses) → findActivityById → check activity event_date is in the past → validate all user_ids exist → batch upsert event_attendance rows (recorded_by=admin_id) → write audit entry (attendance_recorded, metadata: {activity_id, record_count})
- 409 if event_date is in the future

**`close-challenge`**
- Auth: requireServiceRole OR requireAdmin
- Flow (single): findById → check not already ended → update status='ended', ended_at=now() → find participant IDs → call send-notification (type: challenge_ended)
- Flow (batch): find all challenges where end_date < today and status='active' → process each
- Idempotency: no-op if already ended

#### Recognition Module (Sprint 5)

**`create-recognition`**
- Auth: requireAuth (active member)
- Flow: validate (min 1 recipient, valid category_tag, message max 500 chars) → verify all recipient_ids are active profiles → insert recognition row → insert recognition_recipients rows (one per recipient) → call send-notification for all recipients (type: recognition_received)

#### Analytics Module (Sprint 5)

**`compute-monthly-stats`**
- Auth: requireServiceRole
- Flow:
  1. Determine target stat_month (default: first day of previous month)
  2. Fetch all active members (is_system_account=false)
  3. For each member: run 6 aggregate queries against source tables for the month window
     - events_attended: COUNT(event_attendance WHERE status='attended' AND activity.event_date within month)
     - challenges_joined: COUNT(challenge_participants WHERE joined_at within month)
     - progress_logs_count: COUNT(progress_logs WHERE log_date within month)
     - recognitions_received: COUNT(recognition_recipients → recognitions WHERE created_at within month)
     - recognitions_given: COUNT(recognitions WHERE giver_id=user AND created_at within month)
     - posts_count: COUNT(posts WHERE author_id=user AND is_deleted=false AND created_at within month)
  4. Upsert all member rows into member_monthly_stats (ON CONFLICT user_id, stat_month DO UPDATE)
  5. Compute community health score from month aggregates (formula defined in analytics.repository.ts)
  6. Upsert into community_health_scores (ON CONFLICT score_month DO UPDATE)
- Idempotency: UPSERT on both tables; safe to re-run

#### Notifications Module (Sprint 5)

**`send-notification`**
- Auth: requireServiceRole (never callable by client JWT)
- Flow:
  1. Validate NotificationType enum value
  2. Fetch each recipient's profile (push_token, notification_preferences)
  3. Check preference key for this notification type — skip recipients who opted out
  4. Insert notification_inbox rows for ALL recipients (even opted-out — in-app inbox always receives)
  5. Push dispatch only to opted-in recipients who have a push_token
  6. Chunk into Expo Push API batches of 100
  7. Handle DeviceNotRegistered receipts → nullify push_token in profiles
  8. Return {sent_count, skipped_count}

**`scheduled-connect-buddy`**
- Auth: requireServiceRole
- Triggers:
  - `welcome` (called by create-profile): fetches new member's name, composes welcome message, calls post-connect-buddy-message
  - `monthly_highlights` (scheduled 1st of month, after compute-monthly-stats): reads member_monthly_stats for previous month, identifies top performers, composes highlight post, calls post-connect-buddy-message with notify_all=true
  - `event_reminder` (scheduled 24h before each event): fetches activity details, composes reminder, calls post-connect-buddy-message (does NOT send push — Category 1 handles that separately)
  - `poll_reminder` (scheduled 24h before poll closes): fetches poll, composes closing-soon post, calls post-connect-buddy-message
  - `achievement` (called by close-challenge when a member completes a challenge): fetches challenge and member details, composes achievement announcement, calls post-connect-buddy-message with notify_all=true
  - `community_update` (admin-triggered or milestone-driven): composes a community update post for significant platform events, calls post-connect-buddy-message with notify_all=true
  - `memory` (scheduled or admin-triggered): queries past events from previous months, composes a nostalgia post referencing the past event, calls post-connect-buddy-message with notify_all=true

#### Admin Module (Sprint 6)

**`resolve-flag`**
- Auth: requireAdmin
- Flow: findFlagById → check status='pending' → if action='delete': soft-delete flagged content (set is_deleted=true, deleted_by=admin_id) + update flag status='resolved_deleted' → if action='dismiss': update flag status='resolved_dismissed' → write audit entry (flag_resolved_deleted or flag_resolved_dismissed)

**`pin-announcement`**
- Auth: requireAdmin
- Flow (pin): findPostById → deactivateAll pinned_announcements → insert new pinned_announcements row → write audit entry
- Flow (unpin): deactivateAll pinned_announcements → write audit entry

**`deactivate-user`**
- Auth: requireAdmin
- Flow: findProfileById → check is_system_account=false → if deactivating: check is_active=true → update is_active=false, push_token=null → write audit entry (user_deactivated)
- Flow (reactivate=true): check is_active=false → update is_active=true → write audit entry (user_reactivated)

**`remove-user`**
- Auth: requireAdmin
- Flow: findProfileById → check is_system_account=false → update profile (full_name='Removed Member', nullify PII fields, is_active=false, push_token=null) → delete avatar from Supabase Storage (avatars/{user_id}/profile.jpg; non-fatal if not found) → write audit entry (user_removed)

**`revoke-invitation`**
- Auth: requireAdmin
- Flow: findInvitationById → check status='pending' → update status='revoked' → write audit entry (invitation_revoked)
- 409 if not pending

#### System Module (Sprint 6)

**`scheduled-cleanup`**
- Auth: requireServiceRole
- Operations (sequential, each failure is logged but does not stop the sequence):
  1. Hard DELETE posts WHERE is_deleted=true AND deleted_at < now()-30d
  2. Hard DELETE comments WHERE is_deleted=true AND deleted_at < now()-30d
  3. UPDATE invitations SET status='expired' WHERE status='pending' AND expires_at < now()
  4. DELETE notification_inbox WHERE created_at < now()-90d
  5. Call close-challenge use case (batch mode)
  6. Call close-poll use case (batch mode)
- Returns counts for each operation

---

## 7. API Implementation Roadmap

The backend API surface has three access patterns. This section maps each pattern to its implementation source.

### 7.1 Access Pattern Summary

| Pattern | Implementation | Auth | When to use |
|---|---|---|---|
| Supabase REST (PostgREST) | Auto-generated from schema + RLS | JWT (anon or user) | Standard CRUD, list queries, filters |
| Supabase Realtime | WebSocket subscriptions | JWT | Live updates (feed, polls, leaderboard, notifications) |
| Edge Functions | Deno functions in supabase/functions/ | JWT or service-role | Atomic multi-table ops, 3rd-party calls, admin, scheduled |

### 7.2 REST Operations (PostgREST — no custom code required)

These operations work automatically once migrations and RLS policies are applied. Client calls `supabase.from('table').select/insert/update/delete()`.

| Module | Operation count | Key tables |
|---|---|---|
| Auth/Profiles | 6 | profiles |
| Feed | 10 | posts, post_images, post_reactions, comments |
| Events | 14 | activities, activity_rsvps, activity_updates, event_attendance |
| Polls (read) | 4 | polls, poll_options, poll_votes |
| Growth | 9 | challenges, challenge_participants, progress_logs |
| Recognition | 8 | recognitions, recognition_recipients, recognition_reactions |
| Analytics | 7 | member_monthly_stats, community_health_scores |
| Notifications (read/update) | 4 | notification_inbox |
| Admin (read) | 4 | profiles, invitations, flagged_content, admin_audit_log |

**REST column selection rule:** All client queries must explicitly list columns (`select=col1,col2,...`). No `select=*` in production. PostgREST embedded joins are used to reduce round trips (e.g., posts with author profile data in one query).

**Pagination:** Default page size 20. Feed and recognition wall use keyset pagination on `created_at`. Event list uses keyset on `event_date`. All list queries order by a deterministic column.

### 7.3 Edge Function Operations (custom implementation required)

21 functions × 2 files = 42 files to implement. Sprint delivery order:

| Sprint | Functions | Count |
|---|---|---|
| Sprint 1 | send-invitation, validate-invite-token, create-profile | 3 |
| Sprint 2 | create-post, post-connect-buddy-message | 2 |
| Sprint 3 | cancel-activity, post-activity-update, create-poll, close-poll | 4 |
| Sprint 4 | close-challenge, record-attendance | 2 |
| Sprint 5 | compute-monthly-stats, create-recognition, send-notification, scheduled-connect-buddy | 4 |
| Sprint 6 | resolve-flag, pin-announcement, deactivate-user, remove-user, revoke-invitation, scheduled-cleanup | 6 |

### 7.4 Scheduler Configuration

Supabase scheduled functions use pg_cron (Supabase Pro) or an external CRON trigger. Configure in Supabase Dashboard → Edge Functions → Schedules.

| Function | Schedule | Trigger type |
|---|---|---|
| `compute-monthly-stats` | `0 1 1 * *` (1 AM on 1st of month) | pg_cron |
| `scheduled-connect-buddy` (monthly_highlights) | `0 2 1 * *` (2 AM on 1st — after stats) | pg_cron |
| `scheduled-cleanup` | `0 3 * * *` (3 AM daily) | pg_cron |
| `close-challenge` | `0 0 * * *` (midnight daily) | pg_cron |
| `close-poll` | `0 * * * *` (every hour) | pg_cron |
| `scheduled-connect-buddy` (event_reminder) | Per-event, 24h before event_date | Triggered by activities INSERT via database trigger OR pg_cron hourly scan |
| `scheduled-connect-buddy` (poll_reminder) | Per-poll, 24h before closes_at | Same pattern as event reminder |

---

## 8. Realtime Architecture

### 8.1 Channel Catalogue

Seven channels cover all live-update requirements.

---

**Channel 1: `feed:posts`**

| Attribute | Value |
|---|---|
| Table | `posts` |
| Events | INSERT only |
| Subscribers | All authenticated members (global channel, not per-resource) |
| Lifecycle | Subscribe on Feed tab mount; unsubscribe on Feed tab dismount |

**Purpose:** New posts — including Connect Buddy posts — appear at the top of the community feed without the user refreshing. Connect Buddy posts require no special handling; they are standard `posts` rows with a system author and arrive on this channel like any member post.

**Expected traffic:** Very low. 15–20 users, a handful of posts per day. At peak (e.g., immediately after a team event), 3–5 inserts within an hour. This channel is near-silent most of the time.

**Why Realtime is required:** The feed is the central social surface of the app. Manual pull-to-refresh breaks the community feel and means Connect Buddy automated posts (welcome messages, monthly highlights) do not surface until the user manually refreshes.

---

**Channel 2: `feed:reactions:{post_id}`**

| Attribute | Value |
|---|---|
| Table | `post_reactions` |
| Events | INSERT, UPDATE, DELETE |
| Filter | `post_id = eq.{post_id}` |
| Subscribers | Members currently viewing a specific post |
| Lifecycle | Subscribe on PostDetail screen open; unsubscribe on close |

**Purpose:** Emoji reaction counts update live while a member is reading a post — they can see others react in real time without leaving the screen.

**Expected traffic:** Very low. The channel is per-post and only active while someone is viewing that post. A single post might receive 2–5 reaction events in a session. Typically 0 events while viewing (post was already reacted to).

**Why Realtime is required:** Static reaction counts that require a page refresh make reactions feel inert. The social signal of watching counts change while reading is a core engagement mechanic. Without it, reactions appear invisible to the reacting member and stale to other viewers.

---

**Channel 3: `feed:comments:{post_id}`**

| Attribute | Value |
|---|---|
| Table | `comments` |
| Events | INSERT only |
| Filter | `post_id = eq.{post_id}` |
| Subscribers | Members currently viewing a specific post's thread |
| Lifecycle | Subscribe on PostDetail screen open; unsubscribe on close |

**Purpose:** New comments appear immediately in the thread while a member is reading it, enabling back-and-forth conversation without refreshing.

**Expected traffic:** Very low. Comment threads on a post are rarely simultaneous. The channel is per-post and short-lived. 0–2 events per session.

**Why Realtime is required:** Comment threads are conversational. If two members are replying to each other, one must see the other's message without polling. Without Realtime, the thread is a static page that requires exit-and-re-enter to see new replies.

---

**Channel 4: `activities:rsvps:{activity_id}`**

| Attribute | Value |
|---|---|
| Table | `activity_rsvps` |
| Events | INSERT, UPDATE, DELETE |
| Filter | `activity_id = eq.{activity_id}` |
| Subscribers | Members currently viewing an event detail screen |
| Lifecycle | Subscribe on EventDetail open; unsubscribe on close |

**Purpose:** RSVP attendee counts and the Going/Maybe/Not Going breakdown update live on the Event Detail screen as other members respond.

**Expected traffic:** Low with bursts. Traffic concentrates in the hours after an event is posted (initial RSVP wave following the notification) and near the event date. During a burst: 10–15 inserts over a few minutes. Outside bursts: silent.

**Why Realtime is required:** RSVP counts have a social tipping-point effect — members are more likely to commit Going when they see others already going. A stale count suppresses participation. The count must be accurate without requiring the user to leave and re-enter the screen.

---

**Channel 5: `events:poll_votes:{poll_id}`**

| Attribute | Value |
|---|---|
| Table | `poll_votes` |
| Events | INSERT only (votes are immutable — no UPDATE or DELETE) |
| Filter | `poll_id = eq.{poll_id}` |
| Subscribers | Members currently viewing a specific poll |
| Lifecycle | Subscribe on PollDetail open; unsubscribe on close |

**Purpose:** Live vote count and percentage bars update as community members vote on an open poll. The visual shifts in real time as votes arrive.

**Expected traffic:** Low with concentrated bursts. When a poll notification goes out, members who tap immediately may vote within a short window — potentially 10–20 inserts over a few minutes. After the initial burst, traffic drops to near zero for the remainder of the poll's life.

**Why Realtime is required:** Watching live percentage bars shift as people vote is the primary engagement mechanic for polls. A poll with static counts that require refresh has no sense of community momentum. The visual feedback is also what prompts members to look at who's winning before submitting their own vote.

---

**Channel 6: `growth:leaderboard:{challenge_id}`**

| Attribute | Value |
|---|---|
| Table | `progress_logs` |
| Events | INSERT, UPDATE |
| Filter | `challenge_id = eq.{challenge_id}` |
| Subscribers | Members currently viewing a challenge detail screen |
| Lifecycle | Subscribe on ChallengeDetail open; unsubscribe on close |

**Purpose:** The challenge leaderboard re-ranks live after a participant logs daily progress. A member who just logged 8,000 steps sees their position update immediately.

**Expected traffic:** Very low. Progress is logged once per participant per day per challenge. At most 15–20 inserts per day spread across 24 hours. While viewing the leaderboard screen, 0–1 events are likely.

**Why Realtime is required:** Immediate rank feedback after logging is the core motivation loop for challenge participation. A delayed leaderboard removes the dopamine signal that drives daily engagement. Without Realtime, the leaderboard is stale for the rest of the session after a member logs progress.

---

**Channel 7: `notifications:inbox:{user_id}`**

| Attribute | Value |
|---|---|
| Table | `notification_inbox` |
| Events | INSERT only |
| Filter | `recipient_id = eq.{user_id}` |
| Subscribers | Own user only (RLS also enforces this at the database level) |
| Lifecycle | Subscribe at app startup after authentication; unsubscribe on logout. This is the only permanent channel — not tied to a specific screen |

**Purpose:** The unread notification badge count and inbox list update live when the server dispatches a new notification to this user. The badge on the Profile tab increments without the user navigating away and back.

**Expected traffic:** Low but steady. Notifications arrive triggered by events across the platform — a mention, a recognition, an event cancellation. Across all platform activity this may be 0–15 inserts per user per day. Each user's channel receives only their own rows (enforced by both the filter and RLS).

**Why Realtime is required:** This is the only channel that must be permanently active for the session. Without it, the unread badge count is stale until the user navigates to the notifications screen. Polling every N seconds is the alternative, but at 15–20 users even a short polling interval creates unnecessary load, drains battery, and adds latency. The Realtime channel costs nothing at this scale and delivers badge updates within milliseconds of dispatch.

### 8.2 RLS on Realtime

Supabase Realtime respects RLS. Clients receive change events only for rows their RLS policy permits them to SELECT. This means:
- `notifications:inbox:{user_id}` — user only receives events for their own rows (RLS: `recipient_id = auth.uid()`)
- `feed:posts` — soft-deleted posts (is_deleted=true) do not appear because the RLS SELECT policy filters `WHERE is_deleted = false`
- `events:poll_votes:{poll_id}` — all authenticated members can see poll votes (RLS: all authenticated)

### 8.3 Client Subscription Pattern (Flutter)

```
// On widget mount (initState or ref.listen equivalent):
_channel = supabase.channel('channel-name')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'table_name',
    filter: PostgresChangeFilter(type: FilterType.eq, column: 'col', value: id),
    callback: (payload) { /* update local state */ }
  )
  .subscribe();

// On widget dismount (dispose):
supabase.removeChannel(_channel);
```

The client does not poll. All live data arrives via Realtime. Initial data is loaded via REST on mount, then Realtime keeps it up to date.

### 8.4 Connection Management

- Supabase Realtime uses a single WebSocket connection shared across all channels
- The client subscribes to channels on screen open and unsubscribes on screen close — not on app background/foreground
- On reconnection after network loss, `supabase_flutter` SDK handles re-authentication and channel re-subscription automatically
- The `notifications:inbox:{user_id}` channel is permanent for the session duration (not tied to a specific screen)

---

## 9. Notification Architecture Implementation Plan

### 9.1 Infrastructure Components

| Component | Technology | Where configured |
|---|---|---|
| Push token registration | `firebase_messaging` (Flutter) | On app startup, after auth |
| iOS delivery | APNs via FCM | Firebase Console + App Store entitlement |
| Android delivery | FCM | Firebase Console |
| Server-side dispatch | Expo Push API (HTTP) | notification.service.ts |
| Token storage | `profiles.push_token` | Updated via REST PATCH |
| User preferences | `profiles.notification_preferences` (JSONB) | Updated via REST PATCH |
| In-app inbox | `notification_inbox` table | Realtime + REST |

**Note on Expo Push API:** Despite the mobile client using Flutter (not Expo), the Expo Push API can be used as a server-side push aggregator — it accepts FCM/APNs tokens directly and routes to the correct service. If Expo Push is not preferred, the alternative is direct FCM HTTP v1 API for Android and APNs HTTP/2 API for iOS, implemented in notification.service.ts.

### 9.2 Token Lifecycle

| Event | Action | Implementation |
|---|---|---|
| First app launch | Request permission → store token | Flutter: `FirebaseMessaging.instance.requestPermission()` + `getToken()` → PATCH profiles |
| Token refresh | Update stored token | Flutter: `onTokenRefresh` stream → PATCH profiles |
| User logout | Nullify token | REST PATCH `push_token = null` |
| User deactivated | Nullify token | deactivate-user use case |
| DeviceNotRegistered receipt | Nullify token | notification.service.ts receipt handler |

### 9.3 Notification Types and Preference Keys

| NotificationType | Preference Key | Default | Who receives |
|---|---|---|---|
| `activity_created` | `activity_reminders` | ON | All members |
| `activity_reminder_24h` | `activity_reminders` | ON | Going + Maybe RSVPs |
| `activity_reminder_1h` | `activity_reminders` | ON | Going RSVPs |
| `activity_cancelled` | `activity_reminders` | ON | Going + Maybe RSVPs |
| `activity_updated` | `activity_reminders` | ON | Going + Maybe RSVPs |
| `recognition_received` | `recognitions_received` | ON | Named recipients |
| `challenge_created` | `challenge_reminders` | ON | All members |
| `challenge_ending` | `challenge_reminders` | ON | All participants |
| `challenge_ended` | `challenge_reminders` | ON | All participants |
| `mention` | `mentions` | ON | Mentioned user |
| `comment_on_post` | `comments_on_my_posts` | ON | Post author |
| `poll_reminder` | `poll_reminders` | ON | Context-dependent (see below) |
| `connect_buddy_update` | `connect_buddy_updates` | ON | All members (highlights/achievements) |
| `admin_flag` | n/a (always delivered) | — | Admin users only |
| `admin_member_registered` | n/a (always delivered) | — | Admin users only |

**poll_reminder usage:**
- On poll creation → all members
- On poll closing soon (24h before) → members who have NOT yet voted
- On poll closed → all members (results ready)

### 9.4 In-App Notification Inbox

**Schema:** `notification_inbox` table with `recipient_id`, `actor_id` (nullable), `type`, `title`, `body`, `reference_type`, `reference_id`, `is_read`, `read_at`, `created_at`.

**Inbox behavior:**
- Every notification is written to the inbox regardless of push preference (even opted-out recipients see it in-app)
- Realtime channel `notifications:inbox:{user_id}` delivers new entries live (badge count updates without polling)
- Mark as read: REST PATCH on individual row or bulk PATCH on all unread rows
- Inbox is pruned after 90 days by `scheduled-cleanup`

**Deep link routing from notification tap:**

| NotificationType | Target Screen |
|---|---|
| `activity_created`, `activity_cancelled`, `activity_updated`, `activity_reminder_*` | `/events/{reference_id}` |
| `recognition_received` | `/analytics/recognition/{reference_id}` |
| `challenge_created`, `challenge_ending`, `challenge_ended` | `/growth/{reference_id}` |
| `mention` | `/feed/post/{reference_id}` |
| `comment_on_post` | `/feed/post/{reference_id}` |
| `poll_reminder` | `/events/poll/{reference_id}` |
| `connect_buddy_update` | `/feed/post/{reference_id}` |
| `admin_flag` | `/admin/flags/{reference_id}` |
| `admin_member_registered` | `/admin/members` |

Deep link routing on tap is handled by GoRouter in Flutter. The notification `data.targetScreen` field carries the path. Unauthenticated taps (app not open) redirect to auth flow first, then resume the deep link after login.

### 9.5 Notification Dispatch Flow

```
Triggering event (Edge Function use case completes)
  │
  ▼
Call send-notification function with:
  - recipient_ids: string[]
  - type: NotificationType
  - title: string
  - body: string
  - reference_type: string | null
  - reference_id: uuid | null
  │
  ▼
send-notification use case:
  1. For each recipient_id:
     a. Fetch profile (push_token, notification_preferences)
     b. Check preference key — record opted-out status
     c. Insert notification_inbox row (ALL recipients, regardless of preference)
  2. Collect push_tokens for opted-in recipients
  3. Build Expo push messages (title, body, data.type, data.targetScreen)
  4. POST to Expo Push API in batches of 100
  5. Handle DeviceNotRegistered → nullify push_token
```

**Admin notifications** (admin_flag, admin_member_registered) skip the preference check and always deliver push to admin users.

### 9.6 Foreground Notification Handling (Flutter)

When the app is in the foreground:
- `firebase_messaging` `onMessage` stream receives the push
- `flutter_local_notifications` displays a local notification overlay
- Tapping the overlay navigates to the target screen via GoRouter

When the app is in the background or closed:
- System delivers the push notification natively
- Tapping it opens the app; `firebase_messaging` `getInitialMessage` / `onMessageOpenedApp` provides the payload
- GoRouter reads the payload and navigates to the correct screen

---

## 10. Security Implementation Checklist

These items must be verified before each sprint's Edge Functions go to staging.

### Per Edge Function
- [ ] Correct auth guard applied (requireAuth / requireAdmin / requireServiceRole)
- [ ] All input validated before any database write
- [ ] Service role client used only where necessary (not defaulted to)
- [ ] CORS headers present on all responses including error responses
- [ ] AppError thrown (not bare Error) so index.ts can serialize correctly
- [ ] Audit log written for all admin-category actions

### Global Backend
- [ ] RLS enabled on all 26 tables (verify in Supabase dashboard)
- [ ] Service role key and Expo push token stored in Supabase Edge Function secrets / CI env only — not in repository
- [ ] `SUPABASE_SERVICE_ROLE_KEY` not present in any client-side Flutter code
- [ ] Connect Buddy profile protected (is_system_account check in deactivate-user and remove-user)
- [ ] Migration files committed to repository before any Edge Function deploy
- [ ] TypeScript types regenerated after each migration: `supabase gen types typescript`

---

## 11. Development Environment Setup

### Local Supabase

```bash
# Prerequisites: Docker Desktop running
supabase start                    # Start local Supabase stack
supabase db push                  # Apply all migrations
supabase db seed                  # Run seed.sql (Connect Buddy profile)
supabase functions serve          # Serve all Edge Functions locally (hot reload)
```

### Environment Variables (local .env.local)

```
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<local anon key from supabase start output>
SUPABASE_SERVICE_ROLE_KEY=<local service role key>
EXPO_ACCESS_TOKEN=<expo push token for push notification dispatch>
```

### Testing Edge Functions Locally

```bash
# Test a single function (with service role auth for scheduled functions)
curl -X POST http://localhost:54321/functions/v1/send-invitation \
  -H "Authorization: Bearer <admin-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"invitee_name":"Test User","invitee_email":"test@example.com"}'
```

### TypeScript Type Generation

Run after every migration:
```bash
supabase gen types typescript --local > src/types/database.ts
```

The generated types are imported by repositories and validators. They are not manually edited.

---

## 12. Implementation Order Summary

The following is the recommended implementation order within each sprint, based on inter-dependencies.

### Sprint 1 (Foundation)
1. `_shared/` infrastructure (constants, supabase-client, cors, errors, auth, types, crypto)
2. `_shared/services/` (audit.service — needed by create-profile)
3. `_shared/repositories/` (profiles, invitations)
4. `_shared/validators/` (auth.validators)
5. Edge Functions: validate-invite-token → send-invitation → create-profile

### Sprint 2 (Feed)
1. `_shared/repositories/` (posts, post-mentions, connect-buddy)
2. `_shared/validators/` (feed.validators)
3. Edge Functions: post-connect-buddy-message → create-post

### Sprint 3 (Events)
1. `_shared/repositories/` (activities, activity-updates, polls)
2. `_shared/validators/` (events.validators, polls.validators)
3. Edge Functions: create-poll → close-poll → cancel-activity → post-activity-update

### Sprint 4 (Growth + Attendance)
1. `_shared/repositories/` (challenges, attendance)
2. `_shared/validators/` (growth.validators)
3. Edge Functions: close-challenge → record-attendance

### Sprint 5 (Analytics + Notifications + Recognition)
1. `_shared/repositories/` (recognitions, analytics, notifications)
2. `_shared/services/` (notification.service)
3. `_shared/validators/` (recognition.validators, notifications.validators)
4. Edge Functions: send-notification → create-recognition → compute-monthly-stats → scheduled-connect-buddy

### Sprint 6 (Admin + System)
1. `_shared/repositories/` (flagged-content, pinned-announcements, cleanup)
2. `_shared/validators/` (admin.validators)
3. Edge Functions: revoke-invitation → resolve-flag → pin-announcement → deactivate-user → remove-user → scheduled-cleanup

---

## Document Cross-References

| Topic | Authoritative Document |
|---|---|
| Database schema (columns, constraints, CHECK values) | `database-schema-design.md` |
| Entity definitions | `database-entity-catalogue.md` |
| RLS policy matrix | `database-strategy.md` |
| ER diagrams | `database-er-diagram.md` |
| Migration files (68) | `database-migrations-plan.md` |
| Edge Function API contracts (request/response shapes) | `backend-api-contracts.md` |
| Backend architecture principles | `backend-architecture.md` |
| Folder structure (supabase/ tree) | `backend-folder-structure.md` |
| Notification categories, payload design, preferences | `notification-strategy.md` |
| Auth, RLS, data protection | `security-strategy.md` |
| Sprint schedule and task breakdown | `development-roadmap.md` |
| Flutter client architecture | `flutter-architecture.md` |
