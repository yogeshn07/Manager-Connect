# Development Roadmap

## Overview

Manager Connect V1 is delivered in **6 sprints** (2 weeks each = 12 weeks total). The roadmap sequences core infrastructure first and builds features incrementally on a stable foundation. Working software is deliverable at the end of every sprint.

**Team assumption:** 1–2 developers, part-time or full-time.

---

## Milestones

| Milestone | End of Sprint | Description |
|---|---|---|
| M1 | Sprint 1 | Foundation: auth, profiles, navigation shell |
| M2 | Sprint 2 | Feed module live: posts, reactions, comments |
| M3 | Sprint 3 | Events module live: all categories, polls, RSVP |
| M4 | Sprint 4 | Growth module live: challenges, leaderboard |
| M5 | Sprint 5 | Analytics, Connect Buddy, and Notifications live |
| M6 | Sprint 6 | Admin, polish, testing, App Store launch |

---

## Sprint 1: Foundation (Weeks 1–2)

**Goal:** Working app shell with invite-only auth and user profiles. An admin can invite a manager, who registers and completes their profile.

### Tasks

**Infrastructure Setup**
- [ ] Initialize Flutter project (Dart 3.3+, Flutter 3.22+)
- [ ] Configure Supabase (dev and staging projects)
- [ ] Set up GitHub repository with branch protection and CI (GitHub Actions)
- [ ] Configure Flutter lints, analysis_options.yaml
- [ ] Set up Firebase project (FCM for push notifications)
- [ ] Set up EAS Build equivalent (fastlane or direct Xcode/Gradle pipeline)
- [ ] Set up PostHog (staging environment, EU region)
- [ ] Configure Riverpod, GoRouter, Freezed, build_runner

**Auth Module**
- [ ] Database migration: `profiles` table (with `is_system_account` and `app_role` columns), `invitations` table + RLS
- [ ] Seed Connect Buddy system profile (is_system_account=true, full_name='Connect Buddy')
- [ ] Supabase Edge Function: `send-invitation` (generate token, dispatch email/SMS)
- [ ] Supabase Edge Function: `validate-invite-token`
- [ ] Supabase Edge Function: `create-profile` (post-registration profile row creation)
- [ ] Invite token validation and OTP request screen
- [ ] OTP verification screen (6-digit input, auto-advance, paste support)
- [ ] Session persistence (supabase_flutter handles Keychain/Keystore storage)
- [ ] First-time profile creation screen (name, photo, title, bio, interest tags)
- [ ] Auth guard: redirect unauthenticated users to `/welcome`
- [ ] Onboarding completion guard: redirect incomplete profiles to `/create-profile`

**Navigation Shell**
- [ ] 5-tab bottom NavigationBar (Feed / Events / Growth / Analytics / Profile)
- [ ] GoRouter ShellRoute setup with placeholder screens for each tab
- [ ] Admin route group (role-gated, accessed via Profile tab)
- [ ] GoRouterRefreshStream wired to auth state

**Sprint 1 Definition of Done:**
- Admin can send an invitation via Edge Function (CLI or Supabase dashboard)
- Invited manager clicks link, enters OTP, completes profile, lands on Feed tab
- Navigation shell shows 5 tabs with placeholder screens
- Admin route group redirects non-admin users

---

## Sprint 2: Feed Module (Weeks 3–4)

**Goal:** Community feed is live. Members can post, react, comment, and see Connect Buddy's welcome post for new members.

### Tasks

**Feed Module**
- [ ] Database migrations: `posts`, `post_images`, `post_reactions`, `comments`, `post_mentions` tables + RLS
- [ ] Database migration: `pinned_announcements` table + RLS
- [ ] Community feed screen: paginated, reverse chronological, includes Connect Buddy posts
- [ ] Connect Buddy post card: distinct visual treatment (system badge, no delete option for non-admin)
- [ ] Pinned announcement banner at top of feed
- [ ] Create post: text only
- [ ] Create post: with photos (image picker + Supabase Storage upload, compress before upload)
- [ ] Emoji reactions on posts (UPSERT on post_reactions)
- [ ] Comments on posts (flat, paginated)
- [ ] Mention members with @ (autocomplete from profiles, excluding system accounts)
- [ ] Flag post for moderation
- [ ] Delete own post (soft delete)
- [ ] Admin: delete any post
- [ ] Real-time new posts via Supabase Realtime (`feed:posts` channel)
- [ ] Supabase Edge Function: `create-post` (atomic: post + mentions + notification dispatch)
- [ ] Supabase Edge Function: `post-connect-buddy-message` (creates post as CB system account)
- [ ] Connect Buddy welcome message: triggered by `create-profile` Edge Function on first registration

