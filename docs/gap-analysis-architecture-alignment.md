# Gap Analysis: Architecture Alignment Review

**Date:** 2026-06-19  
**Scope:** All 33 documentation files in `docs/` plus the two Flutter architecture files generated in this session  
**Purpose:** Identify every deviation between current documentation and the approved Manager Connect product architecture  
**Status:** FOR REVIEW — No files modified. Awaiting approval before corrections begin.

---

## Executive Summary

| Category | Count |
|---|---|
| Files with deviations | 15 of 35 |
| Critical deviations (feature removal) | 2 |
| Critical deviations (missing features) | 4 |
| Module restructuring deviations | 6 |
| Rename/relabeling deviations | 9 |
| Theme/UI deviations | 1 |
| Concepts with zero documentation | 3 |
| Open questions requiring clarification before correction | 6 |

---

## Deviation 1: Messages Module Exists and Must Be Removed

**Correction Required:** Remove all messaging (DM + group chat) from the product entirely.

**Current State:** Messaging is documented as a first-class feature across every layer of the architecture — database, backend, API contracts, navigation, and the newly generated Flutter files. It is present in 13 documents.

### File-by-File Deviations

**`docs/requirements.md`**
- R08: "In-app messaging (group and direct)" listed as **Must Have (V1)** — must be removed entirely

**`docs/functional-requirements.md`**
- FR-07 (entire section, 6 requirements): Messaging requirements must be removed
  - FR-07.1: Direct messages
  - FR-07.2: Community group chat
  - FR-07.3: Unread count badges on messaging tab
  - FR-07.4: Message push notifications
  - FR-07.5: Message history and search
  - FR-07.6: Admin DM privacy rule

**`docs/module-breakdown.md`**
- Module 7: Messages (entire module) must be removed
  - Screens: Messages hub, Community group chat, Direct message conversation
  - All listed responsibilities
  - Dependencies on Supabase Realtime and conversations/messages tables

**`docs/information-architecture.md`**
- Domain 5: Messages section must be removed
  - Community Group Chat
  - Direct Messages conversation list
  - Conversation thread

**`docs/navigation-architecture.md`**
- Tab 5 "Messages" with chat bubble icon and unread badge — must be removed from tab bar
- Route `/conversation/[id]` — must be removed
- Deep link entry: "New DM → `/conversation/[id]`" — must be removed
- FR-07.3 reference (unread badge on messages tab) — must be removed

**`docs/notification-strategy.md`**
- Category 5: Message Notifications — entire section must be removed
  - New direct message notification
  - New community group message notification
- Notification preference rows for DMs and group messages must be removed from the preferences table
- `notification_preferences` default JSONB structure references DM and group message prefs — must be removed

**`docs/development-roadmap.md`**
- Sprint 4 title includes "Communication" — must be revised
- Sprint 4 "Messages Module" task block (9 tasks) must be removed entirely
  - Conversations and messages DB migration
  - Messages hub screen
  - Community group chat
  - Direct message thread
  - Unread count badge on messages tab
  - Real-time message delivery
  - Message search
- Sprint 4 Definition of Done references "Messages delivered in real time" and "Admin cannot access DM conversation content" — both must be removed
- Milestone M4 description "Communication: messaging, notifications" — must be revised

**`docs/database-strategy.md`**
- Schema Summary table: `conversations`, `conversation_participants`, `messages` (3 tables) must be removed — total table count drops from 23 to 20
- Messaging layer row in Schema Summary must be removed
- RLS Policy Matrix: `conversations`, `conversation_participants`, `messages` rows must be removed
- Indexing Strategy: `idx_messages_conversation` and `idx_messages_sender` indexes must be removed
- Scalability section: "messages will be the largest table over time" note must be removed
- Data Lifecycle table: soft-deleted messages row must be removed
- Storage bucket entry: no messaging-related storage (none exists currently — no change needed here)

