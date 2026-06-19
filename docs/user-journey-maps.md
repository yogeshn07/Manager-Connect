# User Journey Maps — Manager Connect

## Overview

This document maps every primary user journey in Manager Connect from trigger to completion. Each journey includes the actor, entry point, step-by-step flow with screen references, success criteria, error paths, and notification touchpoints.

**Total User Journeys Documented: 16**

---

## UJ-01: First-Time Onboarding

**Actor:** New manager (invited by admin)
**Trigger:** Receives invitation link via email or SMS
**Goal:** Create profile and enter the community feed

```
[Receive invitation link via email/SMS]
       │
       ▼
[Open link → App Store if not installed → Launch app]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SCR-AUTH-001: Welcome Screen                │
│ • App logo and onboarding hero displayed    │
│ • Invitation token auto-extracted from URL  │
│ • System validates invite token             │
│   → If expired/invalid: Error state shown   │
│   → If valid: OTP sent to invitee's         │
│     email/phone from invitation record      │
│ • Tap "Continue"                            │
└─────────────────────────┬───────────────────┘
                          ▼
┌─────────────────────────────────────────────┐
│ SCR-AUTH-002: Verify OTP Screen             │
│ • 6-digit OTP input (auto-advance)         │
│ • Paste support (6-digit paste fills all)   │
│ • 60-second resend timer                    │
│   → If OTP invalid: Error text, retry       │
│   → If OTP expired: "Resend" available      │
│ • OTP verified → session created            │
│ • System checks onboarding_completed        │
│   → false: route to Create Profile          │
│   → true: route to Feed (returning user)    │
└─────────────────────────┬───────────────────┘
                          ▼
┌─────────────────────────────────────────────┐
│ SCR-AUTH-003: Create Profile Screen         │
│ • Tap avatar placeholder → image picker     │
│   (Camera or Gallery) → compress → preview  │
│ • Fill: full name, title, bio (300 char)    │
│ • Select interest tags (chip grid)          │
│ • Tap "Complete Setup"                      │
│   → Profile created via Edge Function       │
│   → Push token registered                   │
│   → onboarding_completed set to true        │
│   → Connect Buddy posts welcome message     │
└─────────────────────────┬───────────────────┘
                          ▼
┌─────────────────────────────────────────────┐
│ SCR-FEED-001: Feed Screen                   │
│ • User lands on community feed              │
│ • Connect Buddy welcome post visible        │
│ • Bottom navigation bar with 5 tabs visible │
└─────────────────────────────────────────────┘
```

**Success Criteria:** User creates profile and sees feed with Connect Buddy welcome post within 5 minutes of opening invite link.

**Error Paths:**
- Invalid/expired token → Error on Welcome Screen → User contacts admin for new invite
- OTP timeout → Resend button enabled after 60 seconds
- Network failure during profile creation → Retry prompt
- Avatar upload failure → Profile created without avatar; user can add later via Edit Profile

---

## UJ-02: Login (Returning User)

**Actor:** Existing member returning to the app
**Trigger:** App launch or session expiry
**Goal:** Reach the community feed

```
[Open app]
       │
       ▼
┌──────────────────────────────────────┐
│ SCR-UTIL-001: Splash Screen          │
│ • Check stored session               │
│   → Valid session: route to Feed     │
│   → Expired session: route to Welcome│
│   → No session: route to Welcome     │
│   → is_active = false: Access Denied │
└───────────────┬──────────────────────┘
                │
    ┌───────────┼───────────┐
    ▼           ▼           ▼
[SCR-FEED-001] [SCR-AUTH-001] [SCR-UTIL-002]
(valid session) (re-auth)    (deactivated)
```

**Re-authentication flow (if session expired):**
1. `SCR-AUTH-001`: Enter email/phone → receive OTP
2. `SCR-AUTH-002`: Enter OTP → session restored
3. Route to `SCR-FEED-001` (onboarding already completed)

**Success Criteria:** Returning user reaches feed within 3 seconds (cached session) or 30 seconds (re-auth).

---

## UJ-03: Feed Usage

**Actor:** Any authenticated member
**Trigger:** App launch or Feed tab tap
**Goal:** Browse community content, interact with posts

