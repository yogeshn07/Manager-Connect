# Database Entity Catalogue

## Overview

Manager Connect uses **26 application tables** in PostgreSQL (via Supabase), plus the Supabase-managed `auth.users` table. All tables live in the `public` schema unless noted. Every table has Row-Level Security (RLS) enabled.

---

## Schema at a Glance

| # | Table | Domain | Description |
|---|-------|--------|-------------|
| — | `auth.users` | Auth (managed) | Supabase-owned identity and session store |
| 1 | `profiles` | Identity | Application-level user data, role, push token, notification prefs |
| 2 | `invitations` | Auth | Invite tokens for controlled registration |
| 3 | `posts` | Feed | Community feed posts (includes Connect Buddy posts) |
| 4 | `post_images` | Feed | Photos attached to posts |
| 5 | `post_reactions` | Feed | Emoji reactions on posts |
| 6 | `comments` | Feed | Comments on posts |
| 7 | `post_mentions` | Feed | @ mentions within post content |
| 8 | `activities` | Events | Events, games, outings, and social connect meetups |
| 9 | `activity_rsvps` | Events | Member RSVP responses |
| 10 | `activity_updates` | Events | Organizer update messages on activities |
| 11 | `polls` | Events | Community polls (standalone or tied to an event) |
| 12 | `poll_options` | Events | Answer choices for a poll |
| 13 | `poll_votes` | Events | Member votes on poll options |
| 14 | `event_attendance` | Events | Post-event attendance recorded by admin |
| 15 | `challenges` | Growth | Fitness and wellness challenges |
| 16 | `challenge_participants` | Growth | Members who joined a challenge |
| 17 | `progress_logs` | Growth | Daily progress entries per member per challenge |
| 18 | `recognitions` | Recognition | Peer shout-out posts |
| 19 | `recognition_recipients` | Recognition | Recipients of a recognition (1:many) |
| 20 | `recognition_reactions` | Recognition | Emoji reactions on recognitions |
| 21 | `member_monthly_stats` | Analytics | Computed monthly engagement stats per member |
| 22 | `community_health_scores` | Analytics | Monthly community health score and participation metrics |
| 23 | `notification_inbox` | Notifications | Persisted in-app notification records |
| 24 | `flagged_content` | Admin | Member-submitted content flags |
| 25 | `pinned_announcements` | Admin | Admin-pinned feed posts |
| 26 | `admin_audit_log` | Admin | Immutable record of all admin actions |

---

## Design Principles Applied

1. **UUIDs as primary keys** — All PKs use `uuid` with `gen_random_uuid()`. No sequential integers exposed to clients.
2. **Soft deletes for user-visible content** — Posts, comments, and recognitions use `is_deleted` + `deleted_at` rather than hard DELETE. Hard deletes run on schedule after the retention period.
3. **PII anonymization on user removal** — When a user is deactivated, PII columns (name, photo, bio) are nullified in-place. Content rows remain with `author_id` pointing to the anonymized profile. No cascade-deletes on user content.
4. **`created_at` and `updated_at` on all mutable tables** — Managed via default and trigger respectively.
5. **JSONB for preferences** — Notification preferences stored as JSONB allows schema-free extension without migrations.
6. **Enum-like CHECK constraints** — Status fields use `TEXT` with a `CHECK IN (...)` constraint rather than PostgreSQL ENUM types, which are harder to alter.
7. **Junction tables for M:N relationships** — No arrays of IDs as foreign keys. All many-to-many relationships use proper junction tables.
8. **System account for Connect Buddy** — The Connect Buddy is a special profile row with `is_system_account = true`. All Connect Buddy content is authored as posts by this profile, identical in structure to member posts.

---

## Entity Definitions

---

### Table: `profiles`

**Domain:** Identity  
**Purpose:** Application-level user data extending `auth.users`. One row per user (members, admins, and the Connect Buddy system account). Created immediately after the user completes OTP verification. The Connect Buddy system account is seeded at platform initialization.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | — | PK, FK → `auth.users.id` | Matches the Supabase auth user ID exactly |
| `full_name` | `text` | NOT NULL | — | — | Display name; set to 'Removed Member' on deactivation |
| `avatar_url` | `text` | NULL | — | — | Storage path in `avatars/` bucket; null after deactivation |
| `title` | `text` | NULL | — | — | Job title or role (e.g., "Manager, Engineering") |
| `bio` | `text` | NULL | — | max 300 chars (app-enforced) | Short personal bio; null after deactivation |
| `interest_tags` | `text[]` | NOT NULL | `'{}'` | — | Array of predefined interest tag strings |
| `app_role` | `text` | NOT NULL | `'member'` | CHECK IN ('member', 'admin', 'system') | Authorization role within the app; 'system' reserved for Connect Buddy |
| `push_token` | `text` | NULL | — | — | Expo push notification token; nullified on logout/deactivation |
| `notification_preferences` | `jsonb` | NOT NULL | `'{...}'` | — | Per-category push notification opt-in/out map (see below) |
| `is_active` | `boolean` | NOT NULL | `true` | — | False = deactivated; blocks all login and data access |
| `is_system_account` | `boolean` | NOT NULL | `false` | — | True = this profile is the Connect Buddy system account; never a human member |
| `onboarding_completed` | `boolean` | NOT NULL | `false` | — | True after first-time profile setup is complete |
| `last_active_at` | `timestamptz` | NULL | — | — | Updated on each app open; used for MAU metric |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | Profile creation timestamp |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | auto-updated by trigger | Last profile update timestamp |

