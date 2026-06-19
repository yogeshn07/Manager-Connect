# Backend API Contracts

## Overview

Manager Connect uses three distinct access patterns. This document defines every backend operation, which pattern it uses, and the full contract for all Edge Function calls.

**Access Patterns:**
1. **Supabase REST (PostgREST)** — Standard CRUD operations. JWT authenticated. RLS enforced.
2. **Supabase Realtime (WebSocket)** — Live change streams. JWT authenticated.
3. **Edge Functions (HTTPS POST)** — Server-side logic. JWT or service-role key authenticated.

---

## Operation Registry

Complete list of all backend operations and which access pattern handles each.

### Auth and Identity

| Operation | Pattern | Endpoint / Table |
|-----------|---------|------------------|
| Request OTP | Platform | Supabase Auth: `signInWithOtp` |
| Verify OTP and get session | Platform | Supabase Auth: `verifyOtp` |
| Refresh session | Platform | Supabase Auth: automatic token rotation |
| Sign out | Platform | Supabase Auth: `signOut` |
| Validate invite token | Edge Function | `POST /validate-invite-token` |
| Create profile (post-registration) | Edge Function | `POST /create-profile` |
| Get own profile | REST | `GET /profiles?id=eq.{id}` |
| Get all member profiles | REST | `GET /profiles?is_active=eq.true&is_system_account=eq.false` |
| Update own profile | REST | `PATCH /profiles?id=eq.{id}` |
| Update notification preferences | REST | `PATCH /profiles?id=eq.{id}` (prefs column only) |
| Update push token | REST | `PATCH /profiles?id=eq.{id}` (push_token only) |
| Update last active | REST | `PATCH /profiles?id=eq.{id}` (last_active_at only) |

### Community Feed

| Operation | Pattern | Endpoint / Table |
|-----------|---------|------------------|
| Get paginated feed | REST | `GET /posts?is_deleted=eq.false&order=created_at.desc&limit=20` |
| Get pinned post | REST | `GET /pinned_announcements?is_active=eq.true` joined with post |
| Create post (with mentions) | Edge Function | `POST /create-post` |
| Get post detail | REST | `GET /posts?id=eq.{id}` |
| Delete own post (soft) | REST | `PATCH /posts?id=eq.{id}` → set is_deleted=true |
| Get post images | REST | `GET /post_images?post_id=eq.{id}` |
| Get reactions for post | REST | `GET /post_reactions?post_id=eq.{id}` |
| Add/change own reaction | REST | `UPSERT /post_reactions` (ON CONFLICT post_id,user_id) |
| Remove own reaction | REST | `DELETE /post_reactions?post_id=eq.{id}&user_id=eq.{uid}` |
| Get comments for post | REST | `GET /comments?post_id=eq.{id}&is_deleted=eq.false` |
| Create comment | REST | `POST /comments` |
| Delete own comment (soft) | REST | `PATCH /comments?id=eq.{id}` → is_deleted=true |
| Flag post or comment | REST | `POST /flagged_content` |
| Subscribe to new posts | Realtime | Channel: `feed:posts` — INSERT on `posts` |
| Subscribe to reactions | Realtime | Channel: `feed:reactions:{post_id}` — `post_reactions` changes |
| Subscribe to comments | Realtime | Channel: `feed:comments:{post_id}` — `comments` INSERT |

### Events

