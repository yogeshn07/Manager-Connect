# Database Schema Design

This document is the authoritative design specification for the Manager Connect PostgreSQL database. The database runs on PostgreSQL v15+ via Supabase and comprises **26 application tables** organized into **8 domain layers**. All tables reside in the `public` schema. Row Level Security (RLS) is enabled on every table, ensuring that data access is governed at the database layer regardless of which client or service issues a query. This document describes the schema in terms of structure, constraints, and indexing rationale. It is a design reference, not a migration script.

---

## Design Conventions

The following conventions apply uniformly across all 26 tables.

- **Primary Keys:** All tables use a `uuid` primary key named `id`, defaulting to `gen_random_uuid()`.
- **Soft Deletes:** Mutable content tables (posts, comments, recognitions) use three columns rather than hard `DELETE`: `is_deleted` (boolean), `deleted_at` (timestamptz), and `deleted_by` (uuid FK to profiles). Physical deletion is never used for content rows.
- **Timestamps:** Every mutable table carries `created_at` (set once on insert) and `updated_at` (managed by a shared trigger function — see Trigger Specification). Immutable/append-only tables carry only `created_at`.
- **Enum Replacement:** PostgreSQL `ENUM` types are deliberately avoided. All categorical columns use `TEXT` with a `CHECK` constraint listing allowed values. This allows schema evolution without `ALTER TYPE` migrations.
- **Flexible Preferences:** Per-user preference maps are stored as `JSONB` rather than individual boolean columns, making it straightforward to add new notification categories without schema changes.
- **Soft Foreign Keys:** Polymorphic references (e.g., `flagged_content.content_id`) omit a database-level `FK` constraint where a single column must reference one of several tables. Referential integrity for these cases is enforced by application logic and RLS policies.

---

## Database at a Glance

| # | Table | Domain | Purpose |
|---|-------|--------|---------|
| 1 | `profiles` | Identity | Application-level user profiles extending Supabase auth |
| 2 | `invitations` | Identity | Invite-only registration tokens (hashed) |
| 3 | `posts` | Feed | Community feed posts including Connect Buddy system posts |
| 4 | `post_images` | Feed | Photos attached to feed posts (up to 4 per post) |
| 5 | `post_reactions` | Feed | Emoji reactions on posts (one per user per post) |
| 6 | `comments` | Feed | Flat comments on feed posts |
| 7 | `post_mentions` | Feed | @mention relationships extracted from post content |
| 8 | `activities` | Events | Events across Games, Outings, and Social Connect categories |
| 9 | `activity_rsvps` | Events | Member RSVP responses for events |
| 10 | `activity_updates` | Events | Organizer update messages posted to an event |
| 11 | `polls` | Events | Community polls, standalone or linked to an event |
| 12 | `poll_options` | Events | Answer choices for a poll |
| 13 | `poll_votes` | Events | Member votes on poll options |
| 14 | `event_attendance` | Events | Post-event attendance records (admin-written) |
| 15 | `challenges` | Growth | Fitness and wellness challenges with defined goal types |
| 16 | `challenge_participants` | Growth | Members who have joined a challenge |
| 17 | `progress_logs` | Growth | Daily progress entries for challenge participants |
| 18 | `recognitions` | Recognition | Peer shout-out posts with category tags |
| 19 | `recognition_recipients` | Recognition | Recipients of a recognition (one row per recipient) |
| 20 | `recognition_reactions` | Recognition | Emoji reactions on recognitions |
| 21 | `member_monthly_stats` | Analytics | Computed monthly engagement statistics per member |
| 22 | `community_health_scores` | Analytics | Monthly community-wide health score |
| 23 | `notification_inbox` | Notifications | Persisted in-app notification records per recipient |
| 24 | `flagged_content` | Admin | Member-submitted content flags for moderation |
| 25 | `pinned_announcements` | Admin | Admin-pinned feed posts displayed at top of Feed |
| 26 | `admin_audit_log` | Admin | Immutable record of all admin actions |

---

## Layer 1: Identity

This layer manages user identity at the application level, sitting on top of the Supabase `auth.users` system. It controls who may exist in the system (via invite tokens) and what role and preferences each user carries.

### profiles

- **Domain:** Identity
- **Purpose:** Stores application-level user data for every account in the system — members, admins, and the Connect Buddy system account — extending the base Supabase auth record with profile details, preferences, and role.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | — | PK, FK → auth.users.id | Matches the Supabase auth user ID exactly; no surrogate key |
| `full_name` | text | NOT NULL | — | — | Display name; set to `'Removed Member'` on PII anonymization |
| `avatar_url` | text | NULL | — | — | Storage path within the `avatars/` bucket; not a full URL |
| `title` | text | NULL | — | — | Job title or role descriptor (e.g., "Manager, Engineering") |
| `bio` | text | NULL | — | max 300 chars (app-enforced) | Short personal bio shown on profile screen |
| `interest_tags` | text[] | NOT NULL | `'{}'` | — | Array of predefined interest tag strings selected during onboarding |
| `app_role` | text | NOT NULL | `'member'` | CHECK IN (`'member'`, `'admin'`, `'system'`) | Authorization role; `'system'` is reserved exclusively for Connect Buddy |
| `push_token` | text | NULL | — | — | FCM device token for push delivery; nullified on logout or deactivation |
| `notification_preferences` | jsonb | NOT NULL | see below | — | Per-category push opt-in map; keys correspond to notification type identifiers |
| `is_active` | boolean | NOT NULL | `true` | — | When `false`, the account is deactivated and blocked from login and data access |
| `is_system_account` | boolean | NOT NULL | `false` | — | `true` only for the Connect Buddy account; never set on human members |
| `onboarding_completed` | boolean | NOT NULL | `false` | — | Flipped to `true` after first-time profile setup is complete |
| `last_active_at` | timestamptz | NULL | — | — | Updated on each app open; used for engagement metrics and activity scoring |
| `created_at` | timestamptz | NOT NULL | `now()` | — | Profile creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | Last modification timestamp; managed by shared trigger |

**notification_preferences JSONB Default**

