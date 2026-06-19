# Navigation Flow Diagrams — Manager Connect

## Overview

This document maps every navigation path in the Manager Connect application. It covers the complete route tree, tab navigation, stack navigation, modal flows, deep linking, and back navigation behavior. All routes reference the GoRouter architecture defined in `navigation-architecture.md`.

---

## 1. Master Navigation Map

```
                          ┌──────────┐
                          │ App Start│
                          └────┬─────┘
                               │
                          ┌────▼─────┐
                          │ Splash / │
                          │ Route:   │
                          │   "/"    │
                          └────┬─────┘
                               │
               ┌───────────────┼───────────────┐
               │               │               │
          No Session     Valid Session    Deactivated
               │               │               │
               ▼               │               ▼
        ┌──────────┐           │        ┌──────────────┐
        │ /welcome │           │        │ Access Denied│
        │AUTH-001  │           │        │  UTIL-002    │
        └────┬─────┘           │        └──────────────┘
             │                 │
             ▼                 │
        ┌──────────┐           │
        │/verify-  │           │
        │ otp      │           │
        │AUTH-002  │           │
        └────┬─────┘           │
             │                 │
     ┌───────┼───────┐        │
     │               │        │
  New User     Returning      │
     │          User          │
     ▼               │        │
┌──────────┐         │        │
│/create-  │         │        │
│ profile  │         │        │
│AUTH-003  │         │        │
└────┬─────┘         │        │
     │               │        │
     └───────┬───────┘        │
             │                │
             ▼                ▼
    ┌────────────────────────────────────────────────────┐
    │              SHELL ROUTE (MainScaffold)             │
    │            5-Tab Bottom Navigation Bar              │
    │                                                    │
    │  ┌──────┐ ┌──────┐ ┌──────┐ ┌─────────┐ ┌──────┐ │
    │  │Feed  │ │Events│ │Growth│ │Analytics│ │Profile│ │
    │  │Tab 1 │ │Tab 2 │ │Tab 3 │ │Tab 4    │ │Tab 5 │ │
    │  │/feed │ │/event│ │/growt│ │/analyti │ │/profi│ │
    │  └──┬───┘ └──┬───┘ └──┬───┘ └───┬─────┘ └──┬───┘ │
    │     │        │        │         │           │     │
    └─────┼────────┼────────┼─────────┼───────────┼─────┘
          │        │        │         │           │
          ▼        ▼        ▼         ▼           ▼
      [Stack   [Stack   [Stack    [Stack      [Stack
       Routes]  Routes]  Routes]   Routes]     Routes]
```

---

## 2. Tab Navigation Flow

### Tab Switching Behavior

```
┌──────────────────────────────────────────────────────────┐
│                    NavigationBar                          │
│                                                          │
│  [Feed]    [Events]    [Growth]    [Analytics]  [Profile]│
│   ●          ○           ○            ○            ○     │
│                                                          │
│  Tap any tab → switch to that tab's root screen          │
│  Per-tab stack state preserved (StatefulShellRoute)      │
│  Re-tap active tab → pop to tab root                     │
│                                                          │
│  Tab badges:                                             │
│  • Feed: dot (new CB posts)                              │
│  • Events: dot (event within 24h)                        │
│  • Growth: count (active challenges)                     │
│  • Analytics: none                                       │
│  • Profile: count (unread notifications)                 │
└──────────────────────────────────────────────────────────┘
```

### Tab Root Screens

| Tab | Route | Screen | Screen ID |
|-----|-------|--------|-----------|
| 1 | `/feed` | FeedScreen | SCR-FEED-001 |
| 2 | `/events` | EventsScreen | SCR-EVT-001 |
| 3 | `/growth` | GrowthScreen | SCR-GRO-001 |
| 4 | `/analytics` | AnalyticsScreen | SCR-ANA-001 |
| 5 | `/profile` | OwnProfileScreen | SCR-PROF-001 |

---

## 3. Stack Navigation Flows

Stack routes push on top of the current tab, covering the bottom navigation bar.

### 3.1 Feed Stack

```
/feed (SCR-FEED-001)
  │
  ├──→ /profile/:id (SCR-PROF-003)     [tap author avatar]
  │       └──→ (back to Feed)
  │
  ├──→ /notifications (SCR-NOTIF-001)   [tap notification bell]
  │       └──→ (back to Feed)
  │       └──→ [target screen]          [tap notification item]
  │
  └──→ [Bottom Sheet: Create Post]       [tap FAB]
        └──→ (dismiss → Feed)
```

