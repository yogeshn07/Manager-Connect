# Database Strategy

## Database Engine

**PostgreSQL v15+ via Supabase (managed)**

PostgreSQL is the sole database for Manager Connect. Supabase provides managed hosting with automated backups, Realtime event streaming, a PostgREST auto-generated REST API, and native Row-Level Security enforcement. No custom ORM is used.

**Related documents:**
- Entity definitions and column specifications: `database-entity-catalogue.md`
- ER diagrams: `database-er-diagram.md`

---

## Schema Summary

| Layer | Tables | Count |
|-------|--------|-------|
| Auth (Supabase-managed) | `auth.users` | 1 (external) |
| Identity | `profiles`, `invitations` | 2 |
| Feed | `posts`, `post_images`, `post_reactions`, `comments`, `post_mentions` | 5 |
| Events | `activities`, `activity_rsvps`, `activity_updates`, `polls`, `poll_options`, `poll_votes`, `event_attendance` | 7 |
| Growth | `challenges`, `challenge_participants`, `progress_logs` | 3 |
| Recognition | `recognitions`, `recognition_recipients`, `recognition_reactions` | 3 |
| Analytics | `member_monthly_stats`, `community_health_scores` | 2 |
| Notifications | `notification_inbox` | 1 |
| Admin | `flagged_content`, `pinned_announcements`, `admin_audit_log` | 3 |
| **Total application tables** | | **26** |

---

## Design Principles