```
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

- **Primary Key:** `id`
- **Foreign Keys:**
  - `id` → `auth.users.id` (no ON DELETE action; Supabase auth manages auth-level deletion)
- **Unique Constraints:** None beyond the primary key
- **Check Constraints:**
  - `app_role` must be one of `'member'`, `'admin'`, `'system'`
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_profiles_active` | `(is_active)` | B-tree | `WHERE is_active = true` | Active member list queries |
| `idx_profiles_role` | `(app_role)` | B-tree | — | Admin lookup, system account identification |
| `idx_profiles_system` | `(is_system_account)` | B-tree | `WHERE is_system_account = true` | Connect Buddy profile fetch |

---

### invitations

- **Domain:** Identity
- **Purpose:** Manages invite tokens for controlled, invite-only registration. The raw token is never stored; only its SHA-256 hash is persisted, preventing token exposure even in the event of a database read.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `invitee_name` | text | NOT NULL | — | — | Name of the person being invited |
| `invitee_email` | text | NULL | — | — | Email address for delivery; at least one of email or phone is required (app-enforced) |
| `invitee_phone` | text | NULL | — | — | Phone number for SMS delivery |
| `token_hash` | text | NOT NULL | — | UNIQUE | SHA-256 hash of the raw UUID invite token |
| `status` | text | NOT NULL | `'pending'` | CHECK IN (`'pending'`, `'accepted'`, `'expired'`, `'revoked'`) | Lifecycle state of the invitation |
| `invited_by` | uuid | NOT NULL | — | FK → profiles.id | Admin who created the invitation |
| `accepted_by` | uuid | NULL | — | FK → profiles.id | Profile created upon acceptance; null until the invitation is accepted |
| `expires_at` | timestamptz | NOT NULL | — | — | Set to 72 hours after creation by the send-invitation Edge Function |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `invited_by` → `profiles.id`
  - `accepted_by` → `profiles.id`
- **Unique Constraints:** `UNIQUE(token_hash)`
- **Check Constraints:**
  - `status` must be one of `'pending'`, `'accepted'`, `'expired'`, `'revoked'`
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_invitations_token` | `(token_hash)` | B-tree | — | Token validation lookup during registration flow |
| `idx_invitations_status` | `(status)` | B-tree | `WHERE status = 'pending'` | Admin pending invites list |

---

## Layer 2: Feed

The Feed layer stores all community feed content: posts (with optional images), reactions, comments, and mention relationships. Soft deletes are used throughout; no content row is physically removed.

### posts

- **Domain:** Feed
- **Purpose:** Stores community feed posts authored by members or the Connect Buddy system account.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `author_id` | uuid | NOT NULL | — | FK → profiles.id | Post author; may be the Connect Buddy system account |
| `content` | text | NOT NULL | — | — | Post body text |
| `is_deleted` | boolean | NOT NULL | `false` | — | Soft delete flag; deleted posts are filtered from all feed queries |
| `deleted_by` | uuid | NULL | — | FK → profiles.id | Who performed the soft delete — the author or an admin |
| `deleted_at` | timestamptz | NULL | — | — | Timestamp of soft deletion |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `author_id` → `profiles.id`
  - `deleted_by` → `profiles.id`
- **Unique Constraints:** None
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_posts_feed` | `(created_at DESC)` | B-tree | `WHERE is_deleted = false` | Community feed ordering; partial index excludes soft-deleted rows |
| `idx_posts_author` | `(author_id)` | B-tree | — | Author's post history |

---

### post_images

- **Domain:** Feed
- **Purpose:** Stores photos attached to posts, supporting up to 4 images per post in a defined display order.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `post_id` | uuid | NOT NULL | — | FK → posts.id ON DELETE CASCADE | Parent post; images are deleted when the post is hard-deleted (cascade only applies if post row is removed; soft-deleted posts retain image rows) |
| `storage_path` | text | NOT NULL | — | — | Supabase Storage path within the `post-images/` bucket |
| `display_order` | smallint | NOT NULL | `0` | CHECK (`display_order >= 0 AND display_order <= 3`) | Zero-based image order within the post; values 0–3 enforce the 4-image limit |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `post_id` → `posts.id` ON DELETE CASCADE
- **Unique Constraints:** None
- **Check Constraints:**
  - `display_order` must be between 0 and 3 inclusive
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_post_images_post` | `(post_id, display_order ASC)` | B-tree | — | Ordered image fetch for a given post |

---

### post_reactions

- **Domain:** Feed
- **Purpose:** Stores emoji reactions on posts. Each user may hold exactly one active reaction per post; changing the emoji is an upsert that replaces the previous reaction.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `post_id` | uuid | NOT NULL | — | FK → posts.id ON DELETE CASCADE | — |
| `user_id` | uuid | NOT NULL | — | FK → profiles.id | Reacting member |
| `emoji` | text | NOT NULL | — | — | Single emoji character; supported set is enforced application-side |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | Updated when the user changes their emoji on re-react |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `post_id` → `posts.id` ON DELETE CASCADE
  - `user_id` → `profiles.id`
- **Unique Constraints:** `UNIQUE(post_id, user_id)` — enforces one reaction per user per post
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_reactions_post` | `(post_id)` | B-tree | — | Reaction count and summary per post |

---

### comments

- **Domain:** Feed
- **Purpose:** Stores flat (non-threaded) comments on feed posts, with soft-delete support.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `post_id` | uuid | NOT NULL | — | FK → posts.id ON DELETE CASCADE | Parent post |
| `author_id` | uuid | NOT NULL | — | FK → profiles.id | Comment author |
| `content` | text | NOT NULL | — | — | Comment body text |
| `is_deleted` | boolean | NOT NULL | `false` | — | Soft delete flag |
| `deleted_by` | uuid | NULL | — | FK → profiles.id | Author or admin who performed the soft delete |
| `deleted_at` | timestamptz | NULL | — | — | Timestamp of soft deletion |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `post_id` → `posts.id` ON DELETE CASCADE
  - `author_id` → `profiles.id`
  - `deleted_by` → `profiles.id`