**`docs/database-entity-catalogue.md`**
- Table: `conversations` — entity definition must be removed
- Table: `conversation_participants` — entity definition must be removed
- Table: `messages` — entity definition must be removed (this includes the critical DM privacy RLS policy that was a specific design decision)
- Schema at a Glance table: rows 17, 18, 19 must be removed

**`docs/database-er-diagram.md`**
- Diagram 6: Messaging — entire diagram must be removed
- Diagram 9: Complete System Overview — all messaging-related relationships must be removed:
  - `CONVERSATIONS ||--|{ CONVERSATION_PARTICIPANTS`
  - `CONVERSATIONS ||--o{ MESSAGES`
  - `PROFILES ||--o{ CONVERSATION_PARTICIPANTS`
  - `PROFILES ||--o{ MESSAGES`
- Key Design Observations section: "Conversation Polymorphism" note must be removed

**`docs/backend-architecture.md`**
- Module Boundary diagram: `messaging` module box must be removed
- Module Ownership section: messaging module must be removed
- Realtime Channel Catalogue: `messages:conversation:{id}` channel must be removed; `messaging:conversations:{uid}` channel must be removed
- Cross-Module Operations table: `create-profile` side effect entry referencing messaging must be updated (create-profile no longer adds user to group chat)
- Security trust boundary mention of DM privacy rule must be removed

**`docs/backend-folder-structure.md`**
- `supabase/functions/create-conversation/` directory must be removed
- All messaging-related references in `supabase/functions/_shared/repositories/` (conversations.repository.ts, messages.repository.ts) must be removed
- `src/services/messaging/` module directory and all files must be removed
- `src/hooks/messaging/` module directory must be removed
- `src/realtime/messages.ts` file must be removed
- `src/stores/` unread count state (if any) must be removed

**`docs/backend-api-contracts.md`**
- Messaging section in Operation Registry must be removed (8 operations)
- `POST /create-conversation` Edge Function contract must be removed
- `send-notification` function: DM notification type must be removed from the function's notification type enum

**`docs/flutter-architecture.md`** *(generated this session)*
- `features/messages/` module reference must be removed from module organization section
- Realtime channel example for `messages:conversation:{id}` must be removed or replaced
- `conversationsNotifierProvider` must be removed from the provider type examples
- `messagesNotifierProvider` must be removed
- `messagesRealtimeProvider` must be removed
- `unreadCountProvider` must be removed from the provider list

**`docs/flutter-folder-structure.md`** *(generated this session)*
- `features/messages/` entire module tree must be removed (all data/domain/presentation sub-files)
- `shared/widgets/` chat-related widgets must be removed if any were referenced
- `pubspec.yaml` has no messaging-specific packages — no change needed here

---

## Deviation 2: Module Structure Does Not Match Approved Architecture

**Correction Required:** Replace all references to the old 8-module structure with the approved 6-module structure.

| Current Module | Status | Approved Module |
|---|---|---|
| Auth | Retained as system concern (not a nav tab) | Auth (infrastructure only) |
| Feed | Retained | Feed |
| Activities | Replaced | → absorbed into Events |
| Wellness | Replaced | → absorbed into Growth |
| Recognition | **UNPLACED** ⚠ | Not named in approved module list |
| Messages | Removed | — |
| Profile | Retained | Profile |
| Admin | Retained | Admin |
| *(absent)* | New | Events |
| *(absent)* | New | Growth |
| *(absent)* | New | Analytics |

**Recognition Module Status — Open Question:**
Recognition is a documented module with 3 database tables (`recognitions`, `recognition_recipients`, `recognition_reactions`), its own navigation tab, and its own screens. The approved module list does not name it. This is the single largest unresolved placement question. See Section: Open Questions for clarification needed before correction.

### Files Affected by Module Rename

All 15 files listed in Deviation 1 above, plus every doc that lists module names. The rename impacts are:

- All references to "Activities module" → "Events module"
- All references to "Wellness module" → "Growth module"  
- All references to "Messaging/Messages module" → removed (Deviation 1)
- Addition of "Analytics module" in all architecture files
- Resolution needed for "Recognition module" placement

