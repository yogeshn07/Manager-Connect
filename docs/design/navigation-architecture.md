# Manager Connect — Navigation Architecture
> Version 1.0 · Complete route hierarchy

---

## 1. Bottom Navigation

### 1.1 Member Navigation (all non-admin users)

```
Tab 1: Home          icon: ti-home            route: /feed
Tab 2: Events        icon: ti-calendar-event  route: /events
Tab 3: Challenges    icon: ti-trophy          route: /challenges
Tab 4: Notifications icon: ti-bell            route: /notifications
Tab 5: Profile       icon: ti-user            route: /profile
```

**Active state:** Icon color `#0C447C` + 4px dot below
**Inactive state:** Icon color `var(--color-text-tertiary)`, no dot
**Notification dot:** 7px red circle `#E24B4A` on bell icon top-right when unread count > 0

### 1.2 Admin Navigation (admin/coordinator roles only)

```
Tab 1: Home          icon: ti-home            route: /admin
Tab 2: Users         icon: ti-users           route: /admin/users
Tab 3: Moderation    icon: ti-flag            route: /admin/moderation
Tab 4: Events        icon: ti-calendar-event  route: /admin/events
Tab 5: Settings      icon: ti-settings        route: /admin/settings
```

**Rule:** Admin nav and member nav are completely separate. A user is in one mode or the other — never both. Admins who are also community members switch contexts explicitly (settings gear → "Switch to member view").

---

## 2. Primary Navigation (Screen-level routes)

### 2.1 Member Route Tree

```
/ (root)
├── /feed                           Feed Home
│   └── /feed/post/:postId          Post Detail
│
├── /events                         Events Hub
│   ├── /events/past                Past Events Archive
│   └── /events/:eventId            Event Detail
│       ├── /events/:eventId/rsvp   RSVP Experience
│       ├── /events/:eventId/attendees  Event Attendees
│       └── /events/:eventId/gallery   Event Gallery
│
├── /challenges                     Challenges Home
│   ├── /challenges/monthly         Monthly Community Challenge
│   ├── /challenges/streaks         Streak Center
│   ├── /challenges/achievements    Achievement Badges (Challenges context)
│   ├── /challenges/milestones      Milestones & Rewards
│   ├── /challenges/growth          Personal Growth Dashboard
│   └── /challenges/:challengeId    Challenge Detail
│       └── /challenges/:challengeId/leaderboard  Challenge Leaderboard
│
├── /wellness                       Wellness Hub
│
├── /notifications                  Notification Center
│   ├── /notifications/inbox        Activity Inbox
│   ├── /notifications/mentions     Mentions Hub
│   ├── /notifications/digest       Digest Summary
│   ├── /notifications/recognition/:notifId  Recognition Alert Detail
│   ├── /notifications/events/:eventId       Event Updates
│   └── /notifications/challenges/:challengeId  Challenge Updates
│
├── /analytics                      Analytics Home
│   ├── /analytics/personal         Personal Insights
│   ├── /analytics/community        Community Health
│   ├── /analytics/recognition      Recognition Insights
│   ├── /analytics/rankings         Rankings & Leaderboards
│   ├── /analytics/monthly          Monthly Review
│   └── /analytics/executive        Executive Summary (senior leader role)
│
└── /profile                        My Profile (self)
    ├── /profile/recognitions        Recognition History (self)
    ├── /profile/achievements        Achievement Gallery (self)
    ├── /profile/activity            Activity Timeline (self)
    └── /profile/:userId             Manager Profile (other user)
        ├── /profile/:userId/recognitions
        ├── /profile/:userId/achievements
        └── /profile/:userId/activity
```

### 2.2 Admin Route Tree

```
/admin                              Admin Home
├── /admin/community                Community Overview
├── /admin/users                    User Management
│   └── /admin/users/invitations    Invitation Management
├── /admin/moderation               Content Moderation
├── /admin/recognition              Recognition Management
├── /admin/events                   Event Administration
├── /admin/challenges               Challenge Administration
├── /admin/analytics                Analytics Administration
├── /admin/health                   Community Health Review
└── /admin/settings                 Admin Settings
```

### 2.3 Auth Routes

```
/auth
├── /auth/login                     Sign In
├── /auth/onboarding/step-1         Profile Setup
├── /auth/onboarding/step-2         First Recognition
└── /auth/onboarding/step-3         First Challenge Join
```

---

## 3. Secondary Navigation (Within-screen tabs)

### 3.1 Profile tabs

```
/profile (My Profile)
  Tab 1: Overview      (default)
  Tab 2: Recognition   → scrolls to recognition section (same route)
  Tab 3: Achievements  → scrolls to achievement section (same route)
  Tab 4: Activity      → scrolls to activity section (same route)
```
**Implementation note:** Profile tabs are scroll-anchors within a single screen, not route changes. The tab strip is sticky below the hero. Active tab underline: 2px amber (`#FAC775`).

### 3.2 Notification Center filter tabs

```
/notifications
  Filter: All (default)
  Filter: Recognition
  Filter: Mentions
  Filter: Events
  Filter: Challenges
```
**Implementation:** These are filter chips in a horizontal scroll strip — not traditional tabs. They filter the visible notification list in-place.

### 3.3 Challenge Leaderboard toggle

```
/analytics/rankings
  Toggle: Monthly (default)
  Toggle: All-time
Category chips: Community Impact (default) | Recognition | Participation | Wellness
```