- **Unique Constraints:** None
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_comments_post` | `(post_id, created_at ASC)` | B-tree | — | Paginated comment list per post in chronological order |

---

### post_mentions

- **Domain:** Feed
- **Purpose:** Records `@mention` relationships extracted from post content. Rows are written exclusively by the create-post Edge Function, which parses mention tokens from the post body and inserts one row per unique mentioned user.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `post_id` | uuid | NOT NULL | — | FK → posts.id ON DELETE CASCADE | Parent post |
| `mentioned_user_id` | uuid | NOT NULL | — | FK → profiles.id | Member who was mentioned in the post |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `post_id` → `posts.id` ON DELETE CASCADE
  - `mentioned_user_id` → `profiles.id`
- **Unique Constraints:** `UNIQUE(post_id, mentioned_user_id)` — the same user is recorded as mentioned at most once per post
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_mentions_user` | `(mentioned_user_id)` | B-tree | — | Notification lookup for the mentioned user |

---

## Layer 3: Events

The Events layer manages the full lifecycle of community activities: creation, RSVPs, organizer updates, polls (with options and votes), and post-event attendance records.

### activities

- **Domain:** Events
- **Purpose:** Stores events across all three categories — Games, Outings, and Social Connect — in a single unified table to simplify feed queries and avoid per-category schema divergence.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `created_by` | uuid | NOT NULL | — | FK → profiles.id | Member who created the event |
| `title` | text | NOT NULL | — | — | Event title |
| `description` | text | NULL | — | — | Optional extended description |
| `event_category` | text | NOT NULL | `'outings'` | CHECK IN (`'games'`, `'outings'`, `'social_connect'`) | Primary category, used for tab filtering |
| `event_type` | text | NULL | — | CHECK IN (`'cricket'`, `'badminton'`, `'pickleball'`, `'table_tennis'`, `'coffee_connect'`, `'lunch_meetup'`, `'dinner_meetup'`, `'other'`) or NULL | Specific sub-type within the category; NULL is valid for Outings which carry no sub-types |
| `location` | text | NULL | — | — | Venue or location description |
| `event_date` | timestamptz | NOT NULL | — | — | Scheduled date and time of the event |
| `cost_note` | text | NULL | — | — | Optional cost information (e.g., "₹200 per person") |
| `status` | text | NOT NULL | `'active'` | CHECK IN (`'active'`, `'cancelled'`) | Lifecycle state |
| `cancelled_at` | timestamptz | NULL | — | — | Set when `status` transitions to `'cancelled'` |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `created_by` → `profiles.id`
- **Unique Constraints:** None
- **Check Constraints:**
  - `event_category` must be one of `'games'`, `'outings'`, `'social_connect'`
  - `event_type` must be one of the defined sport/social values, or NULL
  - `status` must be one of `'active'`, `'cancelled'`
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_activities_date` | `(event_date ASC)` | B-tree | `WHERE status = 'active'` | Upcoming activities list; partial index excludes cancelled events |
| `idx_activities_creator` | `(created_by)` | B-tree | — | Creator's event history |
| `idx_activities_category` | `(event_category)` | B-tree | — | Category tab filtering |

---

### activity_rsvps

- **Domain:** Events
- **Purpose:** Records member RSVP responses for events. Each member may hold one RSVP per event; changing the response is an upsert.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `activity_id` | uuid | NOT NULL | — | FK → activities.id ON DELETE CASCADE | Parent event |
| `user_id` | uuid | NOT NULL | — | FK → profiles.id | RSVPing member |
| `status` | text | NOT NULL | — | CHECK IN (`'going'`, `'not_going'`, `'maybe'`) | RSVP response value |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | Updated when the RSVP status changes |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `activity_id` → `activities.id` ON DELETE CASCADE
  - `user_id` → `profiles.id`
- **Unique Constraints:** `UNIQUE(activity_id, user_id)` — one RSVP per member per event
- **Check Constraints:**
  - `status` must be one of `'going'`, `'not_going'`, `'maybe'`
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_rsvps_activity` | `(activity_id)` | B-tree | — | Full RSVP list per activity |
| `idx_rsvps_user` | `(user_id)` | B-tree | — | Member's RSVP history |

---

### activity_updates

- **Domain:** Events
- **Purpose:** Stores organizer-posted update messages on an event. Writing is restricted to the event creator and is enforced by the post-activity-update Edge Function.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `activity_id` | uuid | NOT NULL | — | FK → activities.id ON DELETE CASCADE | Parent event |
| `author_id` | uuid | NOT NULL | — | FK → profiles.id | Must be the event creator (enforced by Edge Function, not DB constraint) |
| `content` | text | NOT NULL | — | — | Update message content |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `activity_id` → `activities.id` ON DELETE CASCADE
  - `author_id` → `profiles.id`
- **Unique Constraints:** None
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_activity_updates_activity` | `(activity_id, created_at ASC)` | B-tree | — | Updates for an event in chronological order |

---

### polls

- **Domain:** Events
- **Purpose:** Stores community polls. A poll may be standalone or linked to an event, and carries a defined closing time after which votes are no longer accepted.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `activity_id` | uuid | NULL | — | FK → activities.id ON DELETE SET NULL | Linked event; `NULL` for standalone polls. Set to NULL (not cascade) if the event is deleted. |
| `created_by` | uuid | NOT NULL | — | FK → profiles.id | Poll creator |
| `question` | text | NOT NULL | — | — | Poll question text |
| `closes_at` | timestamptz | NOT NULL | — | — | Poll closing time; must be in the future at creation (app-enforced) |
| `is_closed` | boolean | NOT NULL | `false` | — | Set to `true` when the poll closes, either manually or by the close-poll scheduler |
| `closed_at` | timestamptz | NULL | — | — | Timestamp when `is_closed` was flipped to `true` |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `activity_id` → `activities.id` ON DELETE SET NULL
  - `created_by` → `profiles.id`
- **Unique Constraints:** None
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_polls_activity` | `(activity_id)` | B-tree | — | Polls linked to a specific event |
| `idx_polls_open` | `(closes_at ASC)` | B-tree | `WHERE is_closed = false` | Scheduler query to find polls due for closing |

---

### poll_options

