# Frontend Sprint 5 Planning

**Date:** 2026-06-21

---

## 1. Delivery Gap Analysis

### Optimized Roadmap vs Actual Delivery

| Optimized Sprint | Planned Scope | Actual Delivery | Status |
|-----------------|---------------|-----------------|--------|
| F1 | Infrastructure + Auth | Auth (4 screens) | COMPLETE |
| F2 | Community Feed | Feed (3 screens + 1 modal) | COMPLETE |
| F3 | Events + Polls | Activities (2 screens + 1 modal) | PARTIAL — Polls moved to F4 |
| F4 | Growth + Recognition | Polls (2 screens + 1 modal) + Recognition (2 screens + 1 modal) | PARTIAL — Growth not delivered |
| F5 | Notifications + Analytics | — | NOT STARTED |
| F6 | Profile | — | NOT STARTED |
| F7 | Admin | — | NOT STARTED |

### Gap: Growth/Challenges Module

The optimized roadmap placed Growth (Challenges) in F4 alongside Recognition. Recognition was delivered in actual Sprint 4, but Growth was not. This leaves the Challenges feature unimplemented:

| Screen | ID | Status |
|--------|----|--------|
| Challenge List | G1 | NOT IMPLEMENTED |
| Challenge Detail (leaderboard) | G2 | NOT IMPLEMENTED |
| Log Progress | G3 (sheet) | NOT IMPLEMENTED |
| Create Challenge | G4 (modal) | NOT IMPLEMENTED |

The Growth tab currently renders `RecognitionFeedScreen` as a placeholder.

---

## 2. Sprint 5 Recommended Scope

**Combine the Growth gap with the planned F5 scope (Notifications + Analytics).**

This produces a coherent sprint that completes all remaining member-facing features before Profile and Admin.

### Sprint 5 Modules

| Module | Screens | Modals/Sheets | Total UI |
|--------|---------|---------------|----------|
| Growth (Challenges) | 2 (Challenge List, Challenge Detail) | 2 (Create Challenge, Log Progress) | 4 |
| Notifications | 1 (Notification Center) | 0 | 1 |
| Analytics | 2 (Analytics with personal/community tabs, Rankings) | 0 | 2 |
| **Total** | **5** | **2** | **7** |

---

## 3. Screen Definitions

### Growth/Challenges

| # | Screen | Purpose | Data Sources | APIs |
|---|--------|---------|-------------|------|
| G1 | Challenge List | Active + completed challenges, join/leave | challenges, challenge_participants | REST: challenges, challenge_participants |
| G2 | Challenge Detail | Info, participants, leaderboard, progress | challenges, challenge_participants, progress_logs, profiles | REST: all above |
| G3 | Log Progress (sheet) | Daily progress entry | User input | REST: UPSERT progress_logs |
| G4 | Create Challenge (modal) | New challenge form | User input | REST: POST challenges |

### Notifications

| # | Screen | Purpose | Data Sources | APIs | Realtime |
|---|--------|---------|-------------|------|----------|
| N1 | Notification Center | Inbox, mark read, deep link | notification_inbox | REST: GET, PATCH, DELETE | `notifications:inbox:{user_id}` (V1 channel) |

### Analytics

| # | Screen | Purpose | Data Sources | APIs |
|---|--------|---------|-------------|------|
| AN1 | Analytics (Personal + Community tabs) | Own stats + health score + engagement | member_monthly_stats, community_health_scores | REST: member_monthly_stats, community_health_scores |
| AN3 | Rankings | Monthly + all-time leaderboard | member_monthly_stats, profiles | REST: member_monthly_stats with profile joins |

---

## 4. Architecture Impact

### Providers (5 new)

| Provider | Type | Scope |
|----------|------|-------|
| `challengeListProvider` | Notifier (keepAlive) | Challenge list with active/completed filter |
| `challengeDetailProvider(id)` | Notifier (family) | Challenge + participants + leaderboard |
| `notificationInboxProvider` | Notifier (keepAlive) | Inbox list + unread count |
| `analyticsProvider` | Notifier (keepAlive) | Personal stats + community health score |
| `rankingsProvider` | Notifier (auto-dispose) | Monthly rankings |

### Repositories (3 new)

| Repository | Tables | Operations |
|-----------|--------|------------|
| `ChallengeRepository` | challenges, challenge_participants, progress_logs | getActive, getCompleted, getDetail, create, join, leave, logProgress, getLeaderboard |
| `NotificationRepository` | notification_inbox | getInbox, getUnreadCount, markRead, markAllRead, delete |
| `AnalyticsRepository` | member_monthly_stats, community_health_scores | getPersonalStats, getHealthScores, getRankings |

### Models/DTOs (6 new)

| Model | Purpose |
|-------|---------|
| `ChallengeDto` | Challenge with type, goal, dates, status |
| `ParticipantDto` | Challenge participant with profile join |
| `ProgressLogDto` | Daily progress entry |
| `NotificationItemDto` | Notification with type, title, reference |
| `MemberStatsDto` | Monthly stats (events, challenges, recognitions, posts) |
| `HealthScoreDto` | Community health score with component rates |

