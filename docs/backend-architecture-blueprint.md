# Backend Architecture Blueprint

## Architecture Pattern

**BaaS-first with Edge Function compute layer.**

- Standard CRUD → Supabase PostgREST (client-direct, RLS enforced)
- Multi-table atomic operations → Edge Functions (service_role, bypasses RLS)
- Third-party integrations → Edge Functions (FCM push)
- Scheduled tasks → Edge Functions (service_role, cron-triggered)

Client never calls Edge Functions for operations that PostgREST can handle safely.

## Folder Structure

```
supabase/functions/
├── _shared/
│   ├── supabase-client.ts          # createAdminClient(), createUserClient(jwt)
│   ├── cors.ts                     # corsHeaders, corsResponse()
│   ├── errors.ts                   # AppError, toErrorResponse()
│   ├── auth.ts                     # requireAuth(), requireAdmin(), requireServiceRole()
│   ├── crypto.ts                   # hashToken()
│   ├── constants.ts                # CONNECT_BUDDY_PROFILE_ID, limits
│   │
│   ├── validators/
│   │   ├── auth.validators.ts      # send-invitation, validate-invite-token, create-profile
│   │   ├── feed.validators.ts      # create-post
│   │   ├── events.validators.ts    # cancel-activity, post-activity-update
│   │   ├── polls.validators.ts     # create-poll
│   │   ├── attendance.validators.ts # record-attendance
│   │   ├── growth.validators.ts    # close-challenge
│   │   ├── recognition.validators.ts # create-recognition
│   │   └── admin.validators.ts     # resolve-flag, pin-announcement, deactivate/remove-user
│   │
│   ├── repositories/
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
│   └── services/
│       ├── notification.service.ts  # FCM push dispatch
│       └── audit.service.ts         # admin_audit_log writer
│
├── send-notification/               # Internal — called by other EFs
│   ├── index.ts
│   └── use-case.ts
├── validate-invite-token/
│   ├── index.ts
│   └── use-case.ts
├── send-invitation/
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
├── post-activity-update/
├── create-poll/
├── close-poll/
├── record-attendance/
├── close-challenge/
├── create-recognition/
├── compute-monthly-stats/
├── scheduled-connect-buddy/
├── resolve-flag/
├── pin-announcement/
├── deactivate-user/
├── remove-user/
├── revoke-invitation/
└── scheduled-cleanup/
```

## Dependency Flow

```
HTTP Request
  → index.ts (Handler)
    → Parse headers, body, JWT
    → Validate input (validators/)
    → Call use-case.ts
      → repositories/ (DB reads/writes)
      → services/ (notifications, audit)
    → Return HTTP response
```

**Rules:**
- Handlers never call repositories directly
- Use cases may call repositories + services
- Repositories and services never call each other
- Validators are pure functions — no DB access

## Module Inventory

### 1. Auth (3 Edge Functions)

| Function | Auth | Tables | Side Effects |
|----------|------|--------|-------------|
| `validate-invite-token` | Public | invitations | None |
| `send-invitation` | Admin JWT | invitations, admin_audit_log | Audit log entry |
| `create-profile` | User JWT | profiles, invitations | CB welcome post, admin notification |

### 2. Feed (2 Edge Functions + REST)

| Function | Auth | Tables | Side Effects |
|----------|------|--------|-------------|
| `create-post` | User JWT | posts, post_images, post_mentions | Mention notifications |
| `post-connect-buddy-message` | Service role | posts, post_images | Optional all-member notification |

REST handles: get feed, reactions, comments, soft-delete, flagging.

### 3. Events (4 Edge Functions + REST)

| Function | Auth | Tables | Side Effects |
|----------|------|--------|-------------|
| `cancel-activity` | Creator/Admin | activities | Notify RSVPs |
| `post-activity-update` | Creator | activity_updates | Notify RSVPs |
| `create-poll` | User JWT | polls, poll_options | Optional notification |
| `close-poll` | Service role/Admin | polls | Notify voters |

