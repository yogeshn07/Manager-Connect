# Module Breakdown

## Overview

Manager Connect is organized into six feature modules, plus a cross-cutting system component (Connect Buddy). Each module owns its screens, state, and API interactions. Modules are independent: changes to one module do not break others. Navigation is a 5-tab bottom bar: Feed | Events | Growth | Analytics | Profile.

---

## Module 1: Auth

**Purpose:** Handles all authentication, session management, and first-time onboarding.

**Sub-features:** Invite link validation, OTP verification, profile creation onboarding.

**Screens:**
- Welcome / Invite landing
- OTP verification
- Profile creation (onboarding)

**Responsibilities:**
- Validate invitation link before allowing registration
- Request and verify OTP via Supabase Auth
- Store session token in device secure storage
- Detect first-run and redirect to onboarding profile creation
- Handle session refresh and logout

**Key Dependencies:**
- Supabase Auth
- Flutter Secure Storage

---

## Module 2: Feed

**Purpose:** The community home feed — the default landing screen after login. Aggregates all community content in one scrollable stream.

**Sub-features:** Member posts, emoji reactions, comments, @mentions, pinned announcements, Connect Buddy posts (welcome messages, memories, highlights, reminders, achievements, community updates).

**Screens:**
- Home feed (default tab)
- Post detail (with expanded comments)
- Create post (modal)

**Responsibilities:**
- Display paginated feed of member posts and Connect Buddy posts in reverse chronological order
- Display pinned admin announcements at the top of the feed above all other content
- Visually distinguish Connect Buddy posts from member posts
- Create post (text and optional photo upload)
- React to posts (emoji reactions)
- Comment on posts
- Mention members with @ tagging (with autocomplete)
- Flag post or comment for moderation
- Delete own post or comment

**Key Dependencies:**
- Supabase Database (posts, comments, reactions, connect_buddy_posts tables)
- Supabase Storage (post-images bucket)
- Supabase Realtime (live comment and reaction updates)

---

## Module 3: Events

**Purpose:** Event creation, RSVP management, poll creation and voting, attendance recording, and event history.

**Sub-features:**
- Games: Cricket, Badminton, Pickleball, Table Tennis, Other
- Outings
- Social Connect: Coffee Connect, Lunch Meetup, Dinner Meetup, Other
- Polls
- RSVP
- Post-event Attendance (Attended / Absent, recorded by admin)
- Event History

**Screens:**
- Events list (with calendar toggle)
- Event detail
- Create event form
- Event history (past events archive)
- Poll list
- Poll detail (vote + results view)
- Create poll form

**Responsibilities:**
- Create events with title, description, category, sub-category, date/time, location, and optional cost note
- Display events grouped or filterable by category (Games, Outings, Social Connect)
- Manage RSVP responses (Going / Not Going / Maybe) per member per event
- Display attendee list per event
- Allow organizer to post event updates (notifies RSVPd members)
- Allow organizer to cancel event (notifies RSVPd members)
- Schedule automated reminders (24h before to Going + Maybe; 1h before to Going only)
- Archive past events in event history
- Create polls with question, answer options, and optional closing date
- Enforce single vote per member per poll
- Display live poll results (vote counts and percentages) to all members
- Send poll notifications (new poll, closing soon, results ready)
- Enable admin to record post-event attendance (Attended / Absent) for each member
- Feed attendance data to Analytics module for rankings and Community Health Score

**Key Dependencies:**
- Supabase Database (events, rsvps, event_attendance, polls, poll_votes tables)
- Expo / Flutter local notifications (reminder scheduling)
- Supabase Edge Functions (attendance aggregation triggers)

---

## Module 4: Growth

**Purpose:** Fitness and wellness challenge creation, participation, progress logging, and leaderboard tracking.

**Sub-features:**
- Fitness Challenges (quantitative goals: steps, distance, duration)
- Wellness Challenges (custom qualitative or quantitative goals)

**Screens:**
- Growth home (active challenges list)
- Challenge detail (goal, dates, leaderboard, my progress)
- Create challenge form
- My challenges (joined challenges)
- Completed challenges archive

**Responsibilities:**
- Create Fitness Challenges with goal type (steps, distance, duration), target value, start date, and end date
- Create Wellness Challenges with a custom goal definition, start date, and end date
- Allow members to join or leave a challenge
- Accept daily progress log entries from joined members
- Display leaderboard ranked by cumulative progress within the challenge
- Manage challenge status (Active / Ended)
- Send end-of-challenge notifications to all joined participants
- Archive completed challenges

**Key Dependencies:**
- Supabase Database (challenges, challenge_participants, progress_logs tables)
- Flutter local notifications (challenge ending reminder)

---

## Module 5: Analytics

**Purpose:** Personal and community-level engagement insights, rankings, and recognition. Recognition lives inside Analytics — it is not a standalone tab or module.

**Sub-features:**
- Personal Analytics
- Community Analytics
- Community Health Score
- Monthly Rankings
- All-Time Rankings
- Monthly Recognition
- Community Recognition

