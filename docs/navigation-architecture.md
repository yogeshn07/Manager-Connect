# Navigation Architecture

## Overview

Manager Connect uses **GoRouter** for all navigation. GoRouter is a declarative, URL-based routing package for Flutter that supports deep linking, redirect guards, and nested navigation via `ShellRoute`. The persistent 5-tab bottom navigation bar is implemented as a GoRouter `ShellRoute` wrapping the five main tab destinations.

**Framework:** Flutter + GoRouter (`go_router` package)  
**Pattern:** URL-first, declarative routing with `redirect` callbacks for auth and role guards  
**Refresh mechanism:** `GoRouterRefreshStream` connected to `authStateStream` — router re-evaluates all guards automatically on login, logout, or session change

---

## Route Tree

```
/                                → Redirect: /feed (authenticated) or /welcome (no session)

── Auth Group (unauthenticated only) ──────────────────────────────────────────
  /welcome                       → WelcomeScreen (invite prompt + OTP request)
  /verify-otp                    → VerifyOtpScreen (6-digit OTP entry)
  /create-profile                → CreateProfileScreen (first-time profile setup)

── App Group (authenticated — ShellRoute, 5-tab bottom nav) ───────────────────
  /feed                          → FeedScreen                (Tab 1)
  /events                        → EventsScreen              (Tab 2)
  /growth                        → GrowthScreen              (Tab 3)
  /analytics                     → AnalyticsScreen           (Tab 4)
  /profile                       → OwnProfileScreen          (Tab 5)

── Stack Routes (push on top of any active tab) ───────────────────────────────
  /event/:id                     → EventDetailScreen
  /event/:id/poll/:pollId        → PollDetailScreen
  /challenge/:id                 → ChallengeDetailScreen
  /recognition/:id               → RecognitionDetailScreen
  /analytics/ranking             → FullRankingsScreen
  /profile/:id                   → MemberProfileScreen
  /notifications                 → NotificationsScreen

── Admin Group (authenticated + role == 'admin') ──────────────────────────────
  /admin                         → AdminOverviewScreen
  /admin/members                 → AdminMembersScreen
  /admin/flagged                 → AdminFlaggedScreen
  /admin/announcements           → AdminAnnouncementsScreen
  /admin/attendance              → AdminAttendanceScreen
  /admin/connect-buddy           → AdminConnectBuddyScreen
```

---

## Tab Bar (Persistent — ShellRoute)

Five-tab `NavigationBar` (Material 3) rendered by `MainScaffold`. Always visible to authenticated members. The Admin section is accessed via the Profile tab menu — it is not a tab in the main tab bar.

| Tab | Label | Route | Badge |
|-----|-------|-------|-------|
| 1 | Feed | `/feed` | New unread Connect Buddy posts indicator |
| 2 | Events | `/events` | Upcoming event within next 24h indicator |
| 3 | Growth | `/growth` | Active challenge count |
| 4 | Analytics | `/analytics` | — |
| 5 | Profile | `/profile` | Notification bell unread count |

---

## Route Guards

Three guard outcomes evaluated in GoRouter's `redirect` callback:

| Condition | Redirect To |
|-----------|-------------|
| No session → any app route | `/welcome` |
| Session + `onboarding_completed = false` → any app route | `/create-profile` |
| Admin route + `app_role != 'admin'` | `/feed` |
| Authenticated user → auth route (`/welcome`, `/verify-otp`) | `/feed` |

`GoRouterRefreshStream` is wired to `authStateStream` in `shared/providers/auth_state_provider.dart`. The router automatically re-evaluates `redirect` on every auth state change (login, logout, deactivation).

---

## Navigation Patterns

### Stack Navigation

Tapping a card or item from any tab pushes a detail screen onto the current tab's stack. A back chevron is shown in the AppBar. Used for:

| Screen | Route |
|--------|-------|
| Event detail | `/event/:id` |
| Poll detail | `/event/:id/poll/:pollId` |
| Challenge detail | `/challenge/:id` |
| Recognition detail | `/recognition/:id` |
| Member profile | `/profile/:id` |
| Full rankings | `/analytics/ranking` |
| Notification inbox | `/notifications` |

### Modals (Bottom Sheet)

Action flows presented as `DraggableScrollableSheet` bottom sheets. They do not create new routes — they are shown using `context.showMcBottomSheet(builder)` over the current screen context. Back navigation dismisses the sheet and returns to the originating screen.

