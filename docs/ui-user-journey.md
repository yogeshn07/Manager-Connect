# UI User Journey

**Date:** 2026-06-21

---

## 1. First-Time User Journey

```
Admin sends invitation (email/phone)
        │
        ▼
User opens app
        │
        ▼
    ┌─────────┐
    │  Splash  │  Session check → no session
    └────┬────┘
         │ redirect
         ▼
    ┌──────────┐
    │ Welcome  │  "I have an invitation code" → expand token field
    │  Screen  │  Enter token → Validate → Pre-fill email
    └────┬────┘  Enter email → "Send OTP"
         │ push
         ▼
    ┌──────────┐
    │ Verify   │  Enter 6-digit code
    │   OTP    │  Verify → Session created
    └────┬────┘
         │ guard redirect (no profile)
         ▼
    ┌──────────┐
    │ Create   │  Name*, Title, Bio, Interest Tags
    │ Profile  │  "Create Profile" → create-profile EF
    └────┬────┘  Connect Buddy posts welcome message
         │ guard redirect (onboarding complete)
         ▼
    ┌──────────┐
    │   Feed   │  Home screen — first post visible
    │  (Home)  │  (Connect Buddy welcome post)
    └──────────┘
```

**Database state after onboarding:**
- `auth.users`: new row
- `profiles`: `onboarding_completed=true`, `is_active=true`, `app_role=member`
- `invitations`: `status=accepted`, `accepted_by` set
- `posts`: Connect Buddy welcome post

---

## 2. Returning User Journey

```
User opens app
        │
        ▼
    ┌─────────┐
    │  Splash  │  Session check → valid session found
    └────┬────┘  Profile fetch → onboarding_completed=true
         │ redirect
         ▼
    ┌──────────┐
    │   Feed   │  Last-seen feed loads
    └──────────┘
```

**Expired session flow:**
```
Splash → no valid session → Welcome → email → OTP → verify → Feed
```

---

## 3. Daily Usage Journey

### Browse Feed
```
Feed (tab) ─── scroll paginated posts
    │           pull-to-refresh
    │           new posts appear via realtime
    │
    ├── tap post ──► Post Detail
    │                   ├── reactions (tap emoji chip to toggle)
    │                   ├── comments (read list)
    │                   ├── add comment (input bar)
    │                   └── delete own post (app bar icon)
    │
    └── FAB ──► Create Post (modal)
                    write text → "Post" → feed refreshes
```

### Browse Events
```
Events (tab) ─── upcoming/past toggle
    │              category filter chips (All/Games/Outings/Social)
    │              pull-to-refresh
    │
    ├── tap activity ──► Activity Detail
    │                       ├── event info (date, location, type)
    │                       ├── RSVP (SegmentedButton: Going/Maybe/No)
    │                       ├── attendee list (bottom section)
    │                       ├── organizer updates
    │                       └── organizer: cancel / post update
    │
    └── FAB ──► Create Activity (modal)
                    title, category, type, date picker, location
```

### Browse Polls
```
Activity Detail ──► linked poll ──► Poll Detail
                                      ├── question
                                      ├── options (tap to vote)
                                      ├── vote bars (percentage)
                                      └── closed poll = read-only
```

### Growth & Recognition
```
Growth (tab) ─── active/completed challenges
    │              "Recognition" (app bar button)
    │
    ├── tap challenge ──► Challenge Detail
    │                       ├── info (type, goal, dates)
    │                       ├── join / leave
    │                       ├── leaderboard (sorted by total value)
    │                       └── "Log Progress" (bottom sheet: date, value, note)
    │
    ├── FAB ──► Create Challenge (placeholder)
    │
    └── Recognition button ──► Recognition Feed
                                  ├── recognition cards (giver, recipients, category badge)
                                  └── FAB ──► Create Recognition (modal)
                                                 category chips + member picker + message
```

### Notifications
```
App bar bell icon ──► Notification Center
                          ├── notification list (bold = unread)
                          ├── tap = mark read
                          ├── "Mark all read" (app bar)
                          └── pull-to-refresh
                          
Realtime: new notifications increment badge
```

### Analytics
```
Analytics (tab) ─── Personal / Community toggle
    │
    ├── Personal tab
    │       stat cards: events, challenges, recognitions, posts, score
    │
    ├── Community tab
    │       health score, engagement rates, member count
    │
    └── "Rankings" button ──► Rankings Screen
                                 Monthly / All-Time toggle
                                 ranked list tiles with scores
```

### Profile
```
Profile (tab) ─── avatar, name, title, bio
    │               interest tag chips
    │               notification preference toggles (9 categories)
    │               "Sign Out" button
    │
    └── edit icon ──► Edit Profile (modal)
                          name, title, bio, interest tags
                          "Save" → profile updated
```

---

