# UI State Specification — Manager Connect

## Overview

This document defines the visual presentation for every UI state of every major screen in the Manager Connect application. Each screen has up to five states: Loading, Empty, Error, Offline, and Success. The specification ensures consistent user experience across all states.

**State pattern:** All async data uses Riverpod `AsyncValue.when(data:, loading:, error:)`. Offline state is layered on top via `ConnectivityPlus` stream.

---

## State Definitions

| State | Trigger | Visual Pattern |
|-------|---------|---------------|
| **Loading** | Initial data fetch in progress | Skeleton shimmer matching content layout |
| **Empty** | Data loaded successfully but result set is empty | EmptyStateWidget (icon + title + subtitle + optional CTA) |
| **Error** | Data fetch failed (server, auth, network during fetch) | ErrorStateWidget (error icon + message + "Try Again" button) |
| **Offline** | Device has no network connectivity | Persistent banner at top + cached data shown (if available) |
| **Success** | Data loaded successfully with content | Normal screen layout with live data |

---

## Auth Screens

### SCR-AUTH-001: Welcome Screen

| State | Visual |
|-------|--------|
| **Success (Default)** | App logo, onboarding hero image, invite token input field, "Continue" button enabled |
| **Loading** | "Continue" button shows spinner (16px), input field disabled, dimmed overlay |
| **Error (Invalid Token)** | Input field border turns `error` red, error text below: "Invalid or expired invitation. Please contact your admin for a new invite." |
| **Error (Network)** | Snackbar: "No internet connection. Check your connection and try again." with "Retry" action |
| **Offline** | N/A — network required for auth; error state handles this |

### SCR-AUTH-002: Verify OTP Screen

| State | Visual |
|-------|--------|
| **Success (Default)** | 6 OTP input boxes (empty), instruction text: "Enter the 6-digit code sent to [email/phone]", resend timer counting down |
| **Loading (Verifying)** | OTP boxes disabled, "Verify" button shows spinner, dimmed overlay |
| **Error (Invalid OTP)** | All 6 boxes border turns `error` red, error text: "Invalid code. Please try again.", boxes cleared for re-entry |
| **Error (Expired OTP)** | Error text: "Code expired.", "Resend" button enabled and highlighted |
| **Resend Available** | Resend timer shows "Resend code" as tappable `TextButton` in `primary` color |
| **Resend Cooldown** | Timer text: "Resend in 45s" in `onSurfaceVariant`, not tappable |

### SCR-AUTH-003: Create Profile Screen

| State | Visual |
|-------|--------|
| **Success (Default)** | Empty form: avatar placeholder (camera icon), name field, title field, bio field, interest tag grid, "Complete Setup" button |
| **Uploading Avatar** | Avatar area shows circular progress indicator overlaid on image preview |
| **Loading (Submitting)** | "Complete Setup" button shows spinner, all fields disabled |
| **Error (Validation)** | Red borders on invalid fields, error text per field (e.g., "Name is required") |
| **Error (Server)** | Snackbar: "Something went wrong. Please try again." with "Retry" action; form data preserved |

---

## Feed Screen

### SCR-FEED-001: Feed Screen

| State | Visual |
|-------|--------|
| **Loading** | `FeedSkeleton` (CMP-048): 3 shimmer post cards (avatar circle + name bar + 3 content lines + image rect + reaction bar) |
| **Success** | Pinned announcement banner (if active) at top → scrollable post list (PostCard + ConnectBuddyPostCard). FAB visible. |
| **Empty** | EmptyStateWidget: icon `feed` (64px), title "No posts yet", subtitle "Be the first to share something with the community", CTA button "Create Post" (opens SHT-001) |
| **Error** | ErrorStateWidget: error icon (48px), "Something went wrong", error message, "Try Again" button (triggers refetch) |
| **Offline** | Top banner: `surfaceContainerHigh` background, icon `cloud_off` (20px) + "You're offline" text (`labelMedium`). Cached posts remain visible below. FAB hidden (cannot create posts offline). Pull-to-refresh disabled. |
| **Loading More (Pagination)** | `CircularProgressIndicator` (24px) centered below last post while fetching next page |
| **Realtime Update** | New post received → subtle "New posts" pill button appears at top of list; tap scrolls to top and shows new posts |

