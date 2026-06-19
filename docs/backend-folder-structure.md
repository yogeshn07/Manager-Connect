# Backend Folder Structure

## Overview

Manager Connect's backend spans two locations in the repository:

- `supabase/` — The Supabase project: database migrations, seed data, and Edge Functions (Deno)
- `src/` — The mobile client: service layer, hooks, stores, and realtime subscriptions

Both follow the same architectural principles: module boundaries by domain, shared infrastructure in `_shared/`, no cross-module imports.

---

## `supabase/` — Supabase Project

```
supabase/
│
├── config.toml                          # Supabase project configuration
│                                        # Project ref, region, auth settings,
│                                        # storage bucket definitions, Edge Function secrets
│
├── seed.sql                             # Initial data for dev/staging environments
│                                        # Seeds the Connect Buddy system account profile
│                                        # Seeds an admin user profile
│                                        # Seeds predefined interest tags constant
│
├── migrations/                          # Versioned, ordered schema migrations
│   │                                    # Applied via: supabase db push
│   │                                    # Named: {timestamp}_{description}.sql
│   │
│   ├── 20260101000001_create_tables.sql         # All 26 table definitions
│   ├── 20260101000002_rls_policies.sql          # All RLS policies per table
│   ├── 20260101000003_indexes.sql               # All secondary indexes
│   ├── 20260101000004_triggers.sql              # updated_at auto-update triggers
│   ├── 20260101000005_functions.sql             # is_admin() helper function
│   └── 20260101000006_storage_buckets.sql       # avatars and post-images bucket config
│
└── functions/                           # Deno Edge Functions
    │
    ├── _shared/                         # Code shared across all Edge Functions
    │   │                                # Imported via relative path: '../_shared/...'
    │   │                                # NOT a deployed function itself
    │   │
    │   ├── supabase-client.ts           # Supabase admin client (service role)
    │   │                                # Initialized once, exported as singleton
    │   │                                # Uses SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY
    │   │                                # This client BYPASSES RLS — use with care
    │   │
    │   ├── cors.ts                      # CORS response headers
    │   │                                # corsHeaders() → Record<string, string>
    │   │                                # Attached to all HTTP responses
    │   │
    │   ├── errors.ts                    # Error types and HTTP response factory
    │   │                                # AppError class with code + message
    │   │                                # httpError(status, message) → Response
    │   │                                # Standardized error codes:
    │   │                                #   UNAUTHORIZED, FORBIDDEN, NOT_FOUND,
    │   │                                #   VALIDATION_ERROR, CONFLICT, SERVER_ERROR
    │   │
    │   ├── crypto.ts                    # Cryptographic utilities
    │   │                                # hashToken(token: string) → string
    │   │                                # Implements SHA-256 via Web Crypto API
    │   │                                # Used to hash invite tokens before storage
    │   │
    │   ├── auth.ts                      # JWT verification helpers
    │   │                                # getCallerProfile(req) → Profile | null
    │   │                                # assertAdmin(profile) → void (throws if not admin)
    │   │                                # assertAuthenticated(req) → Profile (throws if no JWT)
    │   │
    │   ├── types.ts                     # Shared TypeScript types
    │   │                                # Re-exports from database types
    │   │                                # Defines request/response DTOs for each function
    │   │                                # Defines internal domain types (NotificationPayload, etc.)
    │   │
    │   ├── validators/                  # Input validation — one file per domain
    │   │   ├── invitation.validators.ts # Validates send-invitation input
    │   │   ├── profile.validators.ts    # Validates create-profile input
    │   │   ├── post.validators.ts       # Validates create-post input
    │   │   ├── activity.validators.ts   # Validates cancel-activity, post-update input
    │   │   ├── poll.validators.ts       # Validates create-poll, vote input
    │   │   ├── attendance.validators.ts # Validates record-attendance batch input
    │   │   ├── challenge.validators.ts  # Validates close-challenge input
    │   │   ├── recognition.validators.ts# Validates create-recognition input
    │   │   └── admin.validators.ts      # Validates all admin action inputs
    │   │
    │   ├── repositories/                # Data access layer — one file per entity group
    │   │   │                            # All functions are async, return typed objects
    │   │   │                            # All errors are caught and re-thrown as AppError
    │   │   │
    │   │   ├── profiles.repository.ts   # findById, create, updatePii, deactivate,
    │   │   │                            # anonymize, updatePushToken, updateLastActive
    │   │   │                            # findSystemAccount() → Connect Buddy profile
    │   │   │
    │   │   ├── invitations.repository.ts# findByTokenHash, create, accept,
    │   │   │                            # revoke, markExpired, listPending
    │   │   │
    │   │   ├── posts.repository.ts      # softDelete, extractMentions
    │   │   │                            # (standard reads done via PostgREST from client)
    │   │   │
    │   │   ├── post-mentions.repository.ts # bulkInsert(postId, userIds[])
    │   │   │
    │   │   ├── activities.repository.ts # findById, cancel, listRsvpRecipients,
    │   │   │                            # listPastWithoutAttendance
    │   │   │
    │   │   ├── activity-updates.repository.ts # create(activityId, authorId, content)
    │   │   │
    │   │   ├── polls.repository.ts      # create(pollData, options[]) — atomic
    │   │   │                            # findById, closePoll(pollId)
    │   │   │                            # listVoterIds(pollId) — for notifications
    │   │   │                            # getResults(pollId) → option vote counts
    │   │   │
    │   │   ├── attendance.repository.ts # batchUpsert(activityId, records[])
    │   │   │                            # findByActivity(activityId)
    │   │   │                            # findByUser(userId)
    │   │   │
    │   │   ├── challenges.repository.ts # findExpired, closeChallenge,
    │   │   │                            # listParticipantIds
    │   │   │
    │   │   ├── recognitions.repository.ts # create, bulkInsertRecipients, softDelete
    │   │   │
    │   │   ├── analytics.repository.ts  # computeMemberStats(userId, month) → MemberStats
    │   │   │                            # upsertMemberMonthlyStats(stats[])
    │   │   │                            # computeCommunityHealthScore(month) → HealthScore
    │   │   │                            # upsertCommunityHealthScore(score)
    │   │   │                            # getMonthlyRankings(month) → RankedMember[]
    │   │   │                            # getAllTimeRankings() → RankedMember[]
    │   │   │
    │   │   ├── connect-buddy.repository.ts # getSystemAccountId() → uuid
    │   │   │                               # createPost(content, imagePaths?) → Post
    │   │   │                               # Inserts posts authored by the Connect Buddy
    │   │   │                               # system profile using service-role client
    │   │   │
    │   │   ├── notifications.repository.ts # bulkInsert (notification_inbox rows)
    │   │   │                               # listPushTokensForUsers
    │   │   │
    │   │   ├── flagged-content.repository.ts # findById, resolve, markDeleted
    │   │   │
    │   │   ├── pinned-announcements.repository.ts # deactivateAll, create
    │   │   │
    │   │   └── cleanup.repository.ts    # hardDeleteExpiredContent,
    │   │                                # expireOldInvitations,
    │   │                                # pruneOldNotifications
    │   │
    │   └── services/                    # Side-effect services — third-party integrations
    │       │
    │       ├── notification.service.ts  # Notification dispatch
    │       │                            # dispatch(payload: NotificationPayload) → void
    │       │                            # Fetches push tokens from repository
    │       │                            # Checks notification_preferences per recipient
    │       │                            # Writes notification_inbox rows
    │       │                            # Calls FCM HTTP v1 API (or Expo Push API) in batches
    │       │
    │       └── audit.service.ts         # Admin audit log writing
    │                                    # log(adminId, actionType, targetType,
    │                                    #     targetId?, metadata?) → void
    │                                    # Always writes via service-role client
    │                                    # Atomic: throws if write fails (callers must handle)
    │
    │   ─────────────────────────────────────────────────
    │   Edge Functions (one directory = one deployed function)
    │   Each directory must contain index.ts as the entry point
    │   ─────────────────────────────────────────────────
    │
    ├── send-invitation/                 # MODULE: auth | CALLER: admin
    │   ├── index.ts                     # Handler: POST /send-invitation
    │   │                                # Auth: JWT required, admin role
    │   │                                # Validates body with invitation.validators
    │   │                                # Calls use case, returns 200 { invitation_id }
    │   └── use-case.ts                  # generateToken() → raw token
    │                                    # hashToken(raw) → hash
    │                                    # invitations.repository.create(...)
    │                                    # Returns { invite_url } — admin shares manually
    │                                    # audit.service.log('user_invited', ...)
    │
    ├── validate-invite-token/           # MODULE: auth | CALLER: unauthenticated
    │   ├── index.ts                     # Handler: POST /validate-invite-token
    │   │                                # Auth: none (public, token is the credential)
    │   │                                # Returns invitee details if token valid
    │   └── use-case.ts                  # hashToken(rawToken)
    │                                    # invitations.repository.findByTokenHash(hash)
    │                                    # Validate: status='pending', not expired
    │                                    # Returns { invitee_name, invitee_email, invitee_phone }
    │
    ├── create-profile/                  # MODULE: auth | CALLER: newly-authed user
    │   ├── index.ts                     # Handler: POST /create-profile
    │   │                                # Auth: JWT required (new user, no profile yet)
    │   │                                # Body: { token, full_name, title?, bio?,
    │   │                                #         avatar_storage_path?, interest_tags? }
    │   └── use-case.ts                  # validate-invite-token (re-checks token)
    │                                    # profiles.repository.create(authUserId, ...)
    │                                    # invitations.repository.accept(inviteId, profileId)
    │                                    # notification.service.dispatch to admin:
    │                                    #   'admin_member_registered'
    │
    ├── create-post/                     # MODULE: feed | CALLER: any member
    │   ├── index.ts                     # Handler: POST /create-post
    │   │                                # Auth: JWT required
    │   │                                # Body: { content, image_storage_paths? }
    │   └── use-case.ts                  # Insert post (via service-role for atomicity)
    │                                    # parseMentions(content) → userId[]
    │                                    # post-mentions.repository.bulkInsert(postId, ids)
    │                                    # If images: insert post_images rows
    │                                    # notification.service.dispatch to mentioned users:
    │                                    #   'mention'
    │
    ├── create-recognition/              # MODULE: recognition | CALLER: any member
    │   ├── index.ts                     # Handler: POST /create-recognition
    │   │                                # Auth: JWT required
    │   │                                # Body: { recipient_ids[], category_tag, message }
    │   └── use-case.ts                  # recognitions.repository.create(giverId, ...)
    │                                    # recognitions.repository.bulkInsertRecipients(
    │                                    #   recognitionId, recipientIds)
    │                                    # notification.service.dispatch to recipients:
    │                                    #   'recognition_received'
    │
    ├── create-poll/                     # MODULE: events | CALLER: any member or admin
    │   ├── index.ts                     # Handler: POST /create-poll
    │   │                                # Auth: JWT required
    │   │                                # Body: { question, options[], closes_at,
    │   │                                #         activity_id? }
    │   └── use-case.ts                  # polls.repository.create(pollData, options[])
    │                                    #   Atomic: insert poll + poll_options together
    │                                    # If activity_id: validate activity exists
    │                                    # notification.service.dispatch to all members:
    │                                    #   'poll_reminder' (optional: skip if quiet)
    │                                    # Returns { poll_id, created_at }
    │
    ├── close-poll/                      # MODULE: events | CALLER: scheduled or admin
    │   ├── index.ts                     # Handler: POST /close-poll
    │   │                                # Auth: service-role key OR admin JWT
    │   │                                # Body: { poll_id? } null = process all expired
    │   └── use-case.ts                  # If no poll_id: find all polls where
    │                                    #   closes_at < now() AND is_closed = false
    │                                    # For each: polls.repository.closePoll(pollId)
    │                                    #   sets is_closed = true
    │                                    # polls.repository.listVoterIds(pollId)
    │                                    # notification.service.dispatch to voters:
    │                                    #   'poll_reminder' (results available)
    │                                    # audit.service.log('poll_closed', ...)
    │                                    # Returns { closed_count, poll_ids[] }
    │
    ├── record-attendance/               # MODULE: events | CALLER: admin
    │   ├── index.ts                     # Handler: POST /record-attendance
    │   │                                # Auth: JWT required, admin role
    │   │                                # Body: { activity_id, records: [
    │   │                                #           { user_id, status }
    │   │                                #         ] }
    │   └── use-case.ts                  # assertAdmin(caller)
    │                                    # activities.repository.findById(activityId)
    │                                    # Validate: activity event_date has passed
    │                                    # attendance.repository.batchUpsert(
    │                                    #   activityId, records, recordedBy)
    │                                    # audit.service.log('attendance_recorded', ...)
    │                                    # Returns { recorded_count }
    │
    ├── compute-monthly-stats/           # MODULE: analytics | CALLER: scheduled
    │   ├── index.ts                     # Handler: POST /compute-monthly-stats
    │   │                                # Auth: service-role key ONLY
    │   │                                # Internal scheduled function — runs on 1st of month
    │   │                                # Body: { stat_month? } defaults to previous month
    │   └── use-case.ts                  # For each active profile (is_system_account=false):
    │                                    #   analytics.repository.computeMemberStats(
    │                                    #     userId, previousMonth)
    │                                    #   Aggregates from: event_attendance,
    │                                    #     challenge_participants, progress_logs,
    │                                    #     recognition_recipients, recognitions,
    │                                    #     posts (excluding system account posts)
    │                                    # analytics.repository.upsertMemberMonthlyStats(
    │                                    #   allMemberStats[])
    │                                    # analytics.repository.computeCommunityHealthScore(
    │                                    #   previousMonth)
    │                                    # analytics.repository.upsertCommunityHealthScore(score)
    │                                    # Returns { members_computed, month }
    │
    ├── post-connect-buddy-message/      # MODULE: feed | CALLER: other Edge Functions (internal)
    │   ├── index.ts                     # Handler: POST /post-connect-buddy-message
    │   │                                # Auth: service-role key ONLY
    │   │                                # Internal function — not client-callable
    │   │                                # Body: { content, image_storage_paths?,
    │   │                                #         notify_all?: boolean,
    │   │                                #         notification_title?, notification_body? }
    │   └── use-case.ts                  # connect-buddy.repository.getSystemAccountId()
    │                                    # connect-buddy.repository.createPost(content, images?)
    │                                    # If notify_all:
    │                                    #   profiles.repository.listAllActiveIds()
    │                                    #   notification.service.dispatch to all:
    │                                    #     'connect_buddy_update'
    │                                    # Returns { post_id }
    │
    ├── scheduled-connect-buddy/         # MODULE: feed | CALLER: scheduled
    │   ├── index.ts                     # Handler: POST /scheduled-connect-buddy
    │   │                                # Auth: service-role key ONLY
    │   │                                # Internal scheduled function — multiple triggers:
    │   │                                #   • New member welcome (on profile create)
    │   │                                #   • Monthly highlights (1st of month)
    │   │                                #   • Event reminders (24h before event)
    │   │                                #   • Poll reminders (closing in 24h)
    │   │                                # Body: { trigger_type: string, context?: object }
    │   └── use-case.ts                  # Routes to appropriate sub-handler by trigger_type:
    │                                    # 'welcome' → compose welcome message for new member
    │                                    # 'monthly_highlights' → compose highlights from
    │                                    #   member_monthly_stats for previous month
    │                                    # 'event_reminder' → compose event reminder post
    │                                    # 'poll_reminder' → compose poll closing reminder
    │                                    # All routes call:
    │                                    #   post-connect-buddy-message use-case internally
    │
    ├── cancel-activity/                 # MODULE: events | CALLER: activity creator or admin
    │   ├── index.ts                     # Handler: POST /cancel-activity
    │   │                                # Auth: JWT required
    │   │                                # Body: { activity_id }
    │   └── use-case.ts                  # activities.repository.findById(id)
    │                                    # Assert caller is creator OR is_admin
    │                                    # activities.repository.cancel(id)
    │                                    # activities.repository.listRsvpRecipients(id)
    │                                    # notification.service.dispatch to rsvp recipients:
    │                                    #   'activity_cancelled'
    │
    ├── post-activity-update/            # MODULE: events | CALLER: activity creator
    │   ├── index.ts                     # Handler: POST /post-activity-update
    │   │                                # Auth: JWT required
    │   │                                # Body: { activity_id, content }
    │   └── use-case.ts                  # activities.repository.findById(id)
    │                                    # Assert caller is creator
    │                                    # activity-updates.repository.create(...)
    │                                    # activities.repository.listRsvpRecipients(id)
    │                                    # notification.service.dispatch to recipients:
    │                                    #   'activity_updated'
    │
    ├── close-challenge/                 # MODULE: growth | CALLER: scheduler / admin
    │   ├── index.ts                     # Handler: POST /close-challenge
    │   │                                # Auth: service-role key OR admin JWT
    │   │                                # Body: { challenge_id? } null = process all expired
    │   └── use-case.ts                  # challenges.repository.findExpired() (if no id given)
    │                                    # For each: challenges.repository.closeChallenge(id)
    │                                    # challenges.repository.listParticipantIds(id)
    │                                    # notification.service.dispatch to participants:
    │                                    #   'challenge_ended'
    │
    ├── send-notification/               # MODULE: notifications | CALLER: other Edge Functions only
    │   ├── index.ts                     # Handler: POST /send-notification
    │   │                                # Auth: service-role key ONLY (not callable by clients)
    │   │                                # Internal function — called by other Edge Functions
    │   └── use-case.ts                  # Fetch push tokens for recipient_ids
    │                                    # Filter by notification_preferences per recipient
    │                                    # notifications.repository.bulkInsert (inbox rows)
    │                                    # Batch and send to Expo Push API
    │                                    # Return { sent_count, skipped_count }
    │
    ├── resolve-flag/                    # MODULE: admin | CALLER: admin
    │   ├── index.ts                     # Handler: POST /resolve-flag
    │   │                                # Auth: JWT required, admin role
    │   │                                # Body: { flag_id, action: 'delete' | 'dismiss' }
    │   └── use-case.ts                  # assertAdmin(caller)
    │                                    # flagged-content.repository.findById(flagId)
    │                                    # If action='delete':
    │                                    #   posts.repository.softDelete(contentId) OR
    │                                    #   comments would be soft-deleted similarly
    │                                    #   flagged-content.repository.markDeleted(flagId)
    │                                    # If action='dismiss':
    │                                    #   flagged-content.repository.resolve(flagId)
    │                                    # audit.service.log('flag_resolved_*', ...)
    │
    ├── pin-announcement/                # MODULE: admin | CALLER: admin
    │   ├── index.ts                     # Handler: POST /pin-announcement
    │   │                                # Auth: JWT required, admin role
    │   │                                # Body: { post_id, action: 'pin' | 'unpin' }
    │   └── use-case.ts                  # assertAdmin(caller)
    │                                    # If action='pin':
    │                                    #   pinned-announcements.repository.deactivateAll()
    │                                    #   pinned-announcements.repository.create(postId, adminId)
    │                                    #   audit.service.log('content_pinned', ...)
    │                                    # If action='unpin':
    │                                    #   pinned-announcements.repository.deactivateAll()
    │                                    #   audit.service.log('content_unpinned', ...)
    │
    ├── deactivate-user/                 # MODULE: admin | CALLER: admin
    │   ├── index.ts                     # Handler: POST /deactivate-user
    │   │                                # Auth: JWT required, admin role
    │   │                                # Body: { user_id, reactivate?: boolean }
    │   └── use-case.ts                  # assertAdmin(caller)
    │                                    # profiles.repository.deactivate(userId, reactivate)
    │                                    # If deactivating: profiles.repository.updatePushToken(
    │                                    #   userId, null)  ← stop future notifications
    │                                    # audit.service.log('user_deactivated' | 'user_reactivated')
    │
    ├── remove-user/                     # MODULE: admin | CALLER: admin
    │   ├── index.ts                     # Handler: POST /remove-user
    │   │                                # Auth: JWT required, admin role
    │   │                                # Body: { user_id }
    │   └── use-case.ts                  # assertAdmin(caller)
    │                                    # profiles.repository.anonymize(userId):
    │                                    #   full_name = 'Removed Member'
    │                                    #   avatar_url = null
    │                                    #   bio = null, title = null
    │                                    #   interest_tags = []
    │                                    #   push_token = null
    │                                    #   is_active = false
    │                                    # Delete avatar from Supabase Storage
    │                                    # audit.service.log('user_removed', ...)
    │
    ├── revoke-invitation/               # MODULE: admin | CALLER: admin
    │   ├── index.ts                     # Handler: POST /revoke-invitation
    │   │                                # Auth: JWT required, admin role
    │   │                                # Body: { invitation_id }
    │   └── use-case.ts                  # assertAdmin(caller)
    │                                    # invitations.repository.revoke(invitationId)
    │                                    # audit.service.log('invitation_revoked', ...)
    │
    └── scheduled-cleanup/              # MODULE: system | CALLER: scheduled (pg_cron / external)
        ├── index.ts                     # Handler: POST /scheduled-cleanup
        │                                # Auth: service-role key ONLY
        │                                # Internal scheduled function — not client-callable
        └── use-case.ts                  # cleanup.repository.hardDeleteExpiredContent()
                                         #   ← posts/comments is_deleted=true
                                         #     AND deleted_at < now()-30days
                                         # cleanup.repository.expireOldInvitations()
                                         #   ← status='pending' AND expires_at < now()
                                         # cleanup.repository.pruneOldNotifications()
                                         #   ← created_at < now()-90days
                                         # close-challenge use case (processes expired challenges)
                                         # close-poll use case (processes expired polls)
```