| Operation | Pattern | Endpoint / Table |
|-----------|---------|------------------|
| Get upcoming activities | REST | `GET /activities?status=eq.active&event_date=gte.now()&order=event_date.asc` |
| Get upcoming activities by category | REST | `GET /activities?status=eq.active&event_category=eq.{category}&event_date=gte.now()` |
| Get past activities | REST | `GET /activities?event_date=lt.now()&order=event_date.desc` |
| Get activity detail | REST | `GET /activities?id=eq.{id}` |
| Create activity | REST | `POST /activities` |
| Cancel activity (+ notify RSVPs) | Edge Function | `POST /cancel-activity` |
| Post activity update (+ notify) | Edge Function | `POST /post-activity-update` |
| Get activity updates | REST | `GET /activity_updates?activity_id=eq.{id}` |
| Get RSVP list | REST | `GET /activity_rsvps?activity_id=eq.{id}` |
| Submit or change RSVP | REST | `UPSERT /activity_rsvps` (ON CONFLICT activity_id,user_id) |
| Withdraw RSVP | REST | `DELETE /activity_rsvps?activity_id=eq.{id}&user_id=eq.{uid}` |
| Get event history | REST | `GET /activities?event_date=lt.now()&order=event_date.desc` with attendance join |
| Create poll (standalone or linked) | Edge Function | `POST /create-poll` |
| Get polls (all or for activity) | REST | `GET /polls?activity_id=eq.{id}` or `GET /polls?is_closed=eq.false` |
| Get poll detail with options | REST | `GET /polls?id=eq.{id}` joined with poll_options |
| Get poll results (vote counts) | REST | `GET /poll_votes?poll_id=eq.{id}` — grouped by option_id |
| Vote on a poll | REST | `POST /poll_votes` (UNIQUE enforced; one vote per user per poll) |
| Close poll (+ notify voters) | Edge Function | `POST /close-poll` |
| Record event attendance (batch, admin) | Edge Function | `POST /record-attendance` |
| Get attendance for event | REST | `GET /event_attendance?activity_id=eq.{id}` joined with profiles |
| Get my attendance history | REST | `GET /event_attendance?user_id=eq.{uid}&status=eq.attended` |
| Subscribe to RSVP changes | Realtime | Channel: `activities:rsvps:{activity_id}` — `activity_rsvps` changes |
| Subscribe to poll vote results | Realtime | Channel: `events:poll_votes:{poll_id}` — `poll_votes` INSERT |

### Growth Challenges

| Operation | Pattern | Endpoint / Table |
|-----------|---------|------------------|
| Get active challenges | REST | `GET /challenges?status=eq.active&order=end_date.asc` |
| Get my challenges (joined) | REST | `GET /challenge_participants?user_id=eq.{uid}` joined with challenges |
| Get completed challenges | REST | `GET /challenges?status=eq.ended&order=ended_at.desc` |
| Get challenge detail | REST | `GET /challenges?id=eq.{id}` |
| Create challenge | REST | `POST /challenges` |
| Join challenge | REST | `POST /challenge_participants` |
| Leave challenge | REST | `DELETE /challenge_participants?challenge_id=eq.{id}&user_id=eq.{uid}` |
| Get participants | REST | `GET /challenge_participants?challenge_id=eq.{id}` joined with profiles |
| Log progress | REST | `UPSERT /progress_logs` (ON CONFLICT challenge_id,user_id,log_date) |
| Get my progress logs | REST | `GET /progress_logs?challenge_id=eq.{id}&user_id=eq.{uid}` |
| Get leaderboard | REST | `GET /progress_logs?challenge_id=eq.{id}` → aggregated SUM client-side |
| Close expired challenges (+ notify) | Edge Function | `POST /close-challenge` |
| Subscribe to leaderboard changes | Realtime | Channel: `growth:leaderboard:{challenge_id}` — `progress_logs` INSERT |

### Recognition

| Operation | Pattern | Endpoint / Table |
|-----------|---------|------------------|
| Get recognition wall | REST | `GET /recognitions?is_deleted=eq.false&order=created_at.desc` |
| Get recognitions I received | REST | `GET /recognition_recipients?recipient_id=eq.{uid}` joined with recognitions |
| Get recognitions I gave | REST | `GET /recognitions?giver_id=eq.{uid}` |
| Get recognition detail | REST | `GET /recognitions?id=eq.{id}` |
| Create recognition (+ notify) | Edge Function | `POST /create-recognition` |
| Get recognition recipients | REST | `GET /recognition_recipients?recognition_id=eq.{id}` |
| Get recognition reactions | REST | `GET /recognition_reactions?recognition_id=eq.{id}` |
| Add/change reaction on recognition | REST | `UPSERT /recognition_reactions` (ON CONFLICT recognition_id,user_id) |
| Remove reaction on recognition | REST | `DELETE /recognition_reactions?recognition_id=eq.{id}&user_id=eq.{uid}` |

### Analytics

| Operation | Pattern | Endpoint / Table |
|-----------|---------|------------------|
| Get personal analytics (own stats) | REST | `GET /member_monthly_stats?user_id=eq.{uid}&order=stat_month.desc` |
| Get personal analytics for a month | REST | `GET /member_monthly_stats?user_id=eq.{uid}&stat_month=eq.{date}` |
| Get community analytics | REST | `GET /community_health_scores?order=score_month.desc&limit=12` |
| Get community health score (latest) | REST | `GET /community_health_scores?order=score_month.desc&limit=1` |
| Get monthly rankings | REST | `GET /member_monthly_stats?stat_month=eq.{date}&order=events_attended.desc` |
| Get all-time rankings | REST | Aggregated SUM across `member_monthly_stats` grouped by user_id |
| Get monthly recognition | REST | `GET /recognitions?created_at=gte.{monthStart}&created_at=lt.{monthEnd}` joined with recipients |
| Get community recognition summary | REST | Aggregate counts from `recognition_recipients` grouped by recipient_id |
| Compute monthly stats + health score | Edge Function | `POST /compute-monthly-stats` (service-role, scheduled) |

