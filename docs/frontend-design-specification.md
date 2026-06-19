# Frontend Design Specification — Manager Connect

## Overview

This is the master UI/UX blueprint for Manager Connect. It consolidates all design decisions, references the six companion design documents, and provides the definitive specification for implementing the Flutter frontend.

**Product:** Manager Connect — Private manager community platform
**Platform:** iOS and Android (Flutter cross-platform)
**Theme:** Light mode only (V1)
**Design Language:** Material 3
**Font:** Inter (400, 500, 600, 700)
**Seed Color:** Teal `#006B5F`

---

## Companion Documents

| Document | Purpose |
|----------|---------|
| [design-system.md](design-system.md) | Typography, colors, spacing, borders, elevation, icons, avatars, badges, cards, buttons, forms, accessibility, interaction patterns, motion |
| [screen-inventory.md](screen-inventory.md) | Complete catalogue of all 33 screens with IDs, routes, entry/exit points, permissions, and key elements |
| [component-library.md](component-library.md) | 52 reusable component specifications with variants, props, structure diagrams, and usage contexts |
| [user-journey-maps.md](user-journey-maps.md) | 16 user journeys mapped step-by-step from trigger to completion with error paths |
| [navigation-flow-diagrams.md](navigation-flow-diagrams.md) | Complete route tree, tab navigation, stack navigation, modal flows, deep linking, back behavior |
| [ui-state-specification.md](ui-state-specification.md) | Loading, empty, error, offline, and success states for every major screen |

---

## Design Principles

### 1. Community First, Not Productivity
Manager Connect is a relationship-building platform, not a productivity tool. The UI should feel warm, inviting, and social — more like a private community feed than an enterprise dashboard. Design choices favor engagement and connection over data density.

### 2. Action Proximity
Primary actions (RSVP, vote, react, join, log) are always available on the content card or detail screen. No unnecessary deep navigation for simple interactions. One tap to engage.

### 3. Progressive Disclosure
Feed cards show summaries; detail screens show full content. Analytics starts with the Health Score; drill down for individual metrics. Admin panel shows counts; tap to manage.

### 4. Consistent State Communication
Every async screen has exactly five defined states (Loading, Empty, Error, Offline, Success). Users always know what's happening and what they can do about it.

### 5. Connect Buddy is Visible, Not Intrusive
Connect Buddy posts use subtle visual distinction (purple tint, badge) without being jarring. They appear in the natural feed flow — not as pop-ups or modals.

### 6. Admin as a Separate World
Admin functionality is completely invisible to non-admin users. The Admin panel is a hidden section accessed via Profile, not a persistent tab. Admin screens never bleed into the member experience.

---

## Screen Architecture Summary

### Screen Count by Module

| Module | Screens | Bottom Sheets | Dialogs |
|--------|---------|--------------|---------|
| Auth | 3 | 0 | 0 |
| Feed | 1 | 2 | 3 |
| Events | 4 | 3 | 1 |
| Growth | 3 | 2 | 0 |
| Analytics | 6 | 1 | 0 |
| Profile | 4 | 0 | 1 |
| Admin | 6 | 3 | 4 |
| Notifications | 1 | 0 | 0 |
| Utility | 4 | 0 | 0 |
| **Total** | **32 + 1 shell** | **11** | **9** |

### Navigation Structure

```
App Root
├── Auth Group (unauthenticated)
│   ├── Welcome (/welcome)
│   ├── Verify OTP (/verify-otp)
│   └── Create Profile (/create-profile)
│
├── Shell Route (authenticated — 5-tab bottom nav)
│   ├── Tab 1: Feed (/feed)
│   ├── Tab 2: Events (/events)
│   ├── Tab 3: Growth (/growth)
│   ├── Tab 4: Analytics (/analytics)
│   └── Tab 5: Profile (/profile)
│
├── Stack Routes (push over any tab)
│   ├── Event Detail (/event/:id)
│   ├── Poll Detail (/event/:id/poll/:pollId)
│   ├── Challenge Detail (/challenge/:id)
│   ├── Recognition Detail (/recognition/:id)
│   ├── Full Rankings (/analytics/ranking)
│   ├── Member Profile (/profile/:id)
│   └── Notifications (/notifications)
│
└── Admin Group (authenticated + admin role)
    ├── Admin Overview (/admin)
    ├── Admin Members (/admin/members)
    ├── Admin Flagged (/admin/flagged)
    ├── Admin Announcements (/admin/announcements)
    ├── Admin Attendance (/admin/attendance)
    └── Admin Connect Buddy (/admin/connect-buddy)
```