### 3.2 Events Stack

```
/events (SCR-EVT-001)
  │
  ├──→ /event/:id (SCR-EVT-002)         [tap event card]
  │       │
  │       ├──→ /event/:id/poll/:pollId   [tap poll in event]
  │       │     (SCR-EVT-003)
  │       │       └──→ (back to Event Detail)
  │       │
  │       ├──→ /profile/:id              [tap attendee avatar]
  │       │     (SCR-PROF-003)
  │       │       └──→ (back to Event Detail)
  │       │
  │       ├──→ [Bottom Sheet: Create Poll]  [event creator action]
  │       │       └──→ (dismiss → Event Detail)
  │       │
  │       └──→ [Bottom Sheet: RSVP]      [tap RSVP button]
  │               └──→ (dismiss → Event Detail)
  │
  └──→ [Bottom Sheet: Create Event]      [tap FAB]
        └──→ (dismiss → Events)
```

### 3.3 Growth Stack

```
/growth (SCR-GRO-001)
  │
  ├──→ /challenge/:id (SCR-GRO-002)     [tap challenge card]
  │       │
  │       ├──→ /profile/:id              [tap leaderboard entry]
  │       │     (SCR-PROF-003)
  │       │       └──→ (back to Challenge Detail)
  │       │
  │       └──→ [Bottom Sheet: Log Progress]  [tap Log Progress]
  │               └──→ (dismiss → Challenge Detail)
  │
  └──→ [Bottom Sheet: Create Challenge]  [tap FAB]
        └──→ (dismiss → Growth)
```

### 3.4 Analytics Stack

```
/analytics (SCR-ANA-001)
  │
  ├──→ /analytics/ranking (SCR-ANA-004)  [View All rankings]
  │       │
  │       └──→ /profile/:id              [tap ranked member]
  │             (SCR-PROF-003)
  │               └──→ (back to Rankings)
  │
  ├──→ /recognition/:id (SCR-ANA-006)   [tap recognition card]
  │       │
  │       └──→ /profile/:id              [tap giver/recipient]
  │             (SCR-PROF-003)
  │               └──→ (back to Recognition Detail)
  │
  └──→ [Bottom Sheet: Give Recognition]  [tap FAB on Recognition tab]
        └──→ (dismiss → Analytics)
```

### 3.5 Profile Stack

```
/profile (SCR-PROF-001)
  │
  ├──→ [Edit Profile] (SCR-PROF-002)     [tap Edit Profile]
  │       └──→ (back/save → Own Profile)
  │
  ├──→ [Notification Preferences]         [tap Notification Preferences]
  │     (SCR-PROF-004)
  │       └──→ (back → Own Profile)
  │
  ├──→ /notifications (SCR-NOTIF-001)    [tap notification bell]
  │       └──→ (back → Own Profile)
  │
  ├──→ /admin (SCR-ADMIN-001)            [tap Admin Panel — admin only]
  │       │
  │       ├──→ /admin/members             (SCR-ADMIN-002)
  │       │       ├──→ /profile/:id       [tap member]
  │       │       ├──→ [Sheet: Invite]    [tap Invite Member]
  │       │       └──→ [Dialog: Deactivate/Remove/Revoke]
  │       │
  │       ├──→ /admin/flagged             (SCR-ADMIN-003)
  │       │       └──→ [Dialog: Delete/Dismiss]
  │       │
  │       ├──→ /admin/announcements       (SCR-ADMIN-004)
  │       │       └──→ [Dialog: Unpin]
  │       │
  │       ├──→ /admin/attendance          (SCR-ADMIN-005)
  │       │       └──→ [Sheet: Record Attendance]
  │       │
  │       └──→ /admin/connect-buddy       (SCR-ADMIN-006)
  │               └──→ [Sheet: Trigger CB Post]
  │
  └──→ [Dialog: Logout] (DLG-010)        [tap Logout]
        └──→ /welcome (session cleared)
```

---

## 4. Modal Flow Diagrams

### 4.1 Bottom Sheet Navigation Pattern