---

## Mobile Client (Flutter)

The mobile client codebase lives in `frontend/` and is documented in **`flutter-folder-structure.md`**. This document covers only the Supabase backend (`supabase/`).

The Flutter client communicates with the Supabase backend using:

| Integration Point | Flutter Mechanism |
|---|---|
| Auth (OTP, session, token refresh) | `supabase.auth.*` via `supabase_flutter` SDK |
| REST data access (PostgREST) | `supabase.from(table).*` in `lib/features/*/data/datasources/` |
| Edge Function calls | `supabase.functions.invoke(name, body: {...})` in `lib/features/*/data/datasources/` |
| Realtime subscriptions | `supabase.channel(name).onPostgresChanges(...)` via `StreamProvider` in Riverpod |
| File storage | `supabase.storage.from(bucket).*` in `lib/features/*/data/datasources/` |
| Push token registration | FCM via `firebase_messaging`; token stored in `profiles.push_token` via REST |

### Shared Contract Between Backend and Flutter Client

| Artifact | Backend Location | Flutter Location |
|---|---|---|
| Table names | `supabase/migrations/` | `lib/core/constants/supabase_constants.dart` |
| Edge Function names | `supabase/functions/{name}/` | `supabase.functions.invoke('{name}')` calls in datasources |
| NotificationType enum values | `_shared/types.ts` | `lib/core/constants/supabase_constants.dart` (as Dart constants) |
| Database column types | `supabase/migrations/` | Auto-generated: `supabase gen types dart --project-id <ref>` |