**Unique Constraints:** `id` (PK, also unique by definition)

**Default notification_preferences JSONB:**
```json
{
  "activity_reminders": true,
  "new_activities": true,
  "recognitions_received": true,
  "new_challenges": true,
  "challenge_reminders": true,
  "mentions": true,
  "comments_on_my_posts": true,
  "poll_reminders": true,
  "connect_buddy_updates": true
}
```

**Notes on Connect Buddy system account:**
- Seeded once during platform initialization with `is_system_account = true` and `app_role = 'system'`
- Posts authored by this profile appear in the community feed like any member post
- The system account's `id` is stored as a platform constant used by scheduled Edge Functions
- RLS policies treat `app_role = 'system'` profiles as read-only from the client; all writes are via service-role Edge Functions

**RLS Policies:**
- SELECT: all authenticated users (profiles are community-visible)
- INSERT: only via system/Edge Function at registration; not by client directly
- UPDATE: only own row (WHERE id = auth.uid()); admin can UPDATE any (is_active, app_role)
- DELETE: none (deactivation uses UPDATE, not DELETE)

---

### Table: `invitations`

**Domain:** Auth  
**Purpose:** Tracks invite tokens generated by admin for new member registration. Token stored as a hash; raw token sent via email/SMS.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Internal ID |
| `token_hash` | `text` | NOT NULL | — | UNIQUE | SHA-256 hash of the UUID token sent to invitee |
| `invitee_name` | `text` | NOT NULL | — | — | Display name for the invited manager |
| `invitee_email` | `text` | NULL | — | — | Email address; at least one of email/phone required |
| `invitee_phone` | `text` | NULL | — | — | Mobile number for SMS delivery |
| `invited_by` | `uuid` | NOT NULL | — | FK → `profiles.id` | Admin who created the invite |
| `status` | `text` | NOT NULL | `'pending'` | CHECK IN ('pending', 'accepted', 'revoked', 'expired') | Lifecycle state of the invite |
| `accepted_by` | `uuid` | NULL | — | FK → `profiles.id` | Set to the new user's profile ID on acceptance |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | When the invite was created |
| `expires_at` | `timestamptz` | NOT NULL | `now() + interval '72 hours'` | — | Token is invalid after this timestamp |
| `accepted_at` | `timestamptz` | NULL | — | — | When the invitee completed registration |

**Unique Constraints:** `token_hash`

**Check Constraints:**
- At least one of `invitee_email` or `invitee_phone` must be non-null (enforced at Edge Function level)
- `expires_at > created_at`

**RLS Policies:**
- SELECT: admin only
- INSERT: via Edge Function only (service role); not client-writeable
- UPDATE: via Edge Function only (status updates)
- DELETE: none

---

### Table: `posts`

**Domain:** Feed  
**Purpose:** Community feed posts. Supports text and references to attached images. Soft-deleted rather than hard-deleted. Connect Buddy posts are authored by the system profile and appear in this table identically to member posts.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Post identifier |
| `author_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Author; includes the Connect Buddy system profile |
| `content` | `text` | NOT NULL | — | min 1 char | Post text body |
| `is_deleted` | `boolean` | NOT NULL | `false` | — | Soft-delete flag; hidden from all queries when true |
| `deleted_at` | `timestamptz` | NULL | — | — | When the post was soft-deleted |
| `deleted_by` | `uuid` | NULL | — | FK → `profiles.id` | Null = self-deleted; non-null = admin-deleted |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | Post creation timestamp |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | auto-updated by trigger | Last content edit timestamp |

**RLS Policies:**
- SELECT: all authenticated users WHERE is_deleted = false
- INSERT: any authenticated user (own posts only); Connect Buddy posts inserted via service-role Edge Function
- UPDATE: own post only (content edit); admin can UPDATE is_deleted, deleted_by, deleted_at
- DELETE: none (soft delete only)

---

### Table: `post_images`

**Domain:** Feed  
**Purpose:** Photo attachments on posts. Separate table to support 1:many images per post cleanly without arrays.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Image record identifier |
| `post_id` | `uuid` | NOT NULL | — | FK → `posts.id` ON DELETE CASCADE | Parent post |
| `storage_path` | `text` | NOT NULL | — | UNIQUE | Path in Supabase Storage `post-images/` bucket |
| `display_order` | `smallint` | NOT NULL | `0` | — | Sort order for multi-image display (0-based) |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | Upload timestamp |

**RLS Policies:**
- SELECT: all authenticated users (cascade from post visibility)
- INSERT: only by post author (validated via post ownership check)
- UPDATE: none
- DELETE: only by post author or admin

---

### Table: `post_reactions`

**Domain:** Feed  
**Purpose:** Emoji reactions on posts. One reaction per user per post; replacing a reaction updates the existing row rather than inserting a new one.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Reaction identifier |
| `post_id` | `uuid` | NOT NULL | — | FK → `posts.id` ON DELETE CASCADE | Post being reacted to |
| `user_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | User who reacted |
| `emoji` | `text` | NOT NULL | — | — | Single emoji character; supported set enforced application-side: 👍 ❤️ 😀 😂 😮 👏 🔥 💯 |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | When the reaction was placed |

