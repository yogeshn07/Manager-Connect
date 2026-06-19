# Screen Inventory — Manager Connect

## Overview

This document catalogues every screen in the Manager Connect application. Each screen is assigned a unique ID, has a defined purpose, entry/exit points, required permissions, and navigation paths. Screens are organized by feature module.

**Total Screen Count: 33**
- Auth: 3
- Feed: 1
- Events: 4
- Growth: 3
- Analytics: 6
- Profile: 4
- Admin: 6
- Notifications: 1
- Shell: 1 (MainScaffold)
- Utility: 4 (Splash, Access Denied, Not Found, Post Detail implicit in Feed)

---

## Auth Screens

### SCR-AUTH-001: Welcome Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-AUTH-001` |
| **Route** | `/welcome` |
| **Purpose** | Entry point for invited managers. Validates invite token and requests OTP for authentication |
| **Permissions** | Unauthenticated only |
| **Entry Points** | App launch (no session), logout redirect, deep link (unauthenticated) |
| **Exit Points** | → `SCR-AUTH-002` (OTP verification after token validated) |
| **Key Elements** | App logo, onboarding hero image, invite token input field, "Continue" button |
| **State Variants** | Default, Loading (validating token), Error (invalid/expired token) |

---

### SCR-AUTH-002: Verify OTP Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-AUTH-002` |
| **Route** | `/verify-otp` |
| **Purpose** | 6-digit OTP entry to complete authentication |
| **Permissions** | Unauthenticated only (must have a pending OTP request) |
| **Entry Points** | ← `SCR-AUTH-001` (after successful token validation and OTP sent) |
| **Exit Points** | → `SCR-AUTH-003` (first-time user, onboarding not completed), → `SCR-FEED-001` (returning user, onboarding already completed) |
| **Key Elements** | 6-box OTP input widget, resend timer (60s countdown), "Verify" button, back arrow |
| **State Variants** | Default (awaiting input), Verifying (loading), Error (invalid OTP), Resend Available (timer expired) |

---

### SCR-AUTH-003: Create Profile Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-AUTH-003` |
| **Route** | `/create-profile` |
| **Purpose** | First-time profile setup — collects name, photo, title, bio, and interest tags |
| **Permissions** | Authenticated + `onboarding_completed = false` |
| **Entry Points** | ← `SCR-AUTH-002` (first-time user after OTP verification) |
| **Exit Points** | → `SCR-FEED-001` (after profile creation completes) |
| **Key Elements** | Avatar picker (camera/gallery), full name field, title field, bio field (300 char max), interest tag chip grid, "Complete Setup" button |
| **State Variants** | Default (form empty), Filling (partial input), Uploading Avatar (progress), Submitting (loading), Error (validation/server) |

---

## Feed Screens

### SCR-FEED-001: Feed Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-FEED-001` |
| **Route** | `/feed` |
| **Purpose** | Default landing screen. Reverse-chronological community feed with all posts, Connect Buddy posts, and pinned announcements |
| **Permissions** | Authenticated |
| **Entry Points** | Tab 1 tap, app launch (authenticated), deep link (mention, comment, connect_buddy_update) |
| **Exit Points** | → Post Detail (tap any post card — inline expansion or modal), → `SCR-PROF-003` (tap author avatar/name), → `SCR-NOTIF-001` (tap notification bell), → Create Post (FAB opens bottom sheet) |
| **Key Elements** | Pinned announcement banner (if active), feed list (PostCard + ConnectBuddyPostCard), FAB ("Post"), pull-to-refresh, infinite scroll |
| **State Variants** | Loading (skeleton), Loaded (post list), Empty (no posts yet), Error (network/server), Offline (cached data with banner) |

---

## Events Screens