```
┌─────────────────────────────────────────────┐
│ SCR-FEED-001: Feed Screen                   │
│                                             │
│ • Pinned announcement banner (if active)    │
│   → Tap: expand to full post               │
│                                             │
│ • Scrollable feed (reverse chronological)   │
│   → Pull down: refresh feed                │
│   → Scroll to bottom: load more (page +1)  │
│                                             │
│ • Post Cards (member posts):                │
│   → Tap emoji: React (optimistic update)   │
│   → Tap 💬: Open comments sheet (SHT-002) │
│   → Tap author avatar: SCR-PROF-003        │
│   → Tap ⋮ (own): Delete (DLG-001)         │
│   → Tap ⋮ (other): Flag (DLG-003)         │
│                                             │
│ • Connect Buddy Cards:                      │
│   → Purple tinted background                │
│   → System badge on avatar                  │
│   → Same interactions minus Flag            │
│                                             │
│ • FAB "Post" → opens SHT-001               │
└─────────────────────────────────────────────┘
```

**Realtime:** New posts trigger feed refresh (prepend to top). Reaction counts update live.

---

## UJ-04: Create Post

**Actor:** Any authenticated member
**Trigger:** Tap FAB on Feed screen
**Goal:** Publish a text/photo post with optional @mentions

```
[SCR-FEED-001: Tap FAB "Post"]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SHT-001: Create Post Sheet                  │
│ • Multi-line text input (1000 char max)     │
│ • Type "@" → member autocomplete overlay    │
│   → Select member → insert @{name}         │
│ • Tap 📷 icon → image picker               │
│   → Camera or Gallery                       │
│   → Compress to ≤1MB                        │
│   → Thumbnail preview with ✕ remove         │
│   → Up to 4 images (counter: "2/4")         │
│ • "Post" button (disabled until content)    │
│   → Loading state on button                 │
│   → Images upload first → then create-post  │
│   → Optimistic: post appears in feed        │
│                                             │
│ [Error: Upload fails → retry prompt]        │
│ [Error: Server error → revert optimistic]   │
└─────────────────────────┬───────────────────┘
                          ▼
┌─────────────────────────────────────────────┐
│ SCR-FEED-001: Feed Screen                   │
│ • New post visible at top of feed           │
│ • Success snackbar: "Post published"        │
│ • @mentioned users receive push notification│
└─────────────────────────────────────────────┘
```

**Success Criteria:** Post visible in feed, mentions parsed server-side, mentioned users notified.

---

## UJ-05: Mention Manager

**Actor:** Any authenticated member
**Trigger:** Types "@" in post creation or comment
**Goal:** Mention another manager in a post

```
[Typing in Create Post or Comment input]
       │
       ▼
[Type "@" character]
       │
       ▼
┌─────────────────────────────────────────────┐
│ Mention Autocomplete Overlay                │
│ • Filtered from allProfilesProvider         │
│ • Excludes system accounts                  │
│ • Shows: Avatar (XS) + Name per row        │
│ • Real-time filter as user types after @    │
│   → Type "Ar" → shows "Arjun", "Arun"     │
│ • Tap member → insert @{Name} in text      │
│ • UUID stored internally for Edge Function  │
└─────────────────────────┬───────────────────┘
                          ▼
[Continue composing post/comment]
       │
       ▼
[Submit → Edge Function parses @mentions]
       │
       ▼
[Mentioned user receives push notification]
[type: "mention", targetScreen: "/feed"]
```

---

## UJ-06: Create Event

**Actor:** Any authenticated member
**Trigger:** Tap FAB on Events screen
**Goal:** Create a new community event