**Unique Constraints:** `(post_id, user_id)` — one reaction per user per post

**RLS Policies:**
- SELECT: all authenticated users
- INSERT: any authenticated user (own reaction only)
- UPDATE: own reaction only (emoji change)
- DELETE: own reaction only (unreact)

---

### Table: `comments`

**Domain:** Feed  
**Purpose:** Comments on posts. Flat (not threaded). Soft-deleted.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Comment identifier |
| `post_id` | `uuid` | NOT NULL | — | FK → `posts.id` ON DELETE CASCADE | Parent post |
| `author_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Comment author |
| `content` | `text` | NOT NULL | — | min 1 char | Comment text |
| `is_deleted` | `boolean` | NOT NULL | `false` | — | Soft-delete flag |
| `deleted_at` | `timestamptz` | NULL | — | — | Deletion timestamp |
| `deleted_by` | `uuid` | NULL | — | FK → `profiles.id` | Null = self, non-null = admin |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | Comment creation timestamp |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | auto-updated by trigger | — |

**RLS Policies:**
- SELECT: all authenticated users WHERE is_deleted = false
- INSERT: any authenticated user
- UPDATE: own comment only
- DELETE: none (soft delete)

---

### Table: `post_mentions`

**Domain:** Feed  
**Purpose:** Records explicit @ mentions within a post's content. Enables targeted push notifications without parsing content at query time.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Mention record identifier |
| `post_id` | `uuid` | NOT NULL | — | FK → `posts.id` ON DELETE CASCADE | Post containing the mention |
| `mentioned_user_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | User who was mentioned |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | When the mention was created |

**Unique Constraints:** `(post_id, mentioned_user_id)` — one mention record per user per post

**Note:** Populated by Edge Function at post creation time; not written directly by client.

**RLS Policies:**
- SELECT: own mentions only (WHERE mentioned_user_id = auth.uid())
- INSERT: Edge Function only
- UPDATE/DELETE: none

---

### Table: `activities`

**Domain:** Events  
**Purpose:** Events organized by community members — games (Cricket, Badminton, Pickleball, Table Tennis, Other), outings, and social connect meetups (Coffee Connect, Lunch Meetup, Dinner Meetup, Other).

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Activity identifier |
| `created_by` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member who created the activity |
| `title` | `text` | NOT NULL | — | max 120 chars | Activity title |
| `description` | `text` | NULL | — | — | Optional extended description |
| `event_date` | `timestamptz` | NOT NULL | — | — | Date and time of the event |
| `location` | `text` | NOT NULL | — | — | Location name or address |
| `cost_note` | `text` | NULL | — | — | Optional note about costs (e.g., "~₹500/person") |
| `event_category` | `text` | NOT NULL | `'outings'` | CHECK IN ('games', 'outings', 'social_connect') | High-level event category for module routing and filtering |
| `event_type` | `text` | NULL | — | — | Specific event type within category (e.g., 'cricket', 'badminton', 'pickleball', 'table_tennis', 'coffee_connect', 'lunch_meetup', 'dinner_meetup', 'other'); null = not applicable or 'other' |
| `status` | `text` | NOT NULL | `'active'` | CHECK IN ('active', 'cancelled') | Lifecycle status |
| `cancelled_at` | `timestamptz` | NULL | — | — | Set when status is changed to 'cancelled' |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | Creation timestamp |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | auto-updated by trigger | Last update timestamp |

**Notes on event_category and event_type:**
- `event_category = 'games'` → `event_type` ∈ {'cricket', 'badminton', 'pickleball', 'table_tennis', 'other'}
- `event_category = 'social_connect'` → `event_type` ∈ {'coffee_connect', 'lunch_meetup', 'dinner_meetup', 'other'}
- `event_category = 'outings'` → `event_type` is typically null or 'other' (outings are a single category)

**RLS Policies:**
- SELECT: all authenticated users
- INSERT: any authenticated user
- UPDATE: only by creator_id or admin (status cancel, content edits)
- DELETE: none

---

### Table: `activity_rsvps`