**Sprint 2 Definition of Done:**
- Member can create a post with text and photos
- Member can react and comment on posts
- New members trigger a Connect Buddy welcome post in the feed
- Real-time updates appear without page refresh

---

## Sprint 3: Events Module (Weeks 5–6)

**Goal:** All event types (Games, Outings, Social Connect) are live with RSVP. Polls are live.

### Tasks

**Events Module**
- [ ] Database migration: `activities` table (with `event_category`, `event_type` columns), `activity_rsvps`, `activity_updates` tables + RLS
- [ ] Database migration: `polls`, `poll_options`, `poll_votes` tables + RLS + UNIQUE constraints
- [ ] Events screen with tab filters: All / Games / Outings / Social Connect
- [ ] Event card: displays event_category chip and event_type label
- [ ] Create event form: category selector (Games/Outings/Social Connect), specific type selector within category, title, date/time, location, description, optional cost note
- [ ] Event detail screen: info, RSVP, updates, polls (if any)
- [ ] RSVP: Going / Not Going / Maybe (upsert on activity_rsvps)
- [ ] Attendee list view (RSVP breakdown by status)
- [ ] Event organizer: post update to event
- [ ] Cancel event: Edge Function `cancel-activity` (notifies Going + Maybe RSVPs)
- [ ] Event history screen: past events list
- [ ] Polls: create poll (standalone or attached to event)
- [ ] Polls: vote on poll (one vote per member, UNIQUE enforced)
- [ ] Polls: live vote count updates via Realtime (`events:poll_votes:{poll_id}` channel)
- [ ] Poll detail screen: question, options with live progress bars, result state when closed
- [ ] Edge Function: `create-poll` (creates poll + dispatches poll notification to all members)
- [ ] Edge Function: `close-poll` (marks poll closed + dispatches results notification)
- [ ] Real-time RSVP updates (`activities:rsvps:{activity_id}` channel)
- [ ] Event reminder notifications (24h and 1h before event — see Notification sprint)

**Sprint 3 Definition of Done:**
- Member can create events in all three categories
- Members can RSVP and see live attendee counts
- Members can create and vote on polls with live vote count updates
- Past events appear in Event History

---

## Sprint 4: Growth Module + Attendance (Weeks 7–8)

**Goal:** Fitness and wellness challenges are live. Post-event attendance recording is available to admins.

### Tasks

**Growth Module**
- [ ] Database migration: `challenges`, `challenge_participants`, `progress_logs` tables + RLS + UNIQUE constraints
- [ ] Growth screen: tabs for Active / My Challenges / Completed
- [ ] Challenge type filter: Fitness / Wellness chips
- [ ] Challenge detail screen: goal, dates, participants, progress log, leaderboard
- [ ] Create challenge form: type (fitness/wellness), goal type (steps/distance/duration/custom), title, dates
- [ ] Join / leave challenge (challenge_participants insert/delete)
- [ ] Log daily progress (UPSERT on progress_logs — one entry per member per day per challenge)
- [ ] Leaderboard: SUM(value) GROUP BY user_id ORDER BY total DESC
- [ ] Live leaderboard updates via Realtime (`growth:leaderboard:{challenge_id}` channel)
- [ ] Completed challenges archive
- [ ] Edge Function: `close-challenge` (ends challenge past end_date + notifies participants)

**Attendance (Admin Feature)**
- [ ] Database migration: `event_attendance` table + RLS + UNIQUE(activity_id, user_id)
- [ ] Admin attendance screen: list of past events with attendance not yet recorded
- [ ] Attendance recording sheet: list all RSVPs (Going) per event, mark each as Attended/Absent
- [ ] Edge Function: `record-attendance` (batch insert/upsert into event_attendance by admin)
- [ ] Event detail screen: show attendance summary for past events (admin sees who attended; members see aggregate count)