## 4. Admin Journey

```
App bar admin icon ──► Admin Dashboard
                          ├── count cards (members, invitations, flags, posts, events, challenges)
                          ├── "Members" ──► Member Management
                          │                    ├── member list (name, role, status)
                          │                    └── tap ──► deactivate / reactivate (confirmation dialog)
                          │
                          ├── "Invitations" ──► Invitation Management
                          │                       ├── invitation list (name, email, status)
                          │                       ├── "Send Invitation" (dialog: name + email)
                          │                       └── "Revoke" on pending invitations
                          │
                          ├── "Moderation" ──► Moderation Queue
                          │                      ├── pending flags (reporter, type, reason)
                          │                      └── "Delete" / "Dismiss" (confirmation dialog)
                          │
                          └── "Attendance" ──► Record Attendance (placeholder)

Admin access: guarded by route guard (session.role == AppRole.admin)
Member trying /admin/* → redirected to /feed
```

---

## 5. Screen Map

```
┌─────────────────────────────────────────────────────────────┐
│                     MANAGER CONNECT                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  AUTH                                                       │
│  ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌──────────────┐ │
│  │ Splash  │→ │ Welcome │→ │ Verify   │→ │ Create       │ │
│  │         │  │         │  │ OTP      │  │ Profile      │ │
│  └─────────┘  └─────────┘  └──────────┘  └──────────────┘ │
│                                                             │
│  MAIN TABS (5-tab NavigationBar)                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Feed  │  Events  │  Growth  │ Analytics │ Profile  │  │
│  └───┬────┴────┬─────┴────┬─────┴─────┬─────┴────┬────┘  │
│      │         │          │           │          │         │
│  ┌───┴───┐ ┌───┴───┐ ┌───┴────┐ ┌────┴───┐ ┌───┴────┐   │
│  │Post   │ │Activity│ │Chall.  │ │Rankings│ │Edit    │   │
│  │Detail │ │Detail  │ │Detail  │ │        │ │Profile │   │
│  └───────┘ └───────┘ └────────┘ └────────┘ └────────┘   │
│                │                                           │
│            ┌───┴────┐                                      │
│            │Poll    │                                      │
│            │Detail  │                                      │
│            └────────┘                                      │
│                                                             │
│  MODALS: Create Post, Create Activity, Create Poll,        │
│          Create Recognition, Edit Profile, Log Progress     │
│                                                             │
│  STACK: Notification Center, Recognition Feed               │
│                                                             │
│  ADMIN (protected)                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │Dashboard │→ │Members   │  │Invites   │  │Moderation│  │
│  │          │  │Mgmt      │  │Mgmt      │  │Queue     │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Completion Assessment

### Screens Completed: 25 of 27

| Status | Count | Details |
|--------|-------|---------|
| Fully implemented | 25 | All auth, feed, events, polls, recognition, challenges, notifications, analytics, profile, admin screens |
| Placeholder (inline) | 1 | Create Challenge modal — `_CreateChallengePlaceholder` in challenge_list_screen.dart |
| Placeholder (route) | 1 | Record Attendance — `PlaceholderScreen` at `/admin/attendance` |
| **Total routed** | **27** | |

### Placeholder-Free Verification

| Route | Renders Real Screen | Placeholder |
|-------|-------------------|-------------|
| `/` | SplashScreen | No |
| `/welcome` | WelcomeScreen | No |
| `/verify-otp` | VerifyOtpScreen | No |
| `/create-profile` | CreateProfileScreen | No |
| `/feed` | FeedScreen | No |
| `/events` | ActivitiesListScreen | No |
| `/growth` | ChallengeListScreen | No |
| `/analytics` | AnalyticsScreen | No |
| `/profile` | ProfileScreen | No |
| `/post/:id` | PostDetailScreen | No |
| `/event/:id` | ActivityDetailScreen | No |
| `/poll/:id` | PollDetailScreen | No |
| `/challenge/:id` | ChallengeDetailScreen | No |
| `/analytics/ranking` | RankingsScreen | No |
| `/notifications` | NotificationCenterScreen | No |
| `/admin` | AdminDashboardScreen | No |
| `/admin/members` | MemberManagementScreen | No |
| `/admin/invitations` | InvitationManagementScreen | No |
| `/admin/flagged` | ModerationQueueScreen | No |
| `/admin/attendance` | **PlaceholderScreen** | **YES** |

### TODO/FIXME in Codebase: 0

No `TODO` or `FIXME` comments exist in any screen or provider file. The only "Coming soon" text is in the `_CreateChallengePlaceholder` widget.

### Unused Route Constants: 5

`pollDetail`, `recognitionDetail`, `memberProfile`, `adminAnnouncements`, `adminConnectBuddy` — defined in `RouteNames` but not wired in the router. These were eliminated during scope optimization.