### 1. UUID Primary Keys Throughout
All tables use `uuid` with `gen_random_uuid()` as the primary key. No sequential integers are exposed to the client. Benefits:
- No enumerable IDs (security: can't iterate user IDs)
- Safe to generate client-side if needed (conflict probability negligible)
- No hot-spot contention in distributed writes

### 2. Profiles as the Central Hub
`profiles` is the identity anchor for the entire schema. Every user-authored row in every domain table references `profiles.id` via FK. Display data (names, avatars) is never duplicated into domain tables — always fetched via join. This means a profile name change propagates everywhere instantly without a data migration.

### 3. Soft Deletes for Moderated Content
Posts, comments, and recognitions use soft deletion (`is_deleted`, `deleted_at`, `deleted_by`) rather than hard DELETE. Reasons:
- Audit trail preserved for moderation review
- FK references remain valid (no cascade damage)
- Hard deletion can run asynchronously on schedule
- RLS policies filter `WHERE is_deleted = false` — soft-deleted content is invisible to queries

### 4. PII Anonymization, Not Content Deletion
When a user is removed (NFR-07.3): their `profiles` row is updated in-place — name becomes "Removed Member", avatar_url/bio/title/interest_tags are nullified. Their content rows (posts, comments, recognitions) remain intact with `author_id` pointing to the anonymized profile. This satisfies:
- Data minimization (PII removed)
- Community continuity (content not wiped)
- FK integrity (no orphaned rows)

### 5. Junction Tables for All M:N Relationships
No PostgreSQL arrays are used for storing FK relationships. Every many-to-many is a proper junction table:
- `challenge_participants` (profiles ↔ challenges)
- `recognition_recipients` (recognitions ↔ profiles)
- `poll_votes` (polls ↔ profiles via poll_options)

Benefits: FK constraints enforced, efficient indexed lookups, RLS can filter at row level, future columns can be added to the junction.

### 6. CHECK Constraints for Status Enums
Status fields use `TEXT` with `CHECK IN (...)` rather than PostgreSQL `ENUM` types. PostgreSQL ENUM types cannot be altered (values added/removed) without a complex migration sequence. TEXT + CHECK allows adding new status values with a simple constraint update.

### 7. JSONB for Flexible Preferences
`notification_preferences` on `profiles` is stored as JSONB. New preference keys can be added without a schema migration — the default value in application code simply includes the new key. PostgreSQL JSONB is indexed, queryable, and well-supported by the Supabase client SDK.

---

## Row-Level Security (RLS) Architecture

RLS is enabled on every table. No table is left without a policy. The principle: access is denied by default and must be explicitly granted by a policy.

### Role Identification
PostgreSQL function `is_admin()` is defined as:
```
auth.uid() IN (SELECT id FROM profiles WHERE app_role = 'admin' AND is_active = true)
```
This function is used in RLS policies across admin-elevated actions.

### RLS Policy Matrix

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `profiles` | All authenticated users | Edge Function only | Own row; admin: is_active, app_role | None |
| `invitations` | Admin only | Edge Function only | Edge Function only | None |
| `posts` | All (is_deleted=false) | Any authenticated | Own post; admin: soft delete fields | None |
| `post_images` | All authenticated | Post author only | None | Post author or admin |
| `post_reactions` | All authenticated | Any authenticated | Own reaction | Own reaction |
| `comments` | All (is_deleted=false) | Any authenticated | Own comment | None |
| `post_mentions` | All authenticated | Edge Function only | None | None |
| `activities` | All authenticated | Admin only | Admin only | None |
| `activity_rsvps` | All authenticated | Own RSVP | Own RSVP | Own RSVP |
| `activity_updates` | All authenticated | Activity creator only | None | None |
| `challenges` | All authenticated | Admin only | Admin only; Edge Fn: status | None |
| `challenge_participants` | All authenticated | Own participation | None | Own participation |
| `progress_logs` | All authenticated | Own if participant | Own entry | Own entry |
| `recognitions` | All (is_deleted=false) | Any authenticated | Own; admin: soft delete | None |
| `recognition_recipients` | All authenticated | Recognition giver | None | None |
| `recognition_reactions` | All authenticated | Any authenticated | Own reaction | Own reaction |
| `polls` | All authenticated | Admin only | Admin only | None |
| `poll_options` | All authenticated | Edge Fn only (with poll creation) | None | None |
| `poll_votes` | All authenticated | Own vote; one per poll (UNIQUE enforced) | None | None |
| `event_attendance` | All authenticated | Admin / Edge Fn only | Admin / Edge Fn only | None |
| `member_monthly_stats` | Own rows; admin: all | Edge Fn only (scheduled) | Edge Fn only | None |
| `community_health_scores` | All authenticated | Edge Fn only (scheduled) | None | None |
| `notification_inbox` | Own rows only | Edge Function only | Own rows (is_read) | None |
| `flagged_content` | Admin only | Any authenticated | Admin only | None |
| `pinned_announcements` | All authenticated | Admin only | Admin only | None |
| `admin_audit_log` | Admin only | Edge Function only | None | None |

---

## Indexing Strategy

Indexes are created on columns used in WHERE clauses, ORDER BY, and JOIN conditions for all list and feed views (NFR-04.2).

### Primary Indexes (Created with Tables)
All PK columns are indexed automatically.

### Secondary Indexes

| Table | Index | Columns | Type | Reason |
|-------|-------|---------|------|--------|
| `posts` | `idx_posts_feed` | `created_at DESC` WHERE `is_deleted = false` | Partial B-tree | Community feed ordering |
| `posts` | `idx_posts_author` | `author_id` | B-tree | Author's post history |
| `comments` | `idx_comments_post` | `post_id, created_at ASC` | B-tree | Comments per post |
| `post_reactions` | `idx_reactions_post` | `post_id` | B-tree | Reaction count per post |
| `post_mentions` | `idx_mentions_user` | `mentioned_user_id` | B-tree | Notification lookup |
| `activities` | `idx_activities_date` | `event_date ASC` WHERE `status = 'active'` | Partial B-tree | Upcoming activities list |
| `activities` | `idx_activities_creator` | `creator_id` | B-tree | Creator's activities |
| `activities` | `idx_activities_category` | `event_category` | B-tree | Filter by games/outings/social_connect |
| `activity_rsvps` | `idx_rsvps_activity` | `activity_id` | B-tree | RSVP list per activity |
| `activity_rsvps` | `idx_rsvps_user` | `user_id` | B-tree | User's RSVP history |
| `challenges` | `idx_challenges_status` | `status, end_date ASC` | B-tree | Active challenges list |
| `challenge_participants` | `idx_participants_challenge` | `challenge_id` | B-tree | Participant list per challenge |
| `challenge_participants` | `idx_participants_user` | `user_id` | B-tree | User's joined challenges |
| `progress_logs` | `idx_progress_leaderboard` | `challenge_id, user_id` | B-tree | Leaderboard SUM aggregation |
| `recognitions` | `idx_recognitions_feed` | `created_at DESC` WHERE `is_deleted = false` | Partial B-tree | Recognition wall ordering |
| `recognition_recipients` | `idx_recipients_recognition` | `recognition_id` | B-tree | Recipients of a recognition |
| `recognition_recipients` | `idx_recipients_user` | `recipient_id` | B-tree | Received recognitions on profile |
| `polls` | `idx_polls_activity` | `activity_id` | B-tree | Polls tied to an activity |
| `polls` | `idx_polls_open` | `closes_at` WHERE `is_closed = false` | Partial B-tree | Active/open polls list |
| `poll_votes` | `idx_poll_votes_poll` | `poll_id` | B-tree | Votes per poll (results aggregation) |
| `poll_votes` | `idx_poll_votes_user` | `user_id` | B-tree | User's voting history |
| `event_attendance` | `idx_attendance_activity` | `activity_id` | B-tree | Attendance per event |
| `event_attendance` | `idx_attendance_user` | `user_id` | B-tree | User's attendance history |
| `member_monthly_stats` | `idx_monthly_stats_user` | `user_id, stat_month DESC` | B-tree | Per-user stats history (most recent first) |
| `member_monthly_stats` | `idx_monthly_stats_month` | `stat_month` | B-tree | All members' stats for a given month (rankings) |
| `notification_inbox` | `idx_notifications_recipient` | `recipient_id, created_at DESC` | B-tree | Inbox feed |
| `notification_inbox` | `idx_notifications_unread` | `recipient_id` WHERE `is_read = false` | Partial B-tree | Unread count badge |
| `flagged_content` | `idx_flags_status` | `status` WHERE `status = 'pending'` | Partial B-tree | Admin pending queue |
| `invitations` | `idx_invitations_token` | `token_hash` | B-tree | Token lookup on registration |
| `invitations` | `idx_invitations_status` | `status` WHERE `status = 'pending'` | Partial B-tree | Admin pending invite list |
| `pinned_announcements` | `idx_pinned_active` | `(is_active)` WHERE `is_active = true` | Partial unique | One-active-pin enforcement |
| `admin_audit_log` | `idx_audit_admin` | `admin_id, performed_at DESC` | B-tree | Admin's action history |

*Note: `community_health_scores` is covered by its UNIQUE constraint on `score_month` and requires no additional secondary index.*

---

## Scalability Design

### Current Scale: 15–20 Users
At launch, data volumes are trivially small. PostgreSQL performance at this scale requires no special consideration. The schema is designed correctly from the start to scale cleanly.

### Target Scale: Up to 100 Users (NFR-04.1)
No code or schema changes required to support this range. All queries are indexed. The relational model is unchanged. Supabase Pro tier handles this comfortably.

### Growth Patterns by Table

| Table | Growth Rate | Notes |
|-------|-------------|-------|
| `profiles` | Bounded (max 100) | Small and stable; includes system account for Connect Buddy |
| `notification_inbox` | High | Prune notifications older than 90 days |
| `progress_logs` | Medium | One row per member per day per challenge |
| `poll_votes` | Medium | Bounded per poll by member count; grows with poll frequency |
| `event_attendance` | Low-Medium | One row per member per attended event; admin-recorded |
| `member_monthly_stats` | Low | One row per member per month; computed on schedule |
| `community_health_scores` | Very Low | One row per month; 12 rows/year |
| `admin_audit_log` | Low | Low-frequency admin actions |
| All others | Medium | Grows with community activity |

### Future Scalability Levers (V2+)

If the platform scales to 500+ users or high-frequency activity:

1. **Leaderboard materialized view** — Instead of computing `SUM(value)` on every page load, maintain a `challenge_leaderboard` materialized view, refreshed on each `progress_logs` INSERT.

2. **Notification inbox pruning job** — Archive `notification_inbox` rows older than 90 days to a `notification_archive` table. Keeps the hot table small.

3. **Feed pagination tuning** — Add cursor-based pagination (keyset pagination on `created_at`) instead of offset-based, to maintain consistent performance as the posts table grows.

4. **Read replicas** — Supabase supports read replicas for high-read workloads. Feed and leaderboard queries can be directed to the replica.

5. **Partition `member_monthly_stats` by month** — If the member count grows significantly, partitioning by `stat_month` makes monthly ranking queries more efficient.

---

## Data Lifecycle and Retention

| Data | Event | Action | Timing |
|------|-------|--------|--------|
| User PII (name, photo, bio) | User deactivated or removed | Nullify PII columns in profiles | Within 24 hours |
| User PII | After deactivation | Hard delete PII fields | Within 30 days |
| Soft-deleted posts/comments | is_deleted = true | Hard DELETE the row | After 30 days |
| Expired invitations | expires_at has passed | Set status = 'expired'; clean row | Daily cleanup job |
| Notification inbox | Any | Prune entries older than 90 days | Weekly cleanup job |
| Admin audit log | Any | Retained permanently (or 1 year minimum) | No auto-deletion |
| Progress logs | Challenge ended | Retained indefinitely (lightweight) | No auto-deletion |
| Activity history | Event date passed | Retained in archive view | No auto-deletion |
| Poll votes | Poll closed | Retained indefinitely (analytics) | No auto-deletion |
| Event attendance records | Any | Retained indefinitely (analytics) | No auto-deletion |
| Member monthly stats | Any | Retained indefinitely (rankings history) | No auto-deletion |
| Community health scores | Any | Retained indefinitely (trend analysis) | No auto-deletion |

Cleanup jobs run as scheduled Supabase Edge Functions (or pg_cron if available on the plan).

---

## Migration Strategy

### Tooling
All schema changes are managed via **Supabase CLI migrations** committed to `supabase/migrations/` in the repository. Migration files are named `{timestamp}_{description}.sql`.

### Migration Workflow

```
1. Developer writes migration locally
2. Apply to local Supabase (supabase db push)
3. Test in local environment
4. Commit migration file to PR
5. CI applies migration to staging and runs integration tests
6. On merge: staging deployment confirms success
7. Production release: apply migration to production before new app build submission
```

### Breaking Change Protocol (Three-Phase)
Never apply a breaking change to a live column in a single step. Use the three-phase approach:

| Phase | Action | Deploy |
|-------|--------|--------|
| Phase 1 | Add new column (nullable, no default) | Deploy app that writes both old and new |
| Phase 2 | Backfill existing data | Deploy data migration |
| Phase 3 | Remove old column | Deploy app that reads only new |

This ensures zero-downtime migrations without breaking in-flight client requests.

### Post-Migration Steps
After every migration:
1. Regenerate TypeScript types: `supabase gen types typescript --project-id <ref> > src/types/database.ts`
2. Run integration tests against the updated schema
3. Update `database-entity-catalogue.md` to reflect schema changes

---

## Backup and Recovery

| Attribute | Value |
|-----------|-------|
| Backup frequency | Daily (Supabase Pro) |
| Backup retention | 30 days |
| Recovery Time Objective (RTO) | 4 hours for full restore |
| Recovery Point Objective (RPO) | 24 hours (maximum 1 day data loss) |
| Backup encryption | AES-256 at rest (Supabase-managed) |
| Backup location | Same region as primary database |
| Point-in-time recovery | Available on Supabase Pro (WAL-based) |

### Recovery Scenarios

| Scenario | Recovery Action |
|----------|----------------|
| Accidental data deletion by user | Soft-delete prevents most cases; restore from backup if hard-deleted |
| Accidental migration applied to production | Three-phase protocol prevents irreversible changes; reverse migration if needed |
| Infrastructure failure | Supabase managed failover (Pro plan SLA) |
| Complete database loss | Restore latest daily backup via Supabase dashboard |

---

## Database Monitoring

| What to Monitor | How |
|----------------|-----|
| Query performance (slow queries) | Supabase dashboard → Query Performance |
| Table size growth | Supabase dashboard → Table Editor stats |
| Connection pool usage | Supabase dashboard → Connections |
| Failed RLS policy violations | Supabase logs (PostgREST returns 403; logged) |
| Edge Function errors | Supabase Edge Function logs |
| Notification inbox size | Monthly review via admin panel query |

Alert trigger: any single table exceeding 1 GB warrants a review of archival or partitioning strategy.

---

## Storage Buckets (Supabase Storage)

Two storage buckets are associated with the database design:

| Bucket | Path Convention | Access Policy |
|--------|----------------|---------------|
| `avatars` | `avatars/{user_id}/profile.jpg` | Public read (CDN), authenticated write by owner only |
| `post-images` | `post-images/{user_id}/{uuid}.jpg` | Authenticated read (members only), authenticated write by owner only |

Storage paths are stored in the database as text references, not full URLs. Public URLs are generated at query time via `supabase.storage.from(bucket).getPublicUrl(path)`.

When a user is deactivated, their avatar is deleted from storage as part of the PII anonymization process. Post images are retained (content anonymized via profile anonymization).
