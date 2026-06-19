# Design System — Manager Connect

## Overview

This document defines the complete visual design language for Manager Connect. Every screen, component, and interaction in the application derives its visual properties from this system. The design system is built on Material 3 with a single seed color, targeting light mode only in V1.

**Font:** Inter (Regular 400, Medium 500, SemiBold 600, Bold 700)
**Framework:** Material 3 (`useMaterial3: true`)
**Theme Mode:** Light only — no dark mode in V1
**Seed Color:** Teal `#006B5F`

---

## 1. Color System

### 1.1 Brand Seed Color

All Material 3 tonal palettes are generated from one seed color:

```
Brand Seed: #006B5F (Teal)
```

`ColorScheme.fromSeed(seedColor: Color(0xFF006B5F), brightness: Brightness.light)` produces the full tonal palette including primary, secondary, tertiary, surface, background, error, and all on-* variants.

### 1.2 Generated Color Roles (Material 3)

| Role | Usage |
|------|-------|
| `primary` | FABs, filled buttons, active navigation indicator, links |
| `onPrimary` | Text/icons on primary surfaces |
| `primaryContainer` | Selected chips, active tab indicator fill |
| `onPrimaryContainer` | Text on primary container |
| `secondary` | Secondary buttons, less prominent UI accents |
| `onSecondary` | Text/icons on secondary surfaces |
| `secondaryContainer` | Secondary chip fills, toggled states |
| `onSecondaryContainer` | Text on secondary container |
| `tertiary` | Accent elements, badges, decorative highlights |
| `surface` | Card backgrounds, bottom sheets, dialogs |
| `onSurface` | Primary body text, icons |
| `onSurfaceVariant` | Secondary text, captions, placeholders |
| `surfaceContainerLowest` | App background (scaffold) |
| `surfaceContainerLow` | Slightly elevated surface |
| `surfaceContainer` | Card surface |
| `surfaceContainerHigh` | Elevated cards, bottom nav |
| `outline` | Borders, dividers |
| `outlineVariant` | Subtle dividers, input field borders |
| `error` | Error text, destructive icon tint |
| `onError` | Text on error surfaces |
| `errorContainer` | Error banners, error card backgrounds |

### 1.3 Semantic Colors (AppThemeExtension)

These colors are not part of Material 3's role system. They are defined in `AppThemeExtension` and accessed via `Theme.of(context).extension<AppThemeExtension>()!`.

| Token | Hex Value | Usage |
|-------|-----------|-------|
| `successColor` | `#2E7D32` | Success snackbars, confirmation icons |
| `warningColor` | `#F57F17` | Warning banners, caution indicators |
| `dangerColor` | `#C62828` | Destructive actions, critical alerts |
| `rsvpGoingColor` | `#2E7D32` (green) | RSVP "Going" status chip and badge |
| `rsvpMaybeColor` | `#F57F17` (amber) | RSVP "Maybe" status chip |
| `rsvpNotGoingColor` | `#C62828` (red) | RSVP "Not Going" status chip |
| `attendedColor` | `#2E7D32` (green) | Attendance "Attended" indicator |
| `absentColor` | `#C62828` (red) | Attendance "Absent" indicator |
| `connectBuddyBadgeColor` | `#7C4DFF` (deep purple) | Connect Buddy avatar badge overlay |
| `connectBuddyPostBackground` | `#F3E5F5` (light purple tint) | Connect Buddy post card background |
| `pinnedPostBackground` | `#FFF8E1` (light amber tint) | Pinned announcement banner background |
| `healthScoreHigh` | `#2E7D32` (green) | Health score >= 70 |
| `healthScoreMedium` | `#F57F17` (amber) | Health score 40–69 |
| `healthScoreLow` | `#C62828` (red) | Health score < 40 |

### 1.4 Category Colors

Event categories and challenge types use colored chips for quick identification:

| Category | Color Approach |
|----------|---------------|
| Games | `primaryContainer` / `onPrimaryContainer` |
| Outings | `secondaryContainer` / `onSecondaryContainer` |
| Social Connect | `tertiaryContainer` / `onTertiaryContainer` |
| Fitness Challenge | `primaryContainer` |
| Wellness Challenge | `secondaryContainer` |

### 1.5 Recognition Category Colors

Each recognition category tag badge uses a distinct color pair from the tonal palette:

| Category Tag | Badge Color |
|-------------|-------------|
| Community Contributor | `primaryContainer` |
| Fitness Champion | `successColor` tint |
| Wellness Champion | `tertiaryContainer` |
| Event Champion | `secondaryContainer` |
| Most Supportive Manager | `warningColor` tint |

---

## 2. Typography Scale

Font family: **Inter** across all text styles.

### 2.1 Material 3 TextTheme Scale

| Style | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| `displayLarge` | 57sp | 400 | 64 | -0.25 | *Not used in V1 (reserved)* |
| `displayMedium` | 45sp | 400 | 52 | 0 | *Not used in V1 (reserved)* |
| `displaySmall` | 36sp | 400 | 44 | 0 | *Not used in V1 (reserved)* |
| `headlineLarge` | 32sp | 600 | 40 | 0 | Screen titles (rare — Analytics overview) |
| `headlineMedium` | 28sp | 600 | 36 | 0 | Section headers in detail screens |
| `headlineSmall` | 24sp | 600 | 32 | 0 | Card titles, dialog titles |
| `titleLarge` | 22sp | 600 | 28 | 0 | AppBar titles |
| `titleMedium` | 16sp | 500 | 24 | 0.15 | List tile titles, tab labels |
| `titleSmall` | 14sp | 500 | 20 | 0.1 | Sub-section headers |
| `bodyLarge` | 16sp | 400 | 24 | 0.5 | Post content, event descriptions |
| `bodyMedium` | 14sp | 400 | 20 | 0.25 | Comment text, default body text |
| `bodySmall` | 12sp | 400 | 16 | 0.4 | Captions, timestamps, metadata |
| `labelLarge` | 14sp | 500 | 20 | 0.1 | Button labels, chip labels |
| `labelMedium` | 12sp | 500 | 16 | 0.5 | Badge text, small chip labels |
| `labelSmall` | 11sp | 500 | 16 | 0.5 | Overline text, tiny labels |

### 2.2 Typography Usage Rules

- **Post content:** `bodyLarge` — must be comfortable for reading in a scrollable feed
- **Usernames in feed cards:** `titleSmall` with `fontWeight: 600`
- **Timestamps:** `bodySmall` with `onSurfaceVariant` color
- **Health score value:** `headlineLarge` with color-coded by threshold
- **Leaderboard rank number:** `headlineSmall` with `primary` color
- **Tab bar labels:** `labelLarge`
- **Empty state title:** `titleMedium`
- **Empty state subtitle:** `bodyMedium` with `onSurfaceVariant`
- **Error state message:** `bodyMedium` with `error` color
- **Notification title:** `titleSmall`
- **Notification body:** `bodySmall`

### 2.3 Font Scaling Support

- All text uses `sp` (scaled pixels) — respects system font size settings
- Minimum readable size: 11sp (`labelSmall`)
- Maximum text scale factor: 1.5x (clamped via `MediaQuery` in `app.dart`)
- Long text (post content, bio) wraps naturally; no truncation on scaling

---

## 3. Spacing System

An 4px base unit grid. All spacing values are multiples of 4.

### 3.1 Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Inline icon-to-text gap, tight chip padding |
| `sm` | 8px | Inner card padding (compact), chip gap, icon button padding |
| `md` | 12px | Default card content padding, list tile content spacing |
| `lg` | 16px | Screen edge horizontal padding, card outer margin, section gap |
| `xl` | 20px | Between-section spacing within a screen |
| `xxl` | 24px | Major section separators, bottom sheet top padding |
| `xxxl` | 32px | Screen top padding (below AppBar), large section breaks |
| `huge` | 48px | Empty state vertical centering offset |

### 3.2 Screen-Level Layout

| Property | Value |
|----------|-------|
| Screen horizontal padding | 16px (left + right) |
| Content max width | None (full width — mobile only) |
| AppBar height | 56px (Material 3 default) |
| Bottom navigation bar height | 80px (Material 3 default) |
| FAB bottom offset | 16px above bottom nav |
| Pull-to-refresh trigger distance | 80px |

### 3.3 Card Layout

| Property | Value |
|----------|-------|
| Card outer margin (horizontal) | 16px |
| Card outer margin (vertical) | 8px between cards |
| Card inner padding | 12px (all sides) |
| Card content gap (between elements) | 8px |
| Card header-to-body gap | 8px |
| Card body-to-footer gap | 12px |