```
[Any Screen with FAB or Action Button]
       │
       ▼ (context.showMcBottomSheet)
┌─────────────────────────────────────┐
│         Bottom Sheet                │
│  ┌─────────────────────────────┐   │
│  │     Drag Handle (32×4px)    │   │
│  ├─────────────────────────────┤   │
│  │     Title (titleLarge)      │   │
│  ├─────────────────────────────┤   │
│  │                             │   │
│  │     Content (form fields)   │   │
│  │                             │   │
│  ├─────────────────────────────┤   │
│  │     Submit Button           │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
       │
       │ Dismiss methods:
       │  • Drag below 50% snap point
       │  • Tap outside sheet
       │  • Back gesture
       │  • Submit success
       │
       ▼
[Return to originating screen]
[No route change — same context]
```

### 4.2 Dialog Navigation Pattern

```
[Action triggering confirmation]
       │
       ▼ (showDialog)
┌─────────────────────────────────────┐
│              Dialog                  │
│  ┌─────────────────────────────┐   │
│  │  Title (headlineSmall)      │   │
│  │  Content (bodyMedium)       │   │
│  │                             │   │
│  │  [Cancel]  [Confirm/Delete] │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
       │
       ├── Cancel → dismiss, return to screen
       │
       └── Confirm → execute action, dismiss
              │
              ▼
       [Screen state updates]
       [Success snackbar shown]
```

---

## 5. Auth Guard Flow

```
[Any navigation event]
       │
       ▼
┌──────────────────────────────────────────┐
│ GoRouter redirect callback               │
│                                          │
│ 1. authNotifier is loading?              │
│    → No redirect (show splash)           │
│                                          │
│ 2. No valid session?                     │
│    → Redirect to /welcome                │
│                                          │
│ 3. Session + onboarding_completed=false? │
│    → Redirect to /create-profile         │
│                                          │
│ 4. Admin route + role != 'admin'?        │
│    → Redirect to /feed                   │
│                                          │
│ 5. Auth route + valid session?           │
│    → Redirect to /feed                   │
│                                          │
│ 6. None of the above?                    │
│    → Allow navigation (no redirect)      │
└──────────────────────────────────────────┘

GoRouterRefreshStream watches authStateStream
→ Auto-re-evaluates on login, logout, deactivation
```

---

## 6. Deep Link Navigation Map

### 6.1 Push Notification → Screen Mapping

```
┌───────────────────────────┐    ┌──────────────────────────┐
│  Notification Payload      │    │  Navigation Target       │
│                           │    │                          │
│  type: activity_created   │───►│  /events                 │
│  type: activity_reminder  │───►│  /event/{targetId}       │
│  type: activity_cancelled │───►│  /event/{targetId}       │
│  type: activity_updated   │───►│  /event/{targetId}       │
│  type: poll_reminder      │───►│  /event/{actId}/poll/{tId}│
│  type: recognition_recv   │───►│  /recognition/{targetId} │
│  type: challenge_created  │───►│  /growth                 │
│  type: challenge_ending   │───►│  /challenge/{targetId}   │
│  type: challenge_ended    │───►│  /challenge/{targetId}   │
│  type: mention            │───►│  /feed                   │
│  type: comment_on_post    │───►│  /feed                   │
│  type: connect_buddy      │───►│  /feed                   │
│  type: admin_flag         │───►│  /admin/flagged          │
│  type: admin_member_reg   │───►│  /admin/members          │
└───────────────────────────┘    └──────────────────────────┘
```

### 6.2 Deep Link Processing Flow

```
[Notification tap]
       │
       ▼
┌──────────────────────────────────────┐
│ deep_link_service.dart               │
│                                      │
│ 1. Extract type + targetId from data │
│ 2. Map type to GoRouter path         │
│ 3. Substitute :id with targetId      │
│ 4. Call context.go(path)             │
│                                      │
│ Edge cases:                          │
│ • Missing targetScreen → /feed       │
│ • Deleted content → Not Found state  │
│ • Unauthenticated → hold, auth first │
│ • Admin route + non-admin → /feed    │
└──────────────────────────────────────┘
```

---

## 7. Back Navigation Behavior

### 7.1 Standard Back Behavior