---

## Deviation 3: Events Module Is Incomplete

**Correction Required:** The "Events" module must contain: Games, Outings, Social Connect, Polls, RSVP, Attendance, Event History.

**Current State:** The "Activities" module (which becomes Events) only documents Outings, RSVP, and a basic form of Event History. Five of the seven required sub-features are absent or misclassified.

### Sub-Feature Gap Analysis

| Required Sub-Feature | Current Status | Gap |
|---|---|---|
| Outings | Present (as "Activities") | Rename only |
| RSVP | Present (Going/Not Going/Maybe) | Rename only |
| Event History | Present (as "Past Activities") | Rename only |
| Games | **ABSENT** | Not defined anywhere |
| Social Connect | **ABSENT** | Not defined anywhere |
| Polls | Present only as V2 Nice-to-Have (R15) — must be **PROMOTED to V1** | Significant rework |
| Attendance | **ABSENT as a concept** | RSVP tracks intent; Attendance tracks actual presence post-event |

### Polls Promotion Impact

Polls are currently marked as "R15 — Nice to Have (V2+)" in `requirements.md`. Promoting to V1 requires:

- `requirements.md`: Move Polls from R15 (V2+ Nice to Have) to Must Have. Update constraints section which says "R15 Polls" is out of scope for V1.
- `functional-requirements.md`: New FR section for Polls (requirements do not currently exist at all for Polls)
- `database-entity-catalogue.md`: New tables needed — `polls`, `poll_options`, `poll_votes` (none exist)
- `database-strategy.md`: Schema summary table count increases; new indexes needed
- `database-er-diagram.md`: New ER diagram for Polls domain
- `backend-api-contracts.md`: New Poll operations in Operation Registry; possible new Edge Functions
- `backend-folder-structure.md`: New poll-related files in `_shared/repositories/` and `supabase/functions/`
- `flutter-folder-structure.md`: New `features/events/` module structure (replaces `features/activities/`)
- `notification-strategy.md`: Poll reminder notifications must be added (Deviation 8)
- `development-roadmap.md`: Sprint plan must include Polls development tasks

### Attendance Gap Impact

Attendance as a distinct concept (post-event actual presence recording, separate from pre-event RSVP intent) does not exist anywhere in the current documentation. Requires:
- Definition of what Attendance means (check-in? Admin marks? Self-report?)
- New database column(s) or table
- New UI flow
- Clarification needed — see Open Questions

### Games Gap Impact

Games are not mentioned anywhere. Requires definition of scope before documentation can be corrected. See Open Questions.

### Social Connect Gap Impact

Social Connect is not mentioned anywhere. Requires definition before documentation can be corrected. See Open Questions.

---

## Deviation 4: Growth Module Not Defined

**Correction Required:** Replace Wellness module with Growth module containing both Fitness and Wellness.

**Current State:** The "Wellness" module exists but treats Fitness and Wellness as a single undifferentiated concept. There is no "Growth" module.

### File-by-File Deviations

**`docs/requirements.md`**
- R04: "Wellness and fitness challenge tracking" — needs to be restructured as the Growth module (Fitness + Wellness)

**`docs/functional-requirements.md`**
- FR-05 is titled "Wellness and Fitness Challenges" — exists but is a flat list without Fitness/Wellness distinction
- No sub-categorization between fitness tracking (steps, distance, physical metrics) and wellness activities

**`docs/module-breakdown.md`**
- Module 5 "Wellness" must be renamed and restructured as "Growth" with explicit Fitness and Wellness sub-sections

**`docs/information-architecture.md`**
- Domain 3 "Wellness" section heading must change to "Growth"
- Internal structure must differentiate Fitness vs. Wellness sub-features

**`docs/navigation-architecture.md`**
- Tab 3 label: "Wellness" → "Growth"
- Tab icon: "Flame/pulse icon" — may need to be revisited
- Route group: `wellness/` → `growth/`

