# Manager Connect — Screen Inventory
> Version 1.0 · 63 screens across 8 modules

---

## Module 1: Feed

### 1.1 Feed Home
| Field | Value |
|---|---|
| **Purpose** | Primary discovery and community engagement screen |
| **Primary User** | All members |
| **Route** | `/feed` |
| **Parent Module** | Feed |
| **Dependencies** | Posts API, User profiles, Stories API |
| **Related Screens** | Post Detail, Profile, Events Hub |
| **Entry Points** | App launch (default), Bottom nav Home tab |
| **Exit Points** | Post Detail, Profile, Events Hub, Challenges Home |

### 1.2 Post Detail
| Field | Value |
|---|---|
| **Purpose** | Expanded post view with full comment thread and reactions |
| **Primary User** | All members |
| **Route** | `/feed/post/:postId` |
| **Parent Module** | Feed |
| **Dependencies** | Posts API, Comments API, Reactions API, User profiles |
| **Related Screens** | Feed Home, Profile, Recognition Detail |
| **Entry Points** | Feed card tap, Notification tap, Digest item tap |
| **Exit Points** | Back to Feed, Back to Digest (if entered from Digest) |

---

## Module 2: Profile

### 2.1 My Profile
| Field | Value |
|---|---|
| **Purpose** | Personal identity, leadership score, stats, reputation, recent activity |
| **Primary User** | The authenticated manager (self-view) |
| **Route** | `/profile` |
| **Parent Module** | Profile |
| **Dependencies** | User profile API, Stats API, Badge API, Activity API |
| **Related Screens** | Recognition History, Achievement Gallery, Activity Timeline |
| **Entry Points** | Bottom nav Profile tab |
| **Exit Points** | Recognition History, Achievement Gallery, Activity Timeline |

### 2.2 Manager Profile (Other User)
| Field | Value |
|---|---|
| **Purpose** | Viewing another manager's public profile |
| **Primary User** | All members |
| **Route** | `/profile/:userId` |
| **Parent Module** | Profile |
| **Dependencies** | User profile API, Stats API, Badge API, Connections API |
| **Related Screens** | My Profile, Feed Home, Event Attendees |
| **Entry Points** | Feed post author tap, Attendee list, Leaderboard row tap, Mentions hub tap |
| **Exit Points** | Back to entry point |

### 2.3 Recognition History
| Field | Value |
|---|---|
| **Purpose** | Collectible view of all recognitions received, filterable by category |
| **Primary User** | The authenticated manager (self) or viewing another profile |
| **Route** | `/profile/:userId/recognitions` |
| **Parent Module** | Profile |
| **Dependencies** | Recognition API |
| **Related Screens** | My Profile, Recognition Detail (from notification) |
| **Entry Points** | Profile tab "Recognition" tab, Notification recognition alert |
| **Exit Points** | Back to Profile |

### 2.4 Achievement Gallery
| Field | Value |
|---|---|
| **Purpose** | Collectible badge system with tiers, progress, and locked achievements |
| **Primary User** | The authenticated manager or viewing another profile |
| **Route** | `/profile/:userId/achievements` |
| **Parent Module** | Profile |
| **Dependencies** | Achievement API, Challenge completion API |
| **Related Screens** | My Profile, Milestones & Rewards |
| **Entry Points** | Profile tab "Achievements" tab |
| **Exit Points** | Back to Profile |

### 2.5 Activity Timeline
| Field | Value |
|---|---|
| **Purpose** | Chronological personal history of all platform activity |
| **Primary User** | The authenticated manager (self-view) |
| **Route** | `/profile/:userId/activity` |
| **Parent Module** | Profile |
| **Dependencies** | Activity API (posts, recognitions, events, challenges) |
| **Related Screens** | My Profile |
| **Entry Points** | Profile tab "Activity" tab |
| **Exit Points** | Back to Profile, deep-link to source content (post, event, challenge) |

---

## Module 3: Events