### SCR-EVT-001: Events Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-EVT-001` |
| **Route** | `/events` |
| **Purpose** | Browse upcoming events filtered by category, access polls, and view event history |
| **Permissions** | Authenticated |
| **Entry Points** | Tab 2 tap, deep link (activity_created), back from event detail |
| **Exit Points** | → `SCR-EVT-002` (tap event card), → Create Event (FAB opens bottom sheet), → Event History (tab or link) |
| **Key Elements** | Category tab bar (All / Games / Outings / Social Connect), event list, calendar view toggle (V1 stretch), FAB ("Event"), pull-to-refresh, polls section |
| **State Variants** | Loading (skeleton), Loaded (event list), Empty (no upcoming events), Error, Offline |

---

### SCR-EVT-002: Event Detail Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-EVT-002` |
| **Route** | `/event/:id` |
| **Purpose** | Full event details with RSVP, attendee list, organizer updates, linked polls, and post-event attendance summary |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-EVT-001` (tap event card), deep link (activity_reminder, activity_cancelled, activity_updated) |
| **Exit Points** | → `SCR-EVT-003` (tap linked poll), → `SCR-PROF-003` (tap attendee avatar), ← Back to Events, → RSVP selector (bottom sheet), → Create Poll (bottom sheet, if event creator) |
| **Key Elements** | Event header (title, category chip, type chip, date/time, location, cost note), RSVP selector (Going/Not Going/Maybe), RSVP count summary, attendee list, organizer updates timeline, linked polls list, cancellation banner (if cancelled), post-event attendance summary (if past) |
| **State Variants** | Loading, Loaded (upcoming), Loaded (past — with attendance), Cancelled (banner + no RSVP), Error, Not Found |

---

### SCR-EVT-003: Poll Detail Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-EVT-003` |
| **Route** | `/event/:id/poll/:pollId` |
| **Purpose** | View poll question, vote on options, and see live results |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-EVT-002` (tap poll in event detail), deep link (poll_reminder) |
| **Exit Points** | ← Back to Event Detail |
| **Key Elements** | Poll question text, option list with progress bars (live vote percentages), "Vote" action per option, total vote count, closing date, own vote highlighted, closed state (results only) |
| **State Variants** | Loading, Open (can vote), Voted (own selection highlighted, cannot change), Closed (results final), Error, Not Found |

---

### SCR-EVT-004: Event History Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-EVT-004` |
| **Route** | `/events` (sub-tab or scroll section within Events Screen) |
| **Purpose** | Archive of past events with attendance records |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-EVT-001` (past events section or tab) |
| **Exit Points** | → `SCR-EVT-002` (tap past event — read-only detail with attendance) |
| **Key Elements** | List of past events sorted by date descending, attendance summary badge per event |
| **State Variants** | Loading, Loaded, Empty (no past events) |

---

## Growth Screens

### SCR-GRO-001: Growth Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-GRO-001` |
| **Route** | `/growth` |
| **Purpose** | Browse and manage fitness and wellness challenges |
| **Permissions** | Authenticated |
| **Entry Points** | Tab 3 tap, deep link (challenge_created) |
| **Exit Points** | → `SCR-GRO-002` (tap challenge card), → Create Challenge (FAB opens bottom sheet) |
| **Key Elements** | Tab bar (Active / My Challenges / Completed), challenge list with type badges (Fitness/Wellness), FAB ("Challenge"), pull-to-refresh |
| **State Variants** | Loading (skeleton), Loaded, Empty (per tab — no active/joined/completed challenges), Error, Offline |

---