---

## Events Screens

### SCR-EVT-001: Events Screen

| State | Visual |
|-------|--------|
| **Loading** | `EventsSkeleton` (CMP-049): category tab bar (shimmer chips) + 3 shimmer event cards |
| **Success** | Category tab bar (All / Games / Outings / Social Connect) + filtered event list + polls section + FAB |
| **Empty (All)** | EmptyStateWidget: icon `event` (64px), "No upcoming events", "Create an event to get the community together", CTA "Create Event" |
| **Empty (Games)** | EmptyStateWidget: icon `sports_cricket`, "No games scheduled", "Create a game event to start playing" |
| **Empty (Outings)** | EmptyStateWidget: icon `hiking`, "No outings planned", "Plan an outing for the team" |
| **Empty (Social Connect)** | EmptyStateWidget: icon `coffee`, "No meetups yet", "Set up a coffee connect or lunch meetup" |
| **Error** | ErrorStateWidget per tab with "Try Again" |
| **Offline** | Top offline banner + cached events visible. FAB hidden. |

### SCR-EVT-002: Event Detail Screen

| State | Visual |
|-------|--------|
| **Loading** | Full-screen skeleton: title bar + detail rows + RSVP area + attendee list shimmer |
| **Success (Upcoming)** | Full event header + RSVP selector (Going/Maybe/Not Going) + RSVP count + attendee list + organizer updates timeline + linked polls list |
| **Success (Past)** | Full event header + RSVP selector hidden + attendance summary (Attended X / Absent Y) + "Attendance Recorded" badge |
| **Success (Cancelled)** | Full event header + red cancellation banner: "This event has been cancelled" with cancelled_at date. RSVP selector hidden. |
| **Error** | ErrorStateWidget with "Try Again" |
| **Not Found** | Icon `event_busy` (64px), "Event not found", "This event may have been removed", "Go Back" button |
| **Offline** | Cached event data shown (if previously loaded). RSVP selector disabled with "Offline" tooltip. |

### SCR-EVT-003: Poll Detail Screen

| State | Visual |
|-------|--------|
| **Loading** | Skeleton: question text shimmer + 3 option bars shimmer |
| **Success (Open, Not Voted)** | Question + tappable option tiles + "Vote" affordance + total votes + closing date |
| **Success (Open, Voted)** | Question + option tiles with percentages + own vote highlighted (primary left border, bold text) + "You voted for [option]" label. Options not re-tappable. |
| **Success (Closed)** | Question + final results (percentages) + "Poll closed on [date]" banner + winning option highlighted |
| **Error** | ErrorStateWidget |
| **Not Found** | "Poll not found" with back navigation |

---

## Growth Screens

### SCR-GRO-001: Growth Screen

| State | Visual |
|-------|--------|
| **Loading** | Skeleton: tab bar shimmer + 3 challenge card shimmer |
| **Success** | Tab bar (Active / My Challenges / Completed) + challenge list + FAB "Challenge" |
| **Empty (Active)** | EmptyStateWidget: icon `trending_up`, "No active challenges", "Start a challenge to get the community moving", CTA "Create Challenge" |
| **Empty (My Challenges)** | EmptyStateWidget: icon `emoji_events`, "You haven't joined any challenges", "Browse active challenges and join one" |
| **Empty (Completed)** | EmptyStateWidget: icon `check_circle`, "No completed challenges", "Challenges will appear here once they end" |
| **Error** | ErrorStateWidget per tab |
| **Offline** | Offline banner + cached challenges visible. FAB hidden. |

### SCR-GRO-002: Challenge Detail Screen