---

## Component Architecture Summary

### Component Count by Category

| Category | Count |
|----------|-------|
| App Bars | 1 |
| Bottom Navigation | 1 |
| Feed Cards | 3 |
| Event Components | 6 |
| Poll Components | 2 |
| Challenge Components | 5 |
| Analytics Components | 4 |
| Recognition Components | 4 |
| Comment Components | 2 |
| Notification Components | 2 |
| Reaction Components | 2 |
| Dialogs | 2 |
| Bottom Sheets | 10 |
| Empty States | 1 (parameterized) |
| Error States | 1 |
| Loading Skeletons | 4 |
| Shared Utility | 2 |
| **Total** | **52** |

### Component Hierarchy

```
Shared (used across all modules)
├── McAppBar
├── MainScaffold (NavigationBar)
├── McAvatar (6 sizes × 2 variants)
├── McCachedImage
├── McCard
├── McBottomSheet
├── ConfirmDialog / ErrorDialog
├── EmptyStateWidget
├── ErrorStateWidget
├── SkeletonLoader (+ FeedSkeleton, EventsSkeleton, AnalyticsSkeleton)
├── PrimaryButton / SecondaryButton / IconTextButton
├── EventCategoryChip / StatusChip
└── ReactionBar / MentionInputField

Feature-Specific
├── Feed: PostCard, ConnectBuddyPostCard, PinnedPostBanner, CommentsSheet, CommentTile, CreatePostSheet
├── Events: EventCard, EventTypeSelector, RsvpSelector, AttendeeListTile, EventUpdateTile, PollCard, PollOptionTile, CreateEventSheet, CreatePollSheet
├── Growth: ChallengeCard, ChallengeTypeFilter, GoalTypeSelector, LeaderboardList, LeaderboardEntryTile, LogProgressSheet, CreateChallengeSheet
├── Analytics: HealthScoreCard, HealthScoreBreakdown, PersonalStatCard, RankingEntryTile, RecognitionCard, CategoryTagBadge, RecipientChipList, RecognitionReactionBar, GiveRecognitionSheet
├── Profile: ProfileHeader, InterestTagChip, MemberSearchTile, ReceivedRecognitionsList
├── Admin: MemberManagementTile, PendingInvitationTile, FlaggedContentCard, InviteMemberSheet, AttendanceRecordingSheet, ConnectBuddyTriggerSheet, AdminActionConfirm
└── Notifications: NotificationTile, NotificationMarkAllButton
```

---

## User Journey Summary

### 16 Documented User Journeys

| # | Journey | Actor | Key Screens |
|---|---------|-------|-------------|
| UJ-01 | First-Time Onboarding | New Manager | Welcome → OTP → Create Profile → Feed |
| UJ-02 | Login (Returning) | Any Member | Splash → (Welcome → OTP →) Feed |
| UJ-03 | Feed Usage | Any Member | Feed (browse, react, comment) |
| UJ-04 | Create Post | Any Member | Feed → Create Post Sheet → Feed |
| UJ-05 | Mention Manager | Any Member | Create Post/Comment → @autocomplete |
| UJ-06 | Create Event | Any Member | Events → Create Event Sheet → Events |
| UJ-07 | RSVP to Event | Any Member | Events → Event Detail → RSVP Selector |
| UJ-08 | Vote in Poll | Any Member | Event Detail → Poll Detail → Vote |
| UJ-09 | Join Challenge | Any Member | Growth → Challenge Detail → Join |
| UJ-10 | Log Progress | Joined Member | Challenge Detail → Log Progress Sheet |
| UJ-11 | Give Recognition | Any Member | Recognition → Give Recognition Sheet |
| UJ-12 | View Analytics | Any Member | Analytics tabs (Personal/Community/Rankings/Recognition) |
| UJ-13 | Notification Flow | Any Member | Push → Deep Link → Target Screen |
| UJ-14 | Admin Invitation | Admin | Admin Members → Invite Sheet → URL Copy |
| UJ-15 | Admin Attendance | Admin | Admin Attendance → Recording Sheet |
| UJ-16 | Admin Moderation | Admin | Admin Flagged → Delete/Dismiss |