### SCR-GRO-002: Challenge Detail Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-GRO-002` |
| **Route** | `/challenge/:id` |
| **Purpose** | View challenge details, join/leave, log progress, and view leaderboard |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-GRO-001` (tap challenge card), deep link (challenge_ending, challenge_ended) |
| **Exit Points** | → `SCR-PROF-003` (tap leaderboard participant), ← Back to Growth, → Log Progress (bottom sheet), → Join/Leave action |
| **Key Elements** | Challenge header (title, type badge, goal type, dates, creator, description), Join/Leave button (if active), Log Progress button (if joined + active), leaderboard list (live via Realtime), goal progress indicator |
| **State Variants** | Loading, Active (not joined), Active (joined — shows log progress), Ended (read-only leaderboard), Error, Not Found |

---

### SCR-GRO-003: Completed Challenges Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-GRO-003` |
| **Route** | `/growth` (Completed tab within Growth Screen) |
| **Purpose** | Archive of ended challenges with final leaderboards |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-GRO-001` (Completed tab) |
| **Exit Points** | → `SCR-GRO-002` (tap completed challenge — read-only detail) |
| **Key Elements** | List of ended challenges sorted by end date descending |
| **State Variants** | Loading, Loaded, Empty |

---

## Analytics Screens

### SCR-ANA-001: Analytics Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ANA-001` |
| **Route** | `/analytics` |
| **Purpose** | Analytics hub with tabs for personal stats, community metrics, rankings, and recognition |
| **Permissions** | Authenticated |
| **Entry Points** | Tab 4 tap |
| **Exit Points** | → `SCR-ANA-002` (Personal tab), → `SCR-ANA-003` (Community tab), → `SCR-ANA-004` (Rankings tab), → `SCR-ANA-005` (Recognition tab) |
| **Key Elements** | Tab bar (Personal / Community / Rankings / Recognition), content area per tab |
| **State Variants** | Loading (skeleton), Loaded per tab |

---

### SCR-ANA-002: Personal Analytics Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ANA-002` |
| **Route** | `/analytics` (Personal tab) |
| **Purpose** | View own engagement metrics — events attended, attendance rate, challenges, recognitions, posts |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-ANA-001` (Personal tab) |
| **Exit Points** | Month selector (view previous months) |
| **Key Elements** | Month selector dropdown, stat cards (events attended, attendance rate, challenges joined, progress logs, recognitions received/given, posts count), current month rank badge |
| **State Variants** | Loading, Loaded, Empty (new user with no data), Error |

---

### SCR-ANA-003: Community Analytics Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ANA-003` |
| **Route** | `/analytics` (Community tab) |
| **Purpose** | View community-wide engagement metrics and Community Health Score |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-ANA-001` (Community tab) |
| **Exit Points** | None (informational) |
| **Key Elements** | Health Score card (score 0–100 with color coding), community stat cards (active members, events this month, avg attendance rate, challenge participation, recognition activity), health score breakdown metrics |
| **State Variants** | Loading, Loaded, Error |

---

### SCR-ANA-004: Rankings Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ANA-004` |
| **Route** | `/analytics` (Rankings tab) and `/analytics/ranking` (full page) |
| **Purpose** | Monthly and all-time member rankings by composite participation score |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-ANA-001` (Rankings tab), direct route `/analytics/ranking` |
| **Exit Points** | → `SCR-PROF-003` (tap ranked member) |
| **Key Elements** | Monthly / All-Time toggle, month selector (for monthly), ranked list (rank number, avatar, name, score), top 3 highlighted, own rank highlighted |
| **State Variants** | Loading, Loaded, Empty (no stats computed yet), Error |

---

### SCR-ANA-005: Recognition Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ANA-005` |
| **Route** | `/analytics` (Recognition tab) |
| **Purpose** | Monthly and community-wide recognition wall with give recognition action |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-ANA-001` (Recognition tab) |
| **Exit Points** | → `SCR-ANA-006` (tap recognition card), → Give Recognition (FAB opens bottom sheet) |
| **Key Elements** | Sub-tabs (Monthly Recognition / Community Wall), recognition card list (giver, recipients, category badge, message, reactions), FAB ("Recognize"), infinite scroll on Community Wall |
| **State Variants** | Loading, Loaded, Empty (no recognitions yet), Error |

---

### SCR-ANA-006: Recognition Detail Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ANA-006` |
| **Route** | `/recognition/:id` |
| **Purpose** | Full detail view of a single recognition with reactions |
| **Permissions** | Authenticated |
| **Entry Points** | ← `SCR-ANA-005` (tap recognition card), deep link (recognition_received) |
| **Exit Points** | → `SCR-PROF-003` (tap giver/recipient avatar), ← Back |
| **Key Elements** | Giver profile header, recipient chip list, category tag badge, full message, emoji reaction bar, timestamp |
| **State Variants** | Loading, Loaded, Error, Not Found |

