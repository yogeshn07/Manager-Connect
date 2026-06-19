# Component Library — Manager Connect

## Overview

This document catalogues every reusable UI component in the Manager Connect application. Components are organized by category and defined with their variants, props, visual specifications, and usage contexts. All components reference the design tokens defined in `design-system.md`.

**Total Reusable Component Count: 52**

---

## 1. App Bars

### CMP-001: McAppBar

**Location:** `shared/widgets/app_bar/mc_app_bar.dart`

| Property | Specification |
|----------|--------------|
| Height | 56px (Material 3 default) |
| Elevation (resting) | 0dp |
| Elevation (scrolled) | 6dp (`scrolledUnderElevation`) |
| Title style | `titleLarge` (22sp, SemiBold 600) |
| Title alignment | Start (left-aligned, `centerTitle: false`) |
| Background | `surface` |
| Leading | Back chevron (on stack screens) or none (tab roots) |
| Actions area | Up to 3 icon buttons (24px icons) |

**Variants:**
- **Tab Root AppBar:** No leading icon. Title is tab name. Actions: notification bell (Profile tab only).
- **Detail Screen AppBar:** Back chevron leading. Title is content title. Actions: contextual (share, delete, more).
- **Admin AppBar:** Back chevron. Title is admin section name. No actions beyond back.

**Usage:** Every screen in the app uses `McAppBar` or the default `AppBar` from `AppBarTheme`.

---

## 2. Bottom Navigation

### CMP-002: MainScaffold

**Location:** `shared/widgets/bottom_nav/main_scaffold.dart`

| Property | Specification |
|----------|--------------|
| Widget | `NavigationBar` (Material 3) |
| Tab count | 5 |
| Height | 80px |
| Elevation | Level 2 (3dp) |
| Indicator | Brand-tinted selected indicator (16px radius) |
| Icon size | 24px |
| Label style | `labelMedium` (12sp) |
| Badge position | Top-right of icon |

**Tabs:**

| # | Label | Icon (Inactive) | Icon (Active) | Badge |
|---|-------|----------------|---------------|-------|
| 1 | Feed | `feed_outlined` | `feed` | Dot (new CB posts) |
| 2 | Events | `event_outlined` | `event` | Dot (upcoming within 24h) |
| 3 | Growth | `trending_up_outlined` | `trending_up` | Count (active challenges) |
| 4 | Analytics | `analytics_outlined` | `analytics` | None |
| 5 | Profile | `person_outlined` | `person` | Count (unread notifications) |

**Behavior:**
- Tab switch preserves per-tab navigation stack (StatefulShellRoute)
- Active tab icon fills; inactive icon is outlined
- Badge updates reactively from provider state

---

## 3. Feed Cards

### CMP-003: PostCard

**Location:** `features/feed/presentation/widgets/post_card.dart`

| Property | Specification |
|----------|--------------|
| Background | `surfaceContainer` |
| Border radius | 12px |
| Padding | 12px |
| Margin | 16px horizontal, 8px vertical |

**Structure:**
```
┌─────────────────────────────────────────────┐
│ [Avatar MD] [Author Name]  [Timestamp]  [⋮] │  ← Header
│                                             │
│ Post content text (bodyLarge)               │  ← Body
│                                             │
│ [Image Grid — 1 to 4 images, 12px radius]   │  ← Images (optional)
│                                             │
│ [😀 3] [❤️ 5] [👍 2]    [💬 12] [⚑ Flag]    │  ← Footer
└─────────────────────────────────────────────┘
```

**Header:** Avatar (MD 40px) + Author name (`titleSmall` SemiBold) + Timestamp (`bodySmall` onSurfaceVariant) + More menu (own post: Delete; any post: Flag)
**Body:** Post content (`bodyLarge`), max 6 lines with "See more" expansion
**Images:** Grid layout — 1 image: full width; 2: side-by-side; 3: 1 large + 2 small; 4: 2x2 grid. All 12px radius.
**Footer:** Reaction bar (emoji chips with counts) + Comment count + Flag action

