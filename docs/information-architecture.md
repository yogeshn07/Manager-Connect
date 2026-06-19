# Information Architecture

## Overview

Manager Connect organizes content into five primary domains, accessible via a bottom tab navigation bar. Each domain contains logically grouped sub-sections. A sixth domain — the Admin Panel — is accessible via the Profile tab and is visible only to admin-role users.

---

## Top-Level Structure

```
Manager Connect App
├── Tab 1: Feed
├── Tab 2: Events
├── Tab 3: Growth
├── Tab 4: Analytics
├── Tab 5: Profile
│   └── Admin Panel (admin users only, accessed via Profile menu)
└── [Connect Buddy — system component, posts appear in Feed]
```

---

## Domain 1: Feed (Tab 1)

The default landing screen after login. Aggregates all community content in a single reverse-chronological stream.

```
Feed
├── Pinned Announcements (admin-pinned, shown above all feed content)
├── Community Feed
│   ├── Member post cards (text, photos, emoji reactions, comments)
│   ├── Connect Buddy post cards (welcome messages, memories, highlights,
│   │   event/poll reminders, achievements, community updates)
│   └── Create Post button (FAB)
└── Post Detail
    ├── Full post content and photos
    ├── Emoji reactions
    └── Comments (with @mention support)
```

---

## Domain 2: Events (Tab 2)

The coordination hub for all community events and polls.

```
Events
├── Upcoming Events
│   ├── List view (default)
│   ├── Calendar view (toggle)
│   └── Filter by category: Games | Outings | Social Connect
│
├── Event Detail
│   ├── Title, category, date/time, location, description
│   ├── RSVP action (Going / Not Going / Maybe)
│   ├── Attendee / RSVP list
│   ├── Event updates from organizer
│   └── Attendance record (post-event, visible after event concludes)
│
├── Event Categories
│   ├── Games
│   │   └── Sub-types: Cricket | Badminton | Pickleball | Table Tennis | Other
│   ├── Outings
│   └── Social Connect
│       └── Sub-types: Coffee Connect | Lunch Meetup | Dinner Meetup | Other
│
├── Polls
│   ├── Active Polls list
│   ├── Poll Detail
│   │   ├── Question and answer options
│   │   ├── Vote action (single vote per member)
│   │   └── Results (vote counts and percentages, visible to all)
│   └── Create Poll (FAB / button)
│
├── Event History (past events archive)
│   └── Past Event Detail (read-only, includes attendance record)
│
└── Create Event button (FAB)
```

---

## Domain 3: Growth (Tab 3)

Tracks group fitness and wellness challenges.

```
Growth
├── Active Challenges
│   ├── Fitness Challenges (steps, distance, duration)
│   └── Wellness Challenges (custom goals)
│
├── Challenge Detail
│   ├── Goal type, target, dates, description
│   ├── Join / Leave challenge
│   ├── Log Progress (joined members only)
│   └── Leaderboard (all participants ranked by cumulative progress)
│
├── My Challenges (challenges I have joined)
├── Completed Challenges (archive of ended challenges)
└── Create Challenge button (FAB)
    └── Challenge type selector: Fitness | Wellness
```

---

## Domain 4: Analytics (Tab 4)

Engagement insights, rankings, and recognition. Recognition is a sub-feature of Analytics — not a standalone tab.

```
Analytics
├── Overview Dashboard
│   ├── Community Health Score (composite participation metric)
│   └── Quick-access cards for each sub-section
│
├── Personal Analytics
│   ├── Events attended / absent
│   ├── RSVP history
│   ├── Challenges joined and progress
│   └── Recognitions received and given
│
├── Community Analytics
│   ├── Total events held
│   ├── Overall RSVP and attendance rates
│   ├── Challenge participation rates
│   └── Recognition activity volume
│
├── Rankings
│   ├── Monthly Rankings (participation score for selected month)
│   └── All-Time Rankings (cumulative participation since launch)
│
└── Recognition
    ├── Monthly Recognition (recognitions in current / selected month)
    ├── Community Recognition (all-time recognition leaderboard)
    └── Give Recognition button (FAB / button)
        └── Give Recognition form (recipient, category tag, message)
```

---

## Domain 5: Profile (Tab 5)

User self-management and preferences. The Profile tab is always the fifth tab in the navigation bar.

```
Profile
├── My Profile
│   ├── Photo, name, role, bio
│   ├── Interest tags
│   ├── Recognitions received (summary)
│   └── Edit Profile
│
├── Notification Preferences
│   ├── Event reminders
│   ├── New events
│   ├── Poll notifications
│   ├── Recognitions received
│   ├── New challenges
│   ├── Challenge reminders
│   ├── Mentions
│   ├── Comments on my posts
│   └── Connect Buddy updates
│
├── App Settings
└── Log Out
```

---

## Domain 6: Admin Panel (Admin Role Only)

Accessed via the Profile tab menu. Not visible to regular members.

```
Admin Panel
├── Members
│   ├── Active members list
│   ├── Pending invitations
│   ├── Invite New Member
│   └── Member detail (role, joined date, deactivate, remove)
│
├── Flagged Content
│   ├── Flagged posts and comments queue
│   └── Resolution actions (delete / dismiss)
│
├── Pinned Announcements
│   ├── Currently pinned post
│   └── Pin a new post
│
├── Attendance Recording
│   ├── Select past event
│   └── Mark each member as Attended or Absent
│
└── Connect Buddy Management
    ├── View recent Connect Buddy posts
    ├── Suppress specific post types
    └── Manually trigger a post type
```

---

## System Component: Connect Buddy

Connect Buddy is not a navigation domain. It is a special system account in the database that generates automated posts into the Feed. It has no dedicated tab or menu item. Members see its posts in the Feed alongside member posts, visually distinguished by the Connect Buddy identity.

| Connect Buddy Post Type | Trigger |
|-------------------------|---------|
| Welcome message | New member joins the platform |
| Event reminder | Upcoming event (scheduled in advance) |
| Poll reminder | Poll approaching closing date |
| Achievement announcement | Member completes a challenge or milestone |
| Monthly highlight | Automated monthly community activity summary |
| Community update | Significant platform milestone |
| Memory | Auto-generated post referencing a past event from a previous month |

---

## Content Hierarchy Principles

1. **Recency first:** Feeds and lists are reverse chronological by default.
2. **Action proximity:** Primary actions (RSVP, vote, react, join challenge) are always available on the content card or detail screen — no unnecessary deep navigation required for simple interactions.
3. **Discoverability:** New events, polls, and challenges surface via Connect Buddy posts in the Feed so members do not need to check every tab.
4. **Recognition in context:** Recognition is part of Analytics, not a separate destination. This reinforces that recognition is a measure of community engagement, not an isolated social feature.
5. **Admin separation:** Admin functions are fully separated from the member experience. The Admin panel is never rendered or accessible to non-admin users.
6. **Connect Buddy transparency:** Connect Buddy posts are clearly labelled as system-generated to maintain trust and clarity within the community.