---

## Profile Screens

### SCR-PROF-001: Own Profile Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-PROF-001` |
| **Route** | `/profile` |
| **Purpose** | View own profile, access settings, notification preferences, and admin panel (if admin) |
| **Permissions** | Authenticated |
| **Entry Points** | Tab 5 tap |
| **Exit Points** | → `SCR-PROF-002` (Edit Profile), → `SCR-PROF-004` (Notification Preferences), → `SCR-ADMIN-001` (Admin Panel — admin only), → `SCR-NOTIF-001` (Notifications), → Logout action |
| **Key Elements** | Profile header (XXL avatar, name, title, bio), interest tags, received recognitions summary, settings menu (Edit Profile, Notification Preferences, Admin Panel, Logout), notification bell icon with badge |
| **State Variants** | Loading, Loaded, Error |

---

### SCR-PROF-002: Edit Profile Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-PROF-002` |
| **Route** | `/profile` (pushed as modal or stack screen) |
| **Purpose** | Edit own profile — photo, name, title, bio, interest tags |
| **Permissions** | Authenticated (own profile only) |
| **Entry Points** | ← `SCR-PROF-001` (tap Edit Profile) |
| **Exit Points** | ← Back (discard changes), Save (returns to Own Profile with updated data) |
| **Key Elements** | Avatar picker (change photo), name field, title field, bio field (300 char), interest tag chip grid, "Save" button |
| **State Variants** | Default (populated with current data), Saving (loading), Error (validation/server) |

---

### SCR-PROF-003: Member Profile Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-PROF-003` |
| **Route** | `/profile/:id` |
| **Purpose** | View another member's profile (read-only) |
| **Permissions** | Authenticated |
| **Entry Points** | Tap on any avatar/name across the app (feed, events, growth, analytics, admin), deep link |
| **Exit Points** | ← Back to originating screen |
| **Key Elements** | Profile header (XL avatar, name, title, bio), interest tags, received recognitions list |
| **State Variants** | Loading, Loaded, Error, Not Found |

---

### SCR-PROF-004: Notification Preferences Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-PROF-004` |
| **Route** | `/profile` (pushed from settings menu) |
| **Purpose** | Configure push notification opt-in/out per category |
| **Permissions** | Authenticated (own preferences only) |
| **Entry Points** | ← `SCR-PROF-001` (tap Notification Preferences) |
| **Exit Points** | ← Back (auto-saved) |
| **Key Elements** | 9 toggle switches (one per notification preference category), changes saved immediately on toggle (no save button) |
| **State Variants** | Loading, Loaded, Saving (brief per-toggle), Error |

---

## Admin Screens

### SCR-ADMIN-001: Admin Overview Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ADMIN-001` |
| **Route** | `/admin` |
| **Purpose** | Admin panel home — quick access to all admin functions |
| **Permissions** | Authenticated + `app_role = 'admin'` |
| **Entry Points** | ← `SCR-PROF-001` (tap Admin Panel menu item) |
| **Exit Points** | → `SCR-ADMIN-002` (Members), → `SCR-ADMIN-003` (Flagged Content), → `SCR-ADMIN-004` (Announcements), → `SCR-ADMIN-005` (Attendance), → `SCR-ADMIN-006` (Connect Buddy) |
| **Key Elements** | Admin metric cards (active members, pending invites, flagged content count, events needing attendance), navigation tiles to each admin section |
| **State Variants** | Loading, Loaded, Error |

---

### SCR-ADMIN-002: Admin Members Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ADMIN-002` |
| **Route** | `/admin/members` |
| **Purpose** | Manage community members — view all, invite new, deactivate, remove |
| **Permissions** | Authenticated + `app_role = 'admin'` |
| **Entry Points** | ← `SCR-ADMIN-001`, deep link (admin_member_registered) |
| **Exit Points** | → Invite Member (bottom sheet), → Deactivate/Remove (confirm dialog), → `SCR-PROF-003` (tap member) |
| **Key Elements** | Two sections: Active Members list + Pending Invitations list, Invite Member button, member management tiles (avatar, name, role, status), long-press/swipe for deactivate/remove actions |
| **State Variants** | Loading, Loaded, Empty (no members — edge case), Error |

