# Project Implementation Readiness Audit

## Audit Metadata

| Field | Value |
|-------|-------|
| Audit Date | 2026-06-19 |
| Scope | All approved project documentation (40+ documents) |
| Method | Systematic cross-reference of every requirement, screen, backend endpoint, database table, and Edge Function |
| Verdict | **NOT READY TO BUILD** |

---

## Issue Summary

| Severity | Count |
|----------|-------|
| **Critical** | 2 |
| **High** | 0 |
| **Medium** | 6 |
| **Total** | 8 |

**Rule: READY TO BUILD requires Critical = 0, High = 0, Medium = 0.**

---

## Critical Issues

### CRIT-01: Recognition category_tag values in API contract do not match database CHECK constraint

**Affected Documents:**
- `backend-api-contracts.md` (create-recognition, line ~348)
- `database-schema-design.md` (recognitions table, line ~668)
- `flutter-implementation-plan.md` (Module 5: Analytics, line ~601)
- `design-system.md` (Recognition Category Colors)
- `component-library.md` (CMP-024: CategoryTagBadge)

**The Discrepancy:**

| Source | category_tag values |
|--------|-------------------|
| `backend-api-contracts.md` (create-recognition request) | `teamwork`, `leadership`, `fun`, `wellness`, `other` |
| `database-schema-design.md` (recognitions CHECK constraint) | `community_contributor`, `fitness_champion`, `wellness_champion`, `event_champion`, `most_supportive_manager` |
| `flutter-implementation-plan.md` (CategoryTagBadge) | `community_contributor`, `fitness_champion`, `wellness_champion`, `event_champion`, `most_supportive_manager` |
| `design-system.md` + `component-library.md` | `community_contributor`, `fitness_champion`, `wellness_champion`, `event_champion`, `most_supportive_manager` |

**Impact:** The `backend-api-contracts.md` defines request values (`teamwork`, `leadership`, etc.) that the database `CHECK IN (...)` constraint will reject on INSERT. Every recognition creation attempt will fail with a PostgreSQL CHECK violation. The Flutter client, implementation plan, design system, and component library all align with the database values — only the API contract is wrong.

**Resolution Required:** Update `backend-api-contracts.md` create-recognition contract to use the database-aligned values: `community_contributor`, `fitness_champion`, `wellness_champion`, `event_champion`, `most_supportive_manager`.

---

### CRIT-02: member_monthly_stats RLS policy blocks Rankings feature (FR-06.4, FR-06.5)

**Affected Documents:**
- `rls-security-policies.md` (member_monthly_stats policies, line ~333)
- `database-entity-catalogue.md` (member_monthly_stats RLS, line ~613)
- `database-schema-design.md` (member_monthly_stats index purpose, line ~792)
- `requirements.md` (R16: Monthly Rankings and All-Time Rankings)
- `functional-requirements.md` (FR-06.4, FR-06.5)
- `flutter-implementation-plan.md` (Module 5: Analytics, rankings queries)

**The Discrepancy:**

The RLS policy as documented in `rls-security-policies.md`:

| Policy | Operation | Condition |
|--------|-----------|-----------|
| `member_monthly_stats_select_own` | SELECT | `user_id = auth.uid()` — members see own stats only |
| `member_monthly_stats_select_admin` | SELECT | `is_admin()` — admins see all |

The functional requirements:
- FR-06.4: "Monthly Rankings display members ordered by a participation score for the current or selected month."
- FR-06.5: "All-Time Rankings display members ordered by cumulative participation since platform launch."

The Flutter implementation plan's rankings query:
```dart
supabase.from(Table.memberMonthlyStats)
  .select('user_id, ..., composite_score, profiles!user_id(...)')
  .eq('stat_month', monthIso)
  .order('composite_score', ascending: false)
```

**Impact:** With the documented RLS, a non-admin member querying `member_monthly_stats` receives only their own row. The Rankings screen (SCR-ANA-004), which is accessible to all authenticated users, cannot display a ranked list of all members. The Rankings feature is non-functional for regular members.

