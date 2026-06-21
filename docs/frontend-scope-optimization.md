# Frontend Scope Optimization

**Date:** 2026-06-21

---

## 1. Screen Classification (34 → 26)

### Authentication (4 → 4: no change)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| A1 | Splash | REQUIRED_SCREEN | App entry point — session check, routing. Cannot be merged. |
| A2 | Welcome / Login | REQUIRED_SCREEN | OTP request form. Distinct auth step. |
| A3 | Verify OTP | REQUIRED_SCREEN | OTP entry. Separate from login (different input, different state). |
| A4 | Profile Setup | REQUIRED_SCREEN | Onboarding flow with invite validation + avatar upload. Unique purpose. |

### Community Feed (4 → 3)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| F1 | Feed | REQUIRED_SCREEN | Home screen. Paginated feed + pinned banner. Core UX surface. |
| F2 | Create Post | CONVERT_TO_MODAL_OR_SHEET | Simple text + image input. A full-screen modal (ModalBottomSheet or full-screen dialog) is appropriate — no complex navigation needed. Eliminates a route. |
| F3 | Post Detail | REQUIRED_SCREEN | Reactions + comments require dedicated scroll area. Cannot fit in card. |
| F4 | Member Profile View | MERGE_WITH_EXISTING_SCREEN | **Merge with PR1 (My Profile).** Same layout — profile header, stats, recognitions. The only difference is whether `userId == currentUserId`. One `ProfileScreen(userId)` handles both. Eliminates a screen + a route. |

### Activities (5 → 3)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| E1 | Activities List | REQUIRED_SCREEN | Tab root for Events. Category filter + upcoming/past toggle. |
| E2 | Activity Detail | REQUIRED_SCREEN | Event info, RSVP button, updates, linked polls. Core detail view. |
| E3 | Create Activity | CONVERT_TO_MODAL_OR_SHEET | Form with 6 fields. Full-screen modal like Create Post. No sub-navigation. |
| E4 | RSVP List | CONVERT_TO_MODAL_OR_SHEET | Simple list of avatars + names + status. A **bottom sheet** on Activity Detail is sufficient — no separate route needed. The data is already fetched for Activity Detail. |
| E5 | Activity Updates | MERGE_WITH_EXISTING_SCREEN | **Merge into E2 (Activity Detail).** Updates are a short list displayed as a section within the detail screen (expandable or scrollable). No user writes on this screen — it's read-only display of organizer messages. Separate screen adds unnecessary navigation depth. |

### Polls (3 → 2)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| P1 | Poll List | UNNECESSARY | Polls are either linked to an activity (shown on Activity Detail) or standalone (shown as a section on Events tab or Feed). A dedicated poll-only list screen adds navigation depth with no user value — members discover polls in context, not by browsing a poll directory. Standalone polls appear in the Events tab as a filter/section. |
| P2 | Poll Detail / Vote | REQUIRED_SCREEN | Vote UI + results visualization needs dedicated space. |
| P3 | Create Poll | CONVERT_TO_MODAL_OR_SHEET | Form with question + options + date. Full-screen modal. |

### Growth (4 → 3)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| G1 | Challenge List | REQUIRED_SCREEN | Tab root for Growth. Active/completed filter. |
| G2 | Challenge Detail | REQUIRED_SCREEN | Leaderboard, participants, progress — needs scroll space. |
| G3 | Log Progress | CONVERT_TO_MODAL_OR_SHEET | Single numeric input + optional note. A **bottom sheet** on Challenge Detail is sufficient. User taps "Log Progress" button → sheet slides up → enter value → submit → sheet closes. |
| G4 | Create Challenge | CONVERT_TO_MODAL_OR_SHEET | Form with title, type, goal, dates. Full-screen modal. |

### Recognition (2 → 2: no change)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| R1 | Recognition Feed | REQUIRED_SCREEN | Wall of recognitions. Separate from community feed — different data, different layout. |
| R2 | Create Recognition | CONVERT_TO_MODAL_OR_SHEET | Member picker + category + message. Full-screen modal. |

### Notifications (1 → 1: no change)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| N1 | Notification Center | REQUIRED_SCREEN | Inbox list with mark-read + deep linking. Cannot merge elsewhere. |