---

### SCR-ADMIN-003: Admin Flagged Content Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ADMIN-003` |
| **Route** | `/admin/flagged` |
| **Purpose** | Review and resolve flagged content (posts and comments) |
| **Permissions** | Authenticated + `app_role = 'admin'` |
| **Entry Points** | ← `SCR-ADMIN-001`, deep link (admin_flag) |
| **Exit Points** | → Delete (confirm dialog), → Dismiss (action) |
| **Key Elements** | Pending flags list, each card shows: flagged content preview, content type (post/comment), reporter name, reason, flag date, action buttons (Delete / Dismiss) |
| **State Variants** | Loading, Loaded, Empty (no pending flags — "All clear"), Error |

---

### SCR-ADMIN-004: Admin Announcements Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ADMIN-004` |
| **Route** | `/admin/announcements` |
| **Purpose** | Manage pinned announcements — view current pin, pin a new post, unpin |
| **Permissions** | Authenticated + `app_role = 'admin'` |
| **Entry Points** | ← `SCR-ADMIN-001` |
| **Exit Points** | → Pin new post (select from recent posts), → Unpin (confirm dialog) |
| **Key Elements** | Currently pinned post card (if any), "Pin a Post" action, recent posts list to select from, Unpin button |
| **State Variants** | Loading, Loaded (with active pin), Loaded (no active pin), Error |

---

### SCR-ADMIN-005: Admin Attendance Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ADMIN-005` |
| **Route** | `/admin/attendance` |
| **Purpose** | Record post-event attendance for past events |
| **Permissions** | Authenticated + `app_role = 'admin'` |
| **Entry Points** | ← `SCR-ADMIN-001` |
| **Exit Points** | → Attendance Recording Sheet (bottom sheet — tap event to record) |
| **Key Elements** | List of past events with no attendance recorded, each card shows: event title, date, RSVP count, "Record" button; attendance recording bottom sheet (member list with Attended/Absent toggles) |
| **State Variants** | Loading, Loaded (events needing attendance), Empty (all events have attendance recorded), Error |

---

### SCR-ADMIN-006: Admin Connect Buddy Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-ADMIN-006` |
| **Route** | `/admin/connect-buddy` |
| **Purpose** | View recent Connect Buddy posts and manually trigger post types |
| **Permissions** | Authenticated + `app_role = 'admin'` |
| **Entry Points** | ← `SCR-ADMIN-001` |
| **Exit Points** | → Trigger CB Post (bottom sheet) |
| **Key Elements** | Recent Connect Buddy posts list, manual trigger controls (Welcome — requires member selector, Monthly Highlights, Memory), trigger bottom sheet |
| **State Variants** | Loading, Loaded, Empty (no CB posts yet), Error |

---

## Notifications Screen

### SCR-NOTIF-001: Notifications Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-NOTIF-001` |
| **Route** | `/notifications` |
| **Purpose** | In-app notification inbox — view, read, and navigate to notification targets |
| **Permissions** | Authenticated |
| **Entry Points** | Tap notification bell on Profile tab, notification tap (foreground) |
| **Exit Points** | → Target screen (tap notification — navigates to deep link target), ← Back |
| **Key Elements** | Notification list (reverse chronological, paginated), unread indicator per item, "Mark all as read" action in AppBar, notification tile (icon by type, title, body, relative timestamp) |
| **State Variants** | Loading, Loaded, Empty (no notifications), Error |

---

## Utility Screens

### SCR-UTIL-001: Splash Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-UTIL-001` |
| **Route** | `/` (redirect evaluates) |
| **Purpose** | Brief loading state while session is being evaluated |
| **Permissions** | None (pre-auth) |
| **Entry Points** | App cold start |
| **Exit Points** | → `SCR-AUTH-001` (no session), → `SCR-FEED-001` (valid session), → `SCR-AUTH-003` (session + onboarding incomplete) |
| **Key Elements** | App logo centered, loading indicator |
| **State Variants** | Loading only |