The `database-schema-design.md` itself reveals the contradiction — it defines an index `idx_monthly_stats_month` on `(stat_month, composite_score DESC)` with the stated purpose "Monthly rankings query (leaderboard for a given month)" — implying all-member access.

**Resolution Required:** Change the `member_monthly_stats` SELECT policy for members to allow all authenticated active users to read all rows (same pattern as `community_health_scores`), or create a database VIEW for rankings that runs with elevated privileges and expose it via PostgREST.

---

## Medium Issues

### MED-01: backend-folder-structure.md references email and SMS services that were explicitly removed

**Affected Documents:**
- `backend-folder-structure.md` (lines ~155–161: email.service.ts, sms.service.ts; line ~183: send-invitation use-case references)
- `backend-implementation-plan.md` (Section 5, lines ~278–279: explicit removal statement)
- `backend-api-contracts.md` (send-invitation response, line ~225: "The system does not send email or SMS")

**The Discrepancy:**
`backend-implementation-plan.md` explicitly states: *"Email and SMS services are not included... send-invitation returns the raw invite URL in its response and the admin shares it via any channel."* The API contract confirms this. However, `backend-folder-structure.md` still lists `email.service.ts` and `sms.service.ts` as files to create, and the `send-invitation/use-case.ts` annotation references `email.service.sendInvitationEmail() OR sms.service.sendInvitationSms()`.

**Impact:** A developer following `backend-folder-structure.md` would create unused service files and implement email/SMS dispatch that is not needed. Wasted effort and potential confusion about the invitation delivery model.

**Resolution Required:** Remove `email.service.ts` and `sms.service.ts` from `backend-folder-structure.md`. Update the `send-invitation/use-case.ts` annotation to reflect the URL-return model.

---

### MED-02: backend-architecture.md client layer describes Expo/React Native, not Flutter

**Affected Documents:**
- `backend-architecture.md` (Layer 4, lines ~178–219; topology diagram, lines ~27–30)
- `flutter-architecture.md` (authoritative Flutter client architecture)

**The Discrepancy:**
`backend-architecture.md` Layer 4 ("Client Service Layer") describes a React Native/Expo client architecture with TanStack Query, Zustand stores, Expo Notifications, and `src/services/` structure. The topology diagram labels the client as "Mobile Client (Expo / RN)". The actual mobile client is Flutter with Riverpod, GoRouter, and `firebase_messaging`, as documented in `flutter-architecture.md` and all Flutter-specific documents.

The server-side layers (1–3: Database, Platform Services, Edge Functions) are correct and technology-neutral.

**Impact:** Layer 4 and the topology diagram are misleading. A developer reading `backend-architecture.md` would get a wrong understanding of the client-side tech stack. The strict rules listed (e.g., "Screens never import from src/services/ directly — always through hooks") reference a non-existent code structure.

**Resolution Required:** Rewrite Layer 4 of `backend-architecture.md` to describe the Flutter client architecture (Clean Architecture layers, Riverpod providers, GoRouter, supabase_flutter SDK). Update the topology diagram to reference Flutter, not Expo/RN.

---

### MED-03: user-flows.md UF-06 describes Direct Messages — a removed feature

**Affected Documents:**
- `user-flows.md` (UF-06: Sending a Direct Message, lines ~130–149)
- `requirements.md` (Out of Scope, line ~67: "In-app messaging — removed entirely")

**The Discrepancy:**
`user-flows.md` includes a complete user flow (UF-06) for sending direct messages, with a full step-by-step flow referencing a "Messages tab" and "conversation threads." However, `requirements.md` explicitly states: *"In-app messaging (direct messages or group chat) — removed entirely."* There is no Messages tab, no messaging database table, no messaging Edge Function, and no messaging screen in any other document.

**Impact:** An orphan user flow referencing a feature that does not exist. Could mislead a developer or stakeholder into thinking DMs are in scope.