**`docs/development-roadmap.md`**
- Sprint 3 "Wellness Module" tasks → "Growth Module"
- Milestone M3: "Engagement core: wellness, recognition" → updated

**`docs/database-entity-catalogue.md`**
- `challenges` table currently conflates fitness (steps, distance) and wellness goals — may need sub-categorization column
- `goal_type` CHECK constraint: ('steps', 'distance', 'duration', 'custom') — adequate for both Fitness and Wellness if categorized, but needs review

**`docs/backend-architecture.md`**
- `wellness` module label in module boundary diagram → `growth`

**`docs/backend-folder-structure.md`**
- All `wellness/` paths → `growth/`
- `supabase/functions/_shared/repositories/wellness.repository.ts` → `growth.repository.ts`

**`docs/backend-api-contracts.md`**
- "Wellness Challenges" section header → "Growth" or "Fitness / Wellness"

**`docs/flutter-architecture.md`** *(generated this session)*
- `wellnessNotifierProvider` references → `growthNotifierProvider`
- All module references to wellness → growth

**`docs/flutter-folder-structure.md`** *(generated this session)*
- `features/wellness/` entire directory → `features/growth/`
- All internal file names following wellness naming → growth naming

---

## Deviation 5: Analytics Module Is Entirely Absent

**Correction Required:** Create an Analytics module with Personal Analytics, Community Analytics, Community Health Score, Monthly Rankings, All-Time Rankings.

**Current State:** Analytics does not exist as a module. The only analytics in the product are:
1. Admin-only basic engagement metrics (MAU count, posts count, activities count) visible in the Admin panel
2. PostHog event analytics (backend, not user-visible)

Neither of these is the Analytics module described in the approved architecture. This is a **net-new module** with no existing documentation foundation.

### What Needs to Be Created from Scratch

| Document | Required New Content |
|---|---|
| `requirements.md` | New requirements for Analytics as a member-visible feature |
| `functional-requirements.md` | New FR section: Analytics (Personal + Community + Health Score + Rankings) |
| `module-breakdown.md` | New Module: Analytics — screens, responsibilities, dependencies |
| `information-architecture.md` | New Domain: Analytics — full IA breakdown |
| `navigation-architecture.md` | New Tab: Analytics (replaces current tab slot for Recognition) |
| `database-entity-catalogue.md` | New tables — likely: `community_health_scores`, `monthly_rankings`, `member_analytics_snapshots` (exact schema TBD) |
| `database-strategy.md` | New domain in schema summary; new indexes |
| `database-er-diagram.md` | New ER diagram for Analytics domain |
| `backend-api-contracts.md` | New Analytics operations in registry |
| `backend-architecture.md` | New analytics module in module boundary diagram |
| `backend-folder-structure.md` | New analytics files in repositories and client services |
| `flutter-architecture.md` | New analytics providers and module reference |
| `flutter-folder-structure.md` | New `features/analytics/` module tree |
| `development-roadmap.md` | New sprint tasks for Analytics module |

### Analytics Sub-Features — Current Coverage

| Required | Current Coverage |
|---|---|
| Personal Analytics | **ABSENT** — No per-member stats, activity history, participation counts, wellness progress summaries, or recognition counts are surfaced to the member themselves |
| Community Analytics | **PARTIAL** — Admin has basic counts (posts, MAU, activities). True community analytics visible to all members is absent |
| Community Health Score | **ABSENT** — This concept is not mentioned anywhere. No scoring model defined |
| Monthly Rankings | **PARTIAL** — Wellness leaderboard exists per-challenge but is challenge-scoped, not month-scoped or cross-module |
| All-Time Rankings | **ABSENT** — No all-time ranking system exists |

---

## Deviation 6: Connect Buddy Is Not Documented Anywhere

**Correction Required:** Connect Buddy is described as a "core system component" — it must be designed and documented.