| State | Visual |
|-------|--------|
| **Loading** | Skeleton: header shimmer + button shimmer + leaderboard list shimmer |
| **Success (Active, Not Joined)** | Challenge info header + "Join Challenge" primary button + leaderboard (user not listed) |
| **Success (Active, Joined)** | Challenge info header + "Log Progress" primary button + leaderboard (user's row highlighted) + goal progress indicator |
| **Success (Ended)** | Challenge info header + "Challenge Ended" badge + final leaderboard (read-only) + no action buttons |
| **Error** | ErrorStateWidget |
| **Not Found** | "Challenge not found" with back |
| **Offline** | Cached data shown. "Join" and "Log Progress" buttons disabled with "Offline" tooltip. |

---

## Analytics Screens

### SCR-ANA-001: Analytics Screen (Hub)

| State | Visual |
|-------|--------|
| **Loading** | `AnalyticsSkeleton` (CMP-050): health score card shimmer + stat grid shimmer + list shimmer |
| **Success** | Tab bar (Personal / Community / Rankings / Recognition) + content per active tab |
| **Error** | ErrorStateWidget per tab |

### SCR-ANA-002: Personal Analytics

| State | Visual |
|-------|--------|
| **Loading** | 2×2 grid of stat card shimmer + rank badge shimmer |
| **Success** | Month selector + stat cards grid (events attended, attendance rate, challenges joined, progress logs, recognitions received/given, posts count) + current month rank badge |
| **Empty** | Stat cards show "0" values with subtle `onSurfaceVariant` styling. Message below: "Start participating to see your stats grow!" |
| **Error** | ErrorStateWidget |

### SCR-ANA-003: Community Analytics

| State | Visual |
|-------|--------|
| **Loading** | Health score card shimmer + breakdown shimmer + stat cards shimmer |
| **Success** | HealthScoreCard (score 0–100, color-coded) + HealthScoreBreakdown (4 sub-metrics) + community stat cards |
| **Empty** | Health score shows "—" with message "Not enough data to compute health score yet" |
| **Error** | ErrorStateWidget |

### SCR-ANA-004: Rankings Screen

| State | Visual |
|-------|--------|
| **Loading** | Toggle shimmer + 5 ranking entry shimmer rows |
| **Success (Monthly)** | Monthly/All-Time toggle (Monthly selected) + month selector + ranked member list. Top 3: `primaryContainer` background. Own rank: subtle `primary` border. |
| **Success (All-Time)** | Monthly/All-Time toggle (All-Time selected) + ranked member list (cumulative scores) |
| **Empty** | EmptyStateWidget: "No rankings yet", "Rankings will appear after the first month of activity" |
| **Error** | ErrorStateWidget |

### SCR-ANA-005: Recognition Screen

| State | Visual |
|-------|--------|
| **Loading** | Recognition card shimmer × 3 |
| **Success (Monthly)** | Sub-tab "Monthly Recognition" active + recognition cards for current/selected month + FAB "Recognize" |
| **Success (Community Wall)** | Sub-tab "Community Wall" active + all-time recognition cards (paginated, infinite scroll) + FAB "Recognize" |
| **Empty (Monthly)** | EmptyStateWidget: icon `star`, "No recognitions this month", "Recognize a colleague for their contributions", CTA "Give Recognition" |
| **Empty (Community)** | EmptyStateWidget: icon `star`, "No recognitions yet", "Be the first to give a shout-out", CTA "Give Recognition" |
| **Error** | ErrorStateWidget |

### SCR-ANA-006: Recognition Detail

| State | Visual |
|-------|--------|
| **Loading** | Full-screen skeleton: avatar shimmer + chip shimmer + text block shimmer |
| **Success** | Giver profile header (avatar MD + name + "recognized") + recipient chip list + category tag badge + full message text + emoji reaction bar + timestamp |
| **Error** | ErrorStateWidget |
| **Not Found** | "Recognition not found" with back navigation |

---

## Profile Screens

### SCR-PROF-001: Own Profile Screen

| State | Visual |
|-------|--------|
| **Loading** | Avatar shimmer (XXL circle) + name shimmer + bio shimmer + tag shimmer row |
| **Success** | Profile header (XXL avatar, name, title, bio) + interest tags + received recognitions summary + settings menu (Edit Profile, Notification Preferences, Admin Panel [admin only], Logout) |
| **Error** | ErrorStateWidget |

### SCR-PROF-002: Edit Profile Screen

| State | Visual |
|-------|--------|
| **Success (Default)** | Form pre-populated with current profile data. Avatar shows current photo with edit overlay. |
| **Saving** | "Save" button shows spinner. Fields disabled. |
| **Error (Validation)** | Red borders on invalid fields + error text |
| **Error (Server)** | Snackbar with error message; form data preserved |

### SCR-PROF-003: Member Profile Screen

| State | Visual |
|-------|--------|
| **Loading** | Avatar shimmer (XL) + name/bio shimmer + recognition list shimmer |
| **Success** | Profile header (XL avatar, name, title, bio) + interest tags + received recognitions list |
| **Error** | ErrorStateWidget |
| **Not Found** | "Member not found" — may have been removed. "Go Back" button. |

### SCR-PROF-004: Notification Preferences

| State | Visual |
|-------|--------|
| **Loading** | 9 toggle row shimmer |
| **Success** | 9 toggle switches with labels. Each toggle saves immediately on change (no save button). Brief spinner on the toggled row during PATCH. |
| **Error** | Snackbar: "Failed to update preference. Please try again." Toggle reverts to previous state. |

---

## Admin Screens

### SCR-ADMIN-001: Admin Overview

| State | Visual |
|-------|--------|
| **Loading** | 4 metric card shimmer + 5 navigation tile shimmer |
| **Success** | Metric cards (active members count, pending invites count, flagged content count, events needing attendance count) + navigation tiles to each admin section |
| **Error** | ErrorStateWidget |

### SCR-ADMIN-002: Admin Members

| State | Visual |
|-------|--------|
| **Loading** | Member list shimmer + invitation list shimmer |
| **Success** | Two sections: "Active Members" (avatar + name + role + status per row) + "Pending Invitations" (name + email/phone + status + date). Invite Member button. |
| **Empty** | Edge case — at minimum the admin user exists. Pending section can be empty: "No pending invitations" |
| **Error** | ErrorStateWidget |

### SCR-ADMIN-003: Admin Flagged Content

| State | Visual |
|-------|--------|
| **Loading** | Flagged content card shimmer × 3 |
| **Success** | List of pending flags. Each card: content preview + type badge + reporter + reason + date + [Delete] [Dismiss] buttons |
| **Empty** | EmptyStateWidget: icon `verified`, "All clear", "No flagged content to review" |
| **Error** | ErrorStateWidget |

### SCR-ADMIN-004: Admin Announcements

| State | Visual |
|-------|--------|
| **Loading** | Pinned post card shimmer + recent posts list shimmer |
| **Success (Active Pin)** | Currently pinned post card (highlighted `pinnedPostBackground`) + Unpin button + recent posts list for re-pinning |
| **Success (No Pin)** | "No active announcement" message + recent posts list with "Pin" action per post |
| **Error** | ErrorStateWidget |

### SCR-ADMIN-005: Admin Attendance

| State | Visual |
|-------|--------|
| **Loading** | Event card shimmer × 3 |
| **Success** | List of past events with no attendance recorded. Each card: event title + date + RSVP count + "Record" button. |
| **Empty** | EmptyStateWidget: icon `check_circle`, "All caught up", "Attendance has been recorded for all past events" |
| **Error** | ErrorStateWidget |

### SCR-ADMIN-006: Admin Connect Buddy

| State | Visual |
|-------|--------|
| **Loading** | CB post card shimmer × 3 + trigger controls shimmer |
| **Success** | Recent Connect Buddy posts list + manual trigger controls (Welcome / Monthly Highlights / Memory buttons) |
| **Empty** | EmptyStateWidget: icon `smart_toy`, "No Connect Buddy posts yet", "Use the controls below to trigger a post" |
| **Error** | ErrorStateWidget |

---

## Notifications Screen

### SCR-NOTIF-001: Notifications

| State | Visual |
|-------|--------|
| **Loading** | Notification tile shimmer × 5 (icon circle + 2 text lines) |
| **Success** | Notification list (reverse chronological). Unread: bold title + left `primary` accent bar (3px). Read: normal weight, no accent. "Mark all as read" button in AppBar (visible when unread > 0). |
| **Empty** | EmptyStateWidget: icon `notifications_none` (64px), "No notifications", "You're all caught up!" |
| **Error** | ErrorStateWidget |
| **Offline** | Offline banner + cached notifications shown. New notifications won't arrive until reconnect. |
| **Loading More** | Small spinner below last notification while fetching next page |

---

## Bottom Sheet States

All bottom sheets share a common state pattern:

### Creation Sheet States (SHT-001 through SHT-011)

| State | Visual |
|-------|--------|
| **Default** | Empty form with fields, submit button disabled until required fields filled |
| **Filling** | Fields being populated, submit button becomes enabled when form is valid |
| **Submitting** | Submit button shows spinner (16px). All fields disabled. Sheet cannot be dismissed. |
| **Success** | Sheet auto-dismisses. Success snackbar shown on parent screen. |
| **Validation Error** | Red borders on invalid fields. Error text below each invalid field. Submit button re-enabled. |
| **Server Error** | Snackbar: error message with "Retry" action. Form data preserved. Submit button re-enabled. |
| **Conflict Error** | Specific to vote/join: "Already voted" or "Already joined" message. Sheet dismisses. |

---

## Offline Banner Specification

The offline banner appears on screens that display cached data:

```
┌─────────────────────────────────────────────┐
│ ☁ You're offline · Changes won't be saved  │
│   surfaceContainerHigh bg, bodySmall text    │
│   Height: 36px, full width                  │
│   Position: Below AppBar, above content     │
│   Animation: Slide down (200ms) on offline  │
│              Slide up (150ms) on reconnect  │
└─────────────────────────────────────────────┘
```

**Screens with offline banner:** Feed, Events, Growth, Analytics, Notifications
**Screens without offline banner:** Auth screens (require network), Admin screens (require network for all operations)

**Offline behavior:**
- Cached data from current session remains visible
- Creation FABs are hidden (cannot create content offline)
- Interactive elements (RSVP, Vote, React, Join, Log) are disabled with "Offline" tooltip
- Pull-to-refresh is disabled
- On reconnect: Banner slides up, `ref.invalidate()` triggers refresh of key providers

---

## Snackbar State Summary

| Context | Type | Background | Duration | Action |
|---------|------|-----------|----------|--------|
| Post created | Success | `successColor` | 3s | None |
| Recognition given | Success | `successColor` | 3s | None |
| Event created | Success | `successColor` | 3s | None |
| Challenge joined | Success | `successColor` | 3s | None |
| Progress logged | Success | `successColor` | 3s | None |
| Attendance recorded | Success | `successColor` | 3s | None |
| Invitation sent | Success | `successColor` | 3s | None |
| Post deleted | Success | `successColor` | 3s | None |
| RSVP updated | Info | `surfaceContainerHigh` | 2s | None |
| Notification preference saved | Info | `surfaceContainerHigh` | 2s | None |
| Mark all as read | Info | `surfaceContainerHigh` | 2s | None |
| Network error | Error | `errorContainer` | 5s | "Retry" |
| Server error | Error | `errorContainer` | 5s | "Retry" |
| Validation error (form) | Error | `errorContainer` | 4s | None |
| Already voted | Warning | `warningColor` tint | 3s | None |
| Poll closed | Warning | `warningColor` tint | 3s | None |
| Offline action attempt | Warning | `warningColor` tint | 3s | None |

---

## Optimistic Update States

For actions using the optimistic update pattern, the UI shows the expected result immediately, then reconciles with the server response:

| Action | Optimistic Behavior | Revert on Failure |
|--------|-------------------|-------------------|
| Post reaction (emoji) | Emoji count +1 immediately, chip highlighted | Revert count -1, remove highlight |
| RSVP change | Selected status fills with color, count updates | Revert to previous selection |
| Poll vote | Progress bars animate to estimated new %, own vote highlighted | Remove vote highlight, revert bars |
| Log progress | Leaderboard rank recalculated and animated | Revert to previous rank position |
| Recognition reaction | Emoji count +1, chip highlighted | Revert |
| Create post | Post prepended to feed immediately | Remove optimistic post |
| Mark notification as read | Accent bar removed, text un-bolded | Re-add accent bar, re-bold |
| Mark all notifications as read | All accent bars removed | Restore accent bars on failed items |

**Visual pattern for optimistic revert:**
1. Revert to snapshot state (no animation — immediate)
2. Show error snackbar: "[Action] failed. Please try again." with "Retry" action (5s duration)