- **Domain:** Events
- **Purpose:** Stores the answer choices for a poll. Options are written atomically with their parent poll by the create-poll Edge Function and are never modified after creation.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `poll_id` | uuid | NOT NULL | — | FK → polls.id ON DELETE CASCADE | Parent poll |
| `option_text` | text | NOT NULL | — | — | Answer option text |
| `display_order` | smallint | NOT NULL | `0` | CHECK (`display_order >= 0`) | Zero-based display order of the option within the poll |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `poll_id` → `polls.id` ON DELETE CASCADE
- **Unique Constraints:** None
- **Check Constraints:**
  - `display_order` must be 0 or greater
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_poll_options_poll` | `(poll_id, display_order ASC)` | B-tree | — | Options for a poll in display order |

---

### poll_votes

- **Domain:** Events
- **Purpose:** Records each member's vote on a poll option. The `UNIQUE(poll_id, user_id)` constraint enforces one vote per member per poll at the database level, making vote-swapping impossible after submission.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `poll_id` | uuid | NOT NULL | — | FK → polls.id ON DELETE CASCADE | Parent poll |
| `poll_option_id` | uuid | NOT NULL | — | FK → poll_options.id ON DELETE CASCADE | The specific option chosen |
| `user_id` | uuid | NOT NULL | — | FK → profiles.id | Voting member |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `poll_id` → `polls.id` ON DELETE CASCADE
  - `poll_option_id` → `poll_options.id` ON DELETE CASCADE
  - `user_id` → `profiles.id`
- **Unique Constraints:** `UNIQUE(poll_id, user_id)` — one vote per member per poll; no vote-swapping after submission
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_poll_votes_poll` | `(poll_id)` | B-tree | — | Total vote count aggregation per poll |
| `idx_poll_votes_option` | `(poll_option_id)` | B-tree | — | Votes per option for result percentages |
| `idx_poll_votes_user` | `(user_id)` | B-tree | — | Member voting history |

---

### event_attendance

- **Domain:** Events
- **Purpose:** Records post-event attendance outcomes per member. Rows are written exclusively by administrators via the record-attendance Edge Function; members cannot write or modify their own attendance records.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `activity_id` | uuid | NOT NULL | — | FK → activities.id ON DELETE CASCADE | The event for which attendance is recorded |
| `user_id` | uuid | NOT NULL | — | FK → profiles.id | Member whose attendance is recorded |
| `status` | text | NOT NULL | — | CHECK IN (`'attended'`, `'absent'`) | Attendance outcome |
| `recorded_by` | uuid | NOT NULL | — | FK → profiles.id | Admin who submitted the attendance record |
| `recorded_at` | timestamptz | NOT NULL | `now()` | — | Timestamp of the admin's submission |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | Updated if the admin re-submits a corrected attendance record |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `activity_id` → `activities.id` ON DELETE CASCADE
  - `user_id` → `profiles.id`
  - `recorded_by` → `profiles.id`
- **Unique Constraints:** `UNIQUE(activity_id, user_id)` — one attendance record per member per event
- **Check Constraints:**
  - `status` must be one of `'attended'`, `'absent'`
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_attendance_activity` | `(activity_id)` | B-tree | — | Attendance sheet per event |
| `idx_attendance_user` | `(user_id)` | B-tree | — | Member's attendance history for analytics and scoring |

---

## Layer 4: Growth

The Growth layer supports fitness and wellness challenges. Members can join challenges, log daily progress, and compete on leaderboards. Challenges are created by any member or admin and have a defined start and end date.

### challenges

- **Domain:** Growth
- **Purpose:** Stores fitness and wellness challenges. Each challenge defines a goal type that determines how `progress_logs.value` is interpreted (steps, distance, duration, or custom).

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `created_by` | uuid | NOT NULL | — | FK → profiles.id | Member or admin who created the challenge |
| `title` | text | NOT NULL | — | — | Challenge name |
| `description` | text | NULL | — | — | Optional extended description |
| `challenge_type` | text | NOT NULL | — | CHECK IN (`'fitness'`, `'wellness'`) | Category of the challenge |
| `goal_type` | text | NOT NULL | — | CHECK IN (`'steps'`, `'distance'`, `'duration'`, `'custom'`) | How progress is measured; determines the unit of `progress_logs.value` |
| `goal_description` | text | NULL | — | — | Required when `goal_type = 'custom'`; describes what participants should do (app-enforced) |
| `start_date` | date | NOT NULL | — | — | Challenge start date (inclusive) |
| `end_date` | date | NOT NULL | — | CHECK (`end_date > start_date`) | Challenge end date (inclusive); must be after `start_date` |
| `status` | text | NOT NULL | `'active'` | CHECK IN (`'active'`, `'ended'`) | Lifecycle state; set to `'ended'` by the end-challenge scheduler |
| `ended_at` | timestamptz | NULL | — | — | Set when `status` transitions to `'ended'` |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `created_by` → `profiles.id`
- **Unique Constraints:** None
- **Check Constraints:**
  - `challenge_type` must be one of `'fitness'`, `'wellness'`
  - `goal_type` must be one of `'steps'`, `'distance'`, `'duration'`, `'custom'`
  - `end_date` must be strictly greater than `start_date`
  - `status` must be one of `'active'`, `'ended'`
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_challenges_status` | `(status, end_date ASC)` | B-tree | — | Active challenges list; scheduler uses this to identify challenges past their end date |

---

### challenge_participants

- **Domain:** Growth
- **Purpose:** Records which members have joined a challenge. This is an append-only join table; members cannot leave a challenge once joined (by product design).

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `challenge_id` | uuid | NOT NULL | — | FK → challenges.id ON DELETE CASCADE | Parent challenge |
| `user_id` | uuid | NOT NULL | — | FK → profiles.id | Participating member |
| `joined_at` | timestamptz | NOT NULL | `now()` | — | Timestamp when the member joined the challenge |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `challenge_id` → `challenges.id` ON DELETE CASCADE
  - `user_id` → `profiles.id`
