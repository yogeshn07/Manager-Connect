# Backend Implementation Roadmap

## Implementation Order

Edge Functions are implemented in dependency order. Functions that other functions call are built first.

### Sprint 1: Foundation + Auth (6 functions)

| Order | Function | Complexity | Dependencies | Risk |
|-------|----------|-----------|-------------|------|
| 1 | `send-notification` | Medium | notification_inbox, profiles (push_token), FCM API | **High** — every other function depends on this |
| 2 | `validate-invite-token` | Low | invitations | Low |
| 3 | `send-invitation` | Low | invitations, audit.service | Low |
| 4 | `create-profile` | Medium | profiles, invitations, notification.service | Medium — triggers CB welcome post |
| 5 | `post-connect-buddy-message` | Low | posts, connect-buddy.repository | Low |
| 6 | `create-post` | Medium | posts, post_images, post_mentions, notification.service | Medium — @mention parsing |

**Pre-requisite:** Create Connect Buddy auth.users entry + restore seed.sql before testing `create-profile`.

### Sprint 2: Events (4 functions)

| Order | Function | Complexity | Dependencies | Risk |
|-------|----------|-----------|-------------|------|
| 7 | `cancel-activity` | Low | activities, activity_rsvps, notification.service | Low |
| 8 | `post-activity-update` | Low | activity_updates, activity_rsvps, notification.service | Low |
| 9 | `create-poll` | Medium | polls, poll_options (atomic) | Low |
| 10 | `close-poll` | Medium | polls, poll_votes, notification.service | Low — also handles scheduled batch |

### Sprint 3: Growth + Recognition + Attendance (3 functions)

| Order | Function | Complexity | Dependencies | Risk |
|-------|----------|-----------|-------------|------|
| 11 | `close-challenge` | Low | challenges, challenge_participants, notification.service | Low |
| 12 | `record-attendance` | Medium | event_attendance (batch upsert), audit.service | Low |
| 13 | `create-recognition` | Medium | recognitions, recognition_recipients, notification.service | Low |

### Sprint 4: Admin (5 functions)

| Order | Function | Complexity | Dependencies | Risk |
|-------|----------|-----------|-------------|------|
| 14 | `resolve-flag` | Medium | flagged_content, posts/comments, audit.service | Medium — soft-deletes across tables |
| 15 | `pin-announcement` | Low | pinned_announcements, audit.service | Low |
| 16 | `deactivate-user` | Medium | profiles, audit.service | Medium — nullifies push_token |
| 17 | `remove-user` | High | profiles, Storage (avatar delete), audit.service | **High** — PII anonymization |
| 18 | `revoke-invitation` | Low | invitations, audit.service | Low |

### Sprint 5: Scheduled + Analytics (3 functions)

| Order | Function | Complexity | Dependencies | Risk |
|-------|----------|-----------|-------------|------|
| 19 | `compute-monthly-stats` | High | member_monthly_stats, community_health_scores, reads from 6+ tables | **High** — aggregation logic |
| 20 | `scheduled-connect-buddy` | Medium | posts (via post-connect-buddy-message), multiple trigger types | Medium — 7 trigger types |
| 21 | `scheduled-cleanup` | Medium | posts, comments, invitations, notification_inbox | Medium — hard deletes |

## Complexity Assessment

| Level | Functions | Count |
|-------|----------|-------|
| **High** | send-notification, remove-user, compute-monthly-stats | 3 |
| **Medium** | create-profile, create-post, create-poll, close-poll, record-attendance, create-recognition, resolve-flag, deactivate-user, scheduled-connect-buddy, scheduled-cleanup | 10 |
| **Low** | validate-invite-token, send-invitation, post-connect-buddy-message, cancel-activity, post-activity-update, close-challenge, pin-announcement, revoke-invitation | 8 |

## Risk Areas

| Risk | Impact | Mitigation |
|------|--------|-----------|
| `send-notification` failure | All notification-dependent functions break | Build and test first; mock in downstream tests |
| FCM integration | Push delivery depends on correct FCM key + token management | Test with real device early; fallback to in-app inbox |
| `compute-monthly-stats` aggregation | Wrong scores affect rankings and health score | Test with known fixture data; compare against manual calculations |
| `remove-user` PII anonymization | Legal/compliance requirement | Test thoroughly; verify avatar deleted from Storage |
| `scheduled-cleanup` hard deletes | Data loss if criteria wrong | Test with soft-deleted fixture data; verify only expired content removed |

## Shared Infrastructure Needed

Before any Edge Function can run:

| Component | Status | Action Needed |
|-----------|--------|---------------|
| `_shared/supabase-client.ts` | ✓ Exists | Ready |
| `_shared/cors.ts` | ✓ Exists | Ready |
| `_shared/errors.ts` | ✓ Exists | Ready |
| `_shared/auth.ts` | ✓ Exists | Ready |
| `_shared/crypto.ts` | ✓ Exists | Ready |
| `_shared/constants.ts` | ✓ Exists | Ready |
| `_shared/validators/*.ts` | Structure exists | **Implement per sprint** |
| `_shared/repositories/*.ts` | Structure exists | **Implement per sprint** |
| `_shared/services/notification.service.ts` | Stub exists | **Implement in Sprint 1** |
| `_shared/services/audit.service.ts` | Structure exists | **Implement in Sprint 1** |

## Estimated Effort

| Sprint | Functions | Est. Days |
|--------|----------|-----------|
| Sprint 1 | 6 (foundation + auth + feed) | 5–7 |
| Sprint 2 | 4 (events) | 3–4 |
| Sprint 3 | 3 (growth + recognition + attendance) | 2–3 |
| Sprint 4 | 5 (admin) | 3–5 |
| Sprint 5 | 3 (scheduled + analytics) | 4–6 |
| **Total** | **21** | **17–25 days** |