**Current State:** The phrase "Connect Buddy" does not appear in any of the 35 documentation files. There is no definition, no feature description, no database schema, no API contracts, no UI description, and no notification integration for this system component.

### Impact Scope

This is a complete net-new architectural element. Because it is described as a "core system component" (not a secondary feature), its impact spans potentially every layer:

| Layer | Required Work |
|---|---|
| Product requirements | Define what Connect Buddy does |
| Functional requirements | New FR section |
| Database | New table(s) and relationships |
| Backend | New Edge Function(s) and/or PostgREST operations |
| Flutter | New feature module or shared service |
| Notifications | Connect Buddy update notifications (Correction 8) |
| Navigation | Connect Buddy's place in the IA |

**This deviation cannot be corrected until Connect Buddy is defined.** See Open Questions.

---

## Deviation 7: Memories Feature Is Not Documented Anywhere

**Correction Required:** Memories feature must be included in the product architecture.

**Current State:** "Memories" does not appear in any of the 35 documentation files. There is zero documentation for this feature — no requirements, no data model, no screens, no API operations.

### Impact Scope

| Layer | Required Work |
|---|---|
| Product requirements | Define what Memories is and which V1 requirements it satisfies |
| Functional requirements | New FR section |
| Database | New table(s) — likely `memories` or extension of existing content tables |
| Backend | New repository + possible Edge Function |
| Flutter | New screens and widgets (possibly within Feed module or Profile module) |
| Navigation | Where does Memories surface? (Feed? Profile? Dedicated section?) |

**This deviation cannot be fully corrected until Memories is defined.** See Open Questions.

---

## Deviation 8: Notification Architecture Has Missing Trigger Types

**Correction Required:** Notification architecture must support Poll reminders, Event reminders (renamed from Activity), and Connect Buddy updates.

**Current State:** The notification strategy covers 6 categories. Three corrections are needed.

### Missing Notification Triggers

**Poll Reminders — ABSENT**
- `docs/notification-strategy.md`: No poll notification category exists
- `docs/functional-requirements.md`: Polls had no functional requirements (V2 only)
- Once Polls are promoted to V1 (Deviation 3), poll reminder notifications must be designed and added to the notification strategy

**Connect Buddy Updates — ABSENT**
- Cannot be defined until Connect Buddy itself is defined (Deviation 6)

**Event Reminders — Rename Only**
- `docs/notification-strategy.md`: Category 1 is titled "Activity Notifications" with triggers for "Activity reminder — 24 hours" and "Activity reminder — 1 hour"
- These must be renamed to "Event Notifications" and "Event reminders" throughout

### Message Notification Removal

- `docs/notification-strategy.md`: Category 5 "Message Notifications" must be removed (Deviation 1)
- Notification preference entries for DMs and group messages must be removed from the preference defaults table

### Files Affected

| File | Change Required |
|---|---|
| `docs/notification-strategy.md` | Remove Category 5 (messages); rename Category 1; add Poll reminders; add Connect Buddy updates (pending definition) |
| `docs/functional-requirements.md` | FR-08.1 event trigger list: add Polls, remove DM; add Connect Buddy when defined |
| `docs/backend-api-contracts.md` | `send-notification` function's notification type enum: remove DM type, add Poll type |
| `docs/backend-folder-structure.md` | Notification service: update trigger type constants |
| `docs/flutter-folder-structure.md` | `notification_service.dart`: update handled notification types |
| `docs/flutter-architecture.md` | Push notification handling section: update targetScreen mapping table |

---

## Deviation 9: Navigation Structure Does Not Match

**Correction Required:** Navigation must be Feed, Events, Growth, Analytics, Profile.

**Current State:** Navigation has 5 tabs: Home (Feed), Activities, Wellness, Recognition, Messages.

### Tab-by-Tab Comparison

