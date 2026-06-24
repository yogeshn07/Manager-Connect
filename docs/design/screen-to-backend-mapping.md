# Manager Connect — Screen to Backend Mapping
> Version 1.0 · Implementation dependency map

---

## Legend

| Symbol | Meaning |
|---|---|
| `RT` | Realtime channel (Supabase realtime / WebSocket) |
| `S3` | File/media storage |
| `ROLE` | Required user role |

---

## Module 1: Feed

### Feed Home (`/feed`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /posts` (paginated, sorted by trending/recent), `GET /users/stories` (active status), `GET /posts/trending-topics` |
| **Tables** | `posts`, `users`, `post_reactions`, `post_comments`, `stories` |
| **Realtime** | `RT posts` (new post notifications), `RT post_reactions` (live reaction counts) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member`, `senior_leader`, `admin` |

### Post Detail (`/feed/post/:postId`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /posts/:id`, `GET /posts/:id/comments` (threaded), `GET /posts/:id/reactions`, `POST /posts/:id/reactions`, `POST /posts/:id/comments`, `POST /comments/:id/replies` |
| **Tables** | `posts`, `post_reactions`, `post_comments`, `comment_replies`, `users` |
| **Realtime** | `RT post_comments` (live comment thread), `RT post_reactions` (live count) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

---

## Module 2: Profile

### My Profile (`/profile`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /users/me`, `GET /users/me/stats`, `GET /users/me/badges`, `GET /users/me/activity?limit=4`, `GET /users/me/rank` |
| **Tables** | `users`, `user_stats`, `achievements`, `activity_log`, `community_rankings` |
| **Realtime** | `RT user_stats` (score updates) |
| **Storage** | Profile photos (`S3 user-avatars`) |
| **Permissions** | Authenticated, own profile |
| **User Roles** | `member` |

### Manager Profile — Other User (`/profile/:userId`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /users/:id/public`, `GET /users/:id/stats/public`, `GET /users/:id/badges/public`, `GET /users/:id/recognitions/recent`, `GET /connections/mutual/:id` |
| **Tables** | `users`, `user_stats`, `achievements`, `recognitions`, `connections` |
| **Realtime** | None |
| **Storage** | Profile photos |
| **Permissions** | Authenticated member (public profile view) |
| **User Roles** | `member` |

### Recognition History (`/profile/:userId/recognitions`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /recognitions?userId=:id&filter=category` |
| **Tables** | `recognitions`, `users` |
| **Realtime** | None |
| **Storage** | None |
| **Permissions** | Own recognitions or viewing another's public profile |
| **User Roles** | `member` |

### Achievement Gallery (`/profile/:userId/achievements`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /achievements?userId=:id`, `GET /achievement-progress?userId=:id` |
| **Tables** | `achievements`, `achievement_progress`, `user_achievements` |
| **Realtime** | `RT user_achievements` (badge unlock events) |
| **Storage** | Badge assets (if custom imagery) |
| **Permissions** | Own or public profile |
| **User Roles** | `member` |

### Activity Timeline (`/profile/:userId/activity`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /activity?userId=:id&page=:n` |
| **Tables** | `activity_log` (unified table: posts, recognitions, events, challenges, comments) |
| **Realtime** | None |
| **Storage** | None |
| **Permissions** | Own timeline |
| **User Roles** | `member` |

---

## Module 3: Events