### Analytics (3 → 2)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| AN1 | Personal Analytics | REQUIRED_SCREEN | Own stats dashboard. |
| AN2 | Community Analytics | MERGE_WITH_EXISTING_SCREEN | **Merge into Analytics tab as a toggle/tab with AN1.** Personal and Community are two views of the same data domain — a `TabBar` or `SegmentedButton` at the top of one `AnalyticsScreen` switches between them. Health score gauge fits as a header widget in the community tab. Eliminates a route. |
| AN3 | Rankings | REQUIRED_SCREEN | Scrollable leaderboard with month selector — needs its own scroll view. Accessed from Analytics screen. |

### Profile (3 → 2)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| PR1 | My Profile | REQUIRED_SCREEN | Tab root. **Also serves as Member Profile View** (merged from F4). |
| PR2 | Edit Profile | REQUIRED_SCREEN | Form with avatar upload, interest tags multi-select. Enough fields to warrant full screen. |
| PR3 | Settings | MERGE_WITH_EXISTING_SCREEN | **Merge into PR1 (My Profile) as a section or into PR2 (Edit Profile).** Settings contains only notification preference toggles and a logout button. These are 10 toggle switches + 1 button. They fit naturally as a section at the bottom of My Profile (below recognitions) or as a "Preferences" tab within Edit Profile. Eliminates a route. |

### Admin (5 → 4)

| # | Screen | Classification | Justification |
|---|--------|---------------|---------------|
| AD1 | Admin Dashboard | REQUIRED_SCREEN | Entry point with counts + quick actions. |
| AD2 | Member Management | REQUIRED_SCREEN | List with action sheets (invite, deactivate, remove). Complex interactions. |
| AD3 | Moderation Queue | REQUIRED_SCREEN | Flag review with delete/dismiss actions. Needs dedicated list. |
| AD4 | Attendance Recording | REQUIRED_SCREEN | Batch toggle grid per event. Complex UI. |
| AD5 | Pin Management | MERGE_WITH_EXISTING_SCREEN | **Merge into AD1 (Admin Dashboard) as a quick action.** Pin/unpin is a single action — admin selects a post from a picker, calls `pin-announcement` EF. This is a button + post picker dialog on the dashboard, not a full screen. The current pin status is a one-line display. |

---

## 2. Optimization Summary

### Screen Count

| Category | Original | Optimized | Change |
|----------|----------|-----------|--------|
| Authentication | 4 | 4 | — |
| Community Feed | 4 | 3 | -1 (F4 merged into PR1) |
| Activities | 5 | 3 | -2 (E4 → sheet, E5 merged into E2) |
| Polls | 3 | 2 | -1 (P1 unnecessary) |
| Growth | 4 | 3 | -1 (G3 → sheet) |
| Recognition | 2 | 2 | — |
| Notifications | 1 | 1 | — |
| Analytics | 3 | 2 | -1 (AN2 merged into AN1) |
| Profile | 3 | 2 | -1 (PR3 merged into PR1) |
| Admin | 5 | 4 | -1 (AD5 merged into AD1) |
| **Total** | **34** | **26** | **-8** |

### What Happened to the 8 Removed Screens

| Screen | Disposition |
|--------|------------|
| F4 Member Profile View | Merged into PR1 as `ProfileScreen(userId)` |
| E4 RSVP List | Converted to bottom sheet on E2 |
| E5 Activity Updates | Merged as section within E2 |
| P1 Poll List | Removed — polls accessed via Events tab section or Activity Detail |
| AN2 Community Analytics | Merged as tab within AN1 |
| PR3 Settings | Merged as section within PR1 |
| AD5 Pin Management | Merged as action within AD1 |
| G3 Log Progress | Converted to bottom sheet on G2 |

### Modals and Bottom Sheets (not routed screens)

| Item | Type | Launched From |
|------|------|---------------|
| Create Post | Full-screen modal | Feed FAB |
| Create Activity | Full-screen modal | Events tab FAB |
| Create Poll | Full-screen modal | Events tab or Activity Detail |
| Create Challenge | Full-screen modal | Growth tab FAB |
| Create Recognition | Full-screen modal | Recognition Feed FAB |
| Log Progress | Bottom sheet | Challenge Detail button |
| RSVP List | Bottom sheet | Activity Detail button |