**Sprint 4 Definition of Done:**
- Members can create fitness and wellness challenges and log daily progress
- Leaderboard updates in real time
- Admin can record post-event attendance for any past event
- Completed challenges appear in archive with final leaderboard

---

## Sprint 5: Analytics, Connect Buddy, and Notifications (Weeks 9–10)

**Goal:** Analytics module is fully functional. Connect Buddy posts automated content. Push notifications work for all event types.

### Tasks

**Analytics Module**
- [ ] Database migration: `member_monthly_stats`, `community_health_scores` tables + RLS
- [ ] Edge Function: `compute-monthly-stats` (scheduled: runs 1st of each month; aggregates prior month stats for all members and community health score)
- [ ] Analytics screen: tabs for Personal / Community / Rankings / Recognition
- [ ] Personal analytics screen: my events attended, attendance rate, challenges joined, progress logs, recognitions received/given, posts, current month rank, all-time rank
- [ ] Community analytics screen: active members, total events this month, avg attendance rate, active challenge participants, recognitions this month
- [ ] Community health score card: composite score (0–100) with color coding and breakdown
- [ ] Rankings screen: Monthly Rankings toggle / All-Time Rankings
- [ ] Ranking entry tile: rank, avatar, name, composite score
- [ ] Monthly Recognition section: recognitions given this calendar month
- [ ] Community Recognition wall: all-time recognition wall (paginated, reverse chron)
- [ ] Recognition detail screen: giver, recipients, category, message, reactions
- [ ] Give recognition: sheet with recipient picker (excludes system accounts), category tag, message
- [ ] Edge Function: `create-recognition` (atomic: recognition + recipients + notification dispatch)
- [ ] Emoji reactions on recognitions

**Connect Buddy Automation**
- [ ] Edge Function: `scheduled-connect-buddy` (scheduled: monthly highlights, memories, community updates)
- [ ] Monthly highlights: Connect Buddy posts a monthly recap (top ranked member, most active, new event count)
- [ ] Memories: Connect Buddy posts a memory from past events (1 year ago, 6 months ago)
- [ ] Admin Connect Buddy screen: view recent CB posts, manually trigger a post type (welcome, highlight, memory, update)
- [ ] Edge Function: trigger-able from admin panel for manual CB posts

**Notifications**
- [ ] FCM token registration on app start (update profiles.push_token)
- [ ] Edge Function: `send-notification` (internal dispatch to Expo/FCM Push API)
- [ ] Implement all notification triggers:
  - [ ] Event created → all members
  - [ ] Event reminder 24h → Going + Maybe RSVPs
  - [ ] Event reminder 1h → Going RSVPs
  - [ ] Event cancelled → Going + Maybe RSVPs
  - [ ] Poll created → all members
  - [ ] Poll reminder (24h before closing) → members who have not voted
  - [ ] Poll closed → all members who voted
  - [ ] Recognition received → named recipients
  - [ ] Challenge created → all members
  - [ ] Challenge ending 24h → participants
  - [ ] Challenge ended → participants
  - [ ] Mention in post → mentioned member
  - [ ] Comment on own post → post author
  - [ ] Connect Buddy monthly highlight → all members (configurable, default ON)
  - [ ] Admin: content flagged → admin users
  - [ ] Admin: new member registered → admin users
- [ ] In-app notification inbox screen (`/notifications`)
- [ ] Notification badge on Profile tab (unread count)
- [ ] Deep link routing from notification tap
- [ ] Notification preferences screen (per-category opt-out — 9 categories)
- [ ] Foreground notification display via flutter_local_notifications

**Sprint 5 Definition of Done:**
- Analytics tab shows personal stats, community health score, and rankings
- Recognition can be given and appears in Analytics
- Connect Buddy automatically posts monthly highlights
- All listed notification triggers deliver push notifications within 10 seconds
- Tapping any notification navigates to the correct screen

---

## Sprint 6: Admin, Polish, and Launch (Weeks 11–12)

**Goal:** Admin panel complete. App is polished, fully tested on real devices, and submitted to App Store and Google Play.

### Tasks

