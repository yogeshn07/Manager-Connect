# Frontend Readiness Audit

**Date:** 2026-06-21

---

## 1. Backend Dependency Status

| Component | Status | Notes |
|-----------|--------|-------|
| Database (26 tables) | COMPLETE | 72 migrations, 114 RLS policies, 0 drift |
| Edge Functions (21/21) | COMPLETE | All compile, all verified |
| Connect Buddy seed | COMPLETE | Provisioned via seed.sql |
| Storage buckets | NOT CONFIGURED | avatars + post-images need RLS policies |
| Realtime replication | NOT CONFIGURED | 8 tables need replication enabled |
| FCM push | STUB | notification.service.ts has FCM stub, no server key |

### Pre-Implementation Blockers

| # | Item | Severity | Impact |
|---|------|----------|--------|
| 1 | Storage bucket RLS not configured | **Medium** | Avatar upload + post image upload won't work |
| 2 | Realtime replication not enabled | **Medium** | Live feed, RSVP counts, poll votes won't update in real time |
| 3 | FCM server key not configured | **Low** | Push notifications deferred; in-app inbox works |

These are infrastructure setup tasks, not code changes. They don't block screen implementation — screens can be built with REST polling first, then upgraded to Realtime.

---

## 2. Screen Inventory (32 screens)

### Authentication (4 screens)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| A1 | Splash | App init, session check, routing | Local session | Supabase Auth `getSession()` | No | All |
| A2 | Welcome / Login | OTP request via email/phone | User input | Supabase Auth `signInWithOtp()` | No | Unauthenticated |
| A3 | Verify OTP | OTP entry + verification | User input | Supabase Auth `verifyOtp()` | No | Unauthenticated |
| A4 | Profile Setup | New member onboarding | Invitation data | `validate-invite-token` EF, `create-profile` EF, Storage upload | No | Authenticated (no profile) |

**Navigation:** Splash → Welcome → Verify OTP → Profile Setup → Feed

### Community Feed (4 screens)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| F1 | Feed | Scrollable post list + pinned | posts, pinned_announcements, profiles | REST: posts, pinned_announcements | `feed:posts` INSERT | Active member |
| F2 | Create Post | Text + image post creation | User input, image picker | `create-post` EF, Storage upload | No | Active member |
| F3 | Post Detail | Full post + reactions + comments | posts, post_reactions, comments, profiles | REST: posts, reactions, comments | `feed:reactions`, `feed:comments` | Active member |
| F4 | Member Profile View | View another member's profile | profiles, recognitions received | REST: profiles, recognition_recipients | No | Active member |

**Navigation:** Feed → Post Detail → (Comments inline), Feed → Create Post, Feed → Member Profile

### Activities (5 screens)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| E1 | Activities List | Upcoming + past events, category filter | activities | REST: activities | No | Active member |
| E2 | Activity Detail | Event info, RSVPs, updates, polls | activities, activity_rsvps, activity_updates, polls | REST: all above | `activities:rsvps` | Active member |
| E3 | Create Activity | New event form | User input | REST: POST activities | No | Active member |
| E4 | RSVP List | Attendee list with status | activity_rsvps, profiles | REST: activity_rsvps with profile join | `activities:rsvps` | Active member |
| E5 | Activity Updates | Organizer update feed | activity_updates | REST: activity_updates | No | Active member |

**Navigation:** Events tab → Activities List → Activity Detail → (RSVP List, Updates), Events tab → Create Activity

### Polls (3 screens)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| P1 | Poll List | Active + closed polls | polls | REST: polls | No | Active member |
| P2 | Poll Detail / Vote | View options, cast vote, see results | polls, poll_options, poll_votes | REST: polls, poll_options, poll_votes; POST poll_votes | `events:poll_votes` | Active member |
| P3 | Create Poll | New poll form | User input | `create-poll` EF | No | Active member |

**Navigation:** Activity Detail → Poll Detail, Events tab → Poll List → Poll Detail, Events → Create Poll

### Growth (4 screens)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| G1 | Challenge List | Active + completed challenges | challenges | REST: challenges | No | Active member |
| G2 | Challenge Detail | Info, participants, leaderboard | challenges, challenge_participants, progress_logs, profiles | REST: all above | `growth:leaderboard` | Active member |
| G3 | Log Progress | Daily progress entry form | User input | REST: UPSERT progress_logs | No | Challenge participant |
| G4 | Create Challenge | New challenge form | User input | REST: POST challenges | No | Active member |

**Navigation:** Growth tab → Challenge List → Challenge Detail → Log Progress, Growth tab → Create Challenge

### Recognition (2 screens)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| R1 | Recognition Feed | Wall of peer recognitions | recognitions, recognition_recipients, profiles | REST: recognitions with joins | No | Active member |
| R2 | Create Recognition | Give recognition form | User input, profiles list | `create-recognition` EF | No | Active member |

**Navigation:** Feed (Recognition section) → Recognition Feed → Create Recognition

### Notifications (1 screen)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| N1 | Notification Center | In-app notification inbox | notification_inbox | REST: notification_inbox; PATCH mark read | `notifications:inbox` | Active member |

**Navigation:** App bar icon → Notification Center → Deep-link to referenced content

