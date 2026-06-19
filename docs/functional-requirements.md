# Functional Requirements

## FR-01: Authentication and Access Control

| ID | Requirement |
|----|-------------|
| FR-01.1 | The platform admin can invite users via email or mobile number. |
| FR-01.2 | Users can register only via a valid invitation link. |
| FR-01.3 | Authentication uses OTP (one-time password) via email or SMS. No passwords. |
| FR-01.4 | Sessions persist on device with secure token refresh. |
| FR-01.5 | The admin can deactivate or remove a user, immediately revoking access. |
| FR-01.6 | Deactivated users receive a graceful access-denied message on next open. |

---

## FR-02: User Profiles

| ID | Requirement |
|----|-------------|
| FR-02.1 | Each user has a profile with: full name, profile photo, role/title, a short bio, and interest tags. |
| FR-02.2 | Users can edit their own profile at any time. |
| FR-02.3 | All community members can view each other's profiles. |
| FR-02.4 | Interest tags are predefined (e.g., Running, Hiking, Food, Cycling, Cricket, Gaming). |
| FR-02.5 | Admin can view all profiles but cannot edit other users' profiles. |
| FR-02.6 | Each member's profile displays recognitions they have received. |
| FR-02.7 | Profile settings include notification preferences and logout. |

---

## FR-03: Community Feed

| ID | Requirement |
|----|-------------|
| FR-03.1 | Users can create text posts in the community feed. |
| FR-03.2 | Posts can include one or more photos. |
| FR-03.3 | Users can react to posts (emoji reactions). |
| FR-03.4 | Users can comment on posts. |
| FR-03.5 | Users can mention other members using @ notation. |
| FR-03.6 | Mentioned users receive a push notification. |
| FR-03.7 | Users can delete their own posts or comments. |
| FR-03.8 | Admins can delete any post or comment for moderation purposes. |
| FR-03.9 | Users can flag a post or comment as inappropriate. |
| FR-03.10 | Admin-pinned announcements are displayed at the top of the feed above all other content. |
| FR-03.11 | Connect Buddy posts appear in the feed alongside member posts and are visually distinguished by the Connect Buddy account identity. |
| FR-03.12 | Memories — auto-generated Connect Buddy posts referencing past events or activities from previous months — appear in the feed. |

---

## FR-04: Events

| ID | Requirement |
|----|-------------|
| FR-04.1 | Any member can create an event with: title, description, category, date/time, location, and optional cost note. |
| FR-04.2 | Events are categorized as one of: Games (Cricket, Badminton, Pickleball, Table Tennis, Other), Outings, or Social Connect (Coffee Connect, Lunch Meetup, Dinner Meetup, Other). |
| FR-04.3 | Members can RSVP to an event with Going / Not Going / Maybe. |
| FR-04.4 | The event creator can view the full RSVP list. |
| FR-04.5 | All members can view upcoming events in a list view and a calendar view. |
| FR-04.6 | Automated reminders are sent 24 hours before an event to members who RSVPd Going or Maybe, and 1 hour before to members who RSVPd Going. |
| FR-04.7 | Event organizers can post updates to an event (e.g., location change), which notifies all RSVPd members. |
| FR-04.8 | Event organizers can cancel an event, which sends a cancellation notification to all RSVPd members. |
| FR-04.9 | Past events are archived and viewable in an event history view. |
| FR-04.10 | Any member can create a poll with a question, multiple answer options, and an optional closing date. |
| FR-04.11 | All members can vote on an open poll. Each member may cast one vote. |
| FR-04.12 | Poll results (vote counts and percentages) are visible to all members. |
| FR-04.13 | Members are notified when a new poll is created, when a poll is closing soon, and when poll results are ready. |
| FR-04.14 | After an event concludes, admin can record attendance for each member as Attended or Absent. |
| FR-04.15 | Attendance records are used in analytics, rankings, and the Community Health Score. |

---

## FR-05: Growth