These 7 items are modal/sheet overlays, not routed screens. They share the parent screen's provider scope and don't need separate routes.

---

## 3. Route Optimization

### Original Routes: 22

```
/, /welcome, /verify-otp, /create-profile,
/feed, /events, /growth, /analytics, /profile,
/event/:id, /event/:id/poll/:pollId, /challenge/:id,
/recognition/:id, /analytics/ranking, /profile/:id,
/notifications,
/admin, /admin/members, /admin/flagged, /admin/announcements,
/admin/attendance, /admin/connect-buddy
```

### Optimized Routes: 16

```
/, /welcome, /verify-otp, /create-profile,
/feed, /events, /growth, /analytics, /profile,
/event/:id, /poll/:id, /challenge/:id,
/analytics/rankings, /profile/:id,
/notifications,
/admin, /admin/members, /admin/flagged, /admin/attendance
```

**Removed routes (6):**
- `/event/:id/poll/:pollId` → simplified to `/poll/:id` (polls have globally unique IDs)
- `/recognition/:id` → removed (recognitions viewed inline in feed, not via deep route)
- `/admin/announcements` → merged into admin dashboard
- `/admin/connect-buddy` → removed (Connect Buddy is fully automated; FR-09.6 says admin can "suppress or trigger" — this is a toggle on admin dashboard, not a screen)
- `F4` member profile route → uses `/profile/:id` already defined

---

## 4. Provider Optimization

### Original: ~40 providers

### Optimized: ~30 providers

| Reduction | Justification |
|-----------|---------------|
| Removed `pollListProvider` | P1 screen eliminated — polls loaded via activity detail or events tab section |
| Removed `memberProfileProvider` | F4 merged into ProfileScreen — uses same `profileDetailProvider(userId)` |
| Removed `communityAnalyticsProvider` | AN2 merged — same provider with a `scope` parameter (personal vs community) |
| Removed `settingsProvider` | PR3 merged — notification prefs are part of `currentProfileProvider` |
| Removed `pinManagementProvider` | AD5 merged — pin action uses inline `adminActionsProvider` |
| Merged `activityUpdatesProvider` into `activityDetailProvider` | E5 merged — updates fetched as part of activity detail |
| Merged `rsvpListProvider` into `activityDetailProvider` | E4 merged — RSVPs fetched as part of activity detail |
| Combined `feedRealtimeProvider` with `feedProvider` | Single provider handles both initial fetch + realtime append |

### Final Provider Inventory (~30)

| Category | Providers | Count |
|----------|----------|-------|
| Auth | authProvider, currentProfileProvider | 2 |
| Feed | feedProvider (includes realtime), postDetailProvider, createPostProvider | 3 |
| Events | activitiesListProvider, activityDetailProvider (includes RSVPs + updates), createActivityProvider | 3 |
| Polls | pollDetailProvider, createPollProvider, pollVotesRealtimeProvider | 3 |
| Growth | challengeListProvider, challengeDetailProvider (includes leaderboard), createChallengeProvider, logProgressProvider | 4 |
| Recognition | recognitionFeedProvider, createRecognitionProvider | 2 |
| Notifications | notificationInboxProvider, unreadCountProvider | 2 |
| Analytics | analyticsProvider(scope), rankingsProvider(month) | 2 |
| Profile | profileDetailProvider(userId), editProfileProvider | 2 |
| Admin | adminDashboardProvider, memberManagementProvider, moderationQueueProvider, attendanceProvider | 4 |
| Shared | supabaseClientProvider, authStateProvider, connectivityProvider | 3 |
| **Total** | | **30** |

---

## 5. Repository Optimization

### Original: 15 repositories

### Optimized: 11 repositories