### 3.1 Events Hub
| Field | Value |
|---|---|
| **Purpose** | Event discovery — featured, trending, upcoming |
| **Primary User** | All members |
| **Route** | `/events` |
| **Parent Module** | Events |
| **Dependencies** | Events API, RSVP status API |
| **Related Screens** | Event Detail, Past Events Archive |
| **Entry Points** | Bottom nav Events tab |
| **Exit Points** | Event Detail |

### 3.2 Event Detail
| Field | Value |
|---|---|
| **Purpose** | Full event page with agenda, highlights, organizer, RSVP status |
| **Primary User** | All members |
| **Route** | `/events/:eventId` |
| **Parent Module** | Events |
| **Dependencies** | Events API, RSVP API, Attendees API |
| **Related Screens** | Events Hub, RSVP Screen, Event Attendees |
| **Entry Points** | Events Hub card tap, Feed event post tap, Notification event tap |
| **Exit Points** | RSVP Screen, Event Attendees, Back to Events Hub |

### 3.3 RSVP Experience
| Field | Value |
|---|---|
| **Purpose** | Going / Interested / Can't Attend selection with colleague context |
| **Primary User** | All members |
| **Route** | `/events/:eventId/rsvp` |
| **Parent Module** | Events |
| **Dependencies** | RSVP API, Attendees API (for colleague context) |
| **Related Screens** | Event Detail |
| **Entry Points** | Event Detail "RSVP" button, Feed event card RSVP, Notification "RSVP now" |
| **Exit Points** | Confirmation → back to Event Detail |

### 3.4 Event Attendees
| Field | Value |
|---|---|
| **Purpose** | Manager discovery — see who is attending with leadership scores and badges |
| **Primary User** | All members |
| **Route** | `/events/:eventId/attendees` |
| **Parent Module** | Events |
| **Dependencies** | Attendees API, User profiles API, Leadership scores API |
| **Related Screens** | Event Detail, Manager Profile |
| **Entry Points** | Event Detail "Who's attending" link |
| **Exit Points** | Manager Profile tap, Back to Event Detail |

### 3.5 Event Gallery
| Field | Value |
|---|---|
| **Purpose** | Post-event photo and moment showcase |
| **Primary User** | All members |
| **Route** | `/events/:eventId/gallery` |
| **Parent Module** | Events |
| **Dependencies** | Gallery API, Media storage |
| **Related Screens** | Event Detail, Past Events Archive |
| **Entry Points** | Event Detail (after event), Past Events Archive "View recap" |
| **Exit Points** | Back to Event Detail or Past Events |

### 3.6 Past Events Archive
| Field | Value |
|---|---|
| **Purpose** | Personal history of attended events with recap links and stats |
| **Primary User** | All members |
| **Route** | `/events/past` |
| **Parent Module** | Events |
| **Dependencies** | Events API (past filter), RSVP history API, Gallery API |
| **Related Screens** | Events Hub, Event Gallery |
| **Entry Points** | Events Hub "Past" link |
| **Exit Points** | Event Gallery |

---

## Module 4: Challenges & Wellness

### 4.1 Challenges Home
| Field | Value |
|---|---|
| **Purpose** | Challenge discovery with active challenge status and streak |
| **Primary User** | All members |
| **Route** | `/challenges` |
| **Parent Module** | Challenges |
| **Dependencies** | Challenges API, Streak API, User progress API |
| **Related Screens** | Challenge Detail, Wellness Hub |
| **Entry Points** | Bottom nav Challenges tab |
| **Exit Points** | Challenge Detail, Wellness Hub |

### 4.2 Challenge Detail
| Field | Value |
|---|---|
| **Purpose** | Full challenge page with progress ring, leaderboard, rewards |
| **Primary User** | All members |
| **Route** | `/challenges/:challengeId` |
| **Parent Module** | Challenges |
| **Dependencies** | Challenge API, Leaderboard API, Progress API, Rewards API |
| **Related Screens** | Challenges Home, Leaderboard, Progress Tracking |
| **Entry Points** | Challenges Home card tap, Notification challenge tap |
| **Exit Points** | Log today action, Full leaderboard |