```
[SCR-EVT-001: Tap FAB "Event"]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SHT-003: Create Event Sheet                 │
│ 1. Select category chip:                    │
│    [Games] [Outings] [Social Connect]       │
│                                             │
│ 2. If Games: select type chip               │
│    [Cricket] [Badminton] [Pickleball]       │
│    [Table Tennis] [Other]                   │
│                                             │
│    If Social Connect: select type chip      │
│    [Coffee Connect] [Lunch Meetup]          │
│    [Dinner Meetup] [Other]                  │
│                                             │
│    If Outings: no sub-type (skip)           │
│                                             │
│ 3. Title (required, 100 char)               │
│ 4. Description (optional)                   │
│ 5. Date & Time picker (must be future)      │
│ 6. Location (optional)                      │
│ 7. Cost Note (optional, e.g. "₹200/person") │
│                                             │
│ • "Create Event" button                     │
│   → Validates required fields               │
│   → Creates event via PostgREST insert      │
│   → All members notified (activity_created) │
└─────────────────────────┬───────────────────┘
                          ▼
[Event appears in Events list]
[Success snackbar: "Event created"]
[All members receive push notification]
```

---

## UJ-07: RSVP to Event

**Actor:** Any authenticated member
**Trigger:** View event detail (from Events list or push notification)
**Goal:** RSVP to an upcoming event

```
[SCR-EVT-001 or Push Notification tap]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SCR-EVT-002: Event Detail Screen            │
│ • Event header: title, category, type, date,│
│   location, cost note, creator              │
│                                             │
│ • RSVP Selector (CMP-009):                  │
│   [Going ✓] [Maybe ?] [Not Going ✕]        │
│                                             │
│ • Tap selection → optimistic RSVP upsert    │
│   → Color fills for selected status         │
│   → RSVP count updates immediately          │
│   → Attendee list updates via Realtime      │
│                                             │
│ • Can change RSVP at any time before event  │
│                                             │
│ [Error: Network → revert to previous RSVP]  │
└─────────────────────────────────────────────┘
       │
       ▼
[24h before event: push reminder (if Going/Maybe)]
[1h before event: push reminder (if Going)]
```

**Success Criteria:** RSVP recorded, attendee list reflects change, reminders scheduled.

---

## UJ-08: Vote in Poll

**Actor:** Any authenticated member
**Trigger:** View poll (from Event Detail or deep link)
**Goal:** Cast a vote on a community poll

```
[SCR-EVT-002: Tap poll in event detail]
   or [Deep link from poll_reminder notification]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SCR-EVT-003: Poll Detail Screen             │
│ • Poll question displayed                   │
│ • Options listed with progress bars         │
│                                             │
│ IF not voted and poll is open:              │
│ • Tap an option → "Vote" confirm            │
│ • Vote submitted (INSERT poll_votes)        │
│ • DB UNIQUE(poll_id, user_id) enforces      │
│   one vote — no client guard needed         │
│ • Progress bars animate to new percentages  │
│ • Own vote highlighted (primary border)     │
│                                             │
│ IF already voted:                           │
│ • Own selection highlighted                 │
│ • Options not tappable (vote is final)      │
│ • Live results visible via Realtime         │
│                                             │
│ IF poll is closed:                          │
│ • Final results displayed                   │
│ • "Poll closed" banner shown                │
│                                             │
│ [Error: Conflict → "Already voted" message] │
└─────────────────────────────────────────────┘
```

**Success Criteria:** Vote recorded, live percentages visible, cannot re-vote.

---

## UJ-09: Join Challenge

**Actor:** Any authenticated member
**Trigger:** Browse Growth tab or push notification for new challenge
**Goal:** Join a fitness or wellness challenge

```
[SCR-GRO-001: Tap challenge card]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SCR-GRO-002: Challenge Detail Screen        │
│ • Challenge info: title, type, goal,        │
│   dates, description, creator               │
│                                             │
│ IF active and NOT joined:                   │
│ • "Join Challenge" button (primary)         │
│ • Tap → INSERT challenge_participants       │
│ • Button changes to "Log Progress"          │
│ • Leaderboard shows user at bottom (0)      │
│                                             │
│ IF active and joined:                       │
│ • "Log Progress" button → opens SHT-007    │
│ • Leaderboard shows current rank            │
│                                             │
│ IF ended:                                   │
│ • No action buttons                         │
│ • Final leaderboard displayed               │
│                                             │
│ [Error: Already joined → ConflictFailure]   │
└─────────────────────────────────────────────┘
```

---

## UJ-10: Log Progress

**Actor:** Member who has joined a challenge
**Trigger:** Tap "Log Progress" on Challenge Detail
**Goal:** Record daily progress toward a challenge goal