- **Unique Constraints:** `UNIQUE(challenge_id, user_id)` — a member may join a given challenge only once
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_participants_challenge` | `(challenge_id)` | B-tree | — | Participant list per challenge |
| `idx_participants_user` | `(user_id)` | B-tree | — | Member's joined challenges |

---

### progress_logs

- **Domain:** Growth
- **Purpose:** Stores daily progress entries from challenge participants. One entry is allowed per member per day per challenge; re-submitting on the same day is an upsert that overwrites the existing entry.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `challenge_id` | uuid | NOT NULL | — | FK → challenges.id ON DELETE CASCADE | Parent challenge |
| `user_id` | uuid | NOT NULL | — | FK → profiles.id | Member logging progress |
| `challenge_participant_id` | uuid | NOT NULL | — | FK → challenge_participants.id ON DELETE CASCADE | Participant row; enables direct query from log to participant record without an extra join |
| `log_date` | date | NOT NULL | — | — | Date of the progress entry |
| `value` | numeric(12,2) | NOT NULL | — | CHECK (`value >= 0`) | Numeric progress value; interpreted as steps, km, minutes, or custom count depending on the challenge's `goal_type` |
| `note` | text | NULL | — | — | Optional context note from the member |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | Updated on upsert when a member re-logs on the same date |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `challenge_id` → `challenges.id` ON DELETE CASCADE
  - `user_id` → `profiles.id`
  - `challenge_participant_id` → `challenge_participants.id` ON DELETE CASCADE
- **Unique Constraints:** `UNIQUE(challenge_id, user_id, log_date)` — one log per member per day per challenge
- **Check Constraints:**
  - `value` must be 0 or greater
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_progress_leaderboard` | `(challenge_id, user_id)` | B-tree | — | Supports `SUM(value) GROUP BY user_id` aggregation for leaderboard queries |

---

## Layer 5: Recognition

The Recognition layer manages peer-to-peer recognition posts (shout-outs). A single recognition can acknowledge multiple recipients. Reactions on recognitions follow the same one-per-user upsert pattern as post reactions.

### recognitions

- **Domain:** Recognition
- **Purpose:** Stores peer shout-out posts. A single recognition carries a category tag and message and may name multiple recipients (stored in `recognition_recipients`).

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `giver_id` | uuid | NOT NULL | — | FK → profiles.id | Member giving the recognition |
| `category_tag` | text | NOT NULL | — | CHECK IN (`'community_contributor'`, `'fitness_champion'`, `'wellness_champion'`, `'event_champion'`, `'most_supportive_manager'`) | Recognition category |
| `message` | text | NOT NULL | — | max 500 chars (app-enforced) | Recognition message text |
| `is_deleted` | boolean | NOT NULL | `false` | — | Soft delete flag |
| `deleted_by` | uuid | NULL | — | FK → profiles.id | Giver or admin who performed the soft delete |
| `deleted_at` | timestamptz | NULL | — | — | Timestamp of soft deletion |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `giver_id` → `profiles.id`
  - `deleted_by` → `profiles.id`
- **Unique Constraints:** None
- **Check Constraints:**
  - `category_tag` must be one of `'community_contributor'`, `'fitness_champion'`, `'wellness_champion'`, `'event_champion'`, `'most_supportive_manager'`
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_recognitions_feed` | `(created_at DESC)` | B-tree | `WHERE is_deleted = false` | Recognition wall ordering; partial index excludes soft-deleted rows |
| `idx_recognitions_giver` | `(giver_id)` | B-tree | — | Recognitions given by a specific member |

---

### recognition_recipients

- **Domain:** Recognition
- **Purpose:** Stores the recipients of a recognition. Each recognition may name one or more members; this table holds one row per recipient per recognition.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `recognition_id` | uuid | NOT NULL | — | FK → recognitions.id ON DELETE CASCADE | Parent recognition |
| `recipient_id` | uuid | NOT NULL | — | FK → profiles.id | Member being recognized |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `recognition_id` → `recognitions.id` ON DELETE CASCADE
  - `recipient_id` → `profiles.id`
- **Unique Constraints:** `UNIQUE(recognition_id, recipient_id)` — a member can appear as a recipient only once per recognition
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_recipients_recognition` | `(recognition_id)` | B-tree | — | All recipients of a specific recognition |
| `idx_recipients_user` | `(recipient_id)` | B-tree | — | Recognitions received by a member (used for profile display and analytics) |

---

### recognition_reactions

- **Domain:** Recognition
- **Purpose:** Stores emoji reactions on recognitions. One reaction per user per recognition; changing the emoji is an upsert.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `recognition_id` | uuid | NOT NULL | — | FK → recognitions.id ON DELETE CASCADE | Parent recognition |
| `user_id` | uuid | NOT NULL | — | FK → profiles.id | Reacting member |
| `emoji` | text | NOT NULL | — | — | Single emoji character; supported set is enforced application-side |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | Updated when the user changes their emoji on re-react |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `recognition_id` → `recognitions.id` ON DELETE CASCADE
  - `user_id` → `profiles.id`
- **Unique Constraints:** `UNIQUE(recognition_id, user_id)` — one reaction per user per recognition
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_recog_reactions_recognition` | `(recognition_id)` | B-tree | — | Reaction count and summary per recognition |

---

## Layer 6: Analytics

The Analytics layer stores pre-computed engagement statistics. Both tables are written exclusively by the `compute-monthly-stats` Edge Function and are read-only from the application's perspective. Pre-computation prevents expensive real-time aggregation queries on the main data tables.

### member_monthly_stats

- **Domain:** Analytics
- **Purpose:** Stores computed monthly engagement metrics per member. Rows are inserted or upserted on the 1st of each month by the `compute-monthly-stats` Edge Function.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `user_id` | uuid | NOT NULL | — | FK → profiles.id | Member these statistics belong to |
| `stat_month` | date | NOT NULL | — | — | Always the 1st of the month (e.g., `2026-06-01`); used as the partition key |
| `events_attended` | integer | NOT NULL | `0` | CHECK (`>= 0`) | Count of events with `status = 'attended'` in `event_attendance` for this member within the month |
| `attendance_rate` | numeric(5,2) | NOT NULL | `0.00` | CHECK (`>= 0 AND <= 100`) | Percentage of RSVPed events (status `'going'`) that the member attended |
| `challenges_joined` | integer | NOT NULL | `0` | CHECK (`>= 0`) | Count of `challenge_participants` rows created within the month |
| `progress_logs_count` | integer | NOT NULL | `0` | CHECK (`>= 0`) | Count of `progress_logs` entries created within the month |
| `recognitions_received` | integer | NOT NULL | `0` | CHECK (`>= 0`) | Count of `recognition_recipients` rows for this member within the month |
| `recognitions_given` | integer | NOT NULL | `0` | CHECK (`>= 0`) | Count of `recognitions` rows where `giver_id` is this member within the month |
| `posts_count` | integer | NOT NULL | `0` | CHECK (`>= 0`) | Count of non-deleted posts authored within the month |
| `composite_score` | numeric(6,2) | NOT NULL | `0.00` | CHECK (`>= 0`) | Weighted engagement score used for monthly rankings; formula defined in Edge Function |
| `computed_at` | timestamptz | NOT NULL | `now()` | — | Timestamp of when this row was last computed or updated |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `user_id` → `profiles.id`
- **Unique Constraints:** `UNIQUE(user_id, stat_month)` — one stat row per member per month; supports safe upsert
- **Check Constraints:**
  - `events_attended`, `challenges_joined`, `progress_logs_count`, `recognitions_received`, `recognitions_given`, `posts_count` must all be 0 or greater
  - `attendance_rate` must be between 0.00 and 100.00 inclusive
  - `composite_score` must be 0 or greater
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_monthly_stats_user` | `(user_id, stat_month DESC)` | B-tree | — | Per-member stats history with most recent first |
| `idx_monthly_stats_month` | `(stat_month, composite_score DESC)` | B-tree | — | Monthly rankings query (leaderboard for a given month) |