**Resolution Required:** Remove UF-06 from `user-flows.md` or replace it with a note stating the feature was removed.

---

### MED-04: notification-strategy.md references Expo Notifications SDK as client infrastructure

**Affected Documents:**
- `notification-strategy.md` (infrastructure table, line ~12: "Expo Notifications (expo-notifications)")
- `flutter-architecture.md` (Push Notifications section: firebase_messaging + flutter_local_notifications)
- `flutter-implementation-plan.md` (shared/services/notification_service.dart)

**The Discrepancy:**
`notification-strategy.md` lists "Expo Notifications (`expo-notifications`)" as the client-side notification token management technology. The Flutter application uses `firebase_messaging` for FCM/APNs token management and `flutter_local_notifications` for foreground display, as documented in both Flutter architecture documents.

The server-side dispatch section references "Expo Push API" for server-to-device delivery, which is a separate concern from the client SDK. The server-side mention is acceptable (Expo Push API can route to FCM/APNs), but the client-side SDK reference is wrong.

**Impact:** A developer implementing the Flutter notification service might reference this document and attempt to use `expo-notifications` (which is a React Native package, not a Flutter package).

**Resolution Required:** Update `notification-strategy.md` infrastructure table to list `firebase_messaging` (Flutter) and `flutter_local_notifications` (Flutter) as the client-side components. Clarify that "Expo Push API" is the server-side dispatch mechanism only.

---

### MED-05: post_reactions emoji set inconsistency across three documents

**Affected Documents:**
- `database-schema-design.md` (post_reactions, line ~229: "supported set is enforced application-side" — no CHECK)
- `database-entity-catalogue.md` (post_reactions, line ~203: CHECK IN 6 emojis: 👍❤️🎉🔥😂😮)
- `design-system.md` / `component-library.md` (ReactionBar, CMP-031: 8 emojis: 👍❤️😀😂😮👏🔥💯)

**The Discrepancy:**
Three documents define three different positions on the supported emoji set:

| Document | Position |
|----------|----------|
| `database-schema-design.md` (authoritative for schema) | No CHECK constraint; app-enforced |
| `database-entity-catalogue.md` | CHECK IN 6 values: 👍❤️🎉🔥😂😮 |
| `design-system.md` + `component-library.md` | 8 supported: 👍❤️😀😂😮👏🔥💯 |

If the entity catalogue's CHECK is implemented in migrations, 3 of the design system's 8 emojis (😀, 👏, 💯) would be rejected by the database. The schema design doc (authoritative) says no CHECK, which means the entity catalogue's CHECK should not be implemented.

**Impact:** If migrations follow the entity catalogue, the Flutter app's reaction bar will offer emojis that the database rejects. If migrations follow the schema design (no CHECK), the emoji set mismatch is harmless but the entity catalogue is inaccurate.

**Resolution Required:** Align all three documents. Recommended: follow `database-schema-design.md` (no CHECK, app-enforced) and update `database-entity-catalogue.md` to remove the CHECK constraint on emoji. Update all documents to agree on a single canonical emoji set.

---

### MED-06: scheduled-connect-buddy API missing trigger types referenced in frontend

**Affected Documents:**
- `backend-api-contracts.md` (scheduled-connect-buddy, line ~577: trigger_type values)
- `component-library.md` (CMP-044: ConnectBuddyTriggerSheet)
- `screen-inventory.md` (SCR-ADMIN-006)
- `functional-requirements.md` (FR-07.5: achievements, FR-07.7: community updates, FR-07.8: memories)

**The Discrepancy:**

| Source | Supported trigger_type values |
|--------|-------------------------------|
| `backend-api-contracts.md` (scheduled-connect-buddy) | `welcome`, `monthly_highlights`, `event_reminder`, `poll_reminder` |
| `functional-requirements.md` (FR-07.x) | welcome, event_reminder, poll_reminder, **achievement**, monthly_highlights, **community_update**, **memory** |
| `component-library.md` (Admin CB Trigger Sheet) | Welcome, Monthly Highlights, **Memory** |