```
[SCR-GRO-002: Tap "Log Progress"]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SHT-007: Log Progress Sheet                 │
│ • Date: Pre-filled with today               │
│   (editable within challenge start–end)     │
│ • Value: Number input with goal-type label  │
│   → Steps challenge: "Steps today"          │
│   → Distance: "Kilometers today"            │
│   → Duration: "Minutes today"               │
│   → Custom: "[goal description] today"      │
│ • Note: Optional text field                 │
│ • "Log Progress" button                     │
│   → UPSERT (one per user per day)           │
│   → Re-log same day overwrites previous     │
│   → Leaderboard recalculates (SUM(value))   │
│                                             │
│ [Error: Challenge ended → "Challenge ended"]│
│ [Error: Network → retry prompt]             │
└─────────────────────────┬───────────────────┘
                          ▼
[Leaderboard updates via Realtime]
[Success snackbar: "Progress logged"]
```

**Success Criteria:** Progress value recorded, leaderboard rank updates.

---

## UJ-11: Give Recognition

**Actor:** Any authenticated member
**Trigger:** Tap FAB on Recognition screen within Analytics
**Goal:** Publicly recognize a colleague

```
[SCR-ANA-005: Tap FAB "Recognize"]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SHT-008: Give Recognition Sheet             │
│ • Recipient search field                    │
│   → Autocomplete from allProfilesProvider   │
│   → Excludes system accounts + self         │
│   → Tap member → add to recipient list      │
│   → Multiple recipients allowed             │
│                                             │
│ • Category tag selector (single select):    │
│   [Community Contributor]                   │
│   [Fitness Champion]                        │
│   [Wellness Champion]                       │
│   [Event Champion]                          │
│   [Most Supportive Manager]                 │
│                                             │
│ • Message: Multi-line (500 char max)        │
│                                             │
│ • "Give Recognition" button                 │
│   → Calls create-recognition Edge Function  │
│   → Recipients notified (recognition_recv)  │
│   → Appears on Recognition Wall             │
└─────────────────────────┬───────────────────┘
                          ▼
[SCR-ANA-005: Recognition visible on wall]
[Success snackbar: "Recognition posted"]
[Recipients receive push notification]
```

---

## UJ-12: View Analytics

**Actor:** Any authenticated member
**Trigger:** Tap Analytics tab
**Goal:** View personal and community engagement metrics

```
[Tab 4: Analytics tap]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SCR-ANA-001: Analytics Screen               │
│ • Tab bar: Personal | Community | Rankings  │
│   | Recognition                             │
│                                             │
│ ┌─ Personal Tab (SCR-ANA-002) ────────────┐│
│ │ • Month selector dropdown               ││
│ │ • Stat cards grid (2 columns):          ││
│ │   Events Attended, Attendance Rate,     ││
│ │   Challenges Joined, Progress Logs,     ││
│ │   Recognitions Received/Given, Posts    ││
│ │ • Current month rank badge              ││
│ └─────────────────────────────────────────┘│
│                                             │
│ ┌─ Community Tab (SCR-ANA-003) ───────────┐│
│ │ • Health Score Card (0–100, colored)    ││
│ │ • Health Score Breakdown                ││
│ │ • Community stat cards                  ││
│ └─────────────────────────────────────────┘│
│                                             │
│ ┌─ Rankings Tab (SCR-ANA-004) ────────────┐│
│ │ • Monthly / All-Time toggle             ││
│ │ • Month selector (Monthly mode)         ││
│ │ • Ranked list of members                ││
│ │ • Tap member → SCR-PROF-003            ││
│ └─────────────────────────────────────────┘│
│                                             │
│ ┌─ Recognition Tab (SCR-ANA-005) ─────────┐│
│ │ • Sub-tabs: Monthly | Community Wall    ││
│ │ • Recognition card list                 ││
│ │ • FAB "Recognize" → SHT-008            ││
│ │ • Tap card → SCR-ANA-006               ││
│ └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

---

## UJ-13: Notification Flow

**Actor:** Any authenticated member
**Trigger:** Push notification received (foreground or background)
**Goal:** View notification and navigate to relevant content

### Foreground Notification Path
```
[App is open]
       │
       ▼