**Interactions:**
- Tap card → expand comments (inline or sheet)
- Tap author avatar → navigate to `/profile/:id`
- Tap emoji → react (optimistic update)
- Tap comment icon → open comments sheet
- Long press (own post) → delete option
- Tap "⋮" → context menu

---

### CMP-004: ConnectBuddyPostCard

**Location:** `features/feed/presentation/widgets/connect_buddy_post_card.dart`

Inherits structure from `PostCard` with visual overrides:

| Override | Value |
|----------|-------|
| Background | `connectBuddyPostBackground` (#F3E5F5) |
| Avatar | Connect Buddy avatar with badge overlay |
| Author name | "Connect Buddy" with system label badge |
| More menu | Delete visible to admin only; no Flag option |
| Reactions | Same as PostCard |

**Content types rendered:** Welcome messages, event reminders, poll reminders, achievement announcements, monthly highlights, community updates, memories.

---

### CMP-005: PinnedPostBanner

**Location:** `features/feed/presentation/widgets/pinned_post_banner.dart`

| Property | Specification |
|----------|--------------|
| Background | `pinnedPostBackground` (#FFF8E1) |
| Border radius | 12px |
| Leading icon | Pin icon (16px, `primary`) |
| Position | Above feed list, fixed (not scrollable) |
| Padding | 12px |
| Elevation | Level 1 |

**Structure:** Pin icon + "Pinned" label (`labelMedium`, primary) + Post content preview (1 line, `bodyMedium`) + Author name. Tap navigates to full post.

---

## 4. Event Cards

### CMP-006: EventCard

**Location:** `features/events/presentation/widgets/event_card.dart`

| Property | Specification |
|----------|--------------|
| Background | `surfaceContainer` |
| Border radius | 12px |
| Padding | 12px |

**Structure:**
```
┌────────────────────────────────────────────┐
│ [Category Chip] [Type Chip]   [Status Chip]│  ← Header chips
│                                            │
│ Event Title (titleMedium, SemiBold)        │
│ 📅 Jun 25, 2026 · 8:00 AM                 │  ← Date/Time
│ 📍 Corporate Park Ground Floor             │  ← Location
│                                            │
│ [👤 8 Going] [👤 3 Maybe]                  │  ← RSVP summary
│ [Creator Avatar XS] Created by Arjun       │  ← Creator
└────────────────────────────────────────────┘
```

**Interactions:** Tap → navigate to `/event/:id`

---

### CMP-007: EventCategoryChip

**Location:** `shared/widgets/chips/event_category_chip.dart`

| Category | Background | Text Color |
|----------|-----------|------------|
| Games | `primaryContainer` | `onPrimaryContainer` |
| Outings | `secondaryContainer` | `onSecondaryContainer` |
| Social Connect | `tertiaryContainer` | `onTertiaryContainer` |

- Border radius: 8px
- Text: `labelMedium`
- Height: 28px
- Padding: 8px horizontal

---

### CMP-008: EventTypeSelector

**Location:** `features/events/presentation/widgets/event_type_selector.dart`

Horizontal scrolling chip row showing sub-types within a selected event category.

| Category Selected | Options Shown |
|-------------------|---------------|
| Games | Cricket, Badminton, Pickleball, Table Tennis, Other |
| Social Connect | Coffee Connect, Lunch Meetup, Dinner Meetup, Other |
| Outings | (No sub-types — selector hidden) |

Chips: `ChoiceChip` style, 8px radius, `labelMedium` text.

---

### CMP-009: RsvpSelector

**Location:** `features/events/presentation/widgets/rsvp_selector.dart`

Horizontal toggle group with three options:

| Option | Icon | Color |
|--------|------|-------|
| Going | `check_circle` | `rsvpGoingColor` |
| Maybe | `help_outline` | `rsvpMaybeColor` |
| Not Going | `cancel` | `rsvpNotGoingColor` |

- Style: Segmented button or chip group
- Selected state: Filled with respective color
- Unselected: Outlined with `outlineVariant`
- Height: 40px
- Animation: Cross-fade color transition 200ms

---

### CMP-010: AttendeeListTile

**Location:** `features/events/presentation/widgets/attendee_list_tile.dart`

| Property | Specification |
|----------|--------------|
| Leading | Avatar (SM 32px) |
| Title | Member name (`titleSmall`) |
| Trailing | RSVP status chip or attendance status chip |
| Height | 56px minimum |
| Tap | Navigate to `/profile/:id` |

---

### CMP-011: EventUpdateTile

**Location:** `features/events/presentation/widgets/event_update_tile.dart`

Timeline-style entry for organizer updates on an event.

| Property | Specification |
|----------|--------------|
| Leading | Timeline dot (8px, `primary`) |
| Content | Update text (`bodyMedium`) + timestamp (`bodySmall`) |
| Author | Creator name + avatar (XS) |

---

## 5. Poll Cards

### CMP-012: PollCard

**Location:** `features/events/presentation/widgets/poll_card.dart`

| Property | Specification |
|----------|--------------|
| Background | `surfaceContainer` |
| Border radius | 12px |
| Leading icon | `poll` icon (24px) |

**Structure:**
```
┌───────────────────────────────────────┐
│ 📊 Poll Question Text                │
│ [Option A ████████ 45%]              │
│ [Option B ████ 25%]                  │
│ [Option C ██████ 30%]                │
│ 20 votes · Closes Jun 28             │
└───────────────────────────────────────┘
```

Tap → navigate to Poll Detail Screen.

---

### CMP-013: PollOptionTile

**Location:** `features/events/presentation/widgets/poll_option_tile.dart`

| Property | Specification |
|----------|--------------|
| Height | 48px |
| Progress bar | Animated width (300ms), `primaryContainer` fill |
| Percentage | `labelLarge`, right-aligned |
| Own vote | Left border 3px `primary`, bold text |
| Tappable | Only when poll is open and user has not voted |

---

## 6. Challenge Cards

### CMP-014: ChallengeCard

**Location:** `features/growth/presentation/widgets/challenge_card.dart`

| Property | Specification |
|----------|--------------|
| Background | `surfaceContainer` |
| Border radius | 12px |

**Structure:**
```
┌──────────────────────────────────────────┐
│ [Type Badge: Fitness] [Status: Active]   │
│                                          │
│ Challenge Title (titleMedium, SemiBold)  │
│ 🎯 Goal: 10,000 steps/day              │
│ 📅 Jun 10 — Jul 10, 2026               │
│                                          │
│ 👥 12 participants   🏆 You: Rank #3    │
└──────────────────────────────────────────┘
```

**Interactions:** Tap → navigate to `/challenge/:id`

---

### CMP-015: ChallengeTypeFilter

**Location:** `features/growth/presentation/widgets/challenge_type_filter.dart`

Horizontal chip row: Fitness / Wellness filter options.

---

### CMP-016: GoalTypeSelector

**Location:** `features/growth/presentation/widgets/goal_type_selector.dart`

Selection chips shown during challenge creation:

| Challenge Type | Goal Type Options |
|---------------|-------------------|
| Fitness | Steps, Distance, Duration |
| Wellness | Custom (shows free-text goal description field) |

---

### CMP-017: LeaderboardList

**Location:** `features/growth/presentation/widgets/leaderboard_list.dart`

Container for `LeaderboardEntryTile` items. Shows rank, avatar, name, and cumulative progress value.

---

### CMP-018: LeaderboardEntryTile

**Location:** `features/growth/presentation/widgets/leaderboard_entry_tile.dart`

| Property | Specification |
|----------|--------------|
| Leading | Rank number (`headlineSmall` for top 3; `titleMedium` for others) |
| Avatar | SM (32px) |
| Name | `titleSmall` |
| Value | Progress total (`titleSmall`, `primary` color) |
| Unit | Goal type unit suffix (steps, km, min, or custom) |
| Background | Top 3: `primaryContainer` tint; own rank: subtle border highlight |
| Height | 56px |
| Tap | Navigate to `/profile/:id` |

---

## 7. Analytics Cards

### CMP-019: HealthScoreCard

**Location:** `features/analytics/presentation/widgets/health_score_card.dart`

| Property | Specification |
|----------|--------------|
| Background | `surfaceContainerLow` |
| Border radius | 12px |
| Left border | 3px, color-coded by score threshold |
| Score value | `headlineLarge`, color-coded |
| Label | "Community Health Score" (`titleSmall`) |
| Sub-metrics | 4 rows showing breakdown (participation, attendance, challenges, recognition) |

**Color coding:**
- Score >= 70: `healthScoreHigh` (green)
- Score 40–69: `healthScoreMedium` (amber)
- Score < 40: `healthScoreLow` (red)

---

### CMP-020: HealthScoreBreakdown

**Location:** `features/analytics/presentation/widgets/health_score_breakdown.dart`

Sub-metrics displayed below the health score:

| Metric | Label |
|--------|-------|
| `participation_rate` | Participation Rate |
| `avg_attendance_rate` | Avg Attendance Rate |
| `challenge_engagement_rate` | Challenge Engagement |
| `recognition_activity_rate` | Recognition Activity |

Each metric: Label (`bodySmall`) + percentage value (`labelLarge`) + mini progress bar.

---

### CMP-021: PersonalStatCard

**Location:** `features/analytics/presentation/widgets/personal_stat_card.dart`

Compact single-metric card:

| Property | Specification |
|----------|--------------|
| Background | `surfaceContainerLow` |
| Border radius | 12px |
| Icon | 24px, `primary` |
| Label | `labelMedium`, `onSurfaceVariant` |
| Value | `headlineSmall` |
| Layout | Icon top → Value → Label bottom (vertical) |
| Size | Flexible width, arranged in 2-column grid |

**Used for:** Events Attended, Attendance Rate, Challenges Joined, Progress Logs, Recognitions Received, Recognitions Given, Posts Count.

---

### CMP-022: RankingEntryTile

**Location:** `features/analytics/presentation/widgets/ranking_entry_tile.dart`

| Property | Specification |
|----------|--------------|
| Rank number | `headlineSmall` (top 3: `primary` color with medal emoji); `titleMedium` (others) |
| Avatar | SM (32px) |
| Name | `titleSmall` |
| Score | `titleSmall`, `primary` |
| Background | Top 3: `primaryContainer` tint; own rank: subtle `primary` border |
| Height | 60px |
| Tap | Navigate to `/profile/:id` |

---

## 8. Recognition Cards

### CMP-023: RecognitionCard

**Location:** `features/analytics/presentation/widgets/recognition_card.dart`

| Property | Specification |
|----------|--------------|
| Background | `surfaceContainer` |
| Border radius | 12px |

**Structure:**
```
┌──────────────────────────────────────────────┐
│ [Avatar MD] [Giver Name] recognized          │
│ [Recipient Chip] [Recipient Chip]            │
│                                              │
│ [Category Tag Badge: Fitness Champion]       │
│                                              │
│ "Great job leading the steps challenge..."   │
│                                              │
│ [😀 2] [❤️ 5] [👏 3]       2 hours ago      │
└──────────────────────────────────────────────┘
```

**Interactions:** Tap → navigate to `/recognition/:id`

---

### CMP-024: CategoryTagBadge

**Location:** `features/analytics/presentation/widgets/category_tag_badge.dart`

| Category Tag | Display Label | Color |
|-------------|---------------|-------|
| `community_contributor` | Community Contributor | `primaryContainer` |
| `fitness_champion` | Fitness Champion | `successColor` tint |
| `wellness_champion` | Wellness Champion | `tertiaryContainer` |
| `event_champion` | Event Champion | `secondaryContainer` |
| `most_supportive_manager` | Most Supportive Manager | `warningColor` tint |

- Border radius: 8px
- Text: `labelMedium`
- Height: 24px
- Padding: 8px horizontal, 4px vertical

---

### CMP-025: RecipientChipList

**Location:** `features/analytics/presentation/widgets/recipient_chip_list.dart`

Horizontal wrap layout of recipient chips:
- Each chip: Avatar (XS 24px) + Name (`labelMedium`)
- Border radius: full (pill)
- Background: `surfaceContainerHigh`
- Tap chip → navigate to `/profile/:id`

---

### CMP-026: RecognitionReactionBar

**Location:** `features/analytics/presentation/widgets/recognition_reaction_bar.dart`

Same interaction pattern as post reaction bar (CMP-031) but for recognitions.

---

## 9. Comment Components

### CMP-027: CommentsSheet

**Location:** `features/feed/presentation/widgets/comments_sheet.dart`

Bottom sheet containing comment list + input field:

| Property | Specification |
|----------|--------------|
| Style | `DraggableScrollableSheet` |
| Initial height | 60% |
| Max height | 90% |
| Content | Comment list (chronological) + input field pinned at bottom |

---

### CMP-028: CommentTile

**Location:** `features/feed/presentation/widgets/comment_tile.dart`

| Property | Specification |
|----------|--------------|
| Leading | Avatar (SM 32px) |
| Author | Name (`titleSmall`, SemiBold) |
| Content | Comment text (`bodyMedium`) |
| Timestamp | `bodySmall`, `onSurfaceVariant` |
| Actions | Delete (own comments + admin), long-press menu |
| Min height | 56px |

---

## 10. Notification Components

### CMP-029: NotificationTile

**Location:** `features/notifications/presentation/widgets/notification_tile.dart`

| Property | Specification |
|----------|--------------|
| Leading | Type icon (24px) color-coded by notification category |
| Title | `titleSmall` (bold if unread) |
| Body | `bodySmall`, `onSurfaceVariant` |
| Timestamp | `bodySmall`, right-aligned, relative format |
| Unread indicator | Left accent bar (3px, `primary`) or bold text |
| Height | 72px |
| Tap | Mark as read + navigate to `targetScreen` |

**Icon by type:**

| Notification Category | Icon | Color |
|----------------------|------|-------|
| Event notifications | `event` | `primary` |
| Poll notifications | `poll` | `secondary` |
| Recognition | `star` | `warningColor` |
| Challenge notifications | `trending_up` | `successColor` |
| Social (mention, comment) | `alternate_email` / `comment` | `tertiary` |
| Connect Buddy | `smart_toy` | `connectBuddyBadgeColor` |
| Admin notifications | `admin_panel_settings` | `dangerColor` |

---

### CMP-030: NotificationMarkAllButton

**Location:** `features/notifications/presentation/widgets/notification_mark_all_button.dart`

| Property | Specification |
|----------|--------------|
| Type | `TextButton` in AppBar actions |
| Label | "Mark all as read" (`labelLarge`, `primary`) |
| Visibility | Only shown when unread count > 0 |
| Loading | Replace text with small spinner (16px) during operation |

---

## 11. Reaction Components

### CMP-031: ReactionBar

**Location:** `features/feed/presentation/widgets/reaction_bar.dart`

Horizontal row of emoji reaction chips:

| Property | Specification |
|----------|--------------|
| Layout | Horizontal scroll, wrap if needed |
| Chip height | 28px |
| Chip padding | 6px horizontal |
| Emoji size | 16px |
| Count | `labelSmall` |
| Own reaction | Highlighted border (`primary`), filled background |
| Add reaction | "+" button at end of row |
| Animation | Scale bounce on tap (1.0 → 1.3 → 1.0, 200ms) |

**Supported emojis (V1):** 👍 ❤️ 😀 😂 😮 👏 🔥 💯

---

### CMP-032: MentionInputField

**Location:** `features/feed/presentation/widgets/mention_input_field.dart`

Text field with `@` mention autocomplete:

| Property | Specification |
|----------|--------------|
| Trigger | `@` character typed |
| Overlay | Dropdown below cursor, max 200px height, scrollable |
| Item layout | Avatar (XS 24px) + Name (`bodyMedium`) |
| Filter | Real-time text filter on member names |
| Excludes | System accounts (Connect Buddy) |
| On select | Insert `@{fullName}` visible text; store UUID internally |
| Dismiss | Tap outside, backspace over `@`, Escape |

---

## 12. Dialogs

### CMP-033: ConfirmDialog

**Location:** `shared/widgets/dialogs/confirm_dialog.dart`

| Property | Specification |
|----------|--------------|
| Border radius | 12px |
| Background | `surfaceContainerHigh` |
| Title | `headlineSmall` |
| Content | `bodyMedium` |
| Actions | 2 buttons: Secondary (Cancel) + Primary/Destructive (Confirm) |
| Destructive variant | Confirm button uses `dangerColor` fill |
| Dismiss | Tap cancel button; not dismissible by tap outside for destructive |

---

### CMP-034: ErrorDialog

**Location:** `shared/widgets/dialogs/error_dialog.dart`

| Property | Specification |
|----------|--------------|
| Icon | Error icon (48px, `error` color) |
| Title | "Something went wrong" (`headlineSmall`) |
| Message | Error description (`bodyMedium`) |
| Actions | "OK" button (primary) + optional "Retry" |

---

## 13. Bottom Sheets

### CMP-035: McBottomSheet

**Location:** `shared/widgets/sheets/mc_bottom_sheet.dart`

Base bottom sheet wrapper used by all creation flows:

| Property | Specification |
|----------|--------------|
| Corner radius | 24px (top-left, top-right) |
| Drag handle | 32px wide, 4px tall, centered, `outlineVariant` |
| Background | `surfaceContainerLow` |
| Initial height | 70% (adjustable per sheet) |
| Max height | 90% |
| Min height | 50% (snap point) |
| Title | `titleLarge` (22sp, SemiBold), below drag handle |
| Dismiss | Drag below min height, back gesture, tap outside |
| Padding | 24px top (below handle), 16px horizontal, 16px bottom |

---

### CMP-036: CreatePostSheet

**Location:** `features/feed/presentation/widgets/create_post_sheet.dart`

| Content | Component |
|---------|-----------|
| Text input | Multi-line (large, 1000 char, counter from 800) |
| Mention | `MentionInputField` (CMP-032) integrated |
| Photo | Image picker (up to 4), thumbnail grid with remove (X) |
| Submit | Primary button "Post" (disabled until content entered) |

---

### CMP-037: CreateEventSheet

**Location:** `features/events/presentation/widgets/create_event_sheet.dart`

| Content | Component |
|---------|-----------|
| Category | `EventCategoryChip` selector (CMP-007) — Games / Outings / Social Connect |
| Type | `EventTypeSelector` (CMP-008) — shown for Games and Social Connect |
| Title | Text field (100 char) |
| Description | Multi-line (small, optional) |
| Date/Time | Date picker + Time picker |
| Location | Text field (optional) |
| Cost Note | Text field (optional) |
| Submit | Primary button "Create Event" |

---

### CMP-038: CreateChallengeSheet

**Location:** `features/growth/presentation/widgets/create_challenge_sheet.dart`

| Content | Component |
|---------|-----------|
| Challenge type | Fitness / Wellness chip selector |
| Goal type | `GoalTypeSelector` (CMP-016) |
| Goal description | Text field (shown for Custom goal type only) |
| Title | Text field (100 char) |
| Description | Multi-line (small, optional) |
| Start date | Date picker |
| End date | Date picker (must be after start date) |
| Submit | Primary button "Create Challenge" |

---

### CMP-039: CreatePollSheet

**Location:** `features/events/presentation/widgets/create_poll_sheet.dart`

| Content | Component |
|---------|-----------|
| Question | Text field (200 char) |
| Options | Dynamic list (2–6 options, each 100 char, + "Add Option" button) |
| Closes at | DateTime picker (must be in future) |
| Submit | Primary button "Create Poll" |

---

### CMP-040: GiveRecognitionSheet

**Location:** `features/analytics/presentation/widgets/give_recognition_sheet.dart`

| Content | Component |
|---------|-----------|
| Recipient search | Text field with member autocomplete (excludes system accounts + self) |
| Category | `CategoryTagBadge` selector (5 categories) |
| Message | Multi-line (small, 500 char, counter from 400) |
| Submit | Primary button "Give Recognition" |

---

### CMP-041: LogProgressSheet

**Location:** `features/growth/presentation/widgets/progress_log_sheet.dart`

| Content | Component |
|---------|-----------|
| Date | Pre-filled with today (editable within challenge period) |
| Value | Number input (numeric keyboard), label shows unit (steps/km/min/custom) |
| Note | Text field (optional) |
| Submit | Primary button "Log Progress" |

---

### CMP-042: InviteMemberSheet

**Location:** `features/admin/presentation/widgets/invite_member_sheet.dart`

| Content | Component |
|---------|-----------|
| Name | Text field (required) |
| Email | Text field (optional — at least one of email/phone required) |
| Phone | Text field (optional — at least one of email/phone required) |
| Submit | Primary button "Send Invitation" |
| On success | Show invite URL in copy-to-clipboard dialog |

---

### CMP-043: AttendanceRecordingSheet

**Location:** `features/admin/presentation/widgets/attendance_recording_sheet.dart`

| Content | Component |
|---------|-----------|
| Event header | Event title + date (read-only) |
| Member list | All "Going" RSVPs for the event |
| Per member | Avatar (SM) + Name + Attended/Absent toggle |
| Toggle style | Two-option segmented button (green "Attended" / red "Absent") |
| Submit | Primary button "Submit Attendance" |

---

### CMP-044: ConnectBuddyTriggerSheet

**Location:** `features/admin/presentation/widgets/connect_buddy_trigger_sheet.dart`

| Content | Component |
|---------|-----------|
| Post type selector | Welcome (requires member picker), Monthly Highlights, Memory |
| Member picker | Shown for Welcome type — autocomplete from active members |
| Submit | Primary button "Trigger Post" |

---

## 14. Empty States

### CMP-045: EmptyStateWidget

**Location:** `shared/widgets/empty_states/empty_state_widget.dart`

| Property | Specification |
|----------|--------------|
| Icon | 64px, `onSurfaceVariant` (configurable) |
| Title | `titleMedium` (configurable text) |
| Subtitle | `bodyMedium`, `onSurfaceVariant` (configurable text) |
| Action | Optional primary button (e.g., "Create your first post") |
| Layout | Centered vertically with `huge` (48px) offset from center |

**Per-screen empty state messages:**

| Screen | Icon | Title | Subtitle |
|--------|------|-------|----------|
| Feed | `feed` | "No posts yet" | "Be the first to share something with the community" |
| Events (all) | `event` | "No upcoming events" | "Create an event to get the community together" |
| Events (Games) | `sports_cricket` | "No games scheduled" | "Create a game event to start playing" |
| Events (Outings) | `hiking` | "No outings planned" | "Plan an outing for the team" |
| Events (Social Connect) | `coffee` | "No meetups yet" | "Set up a coffee connect or lunch meetup" |
| Growth (Active) | `trending_up` | "No active challenges" | "Start a challenge to get the community moving" |
| Growth (My Challenges) | `emoji_events` | "You haven't joined any challenges" | "Browse active challenges and join one" |
| Growth (Completed) | `check_circle` | "No completed challenges" | "Challenges will appear here once they end" |
| Recognition (Monthly) | `star` | "No recognitions this month" | "Recognize a colleague for their contributions" |
| Recognition (Community) | `star` | "No recognitions yet" | "Be the first to give a shout-out" |
| Notifications | `notifications_none` | "No notifications" | "You're all caught up!" |
| Admin Flagged | `verified` | "All clear" | "No flagged content to review" |
| Admin Attendance | `check_circle` | "All caught up" | "Attendance has been recorded for all past events" |

---

## 15. Error States

### CMP-046: ErrorStateWidget

**Location:** `shared/widgets/error_states/error_state_widget.dart`

| Property | Specification |
|----------|--------------|
| Icon | 48px, `error` color |
| Title | "Something went wrong" (`titleMedium`) |
| Message | Error description (`bodyMedium`, `onSurfaceVariant`) |
| Retry button | Secondary button "Try Again" |
| Layout | Centered vertically |

Used in all `AsyncValue.when(error: ...)` handlers.

---

## 16. Loading Skeletons

### CMP-047: SkeletonLoader

**Location:** `shared/widgets/loaders/skeleton_loader.dart`

Base shimmer widget:

| Property | Specification |
|----------|--------------|
| Animation | Shimmer sweep (left to right), 1500ms per cycle, infinite |
| Base color | `surfaceContainerHigh` |
| Highlight color | `surfaceContainerLowest` |
| Border radius | Matches target component |

---

### CMP-048: FeedSkeleton

**Location:** `shared/widgets/loaders/feed_skeleton.dart`

3 placeholder post cards:
- Circular shimmer (40px) for avatar
- Rectangular shimmer (120px × 16px) for name
- Rectangular shimmer (full width × 12px) × 3 lines for content
- Rectangular shimmer (full width × 160px) for image area
- Rectangular shimmer row for reaction bar

---

### CMP-049: EventsSkeleton

**Location:** `shared/widgets/loaders/events_skeleton.dart`

3 placeholder event cards:
- Chip shimmer (60px × 24px) for category
- Rectangular shimmer (200px × 16px) for title
- Rectangular shimmer (150px × 12px) for date
- Rectangular shimmer (180px × 12px) for location

---

### CMP-050: AnalyticsSkeleton

**Location:** `shared/widgets/loaders/analytics_skeleton.dart`

- Large card shimmer for health score
- 2×2 grid of small card shimmer for stat cards
- List shimmer (3 rows) for rankings

---

## 17. Shared Utility Widgets

### CMP-051: McAvatar

**Location:** `shared/widgets/image/mc_avatar.dart`

Reusable avatar component (see design-system.md Section 7 for full specification):
- Sizes: XS (24), SM (32), MD (40), LG (56), XL (80), XXL (120)
- Variants: Standard (image + initials fallback), Connect Buddy (with badge)
- Fallback: Initials on colored background derived from user ID hash

---

### CMP-052: McCachedImage

**Location:** `shared/widgets/image/mc_cached_image.dart`

Cached image loading with states:
- Loading: Shimmer placeholder (matches target dimensions)
- Loaded: Image with `BoxFit.cover`
- Error: Grey placeholder with image icon
- Border radius: Configurable (default 12px for post images)

---

## Component Count Summary

| Category | Count |
|----------|-------|
| App Bars | 1 |
| Bottom Navigation | 1 |
| Feed Cards | 3 |
| Event Cards/Widgets | 6 |
| Poll Cards/Widgets | 2 |
| Challenge Cards/Widgets | 5 |
| Analytics Cards/Widgets | 4 |
| Recognition Cards/Widgets | 4 |
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