| Position | Current Tab | Required Tab | Status |
|---|---|---|---|
| 1 | Home (Feed) | Feed | Rename (Home → Feed label) |
| 2 | Activities | Events | Replace |
| 3 | Wellness | Growth | Replace |
| 4 | Recognition | Analytics | Replace — Recognition removed from nav |
| 5 | Messages | Profile | Replace — Messages removed; Profile promoted to tab |

### Key Changes

**Recognition Tab Removed from Navigation**
- Recognition currently has its own tab (tab 4)
- The approved navigation does not include Recognition as a tab
- Recognition's placement in the new IA is undefined — see Open Questions
- `docs/navigation-architecture.md`: Tab 4 "Recognition" must be removed
- All routes under `recognition/` need a new home in the IA

**Profile Promoted to Tab**
- Profile is currently accessed via an avatar icon in the top-right header (not a tab)
- Profile becomes tab 5 in the approved navigation
- This changes the access pattern significantly
- `docs/navigation-architecture.md`: Profile must be added as tab 5
- `docs/information-architecture.md`: Domain 6 "Profile and Settings" accessed via avatar — must be updated to tab access

**Analytics Tab Added**
- Completely new tab (Deviation 5)
- `docs/navigation-architecture.md`: Add Analytics as tab 4 with appropriate icon
- Badge behavior for Analytics tab needs definition

**Admin Navigation Unchanged**
- Admin panel accessed via Profile menu — this pattern remains valid

### Files Affected

| File | Change Required |
|---|---|
| `docs/navigation-architecture.md` | Full tab bar section rewrite; new route map |
| `docs/information-architecture.md` | Domain navigation restructure |
| `docs/module-breakdown.md` | Screen lists update for renamed modules |
| `docs/development-roadmap.md` | Sprint 1 navigation shell task updated |
| `docs/flutter-architecture.md` | ShellRoute tabs rewritten; router structure |
| `docs/flutter-folder-structure.md` | Feature directory names updated |
| `docs/backend-architecture.md` | Module boundary diagram |
| `docs/backend-folder-structure.md` | `src/services/` and `src/hooks/` directory names |

---

## Deviation 10: Dark Mode Is Documented — V1 Must Be Light Mode Only

**Correction Required:** V1 supports Light Mode only. Dark mode must not be designed or documented for V1.

**Current State:** The Flutter architecture (generated this session) explicitly designs and documents both light and dark themes.

### File-by-File Deviations

**`docs/flutter-architecture.md`** *(generated this session)*
- `AppTheme.dark` defined and documented — must be removed
- `ThemeMode.system` as default setting — must change to `ThemeMode.light` (fixed, not configurable)
- `themeNotifierProvider` — must be removed (no theme switching in V1)
- `setLight() / setDark() / setSystem()` methods on ThemeNotifier — must be removed
- "Adaptive Theme (Light / Dark)" section — must be removed
- "Theme mode persisted in SharedPreferences" — must be removed (no persistence needed)

**`docs/flutter-folder-structure.md`** *(generated this session)*
- `AppTheme.dark → ThemeData` in `core/theme/app_theme.dart` annotation — must be removed
- `theme_notifier_provider.dart` — must be removed from `shared/providers/`
- `shared_preferences` package in pubspec.yaml — required only for theme persistence; if the only use was theme, it can be removed (verify if used elsewhere before removing)
- `ThemeMode` persistence in SharedPreferences annotation on `main.dart` — must be removed

**`docs/non-functional-requirements.md`**
- No explicit mention of theme mode — no change needed here

---

## File Impact Matrix

Complete matrix showing which of the 10 corrections affects each file.