### 4.3 Streak Center
| Field | Value |
|---|---|
| **Purpose** | Streak visualization — calendar, milestones, longest streak history |
| **Primary User** | All members |
| **Route** | `/challenges/streaks` |
| **Parent Module** | Challenges |
| **Dependencies** | Streak API, Activity history API |
| **Related Screens** | Challenges Home, Challenge Detail |
| **Entry Points** | Challenges Home streak pill tap |
| **Exit Points** | Back to Challenges |

### 4.4 Wellness Hub
| Field | Value |
|---|---|
| **Purpose** | Meditation, breathing, reflection, and wellness challenge management |
| **Primary User** | All members |
| **Route** | `/wellness` |
| **Parent Module** | Challenges (Wellness sub-section) |
| **Dependencies** | Wellness sessions API, Reflection API, Challenge API |
| **Related Screens** | Challenges Home, Streak Center |
| **Entry Points** | Challenges Home category filter "Wellness", Bottom nav Wellness icon |
| **Exit Points** | Session starts (in-context), Back to Challenges |

### 4.5 Challenge Leaderboard
| Field | Value |
|---|---|
| **Purpose** | Full-screen ranked leaderboard for active challenge |
| **Primary User** | All members |
| **Route** | `/challenges/:challengeId/leaderboard` |
| **Parent Module** | Challenges |
| **Dependencies** | Leaderboard API |
| **Related Screens** | Challenge Detail, Manager Profile |
| **Entry Points** | Challenge Detail leaderboard preview "See all" |
| **Exit Points** | Manager Profile (row tap), Back to Challenge Detail |

### 4.6 Monthly Community Challenge
| Field | Value |
|---|---|
| **Purpose** | Flagship org-wide monthly challenge with countdown and department bars |
| **Primary User** | All members |
| **Route** | `/challenges/monthly` |
| **Parent Module** | Challenges |
| **Dependencies** | Monthly challenge API, Department participation API, Countdown API |
| **Related Screens** | Challenges Home, Leaderboard |
| **Entry Points** | Challenges Home featured card, Notification challenge invite |
| **Exit Points** | Log activity action, Leaderboard |

### 4.7 Achievement Badges (Challenges context)
| Field | Value |
|---|---|
| **Purpose** | Challenge-specific badge showcase — same data as Profile Achievement Gallery |
| **Primary User** | All members |
| **Route** | `/challenges/achievements` |
| **Parent Module** | Challenges |
| **Dependencies** | Achievement API (same as Profile) |
| **Related Screens** | Challenge Detail, Profile Achievement Gallery |
| **Entry Points** | Challenges Home achievement section |
| **Exit Points** | Back |

### 4.8 Milestones & Rewards
| Field | Value |
|---|---|
| **Purpose** | Level progression system — Bronze/Silver/Gold/Platinum tier rewards |
| **Primary User** | All members |
| **Route** | `/challenges/milestones` |
| **Parent Module** | Challenges |
| **Dependencies** | Milestones API, Level API, Rewards API |
| **Related Screens** | Achievement Gallery, Personal Growth Dashboard |
| **Entry Points** | Profile level badge tap |
| **Exit Points** | Back |

### 4.9 Personal Growth Dashboard
| Field | Value |
|---|---|
| **Purpose** | Personal challenge stats, weekly rings, achievement strip, level journey |
| **Primary User** | All members |
| **Route** | `/challenges/growth` |
| **Parent Module** | Challenges |
| **Dependencies** | Stats API, Weekly activity API, Level API |
| **Related Screens** | My Profile, Milestones & Rewards |
| **Entry Points** | Profile tab, Challenges home |
| **Exit Points** | Achievement Gallery, Milestones |

---

## Module 5: Notifications