**Domain:** Events  
**Purpose:** Member RSVP responses to activities. One response per member per activity; updateable (Going → Maybe, etc.).

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | RSVP identifier |
| `activity_id` | `uuid` | NOT NULL | — | FK → `activities.id` ON DELETE CASCADE | Activity being responded to |
| `user_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Responding member |
| `status` | `text` | NOT NULL | — | CHECK IN ('going', 'not_going', 'maybe') | RSVP response |
| `responded_at` | `timestamptz` | NOT NULL | `now()` | — | Last response or update timestamp |

**Unique Constraints:** `(activity_id, user_id)` — one RSVP per member per activity

**RLS Policies:**
- SELECT: all authenticated users (RSVP lists are community-visible)
- INSERT: any authenticated user (own RSVP only)
- UPDATE: own RSVP only
- DELETE: own RSVP only (withdraw response)

---

### Table: `activity_updates`

**Domain:** Events  
**Purpose:** Organizer update messages attached to an activity (e.g., "Location changed to XYZ"). Displayed in the activity detail view. Triggers notifications to RSVPd members.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Update record identifier |
| `activity_id` | `uuid` | NOT NULL | — | FK → `activities.id` ON DELETE CASCADE | Activity this update belongs to |
| `author_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Must be activity creator (enforced at application layer) |
| `content` | `text` | NOT NULL | — | — | Update message text |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | When the update was posted |

**RLS Policies:**
- SELECT: all authenticated users
- INSERT: only the activity creator (validated at RLS via join with activities)
- UPDATE/DELETE: none

---

### Table: `polls`

**Domain:** Events  
**Purpose:** Community polls. May be standalone (e.g., "Where should we go for lunch?") or tied to a specific activity. One vote per user per poll enforced via `poll_votes` UNIQUE constraint.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Poll identifier |
| `activity_id` | `uuid` | NULL | — | FK → `activities.id` | Linked activity; null if standalone poll |
| `created_by` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member who created the poll |
| `question` | `text` | NOT NULL | — | min 1 char | Poll question text |
| `closes_at` | `timestamptz` | NOT NULL | — | — | Poll automatically closes at this timestamp |
| `is_closed` | `boolean` | NOT NULL | `false` | — | True = poll is closed and no more votes accepted |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | Creation timestamp |

**Indexes:**
- `idx_polls_activity` on `activity_id` (polls tied to an event)
- `idx_polls_open` on `closes_at` WHERE `is_closed = false` (active polls list)

**RLS Policies:**
- SELECT: all authenticated users
- INSERT: any authenticated user (or Edge Function for Connect Buddy polls)
- UPDATE: Edge Function only (`close-poll` sets `is_closed = true`)
- DELETE: none

---

### Table: `poll_options`

**Domain:** Events  
**Purpose:** Answer choices for a poll. Each poll has 2 or more options. Inserted atomically with the poll via the `create-poll` Edge Function.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Option identifier |
| `poll_id` | `uuid` | NOT NULL | — | FK → `polls.id` ON DELETE CASCADE | Parent poll |
| `option_text` | `text` | NOT NULL | — | min 1 char | Display text for this answer choice |
| `display_order` | `smallint` | NOT NULL | — | — | Sort order for rendering options (0-based) |

**RLS Policies:**
- SELECT: all authenticated users
- INSERT: Edge Function only (inserted atomically with poll creation)
- UPDATE/DELETE: none

---

### Table: `poll_votes`

