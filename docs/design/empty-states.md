# Manager Connect — Empty States
> Version 1.0 · All module empty states defined

---

## Visual Specification (All Empty States)

All empty states follow the same layout:

```
Container: centered, padding: 40px 24px
Icon: 56px icon tile (category color), centered
Heading: 16px / 500, primary, centered, margin-top: 16px
Supporting text: 13px / 400, secondary, centered, max-width: 260px, margin-top: 8px
CTA button: primary button (full pill), margin-top: 20px, max-width: 200px, centered
Secondary link (optional): ghost link below button, 12px / 500, brand blue
```

The icon tile for empty states uses the module's category color — not a generic gray. This maintains visual warmth and avoids the "dead end" feeling of gray empty screens.

---

## Module 1: Feed

### 1.1 No Feed Posts (New user — first launch)

| | |
|---|---|
| **Icon** | `ti-speakerphone` — blue icon tile |
| **Heading** | "Your feed is waiting" |
| **Supporting text** | "Be the first to post something — share an update, recognize a colleague, or start a poll." |
| **Primary CTA** | "Share your first update" → opens composer |
| **Secondary link** | "Recognize a colleague →" |

### 1.2 No Feed Posts (Filtered view — no results for hashtag)

| | |
|---|---|
| **Icon** | `ti-hash` — blue icon tile |
| **Heading** | "Nothing here yet" |
| **Supporting text** | "No posts with this topic yet. Be the first to start the conversation." |
| **Primary CTA** | "Post with this topic" → opens composer pre-filled with hashtag |
| **Secondary link** | "Clear filter" |

### 1.3 No Comments

| | |
|---|---|
| **Icon** | `ti-message` — blue icon tile |
| **Heading** | "No comments yet" |
| **Supporting text** | "Be the first to add your perspective to this discussion." |
| **Primary CTA** | "Add a comment" → focuses comment composer |

---

## Module 2: Profile

### 2.1 No Recognitions (user has never received any)

| | |
|---|---|
| **Icon** | `ti-award` — amber icon tile |
| **Heading** | "No recognitions yet" |
| **Supporting text** | "Recognitions you receive from colleagues will appear here as collectible awards." |
| **Primary CTA** | None — passive empty state |
| **Secondary link** | "See how recognition works →" → recognition info screen (TBD) |

### 2.2 No Activity (new user, no activity history)

| | |
|---|---|
| **Icon** | `ti-timeline` — blue icon tile |
| **Heading** | "Your story starts here" |
| **Supporting text** | "Join a challenge, attend an event, or post an update — your activity will be recorded here." |
| **Primary CTA** | "Browse challenges" → Challenges Home |

### 2.3 No Achievements (no badges earned yet)

| | |
|---|---|
| **Icon** | `ti-shield` — purple icon tile |
| **Heading** | "Achievements unlock as you participate" |
| **Supporting text** | "Complete challenges, give recognitions, and attend events to earn your first badge." |
| **Primary CTA** | "Join a challenge" → Challenges Home |

---

## Module 3: Events

### 3.1 No Upcoming Events

| | |
|---|---|
| **Icon** | `ti-calendar-event` — blue icon tile |
| **Heading** | "No upcoming events" |
| **Supporting text** | "New events will appear here when they're scheduled. Check back soon." |
| **Primary CTA** | None for members |
| **Admin CTA** | "Create an event" → Event creation |

### 3.2 No Past Events (user has never attended any)

| | |
|---|---|
| **Icon** | `ti-history` — teal icon tile |
| **Heading** | "No events attended yet" |
| **Supporting text** | "Events you attend will be archived here with photos and highlights." |
| **Primary CTA** | "Browse upcoming events" → Events Hub |

### 3.3 No Attendees (event has 0 RSVPs)

| | |
|---|---|
| **Icon** | `ti-users` — blue icon tile |
| **Heading** | "Be the first to RSVP" |
| **Supporting text** | "No one has confirmed yet. Secure your spot and invite your colleagues." |
| **Primary CTA** | "RSVP now" → RSVP screen |

### 3.4 No Gallery Photos (gallery not yet published)

| | |
|---|---|
| **Icon** | `ti-camera` — blue icon tile |
| **Heading** | "Photos coming soon" |
| **Supporting text** | "Event photos will be published here after the event wraps up." |
| **Primary CTA** | None |

### 3.5 Event Search — No Results

| | |
|---|---|
| **Icon** | `ti-search` — blue icon tile |
| **Heading** | "No events found" |
| **Supporting text** | "Try a different search term or browse all upcoming events." |
| **Primary CTA** | "Clear search" |

---

## Module 4: Challenges

### 4.1 No Active Challenges (user hasn't joined any)