```
┌───────────────────────────────────────────────────────┐
│ Context                    │ Back Behavior             │
├───────────────────────────────────────────────────────┤
│ Stack screen               │ Pop to previous in stack  │
│ Bottom sheet open          │ Dismiss sheet             │
│ Dialog open                │ Dismiss dialog (if non-   │
│                            │ destructive)              │
│ Destructive dialog         │ Cancel button only        │
│ Tab root (Feed/Events/etc) │ Exit app (Android)        │
│ Deep-linked screen         │ Pop to relevant tab root  │
│   (not previous screen)    │                           │
│ Autocomplete overlay       │ Dismiss overlay           │
└───────────────────────────────────────────────────────┘
```

### 7.2 Deep Link Back Navigation

```
[User on Growth tab, viewing challenge detail]
       │
[Push notification tap → /event/:id]
       │
       ▼
[Event Detail Screen shows]
       │
[User taps back]
       │
       ▼
[Navigate to /events (tab root)]
[NOT back to /challenge/:id (previous screen)]
[Because deep-linked screens use tab-root fallback]
```

### 7.3 Tab Stack Preservation

```
[User navigates: Feed → Post → Author Profile]
       │
[Switches to Events tab]
       │
[Navigates: Events → Event Detail]
       │
[Switches back to Feed tab]
       │
       ▼
[Feed tab restores: Author Profile screen]
[NOT Feed root — stack state preserved]
[StatefulShellRoute maintains per-tab state]
```

---

## 8. Complete Route Table

| Route | Screen | Type | Parent | Guard |
|-------|--------|------|--------|-------|
| `/` | Splash → redirect | Redirect | Root | None |
| `/welcome` | WelcomeScreen | Auth | Root | No session only |
| `/verify-otp` | VerifyOtpScreen | Auth | Root | No session only |
| `/create-profile` | CreateProfileScreen | Auth | Root | Session + !onboarded |
| `/feed` | FeedScreen | Tab root | ShellRoute | Authenticated |
| `/events` | EventsScreen | Tab root | ShellRoute | Authenticated |
| `/growth` | GrowthScreen | Tab root | ShellRoute | Authenticated |
| `/analytics` | AnalyticsScreen | Tab root | ShellRoute | Authenticated |
| `/profile` | OwnProfileScreen | Tab root | ShellRoute | Authenticated |
| `/event/:id` | EventDetailScreen | Stack | Any tab | Authenticated |
| `/event/:id/poll/:pollId` | PollDetailScreen | Stack | Events | Authenticated |
| `/challenge/:id` | ChallengeDetailScreen | Stack | Growth | Authenticated |
| `/recognition/:id` | RecognitionDetailScreen | Stack | Analytics | Authenticated |
| `/analytics/ranking` | FullRankingsScreen | Stack | Analytics | Authenticated |
| `/profile/:id` | MemberProfileScreen | Stack | Any tab | Authenticated |
| `/notifications` | NotificationsScreen | Stack | Profile | Authenticated |
| `/admin` | AdminOverviewScreen | Stack | Profile | Admin |
| `/admin/members` | AdminMembersScreen | Stack | Admin | Admin |
| `/admin/flagged` | AdminFlaggedScreen | Stack | Admin | Admin |
| `/admin/announcements` | AdminAnnouncementsScreen | Stack | Admin | Admin |
| `/admin/attendance` | AdminAttendanceScreen | Stack | Admin | Admin |
| `/admin/connect-buddy` | AdminConnectBuddyScreen | Stack | Admin | Admin |

---

## 9. Navigation Interaction Summary

### Entry Points Into the App

| Entry Point | First Screen |
|-------------|-------------|
| Cold launch (no session) | SCR-AUTH-001 (Welcome) |
| Cold launch (valid session) | SCR-FEED-001 (Feed) |
| Cold launch (session + !onboarded) | SCR-AUTH-003 (Create Profile) |
| Cold launch (deactivated) | SCR-UTIL-002 (Access Denied) |
| Push notification tap (cold) | Target screen via deep link |
| Push notification tap (warm) | Target screen via deep link |

### Cross-Module Navigation Points

| From | To | Trigger |
|------|----|---------|
| Any screen with avatar/name | `/profile/:id` | Tap avatar or name |
| Feed, Events, Growth | `/notifications` | Tap notification bell |
| Profile tab | `/admin` | Tap "Admin Panel" (admin only) |
| Notification tile | Any target screen | Tap notification |
| Event Detail | Poll Detail | Tap linked poll |
| Recognition list | Recognition Detail | Tap recognition card |
| Rankings list | Member Profile | Tap ranked member |
