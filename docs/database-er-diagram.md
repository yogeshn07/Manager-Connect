# Database ER Diagrams

## Overview

This document contains Entity-Relationship diagrams for Manager Connect's database. Diagrams are organized by domain for readability. All diagrams use Mermaid ERD notation.

**Reading the diagrams:**
- `||--||` one-to-one (exactly one on each side)
- `||--o{` one-to-many (exactly one on left, zero or more on right)
- `||--|{` one-to-many (exactly one on left, one or more on right)
- `}o--o{` many-to-many (via junction table)

---

## Diagram 1: Identity and Authentication

The foundation layer. Every other domain references `profiles`.

```mermaid
erDiagram
    AUTH_USERS {
        uuid id PK
        text email
        text phone
        timestamptz created_at
        timestamptz last_sign_in_at
    }

    PROFILES {
        uuid id PK
        uuid auth_user_id FK
        text full_name
        text avatar_url
        text title
        text bio
        text_array interest_tags
        text app_role
        text push_token
        jsonb notification_preferences
        boolean is_active
        boolean is_system_account
        boolean onboarding_completed
        timestamptz last_active_at
        timestamptz created_at
        timestamptz updated_at
    }

    INVITATIONS {
        uuid id PK
        text token_hash
        text invitee_name
        text invitee_email
        text invitee_phone
        uuid invited_by FK
        text status
        uuid accepted_by FK
        timestamptz created_at
        timestamptz expires_at
        timestamptz accepted_at
    }

    AUTH_USERS ||--|| PROFILES : "1 auth user → 1 profile"
    PROFILES ||--o{ INVITATIONS : "admin sends invites"
    PROFILES |o--o{ INVITATIONS : "accepted_by (optional)"
```

---

## Diagram 2: Community Feed

Posts, images, reactions, comments, and mentions. Connect Buddy posts are authored by the system profile and appear in the same `posts` table.

```mermaid
erDiagram
    PROFILES {
        uuid id PK
        text full_name
        text app_role
        boolean is_system_account
    }

    POSTS {
        uuid id PK
        uuid author_id FK
        text content
        boolean is_deleted
        timestamptz deleted_at
        uuid deleted_by FK
        timestamptz created_at
        timestamptz updated_at
    }

    POST_IMAGES {
        uuid id PK
        uuid post_id FK
        text storage_path
        smallint display_order
        timestamptz created_at
    }

    POST_REACTIONS {
        uuid id PK
        uuid post_id FK
        uuid user_id FK
        text emoji
        timestamptz created_at
    }

    COMMENTS {
        uuid id PK
        uuid post_id FK
        uuid author_id FK
        text content
        boolean is_deleted
        timestamptz deleted_at
        uuid deleted_by FK
        timestamptz created_at
        timestamptz updated_at
    }

    POST_MENTIONS {
        uuid id PK
        uuid post_id FK
        uuid mentioned_user_id FK
        timestamptz created_at
    }

    PINNED_ANNOUNCEMENTS {
        uuid id PK
        uuid post_id FK
        uuid pinned_by FK
        boolean is_active
        timestamptz pinned_at
        timestamptz unpinned_at
    }

    PROFILES ||--o{ POSTS : "author_id (member or Connect Buddy)"
    POSTS ||--o{ POST_IMAGES : "post_id"
    POSTS ||--o{ POST_REACTIONS : "post_id"
    POSTS ||--o{ COMMENTS : "post_id"
    POSTS ||--o{ POST_MENTIONS : "post_id"
    POSTS |o--o{ PINNED_ANNOUNCEMENTS : "post_id (max 1 active)"
    PROFILES ||--o{ POST_REACTIONS : "user_id"
    PROFILES ||--o{ COMMENTS : "author_id"
    PROFILES ||--o{ POST_MENTIONS : "mentioned_user_id"
    PROFILES ||--o{ PINNED_ANNOUNCEMENTS : "pinned_by (admin)"
```

---

## Diagram 3: Growth Challenges

Challenge lifecycle, participation, and progress tracking.