### 5.1 Notification Center
| Field | Value |
|---|---|
| **Purpose** | Chronological notification stream grouped by Today / This week / Earlier |
| **Primary User** | All members |
| **Route** | `/notifications` |
| **Parent Module** | Notifications |
| **Dependencies** | Notifications API, Realtime channel (new notifications) |
| **Related Screens** | All detail screens (notifications link out) |
| **Entry Points** | Bottom nav bell icon, Top bar bell icon tap |
| **Exit Points** | Any notification tap → target screen |

### 5.2 Notification Detail — Recognition Alert
| Field | Value |
|---|---|
| **Purpose** | Expanded recognition notification with quote, social proof, and share CTA |
| **Primary User** | All members |
| **Route** | `/notifications/recognition/:notifId` |
| **Parent Module** | Notifications |
| **Dependencies** | Notification API, Recognition API, Reactions API |
| **Related Screens** | Post Detail, Profile |
| **Entry Points** | Notification Center recognition card tap |
| **Exit Points** | "View post" → Post Detail, "Share" → system share, Back |

### 5.3 Activity Inbox
| Field | Value |
|---|---|
| **Purpose** | Organized view of mentions, replies, and comments grouped by type |
| **Primary User** | All members |
| **Route** | `/notifications/inbox` |
| **Parent Module** | Notifications |
| **Dependencies** | Mentions API, Comments API, Replies API |
| **Related Screens** | Post Detail, Mentions Hub |
| **Entry Points** | Notification Center (inbox shortcut) |
| **Exit Points** | Post thread tap, Back |

### 5.4 Mentions Hub
| Field | Value |
|---|---|
| **Purpose** | Dedicated @mention history with context quotes and reply actions |
| **Primary User** | All members |
| **Route** | `/notifications/mentions` |
| **Parent Module** | Notifications |
| **Dependencies** | Mentions API |
| **Related Screens** | Post Detail, Manager Profile |
| **Entry Points** | Notification Center filter "Mentions", Activity Inbox |
| **Exit Points** | Post thread, Manager Profile |

### 5.5 Event Updates
| Field | Value |
|---|---|
| **Purpose** | All notifications for a single event — RSVP, reminders, updates, attendees |
| **Primary User** | All members |
| **Route** | `/notifications/events/:eventId` |
| **Parent Module** | Notifications |
| **Dependencies** | Event notification API, Events API |
| **Related Screens** | Event Detail, RSVP Screen |
| **Entry Points** | Notification Center "Events" filter tap |
| **Exit Points** | Event Detail, RSVP |

### 5.6 Challenge Updates
| Field | Value |
|---|---|
| **Purpose** | Challenge-specific notifications — streak, rank, progress ring |
| **Primary User** | All members |
| **Route** | `/notifications/challenges/:challengeId` |
| **Parent Module** | Notifications |
| **Dependencies** | Challenge notification API, Progress API |
| **Related Screens** | Challenge Detail, Leaderboard |
| **Entry Points** | Notification Center "Challenges" filter tap |
| **Exit Points** | Challenge Detail, Leaderboard, "Log today" action |

### 5.7 Digest Summary
| Field | Value |
|---|---|
| **Purpose** | Daily/weekly executive summary of all activity — Today / This week / This month tabs |
| **Primary User** | All members |
| **Route** | `/notifications/digest` |
| **Parent Module** | Notifications |
| **Dependencies** | Digest API (aggregated from all modules) |
| **Related Screens** | Feed Home, Event Detail, Challenge Detail, Post Detail |
| **Entry Points** | Notification Center (digest card), Push notification "digest" |
| **Exit Points** | "Open feed" CTA, Any digest item tap → source screen |

---

## Module 6: Analytics