| File | D1 Msg | D2 Modules | D3 Events | D4 Growth | D5 Analytics | D6 ConnBuddy | D7 Memories | D8 Notif | D9 Nav | D10 Theme |
|---|---|---|---|---|---|---|---|---|---|---|
| `requirements.md` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | — |
| `functional-requirements.md` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | — | — |
| `module-breakdown.md` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | — | ✗ | — |
| `information-architecture.md` | ✗ | ✗ | ✗ | ✗ | ✗ | — | — | — | ✗ | — |
| `navigation-architecture.md` | ✗ | ✗ | — | ✗ | ✗ | — | — | — | ✗ | — |
| `notification-strategy.md` | ✗ | — | ✗ | — | — | ✗ | — | ✗ | — | — |
| `development-roadmap.md` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | — |
| `database-strategy.md` | ✗ | ✗ | ✗ | — | ✗ | ✗ | ✗ | — | — | — |
| `database-entity-catalogue.md` | ✗ | — | ✗ | ✗ | ✗ | ✗ | ✗ | — | — | — |
| `database-er-diagram.md` | ✗ | — | ✗ | — | ✗ | ✗ | ✗ | — | — | — |
| `backend-architecture.md` | ✗ | ✗ | — | ✗ | ✗ | ✗ | ✗ | ✗ | — | — |
| `backend-folder-structure.md` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | — |
| `backend-api-contracts.md` | ✗ | — | ✗ | — | ✗ | ✗ | ✗ | ✗ | — | — |
| `flutter-architecture.md` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| `flutter-folder-structure.md` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

**✗ = Deviation present and correction required**

---

## Documents With No Deviations Found

The following documents have no deviations from the approved architecture and require no changes:

| File | Reason No Changes Needed |
|---|---|
| `architecture-decisions.md` | ADRs cover BaaS, auth, RLS, Realtime — none are messaging-specific or module-specific |
| `business-requirements.md` | Business objectives and stakeholder concerns are module-agnostic |
| `user-personas.md` | Persona descriptions do not reference specific module names |
| `security-strategy.md` | Security principles are not module-dependent (note: DM privacy rule reference in section 3 must be removed) |
| `tech-stack.md` | Stack choices are unchanged |
| `database-strategy.md` (partial) | Design principles 1–7 are all valid; only schema-specific sections are affected |
| `testing-strategy.md` | Test levels and approach unchanged; module-specific test table needs updating |
| `deployment-strategy.md` | Deployment process is module-agnostic |
| `branching-strategy.md` | No module references |
| `coding-standards.md` | Standards are module-agnostic |
| `commit-conventions.md` | No module references |
| `api-guidelines.md` | API conventions are module-agnostic |
| `analytics-strategy.md` | PostHog event strategy is independent of product module structure |
| `future-enhancements.md` | V2+ planning |
| `production-readiness-checklist.md` | Process document |
| `release-plan.md` | Process document |
| `documentation-guidelines.md` | Meta document |

**Note:** `security-strategy.md` has one minor deviation in Section 3 PII table where "DM content — Private — Participants only; admin excluded" must be removed.

---

## Open Questions Requiring Clarification Before Corrections Can Proceed

The following 6 questions must be answered before the affected documents can be corrected. Corrections 6 and 7 are **fully blocked** pending answers.

---

### OQ-1: What is Connect Buddy?

**Blocking:** Correction 6 (Connect Buddy), Correction 8 (Connect Buddy notifications), and database/backend/Flutter corrections for the Connect Buddy component.

**Question:** What does Connect Buddy do? Possible interpretations:
- A buddy-pairing system that matches two managers together for a period (e.g., monthly)
- A social suggestion engine ("You haven't connected with [member] in 30 days")
- A virtual wellness companion or habit coach
- A gamified activity suggestion feature ("Your buddy challenged you to…")
- Something else entirely

**Why it matters:** The answer determines whether Connect Buddy is a database table, a scheduled Edge Function, a real-time feature, a new screen/module, or a cross-cutting service. The entire implementation scope depends on this definition.

---

### OQ-2: What are Memories?

**Blocking:** Correction 7 (Memories feature) and its placement in navigation/IA.

**Question:** What is the Memories feature? Possible interpretations:
- Auto-generated "On This Day" style content using past posts and activities
- A photo gallery of event/outing photos across the community
- A highlights reel (admin-curated or auto-generated monthly recap)
- A personal archive of the member's own activity participation, recognitions received, etc.