REST handles: create activity, RSVP, get polls, vote.

### 4. Growth (1 Edge Function + REST)

| Function | Auth | Tables | Side Effects |
|----------|------|--------|-------------|
| `close-challenge` | Service role/Admin | challenges | Notify participants |

REST handles: create challenge, join, leave, log progress, get leaderboard.

### 5. Recognition (1 Edge Function + REST)

| Function | Auth | Tables | Side Effects |
|----------|------|--------|-------------|
| `create-recognition` | User JWT | recognitions, recognition_recipients | Recipient notifications |

REST handles: get wall, reactions.

### 6. Analytics (1 Edge Function + REST)

| Function | Auth | Tables | Side Effects |
|----------|------|--------|-------------|
| `compute-monthly-stats` | Service role | member_monthly_stats, community_health_scores | None |

REST handles: get personal stats, rankings, health score.

### 7. Notifications (1 Edge Function + REST)

| Function | Auth | Tables | Side Effects |
|----------|------|--------|-------------|
| `send-notification` | Service role | notification_inbox, profiles | FCM push dispatch |

REST handles: get inbox, mark read, unread count.

### 8. Admin (5 Edge Functions + REST)

| Function | Auth | Tables | Side Effects |
|----------|------|--------|-------------|
| `resolve-flag` | Admin JWT | flagged_content, posts/comments | Audit log, optional soft-delete |
| `pin-announcement` | Admin JWT | pinned_announcements | Audit log |
| `deactivate-user` | Admin JWT | profiles | Audit log, nullify push_token |
| `remove-user` | Admin JWT | profiles, Storage | Audit log, PII anonymization |
| `revoke-invitation` | Admin JWT | invitations | Audit log |

### 9. System (2 Edge Functions)

| Function | Auth | Tables | Side Effects |
|----------|------|--------|-------------|
| `scheduled-connect-buddy` | Service role | posts | Welcome, highlights, reminders, etc. |
| `scheduled-cleanup` | Service role | posts, comments, invitations, notification_inbox | Hard-delete expired content |

## Strategies

### Validation
- Input validated in `_shared/validators/` before use-case execution
- Validators are pure functions returning `{ valid: true, data }` or `{ valid: false, errors }`
- No database access in validators — schema constraints (CHECK, UNIQUE) provide the second line of defense

### Error Handling
- `AppError` class with typed codes: UNAUTHORIZED, FORBIDDEN, NOT_FOUND, CONFLICT, VALIDATION_ERROR, SERVER_ERROR
- `toErrorResponse()` serializes to `{ error: { code, message } }` with correct HTTP status
- Unhandled errors caught at handler level → 500 with generic message

### Logging
- Supabase Edge Function logs available via Dashboard → Edge Functions → Logs
- Structured `console.log` with function name + operation for traceability
- No PII in logs (no emails, names, tokens)

### Testing
- Use cases tested by injecting mock repositories
- Integration tests via `supabase functions serve` + curl against local Supabase
- RLS tests already complete (114 policies tested)

## Endpoint Count

| Category | Edge Functions | REST Operations | Realtime Channels |
|----------|---------------|----------------|-------------------|
| Auth | 3 | 7 | 0 |
| Feed | 2 | 12 | 3 |
| Events | 4 | 14 | 2 |
| Growth | 1 | 9 | 1 |
| Recognition | 1 | 6 | 0 |
| Analytics | 1 | 6 | 0 |
| Notifications | 1 | 5 | 1 |
| Admin | 5 | 4 | 0 |
| System | 2 | 0 | 0 |
| **Total** | **20** | **63** | **7** |

(Note: `record-attendance` counted under Events; `scheduled-connect-buddy` counted under System. Total 21 Edge Functions per API contracts — `send-notification` is internal, not client-facing.)