```mermaid
erDiagram
    PROFILES {
        uuid id PK
        text full_name
    }

    CHALLENGES {
        uuid id PK
        uuid created_by FK
        text title
        text description
        text challenge_type
        text goal_type
        text goal_description
        date start_date
        date end_date
        text status
        timestamptz ended_at
        timestamptz created_at
        timestamptz updated_at
    }

    CHALLENGE_PARTICIPANTS {
        uuid id PK
        uuid challenge_id FK
        uuid user_id FK
        timestamptz joined_at
    }

    PROGRESS_LOGS {
        uuid id PK
        uuid challenge_id FK
        uuid user_id FK
        date log_date
        numeric value
        text note
        timestamptz logged_at
    }

    PROFILES ||--o{ CHALLENGES : "created_by"
    CHALLENGES ||--o{ CHALLENGE_PARTICIPANTS : "challenge_id"
    CHALLENGES ||--o{ PROGRESS_LOGS : "challenge_id"
    PROFILES ||--o{ CHALLENGE_PARTICIPANTS : "user_id"
    PROFILES ||--o{ PROGRESS_LOGS : "user_id"
```

---

## Diagram 4: Recognition Wall

Peer shout-outs with multiple recipients and reactions. Recognition tables form their own domain layer (Layer 5: Recognition).

```mermaid
erDiagram
    PROFILES {
        uuid id PK
        text full_name
    }

    RECOGNITIONS {
        uuid id PK
        uuid giver_id FK
        text category_tag
        text message
        boolean is_deleted
        timestamptz deleted_at
        uuid deleted_by FK
        timestamptz created_at
    }

    RECOGNITION_RECIPIENTS {
        uuid id PK
        uuid recognition_id FK
        uuid recipient_id FK
    }

    RECOGNITION_REACTIONS {
        uuid id PK
        uuid recognition_id FK
        uuid user_id FK
        text emoji
        timestamptz created_at
    }

    PROFILES ||--o{ RECOGNITIONS : "giver_id"
    RECOGNITIONS ||--|{ RECOGNITION_RECIPIENTS : "recognition_id (1 or more)"
    RECOGNITIONS ||--o{ RECOGNITION_REACTIONS : "recognition_id"
    PROFILES ||--o{ RECOGNITION_RECIPIENTS : "recipient_id"
    PROFILES ||--o{ RECOGNITION_REACTIONS : "user_id"
```

---

## Diagram 5: Events — Activities, Polls, and Attendance

Games, outings, social connect events — with RSVP, organizer updates, community polls, and post-event attendance recording.

```mermaid
erDiagram
    PROFILES {
        uuid id PK
        text full_name
        text app_role
    }

    ACTIVITIES {
        uuid id PK
        uuid created_by FK
        text title
        text description
        timestamptz event_date
        text location
        text cost_note
        text event_category
        text event_type
        text status
        timestamptz cancelled_at
        timestamptz created_at
        timestamptz updated_at
    }

    ACTIVITY_RSVPS {
        uuid id PK
        uuid activity_id FK
        uuid user_id FK
        text status
        timestamptz responded_at
    }

    ACTIVITY_UPDATES {
        uuid id PK
        uuid activity_id FK
        uuid author_id FK
        text content
        timestamptz created_at
    }

    POLLS {
        uuid id PK
        uuid activity_id FK
        uuid created_by FK
        text question
        timestamptz closes_at
        boolean is_closed
        timestamptz closed_at
        timestamptz created_at
        timestamptz updated_at
    }

    POLL_OPTIONS {
        uuid id PK
        uuid poll_id FK
        text option_text
        smallint display_order
    }

    POLL_VOTES {
        uuid id PK
        uuid poll_id FK
        uuid option_id FK
        uuid user_id FK
        timestamptz voted_at
    }

    EVENT_ATTENDANCE {
        uuid id PK
        uuid activity_id FK
        uuid user_id FK
        text status
        uuid recorded_by FK
        timestamptz recorded_at
    }

    PROFILES ||--o{ ACTIVITIES : "created_by"
    ACTIVITIES ||--o{ ACTIVITY_RSVPS : "activity_id"
    ACTIVITIES ||--o{ ACTIVITY_UPDATES : "activity_id"
    ACTIVITIES |o--o{ POLLS : "activity_id (optional)"
    ACTIVITIES ||--o{ EVENT_ATTENDANCE : "activity_id"
    PROFILES ||--o{ ACTIVITY_RSVPS : "user_id"
    PROFILES ||--o{ ACTIVITY_UPDATES : "author_id (creator only)"
    PROFILES ||--o{ POLLS : "created_by"
    POLLS ||--|{ POLL_OPTIONS : "poll_id (2+ options)"
    POLLS ||--o{ POLL_VOTES : "poll_id"
    POLL_OPTIONS ||--o{ POLL_VOTES : "option_id"
    PROFILES ||--o{ POLL_VOTES : "user_id"
    PROFILES ||--o{ EVENT_ATTENDANCE : "user_id"
    PROFILES |o--o{ EVENT_ATTENDANCE : "recorded_by (admin)"
```