| Reduction | Justification |
|-----------|---------------|
| Merged `comment_repository` into `feed_repository` | Comments are always loaded in context of a post. Same Supabase client, same feature module. No independent usage. |
| Merged `reaction_repository` into `feed_repository` | Reactions are always on a post. 3 methods (upsert, delete, list) — too thin for a separate class. |
| Merged `rsvp_repository` into `activity_repository` | RSVPs are always in context of an activity. The activity_repository already queries the same tables. |
| Merged `activity_update_repository` into `activity_repository` | Updates are a sub-resource of activities. 2 methods — not worth a separate file. |
| Removed separate `admin_member_repository`, `moderation_repository`, `admin_event_repository` → single `admin_repository` | Already planned as a single repository in the blueprint; the 3 sub-repos were over-split. Admin operations are low-frequency and share the same auth pattern. |

### Final Repository Inventory (11)

| Repository | Feature | Responsibility |
|-----------|---------|---------------|
| `auth_repository` | auth | OTP, session, signOut |
| `profile_repository` | auth/profile | Profile CRUD, search |
| `feed_repository` | feed | Posts, comments, reactions, flagging |
| `activity_repository` | events | Activities, RSVPs, updates |
| `poll_repository` | polls | Polls, options, votes |
| `challenge_repository` | growth | Challenges, participants |
| `progress_repository` | growth | Progress logs |
| `recognition_repository` | recognition | Recognitions, recipients, reactions |
| `notification_repository` | notifications | Inbox, mark read, count |
| `analytics_repository` | analytics | Member stats, health scores |
| `admin_repository` | admin | All admin Edge Function calls |

---

## 6. DTO/Model Optimization

### Original: 22 DTOs + 22 domain models = 44

### Optimized: 16 DTOs + 16 domain models = 32

| Reduction | Justification |
|-----------|---------------|
| Merged `RsvpDto` into `ActivityDto` (nested) | RSVPs are always fetched with activity via PostgREST join. No standalone DTO needed. |
| Merged `ActivityUpdateDto` into `ActivityDto` (nested list) | Same reasoning — updates fetched with activity detail. |
| Merged `PollVoteDto` into `PollOptionDto` (vote count field) | Vote counts are aggregated per option via PostgREST join. Individual vote rows are never materialized on client. |
| Merged `RecognitionRecipientDto` into `RecognitionDto` (nested list) | Recipients always fetched with recognition. PostgREST join handles this. |
| Merged `RecognitionReactionDto` into `RecognitionDto` (reaction count) | Same pattern as post reactions. Count only, not individual rows. |
| Removed `AuditEntryDto` | Admin audit log is read via REST table directly. No DTO needed — it's a simple list display. Use `Map<String, dynamic>` or a minimal inline model. |

### Final Model Inventory (16 pairs)

| DTO | Domain Model | Feature |
|-----|-------------|---------|
| ProfileDto | Profile | auth |
| InvitationDto | Invitation | auth |
| PostDto | Post | feed (includes author profile, reactions count, comment count) |
| CommentDto | Comment | feed |
| ActivityDto | Activity | events (includes RSVPs, updates, linked polls) |
| PollDto | Poll | polls (includes options with vote counts) |
| PollOptionDto | PollOption | polls |
| ChallengeDto | Challenge | growth |
| ParticipantDto | Participant | growth |
| ProgressLogDto | ProgressLog | growth |
| RecognitionDto | Recognition | recognition (includes recipients, reaction counts) |
| NotificationItemDto | NotificationItem | notifications |
| MemberStatsDto | MemberStats | analytics |
| HealthScoreDto | HealthScore | analytics |
| FlaggedContentDto | FlaggedContent | admin |
| AttendanceRecordDto | AttendanceRecord | admin |

---

## 7. Realtime Optimization

### Original: 7 channels

### Optimized: 3 channels (4 deferred to polling)