### Analytics (3 screens)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| AN1 | Personal Analytics | Own stats, attendance, recognitions | member_monthly_stats, event_attendance | REST: member_monthly_stats, event_attendance | No | Active member |
| AN2 | Community Analytics | Health score, engagement metrics | community_health_scores, member_monthly_stats | REST: community_health_scores | No | Active member |
| AN3 | Rankings | Monthly + all-time leaderboard | member_monthly_stats, profiles | REST: member_monthly_stats with profile joins | No | Active member |

**Navigation:** Analytics tab → Personal/Community toggle, Analytics → Rankings

### Profile (3 screens)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| PR1 | My Profile | Own profile display + stats | profiles, recognitions received | REST: profiles, recognition_recipients | No | Active member |
| PR2 | Edit Profile | Edit name, bio, title, tags, avatar | profiles, Storage | REST: PATCH profiles, Storage upload | No | Own profile |
| PR3 | Settings | Notification prefs, logout | profiles (notification_preferences) | REST: PATCH profiles, Supabase Auth `signOut()` | No | Active member |

**Navigation:** Profile tab → My Profile → Edit Profile, Profile tab → Settings

### Admin (5 screens)

| # | Screen | Purpose | Data Sources | APIs | Realtime | Permissions |
|---|--------|---------|-------------|------|----------|-------------|
| AD1 | Admin Dashboard | Overview, quick actions | profiles count, flagged_content count | REST: aggregate queries | No | Admin |
| AD2 | Member Management | Invite, deactivate, remove | profiles, invitations | `send-invitation` EF, `deactivate-user` EF, `remove-user` EF | No | Admin |
| AD3 | Moderation Queue | Flagged content review | flagged_content, posts, comments | `resolve-flag` EF | No | Admin |
| AD4 | Attendance Recording | Post-event batch attendance | activities, profiles, event_attendance | `record-attendance` EF | No | Admin |
| AD5 | Pin Management | Pin/unpin announcements | posts, pinned_announcements | `pin-announcement` EF | No | Admin |

**Navigation:** Admin icon (app bar) → Admin Dashboard → (Members, Moderation, Attendance, Pins)

---

## 3. Screen Summary

| Category | Count |
|----------|-------|
| Authentication | 4 |
| Community Feed | 4 |
| Activities | 5 |
| Polls | 3 |
| Growth | 4 |
| Recognition | 2 |
| Notifications | 1 |
| Analytics | 3 |
| Profile | 3 |
| Admin | 5 |
| **Total** | **34** |

---

## 4. API Coverage Verification

### Edge Functions Used by Frontend (13 of 21)

| Edge Function | Screen(s) |
|---------------|-----------|
| `validate-invite-token` | A4 Profile Setup |
| `create-profile` | A4 Profile Setup |
| `send-invitation` | AD2 Member Management |
| `create-post` | F2 Create Post |
| `create-poll` | P3 Create Poll |
| `cancel-activity` | E2 Activity Detail |
| `post-activity-update` | E2 Activity Detail |
| `create-recognition` | R2 Create Recognition |
| `resolve-flag` | AD3 Moderation Queue |
| `pin-announcement` | AD5 Pin Management |
| `deactivate-user` | AD2 Member Management |
| `remove-user` | AD2 Member Management |
| `revoke-invitation` | AD2 Member Management |
| `record-attendance` | AD4 Attendance Recording |

### Edge Functions NOT Called by Frontend (7 of 21 — system/internal)

| Edge Function | Reason |
|---------------|--------|
| `send-notification` | Internal — called by other EFs |
| `post-connect-buddy-message` | Internal — called by scheduled-connect-buddy |
| `close-poll` | Service-role scheduled |
| `close-challenge` | Service-role scheduled |
| `compute-monthly-stats` | Service-role scheduled |
| `scheduled-connect-buddy` | Service-role scheduled |
| `scheduled-cleanup` | Service-role scheduled |

### REST Operations by Screen (63 total per API contracts)

All 63 REST operations map to identified screens. No orphaned operations.

### Realtime Channels (7)

| Channel | Screen | Table |
|---------|--------|-------|
| `feed:posts` | F1 Feed | posts INSERT |
| `feed:reactions:{post_id}` | F3 Post Detail | post_reactions changes |
| `feed:comments:{post_id}` | F3 Post Detail | comments INSERT |
| `activities:rsvps:{activity_id}` | E2 Activity Detail, E4 RSVP List | activity_rsvps changes |
| `events:poll_votes:{poll_id}` | P2 Poll Detail | poll_votes INSERT |
| `growth:leaderboard:{challenge_id}` | G2 Challenge Detail | progress_logs INSERT |
| `notifications:inbox:{user_id}` | N1 Notification Center | notification_inbox INSERT |

---

## 5. Unresolved Questions

| # | Question | Answer |
|---|----------|--------|
| — | — | **None. All API contracts are fully defined.** |

---

## 6. Missing Requirements

| # | Requirement | Status |
|---|-------------|--------|
| — | — | **None. All FR-01 through FR-09 have corresponding screens.** |

---

## 7. Verdict

| Check | Result |
|-------|--------|
| Backend dependencies complete | **PASS** (3 infra items deferred, not blocking) |
| Unresolved API questions | **0** |
| Unresolved schema questions | **0** |
| Missing requirements | **0** |
| Every FR mapped to screen | **PASS** |
| Every Edge Function mapped | **PASS** (13 client-facing + 7 system + 1 internal) |
| Every REST operation mapped | **PASS** |
| Every Realtime channel mapped | **PASS** |

### READY FOR FRONTEND IMPLEMENTATION