---

### community_health_scores

- **Domain:** Analytics
- **Purpose:** Stores a monthly community-wide health score computed from aggregate member engagement data. One row per month; written only by the `compute-monthly-stats` Edge Function.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `score_month` | date | NOT NULL | — | — | Always the 1st of the month |
| `score` | numeric(5,2) | NOT NULL | — | CHECK (`>= 0 AND <= 100`) | Composite community health score on a 0–100 scale |
| `active_member_count` | integer | NOT NULL | `0` | CHECK (`>= 0`) | Count of members who performed at least one tracked action in the month |
| `avg_attendance_rate` | numeric(5,2) | NOT NULL | `0.00` | CHECK (`>= 0 AND <= 100`) | Average attendance rate across all active members for the month |
| `challenge_engagement_rate` | numeric(5,2) | NOT NULL | `0.00` | CHECK (`>= 0 AND <= 100`) | Percentage of active members who participated in at least one challenge |
| `recognition_activity_rate` | numeric(5,2) | NOT NULL | `0.00` | CHECK (`>= 0 AND <= 100`) | Percentage of active members who gave or received at least one recognition |
| `participation_rate` | numeric(5,2) | NOT NULL | `0.00` | CHECK (`>= 0 AND <= 100`) | Percentage of active members who attended at least one event |
| `computed_at` | timestamptz | NOT NULL | `now()` | — | Timestamp of when this row was last computed |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |

- **Primary Key:** `id`
- **Foreign Keys:** None
- **Unique Constraints:** `UNIQUE(score_month)` — one health score row per month; supports safe upsert
- **Check Constraints:**
  - `score` must be between 0.00 and 100.00 inclusive
  - All rate columns (`avg_attendance_rate`, `challenge_engagement_rate`, `recognition_activity_rate`, `participation_rate`) must be between 0.00 and 100.00 inclusive
  - `active_member_count` must be 0 or greater
- **Indexes:** The `UNIQUE(score_month)` constraint covers the primary query pattern (fetch score for a given month). No additional indexes are required.

---

## Layer 7: Notifications

### notification_inbox

- **Domain:** Notifications
- **Purpose:** Stores persisted in-app notification records for each recipient. Written exclusively by the `send-notification` Edge Function. Members read their own inbox and mark notifications as read; no member may write or delete rows directly.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `recipient_id` | uuid | NOT NULL | — | FK → profiles.id ON DELETE CASCADE | Notification recipient; rows are deleted if the profile is hard-deleted |
| `actor_id` | uuid | NULL | — | FK → profiles.id ON DELETE SET NULL | Member who triggered the notification (e.g., the commenter, giver); NULL for system-generated notifications |
| `type` | text | NOT NULL | — | CHECK IN 15 values (see below) | Notification type identifier; drives deep-link routing in the Flutter app |
| `title` | text | NOT NULL | — | — | Push notification title text |
| `body` | text | NOT NULL | — | — | Push notification body text |
| `reference_type` | text | NULL | — | CHECK IN (`'activity'`, `'challenge'`, `'recognition'`, `'poll'`, `'post'`, `'user'`) or NULL | Type of the linked resource; used for deep-link routing |
| `reference_id` | uuid | NULL | — | — | ID of the linked resource; combined with `reference_type` to construct a deep link |
| `is_read` | boolean | NOT NULL | `false` | — | Unread state; flipped to `true` when the user views the notification |
| `read_at` | timestamptz | NULL | — | — | Timestamp when `is_read` was set to `true` |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |

**Allowed `type` values:**

| Value | Trigger |
|-------|---------|
| `activity_created` | New event posted |
| `activity_reminder_24h` | 24-hour reminder for an RSVPed event |
| `activity_reminder_1h` | 1-hour reminder for an RSVPed event |
| `activity_cancelled` | An event was cancelled |
| `activity_updated` | Organizer posted an event update |
| `poll_reminder` | Poll closing soon |
| `recognition_received` | Member received a peer recognition |
| `challenge_created` | New challenge posted |
| `challenge_ending` | Active challenge closing soon |
| `challenge_ended` | A challenge has ended |
| `mention` | Member was @mentioned in a post |
| `comment_on_post` | Someone commented on the member's post |
| `connect_buddy_update` | Connect Buddy system message |
| `admin_flag` | Admin action on flagged content (admin-only recipient) |
| `admin_member_registered` | New member registered (admin-only recipient) |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `recipient_id` → `profiles.id` ON DELETE CASCADE
  - `actor_id` → `profiles.id` ON DELETE SET NULL