### Notifications

| Operation | Pattern | Endpoint / Table |
|-----------|---------|------------------|
| Get notification inbox | REST | `GET /notification_inbox?recipient_id=eq.{uid}&order=created_at.desc` |
| Get unread count | REST | `GET /notification_inbox?recipient_id=eq.{uid}&is_read=eq.false` (count) |
| Mark notification as read | REST | `PATCH /notification_inbox?id=eq.{id}` → is_read=true, read_at=now() |
| Mark all as read | REST | `PATCH /notification_inbox?recipient_id=eq.{uid}&is_read=eq.false` → is_read=true |
| Delete notification | REST | `DELETE /notification_inbox?id=eq.{id}` |
| Dispatch push notifications (internal) | Edge Function | `POST /send-notification` (service-role only) |
| Subscribe to new notifications | Realtime | Channel: `notifications:inbox:{user_id}` — `notification_inbox` INSERT |

### Admin

| Operation | Pattern | Endpoint / Table |
|-----------|---------|------------------|
| Get all members | REST | `GET /profiles?is_system_account=eq.false` (admin sees all, including is_active=false) |
| Get pending invitations | REST | `GET /invitations?status=eq.pending` |
| Send invitation to new member | Edge Function | `POST /send-invitation` |
| Revoke pending invitation | Edge Function | `POST /revoke-invitation` |
| Deactivate member | Edge Function | `POST /deactivate-user` |
| Reactivate member | Edge Function | `POST /deactivate-user` with `reactivate: true` |
| Remove member (anonymize) | Edge Function | `POST /remove-user` |
| Get flagged content queue | REST | `GET /flagged_content?status=eq.pending` |
| Resolve flagged content | Edge Function | `POST /resolve-flag` |
| Pin announcement | Edge Function | `POST /pin-announcement` with `action: 'pin'` |
| Unpin announcement | Edge Function | `POST /pin-announcement` with `action: 'unpin'` |
| Record event attendance (batch) | Edge Function | `POST /record-attendance` |
| Get engagement metrics | REST | Multiple lightweight aggregate queries (posts count, active users count, etc.) |
| Get audit log | REST | `GET /admin_audit_log?order=performed_at.desc` |

### Scheduled / System

| Operation | Pattern | Endpoint |
|-----------|---------|----------|
| Expire old invitations + hard-delete soft-deleted content + prune notifications | Edge Function | `POST /scheduled-cleanup` (service-role, scheduled) |
| Close challenges past end_date | Edge Function | `POST /close-challenge` with no body (service-role, scheduled) |
| Close polls past closes_at | Edge Function | `POST /close-poll` with no body (service-role, scheduled) |
| Compute member monthly stats and community health scores | Edge Function | `POST /compute-monthly-stats` (service-role, scheduled 1st of month) |
| Post Connect Buddy content | Edge Function | `POST /scheduled-connect-buddy` (service-role, scheduled multiple triggers) |

---

## Edge Function Contracts

Each Edge Function contract defines the request shape, response shape, auth requirement, and error cases.

### Conventions

All Edge Functions:
- Accept `Content-Type: application/json`
- Respond with `Content-Type: application/json`
- Include CORS headers on all responses
- Return HTTP status codes as the error signal
- Never return 200 with an error body
- All UUIDs as `string` (UUID v4 format)
- All timestamps as ISO 8601 strings