---

## 4. Border Radius System

Consistent corner rounding across all components.

| Token | Value | Applied To |
|-------|-------|-----------|
| `none` | 0px | Dividers, flat edges |
| `sm` | 8px | Chips, small badges, status indicators |
| `md` | 12px | Cards, input fields, buttons, dialogs |
| `lg` | 16px | Image containers, expanded cards |
| `xl` | 24px | Bottom sheets (top corners), FABs |
| `full` | 999px (circular) | Avatars, circular badges, pill chips |

### Applied Defaults

| Component | Border Radius |
|-----------|---------------|
| `CardTheme` | 12px |
| `InputDecorationTheme` (outlined) | 12px |
| `FilledButton` | 12px |
| `OutlinedButton` | 12px |
| `BottomSheetTheme` (top corners) | 24px |
| `DialogTheme` | 12px |
| `ChipTheme` | 8px |
| `FloatingActionButton` | 16px (large) |
| `NavigationBar indicator` | 16px |
| Avatar (all sizes) | Circular (full) |
| Image in post card | 12px |
| Skeleton shimmer | Matches target component |

---

## 5. Elevation System

Material 3 uses tonal elevation (surface tint) rather than drop shadows for most surfaces. Only legacy-style elevation is used sparingly.

| Level | Elevation | Tonal Shift | Usage |
|-------|-----------|-------------|-------|
| Level 0 | 0dp | None | Scaffold background, flat surfaces |
| Level 1 | 1dp | Slight | Cards (resting state) |
| Level 2 | 3dp | Moderate | Hovered/focused cards, bottom navigation bar |
| Level 3 | 6dp | Noticeable | FABs, AppBar (scrolled state) |
| Level 4 | 8dp | Strong | Dialogs, bottom sheets |
| Level 5 | 12dp | Maximum | *Not used in V1* |

### Elevation Assignments

| Component | Elevation |
|-----------|-----------|
| Standard cards (feed, event, challenge, recognition) | Level 1 (1dp) |
| Pinned announcement banner | Level 1 (1dp) |
| Connect Buddy post card | Level 1 (1dp) |
| Bottom navigation bar | Level 2 (3dp) |
| AppBar (resting) | 0dp |
| AppBar (scrolled — `scrolledUnderElevation`) | Level 3 (6dp) |
| FAB | Level 3 (6dp) |
| Bottom sheets | Level 4 (8dp) |
| Dialogs | Level 4 (8dp) |
| Snackbar | Level 3 (6dp) |

---

## 6. Iconography Guidelines

### 6.1 Icon System

- **Primary icon set:** Material Symbols Outlined (ships with Flutter `Icons` class)
- **Icon weight:** 400 (default outlined)
- **Fill:** 0 (outlined) for navigation; 1 (filled) for active/selected state
- **Custom icons:** Connect Buddy avatar badge only — all other icons use Material Symbols

### 6.2 Icon Sizes

| Size | Value | Usage |
|------|-------|-------|
| Tiny | 16px | Inline metadata icons (clock, location pin in compact rows) |
| Small | 20px | List tile trailing icons, chip leading icons |
| Default | 24px | AppBar action icons, navigation bar icons, card action icons |
| Large | 32px | Empty state icons (secondary), section header icons |
| XLarge | 48px | Empty state primary illustrations, onboarding icons |
| Huge | 64px | Full-page empty state illustrations |

### 6.3 Navigation Bar Icons

| Tab | Outlined (Inactive) | Filled (Active) |
|-----|---------------------|-----------------|
| Feed | `Icons.feed_outlined` | `Icons.feed` |
| Events | `Icons.event_outlined` | `Icons.event` |
| Growth | `Icons.trending_up_outlined` | `Icons.trending_up` |
| Analytics | `Icons.analytics_outlined` | `Icons.analytics` |
| Profile | `Icons.person_outlined` | `Icons.person` |

### 6.4 Icon Color Rules

- Active navigation icon: `primary`
- Inactive navigation icon: `onSurfaceVariant`
- Card action icons: `onSurfaceVariant`
- Error icons: `error`
- Success icons: `successColor`
- Destructive action icons: `dangerColor`

---

## 7. Avatar System