---

## Design System Key Tokens

### Colors (Quick Reference)

| Token | Value | Usage |
|-------|-------|-------|
| Brand Seed | `#006B5F` (Teal) | Drives entire Material 3 palette |
| Success | `#2E7D32` | RSVP Going, Attended, success states |
| Warning | `#F57F17` | RSVP Maybe, caution indicators |
| Danger | `#C62828` | RSVP Not Going, Absent, destructive actions |
| Connect Buddy Badge | `#7C4DFF` | CB avatar badge, CB-related accents |
| CB Post Background | `#F3E5F5` | Connect Buddy post card background |
| Pinned Background | `#FFF8E1` | Pinned announcement banner |
| Health High | `#2E7D32` | Score >= 70 |
| Health Medium | `#F57F17` | Score 40–69 |
| Health Low | `#C62828` | Score < 40 |

### Typography (Quick Reference)

| Usage | Style | Size | Weight |
|-------|-------|------|--------|
| AppBar title | `titleLarge` | 22sp | SemiBold 600 |
| Card title | `titleMedium` | 16sp | Medium 500 |
| Post body | `bodyLarge` | 16sp | Regular 400 |
| Default body | `bodyMedium` | 14sp | Regular 400 |
| Timestamp/caption | `bodySmall` | 12sp | Regular 400 |
| Button label | `labelLarge` | 14sp | Medium 500 |
| Tab label | `labelMedium` | 12sp | Medium 500 |

### Spacing (Quick Reference)

| Token | Value | Usage |
|-------|-------|-------|
| Screen padding | 16px | Horizontal edge padding |
| Card margin | 16px H, 8px V | Between cards |
| Card padding | 12px | Inner content |
| Section gap | 20px | Between major sections |
| Component gap | 8px | Between elements within a component |

---

## Accessibility Compliance

| Requirement | Specification |
|-------------|--------------|
| Minimum touch target | 48×48dp for all interactive elements |
| Text scaling | Supports up to 1.5x system font scale |
| Color contrast | WCAG AA (4.5:1 normal text, 3:1 large text) |
| Screen reader | All images have `semanticLabel`; interactive elements have descriptive labels |
| Focus indicators | 2px `primary` outline with 2px offset |
| Keyboard navigation | Logical tab order; focus trapped in dialogs |

---

## Interaction Pattern Summary

| Pattern | Specification |
|---------|--------------|
| Pull to refresh | 80px trigger, Material 3 RefreshIndicator, primary color |
| Infinite scroll | 20 items/page, 200px trigger distance, spinner indicator |
| Image upload | Camera/Gallery → compress ≤1MB → thumbnail preview → upload on submit |
| Bottom sheets | DraggableScrollableSheet, 70% initial, 90% max, 50% min snap, 24px radius |
| Dialogs | AlertDialog, 12px radius, Cancel + Confirm/Destructive buttons |
| Snackbars | Floating, 12px margin, 3s (info) / 5s (error with retry) |
| Back navigation | Stack: pop previous; Sheet: dismiss; Deep link: tab root fallback |
| Optimistic updates | Immediate UI change → await server → revert on failure + error snackbar |

---

## Design Consistency Audit

### Verified Consistencies

1. **Color system:** All semantic colors defined once in `AppThemeExtension`; no hardcoded hex values in widgets
2. **Typography:** All text uses Material 3 `TextTheme` styles; no inline `TextStyle` constructors
3. **Spacing:** All spacing uses 4px-based tokens; no arbitrary pixel values
4. **Border radius:** Consistent per-component radius defined in theme overrides
5. **Card structure:** All content cards follow Header → Body → Footer pattern
6. **Empty states:** Every list screen has a defined empty state with icon, title, subtitle, and optional CTA
7. **Error states:** Every async screen uses `ErrorStateWidget` with retry
8. **Loading states:** Every async screen uses skeleton shimmer matching content layout
9. **Button hierarchy:** Consistent use of Filled (primary), Outlined (secondary), Text (tertiary)
10. **Navigation:** All stack screens have back button; all modals dismissible via standard gestures