Three Connect Buddy post types defined in functional requirements — `achievement`, `community_update`, and `memory` — have no corresponding trigger_type in the `scheduled-connect-buddy` API contract. The frontend admin screen (ConnectBuddyTriggerSheet) offers "Memory" as a manual trigger option, but the backend has no handler for it.

**Impact:** The admin "Memory" trigger button on SCR-ADMIN-006 would send a request the backend cannot process. Achievement and community update posts have no automated trigger mechanism defined. These CB post types exist in requirements but have no backend implementation path.

**Resolution Required:** Add `memory`, `achievement`, and `community_update` trigger types to the `scheduled-connect-buddy` API contract with defined behaviors. Alternatively, scope these to V2 and remove "Memory" from the admin trigger sheet.

---

## Audit Verification Matrix

### 1. Requirements → Full Stack Traceability

Every V1 Must Have requirement (R01–R20) was traced through all four layers:

| Req | DB Table(s) | Backend (EF/REST) | Frontend Screen(s) | User Journey |
|-----|------------|-------------------|-------------------|--------------|
| R01 | invitations, profiles | send-invitation, validate-invite-token, create-profile | AUTH-001→003, ADMIN-002 | UJ-01, UJ-14 |
| R02 | profiles | REST CRUD | PROF-001→003 | UJ-01, UJ-12 |
| R03 | posts, post_images, post_reactions, comments, post_mentions | create-post EF + REST | FEED-001 | UJ-03, UJ-04, UJ-05 |
| R04 | pinned_announcements | pin-announcement EF | FEED-001, ADMIN-004 | UJ-03 |
| R05 | profiles (system), posts | post-connect-buddy-message, scheduled-connect-buddy | FEED-001, ADMIN-006 | UJ-01, UJ-03 |
| R06 | activities | REST + cancel-activity, post-activity-update | EVT-001, EVT-002 | UJ-06, UJ-07 |
| R07 | activity_rsvps | REST UPSERT + send-notification | EVT-002 | UJ-07 |
| R08 | polls, poll_options, poll_votes | create-poll, close-poll + REST | EVT-003 | UJ-08 |
| R09 | event_attendance | record-attendance EF | ADMIN-005 | UJ-15 |
| R10 | activities (past query) | REST | EVT-004 | UJ-07 |
| R11 | challenges, challenge_participants, progress_logs | REST + close-challenge | GRO-001, GRO-002 | UJ-09, UJ-10 |
| R12 | challenges (wellness type) | Same as R11 | GRO-001, GRO-002 | UJ-09, UJ-10 |
| R13 | member_monthly_stats | compute-monthly-stats + REST | ANA-002 | UJ-12 |
| R14 | community_health_scores | compute-monthly-stats + REST | ANA-003 | UJ-12 |
| R15 | community_health_scores | compute-monthly-stats | ANA-003 | UJ-12 |
| R16 | member_monthly_stats | REST (**CRIT-02: RLS blocks this**) | ANA-004 | UJ-12 |
| R17 | recognitions, recognition_recipients, recognition_reactions | create-recognition (**CRIT-01: tag mismatch**) + REST | ANA-005, ANA-006 | UJ-11, UJ-12 |
| R18 | notification_inbox | send-notification + REST | NOTIF-001 | UJ-13 |
| R19 | flagged_content, pinned_announcements, admin_audit_log, invitations | Multiple admin EFs | ADMIN-001→006 | UJ-14, UJ-15, UJ-16 |
| R20 | invitations, profiles | Auth guards, RLS | AUTH-001 | UJ-01 |

**Result:** All 20 Must Have requirements have full-stack traceability. 2 requirements (R16, R17) are blocked by critical issues.

---

### 2. Screen → Backend Traceability

All 33 screens verified for navigation path, data source, and backend dependency.