**Why it matters:** The answer determines where Memories lives in the navigation (Feed? Profile? Its own tab?), what data it aggregates, whether it requires new database tables or queries against existing content, and whether it generates push notifications.

---

### OQ-3: Where does the Recognition module live in the new structure?

**Blocking:** Correction 2 (module structure), Correction 9 (navigation), and the full restructuring of recognition-related docs.

**Question:** Recognition (peer shout-outs) is currently a standalone tab with its own database tables. In the new 5-tab navigation (Feed, Events, Growth, Analytics, Profile), it has no assigned home. Options:
- Recognition becomes a content type in Feed (recognition posts appear alongside other posts)
- Recognition becomes a sub-section within Profile (you see recognitions on a member's profile)
- Recognition gets its own section within Analytics (recognition leaderboard, most recognized members)
- Recognition is accessed from within Feed via a dedicated wall view (not a tab, but a filter)

**Why it matters:** The `recognitions`, `recognition_recipients`, and `recognition_reactions` tables are already designed. The answer determines whether those tables remain, are merged into the posts model, or stay separate. It also determines which module owns these screens.

---

### OQ-4: What are Games in the Events module?

**Blocking:** Correction 3 (Events module), database design for Games, API contracts for Games.

**Question:** What type of games does the Games sub-feature cover? Options:
- A category of events (managers organize a cricket match, badminton session, board game night) — essentially an event type within Events
- In-app competitive games between members
- Something else

**Why it matters:** If Games is just an event type/category, it requires only a `category` field on the `activities` table (games vs. outings vs. social connect). If Games is an in-app feature, it requires significant new backend and frontend design.

---

### OQ-5: What is Social Connect in the Events module?

**Blocking:** Correction 3 (Events module).

**Question:** What does Social Connect mean as an Events sub-feature? Options:
- A type of event (coffee catch-up, 1:1 meeting, team lunch — informal social events)
- A feature to suggest connections between managers who haven't interacted
- Essentially the same as "Outings" but for smaller, informal gatherings

**Why it matters:** Similar to Games — if it's an event category, the fix is a data model tweak. If it's a separate feature, it needs its own design.

---

### OQ-6: What does Attendance mean, and how is it captured?

**Blocking:** Correction 3 (Events module — Attendance sub-feature).

**Current RSVP system:** Tracks intent before the event (Going / Not Going / Maybe). This is not the same as attendance.

**Question:** What is the Attendance sub-feature? Options:
- Post-event self-report: members mark themselves as attended after the event
- Admin/organizer marks who actually attended
- QR code or geolocation check-in at the event
- Automatic: all Going RSVPs are treated as attended after the event date passes

**Why it matters:** Each option requires different database design (a new `attendance` table with different fields, or a status update on `activity_rsvps`), different UI flows, and different Edge Function logic.

---

## Summary of Corrections by Status

| Correction | Status | Can Proceed After Approval? |
|---|---|---|
| 1. Remove Messages | Fully defined | Yes — no open questions |
| 2. Module structure rename | Partially blocked | Yes for renames; blocked on Recognition placement (OQ-3) |
| 3. Events module | Partially blocked | Yes for Outings/RSVP/History rename; blocked on Games (OQ-4), Social Connect (OQ-5), Attendance (OQ-6), Polls (can proceed for promotion) |
| 4. Growth module | Fully defined | Yes — rename + Fitness/Wellness split is clear |
| 5. Analytics module | Fully defined in scope | Yes — net-new content to create |
| 6. Connect Buddy | **Fully blocked** | No — OQ-1 must be answered first |
| 7. Memories | **Fully blocked** | No — OQ-2 must be answered first |
| 8. Notification architecture | Partially blocked | Yes for message removal + rename; blocked on Connect Buddy updates (OQ-1) |
| 9. Navigation structure | Partially blocked | Yes for tab renames; blocked on Recognition placement (OQ-3) |
| 10. Light mode only | Fully defined | Yes — remove dark mode from Flutter docs |