- **Unique Constraints:** None
- **Check Constraints:**
  - `type` must be one of the 15 values listed above
  - `reference_type` must be one of `'activity'`, `'challenge'`, `'recognition'`, `'poll'`, `'post'`, `'user'`, or NULL
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_notifications_recipient` | `(recipient_id, created_at DESC)` | B-tree | — | Inbox feed for a user in reverse chronological order |
| `idx_notifications_unread` | `(recipient_id)` | B-tree | `WHERE is_read = false` | Unread notification badge count; partial index covers only unread rows |

---

## Layer 8: Admin

The Admin layer provides moderation tools, pinned announcement management, and an immutable audit trail. All three tables are heavily restricted by RLS; members have no write access to any of them.

### flagged_content

- **Domain:** Admin
- **Purpose:** Stores member-submitted content flags for admin moderation. Admins review flags and mark them as resolved (either by deleting the content or dismissing the flag).

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `reporter_id` | uuid | NOT NULL | — | FK → profiles.id | Member who submitted the flag |
| `content_type` | text | NOT NULL | — | CHECK IN (`'post'`, `'comment'`) | Identifies which table `content_id` references |
| `content_id` | uuid | NOT NULL | — | No FK (polymorphic) | References `posts.id` or `comments.id` depending on `content_type`; no database FK due to polymorphic pattern |
| `reason` | text | NULL | — | — | Optional reason text provided by the flagger |
| `status` | text | NOT NULL | `'pending'` | CHECK IN (`'pending'`, `'resolved_deleted'`, `'resolved_dismissed'`) | Moderation outcome |
| `resolved_by` | uuid | NULL | — | FK → profiles.id | Admin who resolved the flag |
| `resolved_at` | timestamptz | NULL | — | — | Timestamp of resolution |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

**Note on polymorphic reference:** `content_id` uses a polymorphic pattern and intentionally omits a database-level foreign key constraint, because it must reference either `posts.id` or `comments.id` depending on `content_type`. Referential integrity is maintained by application-level validation in the Edge Function and by RLS policies that restrict `SELECT` on `flagged_content` to admin roles only.

- **Primary Key:** `id`
- **Foreign Keys:**
  - `reporter_id` → `profiles.id`
  - `resolved_by` → `profiles.id`
- **Unique Constraints:** None
- **Check Constraints:**
  - `content_type` must be one of `'post'`, `'comment'`
  - `status` must be one of `'pending'`, `'resolved_deleted'`, `'resolved_dismissed'`
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_flags_status` | `(status)` | B-tree | `WHERE status = 'pending'` | Admin pending moderation queue; partial index covers only unresolved flags |

---

### pinned_announcements

- **Domain:** Admin
- **Purpose:** Tracks which feed post is currently pinned to the top of the community Feed. Only one pin may be active at any time; pinning a new post deactivates the previous pin (enforced by the pin-post Edge Function).

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `post_id` | uuid | NOT NULL | — | FK → posts.id ON DELETE CASCADE | The post being pinned; row is removed if the underlying post is hard-deleted |
| `pinned_by` | uuid | NOT NULL | — | FK → profiles.id | Admin who created the pin |
| `is_active` | boolean | NOT NULL | `true` | — | `false` means the post has been unpinned; at most one row may have `is_active = true` at any time |
| `created_at` | timestamptz | NOT NULL | `now()` | — | — |
| `updated_at` | timestamptz | NOT NULL | `now()` | auto-trigger | — |

- **Primary Key:** `id`
- **Foreign Keys:**
  - `post_id` → `posts.id` ON DELETE CASCADE
  - `pinned_by` → `profiles.id`