| Screen ID | Route | Data Source | Backend Dependency | Status |
|-----------|-------|-----------|-------------------|--------|
| SCR-AUTH-001 | `/welcome` | validate-invite-token EF | Edge Function | ✓ |
| SCR-AUTH-002 | `/verify-otp` | Supabase Auth | Platform | ✓ |
| SCR-AUTH-003 | `/create-profile` | create-profile EF | Edge Function | ✓ |
| SCR-FEED-001 | `/feed` | posts, pinned_announcements REST + Realtime | REST + Realtime | ✓ |
| SCR-EVT-001 | `/events` | activities REST | REST | ✓ |
| SCR-EVT-002 | `/event/:id` | activities, activity_rsvps, polls REST + Realtime | REST + Realtime + EF | ✓ |
| SCR-EVT-003 | `/event/:id/poll/:pollId` | polls, poll_votes REST + Realtime | REST + Realtime | ✓ |
| SCR-EVT-004 | `/events` (section) | activities REST (past) | REST | ✓ |
| SCR-GRO-001 | `/growth` | challenges REST | REST | ✓ |
| SCR-GRO-002 | `/challenge/:id` | challenges, progress_logs REST + Realtime | REST + Realtime | ✓ |
| SCR-GRO-003 | `/growth` (tab) | challenges REST (ended) | REST | ✓ |
| SCR-ANA-001 | `/analytics` | Multiple REST | REST | ✓ |
| SCR-ANA-002 | `/analytics` (tab) | member_monthly_stats REST | REST | ✓ |
| SCR-ANA-003 | `/analytics` (tab) | community_health_scores REST | REST | ✓ |
| SCR-ANA-004 | `/analytics/ranking` | member_monthly_stats REST | REST | **⚠ CRIT-02** |
| SCR-ANA-005 | `/analytics` (tab) | recognitions REST | REST + EF | **⚠ CRIT-01** |
| SCR-ANA-006 | `/recognition/:id` | recognitions REST | REST | ✓ |
| SCR-PROF-001 | `/profile` | profiles REST | REST | ✓ |
| SCR-PROF-002 | (stack) | profiles REST | REST | ✓ |
| SCR-PROF-003 | `/profile/:id` | profiles REST | REST | ✓ |
| SCR-PROF-004 | (stack) | profiles REST (prefs) | REST | ✓ |
| SCR-ADMIN-001 | `/admin` | Aggregate queries | REST | ✓ |
| SCR-ADMIN-002 | `/admin/members` | profiles, invitations REST + EFs | REST + EF | ✓ |
| SCR-ADMIN-003 | `/admin/flagged` | flagged_content REST + EF | REST + EF | ✓ |
| SCR-ADMIN-004 | `/admin/announcements` | pinned_announcements + EF | REST + EF | ✓ |
| SCR-ADMIN-005 | `/admin/attendance` | activities, event_attendance + EF | REST + EF | ✓ |
| SCR-ADMIN-006 | `/admin/connect-buddy` | posts REST + EF | REST + EF | **⚠ MED-06** |
| SCR-NOTIF-001 | `/notifications` | notification_inbox REST + Realtime | REST + Realtime | ✓ |
| SCR-UTIL-001 | `/` | Auth state | Platform | ✓ |
| SCR-UTIL-002 | (in-place) | Auth state | Platform | ✓ |
| SCR-UTIL-003 | 404 fallback | None | None | ✓ |
| SCR-UTIL-004 | ShellRoute | Provider state | None | ✓ |

**Result:** 33/33 screens have verified data sources. 2 screens affected by critical issues, 1 by medium.

---

### 3. Edge Functions → Consumer Traceability

All 21 Edge Functions verified for frontend consumer and database dependency.