**Standard error response shape:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR | UNAUTHORIZED | FORBIDDEN | NOT_FOUND | CONFLICT | SERVER_ERROR",
    "message": "Human-readable description"
  }
}
```

---

### `POST /send-invitation`

**Auth:** Bearer JWT — `app_role = 'admin'` required  
**Module:** auth

**Request:**
```json
{
  "invitee_name": "string, required",
  "invitee_email": "string | null",
  "invitee_phone": "string | null"
}
```
*Constraint: at least one of email or phone must be non-null.*

**Success Response — 200:**
```json
{
  "invitation_id": "uuid",
  "invite_url": "string (deep-link URL containing the raw token — admin shares this manually)",
  "status": "pending",
  "expires_at": "ISO 8601 timestamp"
}
```

*The admin copies `invite_url` and delivers it via any channel (WhatsApp, direct message, etc.). The system does not send email or SMS.*

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT or invalid JWT |
| 403 | FORBIDDEN | Caller is not admin |
| 422 | VALIDATION_ERROR | Missing name or both email/phone null |
| 409 | CONFLICT | Pending invitation already exists for this email/phone |

---

### `POST /validate-invite-token`

**Auth:** None (public — token is the credential)  
**Module:** auth

**Request:**
```json
{
  "token": "string, required (raw UUID token from invite link)"
}
```

**Success Response — 200:**
```json
{
  "valid": true,
  "invitation_id": "uuid",
  "invitee_name": "string",
  "invitee_email": "string | null",
  "invitee_phone": "string | null"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 422 | VALIDATION_ERROR | Token missing or not a valid UUID format |
| 404 | NOT_FOUND | No matching token (never existed or already used) |
| 410 | CONFLICT | Token exists but is expired, revoked, or already accepted |

---

### `POST /create-profile`

**Auth:** Bearer JWT — any authenticated user (newly registered, no profile yet)  
**Module:** auth

**Request:**
```json
{
  "token": "string, required (raw invite token for re-verification)",
  "full_name": "string, required",
  "title": "string | null",
  "bio": "string | null, max 300 chars",
  "avatar_storage_path": "string | null",
  "interest_tags": "string[]"
}
```

**Success Response — 201:**
```json
{
  "profile_id": "uuid"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 404 | NOT_FOUND | Invite token invalid or expired |
| 409 | CONFLICT | Profile already exists for this auth user |
| 422 | VALIDATION_ERROR | full_name missing or bio > 300 chars |

---

### `POST /create-post`

**Auth:** Bearer JWT — any authenticated active member  
**Module:** feed

**Request:**
```json
{
  "content": "string, required, min 1 char",
  "image_storage_paths": "string[] | null, max 4 images"
}
```

**Success Response — 201:**
```json
{
  "post_id": "uuid",
  "created_at": "ISO 8601 timestamp"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 403 | FORBIDDEN | User is_active = false |
| 422 | VALIDATION_ERROR | Content empty or image count > 4 |

**Side effects:**
- Parses content for `@{user_id}` patterns, inserts `post_mentions` rows
- Dispatches `mention` notifications to mentioned users
- Inserts `post_images` rows for each path provided

---

### `POST /create-recognition`

**Auth:** Bearer JWT — any authenticated active member  
**Module:** recognition

**Request:**
```json
{
  "recipient_ids": "uuid[], required, min 1 element",
  "category_tag": "string, required — one of: community_contributor | fitness_champion | wellness_champion | event_champion | most_supportive_manager",
  "message": "string, required, min 1 char, max 500 chars"
}
```

**Success Response — 201:**
```json
{
  "recognition_id": "uuid",
  "created_at": "ISO 8601 timestamp"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 403 | FORBIDDEN | User is_active = false |
| 422 | VALIDATION_ERROR | No recipients, invalid category, message too long |
| 404 | NOT_FOUND | One or more recipient_ids not found in active profiles |

**Side effects:**
- Inserts `recognition_recipients` row for each recipient
- Dispatches `recognition_received` notification to all recipients

---

### `POST /create-poll`

**Auth:** Bearer JWT — any authenticated active member  
**Module:** events

**Request:**
```json
{
  "question": "string, required, min 1 char",
  "options": "string[], required, min 2 elements, max 10 elements",
  "closes_at": "ISO 8601 timestamp, required (must be in the future)",
  "activity_id": "uuid | null (link to an event, or null for standalone poll)"
}
```

**Success Response — 201:**
```json
{
  "poll_id": "uuid",
  "created_at": "ISO 8601 timestamp"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 403 | FORBIDDEN | User is_active = false |
| 422 | VALIDATION_ERROR | Missing question, fewer than 2 options, more than 10 options, closes_at in the past |
| 404 | NOT_FOUND | activity_id provided but not found |

**Side effects:**
- Atomically inserts `polls` row + `poll_options` rows (one per option string, display_order 0-based)
- If `activity_id` provided: validates the activity exists and is not cancelled
- Optionally dispatches `poll_reminder` notification to all active members (community awareness)

---

### `POST /close-poll`

**Auth:** Service-role key (scheduled) OR admin JWT  
**Module:** events

**Request:**
```json
{
  "poll_id": "uuid | null"
}
```
*If `poll_id` is null, processes all polls where `closes_at < now()` and `is_closed = false`.*

**Success Response — 200:**
```json
{
  "closed_count": "number",
  "poll_ids": "uuid[]"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No service-role key and no admin JWT |
| 404 | NOT_FOUND | Specific poll_id not found |
| 409 | CONFLICT | Poll is already closed |

**Side effects:**
- Sets `polls.is_closed = true` for each closed poll
- Dispatches `poll_reminder` notification to all members who voted (results now final)
- Writes audit log entry: `poll_closed`

---

### `POST /record-attendance`

**Auth:** Bearer JWT — `app_role = 'admin'` required  
**Module:** events / admin

**Request:**
```json
{
  "activity_id": "uuid, required",
  "records": [
    {
      "user_id": "uuid, required",
      "status": "attended | absent, required"
    }
  ]
}
```
*`records` is a required non-empty array. Batch upsert: if a record already exists for (activity_id, user_id), it is updated.*

**Success Response — 200:**
```json
{
  "recorded_count": "number"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 403 | FORBIDDEN | Caller is not admin |
| 404 | NOT_FOUND | activity_id not found |
| 422 | VALIDATION_ERROR | records is empty; invalid status value; one or more user_ids not found in active profiles |
| 409 | CONFLICT | Activity event_date is in the future (cannot record attendance before event) |

**Side effects:**
- Batch upserts `event_attendance` rows (one per record in the array)
- Writes audit log entry: `attendance_recorded` with metadata `{ activity_id, record_count }`

---

### `POST /compute-monthly-stats`

**Auth:** Service-role key ONLY — triggered by scheduler on the 1st of each month  
**Module:** analytics / system

**Request:**
```json
{
  "stat_month": "ISO 8601 date string (YYYY-MM-DD, first of the month) | null"
}
```
*If `stat_month` is null, defaults to the first day of the previous month.*

**Success Response — 200:**
```json
{
  "members_computed": "number",
  "stat_month": "ISO 8601 date string",
  "health_score": "number"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No service-role key |
| 422 | VALIDATION_ERROR | stat_month is in the future |

**Operations (executed in sequence):**
1. Fetch all active member profiles (`is_system_account = false`, `is_active = true`)
2. For each member: aggregate stats for `stat_month`:
   - `events_attended` — COUNT from `event_attendance` WHERE status='attended' and activity event_date within month
   - `challenges_joined` — COUNT from `challenge_participants` WHERE joined_at within month
   - `progress_logs_count` — COUNT from `progress_logs` WHERE log_date within month
   - `recognitions_received` — COUNT from `recognition_recipients` joined with `recognitions` WHERE recognitions.created_at within month
   - `recognitions_given` — COUNT from `recognitions` WHERE giver_id = user and created_at within month
   - `posts_count` — COUNT from `posts` WHERE author_id = user and is_deleted = false and created_at within month
3. Upsert all member stats rows into `member_monthly_stats`
4. Compute community health score from aggregate metrics for the month
5. Upsert into `community_health_scores`

---

### `POST /post-connect-buddy-message`

**Auth:** Service-role key ONLY — internal function called by other Edge Functions  
**Module:** feed / system

**Request:**
```json
{
  "content": "string, required, min 1 char",
  "image_storage_paths": "string[] | null",
  "notify_all": "boolean, optional, default false",
  "notification_title": "string | null (required if notify_all=true)",
  "notification_body": "string | null (required if notify_all=true)"
}
```

**Success Response — 201:**
```json
{
  "post_id": "uuid"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No service-role key |
| 422 | VALIDATION_ERROR | Content empty; notify_all=true but notification_title or notification_body missing |
| 500 | SERVER_ERROR | Connect Buddy system profile not found (seed data issue) |

**Side effects:**
- Retrieves the Connect Buddy system account profile ID (from platform constant or DB lookup)
- Inserts a `posts` row with `author_id` = Connect Buddy system profile ID
- If `image_storage_paths` provided: inserts `post_images` rows
- If `notify_all = true`: fetches all active member IDs (excluding system account) and dispatches `connect_buddy_update` notification with the provided title and body

---

### `POST /scheduled-connect-buddy`

**Auth:** Service-role key ONLY — triggered by scheduler on multiple schedules  
**Module:** feed / system

**Request:**
```json
{
  "trigger_type": "string, required — 'welcome' | 'monthly_highlights' | 'event_reminder' | 'poll_reminder' | 'achievement' | 'community_update' | 'memory'",
  "context": {
    "user_id": "uuid | null (for 'welcome' trigger — the new member)",
    "activity_id": "uuid | null (for 'event_reminder' trigger)",
    "poll_id": "uuid | null (for 'poll_reminder' trigger)",
    "challenge_id": "uuid | null (for 'achievement' trigger — completed challenge)",
    "past_activity_id": "uuid | null (for 'memory' trigger — past event to reference)"
  }
}
```

**Success Response — 200:**
```json
{
  "trigger_type": "string",
  "post_id": "uuid | null",
  "skipped": "boolean (true if no meaningful content to post)"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No service-role key |
| 422 | VALIDATION_ERROR | Unknown trigger_type; required context field missing for trigger type |
| 404 | NOT_FOUND | Referenced activity_id or poll_id not found |

**Trigger behaviors:**

| trigger_type | Schedule | Behavior |
|---|---|---|
| `welcome` | On new profile creation | Composes and posts a welcome message for the new member; notifies the new member via `connect_buddy_update` |
| `monthly_highlights` | 1st of month (after compute-monthly-stats) | Reads top performers from previous month's `member_monthly_stats`; composes a highlights post; notifies all members |
| `event_reminder` | 24h before each event | Composes an event reminder post for the upcoming activity; notifies all RSVP'd members |
| `poll_reminder` | 24h before each poll closes | Composes a "vote before it closes" reminder post; notifies members who haven't voted yet |
| `achievement` | On challenge completion by a member | Reads the completed challenge and member name; composes an achievement announcement post; notifies all members via `connect_buddy_update` |
| `community_update` | On significant platform milestone | Composes a community update post (e.g., milestone member count, platform anniversary); admin-triggered or scheduled; notifies all members |
| `memory` | Scheduled or admin-triggered | Queries past events from previous months; composes a nostalgia post referencing the past event; notifies all members via `connect_buddy_update` |

**Side effects:**
- All triggers call `post-connect-buddy-message` internally to author the post
- All notifications dispatched as `connect_buddy_update` type

---

### `POST /cancel-activity`

**Auth:** Bearer JWT — activity creator or admin  
**Module:** events

**Request:**
```json
{
  "activity_id": "uuid, required"
}
```

**Success Response — 200:**
```json
{
  "cancelled": true
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 404 | NOT_FOUND | activity_id not found |
| 403 | FORBIDDEN | Caller is not creator and not admin |
| 409 | CONFLICT | Activity already cancelled |

**Side effects:**
- Sets `activities.status = 'cancelled'`, `cancelled_at = now()`
- Dispatches `activity_cancelled` notification to all Going + Maybe RSVPs

---

### `POST /post-activity-update`

**Auth:** Bearer JWT — activity creator only  
**Module:** events

**Request:**
```json
{
  "activity_id": "uuid, required",
  "content": "string, required, min 1 char"
}
```

**Success Response — 201:**
```json
{
  "update_id": "uuid",
  "created_at": "ISO 8601 timestamp"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 404 | NOT_FOUND | activity_id not found |
| 403 | FORBIDDEN | Caller is not the activity creator |
| 409 | CONFLICT | Activity is cancelled (no updates on cancelled activities) |

**Side effects:**
- Inserts `activity_updates` row
- Dispatches `activity_updated` notification to Going + Maybe RSVPs

---

### `POST /close-challenge`

**Auth:** Service-role key (scheduled) OR admin JWT  
**Module:** growth

**Request:**
```json
{
  "challenge_id": "uuid | null"
}
```
*If `challenge_id` is null, processes all active challenges where `end_date < today`.*

**Success Response — 200:**
```json
{
  "closed_count": "number",
  "challenge_ids": "uuid[]"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No service-role key and no admin JWT |
| 404 | NOT_FOUND | Specific challenge_id not found |

**Side effects:**
- Sets `challenges.status = 'ended'`, `ended_at = now()` for each closed challenge
- Dispatches `challenge_ended` notification to all participants of each closed challenge

---

### `POST /send-notification`

**Auth:** Service-role key ONLY — not callable by client JWT  
**Module:** notifications (internal)

**Request:**
```json
{
  "recipient_ids": "uuid[], required",
  "type": "string, required — one of the NotificationType enum values (see below)",
  "title": "string, required",
  "body": "string, required",
  "resource_type": "string | null — one of: 'activity' | 'challenge' | 'recognition' | 'poll' | 'post' | 'user'",
  "resource_id": "uuid | null"
}
```

**NotificationType enum values:**
`'activity_created'`, `'activity_reminder_24h'`, `'activity_reminder_1h'`, `'activity_cancelled'`, `'activity_updated'`, `'recognition_received'`, `'challenge_created'`, `'challenge_ending'`, `'challenge_ended'`, `'mention'`, `'comment_on_post'`, `'poll_reminder'`, `'connect_buddy_update'`, `'admin_flag'`, `'admin_member_registered'`

**notification_preferences key mapping:**

| type | preference key checked |
|------|----------------------|
| `activity_created`, `activity_reminder_24h`, `activity_reminder_1h`, `activity_cancelled`, `activity_updated` | `activity_reminders` |
| `recognition_received` | `recognitions_received` |
| `challenge_created`, `challenge_ending`, `challenge_ended` | `challenge_reminders` |
| `mention` | `mentions` |
| `comment_on_post` | `comments_on_my_posts` |
| `poll_reminder` | `poll_reminders` |
| `connect_buddy_update` | `connect_buddy_updates` |
| `admin_flag`, `admin_member_registered` | Always delivered (admin notifications, no opt-out) |

**Success Response — 200:**
```json
{
  "sent_count": "number",
  "skipped_count": "number (opted-out)"
}
```

**Side effects:**
- Inserts `notification_inbox` rows for all recipients
- Fetches each recipient's `push_token` from profiles
- Checks `notification_preferences[key]` per recipient — skips if opted out
- Batches push to Expo Push API (100 per batch)

---

### `POST /resolve-flag`

**Auth:** Bearer JWT — `app_role = 'admin'` required  
**Module:** admin

**Request:**
```json
{
  "flag_id": "uuid, required",
  "action": "string, required — 'delete' | 'dismiss'"
}
```

**Success Response — 200:**
```json
{
  "resolved": true,
  "action_taken": "delete | dismiss"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 403 | FORBIDDEN | Caller is not admin |
| 404 | NOT_FOUND | flag_id not found |
| 409 | CONFLICT | Flag already resolved |

**Side effects (action='delete'):**
- Soft-deletes the flagged post or comment (sets is_deleted=true, deleted_by=admin_id)
- Updates flag status to 'resolved_deleted'
- Writes audit log: `post_deleted` or `comment_deleted` + `flag_resolved_deleted`

**Side effects (action='dismiss'):**
- Updates flag status to 'resolved_dismissed'
- Writes audit log: `flag_resolved_dismissed`

---

### `POST /pin-announcement`

**Auth:** Bearer JWT — `app_role = 'admin'` required  
**Module:** admin

**Request:**
```json
{
  "post_id": "uuid, required if action='pin'",
  "action": "string, required — 'pin' | 'unpin'"
}
```

**Success Response — 200:**
```json
{
  "success": true
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 403 | FORBIDDEN | Caller is not admin |
| 404 | NOT_FOUND | post_id not found (for pin action) |
| 422 | VALIDATION_ERROR | action='pin' but post_id missing |

**Side effects:**
- Sets all existing active pins to `is_active = false`
- If action='pin': inserts new `pinned_announcements` row with `is_active = true`
- Writes audit log: `content_pinned` or `content_unpinned`

---

### `POST /deactivate-user`

**Auth:** Bearer JWT — `app_role = 'admin'` required  
**Module:** admin

**Request:**
```json
{
  "user_id": "uuid, required",
  "reactivate": "boolean, optional, default false"
}
```

**Success Response — 200:**
```json
{
  "success": true,
  "user_id": "uuid",
  "is_active": "boolean (new state)"
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 403 | FORBIDDEN | Caller is not admin |
| 404 | NOT_FOUND | user_id not found |
| 409 | CONFLICT | Attempting to deactivate an already-deactivated user |
| 422 | VALIDATION_ERROR | Attempting to deactivate or remove the Connect Buddy system account (is_system_account=true) |

**Side effects:**
- Updates `profiles.is_active` to the new state
- If deactivating: nullifies `profiles.push_token` (stop future push delivery)
- Writes audit log: `user_deactivated` or `user_reactivated`

---

### `POST /remove-user`

**Auth:** Bearer JWT — `app_role = 'admin'` required  
**Module:** admin

**Request:**
```json
{
  "user_id": "uuid, required"
}
```

**Success Response — 200:**
```json
{
  "success": true
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 403 | FORBIDDEN | Caller is not admin |
| 404 | NOT_FOUND | user_id not found |
| 422 | VALIDATION_ERROR | Attempting to remove the Connect Buddy system account (is_system_account=true) |

**Side effects:**
- Sets `profiles.full_name = 'Removed Member'`
- Nullifies: `avatar_url`, `bio`, `title`, `interest_tags = []`, `push_token`, `is_active = false`
- Deletes avatar from Supabase Storage: `avatars/{user_id}/profile.jpg`
- Content (posts, comments, recognitions) remains attributed to the anonymized profile
- Writes audit log: `user_removed`

---

### `POST /revoke-invitation`

**Auth:** Bearer JWT — `app_role = 'admin'` required  
**Module:** admin

**Request:**
```json
{
  "invitation_id": "uuid, required"
}
```

**Success Response — 200:**
```json
{
  "success": true
}
```

**Error Cases:**
| Status | Code | Condition |
|--------|------|-----------|
| 401 | UNAUTHORIZED | No JWT |
| 403 | FORBIDDEN | Caller is not admin |
| 404 | NOT_FOUND | invitation_id not found |
| 409 | CONFLICT | Invitation not in 'pending' status |

**Side effects:**
- Updates `invitations.status = 'revoked'`
- Writes audit log: `invitation_revoked`

---

### `POST /scheduled-cleanup`

**Auth:** Service-role key ONLY — triggered by scheduler  
**Module:** system

**Request:** `{}` (no body required)

**Success Response — 200:**
```json
{
  "hard_deleted_posts": "number",
  "hard_deleted_comments": "number",
  "expired_invitations": "number",
  "pruned_notifications": "number"
}
```

**Operations (executed in sequence):**
1. Hard DELETE posts WHERE `is_deleted=true` AND `deleted_at < now()-30 days`
2. Hard DELETE comments WHERE `is_deleted=true` AND `deleted_at < now()-30 days`
3. UPDATE invitations SET `status='expired'` WHERE `status='pending'` AND `expires_at < now()`
4. DELETE notification_inbox WHERE `created_at < now()-90 days`
5. Invoke close-challenge use case (processes all expired challenges)
6. Invoke close-poll use case (processes all expired polls)

---

## Response Conventions

### Pagination

All paginated list responses from PostgREST use:
- Query params: `limit={page_size}&offset={page * page_size}` or `range: from-to` header
- Default page size: **20 items**
- Client uses cursor-based pagination by `created_at` or `event_date` for feeds (keyset pagination over offset for large sets)

### Column Selection

All client REST queries explicitly specify columns. No `select=*` in production. Example:

```
GET /posts?select=id,content,author_id,created_at,profiles(full_name,avatar_url,is_system_account)&is_deleted=eq.false
```

### Embedded Joins (PostgREST)

PostgREST supports inline joins with foreign key relationships. Used to reduce round trips:
- Posts with author profile data: `select=*,profiles(full_name,avatar_url,is_system_account)`
- RSVP list with participant profiles: `select=*,profiles(full_name,avatar_url)`
- Challenge participants with profile: `select=*,profiles(full_name,avatar_url)`
- Recognitions with giver and recipients: `select=*,giver:profiles!giver_id(full_name,avatar_url),recognition_recipients(recipient_id,profiles(full_name,avatar_url))`
- Poll with options and vote counts: `select=*,poll_options(id,option_text,display_order,poll_votes(count))`
- Event attendance with profiles: `select=*,profiles(full_name,avatar_url)`
- Monthly rankings: `select=user_id,events_attended,recognitions_received,posts_count,profiles(full_name,avatar_url)&stat_month=eq.{date}&order=events_attended.desc`

### Error Handling on Client

| HTTP Status | Client Action |
|-------------|--------------|
| 200 / 201 | Success — proceed |
| 400 | Validation error — show field-level feedback |
| 401 | Session expired — force logout, redirect to auth |
| 403 | Permission denied — show "You don't have access" toast |
| 404 | Resource not found — show "Not found" state |
| 409 | Conflict — show specific message (e.g., "Already voted on this poll") |
| 422 | Unprocessable — show validation error toast |
| 500 | Server error — show "Something went wrong. Try again." toast |
| Network error | Show offline banner; queue mutation for retry |

### Idempotency

Edge Functions that can be retried are designed to be idempotent:
- `close-challenge` — re-processing an already-ended challenge is a no-op
- `close-poll` — re-processing an already-closed poll returns 409 CONFLICT for single poll; skips already-closed polls in batch mode
- `compute-monthly-stats` — uses UPSERT; safe to re-run for the same month
- `scheduled-cleanup` — safe to re-run; DELETE on non-existent rows is safe
- `record-attendance` — uses batch UPSERT; re-running with same data is a no-op
- `post-connect-buddy-message` — not idempotent by design (each call creates a new post)
- `cancel-activity` — returns 409 CONFLICT if already cancelled (not idempotent by design; prevents accidental re-cancel notifications)