- **Unique Constraints:** None (single-active-pin invariant is maintained by the pin-post Edge Function, which deactivates any existing active pin before creating the new one)
- **Check Constraints:** None
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_pinned_active` | `(is_active)` | B-tree | `WHERE is_active = true` | Feed query for the active pin; partial index guarantees at most one matching row is scanned |

---

### admin_audit_log

- **Domain:** Admin
- **Purpose:** Provides an immutable chronological record of all admin actions. Rows are written exclusively by Edge Functions and may not be modified or deleted by any role. There is no `updated_at` column by design.

**Columns**

| Column | PostgreSQL Type | Nullable | Default | Constraints | Description |
|--------|----------------|----------|---------|-------------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | PK | — |
| `admin_id` | uuid | NOT NULL | — | FK → profiles.id | Admin who performed the action |
| `action_type` | text | NOT NULL | — | CHECK IN 13 values (see below) | Describes what admin action was taken |
| `target_type` | text | NULL | — | CHECK IN 8 values (see below) or NULL | The type of entity that was acted upon |
| `target_id` | uuid | NULL | — | — | ID of the target entity; no FK constraint due to multi-table polymorphism |
| `metadata` | jsonb | NULL | — | — | Additional context for the action (e.g., `{"record_count": 12}` for a batch attendance submission) |
| `performed_at` | timestamptz | NOT NULL | `now()` | — | Timestamp of the action; used as the primary ordering column |

**Allowed `action_type` values:**

| Value | Meaning |
|-------|---------|
| `user_invited` | Admin sent an invitation |
| `user_deactivated` | Admin deactivated a member account |
| `user_reactivated` | Admin reactivated a member account |
| `user_removed` | Admin permanently removed a member |
| `invitation_revoked` | Admin revoked a pending invitation |
| `post_deleted` | Admin soft-deleted a post |
| `comment_deleted` | Admin soft-deleted a comment |
| `flag_resolved_deleted` | Admin resolved a flag by deleting the content |
| `flag_resolved_dismissed` | Admin resolved a flag by dismissing it |
| `content_pinned` | Admin pinned a post to the Feed |
| `content_unpinned` | Admin unpinned the active pin |
| `attendance_recorded` | Admin submitted attendance for an event |
| `poll_closed` | Admin manually closed a poll |

**Allowed `target_type` values:** `'user'`, `'post'`, `'comment'`, `'flag'`, `'announcement'`, `'attendance'`, `'poll'`, `'invitation'`

- **Primary Key:** `id`
- **Foreign Keys:**
  - `admin_id` → `profiles.id`
- **Unique Constraints:** None
- **Check Constraints:**
  - `action_type` must be one of the 13 values listed above
  - `target_type` must be one of the 8 values listed above, or NULL
- **Indexes:**

| Index Name | Columns | Type | Partial Condition | Purpose |
|------------|---------|------|-------------------|---------|
| `idx_audit_admin` | `(admin_id, performed_at DESC)` | B-tree | — | Per-admin action history in reverse chronological order |
| `idx_audit_performed` | `(performed_at DESC)` | B-tree | — | Full chronological audit log view |

---

## Trigger Specification

### update_updated_at_column()

A single reusable trigger function drives `updated_at` management across all mutable tables, eliminating the need for duplicate trigger definitions.

- **Behavior:** Sets `NEW.updated_at = now()` before each `UPDATE` operation on the table.
- **Applied to (16 of 26 tables):** `profiles`, `invitations`, `posts`, `post_reactions`, `comments`, `activities`, `activity_rsvps`, `polls`, `event_attendance`, `challenges`, `progress_logs`, `recognitions`, `recognition_reactions`, `member_monthly_stats`, `flagged_content`, `pinned_announcements`

**Tables without `updated_at`** — these are either immutable (audit log) or append-only (no row is ever updated after insert):

| Table | Reason |
|-------|--------|
| `post_images` | Append-only; images are not edited after upload |
| `post_mentions` | Append-only; mention relationships do not change |
| `activity_updates` | Append-only; updates are not edited |
| `poll_options` | Append-only; options are set at poll creation |
| `poll_votes` | Append-only; votes cannot be changed after submission |
| `challenge_participants` | Append-only; members do not leave challenges |
| `recognition_recipients` | Append-only; recipients do not change |
| `notification_inbox` | Append-only for content; `is_read`/`read_at` are the only mutable fields, tracked via dedicated columns — no `updated_at` column |
| `community_health_scores` | No updates needed; rows are upserted by primary key |
| `admin_audit_log` | Immutable by design; no UPDATE permitted by any role |

### is_active_user()

A helper function used as the base guard in every RLS policy on every table. Created to prevent infinite RLS recursion — without `SECURITY DEFINER`, an inline `EXISTS (SELECT FROM profiles WHERE is_active)` check inside a `profiles` SELECT policy would trigger the same policy recursively.

- **Returns:** `boolean`
- **Logic:** Returns `true` if `auth.uid()` resolves to a `profiles` row where `is_active = true`. Returns `false` if no profile exists or the profile is deactivated.
- **Security:** Defined with `SECURITY DEFINER` so it bypasses RLS on the `profiles` table during policy evaluation.
- **Used in:** Every RLS policy on every table, as the `[active-user-guard]` condition.

### is_admin()

A helper function used across RLS policies to determine whether the calling user holds an active admin role.

- **Returns:** `boolean`
- **Logic:** Returns `true` if `auth.uid()` resolves to a `profiles` row where `app_role = 'admin'` AND `is_active = true`
- **Security:** Defined with `SECURITY DEFINER` so it bypasses RLS on the `profiles` table during policy evaluation.
- **Used in:** RLS policies across all tables requiring admin-elevated read or write access

---

## Constraint Summary

| Table | UNIQUE Constraints | CHECK Constraints |
|-------|-------------------|------------------|
| `profiles` | `id` (PK) | `app_role IN ('member','admin','system')` |
| `invitations` | `token_hash` | `status IN ('pending','accepted','expired','revoked')` |
| `posts` | — | — |
| `post_images` | — | `display_order BETWEEN 0 AND 3` |
| `post_reactions` | `(post_id, user_id)` | — |
| `comments` | — | — |
| `post_mentions` | `(post_id, mentioned_user_id)` | — |
| `activities` | — | `event_category IN ('games','outings','social_connect')`; `event_type IN (...)` or NULL; `status IN ('active','cancelled')` |
| `activity_rsvps` | `(activity_id, user_id)` | `status IN ('going','not_going','maybe')` |
| `activity_updates` | — | — |
| `polls` | — | — |
| `poll_options` | — | `display_order >= 0` |
| `poll_votes` | `(poll_id, user_id)` | — |
| `event_attendance` | `(activity_id, user_id)` | `status IN ('attended','absent')` |
| `challenges` | — | `challenge_type IN ('fitness','wellness')`; `goal_type IN ('steps','distance','duration','custom')`; `end_date > start_date`; `status IN ('active','ended')` |
| `challenge_participants` | `(challenge_id, user_id)` | — |
| `progress_logs` | `(challenge_id, user_id, log_date)` | `value >= 0` |
| `recognitions` | — | `category_tag IN ('community_contributor','fitness_champion','wellness_champion','event_champion','most_supportive_manager')` |
| `recognition_recipients` | `(recognition_id, recipient_id)` | — |
| `recognition_reactions` | `(recognition_id, user_id)` | — |
| `member_monthly_stats` | `(user_id, stat_month)` | All count columns `>= 0`; rate columns `BETWEEN 0 AND 100` |
| `community_health_scores` | `(score_month)` | `score BETWEEN 0 AND 100`; all rate columns `BETWEEN 0 AND 100` |
| `notification_inbox` | — | `type IN (15 values)`; `reference_type IN (6 values)` or NULL |
| `flagged_content` | — | `content_type IN ('post','comment')`; `status IN ('pending','resolved_deleted','resolved_dismissed')` |
| `pinned_announcements` | — | — |
| `admin_audit_log` | — | `action_type IN (13 values)`; `target_type IN (8 values)` or NULL |

---

## Storage Buckets

Two Supabase Storage buckets are part of the database design. Storage paths are recorded in the database as plain text references (`avatar_url` in `profiles`, `storage_path` in `post_images`). Full public or signed URLs are generated at query time by the application and are never persisted.

| Bucket | Path Convention | Access Policy |
|--------|----------------|---------------|
| `avatars` | `avatars/{user_id}/profile.jpg` | Public read (CDN delivery); authenticated write restricted to the profile owner |
| `post-images` | `post-images/{user_id}/{uuid}.jpg` | Authenticated read (active members only); authenticated write restricted to the post author |

When a member account is permanently removed, their avatar file is deleted from the `avatars` bucket as part of the PII anonymization process. Post images are not deleted on member removal; the post content is soft-deleted and the `full_name` is anonymized to `'Removed Member'`.
