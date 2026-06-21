# Frontend Implementation Roadmap

**Date:** 2026-06-21

---

## 1. Implementation Principles

1. **Feature-complete sprints.** Each sprint delivers fully working screens, not partial scaffolds.
2. **Data layer first.** DTOs → Repository → Provider → Screen. Bottom-up within each feature.
3. **Infrastructure before features.** Shared widgets, services, and the repository base go first.
4. **Auth before content.** Users must be able to log in before any feature screen is useful.
5. **Read before write.** List/detail screens before create/edit screens.
6. **Core features before admin.** Admin screens are low-traffic and can come last.

---

## 2. Sprint Plan (8 sprints)

### Sprint F1: Infrastructure + Auth (4 screens)

**Goal:** Login flow end-to-end, session management, profile setup.

| Task | Type | Screens |
|------|------|---------|
| Shared widgets: user_avatar, empty_state, error_state, loading_state, toast, confirm_dialog | Widget | — |
| Shared services: image_upload_service, deep_link_service | Service | — |
| core/network: api_error_handler, connectivity_provider | Core | — |
| Auth DTOs + domain models: Profile, Invitation | Model | — |
| auth_repository, profile_repository | Repository | — |
| Splash screen | Screen | A1 |
| Welcome / Login screen (OTP request) | Screen | A2 |
| Verify OTP screen | Screen | A3 |
| Profile Setup screen (invite validation + profile creation + avatar upload) | Screen | A4 |
| Auth route guards (auth, profile, deactivated) | Router | — |

**Dependencies:** Supabase Auth, `validate-invite-token` EF, `create-profile` EF, Storage (avatars)
**Screens:** 4
**Complexity:** Medium (OTP flow, session management, image upload)

---

### Sprint F2: Community Feed (4 screens)

**Goal:** Feed browsing, post creation, reactions, comments, pinned posts.

| Task | Type | Screens |
|------|------|---------|
| Feed DTOs + domain models: Post, Comment, Reaction | Model | — |
| feed_repository, comment_repository, reaction_repository | Repository | — |
| Feed providers: paginated feed, post detail, realtime | Provider | — |
| Feed screen (paginated list, pinned post banner, Connect Buddy styling) | Screen | F1 |
| Create Post screen (text + image picker + upload) | Screen | F2 |
| Post Detail screen (reactions, comments, flag action) | Screen | F3 |
| Member Profile View screen | Screen | F4 |
| Widgets: post_card, pinned_post_banner, connect_buddy_badge, reaction_bar, comment_tile | Widget | — |
| Realtime: `feed:posts`, `feed:reactions`, `feed:comments` subscriptions | Realtime | — |

**Dependencies:** `create-post` EF, Storage (post-images), Realtime
**Screens:** 4
**Complexity:** High (pagination, realtime, image upload, @mentions, multiple card types)

---

### Sprint F3: Events (5 screens)

**Goal:** Event browsing, creation, RSVP flow, organizer updates.

| Task | Type | Screens |
|------|------|---------|
| Events DTOs + domain models: Activity, Rsvp, ActivityUpdate | Model | — |
| activity_repository, rsvp_repository, activity_update_repository | Repository | — |
| Events providers | Provider | — |
| Activities List screen (upcoming/past, category filter) | Screen | E1 |
| Activity Detail screen (info, RSVP button, updates, linked polls) | Screen | E2 |
| Create Activity screen | Screen | E3 |
| RSVP List screen | Screen | E4 |
| Activity Updates screen | Screen | E5 |
| Widgets: activity_card, rsvp_button, category_filter_chips, update_tile | Widget | — |
| Realtime: `activities:rsvps` subscription | Realtime | — |

**Dependencies:** `cancel-activity` EF, `post-activity-update` EF, Realtime
**Screens:** 5
**Complexity:** Medium (RSVP state, category filtering, date formatting)

---

### Sprint F4: Polls (3 screens)

**Goal:** Poll browsing, voting, result visualization.

| Task | Type | Screens |
|------|------|---------|
| Poll DTOs + domain models: Poll, PollOption, PollVote | Model | — |
| poll_repository | Repository | — |
| Poll providers | Provider | — |
| Poll List screen | Screen | P1 |
| Poll Detail / Vote screen (options, vote, results bar chart) | Screen | P2 |
| Create Poll screen | Screen | P3 |
| Widgets: poll_card, poll_option_tile, poll_results_chart | Widget | — |
| Realtime: `events:poll_votes` subscription | Realtime | — |

**Dependencies:** `create-poll` EF, Realtime
**Screens:** 3
**Complexity:** Medium (voting logic, result visualization, optimistic updates)

---

### Sprint F5: Growth + Recognition (6 screens)

**Goal:** Challenges with leaderboard + recognition feed.

| Task | Type | Screens |
|------|------|---------|
| Growth DTOs + models: Challenge, Participant, ProgressLog | Model | — |
| challenge_repository, progress_repository | Repository | — |
| Growth providers | Provider | — |
| Challenge List screen | Screen | G1 |
| Challenge Detail screen (leaderboard, progress) | Screen | G2 |
| Log Progress screen | Screen | G3 |
| Create Challenge screen | Screen | G4 |
| Recognition DTOs + models: Recognition, Recipient, Reaction | Model | — |
| recognition_repository | Repository | — |
| Recognition Feed screen | Screen | R1 |
| Create Recognition screen (member picker, category selector) | Screen | R2 |
| Widgets: challenge_card, leaderboard_tile, progress_input, recognition_card, category_badge | Widget | — |
| Realtime: `growth:leaderboard` subscription | Realtime | — |