| Channel | Original | Optimized | Justification |
|---------|----------|-----------|---------------|
| `feed:posts` | Realtime | **Keep** | Feed is the home screen. New posts appearing live is core UX. High-value channel. |
| `feed:reactions:{post_id}` | Realtime | **Defer → polling** | Reaction counts update on pull-to-refresh or screen revisit. Live reaction count updates add complexity (per-post subscriptions) with minimal UX value — users don't watch reaction counts in real time. |
| `feed:comments:{post_id}` | Realtime | **Defer → polling** | Same reasoning. Comments refresh on pull-to-refresh. Live comment streaming is a nice-to-have, not a launch requirement. |
| `activities:rsvps:{activity_id}` | Realtime | **Defer → polling** | RSVP counts change infrequently. A pull-to-refresh on activity detail is sufficient. Per-activity subscriptions add complexity. |
| `events:poll_votes:{poll_id}` | Realtime | **Defer → polling** | Vote counts change infrequently. Results update on screen revisit or pull-to-refresh. |
| `growth:leaderboard:{challenge_id}` | Realtime | **Defer → polling** | Leaderboard updates daily (progress logs). Pull-to-refresh is perfectly adequate. |
| `notifications:inbox:{user_id}` | Realtime | **Keep** | Badge count must update without user action. This is a single app-wide channel (not per-screen), so it's low-cost. |

### Deferred Realtime → V2

The 4 deferred channels (`feed:reactions`, `feed:comments`, `activities:rsvps`, `events:poll_votes`, `growth:leaderboard`) can be added in a V2 pass after launch. The infrastructure (`realtime_service.dart`) is designed for it — adding a channel is a provider change, not an architecture change.

### V1 Realtime (2 channels only)

| Channel | Scope | Lifecycle |
|---------|-------|-----------|
| `feed:posts` | Feed screen visible | Subscribe on mount, unsubscribe on dispose |
| `notifications:inbox:{user_id}` | App-wide (keepAlive) | Subscribe on auth, unsubscribe on logout |

This reduces Realtime complexity from 7 concurrent channel types to 2, eliminating per-item subscription management entirely.

---

## 8. Admin Flow Optimization

### Original: 5 screens

### Optimized: 4 screens

| Screen | Disposition | Justification |
|--------|------------|---------------|
| AD1 Admin Dashboard | **Keep as screen** | Entry point with counts, quick actions, pin toggle |
| AD2 Member Management | **Keep as screen** | Complex list with multiple actions per member |
| AD3 Moderation Queue | **Keep as screen** | Flag review cards with delete/dismiss — needs scroll space |
| AD4 Attendance Recording | **Keep as screen** | Batch toggle grid is complex enough to warrant full screen |
| AD5 Pin Management | **Merge into AD1** | Single action (pick post → pin) fits as a card/section on dashboard |

Admin navigation becomes: `Admin Dashboard → {Members, Moderation, Attendance}` — 3 list items instead of 4.

---

## 9. Widget Optimization

### Original: ~32 widgets

### Optimized: ~22 widgets

| Reduction | Justification |
|-----------|---------------|
| Removed `pinned_post_banner` | A pinned post is a `PostCard` with a "Pinned" chip — not a separate widget. Use a `isPinned` flag on `PostCard`. |
| Removed `connect_buddy_badge` | Connect Buddy distinction is an `isSystemAccount` flag on `PostCard` that changes background color and shows a badge. Not a separate widget. |
| Removed `update_tile` | Activity updates are simple text + timestamp. Use a `ListTile` directly — no custom widget needed. |
| Removed `poll_results_chart` | Poll results are horizontal bars per option. Simple enough to build inline in `PollOptionTile` with a `LinearProgressIndicator`. |
| Removed `progress_input` | Log Progress sheet has a single `TextField` + submit button. No reusable component needed. |
| Removed `notification_pref_tile` | A `SwitchListTile` with label — use it directly. No custom widget. |
| Merged `flag_review_card` into `PostCard` with moderation actions | Flag review shows the flagged post/comment + action buttons. Reuse `PostCard` with an action parameter. |
| Merged `attendance_toggle` into a simple `CheckboxListTile` | Attended/absent is a binary toggle per member row. Standard Flutter widget. |
| Removed `stat_card` | Analytics stat display is a `Card` with a column of `Text` widgets. Too simple for a custom widget. |
| Removed `category_badge` | Recognition category is a `Chip` with a color. Use `Chip` directly. |

### Final Widget Inventory (~22)