[Push notification received]
       │
       ▼
[flutter_local_notifications displays banner]
       │
       ▼
[User taps banner]
       │
       ▼
[handleNotificationTap extracts targetScreen]
       │
       ▼
[context.go(targetScreen) → relevant screen]
```

### Background Notification Path
```
[App is in background or killed]
       │
       ▼
[Push notification appears in system tray]
       │
       ▼
[User taps notification]
       │
       ▼
[FirebaseMessaging.onMessageOpenedApp (warm)]
   or [getInitialMessage (cold start)]
       │
       ▼
[App launches/resumes]
       │
       ▼
[Auth guard evaluates → if no session: hold notification]
       │
       ▼
[If authenticated: navigate to targetScreen]
[If not authenticated: save target → auth → then navigate]
```

### In-App Notification Inbox Path
```
[Tap notification bell (Profile tab)]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SCR-NOTIF-001: Notifications Screen         │
│ • Reverse-chronological notification list   │
│ • Unread: bold text + left accent bar       │
│ • Tap notification tile:                    │
│   1. Mark as read (optimistic)              │
│   2. Navigate to targetScreen               │
│ • "Mark all as read" in AppBar              │
│ • Empty state if no notifications           │
│ • Infinite scroll (20 per page)             │
│ • Realtime: new INSERT → badge increments   │
└─────────────────────────────────────────────┘
```

**Deep link mapping:**

| Notification Type | Target Screen |
|-------------------|---------------|
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

**Edge cases:**
- Deleted content: "Not found" state on target screen; back returns to parent tab
- Unauthenticated tap: Notification target held; redirected after login
- Non-existent ID: Provider returns `NotFoundFailure`; error state shown

---

## UJ-14: Admin Invitation Flow

**Actor:** Admin
**Trigger:** Need to invite a new manager to the community
**Goal:** Send invitation and track acceptance

```
[SCR-PROF-001: Tap "Admin Panel"]
       │
       ▼
[SCR-ADMIN-001: Tap "Members"]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SCR-ADMIN-002: Admin Members Screen         │
│ • Active Members list                       │
│ • Pending Invitations list                  │
│ • Tap "Invite Member" button                │
└─────────────────────────┬───────────────────┘
                          ▼
┌─────────────────────────────────────────────┐
│ SHT-009: Invite Member Sheet                │
│ • Name (required)                           │
│ • Email (optional, at least one required)   │
│ • Phone (optional, at least one required)   │
│ • "Send Invitation" button                  │
│   → Calls send-invitation Edge Function     │
│   → Token generated, hashed, stored         │
│   → invite_url returned in response         │
└─────────────────────────┬───────────────────┘
                          ▼
┌─────────────────────────────────────────────┐
│ DLG-011: Invite URL Copy Dialog             │
│ • Displays invite URL                       │
│ • "Copy to Clipboard" button                │
│ • Admin shares URL manually (SMS/email)     │
└─────────────────────────┬───────────────────┘
                          ▼
[Pending Invitations list shows new entry]
       │
       ▼
[Invitee completes onboarding (UJ-01)]
       │
       ▼
[Admin receives admin_member_registered push]
[Pending → Active in members list]
[Audit log entry: user_invited]
```

**Admin can also:**
- Revoke pending invitation (DLG-007 confirm → `revoke-invitation` Edge Function)
- Deactivate active member (DLG-005 confirm → `deactivate-user` Edge Function)
- Remove member permanently (DLG-006 confirm → `remove-user` Edge Function)

---

## UJ-15: Admin Attendance Flow

**Actor:** Admin
**Trigger:** Past event needs attendance recording
**Goal:** Record which members attended vs. were absent

```
[SCR-ADMIN-001: Tap "Attendance"]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SCR-ADMIN-005: Admin Attendance Screen      │
│ • List of past events with no attendance    │
│ • Each card: event title, date, RSVP count  │
│ • Tap "Record" on an event                  │
└─────────────────────────┬───────────────────┘
                          ▼