| Action | Launched From |
|--------|--------------|
| Create Post | Feed tab FAB |
| Create Event | Events tab FAB |
| Create Challenge | Growth tab FAB |
| Create Poll | Event Detail screen |
| Give Recognition | Analytics / Recognition screen |
| Log Progress | Challenge Detail screen |
| RSVP selector | Event Detail screen |
| Notification Preferences | Profile tab settings |
| Invite Member (admin) | Admin Members screen |
| Record Attendance (admin) | Admin Attendance screen |
| Trigger Connect Buddy Post (admin) | Admin Connect Buddy screen |

### Admin Navigation

The Admin panel is accessed from the Profile tab via a "Admin Panel" menu item — it is not a persistent tab. Admin routes use a nested GoRouter group (`/admin/...`) with a role guard that redirects non-admin users to `/feed`. Admin route changes do not affect the member's active tab state.

---

## Deep Link Strategy

Every push notification tap deep-links to the relevant content screen via GoRouter. `FirebaseMessaging.onMessageOpenedApp` and `getInitialMessage` (cold start) both route via `context.go(targetScreen)`.

| Notification Type (`NotificationType` enum) | GoRouter Path |
|---------------------------------------------|---------------|
| `activity_created` | `/events` |
| `activity_reminder_24h` | `/event/:id` |
| `activity_reminder_1h` | `/event/:id` |
| `activity_cancelled` | `/event/:id` |
| `activity_updated` | `/event/:id` |
| `poll_reminder` | `/event/:id/poll/:pollId` |
| `recognition_received` | `/recognition/:id` |
| `challenge_created` | `/growth` |
| `challenge_ending` | `/challenge/:id` |
| `challenge_ended` | `/challenge/:id` |
| `mention` | `/feed` |
| `comment_on_post` | `/feed` |
| `connect_buddy_update` | `/feed` |
| `admin_flag` | `/admin/flagged` |
| `admin_member_registered` | `/admin/members` |

Deep link edge cases handled by `deep_link_service.dart` in `shared/services/`:
- **Deleted content:** Screen shows "not found" state; back navigation returns to parent tab
- **Unauthenticated tap:** Notification tap is held; after login completes, navigate to target
- **Non-existent ID:** `eventDetailProvider.family` returns `NotFoundFailure`; screen shows error state

---

## Back Navigation Behavior

- The back button always returns to the previously visited screen in the current stack.
- Closing a modal (bottom sheet) always returns to the screen that launched it.
- Deep-linked screens opened from a push notification use a back button that returns to the relevant tab root (not the notification origin screen). Example: tapping an event reminder notification while on the Growth tab, then pressing back, returns to `/events` — not `/growth`.
- Navigating between tabs does not clear the stack state of the previously visited tab (`StatefulShellRoute` preserves per-tab navigation state).

---

## GoRouter Implementation Notes

**File locations:**
- Route tree: `lib/core/router/app_router.dart`
- Router provider: `lib/core/router/router_provider.dart` (`@riverpod GoRouter appRouter(...)`)
- Guard functions: `lib/core/router/route_guards.dart`
- Route name constants: `lib/core/constants/route_names.dart`

**Route name constants (`RouteNames`):**

| Constant | Value |
|----------|-------|
| `RouteNames.welcome` | `/welcome` |
| `RouteNames.verifyOtp` | `/verify-otp` |
| `RouteNames.createProfile` | `/create-profile` |
| `RouteNames.feed` | `/feed` |
| `RouteNames.events` | `/events` |
| `RouteNames.growth` | `/growth` |
| `RouteNames.analytics` | `/analytics` |
| `RouteNames.profile` | `/profile` |
| `RouteNames.eventDetail` | `/event/:id` |
| `RouteNames.pollDetail` | `/event/:id/poll/:pollId` |
| `RouteNames.challengeDetail` | `/challenge/:id` |
| `RouteNames.recognitionDetail` | `/recognition/:id` |
| `RouteNames.fullRankings` | `/analytics/ranking` |
| `RouteNames.memberProfile` | `/profile/:id` |
| `RouteNames.notifications` | `/notifications` |
| `RouteNames.admin` | `/admin` |
| `RouteNames.adminMembers` | `/admin/members` |
| `RouteNames.adminFlagged` | `/admin/flagged` |
| `RouteNames.adminAnnouncements` | `/admin/announcements` |
| `RouteNames.adminAttendance` | `/admin/attendance` |
| `RouteNames.adminConnectBuddy` | `/admin/connect-buddy` |