### 6.1 Analytics Home
| Field | Value |
|---|---|
| **Purpose** | Overview dashboard — community health score, 4 KPI cards, key insights, engagement chart |
| **Primary User** | All members (personal context), Senior leaders (org context) |
| **Route** | `/analytics` |
| **Parent Module** | Analytics |
| **Dependencies** | Analytics API, Community health API, Insights API |
| **Related Screens** | All analytics sub-screens |
| **Entry Points** | Bottom nav chart icon (or Profile sub-screen) |
| **Exit Points** | Any analytics detail screen |

### 6.2 Personal Insights
| Field | Value |
|---|---|
| **Purpose** | Individual manager's activity stats, monthly chart, org rank |
| **Primary User** | All members (own data) |
| **Route** | `/analytics/personal` |
| **Parent Module** | Analytics |
| **Dependencies** | Personal stats API, Ranking API |
| **Related Screens** | Analytics Home, Rankings |
| **Entry Points** | Analytics Home |
| **Exit Points** | Rankings, Back |

### 6.3 Community Health
| Field | Value |
|---|---|
| **Purpose** | Org-wide trend chart, department participation bars, top contributors |
| **Primary User** | Senior leaders, all members |
| **Route** | `/analytics/community` |
| **Parent Module** | Analytics |
| **Dependencies** | Community health API, Department API, Contributors API |
| **Related Screens** | Analytics Home |
| **Entry Points** | Analytics Home |
| **Exit Points** | Contributor profile tap, Back |

### 6.4 Recognition Insights
| Field | Value |
|---|---|
| **Purpose** | Recognition category breakdown + daily momentum dot-grid calendar |
| **Primary User** | All members (own), Senior leaders (org) |
| **Route** | `/analytics/recognition` |
| **Parent Module** | Analytics |
| **Dependencies** | Recognition analytics API |
| **Related Screens** | Recognition History |
| **Entry Points** | Analytics Home |
| **Exit Points** | Back |

### 6.5 Rankings & Leaderboards (Analytics context)
| Field | Value |
|---|---|
| **Purpose** | Monthly/all-time community rankings by category |
| **Primary User** | All members |
| **Route** | `/analytics/rankings` |
| **Parent Module** | Analytics |
| **Dependencies** | Leaderboard API (full 500-member ranked list) |
| **Related Screens** | Manager Profile (row tap) |
| **Entry Points** | Analytics Home |
| **Exit Points** | Manager Profile |

### 6.6 Monthly Review
| Field | Value |
|---|---|
| **Purpose** | Personal month-in-review — wins, growth bars, Apple Year In Review format |
| **Primary User** | All members |
| **Route** | `/analytics/monthly` |
| **Parent Module** | Analytics |
| **Dependencies** | Monthly summary API |
| **Related Screens** | Analytics Home |
| **Entry Points** | Analytics Home |
| **Exit Points** | Back |

### 6.7 Executive Summary
| Field | Value |
|---|---|
| **Purpose** | Strategic overview — status table, signal grid, multi-bar chart, export to PDF |
| **Primary User** | Senior leaders |
| **Route** | `/analytics/executive` |
| **Parent Module** | Analytics |
| **Dependencies** | Executive analytics API, PDF generation service |
| **Related Screens** | Analytics Home |
| **Entry Points** | Analytics Home (senior leader role) |
| **Exit Points** | PDF export, Back |

---

## Module 7: Admin

### 7.1 Admin Home
| Field | Value |
|---|---|
| **Purpose** | Executive workspace — community status, pending actions, upcoming events |
| **Primary User** | Community admins, HR coordinators |
| **Route** | `/admin` |
| **Parent Module** | Admin |
| **Dependencies** | Admin dashboard API, Moderation queue API, Events API |
| **Related Screens** | All admin sub-screens |
| **Entry Points** | Admin role user app launch |
| **Exit Points** | Any admin detail screen |

### 7.2 Community Overview
| Field | Value |
|---|---|
| **Purpose** | KPI cards, active trend chart, department participation, status breakdown |
| **Primary User** | Admins |
| **Route** | `/admin/community` |
| **Parent Module** | Admin |
| **Dependencies** | Community stats API, Department API |
| **Related Screens** | Admin Home |
| **Entry Points** | Admin Home |
| **Exit Points** | Back |