**Admin Module**
- [ ] Admin panel navigation (role-gated, accessed via Profile tab)
- [ ] Member management: list all members (active + pending invites)
- [ ] Invite member form (name + email or phone)
- [ ] Deactivate / remove member (Edge Functions: deactivate-user / remove-user)
- [ ] Flagged content queue: review, delete, or dismiss
- [ ] Pin / unpin announcement to feed (Edge Function: pin-announcement)
- [ ] Admin overview: lightweight metrics from Analytics module
- [ ] Admin audit log view
- [ ] Admin Connect Buddy panel: view recent posts, trigger post types manually
- [ ] Attendance recording flows (post-event admin action for any past event)

**Polish and Hardening**
- [ ] Empty states for all list screens (feed, events, growth, analytics, notifications)
- [ ] Loading skeletons for all data-heavy screens (feed, events, analytics)
- [ ] Error states with retry option
- [ ] Offline banner: reads from cache, shows write-blocked indicator when offline
- [ ] Image upload compression (client-side via `image` package before Supabase Storage upload)
- [ ] Accessibility: WCAG 2.1 AA tap target sizes (48×48dp min), contrast ratios verified
- [ ] Deep link edge cases: invalid ID, deleted content, unauthenticated tap
- [ ] System account protection: Connect Buddy profile cannot be deactivated or removed via admin
- [ ] Security review: RLS verification, token storage audit, system account access control

**Testing**
- [ ] Unit test suite complete (60% coverage target on business logic)
- [ ] Integration test suite complete for all modules
- [ ] E2E critical flows on iOS simulator and Android emulator:
  - [ ] Onboarding: invite → OTP → profile → feed landing → CB welcome post appears
  - [ ] Create event (Games) and RSVP
  - [ ] Create poll and vote (live update visible)
  - [ ] Admin records post-event attendance
  - [ ] Join challenge and log progress (leaderboard update)
  - [ ] Give a recognition — recipient analytics updated
  - [ ] Analytics tab: personal stats and community health score visible
  - [ ] Admin: invite a member, deactivate a member
- [ ] Manual device testing: iPhone (latest iOS), iPhone (iOS–1), Android flagship, Android mid-range
- [ ] Production readiness checklist signed off

**Deployment**
- [ ] Apply all DB migrations to production Supabase project
- [ ] Deploy all Edge Functions to production
- [ ] Seed Connect Buddy system profile in production
- [ ] Configure PostHog for production (EU region)
- [ ] Flutter build (release): iOS IPA and Android APK/AAB
- [ ] Submit to App Store Connect (iOS) and Google Play Console (Android)
- [ ] Await App Store and Play Store review approval
- [ ] Admin briefing: invite flow, attendance recording, Connect Buddy panel, moderation
- [ ] First 3 members (including admin) onboarded in production

**Sprint 6 Definition of Done:**
- App approved and live on App Store and Google Play
- At least 3 members including admin successfully onboarded in production
- Connect Buddy system profile visible and posting in feed
- No P0 or P1 bugs open
- Monitoring and error tracking confirmed working

---

## Post-Launch (Weeks 13–14): Stabilization

Observation period — not a development sprint:
- Monitor crash rates (Firebase Crashlytics or Sentry)
- Review PostHog engagement events (events created, polls voted, recognitions given, analytics viewed)
- Collect member feedback via direct conversation
- Identify and prioritize V1.1 features
- Address P0/P1 bugs via hotfix

---

## Risk Buffer

**1 week of buffer** is built into the 12-week plan. Sprint 5 (Analytics + Connect Buddy + Notifications) is the highest-risk sprint due to breadth. If Sprint 5 runs over, Sprint 6 slides one week. The buffer absorbs App Store review delays and device testing surprises.

---

## Edge Function Delivery Schedule

| Edge Function | Sprint |
|---|---|
| `send-invitation` | 1 |
| `validate-invite-token` | 1 |
| `create-profile` | 1 |
| `post-connect-buddy-message` | 2 |
| `create-post` | 2 |
| `cancel-activity` | 3 |
| `post-activity-update` | 3 |
| `create-poll` | 3 |
| `close-poll` | 3 |
| `close-challenge` | 4 |
| `record-attendance` | 4 |
| `compute-monthly-stats` | 5 |
| `create-recognition` | 5 |
| `send-notification` | 5 |
| `scheduled-connect-buddy` | 5 |
| `resolve-flag` | 6 |
| `pin-announcement` | 6 |
| `deactivate-user` | 6 |
| `remove-user` | 6 |
| `revoke-invitation` | 6 |
| `scheduled-cleanup` | 6 |