### Events Hub (`/events`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /events?status=upcoming&featured=true`, `GET /events?status=upcoming&sort=date`, `GET /rsvps/me` (to show RSVP status on cards) |
| **Tables** | `events`, `event_rsvps`, `users` |
| **Realtime** | `RT events` (capacity updates) |
| **Storage** | Event images (`S3 event-images`) |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Event Detail (`/events/:eventId`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /events/:id`, `GET /events/:id/attendees?limit=5`, `GET /events/:id/rsvp/me`, `GET /events/:id/agenda` |
| **Tables** | `events`, `event_rsvps`, `event_agenda`, `users` |
| **Realtime** | `RT event_rsvps` (live capacity bar updates) |
| **Storage** | Event images |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### RSVP Experience (`/events/:eventId/rsvp`)

| Dependency | Details |
|---|---|
| **APIs** | `POST /events/:id/rsvp` (body: `{status: "going"|"interested"|"not_going"}`), `GET /events/:id/rsvp/colleagues` |
| **Tables** | `event_rsvps`, `users` |
| **Realtime** | None (result confirmed synchronously) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Event Attendees (`/events/:eventId/attendees`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /events/:id/attendees?page=:n&department=:dept`, `GET /events/:id/attendees/stats` |
| **Tables** | `event_rsvps`, `users`, `user_stats` |
| **Realtime** | None |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Event Gallery (`/events/:eventId/gallery`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /events/:id/gallery`, `POST /gallery/:photoId/like`, `DELETE /gallery/:photoId/like` |
| **Tables** | `event_gallery`, `gallery_likes`, `users` |
| **Realtime** | `RT gallery_likes` (live like counts) |
| **Storage** | `S3 event-gallery` (photos) |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Past Events Archive (`/events/past`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /events?status=past&rsvp_userId=me&sort=date_desc` |
| **Tables** | `events`, `event_rsvps` |
| **Realtime** | None |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

---

## Module 4: Challenges & Wellness

### Challenges Home (`/challenges`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /challenges?status=active&featured=true`, `GET /challenges/me/active`, `GET /streaks/me/current` |
| **Tables** | `challenges`, `challenge_participants`, `streaks` |
| **Realtime** | `RT streaks` (live streak count) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Challenge Detail (`/challenges/:challengeId`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /challenges/:id`, `GET /challenges/:id/progress/me`, `GET /challenges/:id/leaderboard?limit=4`, `GET /challenges/:id/rewards` |
| **Tables** | `challenges`, `challenge_progress`, `challenge_leaderboard`, `challenge_rewards` |
| **Realtime** | `RT challenge_leaderboard` (live rank updates) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Challenge Leaderboard (`/challenges/:challengeId/leaderboard`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /challenges/:id/leaderboard?full=true` |
| **Tables** | `challenge_leaderboard`, `users` |
| **Realtime** | `RT challenge_leaderboard` |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Streak Center (`/challenges/streaks`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /streaks/me`, `GET /streaks/me/calendar?month=:month` |
| **Tables** | `streaks`, `streak_days` |
| **Realtime** | None |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Wellness Hub (`/wellness`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /wellness/sessions`, `GET /wellness/score/me`, `GET /wellness/reflections/today` |
| **Tables** | `wellness_sessions`, `wellness_scores`, `reflections` |
| **Realtime** | None |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Monthly Community Challenge (`/challenges/monthly`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /challenges/monthly/current`, `GET /challenges/monthly/participation/departments`, `GET /challenges/monthly/leaderboard?limit=5`, `GET /challenges/monthly/countdown` |
| **Tables** | `challenges`, `challenge_participants`, `challenge_leaderboard`, `departments` |
| **Realtime** | `RT challenge_leaderboard`, `RT challenge_participants` (participation counter) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Milestones & Rewards (`/challenges/milestones`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /users/me/level`, `GET /rewards?tier=all`, `GET /rewards/me/unlocked` |
| **Tables** | `user_levels`, `rewards`, `user_rewards` |
| **Realtime** | None |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

---

## Module 5: Notifications

### Notification Center (`/notifications`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /notifications/me?page=:n`, `POST /notifications/me/read-all`, `DELETE /notifications/:id` |
| **Tables** | `notifications`, `users` |
| **Realtime** | `RT notifications` (new notification push to client) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Digest Summary (`/notifications/digest`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /digest/me?period=today|week|month` |
| **Tables** | `digest_aggregates` (pre-computed), `posts`, `recognitions`, `streaks`, `events`, `notifications` |
| **Realtime** | None (snapshot, not realtime) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

### Mentions Hub (`/notifications/mentions`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /mentions/me?page=:n` |
| **Tables** | `mentions`, `posts`, `post_comments`, `users` |
| **Realtime** | `RT mentions` |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

---

## Module 6: Analytics

### Analytics Home (`/analytics`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /analytics/community-health`, `GET /analytics/kpis/me`, `GET /analytics/insights`, `GET /analytics/engagement/weekly` |
| **Tables** | `analytics_snapshots`, `community_health_scores` |
| **Realtime** | None (daily aggregated) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member`, `senior_leader` |

### Executive Summary (`/analytics/executive`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /analytics/executive-summary`, `POST /analytics/executive-summary/export-pdf` |
| **Tables** | `analytics_snapshots`, `community_health_scores`, `recommendations` |
| **Realtime** | None |
| **Storage** | `S3 exports` (generated PDFs, 24hr TTL) |
| **Permissions** | `senior_leader` or `admin` role only |
| **User Roles** | `senior_leader`, `admin` |

### Rankings (`/analytics/rankings`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /rankings?period=monthly|alltime&category=community_impact|recognition|participation|wellness&page=:n` |
| **Tables** | `community_rankings`, `users` |
| **Realtime** | None (daily snapshot) |
| **Storage** | None |
| **Permissions** | Authenticated member |
| **User Roles** | `member` |

---

## Module 7: Admin

### Admin Home (`/admin`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /admin/dashboard`, `GET /admin/pending-counts`, `GET /events?status=upcoming&limit=3` |
| **Tables** | `admin_dashboard_snapshot`, `moderation_queue`, `event_rsvps`, `invitations` |
| **Realtime** | `RT moderation_queue` (new reports), `RT invitations` (new accepts) |
| **Storage** | None |
| **Permissions** | Admin only |
| **User Roles** | `admin`, `hr_coordinator`, `event_organizer` |

### Content Moderation (`/admin/moderation`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /admin/moderation/queue`, `POST /admin/moderation/:reportId/keep`, `POST /admin/moderation/:reportId/warn`, `POST /admin/moderation/:reportId/remove` |
| **Tables** | `moderation_queue`, `content_reports`, `posts`, `users`, `user_warnings` |
| **Realtime** | `RT moderation_queue` |
| **Storage** | None |
| **Permissions** | `admin` |
| **User Roles** | `admin` |

### User Management (`/admin/users`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /admin/users?search=:q&status=:s&department=:d&page=:n`, `POST /admin/users/:id/warn`, `POST /admin/users/:id/suspend`, `POST /admin/users/:id/activate`, `POST /admin/users/:id/nudge` |
| **Tables** | `users`, `user_warnings`, `user_stats` |
| **Realtime** | None |
| **Storage** | None |
| **Permissions** | `admin` |
| **User Roles** | `admin` |

### Invitation Management (`/admin/users/invitations`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /admin/invitations?status=pending|accepted|expired`, `POST /admin/invitations`, `POST /admin/invitations/:id/resend`, `DELETE /admin/invitations/:id` |
| **Tables** | `invitations` |
| **Realtime** | `RT invitations` |
| **Storage** | None |
| **Permissions** | `admin` |
| **User Roles** | `admin`, `hr_coordinator` |

### Event Administration (`/admin/events`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /admin/events`, `PUT /admin/events/:id`, `DELETE /admin/events/:id`, `GET /admin/events/:id/rsvps` |
| **Tables** | `events`, `event_rsvps`, `event_agenda` |
| **Realtime** | `RT event_rsvps` |
| **Storage** | `S3 event-images` |
| **Permissions** | `admin`, `event_organizer` |
| **User Roles** | `admin`, `event_organizer` |

### Challenge Administration (`/admin/challenges`)

| Dependency | Details |
|---|---|
| **APIs** | `GET /admin/challenges`, `PUT /admin/challenges/:id`, `POST /admin/challenges/:id/end`, `POST /admin/challenges/:id/rewards/confirm`, `POST /admin/challenges/:id/nudge` |
| **Tables** | `challenges`, `challenge_participants`, `challenge_progress`, `challenge_rewards` |
| **Realtime** | None |
| **Storage** | None |
| **Permissions** | `admin` |
| **User Roles** | `admin` |

---

## User Roles Reference

| Role | Description | Access |
|---|---|---|
| `member` | Standard manager/team lead | All member screens |
| `senior_leader` | VP/Director | Member screens + Executive Summary |
| `event_organizer` | Can create and manage events | Member screens + Event Admin |
| `hr_coordinator` | Can manage invitations and users | Member screens + User Management + Invitations |
| `admin` | Full community admin | All screens including Admin module |

---

## Data Models Reference (Key Tables)

```
users               id, name, email, role, department, avatar_url, joined_at, level, score
posts               id, user_id, type, content, created_at, is_pinned
post_reactions      id, post_id, user_id, reaction_type
post_comments       id, post_id, user_id, content, created_at
comment_replies     id, comment_id, user_id, content, created_at
recognitions        id, giver_id, receiver_id, category, reason, created_at, is_featured
events              id, title, type, date, venue, capacity, organizer_id, status
event_rsvps         id, event_id, user_id, status (going/interested/not_going)
event_gallery       id, event_id, photo_url, caption, uploaded_at
challenges          id, title, type, duration_days, start_date, end_date, goal, status
challenge_participants  id, challenge_id, user_id, joined_at
challenge_progress  id, challenge_id, user_id, date, value, is_complete
streaks             id, user_id, challenge_id, current_streak, longest_streak
achievements        id, user_id, badge_type, tier, earned_at
notifications       id, user_id, type, content, reference_id, reference_type, read_at
invitations         id, email, invited_by, sent_at, expires_at, accepted_at, status
moderation_queue    id, content_type, content_id, reporter_id, reason, status, created_at
user_warnings       id, user_id, issued_by, reason, created_at
analytics_snapshots id, metric, value, period, created_at
community_rankings  id, user_id, category, rank, score, period
```