┌─────────────────────────────────────────────┐
│ SHT-010: Attendance Recording Sheet         │
│ • Event header (title, date — read-only)    │
│ • Member list (all "Going" RSVPs)           │
│ • Per member row:                           │
│   [Avatar SM] [Name] [Attended|Absent]      │
│   Toggle: green "Attended" / red "Absent"   │
│ • "Submit Attendance" button                │
│   → Calls record-attendance Edge Function   │
│   → Batch records array submitted           │
│   → Audit log entry: attendance_recorded    │
└─────────────────────────┬───────────────────┘
                          ▼
[Event removed from "needs attendance" list]
[Attendance data feeds into:
  - Personal Analytics (events attended count)
  - Community Analytics (attendance rate)
  - Monthly Rankings (composite score)
  - Community Health Score]
[Success snackbar: "Attendance recorded"]
```

---

## UJ-16: Admin Content Moderation

**Actor:** Admin
**Trigger:** Content flagged by a member, or admin checks flagged queue
**Goal:** Review flagged content and take action

```
[Push notification: admin_flag]
   or [SCR-ADMIN-001: Tap "Flagged Content"]
       │
       ▼
┌─────────────────────────────────────────────┐
│ SCR-ADMIN-003: Admin Flagged Content Screen │
│ • Pending flags list                        │
│ • Each card shows:                          │
│   - Flagged content preview (post/comment)  │
│   - Content type badge (post or comment)    │
│   - Reporter name and avatar                │
│   - Reason text (if provided)               │
│   - Flag date                               │
│   - Two action buttons:                     │
│     [Delete] [Dismiss]                      │
│                                             │
│ Tap "Delete":                               │
│   → DLG-008: Confirm deletion               │
│   → resolve-flag Edge Function              │
│     (action: resolved_deleted)              │
│   → Content soft-deleted                    │
│   → Audit log: flag_resolved_deleted        │
│   → Flag removed from queue                 │
│                                             │
│ Tap "Dismiss":                              │
│   → resolve-flag Edge Function              │
│     (action: resolved_dismissed)            │
│   → Flag cleared, content untouched         │
│   → Audit log: flag_resolved_dismissed      │
│   → Flag removed from queue                 │
│                                             │
│ [All flags resolved → Empty state:          │
│  "All clear — no flagged content"]          │
└─────────────────────────────────────────────┘
```

---

## Journey Coverage Matrix

| Journey | Module | Screens Involved | Bottom Sheets | Dialogs | Notifications |
|---------|--------|-----------------|---------------|---------|---------------|
| UJ-01: Onboarding | Auth | AUTH-001, AUTH-002, AUTH-003, FEED-001 | — | — | connect_buddy_update |
| UJ-02: Login | Auth | UTIL-001, AUTH-001, AUTH-002, FEED-001 | — | — | — |
| UJ-03: Feed Usage | Feed | FEED-001, PROF-003 | SHT-002 | DLG-001, DLG-003 | — |
| UJ-04: Create Post | Feed | FEED-001 | SHT-001 | — | mention |
| UJ-05: Mention | Feed | FEED-001 | SHT-001 | — | mention |
| UJ-06: Create Event | Events | EVT-001 | SHT-003 | — | activity_created |
| UJ-07: RSVP | Events | EVT-001, EVT-002 | — | — | activity_reminder_24h, _1h |
| UJ-08: Vote in Poll | Events | EVT-002, EVT-003 | — | — | poll_reminder |
| UJ-09: Join Challenge | Growth | GRO-001, GRO-002 | — | — | challenge_ending, _ended |
| UJ-10: Log Progress | Growth | GRO-002 | SHT-007 | — | — |
| UJ-11: Give Recognition | Analytics | ANA-005 | SHT-008 | — | recognition_received |
| UJ-12: View Analytics | Analytics | ANA-001–006 | — | — | — |
| UJ-13: Notifications | Notifications | NOTIF-001 + any target | — | — | All 15 types |
| UJ-14: Admin Invitation | Admin | ADMIN-001, ADMIN-002 | SHT-009 | DLG-007, DLG-011 | admin_member_registered |
| UJ-15: Admin Attendance | Admin | ADMIN-001, ADMIN-005 | SHT-010 | — | — |
| UJ-16: Admin Moderation | Admin | ADMIN-001, ADMIN-003 | — | DLG-008 | admin_flag |