**Domain:** Events  
**Purpose:** Records which option each member voted for in a poll. Enforces one vote per user per poll via UNIQUE constraint. Voting on a closed poll is rejected at the Edge Function layer.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Vote record identifier |
| `poll_id` | `uuid` | NOT NULL | — | FK → `polls.id` ON DELETE CASCADE | Poll being voted on |
| `option_id` | `uuid` | NOT NULL | — | FK → `poll_options.id` ON DELETE CASCADE | Selected answer option |
| `user_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member who voted |
| `voted_at` | `timestamptz` | NOT NULL | `now()` | — | When the vote was cast |

**Unique Constraints:** `(poll_id, user_id)` — one vote per user per poll

**Indexes:**
- `idx_poll_votes_poll` on `poll_id` (vote count aggregation per option)
- `idx_poll_votes_user` on `user_id` (user's voting history)

**RLS Policies:**
- SELECT: all authenticated users (results are community-visible)
- INSERT: any authenticated user (own vote only; UNIQUE enforced by DB)
- UPDATE: none (votes cannot be changed; withdraw and re-vote not permitted)
- DELETE: none

---

### Table: `event_attendance`

**Domain:** Events  
**Purpose:** Post-event attendance records. Admin records who attended vs. was absent after the event occurs. Used by Analytics for participation metrics and rankings. Not self-reported — admin-recorded only.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Attendance record identifier |
| `activity_id` | `uuid` | NOT NULL | — | FK → `activities.id` NOT NULL | Event the record belongs to |
| `user_id` | `uuid` | NOT NULL | — | FK → `profiles.id` NOT NULL | Member whose attendance is recorded |
| `status` | `text` | NOT NULL | — | CHECK IN ('attended', 'absent') | Attendance outcome |
| `recorded_by` | `uuid` | NOT NULL | — | FK → `profiles.id` | Admin who recorded the attendance |
| `recorded_at` | `timestamptz` | NOT NULL | `now()` | — | When the record was created |

**Unique Constraints:** `(activity_id, user_id)` — one attendance record per member per event

**Indexes:**
- `idx_attendance_activity` on `activity_id` (attendance list per event)
- `idx_attendance_user` on `user_id` (member's attendance history)

**RLS Policies:**
- SELECT: all authenticated users (attendance is community-visible for analytics)
- INSERT: admin only (via `record-attendance` Edge Function)
- UPDATE: admin only (correct a mistaken record)
- DELETE: none

---

### Table: `challenges`

**Domain:** Growth  
**Purpose:** Fitness and wellness challenges. Members join independently and log progress against a defined goal.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Challenge identifier |
| `created_by` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member or admin who created the challenge |
| `title` | `text` | NOT NULL | — | — | Challenge name |
| `description` | `text` | NULL | — | — | Optional extended description |
| `challenge_type` | `text` | NOT NULL | — | CHECK IN ('fitness', 'wellness') | Category of the challenge |
| `goal_type` | `text` | NOT NULL | — | CHECK IN ('steps', 'distance', 'duration', 'custom') | How progress is measured; determines the unit of progress_logs.value |
| `goal_description` | `text` | NULL | — | — | Required when goal_type = 'custom'; describes what participants should do (app-enforced) |
| `start_date` | `date` | NOT NULL | — | — | Challenge start date (inclusive) |
| `end_date` | `date` | NOT NULL | — | CHECK end_date > start_date | Challenge end date (inclusive); must be after start_date |
| `status` | `text` | NOT NULL | `'active'` | CHECK IN ('active', 'ended') | Lifecycle state; set to 'ended' by the end-challenge scheduler |
| `ended_at` | `timestamptz` | NULL | — | — | Set when status transitions to 'ended' |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | Creation timestamp |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | auto-updated by trigger | Last update timestamp |

**Check Constraints:** `challenge_type IN ('fitness','wellness')`, `goal_type IN ('steps','distance','duration','custom')`, `end_date > start_date`, `status IN ('active','ended')`

**RLS Policies:**
- SELECT: all authenticated users
- INSERT: any authenticated user
- UPDATE: creator only for content; Edge Function updates status to 'ended'
- DELETE: none

---

### Table: `challenge_participants`

**Domain:** Growth  
**Purpose:** Junction table tracking which members have joined which challenge.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Participant record identifier |
| `challenge_id` | `uuid` | NOT NULL | — | FK → `challenges.id` ON DELETE CASCADE | Challenge joined |
| `user_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member who joined |
| `joined_at` | `timestamptz` | NOT NULL | `now()` | — | When the member joined |

**Unique Constraints:** `(challenge_id, user_id)`

**RLS Policies:**
- SELECT: all authenticated users (leaderboard requires seeing all participants)
- INSERT: any authenticated user (own participation only)
- DELETE: own participation only (leave challenge)

---

### Table: `progress_logs`

**Domain:** Growth  
**Purpose:** Daily progress entries submitted by a participant in a challenge. One entry per member per calendar day per challenge.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Log entry identifier |
| `challenge_id` | `uuid` | NOT NULL | — | FK → `challenges.id` ON DELETE CASCADE | Challenge being logged against |
| `user_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member logging progress |
| `challenge_participant_id` | `uuid` | NOT NULL | — | FK → `challenge_participants.id` ON DELETE CASCADE | Participant row; enables direct query from log to participant without extra join |
| `log_date` | `date` | NOT NULL | — | — | Calendar date for this entry |
| `value` | `numeric` | NOT NULL | — | value > 0 | Progress value in the challenge's goal_unit |
| `note` | `text` | NULL | — | — | Optional personal note |
| `logged_at` | `timestamptz` | NOT NULL | `now()` | — | When the log was submitted |

**Unique Constraints:** `(challenge_id, user_id, log_date)` — one entry per member per day per challenge; updates replace the existing row

**RLS Policies:**
- SELECT: all authenticated users (leaderboard uses aggregates from all rows)
- INSERT: only if user is a participant (validated via challenge_participants)
- UPDATE: own entry only, same-day only (app-enforced)
- DELETE: own entry only

---

### Table: `recognitions`

**Domain:** Recognition  
**Purpose:** Peer shout-out posts. A recognition has one giver but can have multiple recipients (see `recognition_recipients`). Part of the Recognition domain; recognition data feeds into analytics and rankings via `member_monthly_stats`.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Recognition identifier |
| `giver_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member who gave the recognition |
| `category_tag` | `text` | NOT NULL | — | CHECK IN ('community_contributor', 'fitness_champion', 'wellness_champion', 'event_champion', 'most_supportive_manager') | Recognition category |
| `message` | `text` | NOT NULL | — | min 1 char, max 500 chars | Recognition message |
| `is_deleted` | `boolean` | NOT NULL | `false` | — | Soft-delete flag |
| `deleted_at` | `timestamptz` | NULL | — | — | Deletion timestamp |
| `deleted_by` | `uuid` | NULL | — | FK → `profiles.id` | Admin who deleted (null if giver self-deleted) |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | Creation timestamp |

