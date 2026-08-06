# Moonchild UI Migration Report

**Branch:** `ui-v0-feed-migration`  
**Date:** 2026-07-01  
**Engineer:** Principal Flutter UI — Moonchild Design System Implementation

---

## Summary

Complete replacement of the Manager Connect Flutter presentation layer with the **Moonchild design language**, as specified in `docs/design/moonchild/explore-ui-style.md`. All backend integrations (Supabase, Riverpod providers, repositories, services) were preserved unchanged.

---

## Design Token System — New Files

| File | Class | Purpose |
|------|-------|---------|
| `lib/shared/widgets/mc/mc_colors.dart` | `MCColors` | Full Moonchild palette: primary navy ramp, amber, violet, semantic, surface, text, border, gradients, shadows |
| `lib/shared/widgets/mc/mc_typography.dart` | `MCTypography` | DM Sans (General Sans substitute) + Inter — 20 named text styles |
| `lib/shared/widgets/mc/mc_spacing.dart` | `MCSpacing` | Base scale, layout constants, radii, borders, avatar sizes, nav sizes |
| `lib/shared/widgets/mc/mc_theme.dart` | `MCTheme` | `MaterialApp` `ThemeData` — `NoSplash.splashFactory`, FilledButton, Input, Chip, Divider, BottomSheet, Dialog, SnackBar all themed |

---

## Component Library — New Files

| File | Components | Notes |
|------|-----------|-------|
| `lib/shared/widgets/mc/mc_buttons.dart` | `MCPrimaryButton`, `MCAmberButton`, `MCGhostButton`, `MCPillButton`, `MCIconButton` | Gradient CTAs, 54px, radius 14, shadow |
| `lib/shared/widgets/mc/mc_inputs.dart` | `MCInput`, `MCOtpInput`, `MCTextarea` | Animated focus, 6-box OTP with `KeyboardListener`/`KeyDownEvent`, borderless textarea |
| `lib/shared/widgets/mc/mc_cards.dart` | `MCCard`, `MCAnnouncementCard`, `MCRecognitionCardShimmer`, `MCPollCard` | Left-border accent variants |
| `lib/shared/widgets/mc/mc_badges.dart` | `MCStatusPill`, `MCFilterChip`, `MCBadgeDot` | Semantic factory constructors, active-navy fill chip |
| `lib/shared/widgets/mc/mc_avatar.dart` | `MCAvatar`, `MCAvatarStack`, `MCStoryAvatar` | Story ring gradient, configurable overlap stack |
| `lib/shared/widgets/mc/mc_bottom_nav.dart` | `MCBottomNav` | 72px, animated pill (48×28, radius 9999), 5 tabs |
| `lib/shared/widgets/mc/mc_main_scaffold.dart` | `MCMainScaffold` | GoRouter ShellRoute wrapper; 430px phone frame on screens > 480px |

---

## Screens Replaced

### Auth Flow

| Screen | File | Theme | Backend Preserved |
|--------|------|-------|-------------------|
| Splash | `lib/features/auth/presentation/screens/splash_screen.dart` | Navy gradient, custom `_Logomark` painter, amber progress bar | `authProvider.initialize()` |
| Login | `lib/features/auth/presentation/screens/welcome_screen.dart` | Two-zone hero + white bottom sheet (radius 28) | `validateInviteToken`, `sendOtp`, `authProvider` |
| OTP Verification | `lib/features/auth/presentation/screens/verify_otp_screen.dart` | Shield icon, 6-box `MCOtpInput`, 120s countdown | `repo.verifyOtp`, `authProvider.handleSignIn` |
| Onboarding / Create Profile | `lib/features/auth/presentation/screens/create_profile_screen.dart` | 2-step progress form, interest `MCFilterChip` tags | `ProfileRepository.createProfile`, `authProvider.handleProfileCreated` |

### Feed Flow

| Screen | File | Theme | Backend Preserved |
|--------|------|-------|-------------------|
| Feed | `lib/features/feed/presentation/screens/mc_feed_screen.dart` | Stories row, filter chips, composer card, 5 card types, `FeedItem` sealed switch | `feedProvider.loadFeed/loadMore/refresh` |
| Post Detail | `lib/features/feed/presentation/screens/post_detail_screen.dart` | 5-emoji reactions (animated pills), bubble comment tiles | `postDetailProvider`, `toggleReaction`, `addComment`, `deleteComment` |
| Create Post | `lib/features/feed/presentation/screens/create_post_screen.dart` | Borderless textarea, animated pill CTA | `FeedRepository.createPost`, `feedProvider.refresh` |

### Creation Screens

| Screen | File | Theme | Backend Preserved |
|--------|------|-------|-------------------|
| Create Recognition | `lib/features/recognition/presentation/screens/create_recognition_screen.dart` | Amber gradient hero, category chips, member chips | `RecognitionRepository.createRecognition`, `recognitionFeedProvider` |
| Create Poll | `lib/features/polls/presentation/screens/create_poll_screen.dart` | Violet accent banner, numbered option rows, add/remove options | `PollRepository.createPoll` |
| Create Event | `lib/features/events/presentation/screens/create_activity_screen.dart` | Navy gradient hero, category icon cards, event-type chips | `ActivityRepository.createActivity`, `activitiesProvider.refresh` |

