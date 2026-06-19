# Notification Strategy

## Overview

Push notifications are a critical engagement mechanism for Manager Connect. With only 15–20 users, every notification must feel relevant and timely — not spammy. The strategy prioritizes high-value, action-oriented notifications with full user control over preferences.

---

## Notification Infrastructure

| Component | Technology |
|-----------|------------|
| Client token management | Firebase Messaging (`firebase_messaging` Flutter package) |
| iOS delivery | Apple Push Notification Service (APNs) via FCM |
| Android delivery | Firebase Cloud Messaging (FCM) |
| Foreground display | `flutter_local_notifications` Flutter package |
| Server-side dispatch | FCM HTTP v1 API (via Supabase Edge Function) |
| Token storage | Supabase `profiles.push_token` column (FCM device token) |

### Flow

```
[Triggering event in DB / Edge Function]
       ↓
[Supabase Edge Function: send-notification]
       ↓
[Fetch recipient's push_token from profiles]
       ↓
[Call Expo Push API with payload]
       ↓
[Expo routes to APNs (iOS) or FCM (Android)]
       ↓
[Device receives notification]
       ↓
[Tap opens app → deep links to relevant screen]
```

---

## Notification Categories

### Category 1: Event Notifications

| Event | Trigger | Recipients |
|-------|---------|------------|
| New event created | On event post | All members |
| Event reminder — 24 hours | Scheduled 24h before event_date | RSVPd Going and Maybe |
| Event reminder — 1 hour | Scheduled 1h before event_date | RSVPd Going |
| Event cancelled | On cancel action | All RSVPs (Going + Maybe) |
| Event updated | On organizer update post | All RSVPs (Going + Maybe) |

### Category 2: Poll Notifications

| Event | Trigger | Recipients |
|-------|---------|------------|
| New poll created | On poll post | All members |
| Poll closing soon | Scheduled 24h before poll closing_date | All members who have not yet voted |
| Poll results ready | On poll close (status change to closed) | All members |

### Category 3: Recognition Notifications

| Event | Trigger | Recipients |
|-------|---------|------------|
| New recognition received | On recognition post | Named recipients only |

Recognition is surfaced in the Analytics module (Monthly Recognition and Community Recognition). The notification deep-links to the recognition detail within Analytics.

### Category 4: Growth Challenge Notifications

| Event | Trigger | Recipients |
|-------|---------|------------|
| New challenge created | On challenge post | All members |
| Challenge ending in 24 hours | Scheduled | All joined participants |
| Challenge ended | On status change to ended | All joined participants |

### Category 5: Social Notifications

| Event | Trigger | Recipients |
|-------|---------|------------|
| Mentioned in a post | On @ mention | Mentioned user |
| Comment on own post | On comment insert | Post author |

### Category 6: Connect Buddy Notifications

Connect Buddy posts appear in the Feed automatically. Members may optionally receive a push notification when Connect Buddy posts certain high-value content types. Lower-signal post types (event reminders, poll reminders) are not double-notified via this category because those are already covered by Category 1 and Category 2.

| Event | Trigger | Recipients |
|-------|---------|------------|
| Connect Buddy posts monthly highlight | On monthly highlight post | All members (configurable; on by default) |
| Connect Buddy posts a memory | On memory post | All members (configurable; off by default) |
| Connect Buddy posts an achievement announcement | On achievement post | All members (configurable; on by default) |

### Category 7: Admin Notifications

| Event | Trigger | Recipients |
|-------|---------|------------|
| Content flagged | On flag action | Admin users only |
| New member registered | On invite accepted | Admin users only |

---

## User Notification Preferences

Each user can configure per-category opt-in/opt-out from the Notification Preferences screen in their Profile.

| Category | Preference Label | Default |
|----------|-----------------|---------|
| Event reminders | Event reminders (24h and 1h) | ON |
| New events | New event created | ON |
| Poll notifications | Poll created, closing soon, results | ON |
| Recognitions received | When someone recognizes me | ON |
| New challenges | New challenge created | ON |
| Challenge reminders | Challenge ending soon | ON |
| Mentions | When I'm @mentioned | ON |
| Comments on my posts | When someone comments | ON |
| Connect Buddy monthly highlights | Monthly highlight posts | ON |
| Connect Buddy achievements | Achievement announcement posts | ON |
| Connect Buddy memories | Memory posts | OFF |

Preferences are stored in the `notification_preferences` JSONB column on the `profiles` table.

---

## Notification Payload Design

Each notification payload includes:

```json
{
  "title": "Brief, action-oriented title",
  "body": "Concise context in one sentence",
  "data": {
    "type": "event_reminder | event_cancelled | event_updated | poll_new | poll_closing | poll_results | recognition | mention | comment | challenge_ending | challenge_ended | connect_buddy_highlight | connect_buddy_memory | connect_buddy_achievement | admin_flagged",
    "targetId": "<resource UUID>",
    "targetScreen": "/event/[id]"
  }
}
```

### Copywriting Guidelines

- **Title:** 3–5 words. Action-oriented. No generic "You have a notification."
- **Body:** Who did what, or what is happening. Maximum 60 characters.
- **Never:** Do not include private member content verbatim in notification bodies.

**Examples:**

| Event | Title | Body |
|-------|-------|------|
| Event reminder (24h) | "Cricket tomorrow morning!" | "Don't forget — 8AM at the ground" |
| Event reminder (1h) | "Cricket starts in 1 hour" | "Tap to see location and details" |
| New poll created | "New poll: vote now" | "Where should we go for the outing?" |
| Poll closing soon | "Poll closes tomorrow" | "Cast your vote before it's too late" |
| Poll results ready | "Poll results are in" | "See how the community voted" |
| Recognition received | "Priya recognized you!" | "For your leadership on the Q2 push" |
| Challenge ending | "Challenge ends tomorrow" | "10K Steps — log your progress now" |
| Connect Buddy highlight | "Your monthly highlights" | "Here's what the community did in May" |
| Connect Buddy achievement | "New achievement unlocked!" | "Rahul completed the Steps Challenge" |
| @mention | "Arjun mentioned you" | "In a post on the community feed" |

---

## Notification Volume Control

- **Batching:** If multiple notifications trigger in quick succession (e.g., 5 comments on one post), batch into one: "5 new comments on your post."
- **No double-notification:** Event reminders and poll reminders sent via Category 1 and Category 2 are not re-sent under the Connect Buddy category, even when Connect Buddy also posts a reminder in the Feed.
- **Quiet hours:** V1 does not enforce quiet hours. V2 will introduce a configurable quiet window (e.g., 10 PM – 7 AM).
- **Connect Buddy memories:** Off by default to prevent notification fatigue from auto-generated historical content.
- **No marketing notifications:** The platform never sends promotional or platform-push notifications.

---

## Token Lifecycle

| Event | Action |
|-------|--------|
| App first launch | Request notification permission; store token in `profiles.push_token` |
| Permission denied | Gracefully downgrade; no notifications sent; re-prompt after 30 days |
| Token refresh (device or OS change) | Update `profiles.push_token` on next app open |
| User logged out | Nullify `push_token` in database; stop all dispatch to that token |
| User deactivated | Nullify `push_token`; stop all dispatch immediately |