| Edge Function | Frontend Consumer | DB Tables Written | Status |
|---------------|------------------|------------------|--------|
| send-invitation | SCR-ADMIN-002 (InviteMemberSheet) | invitations, admin_audit_log | ✓ |
| validate-invite-token | SCR-AUTH-001 (WelcomeScreen) | invitations (read) | ✓ |
| create-profile | SCR-AUTH-003 (CreateProfileScreen) | profiles, invitations | ✓ |
| create-post | SCR-FEED-001 (CreatePostSheet) | posts, post_images, post_mentions | ✓ |
| post-connect-buddy-message | Internal (scheduled-CB, admin trigger) | posts, post_images, notification_inbox | ✓ |
| cancel-activity | SCR-EVT-002 (organizer action) | activities, notification_inbox | ✓ |
| post-activity-update | SCR-EVT-002 (organizer action) | activity_updates, notification_inbox | ✓ |
| create-poll | SCR-EVT-002 (CreatePollSheet) | polls, poll_options, notification_inbox | ✓ |
| close-poll | Scheduled + admin | polls, notification_inbox, admin_audit_log | ✓ |
| record-attendance | SCR-ADMIN-005 (AttendanceSheet) | event_attendance, admin_audit_log | ✓ |
| close-challenge | Scheduled + admin | challenges, notification_inbox | ✓ |
| create-recognition | SCR-ANA-005 (GiveRecognitionSheet) | recognitions, recognition_recipients, notification_inbox | **⚠ CRIT-01** |
| compute-monthly-stats | Scheduled (no frontend) | member_monthly_stats, community_health_scores | ✓ |
| send-notification | Internal (other EFs) | notification_inbox, profiles (push_token) | ✓ |
| scheduled-connect-buddy | Scheduled + SCR-ADMIN-006 | posts (via post-CB-message) | **⚠ MED-06** |
| resolve-flag | SCR-ADMIN-003 | flagged_content, posts/comments, admin_audit_log | ✓ |
| pin-announcement | SCR-ADMIN-004 | pinned_announcements, admin_audit_log | ✓ |
| deactivate-user | SCR-ADMIN-002 | profiles, admin_audit_log | ✓ |
| remove-user | SCR-ADMIN-002 | profiles, admin_audit_log, Storage | ✓ |
| revoke-invitation | SCR-ADMIN-002 | invitations, admin_audit_log | ✓ |
| scheduled-cleanup | Scheduled (no frontend) | posts, comments, invitations, notification_inbox | ✓ |

**Result:** 21/21 Edge Functions have verified consumers and DB dependencies. No orphan Edge Functions.

---

### 4. Database Tables → Usage Traceability

All 26 tables verified for business purpose, backend owner, and frontend usage.