---

## Files Removed

### V0 Widget Layer (`lib/shared/widgets/v0/`)
- `v0_animations.dart`
- `v0_avatar_stack.dart`
- `v0_bottom_nav.dart`
- `v0_colors.dart`
- `v0_composer.dart`
- `v0_engagement_bar.dart`
- `v0_main_scaffold.dart`
- `v0_poll_block.dart`
- `v0_post_card.dart`
- `v0_post_header.dart`
- `v0_spotlight_rail.dart`
- `v0_theme.dart`
- `v0_top_bar.dart`
- `v0_typography.dart`

### Legacy MC Widgets (`lib/shared/widgets/mc/`)
- `mc_action_row.dart`
- `mc_composer.dart`
- `mc_engagement_cluster.dart`
- `mc_feed_post_card.dart`
- `mc_icon_tile.dart`
- `mc_section_header.dart`
- `mc_social_proof_row.dart`
- `mc_top_bar.dart`
- `mc_type_pill.dart`

### Legacy Feed Widgets (`lib/features/feed/presentation/widgets/`)
- `composer_card.dart`
- `feed_app_bar.dart`
- `post_card.dart`
- `trending_header.dart`

### Legacy Navigation (`lib/shared/widgets/bottom_nav/`)
- `main_scaffold.dart`

### Legacy Theme (`lib/core/theme/`)
- `app_theme.dart`
- `app_colors.dart` (pre-existing delete)
- `app_text_styles.dart` (pre-existing delete)
- `app_theme_extensions.dart` (pre-existing delete)

### Legacy Screen
- `lib/features/feed/presentation/screens/v0_feed_screen.dart`

---

## Files Updated

| File | Change |
|------|--------|
| `lib/app.dart` | `V0Theme.light` → `MCTheme.light` |
| `lib/core/router/app_router.dart` | `V0MainScaffold` → `MCMainScaffold`; `V0FeedScreen` → `MCFeedScreen` |
| `lib/features/events/presentation/screens/activity_detail_screen.dart` | `V0Colors.emerald/amber` → `MCColors.success/amber` |

---

## Backend Connections Verified

All existing providers, repositories, and services remain untouched:

- **Auth:** `authProvider`, `AuthNotifier`, `authRepository`, `ProfileRepository`
- **Feed:** `feedProvider`, `FeedRepository`, `postDetailProvider`
- **Recognition:** `recognitionFeedProvider`, `RecognitionRepository`
- **Polls:** `PollRepository`
- **Events:** `activitiesProvider`, `ActivityRepository`, `activityDetailProvider`
- **Supabase:** `supabaseClientProvider` — unchanged
- **Routing:** GoRouter `appRouterProvider`, `RouteNames` — unchanged
- **Notifications:** Unchanged
- **Admin:** Unchanged

---

## Design System Mapping

| Moonchild Token | Value | Flutter Usage |
|----------------|-------|--------------|
| Primary | `#1A3A6B` | `MCColors.primary` |
| Primary Mid | `#2451A3` | `MCColors.primaryMid` — active nav, CTAs |
| Amber | `#FFB840` | `MCColors.amber` — recognition accent |
| Violet | `#7C3AED` | `MCColors.violet` — polls accent |
| Success | `#10B981` | `MCColors.success` |
| Background | `#F4F5F7` | `MCColors.background` |
| Card | `#FFFFFF` | `MCColors.card` |
| Font (headings) | DM Sans | `GoogleFonts.dmSans()` (General Sans substitute) |
| Font (body) | Inter | `GoogleFonts.inter()` |
| Card radius | 16px | `MCSpacing.radiusMd` |
| Button radius | 14px | `MCSpacing.radiusButton` |
| Nav height | 72px | `MCSpacing.navHeight` |
| Phone frame | 430px, radius 44 | `MCMainScaffold` (web > 480px) |

---

## `flutter analyze` Result

```
3 issues found (all info-level — prefer_const suggestions only)
Exit code: 0 — No errors, no warnings
```

---

## Remaining Screens (Not in Migration Scope)

The following screens exist in the codebase but were not in the 10-screen migration scope. They continue to function using Material defaults and can be migrated in a follow-up:

- `ActivitiesListScreen` — events list
- `ActivityDetailScreen` — updated to remove V0Colors; body still uses Material widgets
- `PollDetailScreen`
- `ChallengeListScreen` / `ChallengeDetailScreen`
- `AnalyticsScreen` / `RankingsScreen`
- `NotificationCenterScreen`
- `ProfileScreen`
- `AdminDashboardScreen` (partially updated)
- `MemberManagementScreen` / `InvitationManagementScreen` / `ModerationQueueScreen` / `AttendanceRecordingScreen`