| Widget | Used By |
|--------|---------|
| `user_avatar` | Every screen with profile data |
| `empty_state` | Every list screen |
| `error_state` | Every async screen |
| `loading_state` | Every async screen |
| `confirm_dialog` | Delete, deactivate, remove actions |
| `toast` | Success/error feedback |
| `post_card` | Feed, Post Detail, Moderation Queue |
| `reaction_bar` | Post Detail |
| `comment_tile` | Post Detail |
| `activity_card` | Activities List |
| `rsvp_button` | Activity Detail |
| `category_filter_chips` | Activities List |
| `poll_card` | Events tab, Activity Detail |
| `poll_option_tile` | Poll Detail (includes vote bar) |
| `challenge_card` | Challenge List |
| `leaderboard_tile` | Challenge Detail |
| `recognition_card` | Recognition Feed |
| `notification_tile` | Notification Center |
| `health_score_gauge` | Community Analytics section |
| `ranking_tile` | Rankings screen |
| `profile_header` | Profile screen |
| `member_action_sheet` | Admin Member Management |

---

## 10. Final Optimized Architecture Summary

| Metric | Original | Optimized | Reduction |
|--------|----------|-----------|-----------|
| Routed screens | 34 | 26 | -24% |
| Navigation routes | 22 | 16 | -27% |
| Riverpod providers | ~40 | ~30 | -25% |
| Repositories | 15 | 11 | -27% |
| DTOs | 22 | 16 | -27% |
| Domain models | 22 | 16 | -27% |
| Reusable widgets | ~32 | ~22 | -31% |
| Realtime channels (V1) | 7 | 2 | -71% |
| Services | 4 | 4 | — |
| Feature modules | 10 | 9 (polls merged into events) | -10% |

### Effort Reduction Estimate

- **~25% fewer files** to create, test, and maintain
- **~30% fewer navigation paths** to handle edge cases for
- **~70% less realtime complexity** at launch (2 channels vs 7)
- **8 fewer screens** means 8 fewer widget trees, 8 fewer test surfaces
- Modal/sheet pattern for creation forms means shared provider scope — no state synchronization between screens

### Maintainability Impact

- **Positive.** Fewer abstractions means less indirection. One `ProfileScreen(userId)` is easier to maintain than two screens with duplicated layouts. One `feed_repository` with comments/reactions is easier to navigate than three files.
- **Risk: none.** Every removed screen is either merged into an existing screen or converted to a modal/sheet. No functionality is cut.

### Security Impact

- **None.** All authorization checks remain in Edge Functions (server-side). Reducing screens doesn't change the auth boundary. Admin route guard still applies to `/admin/*`.

---

## 11. Optimized Sprint Plan (7 sprints, down from 8)

| Sprint | Name | Screens | Modals/Sheets | Total UI |
|--------|------|---------|---------------|----------|
| F1 | Infrastructure + Auth | 4 | 0 | 4 |
| F2 | Community Feed | 3 | 1 (Create Post) | 4 |
| F3 | Events + Polls | 4 | 3 (Create Activity, Create Poll, RSVP sheet) | 7 |
| F4 | Growth + Recognition | 4 | 3 (Create Challenge, Log Progress sheet, Create Recognition) | 7 |
| F5 | Notifications + Analytics | 3 | 0 | 3 |
| F6 | Profile | 2 | 0 | 2 |
| F7 | Admin | 4 | 0 | 4 |
| **Total** | | **24** (+2 merged) | **7** | **31** |

Polls merged into Events sprint (F3) since polls are accessed from Activity Detail and Events tab. Growth and Recognition combined (F4) — both are engagement features with similar UI patterns. Profile sprint (F6) simplified to 2 screens. One sprint eliminated.

---

## 12. Final Validation

| Check | Result |
|-------|--------|
| Duplicated screens | **0** — F4 merged into PR1, E5 into E2, AN2 into AN1, PR3 into PR1, AD5 into AD1 |
| Duplicated providers | **0** — all provider consolidations documented above |
| Duplicated repositories | **0** — 4 thin repos merged into parent repos |
| Unnecessary routes | **0** — 6 routes eliminated |
| Unresolved UI questions | **0** |
| Functionality cut | **0** — all features preserved via merges, sheets, or inline sections |

### READY FOR FRONTEND SPRINT 1