| ID | Requirement |
|----|-------------|
| FR-05.1 | Admin or any member can create a Fitness Challenge with: title, description, goal type (steps, distance, or duration), start date, and end date. |
| FR-05.2 | Admin or any member can create a Wellness Challenge with: title, description, a custom goal definition, start date, and end date. |
| FR-05.3 | Members can join a challenge before or after it starts. |
| FR-05.4 | Members can log progress against an active challenge they have joined. |
| FR-05.5 | Challenge progress is visible to all members on a leaderboard ranked by cumulative progress. |
| FR-05.6 | Challenges have a completion status (Active, Ended). |
| FR-05.7 | Members receive a push notification when a challenge they joined is ending in 24 hours and when it ends. |

---

## FR-06: Analytics

| ID | Requirement |
|----|-------------|
| FR-06.1 | Each member can view their Personal Analytics: events attended, RSVP history, challenges joined, challenge progress, and recognitions received. |
| FR-06.2 | All members can view Community Analytics: aggregate engagement metrics across the group (events held, total RSVPs, challenge participation, recognition activity). |
| FR-06.3 | The platform computes a Community Health Score — a composite metric reflecting overall member participation across events, challenges, and recognitions. |
| FR-06.4 | Monthly Rankings display members ordered by a participation score for the current or selected month. |
| FR-06.5 | All-Time Rankings display members ordered by cumulative participation since platform launch. |
| FR-06.6 | Monthly Recognition showcases peer recognitions given and received within the current or selected month. |
| FR-06.7 | Community Recognition provides an all-time view of recognition activity, highlighting the most recognized members. |
| FR-06.8 | Attendance records (Attended / Absent) contribute to each member's participation score and to the Community Health Score. |

---

## FR-07: Connect Buddy

| ID | Requirement |
|----|-------------|
| FR-07.1 | Connect Buddy is a special system profile in the database, distinct from regular member accounts. It is not a human user and cannot be logged into. |
| FR-07.2 | When a new member joins the platform, Connect Buddy automatically posts a welcome message in the feed introducing the new member to the community. |
| FR-07.3 | Connect Buddy automatically posts event reminders in the feed in the lead-up to scheduled events. |
| FR-07.4 | Connect Buddy automatically posts poll reminders in the feed when a poll is open and approaching its closing date. |
| FR-07.5 | Connect Buddy automatically posts achievement announcements in the feed when a member completes a challenge or reaches a milestone. |
| FR-07.6 | Connect Buddy automatically posts monthly highlights in the feed — a summary of community activity from the previous month. |
| FR-07.7 | Connect Buddy automatically posts community update messages in the feed for significant platform events (e.g., milestone member counts). |
| FR-07.8 | Connect Buddy automatically generates and posts Memories — content referencing past events or activities from previous months — to surface nostalgia and reinforce community history. |
| FR-07.9 | Admin can manage Connect Buddy behavior from the Admin panel, including the ability to suppress or manually trigger certain post types. |
| FR-07.10 | Connect Buddy posts are visually distinguished in the feed via a unique account avatar and a system-account label. |

---

## FR-08: Notifications

| ID | Requirement |
|----|-------------|
| FR-08.1 | Push notifications are sent for: event reminders, event cancellations, event updates, new poll created, poll closing soon, poll results ready, new recognition received, challenge updates, challenge ending, @mentions, comment on own post, Connect Buddy posts (monthly highlights, achievements), and admin-flagged content alerts (admin only). |
| FR-08.2 | Members can configure their notification preferences per category from the Notification Preferences screen in their Profile. |
| FR-08.3 | In-app notification inbox shows recent notification activity. |
| FR-08.4 | Tapping a notification deep-links directly to the relevant content. |

---

## FR-09: Admin Panel

| ID | Requirement |
|----|-------------|
| FR-09.1 | Admin can view and manage all members (invite, deactivate, remove). |
| FR-09.2 | Admin can view flagged content and take action (delete or dismiss). |
| FR-09.3 | Admin can pin announcements to the top of the community feed. |
| FR-09.4 | Admin can view engagement metrics via the Analytics module (active users, posts this month, events created, challenge participation). |
| FR-09.5 | Admin can record post-event attendance for each member (Attended / Absent). |
| FR-09.6 | Admin can manage Connect Buddy behavior (suppress or manually trigger post types). |
| FR-09.7 | Admin settings and functions are accessible only to users with the admin role. All admin API calls enforce a server-side role check. |