### 7.1 Avatar Sizes

| Size | Diameter | Usage |
|------|----------|-------|
| XS | 24px | Inline mention chips, compact lists |
| SM | 32px | Comment author, notification tile, leaderboard row |
| MD | 40px | Feed post card author, event card creator, recognition giver |
| LG | 56px | Member profile tile (admin list), attendee list |
| XL | 80px | Profile screen header, member detail view |
| XXL | 120px | Own profile screen, edit profile screen |

### 7.2 Avatar Variants

**Standard Avatar (`McAvatar`)**
- Circular clip with `cached_network_image`
- Fallback: Colored circle with initials (first letter of first and last name)
- Fallback color: Derived from user ID hash mapped to Material tonal palette
- Border: None by default; 2px `outline` border on profile screens

**Connect Buddy Avatar**
- Same circular image but uses the static `connect_buddy_avatar.png` asset
- Badge overlay: Small circular badge at bottom-right with `connectBuddyBadgeColor` (#7C4DFF)
- Badge contains a sparkle/bot icon (16px)

**System Badge on Avatar**
- Position: Bottom-right corner, overlapping the avatar circle by 25%
- Badge size: 18px diameter
- Badge background: `connectBuddyBadgeColor`
- Badge icon: Bot/sparkle icon, 12px, white

### 7.3 Avatar Fallback Behavior

1. Image URL present → Load via `CachedNetworkImage` with shimmer placeholder
2. Image loading → Show shimmer circle (same size as avatar)
3. Image load error → Show initials fallback
4. No image URL → Show initials fallback immediately
5. No name (edge case) → Show generic person icon on colored background

---

## 8. Badge System

### 8.1 Notification Badge

- Shape: Circular
- Size: 6px (dot-only, no count) on navigation bar tabs
- Background: `error` color (red)
- Position: Top-right of the icon, offset by (-2, -2)
- Used on: Events tab (upcoming event indicator), Profile tab (unread notifications)

### 8.2 Count Badge

- Shape: Rounded rectangle (pill) when count > 9; circular when count <= 9
- Min width: 16px
- Height: 16px
- Text: `labelSmall`, white on `error` background
- Max display: "99+" for counts exceeding 99
- Used on: Growth tab (active challenge count), notification inbox unread count

### 8.3 Status Badge

- Shape: Small chip (rounded rectangle, 8px radius)
- Height: 20px
- Padding: 4px horizontal, 2px vertical
- Text: `labelSmall`
- Variants:

| Status | Background | Text Color |
|--------|-----------|------------|
| Active | `primaryContainer` | `onPrimaryContainer` |
| Ended | `surfaceContainerHigh` | `onSurfaceVariant` |
| Cancelled | `errorContainer` | `error` |
| Going | `rsvpGoingColor` tint | `rsvpGoingColor` |
| Maybe | `rsvpMaybeColor` tint | `rsvpMaybeColor` |
| Not Going | `rsvpNotGoingColor` tint | `rsvpNotGoingColor` |
| Attended | `attendedColor` tint | `attendedColor` |
| Absent | `absentColor` tint | `absentColor` |
| Pending (invitation) | `warningColor` tint | `warningColor` |

---

## 9. Card System

### 9.1 Base Card Properties

All cards inherit from `CardTheme`:
- Background: `surfaceContainer`
- Border radius: 12px
- Elevation: 1dp (tonal)
- Clip behavior: `Clip.antiAlias`
- Outer margin: 16px horizontal, 8px vertical
- Inner padding: 12px all sides

### 9.2 Card Variants

**Standard Content Card**
- Used for: Feed posts, event cards, challenge cards, recognition cards
- Structure: Header (avatar + name + timestamp) → Body (content) → Footer (actions)
- Tap target: Entire card is tappable (navigates to detail)

**Connect Buddy Card**
- Inherits standard card structure
- Background override: `connectBuddyPostBackground` (#F3E5F5)
- Avatar: Connect Buddy avatar with badge overlay
- Header includes "Connect Buddy" label with system badge

**Pinned Announcement Card**
- Background override: `pinnedPostBackground` (#FFF8E1)
- Leading pin icon (16px, `primary` color)
- Positioned above the feed list, outside the scrollable area
- Elevation: Level 1

**Stat Card (Analytics)**
- Compact card with single metric
- Structure: Icon (24px) → Label (`labelMedium`) → Value (`headlineSmall`)
- Background: `surfaceContainerLow`
- Used in: Personal analytics, community analytics

**Health Score Card**
- Prominent card with large score value
- Score value: `headlineLarge`, color-coded by threshold
- Sub-metrics displayed as small stat rows below the score
- Border: 2px left border in score-threshold color

**Ranking Entry Card**
- Compact horizontal layout: Rank number → Avatar (SM) → Name → Score
- Top 3 ranks: Highlighted with `primaryContainer` background
- Current user's rank: Highlighted with subtle border

---

## 10. Button Hierarchy

### 10.1 Button Types

| Type | Widget | Usage | Appearance |
|------|--------|-------|------------|
| Primary | `FilledButton` | Main actions: Submit, Create, Post, Save | Filled `primary`, white text |
| Secondary | `OutlinedButton` | Alternative actions: Cancel, Back, Skip | `outline` border, `primary` text |
| Tertiary | `TextButton` | Inline actions: View All, See More, Learn More | No background, `primary` text |
| Icon | `IconButton` | Compact actions: React, Share, More menu | Icon only, `onSurfaceVariant` |
| FAB | `FloatingActionButton.extended` | Screen-level creation: New Post, New Event | `primaryContainer` fill |
| Destructive | `FilledButton` with `dangerColor` | Delete, Remove, Deactivate | Filled `dangerColor`, white text |

### 10.2 Button Sizes

| Size | Height | Padding (H) | Text Style | Usage |
|------|--------|-------------|------------|-------|
| Small | 32px | 12px | `labelMedium` | Inline card actions, compact rows |
| Default | 40px | 16px | `labelLarge` | Form submit, dialog actions |
| Large | 48px | 24px | `labelLarge` | Full-width CTA buttons on screens |

### 10.3 Button States

| State | Visual Change |
|-------|--------------|
| Default | Standard appearance |
| Hovered | Slight tonal shift (handled by Material 3) |
| Pressed | Ripple effect + slight scale (Material 3 default) |
| Focused | Focus ring (2px outline offset) |
| Disabled | 38% opacity, no interaction |
| Loading | Replace label with `CircularProgressIndicator` (16px, white for filled; primary for outlined) |

### 10.4 FAB Placement Rules

- Position: Bottom-right corner, 16px above bottom navigation bar
- Only one FAB per screen
- FAB is extended (icon + label) on creation screens
- FAB hides on scroll down, reappears on scroll up
- FAB screens:

| Screen | FAB Label | Icon |
|--------|-----------|------|
| Feed | "Post" | `Icons.edit` |
| Events | "Event" | `Icons.add` |
| Growth | "Challenge" | `Icons.add` |
| Recognition (within Analytics) | "Recognize" | `Icons.star` |

---

## 11. Form Guidelines

### 11.1 Input Fields

- Style: `OutlinedInputBorder` (all fields)
- Border radius: 12px
- Border color: `outlineVariant` (resting), `primary` (focused), `error` (error)
- Fill: `surfaceContainerLowest`
- Label: Floating label (Material 3 default)
- Helper text: `bodySmall`, `onSurfaceVariant`
- Error text: `bodySmall`, `error`
- Counter text: `bodySmall`, `onSurfaceVariant` (for character-limited fields)

### 11.2 Field Sizes

| Type | Height | Usage |
|------|--------|-------|
| Single line | 56px | Name, title, location, email |
| Multi-line (small) | 100px (3 lines) | Bio (300 char), comment |
| Multi-line (large) | 160px (5 lines) | Post content (1000 char), descriptions |

### 11.3 Character Limits

| Field | Max Length | Show Counter |
|-------|-----------|-------------|
| Post content | 1000 | Yes, from 800 |
| Bio | 300 | Yes, from 200 |
| Comment | 500 | Yes, from 400 |
| Recognition message | 500 | Yes, from 400 |
| Event title | 100 | No |
| Challenge title | 100 | No |
| Poll question | 200 | No |
| Poll option | 100 | No |
| Event update content | 500 | Yes, from 400 |

### 11.4 Validation Patterns

- Required fields: Red border + "Required" error text on submit attempt
- Character limit: Counter turns `error` color when exceeded; submit disabled
- Email format: Validated on blur with regex
- Phone format: Validated on blur
- Date/time: Must be in the future for events/polls; end date > start date for challenges
- Number inputs (progress log): Must be >= 0; numeric keyboard enforced

### 11.5 Special Input Components

**OTP Input (6-box)**
- 6 individual square inputs, 48x48px each
- Gap: 8px between boxes
- Auto-advance: Focus moves to next box on digit entry
- Paste: Full 6-digit paste fills all boxes
- Border: `outlineVariant` default, `primary` focused, `error` on invalid

**@Mention Input**
- Standard text field with `@` trigger
- On `@` keystroke: Show overlay dropdown with member list filtered by typed characters
- Overlay: Positioned below cursor, max height 200px, scrollable
- Each item: Avatar (XS) + name
- On select: Insert `@{fullName}` visible text; store UUID internally

**Interest Tag Selector**
- Chip grid (wrap layout)
- Chips: `FilterChip` with checkmark on selected
- Max selections: No limit
- Predefined tags from `InterestTags` constant list

---

## 12. Accessibility

### 12.1 Touch Targets

- **Minimum touch target:** 48x48dp for all interactive elements
- Small icon buttons (24px visual) are padded to 48px hit area
- Chip minimum height: 32px (with 48px hit area via padding)
- List tile minimum height: 56px

### 12.2 Font Scaling

- All text uses `sp` (respects system accessibility settings)
- App supports up to 1.5x system font scale
- Layout tested at 1.0x, 1.2x, and 1.5x scale factors
- No text truncation at 1.5x — layouts expand or wrap

### 12.3 Screen Reader Considerations

- All images include `semanticLabel` on `Image` widgets
- Avatars announce user name: "Profile photo of [Name]"
- Interactive elements have descriptive `tooltip` or `semanticsLabel`
- Feed cards announce: "[Author] posted [time ago]. [content preview]"
- RSVP buttons announce current selection state
- Health score announces: "Community health score: [value] out of 100"
- Leaderboard entries announce: "Rank [number], [name], score [value]"

### 12.4 Contrast Requirements

- All text meets WCAG AA contrast ratio (4.5:1 for normal text, 3:1 for large text)
- Material 3 `ColorScheme.fromSeed()` generates AA-compliant on-* colors by default
- Semantic colors (success, warning, danger) are selected for sufficient contrast on both white and tinted backgrounds
- Disabled text: 38% opacity of `onSurface` — meets minimum contrast on `surface`

### 12.5 Keyboard & Focus Accessibility

- Logical tab order follows visual layout (top-to-bottom, left-to-right)
- Focus indicators: 2px `primary` outline with 2px offset
- Bottom sheets dismissible via back gesture or swipe down
- Dialogs: Focus trapped within dialog while open; escape dismisses

---

## 13. Mobile Interaction Patterns

### 13.1 Pull to Refresh

- Available on: Feed, Events list, Growth challenges list, Recognition wall, Notification inbox
- Trigger distance: 80px pull
- Indicator: Material 3 `RefreshIndicator` with `primary` color
- Behavior: Refetches the current list from page 0; replaces stale data
- Disabled during: Active search/filter operations

### 13.2 Infinite Scroll / Pagination

- Page size: 20 items per page
- Trigger: Scroll within 200px of list bottom
- Indicator: `CircularProgressIndicator` centered below last item (24px)
- End-of-list: No indicator shown; list stops requesting
- Applied to: Feed posts, notification inbox, recognition community wall
- NOT paginated: Events (bounded set), challenges (bounded set), rankings (bounded set)

### 13.3 Image Upload Flow

1. Tap photo icon in create post/edit profile
2. Show `image_picker` source selection: Camera / Gallery
3. After selection: compress to ≤1MB, JPEG quality 80
4. Show thumbnail preview with remove (X) button
5. Upload happens on form submit, not on image selection
6. Progress: Linear progress indicator on the image thumbnail during upload
7. Post images: Up to 4 images; show "4/4" counter; hide add button at max
8. Avatar: Single image; replaces existing

### 13.4 Bottom Sheet Usage

- All creation flows: Create Post, Create Event, Create Challenge, Create Poll, Give Recognition, Log Progress, Invite Member, Record Attendance, Trigger CB Post
- Style: `DraggableScrollableSheet` with drag handle
- Initial height: 70% of screen (adjustable per sheet)
- Max height: 90% of screen
- Min height: 50% of screen (snap point)
- Dismiss: Drag below min height, tap outside, or back gesture
- Corner radius: 24px top-left and top-right
- Drag handle: Centered, 32px wide, 4px tall, `outlineVariant` color

### 13.5 Dialog Usage

- Confirmation dialogs only: Delete post, deactivate user, remove user, cancel event, revoke invitation
- Style: `AlertDialog` with 12px border radius
- Actions: Two buttons — Secondary (Cancel) + Primary or Destructive (Confirm)
- Destructive dialogs: Confirm button uses `dangerColor`
- Not dismissible by tap outside for destructive actions

### 13.6 Toast / Snackbar Usage

- Style: Floating `SnackBar` with 12px margin from edges
- Duration: 3 seconds (info), 5 seconds (error with retry)
- Success: `successColor` background, white text
- Error: `errorContainer` background, `error` text, optional "Retry" action
- Info: `surfaceContainerHigh` background, `onSurface` text
- Position: Bottom of screen, above bottom navigation bar
- Max lines: 2

### 13.7 Back Navigation Behavior

- Back button on detail screens → returns to previous screen in current tab stack
- Back gesture on bottom sheets → dismisses the sheet
- Back gesture on dialogs → dismisses the dialog (except destructive confirmations)
- Deep-linked screens → back returns to relevant tab root (not notification origin)
- Tab switching → preserves per-tab navigation stack state (StatefulShellRoute)
- Android back button on tab root → exits app (standard behavior)

---

## 14. Motion & Animation

### 14.1 Transitions

| Transition | Type | Duration | Curve |
|-----------|------|----------|-------|
| Screen push (stack) | Slide from right | 300ms | `Curves.easeInOut` |
| Screen pop | Slide to right | 250ms | `Curves.easeInOut` |
| Bottom sheet enter | Slide from bottom | 300ms | `Curves.easeOutCubic` |
| Bottom sheet exit | Slide to bottom | 200ms | `Curves.easeInCubic` |
| Dialog enter | Fade + scale from 0.9 | 200ms | `Curves.easeOut` |
| Dialog exit | Fade out | 150ms | `Curves.easeIn` |
| Tab switch | Cross-fade | 200ms | `Curves.linear` |
| FAB appear (scroll up) | Scale from 0 | 200ms | `Curves.easeOut` |
| FAB disappear (scroll down) | Scale to 0 | 150ms | `Curves.easeIn` |

### 14.2 Micro-Interactions

| Interaction | Animation |
|-------------|-----------|
| Emoji reaction tap | Scale bounce (1.0 → 1.3 → 1.0) 200ms |
| RSVP status change | Cross-fade color transition 200ms |
| Poll vote | Progress bar width animates to new percentage 300ms |
| Leaderboard rank change | Slide to new position 400ms |
| Card long-press (admin delete) | Subtle scale to 0.98 + haptic feedback |
| Skeleton shimmer | Infinite shimmer sweep, 1500ms per cycle |
| Pull-to-refresh | Spring physics on the indicator |

---

## 15. Component Override Summary (AppTheme.light)

All global component overrides are applied once in `AppTheme.light`. No per-widget `Theme.of(context).copyWith()` anywhere in the app.

| Component Theme | Key Overrides |
|----------------|---------------|
| `CardTheme` | borderRadius: 12, elevation: 1, clipBehavior: antiAlias |
| `NavigationBarTheme` | Brand-tinted indicator, height: 80 |
| `FloatingActionButtonTheme` | primaryContainer color, 16px radius |
| `InputDecorationTheme` | Outlined, 12px radius, surfaceContainerLowest fill |
| `AppBarTheme` | elevation: 0, scrolledUnderElevation: 6, no centerTitle |
| `BottomSheetTheme` | 24px top radius, drag handle visible, surfaceContainerLow |
| `SnackBarTheme` | Floating behavior, 12px margin, 12px radius |
| `ChipTheme` | 8px radius, used for categories/tags/interests/filters |
| `DialogTheme` | 12px radius, surfaceContainerHigh background |
| `TabBarTheme` | primary indicator, labelLarge labels |
| `DividerTheme` | outlineVariant color, 1px thickness |
| `BadgeTheme` | error background, 6px size for dots |