**Screens:**
- Analytics home (overview dashboard)
- Personal Analytics view
- Community Analytics view
- Community Health Score view
- Rankings view (Monthly / All-Time toggle)
- Recognition view (Monthly / All-Time toggle)
- Give Recognition form (modal)

**Responsibilities:**
- Compute and display each member's Personal Analytics: events attended, RSVP history, challenges joined, progress logged, recognitions received and given
- Compute and display Community Analytics: aggregate participation metrics across the entire group
- Compute and display the Community Health Score — a composite participation metric derived from event attendance, RSVP activity, challenge participation, and recognition activity
- Compute Monthly Rankings: members ranked by participation score for the selected month
- Compute All-Time Rankings: members ranked by cumulative participation score since launch
- Display Monthly Recognition: peer recognitions given and received in the current or selected month
- Display Community Recognition: all-time recognition history highlighting most recognized members
- Allow any member to give a recognition (shout-out) with recipient(s), category tag, and message
- Notify recognized members via push notification
- Consume attendance data from Events module to factor into participation scores

**Key Dependencies:**
- Supabase Database (recognitions, recognition_reactions, events, event_attendance, challenges, challenge_participants, progress_logs tables)
- Supabase Edge Functions (score and ranking computation)
- Flutter notifications (recognition received)

---

## Module 6: Profile

**Purpose:** User self-management — own profile, member directory browsing, notification preferences, app settings, and logout.

**Sub-features:** Own profile, edit profile, member profiles, notification preferences, settings, logout.

**Screens:**
- My profile
- Edit profile (name, photo, role, bio, interests)
- Any member's profile (read-only view)
- Notification preferences
- App settings
- Logout

**Responsibilities:**
- Fetch and render own profile data (name, photo, bio, role, interest tags)
- Allow member to edit their own profile at any time
- Upload and store profile photo via Supabase Storage
- Display read-only profiles for any other community member
- Show recognitions received on any member's profile
- Persist notification preferences (per-category opt-in/out) to database
- Provide logout action (clears session token and push token)
- Provide access point to Admin panel for admin-role users

**Key Dependencies:**
- Supabase Database (profiles, notification_preferences tables)
- Supabase Storage (avatars bucket)

---

## Module 7: Admin

**Purpose:** Platform administration — member management, content moderation, pinned announcements, Connect Buddy management, and attendance recording.

**Sub-features:** Member management, content moderation, announcements, Connect Buddy management, attendance recording.

**Screens:**
- Admin overview / dashboard
- Member management list
- Invite member form
- Member detail (role, joined date, deactivate / remove)
- Flagged content queue
- Pin announcement screen
- Connect Buddy management
- Event attendance recording form

**Responsibilities:**
- View and manage all community members (invite via email or SMS, deactivate, remove)
- Review flagged posts and comments; resolve by deleting or dismissing
- Pin a post as an announcement at the top of the community feed
- Manage Connect Buddy configuration (suppress or manually trigger specific post types such as memories, highlights, or achievement announcements)
- Record post-event attendance per member (Attended / Absent) after each event concludes
- Maintain an audit log of admin actions

**Access Control:** Accessible only to users with `role = 'admin'`. All admin API calls enforce a server-side role check. The Admin module is never surfaced in the UI for non-admin members.

**Key Dependencies:**
- Supabase Database (admin_audit_log, flagged_content, event_attendance, connect_buddy_config tables)
- Supabase Edge Functions (invitation email/SMS dispatch, Connect Buddy post triggers)

---

## Cross-Cutting System Component: Connect Buddy

Connect Buddy is not a module with its own tab or navigation. It is a special system profile in the database that generates automated posts directly into the Feed. Its behavior is configured and managed from the Admin module.

| Post Type | Trigger |
|-----------|---------|
| Welcome message | New member accepts invitation and joins the platform |
| Event reminder | Scheduled in advance of an upcoming event |
| Poll reminder | Poll is open and approaching its closing date |
| Achievement announcement | Member completes a challenge or reaches a milestone |
| Monthly highlight | Automated monthly summary of community activity |
| Community update | Significant platform event (e.g., milestone member count) |
| Memory | Auto-generated post referencing a past event or activity from a previous month |

All Connect Buddy posts appear in the community Feed and are visually distinguished by the Connect Buddy account avatar and a system-account label. Members cannot reply to Connect Buddy posts with direct messages, but can react and comment as on any Feed post.

---

## Cross-Cutting Concerns

These are shared infrastructure concerns that apply across all modules:

| Concern | Implementation |
|---------|----------------|
| Push notifications | Flutter local notifications + Expo Push API / FCM / APNs |
| Authentication guard | Shared auth context provider wrapping all app routes |
| Error handling | Centralized error boundary + toast notifications |
| Loading states | Shared skeleton loader component |
| Image optimization | Compress before upload; serve from CDN |
| Offline handling | Cached reads; queue writes for retry on reconnect |
| Theme | Light mode only (V1). Dark mode not implemented. |