### Identified Design Considerations

1. **Calendar view (R22 — V1 stretch):** Events screen includes calendar toggle as "Should Have". If implemented, it should use a horizontal week-strip calendar (not full-month) to conserve vertical space. Component not specified in this phase — defer to implementation sprint.

2. **Photo sharing in events (R21 — V1 stretch):** Photo sharing is specified for posts but not for events in V1. If added, it would use the same `McCachedImage` component and image upload flow from the Feed module.

3. **Dark mode (R27 — V2+):** The entire design system is light-mode only. All semantic colors, theme extensions, and contrast ratios are validated for light mode. Dark mode will require a parallel `AppTheme.dark` and dark-mode color audit.

4. **Notification batching:** The notification strategy specifies batching (e.g., "5 new comments on your post") but the notification tile component renders individual notifications. Batched notifications should collapse into a single tile with count badge — this is a server-side concern that needs coordination with the `send-notification` Edge Function.

---

## Frontend Readiness Verdict

### Completeness Assessment

| Deliverable | Status | Notes |
|-------------|--------|-------|
| Screen inventory | **Complete** | 33 screens catalogued with IDs, routes, permissions, entry/exit points |
| User journeys | **Complete** | 16 journeys documented with step-by-step flows, error paths, notification touchpoints |
| Design system | **Complete** | Typography, colors, spacing, borders, elevation, icons, avatars, badges, cards, buttons, forms, accessibility, motion |
| Component library | **Complete** | 52 reusable components specified with structure, variants, and interactions |
| Navigation flows | **Complete** | Full route tree, tab nav, stack nav, modals, deep links, back behavior |
| UI state specification | **Complete** | Loading/Empty/Error/Offline/Success for every screen and bottom sheet |
| Accessibility | **Complete** | Touch targets, font scaling, screen reader, contrast, focus management |

### Metrics

| Metric | Value |
|--------|-------|
| Total screens | 33 |
| Total reusable components | 52 |
| Total user journeys | 16 |
| Total bottom sheets | 11 |
| Total dialogs | 9 |
| Total notification types mapped | 15 |
| Total routes | 22 |
| Design inconsistencies found | 0 (4 design considerations noted for future phases) |

### Verdict: **READY FOR IMPLEMENTATION**

All design specifications are complete, consistent with the approved architecture documents, and aligned with the Flutter implementation plan. The design system, component library, screen inventory, user journeys, navigation flows, and UI states form a comprehensive blueprint that covers every screen, interaction, and edge case required for V1 implementation.

**Recommended next step:** Review and approve this design specification phase, then proceed to Sprint 1 implementation (Foundation + Auth module) as defined in `flutter-implementation-plan.md`.

---

## Document Cross-References

| Topic | Authoritative Document |
|-------|----------------------|
| Product vision and requirements | `product-vision.md`, `requirements.md` |
| Functional requirements | `functional-requirements.md` |
| Information architecture | `information-architecture.md` |
| Navigation routes and guards | `navigation-architecture.md` |
| Flutter architecture and patterns | `flutter-architecture.md` |
| Flutter folder structure | `flutter-folder-structure.md` |
| Flutter implementation plan | `flutter-implementation-plan.md` |
| Backend architecture | `backend-architecture.md` |
| Backend API contracts | `backend-api-contracts.md` |
| Database schema | `database-schema-design.md` |
| Notification strategy | `notification-strategy.md` |
| Design system (this phase) | `design-system.md` |
| Screen inventory (this phase) | `screen-inventory.md` |
| Component library (this phase) | `component-library.md` |
| User journeys (this phase) | `user-journey-maps.md` |
| Navigation flows (this phase) | `navigation-flow-diagrams.md` |
| UI states (this phase) | `ui-state-specification.md` |