**Dependencies:** `create-recognition` EF, Realtime
**Screens:** 6
**Complexity:** Medium (leaderboard sorting, progress input, category tags)

---

### Sprint F6: Notifications + Analytics (4 screens)

**Goal:** Notification inbox with deep linking + personal and community analytics.

| Task | Type | Screens |
|------|------|---------|
| Notification DTOs + models | Model | — |
| notification_repository | Repository | — |
| Notification Center screen (inbox, mark read, deep link) | Screen | N1 |
| Notification badge provider (unread count) | Provider | — |
| Realtime: `notifications:inbox` subscription | Realtime | — |
| Analytics DTOs + models: MemberStats, HealthScore | Model | — |
| analytics_repository | Repository | — |
| Personal Analytics screen | Screen | AN1 |
| Community Analytics screen (health score gauge) | Screen | AN2 |
| Rankings screen (monthly + all-time tabs) | Screen | AN3 |
| Widgets: stat_card, health_score_gauge, ranking_tile, notification_tile | Widget | — |
| deep_link_service: notification tap → GoRouter navigation | Service | — |

**Dependencies:** None (all REST-based)
**Screens:** 4
**Complexity:** Medium (data visualization, deep linking)

---

### Sprint F7: Profile + Settings (3 screens)

**Goal:** Profile viewing, editing, notification preferences, logout.

| Task | Type | Screens |
|------|------|---------|
| My Profile screen (stats, recognitions received) | Screen | PR1 |
| Edit Profile screen (avatar, name, bio, title, tags) | Screen | PR2 |
| Settings screen (notification prefs toggles, logout) | Screen | PR3 |
| Widgets: profile_header, notification_pref_tile | Widget | — |

**Dependencies:** Storage (avatar upload)
**Screens:** 3
**Complexity:** Low (form editing, toggle preferences)

---

### Sprint F8: Admin (5 screens)

**Goal:** Full admin panel — members, moderation, attendance, pins.

| Task | Type | Screens |
|------|------|---------|
| Admin DTOs + models: FlaggedContent | Model | — |
| admin_repository (member, moderation, event) | Repository | — |
| Admin Dashboard screen | Screen | AD1 |
| Member Management screen (invite, deactivate, remove, reactivate) | Screen | AD2 |
| Moderation Queue screen (review + resolve flags) | Screen | AD3 |
| Attendance Recording screen (batch toggle) | Screen | AD4 |
| Pin Management screen | Screen | AD5 |
| Admin route guard | Router | — |
| Widgets: member_action_sheet, flag_review_card, attendance_toggle | Widget | — |

**Dependencies:** 5 admin Edge Functions
**Screens:** 5
**Complexity:** Medium (batch operations, confirmation dialogs, role guards)

---

## 3. Sprint Summary

| Sprint | Name | Screens | New Widgets | New Models | New Repos | Complexity |
|--------|------|---------|-------------|------------|-----------|-----------|
| F1 | Infrastructure + Auth | 4 | 6 | 4 | 2 | Medium |
| F2 | Community Feed | 4 | 5 | 6 | 3 | High |
| F3 | Events | 5 | 4 | 6 | 3 | Medium |
| F4 | Polls | 3 | 3 | 6 | 1 | Medium |
| F5 | Growth + Recognition | 6 | 5 | 12 | 3 | Medium |
| F6 | Notifications + Analytics | 4 | 4 | 6 | 2 | Medium |
| F7 | Profile + Settings | 3 | 2 | 0 | 0 | Low |
| F8 | Admin | 5 | 3 | 4 | 1 | Medium |
| **Total** | | **34** | **32** | **44** | **15** | |

---

## 4. Dependency Graph

```
F1 (Auth) ──────────────┐
                         ▼
F2 (Feed) ──────────► F3 (Events) ──► F4 (Polls)
                         │
                         ▼
                      F5 (Growth + Recognition)
                         │
F6 (Notifications) ◄─────┘
F7 (Profile) ◄── F1 (shares profile_repository)
F8 (Admin) ◄── F1 (auth guard)
```

- F1 must go first (auth is prerequisite for everything)
- F2 should go second (feed is the app's home screen)
- F3-F5 can be parallelized after F2 if multiple developers are available
- F6 can start after F1 (notification infrastructure) but benefits from having content screens
- F7 can start anytime after F1
- F8 goes last (low priority, admin-only)

---

## 5. Cumulative Totals

| Metric | Count |
|--------|-------|
| Total screens | **34** |
| Reusable widgets | **~32** |
| Riverpod providers | **~40** |
| Repositories | **15** |
| DTOs | **22** |
| Domain models | **22** |
| Services | **4** |
| Realtime channels | **7** |
| Feature modules | **10** |
| Sprints | **8** |

---

## 6. Infrastructure Prerequisites

These must be completed before Sprint F1 starts:

| # | Task | Status |
|---|------|--------|
| 1 | Storage bucket `avatars` — configure RLS policies | Pending |
| 2 | Storage bucket `post-images` — configure RLS policies | Pending (needed by F2) |
| 3 | Realtime replication on 8 tables | Pending (needed by F2+) |
| 4 | FCM server key configuration | Pending (deferred — inbox works without push) |
| 5 | Inter font files placed in `assets/fonts/` | Pending (optional — system font works) |
| 6 | Firebase `google-services.json` / `GoogleService-Info.plist` | Required for FCM |

Items 1-3 are Supabase configuration, not code. They can be done in a single setup session before F1.