### 7.3 User Management
| Field | Value |
|---|---|
| **Purpose** | Manager directory with status dots, search, filter, invite, warn, suspend |
| **Primary User** | Admins |
| **Route** | `/admin/users` |
| **Parent Module** | Admin |
| **Dependencies** | Users admin API, Role management API |
| **Related Screens** | Invitation Management, Manager Profile |
| **Entry Points** | Admin bottom nav Users tab, Admin Home quick action |
| **Exit Points** | Manager Profile view, Invitation Management |

### 7.4 Invitation Management
| Field | Value |
|---|---|
| **Purpose** | Pending/accepted/expired invitation tracking with resend/revoke actions |
| **Primary User** | Admins |
| **Route** | `/admin/invitations` |
| **Parent Module** | Admin |
| **Dependencies** | Invitations API, Email service |
| **Related Screens** | User Management |
| **Entry Points** | Admin Home pending chip, User Management |
| **Exit Points** | Back |

### 7.5 Content Moderation
| Field | Value |
|---|---|
| **Purpose** | Reported content queue with Keep / Warn / Remove actions |
| **Primary User** | Admins |
| **Route** | `/admin/moderation` |
| **Parent Module** | Admin |
| **Dependencies** | Moderation API, Content reports API, User warning API |
| **Related Screens** | Post Detail (view context), User Management |
| **Entry Points** | Admin Home moderation chip, Admin bottom nav Moderation tab |
| **Exit Points** | Post Detail (context view), User warning → User Management |

### 7.6 Recognition Management
| Field | Value |
|---|---|
| **Purpose** | Recognition category trends, flagged recognitions, moderation |
| **Primary User** | Admins |
| **Route** | `/admin/recognition` |
| **Parent Module** | Admin |
| **Dependencies** | Recognition admin API, Recognition reports API |
| **Related Screens** | Recognition History (member view) |
| **Entry Points** | Admin Home |
| **Exit Points** | Back |

### 7.7 Event Administration
| Field | Value |
|---|---|
| **Purpose** | Event list with RSVP progress bars, organizer management, create/edit |
| **Primary User** | Admins, event organizers |
| **Route** | `/admin/events` |
| **Parent Module** | Admin |
| **Dependencies** | Events admin API, RSVP admin API |
| **Related Screens** | Event Detail (member view) |
| **Entry Points** | Admin bottom nav Events tab, Admin Home |
| **Exit Points** | Event Detail, Back |

### 7.8 Challenge Administration
| Field | Value |
|---|---|
| **Purpose** | Active challenge monitoring, participant counts, completion rates, reward confirmation |
| **Primary User** | Admins |
| **Route** | `/admin/challenges` |
| **Parent Module** | Admin |
| **Dependencies** | Challenge admin API, Reward confirmation API |
| **Related Screens** | Challenge Detail (member view), Leaderboard |
| **Entry Points** | Admin Home challenges chip |
| **Exit Points** | Back |

### 7.9 Community Health Review
| Field | Value |
|---|---|
| **Purpose** | Strategic SWOT-style review with recommended admin actions |
| **Primary User** | Admins, senior leaders |
| **Route** | `/admin/health` |
| **Parent Module** | Admin |
| **Dependencies** | Executive analytics API, Admin actions API |
| **Related Screens** | Analytics Executive Summary |
| **Entry Points** | Admin Home, Admin settings |
| **Exit Points** | Action links → relevant admin screens |

---

## Total Screen Count

| Module | Screens |
|---|---|
| Feed | 2 |
| Profile | 5 |
| Events | 6 |
| Challenges & Wellness | 9 |
| Notifications | 7 |
| Analytics | 7 |
| Admin | 9 |
| **Total** | **45 primary screens** |

> Note: Empty states, error states, modals, and onboarding flow are separate from this inventory and covered in `empty-states.md` and `error-states.md`.