### 3.4 Invitation Management tabs

```
/admin/users/invitations
  Tab 1: Pending (default, shows count badge)
  Tab 2: Accepted
  Tab 3: Expired
```

### 3.5 Digest tabs

```
/notifications/digest
  Tab 1: Today (default)
  Tab 2: This week
  Tab 3: This month
```

---

## 4. Detail Navigation

### 4.1 Back navigation rules

**Rule 1:** All detail screens show a back link in the top bar — left-aligned, `13px / 500`, `#185FA5`, with left-arrow icon + parent screen name.

**Rule 2:** The back label always reflects the originating screen:
```
Feed Home → Post Detail: "← Feed"
Events Hub → Event Detail: "← Events"
Past Events → Event Gallery: "← Past events"
Notification Center → Recognition Detail: "← Notifications"
Digest → Post Detail: "← Digest"
```

**Rule 3:** Never use a generic "← Back" — always use the parent name.

**Rule 4:** Scroll position is preserved on back navigation for all list screens (Feed, Notification Center, Challenges Home, Events Hub).

### 4.2 Event gallery back destination (dynamic)

The Event Gallery screen is reached from two entry points. The back label must reflect the entry point:
- From Event Detail → "← Event"
- From Past Events → "← Past events"

**Implementation:** Pass entry point as navigation parameter.

---

## 5. Deep Links

### 5.1 Push notification deep links

| Notification type | Deep link target |
|---|---|
| Recognition received | `/notifications/recognition/:notifId` |
| @mention | `/notifications/mentions` |
| Event reminder | `/notifications/events/:eventId` |
| Challenge milestone | `/notifications/challenges/:challengeId` |
| Achievement unlocked | `/profile/achievements` |
| Digest ready | `/notifications/digest` |
| Leaderboard rank change | `/challenges/:challengeId/leaderboard` |

### 5.2 Share links (external)

Recognition "Share award" button generates a shareable link:
`/share/recognition/:recognitionId` → public preview card (no auth required, limited view)

Executive Summary "Export PDF" is not a shareable link — it is a locally generated PDF via the device's share sheet.

---

## 6. Modal Navigation

### 6.1 Bottom sheets (slide-up modals)

| Trigger | Sheet content |
|---|---|
| Post Detail reaction hold | Reaction picker (5-item pill) |
| Moderation "Remove" tap | Confirm removal sheet |
| RSVP "Confirm" tap | Calendar invite prompt |
| Admin user flagged dot tap | Inline status expansion (not a modal — card expands) |
| Challenge "Log activity" tap | Activity logger (type + count input) |
| Wellness session tap | Session start sheet |

**Sheet anatomy:**
- White bg, `border-radius: 20px 20px 0 0`, `bottom: 0`
- Handle: 4×32px gray pill centered, 8px from top
- Content: 16–20px padding
- Backdrop: `rgba(0,0,0,0.45)`
- Dismiss: tap backdrop OR drag down

### 6.2 Confirmation dialogs (within bottom sheet)

Used for destructive actions only:
- Remove post (moderation)
- Revoke invitation
- Suspend user
- End challenge early

**Pattern:** Two-tap confirmation (first tap changes label, second tap within 3s confirms).

---

## 7. Navigation Anti-patterns (Do Not Do)

1. **Never nest more than 3 levels deep.** Root → Primary → Detail is the maximum depth.
2. **Never show bottom nav on detail screens.** Bottom nav only on root-level screens.
3. **Never use generic "Back" labels.** Always use parent screen name.
4. **Never crosslink member nav and admin nav.** Route prefixes (`/admin` vs `/`) enforce this.
5. **Never use tabs that change the URL route for profile.** Profile tabs are scroll anchors.
6. **Never open a new nav stack from a bottom sheet.** Bottom sheets are contextual — navigation must close them first.

---

## 8. Complete Screen Tree (Flat listing)

```
AUTH
  /auth/login
  /auth/onboarding/step-1
  /auth/onboarding/step-2
  /auth/onboarding/step-3

FEED (member)
  /feed
  /feed/post/:postId

EVENTS (member)
  /events
  /events/past
  /events/:eventId
  /events/:eventId/rsvp
  /events/:eventId/attendees
  /events/:eventId/gallery

CHALLENGES (member)
  /challenges
  /challenges/monthly
  /challenges/streaks
  /challenges/achievements
  /challenges/milestones
  /challenges/growth
  /challenges/:challengeId
  /challenges/:challengeId/leaderboard
  /wellness

NOTIFICATIONS (member)
  /notifications
  /notifications/inbox
  /notifications/mentions
  /notifications/digest
  /notifications/recognition/:notifId
  /notifications/events/:eventId
  /notifications/challenges/:challengeId

ANALYTICS (member)
  /analytics
  /analytics/personal
  /analytics/community
  /analytics/recognition
  /analytics/rankings
  /analytics/monthly
  /analytics/executive

PROFILE (member)
  /profile
  /profile/recognitions
  /profile/achievements
  /profile/activity
  /profile/:userId
  /profile/:userId/recognitions
  /profile/:userId/achievements
  /profile/:userId/activity

ADMIN
  /admin
  /admin/community
  /admin/users
  /admin/users/invitations
  /admin/moderation
  /admin/recognition
  /admin/events
  /admin/challenges
  /admin/analytics
  /admin/health
  /admin/settings
```

**Total routes: 44**