**RLS Policies:**
- SELECT: all authenticated users WHERE is_deleted = false
- INSERT: any authenticated user
- UPDATE: own recognition only; admin can soft-delete
- DELETE: none

---

### Table: `recognition_recipients`

**Domain:** Recognition  
**Purpose:** Junction table for the many-to-many relationship between a recognition and its recipients (FR-06.1: "one or more members").

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Record identifier |
| `recognition_id` | `uuid` | NOT NULL | — | FK → `recognitions.id` ON DELETE CASCADE | Parent recognition |
| `recipient_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member receiving the recognition |

**Unique Constraints:** `(recognition_id, recipient_id)`

**RLS Policies:**
- SELECT: all authenticated users (wall is community-visible)
- INSERT: created atomically with the recognition (own giver context)
- DELETE: none

---

### Table: `recognition_reactions`

**Domain:** Recognition  
**Purpose:** Emoji reactions on recognition posts. One reaction per user per recognition.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Reaction identifier |
| `recognition_id` | `uuid` | NOT NULL | — | FK → `recognitions.id` ON DELETE CASCADE | Recognition being reacted to |
| `user_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | User who reacted |
| `emoji` | `text` | NOT NULL | — | — | Single emoji character; supported set enforced application-side: 👍 ❤️ 😀 😂 😮 👏 🔥 💯 |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | Reaction timestamp |

**Unique Constraints:** `(recognition_id, user_id)` — one reaction per user per recognition

**RLS Policies:**
- SELECT: all authenticated users
- INSERT: any authenticated user
- UPDATE: own reaction only
- DELETE: own reaction only

---

### Table: `member_monthly_stats`

**Domain:** Analytics  
**Purpose:** Pre-computed monthly engagement statistics per member. Populated by the `compute-monthly-stats` scheduled Edge Function on the first day of each month for the prior month. Powers Personal Analytics, Monthly Rankings, and Monthly Recognition views. Not written by clients.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Record identifier |
| `user_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member these stats belong to |
| `stat_month` | `date` | NOT NULL | — | — | First day of the month these stats represent (e.g., 2026-06-01) |
| `events_attended` | `integer` | NOT NULL | `0` | CHECK >= 0 | Count of events with attendance status = 'attended' in the month |
| `attendance_rate` | `numeric(5,2)` | NOT NULL | `0.00` | CHECK 0–100 | Percentage of RSVPed events the member actually attended |
| `challenges_joined` | `integer` | NOT NULL | `0` | CHECK >= 0 | Challenges the member joined in this month |
| `progress_logs_count` | `integer` | NOT NULL | `0` | CHECK >= 0 | Total progress log entries submitted this month |
| `recognitions_received` | `integer` | NOT NULL | `0` | CHECK >= 0 | Recognitions received this month |
| `recognitions_given` | `integer` | NOT NULL | `0` | CHECK >= 0 | Recognitions given this month |
| `posts_count` | `integer` | NOT NULL | `0` | CHECK >= 0 | Posts authored this month (excludes Connect Buddy posts) |
| `composite_score` | `numeric(6,2)` | NOT NULL | `0.00` | CHECK >= 0 | Weighted engagement score used for monthly rankings; formula defined in Edge Function |
| `computed_at` | `timestamptz` | NOT NULL | `now()` | — | When this record was computed |

**Unique Constraints:** `(user_id, stat_month)` — one stat row per member per month

**Indexes:**
- `idx_monthly_stats_user` on `(user_id, stat_month DESC)` — user's stats history, most recent first
- `idx_monthly_stats_month` on `stat_month` — all members' stats for a given month (rankings query)

**RLS Policies:**
- SELECT: all authenticated active users (rankings require all members to read all rows — same pattern as `community_health_scores`)
- INSERT: Edge Function only (service role; `compute-monthly-stats` scheduled function)
- UPDATE: Edge Function only (recomputation if needed)
- DELETE: none

---

### Table: `community_health_scores`

**Domain:** Analytics  
**Purpose:** Monthly community-level health and engagement metrics. One row per month, computed by `compute-monthly-stats`. Powers the Community Health Score and Community Analytics views visible to all members and admins.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Record identifier |
| `score_month` | `date` | NOT NULL | — | UNIQUE | First day of the month this score represents |
| `score` | `numeric(5,2)` | NOT NULL | — | CHECK 0–100 | Composite community health score on a 0–100 scale |
| `active_member_count` | `integer` | NOT NULL | `0` | CHECK >= 0 | Count of members who performed at least one tracked action in the month |
| `avg_attendance_rate` | `numeric(5,2)` | NOT NULL | `0.00` | CHECK 0–100 | Average attendance rate across all active members for the month |
| `challenge_engagement_rate` | `numeric(5,2)` | NOT NULL | `0.00` | CHECK 0–100 | Percentage of active members who participated in at least one challenge |
| `recognition_activity_rate` | `numeric(5,2)` | NOT NULL | `0.00` | CHECK 0–100 | Percentage of active members who gave or received at least one recognition |
| `participation_rate` | `numeric(5,2)` | NOT NULL | `0.00` | CHECK 0–100 | Percentage of active members who attended at least one event |
| `computed_at` | `timestamptz` | NOT NULL | `now()` | — | When this record was computed |

**Unique Constraints:** `score_month` — one health score row per month (also serves as the primary lookup index)

**RLS Policies:**
- SELECT: all authenticated users (Community Health Score is visible to all members)
- INSERT: Edge Function only (service role; `compute-monthly-stats` scheduled function)
- UPDATE: none (scores are immutable once computed; recompute = re-insert with upsert)
- DELETE: none

---

### Table: `notification_inbox`

**Domain:** Notifications  
**Purpose:** Persisted record of notifications sent to each user. Powers the in-app notification inbox screen (FR-08.3). Created server-side for each notification dispatched.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Notification record identifier |
| `recipient_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Notification recipient |
| `type` | `text` | NOT NULL | — | CHECK IN (see below) | Notification category |
| `title` | `text` | NOT NULL | — | — | Push notification title text |
| `body` | `text` | NOT NULL | — | — | Push notification body text |
| `actor_id` | `uuid` | NULL | — | FK → `profiles.id` ON DELETE SET NULL | Member who triggered the notification; NULL for system-generated notifications |
| `reference_type` | `text` | NULL | — | CHECK IN ('activity','challenge','recognition','poll','post','user') or NULL | Type of linked resource; used for deep-link routing |
| `reference_id` | `uuid` | NULL | — | — | ID of the linked resource; combined with reference_type to construct a deep link |
| `is_read` | `boolean` | NOT NULL | `false` | — | Whether the user has read/dismissed this notification |
| `read_at` | `timestamptz` | NULL | — | — | When the notification was marked as read |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | When the notification was created |