---

## Diagram 6: Analytics — Monthly Stats and Health Scores

Pre-computed monthly member stats and community health scores that power the Analytics module. Recognition data that feeds into analytics is defined in Diagram 4 (Recognition domain).

```mermaid
erDiagram
    PROFILES {
        uuid id PK
        text full_name
        text app_role
    }

    RECOGNITIONS {
        uuid id PK
        uuid giver_id FK
        text category_tag
        text message
        boolean is_deleted
        timestamptz created_at
    }

    RECOGNITION_RECIPIENTS {
        uuid id PK
        uuid recognition_id FK
        uuid recipient_id FK
    }

    MEMBER_MONTHLY_STATS {
        uuid id PK
        uuid user_id FK
        date stat_month
        int events_attended
        int challenges_joined
        int progress_logs_count
        int recognitions_received
        int recognitions_given
        int posts_count
        timestamptz computed_at
    }

    COMMUNITY_HEALTH_SCORES {
        uuid id PK
        date score_month
        numeric score
        int active_member_count
        numeric avg_attendance_rate
        numeric challenge_engagement_rate
        numeric recognition_activity_rate
        numeric participation_rate
        timestamptz computed_at
        timestamptz created_at
    }

    PROFILES ||--o{ RECOGNITIONS : "giver_id"
    RECOGNITIONS ||--|{ RECOGNITION_RECIPIENTS : "recognition_id"
    PROFILES ||--o{ RECOGNITION_RECIPIENTS : "recipient_id"
    PROFILES ||--o{ MEMBER_MONTHLY_STATS : "user_id"
```

---

## Diagram 7: Notifications

In-app notification inbox fed by server-side dispatch.

```mermaid
erDiagram
    PROFILES {
        uuid id PK
        text full_name
        text push_token
        jsonb notification_preferences
    }

    NOTIFICATION_INBOX {
        uuid id PK
        uuid recipient_id FK
        uuid actor_id FK
        text type
        text title
        text body
        text reference_type
        uuid reference_id
        boolean is_read
        timestamptz read_at
        timestamptz created_at
    }

    PROFILES ||--o{ NOTIFICATION_INBOX : "recipient_id"
    PROFILES |o--o{ NOTIFICATION_INBOX : "actor_id (nullable)"
```

---

## Diagram 8: Admin and Moderation

Flags, pinned posts, invitations, and the audit log.

```mermaid
erDiagram
    PROFILES {
        uuid id PK
        text full_name
        text app_role
        boolean is_active
    }

    FLAGGED_CONTENT {
        uuid id PK
        text content_type
        uuid content_id
        uuid reporter_id FK
        text reason
        text status
        uuid resolved_by FK
        timestamptz resolved_at
        timestamptz created_at
        timestamptz updated_at
    }

    PINNED_ANNOUNCEMENTS {
        uuid id PK
        uuid post_id FK
        uuid pinned_by FK
        boolean is_active
        timestamptz pinned_at
        timestamptz unpinned_at
    }

    ADMIN_AUDIT_LOG {
        uuid id PK
        uuid admin_id FK
        text action_type
        text target_type
        uuid target_id
        jsonb metadata
        timestamptz performed_at
    }

    INVITATIONS {
        uuid id PK
        text token_hash
        text invitee_name
        text invitee_email
        text invitee_phone
        uuid invited_by FK
        text status
        timestamptz expires_at
        timestamptz accepted_at
    }

    PROFILES ||--o{ FLAGGED_CONTENT : "reporter_id"
    PROFILES |o--o{ FLAGGED_CONTENT : "resolved_by (admin)"
    PROFILES ||--o{ PINNED_ANNOUNCEMENTS : "pinned_by (admin)"
    PROFILES ||--o{ ADMIN_AUDIT_LOG : "admin_id"
    PROFILES ||--o{ INVITATIONS : "invited_by (admin)"
```

---

## Diagram 9: Complete System Overview

Simplified overview showing all entities and their cross-domain relationships. Column details omitted for readability.

```mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : "identity"

    PROFILES ||--o{ INVITATIONS : "sends"
    PROFILES ||--o{ POSTS : "authors"
    PROFILES ||--o{ POST_REACTIONS : "reacts"
    PROFILES ||--o{ COMMENTS : "comments"
    PROFILES ||--o{ ACTIVITIES : "creates"
    PROFILES ||--o{ ACTIVITY_RSVPS : "RSVPs"
    PROFILES ||--o{ POLLS : "creates"
    PROFILES ||--o{ POLL_VOTES : "votes"
    PROFILES ||--o{ EVENT_ATTENDANCE : "recorded for"
    PROFILES ||--o{ CHALLENGES : "creates"
    PROFILES ||--o{ CHALLENGE_PARTICIPANTS : "joins"
    PROFILES ||--o{ PROGRESS_LOGS : "logs"
    PROFILES ||--o{ RECOGNITIONS : "gives"
    PROFILES ||--o{ RECOGNITION_RECIPIENTS : "receives"
    PROFILES ||--o{ RECOGNITION_REACTIONS : "reacts"
    PROFILES ||--o{ MEMBER_MONTHLY_STATS : "has stats"
    PROFILES ||--o{ NOTIFICATION_INBOX : "receives"
    PROFILES ||--o{ FLAGGED_CONTENT : "flags"
    PROFILES ||--o{ PINNED_ANNOUNCEMENTS : "pins"
    PROFILES ||--o{ ADMIN_AUDIT_LOG : "logged for"

    POSTS ||--o{ POST_IMAGES : "has"
    POSTS ||--o{ POST_REACTIONS : "receives"
    POSTS ||--o{ COMMENTS : "has"
    POSTS ||--o{ POST_MENTIONS : "contains"
    POSTS |o--o{ PINNED_ANNOUNCEMENTS : "pinned as"

    ACTIVITIES ||--o{ ACTIVITY_RSVPS : "receives"
    ACTIVITIES ||--o{ ACTIVITY_UPDATES : "has"
    ACTIVITIES |o--o{ POLLS : "optionally has"
    ACTIVITIES ||--o{ EVENT_ATTENDANCE : "records"

    POLLS ||--|{ POLL_OPTIONS : "has"
    POLLS ||--o{ POLL_VOTES : "receives"
    POLL_OPTIONS ||--o{ POLL_VOTES : "selected by"

    CHALLENGES ||--o{ CHALLENGE_PARTICIPANTS : "has"
    CHALLENGES ||--o{ PROGRESS_LOGS : "receives"

    RECOGNITIONS ||--|{ RECOGNITION_RECIPIENTS : "has"
    RECOGNITIONS ||--o{ RECOGNITION_REACTIONS : "receives"
```

---

## Key Design Observations

### Cross-Domain Profile References
`profiles` is the central hub entity. Every domain table that involves a user action references `profiles.id`. The design avoids embedding user data in domain tables — all user display data is fetched via join with `profiles`. The Connect Buddy system account is a row in `profiles` with `is_system_account = true`, making its posts structurally identical to member posts.

### Two-Table Pattern for Multi-Recipients
Recognition uses a junction table (`recognition_recipients`) rather than an array column to store multiple recipients. This enables:
- Standard FK constraints
- Efficient query: "show all recognitions where I am a recipient"
- Clean RLS (filter by `recipient_id`)
- Future extensibility (add received_at, acknowledged, etc.)

### Soft Delete Chain
Content that can be moderated follows a consistent pattern:
`is_deleted (bool)` + `deleted_at (timestamptz)` + `deleted_by (uuid FK → profiles.id)`
This applies to: posts, comments, recognitions. Anonymization (not deletion) applies to user PII in profiles.

### Poll Design: Standalone and Activity-Linked
The `polls` table has a nullable `activity_id` FK. This allows polls to exist independently (community standalone polls) or be tied to a specific event (e.g., "Vote on the next cricket team format"). The `poll_votes` UNIQUE constraint on `(poll_id, user_id)` guarantees one vote per member per poll at the database level.

### Analytics Computation Pattern
`member_monthly_stats` and `community_health_scores` are computed tables — their data is derived from source tables (`event_attendance`, `progress_logs`, `recognitions`, `posts`, `challenge_participants`) by the `compute-monthly-stats` scheduled Edge Function. This avoids expensive aggregate queries at read time for the Analytics screens.

### Leaderboard Query Pattern
The in-challenge leaderboard is computed on query — no denormalized totals are stored. For 20–100 users it is a lightweight `SUM(value) GROUP BY user_id ORDER BY total DESC` on `progress_logs`. All-time rankings across months use `member_monthly_stats` for efficiency. If scale increases further, a materialized view can be added without changing the base schema.

### event_category and event_type Pattern
The `activities` table uses a two-column categorization: `event_category` (high-level: games/outings/social_connect) and `event_type` (specific: cricket/lunch_meetup/etc.). This enables both broad filtering (show all games) and specific filtering (show all cricket events) from a single indexed query without complex joins.