### What Is NOT in `supabase/`

```
supabase/
└── (does NOT contain)
    ├── Mobile app screens or UI code   → frontend/lib/features/*/presentation/
    ├── State management (Riverpod)     → frontend/lib/features/*/presentation/providers/
    ├── Navigation (GoRouter)           → frontend/lib/core/router/
    └── Push notification handling      → frontend/lib/shared/services/notification_service.dart
```

See `flutter-folder-structure.md` for the complete Flutter application structure.

---

## File Naming Conventions (Supabase Backend)

| Pattern | Example | Used For |
|---------|---------|---------|
| `{noun}.repository.ts` | `polls.repository.ts` | Edge Function data access layer (`_shared/repositories/`) |
| `{noun}.validators.ts` | `poll.validators.ts` | Input validation modules (`_shared/validators/`) |
| `{noun}.service.ts` | `notification.service.ts` | Side-effect services (`_shared/services/`) |
| `index.ts` | `create-poll/index.ts` | Edge Function HTTP handler entry point |
| `use-case.ts` | `create-poll/use-case.ts` | Edge Function application logic |

---

## What Is NOT in This Structure

| Item | Reason |
|------|--------|
| Controllers or route handlers | Not a REST API — Supabase PostgREST provides this |
| Middleware | Not applicable — auth is JWT-based via Supabase; RLS handles authorization |
| Data models / ORM files | No ORM — types are auto-generated from schema |
| Background workers | Handled by scheduled Edge Functions |
| Config files per environment | Secrets in EAS Secrets and GitHub Actions; `config.toml` handles project config |
| Messaging service or hooks | Messaging removed; Connect Buddy posts live in the Feed module |