**Type CHECK values:**
`'activity_created'`, `'activity_reminder_24h'`, `'activity_reminder_1h'`, `'activity_cancelled'`, `'activity_updated'`, `'recognition_received'`, `'challenge_created'`, `'challenge_ending'`, `'challenge_ended'`, `'mention'`, `'comment_on_post'`, `'poll_reminder'`, `'connect_buddy_update'`, `'admin_flag'`, `'admin_member_registered'`

**RLS Policies:**
- SELECT: own notifications only (WHERE recipient_id = auth.uid())
- INSERT: Edge Function only (server-side notification dispatch)
- UPDATE: own rows only (mark as read)
- DELETE: own rows only (clear inbox)

---

### Table: `flagged_content`

**Domain:** Admin  
**Purpose:** Tracks member-submitted flags on posts or comments for admin review. One flag per member per content item (members cannot spam-flag the same post).

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Flag record identifier |
| `content_type` | `text` | NOT NULL | — | CHECK IN ('post', 'comment') | Type of flagged content |
| `content_id` | `uuid` | NOT NULL | — | — | ID of the flagged post or comment (polymorphic soft FK, no DB constraint) |
| `reporter_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Member who submitted the flag |
| `reason` | `text` | NULL | — | — | Optional free-text reason from the member |
| `status` | `text` | NOT NULL | `'pending'` | CHECK IN ('pending', 'resolved_deleted', 'resolved_dismissed') | Review status |
| `resolved_by` | `uuid` | NULL | — | FK → `profiles.id` | Admin who resolved the flag |
| `resolved_at` | `timestamptz` | NULL | — | — | When the flag was resolved |
| `created_at` | `timestamptz` | NOT NULL | `now()` | — | When the flag was submitted |

**Unique Constraints:** `(content_type, content_id, flagged_by)` — one flag per member per content item

**Note:** `content_id` does not have a DB-level FK because it references either `posts.id` or `comments.id` depending on `content_type`. Referential integrity enforced at application/Edge Function level.

**RLS Policies:**
- SELECT: admin only
- INSERT: any authenticated user (flag own or others' content)
- UPDATE: admin only (status resolution)
- DELETE: none

---

### Table: `pinned_announcements`

**Domain:** Admin  
**Purpose:** Admin-pinned posts shown at the top of the community feed. Only one announcement is active at a time, enforced by a partial unique index.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Pin record identifier |
| `post_id` | `uuid` | NOT NULL | — | FK → `posts.id` | The post being pinned |
| `pinned_by` | `uuid` | NOT NULL | — | FK → `profiles.id` | Admin who pinned the post |
| `is_active` | `boolean` | NOT NULL | `true` | — | True = currently pinned; false = unpinned |
| `pinned_at` | `timestamptz` | NOT NULL | `now()` | — | When the post was pinned |
| `unpinned_at` | `timestamptz` | NULL | — | — | When the post was unpinned |

**Unique Constraints:** Partial unique index on `(is_active) WHERE is_active = true` — only one active pin at any time

**Business Rule:** Before inserting a new active pin, the Edge Function sets all existing active pins to `is_active = false`.

**RLS Policies:**
- SELECT: all authenticated users (feed needs to display the pinned post)
- INSERT: admin only
- UPDATE: admin only (to unpin)
- DELETE: none

---

### Table: `admin_audit_log`

**Domain:** Admin  
**Purpose:** Immutable append-only log of all admin actions. No UPDATE or DELETE is permitted on this table by any role, including admin. Retained for 1 year.

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK | Log entry identifier |
| `admin_id` | `uuid` | NOT NULL | — | FK → `profiles.id` | Admin who performed the action |
| `action_type` | `text` | NOT NULL | — | CHECK IN (see below) | What action was taken |
| `target_type` | `text` | NOT NULL | — | CHECK IN ('user','post','comment','flag','announcement','invitation','attendance','poll') | What type of resource was affected |
| `target_id` | `uuid` | NULL | — | — | ID of the affected resource |
| `metadata` | `jsonb` | NULL | — | — | Additional context (e.g., before-state, reason, invitee name) |
| `performed_at` | `timestamptz` | NOT NULL | `now()` | — | When the action occurred |

**Action Type CHECK values:**
`'user_invited'`, `'user_deactivated'`, `'user_reactivated'`, `'user_removed'`, `'invitation_revoked'`, `'post_deleted'`, `'comment_deleted'`, `'flag_resolved_deleted'`, `'flag_resolved_dismissed'`, `'content_pinned'`, `'content_unpinned'`, `'attendance_recorded'`, `'poll_closed'`

**RLS Policies:**
- SELECT: admin only
- INSERT: Edge Function only (service role — never client-writable)
- UPDATE: none (immutable)
- DELETE: none (immutable)

---

## Relationship Summary

| Relationship | Cardinality | Implementation |
|---|---|---|
| `auth.users` → `profiles` | 1:1 | profiles.id FK → auth.users.id |
| `profiles` → `posts` | 1:N | posts.author_id → profiles.id (includes Connect Buddy system profile) |
| `posts` → `post_images` | 1:N | post_images.post_id → posts.id |
| `posts` → `post_reactions` | 1:N | post_reactions.post_id → posts.id |
| `posts` → `comments` | 1:N | comments.post_id → posts.id |
| `posts` → `post_mentions` | 1:N | post_mentions.post_id → posts.id |
| `posts` → `pinned_announcements` | 1:0..1 | pinned_announcements.post_id → posts.id |
| `profiles` → `invitations` (sent) | 1:N | invitations.invited_by → profiles.id |
| `profiles` → `activities` (created) | 1:N | activities.created_by → profiles.id |
| `activities` → `activity_rsvps` | 1:N | activity_rsvps.activity_id → activities.id |
| `activities` → `activity_updates` | 1:N | activity_updates.activity_id → activities.id |
| `activities` → `polls` (optional) | 1:0..N | polls.activity_id → activities.id (nullable) |
| `polls` → `poll_options` | 1:N | poll_options.poll_id → polls.id |
| `polls` → `poll_votes` | 1:N | poll_votes.poll_id → polls.id |
| `poll_options` → `poll_votes` | 1:N | poll_votes.option_id → poll_options.id |
| `activities` → `event_attendance` | 1:N | event_attendance.activity_id → activities.id |
| `profiles` → `challenges` (created) | 1:N | challenges.created_by → profiles.id |
| `challenges` → `challenge_participants` | 1:N | challenge_participants.challenge_id → challenges.id |
| `challenges` → `progress_logs` | 1:N | progress_logs.challenge_id → challenges.id |
| `profiles` → `recognitions` (given) | 1:N | recognitions.giver_id → profiles.id |
| `recognitions` → `recognition_recipients` | 1:N | recognition_recipients.recognition_id → recognitions.id |
| `recognitions` → `recognition_reactions` | 1:N | recognition_reactions.recognition_id → recognitions.id |
| `profiles` → `member_monthly_stats` | 1:N | member_monthly_stats.user_id → profiles.id |
| `profiles` → `notification_inbox` | 1:N | notification_inbox.recipient_id → profiles.id |
| `profiles` → `admin_audit_log` | 1:N | admin_audit_log.admin_id → profiles.id |

---

## Entity Count Summary

| Domain | Tables | Rows (Est. at launch) |
|--------|--------|-----------------------|
| Identity | 2 | ~25 (includes Connect Buddy system account) |
| Feed | 5 | Grows with usage |
| Events | 7 | Grows with usage (activities + polls + attendance) |
| Growth | 3 | Grows with usage |
| Recognition | 3 | Grows with usage |
| Analytics | 2 | Low volume; computed monthly |
| Notifications | 1 | High volume; pruned regularly |
| Admin | 3 | Low volume; audit log grows over time |
| **Total** | **26** | — |