### Realtime (1 new channel — V1)

| Channel | Scope | Lifecycle |
|---------|-------|-----------|
| `notifications:inbox:{user_id}` | App-wide (keepAlive) | Subscribe on auth, unsubscribe on logout |

This is the second V1 realtime channel (alongside `feed:posts`).

### Routes (2 new)

| Route | Screen |
|-------|--------|
| `/challenge/:id` | ChallengeDetailScreen |
| `/analytics/rankings` | RankingsScreen |

### Tab Changes

| Tab | Current | Sprint 5 |
|-----|---------|----------|
| Growth | RecognitionFeedScreen | ChallengeListScreen (with link to Recognition) |
| Analytics | PlaceholderScreen | AnalyticsScreen (personal/community tabs) |

### Navigation Update

The Growth tab will show ChallengeListScreen with a "Recognition Wall" action button in the app bar to access the existing RecognitionFeedScreen. This preserves the current Recognition module while adding Challenges as the tab's primary content.

---

## 5. Dependency Verification

### Backend APIs

| API | Pattern | Table/Function | Status |
|-----|---------|---------------|--------|
| Get active challenges | REST | challenges | **EXISTS** |
| Create challenge | REST | challenges | **EXISTS** |
| Join challenge | REST | challenge_participants | **EXISTS** |
| Leave challenge | REST | challenge_participants | **EXISTS** |
| Log progress | REST | progress_logs | **EXISTS** |
| Get leaderboard | REST | progress_logs | **EXISTS** |
| Get notification inbox | REST | notification_inbox | **EXISTS** |
| Mark notification read | REST | notification_inbox | **EXISTS** |
| Get personal stats | REST | member_monthly_stats | **EXISTS** |
| Get health scores | REST | community_health_scores | **EXISTS** |
| Get rankings | REST | member_monthly_stats | **EXISTS** |

### Edge Functions (not called by Sprint 5 screens)

`close-challenge` and `compute-monthly-stats` are service-role scheduled functions — not called from frontend. All Sprint 5 operations are REST-only.

### Database Tables

| Table | Status |
|-------|--------|
| challenges | **EXISTS** — 26 tables verified |
| challenge_participants | **EXISTS** |
| progress_logs | **EXISTS** |
| notification_inbox | **EXISTS** |
| member_monthly_stats | **EXISTS** |
| community_health_scores | **EXISTS** |

### FK Ambiguity Check

| Table | FKs to profiles | Hint Needed |
|-------|----------------|-------------|
| challenges | 1 (`created_by`) | No |
| challenge_participants | 1 (`user_id`) | No |
| progress_logs | 0 (FK to challenge_participants, not profiles) | No |
| notification_inbox | 0 (no profile join needed) | No |
| member_monthly_stats | 1 (`user_id`) | No |

No FK ambiguity issues for Sprint 5 tables.

---

## 6. Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| progress_logs UPSERT needs correct on_conflict columns | Low | Verified: UNIQUE on (challenge_id, user_id, log_date) — but FK is via challenge_participant_id, not challenge_id directly. Need to check exact column structure. |
| Notification deep-link routing for missing screens | Medium | Some notification types reference screens not yet built (e.g., recognitions). Deep link falls back to feed if route doesn't exist. |
| Growth tab restructure disrupts Recognition access | Low | Recognition remains at its current route; Growth tab adds a navigation path to it. |

---

## 7. Acceptance Criteria

| # | Criterion |
|---|-----------|
| 1 | Challenge List shows active and completed challenges |
| 2 | Challenge Detail shows participants and leaderboard |
| 3 | Users can create, join, and leave challenges |
| 4 | Users can log daily progress (upsert) |
| 5 | Notification Center shows inbox with mark-read |
| 6 | Notification unread badge updates via realtime |
| 7 | Analytics screen shows personal stats and community health score |
| 8 | Rankings screen shows monthly leaderboard |
| 9 | `flutter analyze` — no issues |
| 10 | `flutter build web` — compiles |
| 11 | `flutter run -d chrome` — launches |

---

## 8. Scope Isolation

| Check | Result |
|-------|--------|
| No Sprint F6 (Profile) functionality | **CONFIRMED** — Profile tab remains placeholder |
| No Sprint F7 (Admin) functionality | **CONFIRMED** — Admin route remains placeholder |
| No backend modifications | **CONFIRMED** — all APIs exist |
| No schema changes | **CONFIRMED** — all tables exist |
| No RLS changes | **CONFIRMED** |

---

## 9. Verdict

| Check | Result |
|-------|--------|
| Scope clearly defined | **PASS** — 3 modules, 5 screens, 2 modals |
| Dependencies satisfied | **PASS** — all 6 tables exist, all REST APIs defined |
| Required APIs available | **PASS** — all REST, no Edge Functions needed |
| Required tables available | **PASS** — verified in live database |
| Unresolved blockers | **0** |

### READY FOR FRONTEND SPRINT 5 IMPLEMENTATION
