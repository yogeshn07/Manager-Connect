# Manager Connect — User Flows
> Version 1.0 · All primary journeys mapped

---

## Flow 1: Authentication

```
App Launch (cold start)
  → Splash screen (brand logo, 1.5s)
  → Check auth token
    ├── Valid token → Feed Home
    └── No token / expired →
          Sign In screen
            ├── Success → Onboarding check
            │     ├── First time user → Onboarding Flow (see Flow 2)
            │     └── Returning user → Feed Home
            └── Failure → Error state (see error-states.md)
```

---

## Flow 2: Onboarding (New User)

```
Onboarding Step 1 — Profile setup
  → Enter name, role, department
  → Upload profile photo (optional, skip available)

Onboarding Step 2 — First recognition
  → "Recognise a colleague to get started"
  → Select colleague from directory
  → Select category
  → Add message
  → Post recognition → Feed Home (with recognition posted)

Onboarding Step 3 — Join first challenge
  → "Join a challenge to start your streak"
  → Show 3 recommended challenges
  → Tap to join or "Skip for now"
  → Challenges Home

→ Feed Home (onboarding complete, welcome state dismissed)
```

---

## Flow 3: Feed

### 3.1 Main Feed Loop
```
Feed Home
  ├── Tap story ring → Story/Live view (future feature, ring state only)
  ├── Tap composer "Share something" → Post Composer
  │     ├── Share Update → Text post → Feed (post appears)
  │     ├── Recognition → Recognition Composer → Feed
  │     ├── Poll → Poll Composer → Feed
  │     └── Event → Event creation (admin/organizer only) → Feed
  ├── Tap trending chip → Feed filtered by hashtag
  ├── Tap "Recent" → Feed sorted by recency
  └── Tap any feed card → Post Detail

Post Detail
  ├── Tap reaction → Reaction recorded, engagement count updates
  ├── Tap reaction picker item → Category reaction recorded
  ├── Tap "Comment" → Comment composer focuses
  ├── Type comment → Submit → Comment appears in thread
  ├── Tap existing comment → Reply composer focuses
  ├── Tap commenter avatar → Manager Profile
  └── Back → Feed Home (scroll position preserved)
```

### 3.2 Recognition Post Flow
```
Feed Home
  → Tap recognition card
  → Post Detail (recognition view with blue hero)
    ├── Reactions visible
    ├── Tap "View award →" → Recognition History (scrolled to this award)
    ├── Tap "Share this recognition" → System share sheet
    └── Back → Feed
```

### 3.3 Poll Interaction
```
Feed Home → Poll card
  → Tap an option → Vote recorded, bars animate to new percentages
  → Counts update in real time
  → Back → Feed (voted state persisted)
```

---

## Flow 4: Recognition

### 4.1 Give a Recognition
```
Feed Home → Composer → "Recognize" button
  → Recognition Composer
    → Search or browse colleague
    → Select recognition category (5 categories)
    → Write reason (text input)
    → Post
  → Feed Home (recognition card appears in feed)
  → Colleague receives notification → Recognition Alert
```

### 4.2 Receive a Recognition
```
Push notification OR in-app notification dot
  → Notification Center
  → Tap recognition card
  → Recognition Alert Detail
    ├── Read quote, see social proof
    ├── Tap "Share this recognition" → System share sheet
    ├── Tap "View post" → Post Detail (recognition post)
    └── Back → Notification Center

Profile → Recognition History
  → Browse all received recognitions
  → Filter by category
  → Tap "Share award" on any card → System share sheet
```

---

## Flow 5: Event RSVP

### 5.1 Discover and RSVP
```
Events Hub (or Feed event card)
  → Event Detail
    ├── Read agenda, highlights
    ├── See attendee momentum bar (seats remaining)
    ├── Tap "RSVP — Save my spot" button
    → RSVP Screen
      → See colleague context (who else is going)
      → Select: Going / Interested / Can't Attend
      → Tap "Confirm — I'm going"
      → Calendar invite added (OS-level)
      → Back to Event Detail (RSVP state reflected)
  └── Tap attendee avatar strip → Event Attendees
        → Browse all 84+ attendees
        → Filter by department
        → Tap attendee → Manager Profile
```

### 5.2 Event Reminder Flow
```
Push notification (day before event)
  → Event Updates screen (for this event)
  → Review schedule and venue
  → Tap "View event" → Event Detail
```

### 5.3 Post-Event Gallery Flow
```
Notification (event gallery published)
  → Event Gallery
    ├── Browse highlights and photo grid
    ├── Tap heart icon → Like photo
    └── MVP recognition card visible
  → Past Events Archive (this event card visible)
    → "View recap" → Event Gallery
```

---

## Flow 6: Challenge Participation

### 6.1 Join a Challenge
```
Challenges Home
  → Tap featured challenge card
  → Challenge Detail
    → See goal, leaderboard preview, rewards
    → Tap "Log today's steps" (if already joined) OR "Join →" (if not)
    → If joining: confirmation state, card updates to "Joined"
    → Log activity: input steps/activity
    → Progress ring updates, day pip marks as done
    → Leaderboard position may change
```

### 6.2 Streak Loop
```
Daily: Push notification "Log your steps to keep your streak"
  → Challenge Detail
  → Log activity
  → Day pip turns green
  → Ring percentage increases
  → If streak milestone hit:
      → Full-screen celebration overlay (3 seconds)
      → Badge unlocked notification
  → Leaderboard updates
```

### 6.3 Challenge Completion
```
Challenge Detail (day 30)
  → All day pips filled
  → Ring shows 100%
  → Completion celebration
  → Badge earned
  → Rewards card shows "Earned" state
  → Challenges Home: card moves to "Completed" section
  → Profile Achievement Gallery: new badge visible
```