| | |
|---|---|
| **Icon** | `ti-trophy` — teal icon tile |
| **Heading** | "No active challenges yet" |
| **Supporting text** | "Join a challenge to start building your streak and competing on the leaderboard." |
| **Primary CTA** | "Browse challenges" → scrolls to featured section |

### 4.2 No Completed Challenges

| | |
|---|---|
| **Icon** | `ti-medal` — amber icon tile |
| **Heading** | "No completed challenges yet" |
| **Supporting text** | "Challenges you complete will appear here. Keep going!" |
| **Primary CTA** | None |

### 4.3 No Leaderboard Data (challenge just started)

| | |
|---|---|
| **Icon** | `ti-podium` — teal icon tile |
| **Heading** | "The race hasn't started yet" |
| **Supporting text** | "Log your first activity to appear on the leaderboard." |
| **Primary CTA** | "Log today's activity" → activity logger |

### 4.4 No Streak (first-time user, no streak started)

| | |
|---|---|
| **Icon** | `ti-flame` — amber icon tile |
| **Heading** | "Start your first streak" |
| **Supporting text** | "Complete a day of activity to light your first streak flame." |
| **Primary CTA** | "Log today" → Challenge Detail |

---

## Module 5: Notifications

### 5.1 Notification Center — All Caught Up

| | |
|---|---|
| **Icon** | `ti-checks` — teal icon tile |
| **Heading** | "You're all caught up" |
| **Supporting text** | "No new notifications. Check back after engaging with your community." |
| **Primary CTA** | "Go to feed" → Feed Home |

### 5.2 Notifications — Category Filter Empty

| | |
|---|---|
| **Icon** | `ti-filter` — blue icon tile |
| **Heading** | "No [category] notifications" |
| **Supporting text** | "You don't have any [recognition/event/challenge] notifications right now." |
| **Primary CTA** | "See all notifications" → clears filter |

### 5.3 Mentions Hub — No Mentions

| | |
|---|---|
| **Icon** | `ti-at` — purple icon tile |
| **Heading** | "No mentions yet" |
| **Supporting text** | "When colleagues mention you in posts, polls, or discussions, they'll appear here." |
| **Primary CTA** | None |

---

## Module 6: Analytics

### 6.1 Analytics Home — Insufficient Data (new community)

| | |
|---|---|
| **Icon** | `ti-chart-line` — blue icon tile |
| **Heading** | "Insights are warming up" |
| **Supporting text** | "Analytics become meaningful with 7+ days of community activity. Check back soon." |
| **Primary CTA** | None |

### 6.2 Personal Insights — No Activity This Month

| | |
|---|---|
| **Icon** | `ti-user` — blue icon tile |
| **Heading** | "No personal data yet this month" |
| **Supporting text** | "Engage with the community — posts, recognitions, events — to see your insights here." |
| **Primary CTA** | "Go to feed" → Feed Home |

### 6.3 Recognition Insights — No Recognition Activity

| | |
|---|---|
| **Icon** | `ti-award` — amber icon tile |
| **Heading** | "No recognition data this period" |
| **Supporting text** | "Recognition activity will appear here once colleagues start giving and receiving recognitions." |
| **Primary CTA** | "Give a recognition" → composer recognition mode |

---

## Module 7: Admin

### 7.1 Moderation Queue — Nothing to Review

| | |
|---|---|
| **Icon** | `ti-shield-check` — teal icon tile |
| **Heading** | "Queue is clear" |
| **Supporting text** | "No content reports pending. The community is running smoothly." |
| **Primary CTA** | None |

### 7.2 User Management — No Search Results

| | |
|---|---|
| **Icon** | `ti-user-search` — blue icon tile |
| **Heading** | "No managers found" |
| **Supporting text** | "Try a different name, email, or department filter." |
| **Primary CTA** | "Clear search" |

### 7.3 Invitation Management — No Pending Invitations

| | |
|---|---|
| **Icon** | `ti-mail-check` — teal icon tile |
| **Heading** | "All invitations are accepted" |
| **Supporting text** | "No pending invitations. Send new invites to grow your community." |
| **Primary CTA** | "Send new invitation" → invitation compose |

### 7.4 Invitation Management — No Expired Invitations

| | |
|---|---|
| **Icon** | `ti-mail-off` — gray icon tile |
| **Heading** | "No expired invitations" |
| **Supporting text** | "All invitations are still active or have been accepted." |
| **Primary CTA** | None |

---

## Universal Search — No Results

| | |
|---|---|
| **Icon** | `ti-search` — blue icon tile |
| **Heading** | "No results for "[query]"" |
| **Supporting text** | "Try different keywords or check the spelling." |
| **Primary CTA** | "Clear search" |
| **Secondary suggestions** | Show 3 recent searches (if applicable) |