---

### SCR-UTIL-002: Access Denied Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-UTIL-002` |
| **Route** | Shown in-place (no dedicated route) |
| **Purpose** | Graceful message for deactivated users |
| **Permissions** | Authenticated but `is_active = false` |
| **Entry Points** | Auth state change to deactivated |
| **Exit Points** | → Logout (clears session, returns to Welcome) |
| **Key Elements** | "Account Deactivated" message, explanation text, "Log Out" button |
| **State Variants** | Static only |

---

### SCR-UTIL-003: Not Found Screen

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-UTIL-003` |
| **Route** | 404 fallback route |
| **Purpose** | Shown when navigating to a deleted resource or invalid route |
| **Permissions** | Authenticated |
| **Entry Points** | Deep link to deleted content, malformed URL |
| **Exit Points** | → Back to relevant tab root |
| **Key Elements** | "Not Found" illustration, message, "Go Home" button |
| **State Variants** | Static only |

---

### SCR-UTIL-004: Main Scaffold (Shell)

| Property | Value |
|----------|-------|
| **Screen ID** | `SCR-UTIL-004` |
| **Route** | ShellRoute wrapper (no unique route) |
| **Purpose** | Persistent 5-tab bottom navigation bar wrapping all authenticated screens |
| **Permissions** | Authenticated |
| **Entry Points** | Always rendered for authenticated users |
| **Exit Points** | N/A — wraps tab content |
| **Key Elements** | NavigationBar with 5 tabs (Feed, Events, Growth, Analytics, Profile), tab badges (Events: upcoming event, Growth: active challenge count, Profile: unread notification count) |
| **State Variants** | Always visible for authenticated users |

---

## Screen Summary Table

| Screen ID | Name | Route | Module | Permission |
|-----------|------|-------|--------|-----------|
| SCR-AUTH-001 | Welcome | `/welcome` | Auth | Unauthenticated |
| SCR-AUTH-002 | Verify OTP | `/verify-otp` | Auth | Unauthenticated |
| SCR-AUTH-003 | Create Profile | `/create-profile` | Auth | Auth + onboarding incomplete |
| SCR-FEED-001 | Feed | `/feed` | Feed | Authenticated |
| SCR-EVT-001 | Events | `/events` | Events | Authenticated |
| SCR-EVT-002 | Event Detail | `/event/:id` | Events | Authenticated |
| SCR-EVT-003 | Poll Detail | `/event/:id/poll/:pollId` | Events | Authenticated |
| SCR-EVT-004 | Event History | `/events` (section) | Events | Authenticated |
| SCR-GRO-001 | Growth | `/growth` | Growth | Authenticated |
| SCR-GRO-002 | Challenge Detail | `/challenge/:id` | Growth | Authenticated |
| SCR-GRO-003 | Completed Challenges | `/growth` (tab) | Growth | Authenticated |
| SCR-ANA-001 | Analytics | `/analytics` | Analytics | Authenticated |
| SCR-ANA-002 | Personal Analytics | `/analytics` (tab) | Analytics | Authenticated |
| SCR-ANA-003 | Community Analytics | `/analytics` (tab) | Analytics | Authenticated |
| SCR-ANA-004 | Rankings | `/analytics` (tab) + `/analytics/ranking` | Analytics | Authenticated |
| SCR-ANA-005 | Recognition | `/analytics` (tab) | Analytics | Authenticated |
| SCR-ANA-006 | Recognition Detail | `/recognition/:id` | Analytics | Authenticated |
| SCR-PROF-001 | Own Profile | `/profile` | Profile | Authenticated |
| SCR-PROF-002 | Edit Profile | `/profile` (stack) | Profile | Authenticated |
| SCR-PROF-003 | Member Profile | `/profile/:id` | Profile | Authenticated |
| SCR-PROF-004 | Notification Preferences | `/profile` (stack) | Profile | Authenticated |
| SCR-ADMIN-001 | Admin Overview | `/admin` | Admin | Admin |
| SCR-ADMIN-002 | Admin Members | `/admin/members` | Admin | Admin |
| SCR-ADMIN-003 | Admin Flagged Content | `/admin/flagged` | Admin | Admin |
| SCR-ADMIN-004 | Admin Announcements | `/admin/announcements` | Admin | Admin |
| SCR-ADMIN-005 | Admin Attendance | `/admin/attendance` | Admin | Admin |
| SCR-ADMIN-006 | Admin Connect Buddy | `/admin/connect-buddy` | Admin | Admin |
| SCR-NOTIF-001 | Notifications | `/notifications` | Notifications | Authenticated |
| SCR-UTIL-001 | Splash | `/` | Utility | None |
| SCR-UTIL-002 | Access Denied | (in-place) | Utility | Deactivated |
| SCR-UTIL-003 | Not Found | 404 fallback | Utility | Authenticated |
| SCR-UTIL-004 | Main Scaffold | ShellRoute | Utility | Authenticated |

---

## Bottom Sheet Inventory

Bottom sheets are modal interaction surfaces — not standalone screens. They do not create new routes.

| Sheet ID | Name | Launched From | Purpose |
|----------|------|--------------|---------|
| SHT-001 | Create Post | `SCR-FEED-001` FAB | Author new text/photo post with @mentions |
| SHT-002 | Comments | `SCR-FEED-001` comment action | View and add comments on a post |
| SHT-003 | Create Event | `SCR-EVT-001` FAB | Create new event with category, type, details |
| SHT-004 | Create Poll | `SCR-EVT-002` action | Create poll linked to an event |
| SHT-005 | RSVP Selector | `SCR-EVT-002` RSVP button | Select Going / Not Going / Maybe |
| SHT-006 | Create Challenge | `SCR-GRO-001` FAB | Create fitness or wellness challenge |
| SHT-007 | Log Progress | `SCR-GRO-002` action | Log daily progress for a joined challenge |
| SHT-008 | Give Recognition | `SCR-ANA-005` FAB | Select recipient, category, write message |
| SHT-009 | Invite Member | `SCR-ADMIN-002` action | Enter name + email/phone for invitation |
| SHT-010 | Attendance Recording | `SCR-ADMIN-005` action | Mark each member Attended/Absent for a past event |
| SHT-011 | Connect Buddy Trigger | `SCR-ADMIN-006` action | Manually trigger a Connect Buddy post type |
| SHT-012 | Notification Preferences | `SCR-PROF-001` menu | (Alternative entry — may also be a pushed screen) |

---

## Dialog Inventory

| Dialog ID | Name | Launched From | Purpose |
|-----------|------|--------------|---------|
| DLG-001 | Delete Post | `SCR-FEED-001` post actions | Confirm post deletion |
| DLG-002 | Delete Comment | `SCR-FEED-001` comment actions | Confirm comment deletion |
| DLG-003 | Flag Content | `SCR-FEED-001` post/comment actions | Flag post or comment as inappropriate |
| DLG-004 | Cancel Event | `SCR-EVT-002` organizer actions | Confirm event cancellation |
| DLG-005 | Deactivate User | `SCR-ADMIN-002` member actions | Confirm user deactivation |
| DLG-006 | Remove User | `SCR-ADMIN-002` member actions | Confirm permanent user removal |
| DLG-007 | Revoke Invitation | `SCR-ADMIN-002` invitation actions | Confirm invitation revocation |
| DLG-008 | Delete Flagged Content | `SCR-ADMIN-003` flag actions | Confirm deletion of flagged content |
| DLG-009 | Unpin Announcement | `SCR-ADMIN-004` action | Confirm unpinning current announcement |
| DLG-010 | Logout | `SCR-PROF-001` menu | Confirm logout action |
| DLG-011 | Invite URL Copy | `SCR-ADMIN-002` after invitation | Show invite URL for copying |