### 6.4 Monthly Community Challenge
```
Challenges Home → Monthly challenge featured card
  → Monthly Community Challenge screen
    → See countdown timer
    → See org-wide participation bars
    → See leaderboard
    → Already enrolled: "Log activity" button
    → Not enrolled: auto-enrolled or "Join" CTA
  → Log activity → same as 6.1
```

---

## Flow 7: Wellness

```
Challenges Home → Category filter "Wellness" → Wellness Hub
  (OR bottom nav Wellness icon if implemented)

Wellness Hub
  ├── Tap session type (Meditation, Breathing, Reflection, Gratitude)
  │     → Session starts (full-screen immersive view, not designed — TBD)
  │     → Session complete → Streak +1
  ├── Tap "Start →" on daily reflection
  │     → Write reflection in text input
  │     → Submit → Reflection streak +1
  └── Tap wellness challenge → Challenge Detail
```

---

## Flow 8: Notifications

### 8.1 Notification Triage
```
Bottom nav bell icon (with red dot = unread count)
  → Notification Center
    ├── Tap any card → relevant detail screen
    ├── Filter by category (Recognition, Mentions, Events, Challenges)
    ├── Swipe right on card → Mark as read
    ├── Swipe left on card → "Mute this type" or "Delete"
    ├── Tap "Mark all read" (top right) → All cleared
    └── Scroll down → "This week" and "Earlier" sections
```

### 8.2 Digest Flow
```
Push notification: "Your daily digest is ready"
  → Digest Summary (Today tab)
    ├── Tap "Your wins today" item → Recognition Alert or Challenge Detail
    ├── Tap "Events" item → Event Detail
    ├── Tap "Mentions" item → Mentions Hub
    ├── Tap "Catch up on the feed" amber CTA → Feed Home
    └── Switch tabs: Today / This week / This month
```

---

## Flow 9: Analytics

### 9.1 Member Analytics Journey
```
Profile (bottom nav) → "My insights" card
  → Analytics Home
    ├── Community Health Score visible in hero
    ├── 4 KPI cards: Engagement, Wellness, Participation, Recognition
    ├── Insight cards: tap any → relevant detail screen
    ├── Bar chart: weekly engagement overview
    └── Navigate to sub-screens:
          Personal Insights → own activity stats + monthly chart
          Community Health → trend chart + department bars
          Recognition Insights → category breakdown + momentum calendar
          Rankings → leaderboard (monthly/all-time)
          Monthly Review → key wins + growth bars
          Executive Summary (senior leader role only)
```

### 9.2 Executive Summary Export
```
Analytics Home → Executive Summary
  → Read status table, signals, multi-bar chart
  → Tap "Export PDF" (top right)
  → Loading state: spinner 800ms
  → System share sheet with PDF
```

---

## Flow 10: Admin

### 10.1 Admin Daily Workflow
```
App launch (admin role)
  → Admin Home
    → Review hero: "X items need attention"
    → Pending action chips: count of each category
    → Priority action cards: tap any → relevant admin screen
    → Quick actions: common tasks

Moderation Queue (3 pending):
  → Admin Home "Moderation" chip OR Admin nav Moderation tab
  → Content Moderation screen
  → Tap each card: review content
  → Decision: Keep post / Warn user / Remove
    ├── Remove: confirmation bottom sheet → confirm → card slides off
    ├── Warn: user receives warning notification
    └── Keep: card dismissed
```

### 10.2 Invitation Management Flow
```
Admin Home → "Invites (12)" chip
  → Invitation Management → Pending tab
  → Cards expiring within 48hrs shown first
  → Tap "Resend" → email re-sent, chip changes to "Sent" (2s)
  → Tap "Revoke" → button changes to "Tap to confirm" → 3s window → confirm → card removed
  → Switch to Accepted / Expired tabs
```

### 10.3 Challenge Reward Confirmation
```
Admin Home → action card "Badminton challenge ending in 3 days"
  → Challenge Administration
  → Find Badminton challenge card
  → Tap "Confirm rewards"
  → Reward distribution confirmation screen (bottom sheet)
  → Confirm → top 5 receive badges + notifications
```

### 10.4 User Management Flow
```
Admin nav → Users tab
  → User Management
  → Search or filter
  → Tap user card to expand inline actions
    ├── Standard active user: View profile, Edit
    ├── Flagged/warned user: View profile, Edit, Suspend (danger)
    ├── Inactive user: View profile, Send nudge (email)
  → Tap avatar status dot on flagged user:
      → Inline expansion (card grows 60px)
      → Options: Clear warnings / Issue final warning / Suspend
```

---

## Flow 11: Search

```
Top bar search icon (Feed, Events, Challenges, Admin)
  → Search overlay / screen
  → Type query
  → Results: Managers (profiles), Posts, Events, Challenges
  → Tap result → relevant screen
  → No results → Empty state with suggestions

(Note: Search screen is not independently designed — uses modal overlay with existing components)
```

---

## Alternate Paths Summary

| Flow | Primary Path | Alternate Path |
|---|---|---|
| Recognition detail | Feed → Post Detail | Notification → Recognition Alert → Post Detail |
| Event RSVP | Events Hub → Event Detail → RSVP | Feed event card → RSVP → Event Detail |
| Challenge join | Challenges Home → Challenge Detail | Notification invite → Challenge Detail |
| Gallery | Past Events → Gallery | Event Detail (post-event) → Gallery |
| Analytics | Profile → Analytics | Bottom nav chart icon |
| Admin moderation | Admin Home chip | Admin nav Moderation tab |
| Digest | Push notification | Notification Center (digest card) |