| # | Table | Business Purpose | Backend Owner | Frontend Usage | Status |
|---|-------|-----------------|---------------|---------------|--------|
| 1 | profiles | User identity and preferences | profiles.repository | All screens (avatars, names) | ✓ |
| 2 | invitations | Invite-only registration | invitations.repository | ADMIN-002 | ✓ |
| 3 | posts | Community feed content | posts.repository | FEED-001 | ✓ |
| 4 | post_images | Photo attachments | create-post EF | FEED-001 (image grid) | ✓ |
| 5 | post_reactions | Emoji reactions | REST | FEED-001 (ReactionBar) | ✓ |
| 6 | comments | Post comments | REST | FEED-001 (CommentsSheet) | ✓ |
| 7 | post_mentions | @mention records | create-post EF | Not directly rendered (notification trigger) | ✓ |
| 8 | activities | Events | activities.repository | EVT-001, EVT-002 | ✓ |
| 9 | activity_rsvps | RSVP responses | REST | EVT-002 (RsvpSelector) | ✓ |
| 10 | activity_updates | Organizer updates | post-activity-update EF | EVT-002 (timeline) | ✓ |
| 11 | polls | Community polls | polls.repository | EVT-003 | ✓ |
| 12 | poll_options | Poll answer choices | create-poll EF | EVT-003 (PollOptionTile) | ✓ |
| 13 | poll_votes | Member votes | REST | EVT-003 (live percentages) | ✓ |
| 14 | event_attendance | Attendance records | record-attendance EF | ADMIN-005, EVT-002 (past) | ✓ |
| 15 | challenges | Fitness/wellness challenges | challenges.repository | GRO-001, GRO-002 | ✓ |
| 16 | challenge_participants | Challenge membership | REST | GRO-002 (join/leave) | ✓ |
| 17 | progress_logs | Daily progress entries | REST | GRO-002 (leaderboard) | ✓ |
| 18 | recognitions | Peer shout-outs | create-recognition EF | ANA-005, ANA-006 | **⚠ CRIT-01** |
| 19 | recognition_recipients | Recognition recipients | create-recognition EF | ANA-006 (RecipientChipList) | ✓ |
| 20 | recognition_reactions | Recognition reactions | REST | ANA-006 (ReactionBar) | ✓ |
| 21 | member_monthly_stats | Monthly engagement metrics | compute-monthly-stats EF | ANA-002, ANA-004 | **⚠ CRIT-02** |
| 22 | community_health_scores | Community health score | compute-monthly-stats EF | ANA-003 (HealthScoreCard) | ✓ |
| 23 | notification_inbox | In-app notifications | send-notification EF | NOTIF-001 | ✓ |
| 24 | flagged_content | Content moderation flags | resolve-flag EF | ADMIN-003 | ✓ |
| 25 | pinned_announcements | Pinned feed posts | pin-announcement EF | FEED-001, ADMIN-004 | ✓ |
| 26 | admin_audit_log | Admin action trail | audit.service | No V1 screen (backend-only audit) | ✓ |

**Result:** 26/26 tables have verified business purpose, backend owner, and frontend usage (or justified backend-only usage). No orphan tables.

---

### 5. Orphan Check

| Check | Result |
|-------|--------|
| Orphan features (feature in docs with no requirement) | **None found** |
| Orphan screens (screen with no navigation path or data source) | **None found** |
| Orphan database tables (table with no backend or frontend usage) | **None found** |
| Orphan Edge Functions (function with no consumer) | **None found** |
| Orphan user flows (flow referencing removed features) | **1 found: UF-06** (MED-03) |

---

## Final Verdict

| Criteria | Value | Required |
|----------|-------|----------|
| Critical issues | **2** | 0 |
| High issues | **0** | 0 |
| Medium issues | **6** | 0 |
| **Verdict** | **NOT READY TO BUILD** | — |

### Path to Readiness

**To reach Critical = 0 (mandatory before any sprint begins):**
1. **CRIT-01:** Update `backend-api-contracts.md` create-recognition `category_tag` values to match database CHECK constraint: `community_contributor`, `fitness_champion`, `wellness_champion`, `event_champion`, `most_supportive_manager`
2. **CRIT-02:** Update `rls-security-policies.md` and `database-entity-catalogue.md` to grant SELECT on `member_monthly_stats` to all authenticated active users (matching `community_health_scores` pattern), enabling the Rankings feature (FR-06.4, FR-06.5)

**To reach Medium = 0 (mandatory before build):**
3. **MED-01:** Remove `email.service.ts` and `sms.service.ts` from `backend-folder-structure.md`; update send-invitation annotations
4. **MED-02:** Rewrite `backend-architecture.md` Layer 4 to describe Flutter/Riverpod client, not Expo/React Native
5. **MED-03:** Remove UF-06 (Direct Messages) from `user-flows.md`
6. **MED-04:** Update `notification-strategy.md` client infrastructure to reference `firebase_messaging`, not `expo-notifications`
7. **MED-05:** Align emoji set across `database-entity-catalogue.md`, `database-schema-design.md`, and `design-system.md` to a single canonical set
8. **MED-06:** Add `memory`, `achievement`, `community_update` trigger types to `scheduled-connect-buddy` API contract, or descope from admin trigger sheet

**Estimated resolution effort:** 2–4 hours of document updates. No architectural changes required. No new documents needed.
