# Flutter Folder Structure

## Overview

Manager Connect's Flutter application lives in the `frontend/` directory. The structure enforces Clean Architecture via folder conventions: every feature module contains `data/`, `domain/`, and `presentation/` sub-layers. Shared infrastructure lives in `core/` and `shared/`. No feature module imports from another.

For architecture rationale, see `flutter-architecture.md`.

---

## Top-Level Layout

```
frontend/
│
├── android/                              # Android project (Flutter-managed)
├── ios/                                  # iOS project (Flutter-managed)
├── assets/
│   ├── fonts/
│   │   └── Inter/                        # Inter-Regular, Medium, SemiBold, Bold (.ttf)
│   ├── images/
│   │   ├── logo.png
│   │   ├── connect_buddy_avatar.png      # Connect Buddy system account avatar
│   │   └── onboarding_hero.png
│   └── icons/                            # Custom icon assets
│
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   ├── shared/
│   └── features/
│
├── test/
├── pubspec.yaml
├── analysis_options.yaml
└── build.yaml
```

---

## `lib/main.dart` and `lib/app.dart`

```
lib/
│
├── main.dart
│   # ProviderScope (Riverpod root)
│   # Firebase.initializeApp()
│   # Supabase.initialize(url, anonKey)
│   # NotificationService.initialize()
│   # ErrorWidget.builder override (production friendly error screen)
│   # runApp(ProviderScope(child: App()))
│
└── app.dart
    # ConsumerWidget reads appRouterProvider
    # MaterialApp.router(
    #   routerConfig: ref.watch(appRouterProvider),
    #   theme: AppTheme.light,        ← light only; no darkTheme parameter
    #   themeMode: ThemeMode.light,   ← hardcoded, no user toggle in V1
    # )
```

---

## `lib/core/` — Shared Infrastructure

```
lib/core/
│
├── constants/
│   ├── app_constants.dart
│   │   # paginationPageSize: 20
│   │   # maxPostImageCount: 4
│   │   # maxPostContentLength: 1000
│   │   # maxBioLength: 300
│   │   # inviteTokenExpiryHours: 72
│   │   # otpExpiryMinutes: 10
│   │   # connectBuddySystemAccountId: String (UUID, seeded)
│   │
│   ├── supabase_constants.dart
│   │   # Table.profiles / posts / activities / polls / poll_options / poll_votes
│   │   # Table.eventAttendance / challenges / challenge_participants / progress_logs
│   │   # Table.recognitions / recognition_recipients / recognition_reactions
│   │   # Table.memberMonthlyStats / communityHealthScores
│   │   # Table.notificationInbox / flaggedContent / pinnedAnnouncements / adminAuditLog
│   │   # Table.invitations
│   │   # Bucket.avatars / postImages
│   │
│   ├── route_names.dart
│   │   # RouteNames.feed = '/feed'
│   │   # RouteNames.events = '/events'
│   │   # RouteNames.growth = '/growth'
│   │   # RouteNames.analytics = '/analytics'
│   │   # RouteNames.profile = '/profile'
│   │   # RouteNames.eventDetail = '/event/:id'
│   │   # RouteNames.pollDetail = '/event/:id/poll/:pollId'
│   │   # RouteNames.challengeDetail = '/challenge/:id'
│   │   # RouteNames.recognitionDetail = '/recognition/:id'
│   │   # RouteNames.memberProfile = '/profile/:id'
│   │   # RouteNames.notifications = '/notifications'
│   │   # RouteNames.admin = '/admin'
│   │   # RouteNames.adminMembers / flagged / announcements / attendance / connectBuddy
│   │
│   └── interest_tags.dart
│       # Predefined interest tag strings
│       # ['Running', 'Hiking', 'Food', 'Cricket', 'Badminton', 'Cycling', ...]
│
├── errors/
│   ├── failure.dart
│   │   # sealed class Failure { final String message; }
│   │   # NetworkFailure / AuthFailure / ServerFailure
│   │   # ValidationFailure / NotFoundFailure / PermissionFailure
│   │
│   └── app_exception.dart
│       # Data-layer exception base class (thrown in datasources, caught in repos)
│
├── extensions/
│   ├── datetime_extensions.dart
│   │   # .toDisplayDate() → "Jun 19, 2026"
│   │   # .toDisplayTime() → "2:30 PM"
│   │   # .toRelative() → "3 hours ago"
│   │   # .isToday / .isTomorrow / .isPast
│   │
│   ├── string_extensions.dart
│   │   # .capitalize() / .truncate(max) / .initials()
│   │
│   └── context_extensions.dart
│       # .theme / .colorScheme / .textTheme
│       # .screenWidth / .screenHeight
│       # .showSnackBar(message, [isError])
│       # .showMcBottomSheet(builder)
│       # .appThemeExtension → AppThemeExtension
│
├── router/
│   ├── app_router.dart
│   │   # Full GoRouter route tree
│   │   # ShellRoute with 5 tabs (Feed, Events, Growth, Analytics, Profile)
│   │   # Admin GoRoute group (role-gated)
│   │   # Auth GoRoute group (unauthenticated only)
│   │   # 404 fallback route
│   │
│   ├── router_provider.dart
│   │   # @riverpod GoRouter appRouter(...)
│   │   # Watches authNotifierProvider
│   │   # GoRouterRefreshStream(authStateStream)
│   │
│   └── route_guards.dart
│       # requireAuth(ref, state) → String? redirect path
│       # requireAdmin(ref, state) → String? redirect path
│       # requireNoAuth(ref, state) → String? redirect path
│       # requireOnboarding(ref, state) → String? redirect path
│
└── theme/
    ├── app_theme.dart
    │   # AppTheme.light → ThemeData (only theme; no dark variant)
    │   # useMaterial3: true
    │   # colorScheme: ColorScheme.fromSeed(seedColor, brightness: Brightness.light)
    │   # All component overrides: Card, NavigationBar, FAB, Input, AppBar, BottomSheet,
    │   #   SnackBar, Chip, Dialog, Badge
    │
    ├── app_colors.dart
    │   # AppColors.brandSeed = Color(0xFF006B5F)
    │   # AppColors.success / warning / danger
    │
    ├── app_text_styles.dart
    │   # Font family: 'Inter'
    │   # TextTheme overrides for displayLarge through labelSmall
    │
    └── app_theme_extensions.dart
        # ThemeExtension<AppThemeExtension>
        # successColor / warningColor / dangerColor
        # rsvpGoingColor / rsvpMaybeColor / rsvpNotGoingColor
        # attendedColor / absentColor
        # connectBuddyBadgeColor / connectBuddyPostBackground
        # pinnedPostBackground
        # healthScoreHigh / healthScoreMedium / healthScoreLow
```

---

## `lib/shared/` — Reusable Widgets and Services

```
lib/shared/
│
├── providers/
│   ├── supabase_provider.dart
│   │   # @riverpod SupabaseClient supabaseClient(...)
│   │   # Returns Supabase.instance.client
│   │
│   ├── auth_state_provider.dart
│   │   # @riverpod Stream<AuthState> authStateStream(...)
│   │   # Wraps supabase.auth.onAuthStateChange
│   │
│   └── connect_buddy_provider.dart
│       # @riverpod FutureOr<Profile> connectBuddyProfile(...)
│       # Fetches the system account profile (is_system_account=true)
│       # Used by Feed to render Connect Buddy posts with system badge
│
├── services/
│   ├── notification_service.dart
│   │   # FirebaseMessaging setup, permission request
│   │   # registerToken(supabase, userId) → updates profiles.push_token
│   │   # handleForegroundNotification() → flutter_local_notifications display
│   │   # handleNotificationTap(data) → context.go(data['targetScreen'])
│   │   # Handled types (all 15 NotificationType enum values):
│   │   #   activity_created      → /events
│   │   #   activity_reminder_24h → /event/:id
│   │   #   activity_reminder_1h  → /event/:id
│   │   #   activity_cancelled    → /event/:id
│   │   #   activity_updated      → /event/:id
│   │   #   poll_reminder         → /event/:id/poll/:pollId
│   │   #   recognition_received  → /recognition/:id
│   │   #   challenge_created     → /growth
│   │   #   challenge_ending      → /challenge/:id
│   │   #   challenge_ended       → /challenge/:id
│   │   #   mention               → /feed
│   │   #   comment_on_post       → /feed
│   │   #   connect_buddy_update  → /feed
│   │   #   admin_flag            → /admin/flagged
│   │   #   admin_member_registered → /admin/members
│   │
│   └── deep_link_service.dart
│       # Parses notification data.targetScreen
│       # Handles cold-start (getInitialMessage) and warm-start (onMessageOpenedApp)
│
└── widgets/
    │
    ├── app_bar/
    │   └── mc_app_bar.dart               # Standard AppBar with optional actions
    │
    ├── bottom_nav/
    │   └── main_scaffold.dart
    │       # ShellRoute scaffold
    │       # NavigationBar with 5 destinations (Feed/Events/Growth/Analytics/Profile)
    │       # Badge on Profile tab for notification count
    │       # Badge on Events tab for upcoming-soon indicator
    │
    ├── buttons/
    │   ├── primary_button.dart           # FilledButton + loading state
    │   ├── secondary_button.dart         # OutlinedButton
    │   └── icon_text_button.dart         # TextButton with icon
    │
    ├── cards/
    │   └── mc_card.dart                  # Standard Card with padding/radius
    │
    ├── chips/
    │   ├── event_category_chip.dart      # Games / Outings / Social Connect chip
    │   └── status_chip.dart              # Active / Ended / Cancelled status chip
    │
    ├── dialogs/
    │   ├── confirm_dialog.dart
    │   └── error_dialog.dart
    │
    ├── empty_states/
    │   └── empty_state_widget.dart       # Icon + title + subtitle
    │
    ├── error_states/
    │   └── error_state_widget.dart       # Error + retry button (.when error: handler)
    │
    ├── image/
    │   ├── mc_avatar.dart
    │   │   # Circular avatar with fallback initials
    │   │   # Connect Buddy variant: shows CB badge overlay
    │   │
    │   └── mc_cached_image.dart          # CachedNetworkImage + shimmer + error
    │
    ├── loaders/
    │   ├── skeleton_loader.dart           # Shimmer base widget
    │   ├── feed_skeleton.dart
    │   ├── events_skeleton.dart
    │   └── analytics_skeleton.dart
    │
    └── sheets/
        └── mc_bottom_sheet.dart          # DragHandle + title + content
                                          # showMcBottomSheet(context, builder) helper
```

---

## `lib/features/` — Feature Modules

---

### `features/auth/` — Authentication and Onboarding

```
lib/features/auth/
│
├── data/
│   ├── datasources/
│   │   └── auth_remote_datasource.dart
│   │       # validateInviteToken(token) → InvitationModel
│   │       # requestOtp(email) → void
│   │       # verifyOtp(email, otp) → Session
│   │       # signOut() → void (also nullifies push_token)
│   │       # getCurrentSession() → Session?
│   │
│   ├── models/
│   │   ├── session_model.dart            # @freezed + fromJson
│   │   └── invitation_model.dart         # @freezed + fromJson
│   │
│   └── repositories/
│       └── auth_repository_impl.dart     # Either<Failure, T> for all ops
│
├── domain/
│   ├── entities/
│   │   ├── app_session.dart              # userId, email, accessToken, role, isSystemAccount
│   │   └── invitation.dart
│   │
│   ├── repositories/
│   │   └── auth_repository.dart          # abstract interface
│   │
│   └── usecases/
│       ├── validate_invite_token.dart
│       ├── request_otp.dart
│       ├── verify_otp.dart
│       └── sign_out.dart
│
└── presentation/
    ├── providers/
    │   ├── auth_providers.dart            # DI providers for repo + use cases
    │   └── auth_notifier.dart
    │       # @riverpod class AuthNotifier
    │       # AuthState: unauthenticated | authenticating | authenticated(session) | deactivated
    │       # Methods: requestOtp(), verifyOtp(), signOut()
    │
    ├── screens/
    │   ├── welcome_screen.dart
    │   ├── verify_otp_screen.dart
    │   └── create_profile_screen.dart
    │
    └── widgets/
        ├── otp_input_widget.dart          # 6-box OTP row, auto-advance, paste-friendly
        └── interest_tag_selector.dart     # Chip grid for interest tag selection
```

---

### `features/feed/` — Community Feed

```
lib/features/feed/
│
├── data/
│   ├── datasources/
│   │   └── feed_remote_datasource.dart
│   │       # getFeedPosts(page) — all posts incl. Connect Buddy, with author+images+reactions
│   │       # createPost(content, imageUrls, mentionedIds) — Edge Function: create-post
│   │       # deletePost(postId)
│   │       # reactToPost(postId, emoji) / removeReaction(postId)
│   │       # getComments(postId) / addComment(postId, content) / deleteComment(commentId)
│   │       # flagPost(postId, reason)
│   │       # getPinnedPost()
│   │       # getFeedRealtimeStream() → Stream<void>
│   │
│   ├── models/
│   │   ├── post_model.dart               # includes author.is_system_account for CB detection
│   │   ├── comment_model.dart
│   │   ├── reaction_model.dart
│   │   └── pinned_announcement_model.dart
│   │
│   └── repositories/
│       └── feed_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── post.dart                     # bool isConnectBuddyPost (from author.isSystemAccount)
│   │   ├── comment.dart
│   │   ├── reaction.dart
│   │   └── pinned_announcement.dart
│   │
│   ├── repositories/
│   │   └── feed_repository.dart
│   │
│   └── usecases/
│       ├── get_feed_posts.dart
│       ├── create_post.dart
│       ├── delete_post.dart
│       ├── react_to_post.dart
│       ├── get_comments.dart
│       ├── add_comment.dart
│       ├── delete_comment.dart
│       └── flag_post.dart
│
└── presentation/
    ├── providers/
    │   ├── feed_providers.dart
    │   ├── feed_notifier.dart            # AsyncNotifier<List<Post>>
    │   ├── post_comments_notifier.dart   # .family by postId
    │   ├── post_reactions_notifier.dart  # .family by postId
    │   └── feed_realtime_provider.dart   # StreamProvider → invalidates feed
    │
    ├── screens/
    │   └── feed_screen.dart              # Feed with pinned post header
    │
    └── widgets/
        ├── post_card.dart                # Regular post card
        ├── connect_buddy_post_card.dart  # Distinct CB post card with system badge
        ├── reaction_bar.dart
        ├── comment_tile.dart
        ├── comments_sheet.dart
        ├── create_post_sheet.dart        # Text + photo + @mention
        ├── pinned_post_banner.dart
        └── mention_input_field.dart      # @ autocomplete overlay
```

---

### `features/events/` — Events (Games, Outings, Social Connect, Polls, RSVP, Attendance)

```
lib/features/events/
│
├── data/
│   ├── datasources/
│   │   └── events_remote_datasource.dart
│   │       # getEvents(category?, status?) — filter by games/outings/social_connect
│   │       # getEventById(id) — with creator, rsvps, attendance join
│   │       # createEvent(params) — PostgREST insert (includes event_category, event_type)
│   │       # cancelEvent(eventId) — Edge Function: cancel-activity
│   │       # postEventUpdate(eventId, content) — Edge Function: post-activity-update
│   │       # submitRsvp(eventId, status)
│   │       # getPolls(eventId?) / getPollById(id)
│   │       # createPoll(params) — Edge Function: create-poll
│   │       # voteOnPoll(pollId, optionId) — PostgREST insert on poll_votes
│   │       # getEventAttendance(eventId) — post-event admin view
│   │       # getRsvpRealtimeStream(eventId) → Stream<void>
│   │       # getPollVotesRealtimeStream(pollId) → Stream<void>
│   │
│   ├── models/
│   │   ├── event_model.dart              # event_category + event_type fields
│   │   ├── rsvp_model.dart
│   │   ├── event_update_model.dart
│   │   ├── poll_model.dart
│   │   ├── poll_option_model.dart
│   │   ├── poll_vote_model.dart
│   │   └── event_attendance_model.dart
│   │
│   └── repositories/
│       └── events_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── event.dart
│   │   │   # enum EventCategory { games, outings, socialConnect }
│   │   │   # String? eventType (cricket/badminton/coffeeConnect/etc.)
│   │   │
│   │   ├── rsvp.dart                     # enum RsvpStatus { going, notGoing, maybe }
│   │   ├── event_update.dart
│   │   ├── poll.dart
│   │   ├── poll_option.dart              # option text + vote count (computed)
│   │   └── event_attendance.dart         # enum AttendanceStatus { attended, absent }
│   │
│   ├── repositories/
│   │   └── events_repository.dart
│   │
│   └── usecases/
│       ├── get_events.dart
│       ├── get_event_by_id.dart
│       ├── create_event.dart
│       ├── cancel_event.dart
│       ├── submit_rsvp.dart
│       ├── post_event_update.dart
│       ├── get_polls.dart
│       ├── create_poll.dart
│       ├── vote_on_poll.dart
│       └── get_event_attendance.dart
│
└── presentation/
    ├── providers/
    │   ├── events_providers.dart
    │   ├── events_notifier.dart          # AsyncNotifier<List<Event>>: filter by category
    │   ├── event_detail_provider.dart    # FutureProvider.family
    │   ├── polls_notifier.dart           # AsyncNotifier<List<Poll>>
    │   ├── poll_votes_notifier.dart      # AsyncNotifier<Poll> with vote counts (family)
    │   ├── rsvp_notifier.dart            # AsyncNotifier per eventId (family)
    │   ├── rsvp_realtime_provider.dart
    │   └── poll_votes_realtime_provider.dart
    │
    ├── screens/
    │   ├── events_screen.dart            # Tabs: All / Games / Outings / Social Connect
    │   ├── event_detail_screen.dart      # Event info, RSVP, updates, polls, past: attendance
    │   ├── poll_detail_screen.dart       # Poll question, options, live vote counts, results
    │   └── event_history_screen.dart     # Past events with attendance records
    │
    └── widgets/
        ├── event_card.dart               # Event preview card with category chip
        ├── event_category_filter.dart    # Horizontal chip filter row
        ├── rsvp_selector.dart            # Going / Not Going / Maybe toggle
        ├── attendee_list_tile.dart
        ├── event_update_tile.dart
        ├── create_event_sheet.dart       # Category + type + title + date + location
        ├── poll_card.dart                # Poll preview with vote count
        ├── poll_option_tile.dart         # Option with progress bar (live)
        ├── create_poll_sheet.dart
        └── event_type_selector.dart      # Specific type within category (cricket/etc.)
```

---

### `features/growth/` — Fitness and Wellness Challenges

```
lib/features/growth/
│
├── data/
│   ├── datasources/
│   │   └── growth_remote_datasource.dart
│   │       # getChallenges(type?) — filter by 'fitness'|'wellness'
│   │       # getChallengeById(id)
│   │       # createChallenge(params)
│   │       # joinChallenge(challengeId) / leaveChallenge(challengeId)
│   │       # logProgress(challengeId, value, note)
│   │       # getLeaderboard(challengeId)
│   │       # getLeaderboardRealtimeStream(challengeId) → Stream<void>
│   │
│   ├── models/
│   │   ├── challenge_model.dart          # challenge_type: 'fitness'|'wellness'
│   │   ├── challenge_participant_model.dart
│   │   ├── progress_log_model.dart
│   │   └── leaderboard_entry_model.dart
│   │
│   └── repositories/
│       └── growth_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── challenge.dart
│   │   │   # enum ChallengeType { fitness, wellness }
│   │   │   # enum GoalType { steps, distance, duration, custom }
│   │   │
│   │   ├── challenge_participant.dart
│   │   ├── progress_log.dart
│   │   └── leaderboard_entry.dart
│   │
│   ├── repositories/
│   │   └── growth_repository.dart
│   │
│   └── usecases/
│       ├── get_challenges.dart
│       ├── get_challenge_by_id.dart
│       ├── create_challenge.dart
│       ├── join_challenge.dart
│       ├── leave_challenge.dart
│       ├── log_progress.dart
│       └── get_leaderboard.dart
│
└── presentation/
    ├── providers/
    │   ├── growth_providers.dart
    │   ├── challenges_notifier.dart      # AsyncNotifier<List<Challenge>>
    │   ├── challenge_detail_provider.dart
    │   ├── leaderboard_notifier.dart     # .family by challengeId
    │   └── leaderboard_realtime_provider.dart
    │
    ├── screens/
    │   ├── growth_screen.dart            # Tabs: Active / My Challenges / Completed
    │   ├── challenge_detail_screen.dart
    │   └── completed_challenges_screen.dart
    │
    └── widgets/
        ├── challenge_card.dart           # Challenge type badge (Fitness / Wellness)
        ├── challenge_type_filter.dart    # Fitness / Wellness filter chips
        ├── leaderboard_list.dart
        ├── leaderboard_entry_tile.dart
        ├── progress_log_sheet.dart
        ├── create_challenge_sheet.dart
        └── goal_type_selector.dart       # Steps / Distance / Duration / Custom
```

---

### `features/analytics/` — Analytics, Rankings, and Recognition

```
lib/features/analytics/
│
├── data/
│   ├── datasources/
│   │   └── analytics_remote_datasource.dart
│   │       # getPersonalAnalytics(userId) — from member_monthly_stats + aggregates
│   │       # getCommunityAnalytics() — community-wide aggregates
│   │       # getCommunityHealthScore() — latest community_health_scores row
│   │       # getMonthlyRankings(month) — ranked member_monthly_stats
│   │       # getAllTimeRankings() — SUM aggregation across all months
│   │       # getMonthlyRecognition(month) — recognitions in current month
│   │       # getCommunityRecognition(page) — all recognitions, reverse chron
│   │       # getRecognitionById(id)
│   │       # createRecognition(params) — Edge Function: create-recognition
│   │       # reactToRecognition(recognitionId, emoji)
│   │
│   ├── models/
│   │   ├── personal_analytics_model.dart
│   │   ├── community_analytics_model.dart
│   │   ├── health_score_model.dart
│   │   ├── ranking_entry_model.dart
│   │   ├── recognition_model.dart
│   │   ├── recognition_recipient_model.dart
│   │   └── recognition_reaction_model.dart
│   │
│   └── repositories/
│       └── analytics_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── personal_analytics.dart
│   │   │   # eventsAttended, attendanceRate, challengesJoined
│   │   │   # progressLogsCount, recognitionsReceived, recognitionsGiven
│   │   │   # postsCount, currentMonthRank, allTimeRank
│   │   │
│   │   ├── community_analytics.dart
│   │   │   # activeMembers, totalEventsThisMonth, avgAttendanceRate
│   │   │   # activeChallengeParticipants, totalRecognitionsThisMonth
│   │   │
│   │   ├── health_score.dart
│   │   │   # score (0–100), scoreMonth, participationRate
│   │   │   # avgAttendanceRate, challengeEngagement, recognitionActivity
│   │   │   # enum HealthLevel { high, medium, low }
│   │   │
│   │   ├── ranking_entry.dart
│   │   │   # rank, profile (ProfileSummary), score, eventsAttended
│   │   │   # recognitionsReceived, challengeCompletion
│   │   │
│   │   └── recognition.dart
│   │           # giver, recipients (List<ProfileSummary>), categoryTag, message
│   │           # reactions, createdAt
│   │
│   ├── repositories/
│   │   └── analytics_repository.dart
│   │
│   └── usecases/
│       ├── get_personal_analytics.dart
│       ├── get_community_analytics.dart
│       ├── get_community_health_score.dart
│       ├── get_monthly_rankings.dart
│       ├── get_all_time_rankings.dart
│       ├── get_monthly_recognition.dart
│       ├── get_community_recognition.dart
│       ├── create_recognition.dart
│       └── react_to_recognition.dart
│
└── presentation/
    ├── providers/
    │   ├── analytics_providers.dart
    │   ├── personal_analytics_provider.dart    # FutureProvider (own stats)
    │   ├── community_analytics_provider.dart   # FutureProvider
    │   ├── health_score_provider.dart           # FutureProvider
    │   ├── monthly_rankings_notifier.dart       # AsyncNotifier
    │   ├── all_time_rankings_notifier.dart      # AsyncNotifier
    │   ├── monthly_recognition_notifier.dart    # AsyncNotifier
    │   └── community_recognition_notifier.dart  # AsyncNotifier (paginated)
    │
    ├── screens/
    │   ├── analytics_screen.dart
    │   │   # Tabs: Personal | Community | Rankings | Recognition
    │   │
    │   ├── personal_analytics_screen.dart      # My stats, charts, streak
    │   ├── community_analytics_screen.dart     # Health score + community stats
    │   ├── rankings_screen.dart                # Monthly / All-Time toggle
    │   ├── recognition_screen.dart             # Monthly Recognition + Community Wall tabs
    │   └── recognition_detail_screen.dart
    │       # Full detail view for a single recognition
    │       # Giver profile, recipient chips, category tag badge, message
    │       # Reaction bar (emoji reactions on the recognition)
    │       # Routed by: /recognition/:id
    │
    └── widgets/
        ├── health_score_card.dart              # Score dial / gauge with color coding
        ├── health_score_breakdown.dart         # Sub-metrics (participation, attendance, etc.)
        ├── ranking_entry_tile.dart             # Rank number, avatar, name, score
        ├── personal_stat_card.dart             # Single metric card (events attended, etc.)
        ├── recognition_card.dart               # Recognition with giver/recipients/category
        ├── recognition_reaction_bar.dart
        ├── recipient_chip_list.dart
        ├── category_tag_badge.dart             # Community Contributor / Fitness Champion / etc. chip
        └── give_recognition_sheet.dart         # Recipient search + category + message
```

---

### `features/profile/` — User Profile and Settings

```
lib/features/profile/
│
├── data/
│   ├── datasources/
│   │   └── profile_remote_datasource.dart
│   │       # getProfileById(id) — filters out is_system_account=true profiles
│   │       # getAllMemberProfiles() — all active non-system profiles
│   │       # updateProfile(params)
│   │       # uploadAvatar(userId, imageBytes)
│   │       # updateNotificationPreferences(prefs)
│   │       # updatePushToken(token) / nullifyPushToken()
│   │
│   ├── models/
│   │   ├── profile_model.dart
│   │   └── notification_preferences_model.dart
│   │       # activityReminders / newEvents / recognitionsReceived
│   │       # newChallenges / challengeReminders / mentions
│   │       # commentsOnMyPosts / pollReminders / connectBuddyUpdates
│   │
│   └── repositories/
│       └── profile_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── profile.dart                  # Full profile (isSystemAccount included)
│   │   ├── profile_summary.dart          # id, fullName, avatarUrl, title, isSystemAccount
│   │   └── notification_preferences.dart # All 9 preference fields
│   │
│   ├── repositories/
│   │   └── profile_repository.dart
│   │
│   └── usecases/
│       ├── get_profile.dart
│       ├── get_all_member_profiles.dart  # Excludes system accounts
│       ├── update_profile.dart
│       ├── upload_avatar.dart
│       └── update_notification_preferences.dart
│
└── presentation/
    ├── providers/
    │   ├── profile_providers.dart
    │   ├── profile_notifier.dart         # .family by userId
    │   ├── own_profile_notifier.dart
    │   └── all_profiles_provider.dart    # Used for @mention + recognition recipient picker
    │
    ├── screens/
    │   ├── own_profile_screen.dart       # Profile tab root: own profile + settings entry
    │   ├── edit_profile_screen.dart
    │   ├── member_profile_screen.dart    # Any other member's profile
    │   └── notification_preferences_screen.dart
    │
    └── widgets/
        ├── profile_header.dart
        ├── interest_tag_chip.dart
        ├── member_search_tile.dart       # Avatar + name for pickers
        └── received_recognitions_list.dart # Member's received recognitions from Analytics
```

---

### `features/admin/` — Admin Panel

```
lib/features/admin/
│
├── data/
│   ├── datasources/
│   │   └── admin_remote_datasource.dart
│   │       # getAllMembers() / getAllInvitations()
│   │       # sendInvitation(params) → Edge Function: send-invitation
│   │       # revokeInvitation(id) → Edge Function: revoke-invitation
│   │       # deactivateUser(userId) → Edge Function: deactivate-user
│   │       # removeUser(userId) → Edge Function: remove-user
│   │       # getFlaggedContent() → pending flags
│   │       # resolveFlag(flagId, action) → Edge Function: resolve-flag
│   │       # pinAnnouncement(postId) → Edge Function: pin-announcement
│   │       # recordAttendance(activityId, records) → Edge Function: record-attendance
│   │       # getEventsNeedingAttendance() → past events with no attendance recorded
│   │       # getConnectBuddyPosts() → recent CB posts from feed
│   │       # triggerConnectBuddyPost(type, params) → Edge Function: post-connect-buddy-message
│   │       # getEngagementMetrics()
│   │
│   ├── models/
│   │   ├── flagged_content_model.dart
│   │   ├── invitation_admin_model.dart
│   │   └── admin_metrics_model.dart
│   │
│   └── repositories/
│       └── admin_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── flagged_content.dart
│   │   ├── invitation_admin.dart
│   │   └── admin_metrics.dart
│   │
│   ├── repositories/
│   │   └── admin_repository.dart
│   │
│   └── usecases/
│       ├── get_all_members.dart
│       ├── send_invitation.dart
│       ├── revoke_invitation.dart
│       ├── deactivate_user.dart
│       ├── remove_user.dart
│       ├── get_flagged_content.dart
│       ├── resolve_flag.dart
│       ├── pin_announcement.dart
│       ├── record_attendance.dart
│       └── trigger_connect_buddy_post.dart
│
└── presentation/
    ├── providers/
    │   ├── admin_providers.dart
    │   ├── members_notifier.dart
    │   ├── invitations_notifier.dart
    │   ├── flagged_content_notifier.dart
    │   ├── attendance_notifier.dart      # Events needing attendance + submit
    │   └── admin_metrics_provider.dart   # FutureProvider
    │
    ├── screens/
    │   ├── admin_overview_screen.dart
    │   ├── admin_members_screen.dart
    │   ├── admin_flagged_screen.dart
    │   ├── admin_announcements_screen.dart
    │   ├── admin_attendance_screen.dart  # Record post-event attendance
    │   └── admin_connect_buddy_screen.dart # View/trigger Connect Buddy posts
    │
    └── widgets/
        ├── member_management_tile.dart
        ├── pending_invitation_tile.dart
        ├── flagged_content_card.dart
        ├── invite_member_sheet.dart
        ├── admin_action_confirm.dart
        ├── attendance_recording_sheet.dart # Mark each member Attended/Absent
        └── connect_buddy_trigger_sheet.dart # Manually trigger a CB post type
```

---

### `features/notifications/` — Notification Inbox

Presentation-only feature module. No domain or data layers — data access is handled via `shared/services/notification_service.dart`; domain logic is trivial (read + mark-read). The notification inbox satisfies R24 (in-app notification inbox, Should Have).

```
lib/features/notifications/
│
└── presentation/
    ├── providers/
    │   ├── notification_inbox_notifier.dart
    │   │   # @riverpod class NotificationInboxNotifier
    │   │   # AsyncNotifier<List<NotificationItem>>
    │   │   # Methods: markAsRead(id), markAllAsRead(), deleteNotification(id)
    │   │   # Backed by notification_inbox REST queries via shared notification service
    │   │
    │   └── notification_realtime_provider.dart
    │       # @riverpod Stream<void> notificationRealtimeStream(...)
    │       # Subscribes to: notifications:inbox:{userId} — INSERT on notification_inbox
    │       # On event: invalidates notificationInboxProvider + updates badge count
    │
    ├── screens/
    │   └── notifications_screen.dart
    │       # Routed by: /notifications
    │       # Inbox list: all notifications, reverse-chron, paginated (20/page)
    │       # Marks individual notification as read on tap
    │       # Tapping navigates to targetScreen from notification data
    │       # "Mark all as read" action in AppBar
    │       # Empty state when inbox is empty
    │
    └── widgets/
        ├── notification_tile.dart
        │   # Leading icon by notification type (event/poll/growth/recognition/admin)
        │   # Title + body text, timestamp (relative)
        │   # Unread indicator: left accent bar or bold text
        │   # On tap: mark as read + navigate to targetScreen
        │
        └── notification_mark_all_button.dart
            # TextButton "Mark all as read" — shown only when unread count > 0
```

---

## `test/` — Test Structure

```
test/
│
├── unit/
│   ├── core/
│   │   └── extensions/
│   │       ├── datetime_extensions_test.dart
│   │       └── string_extensions_test.dart
│   │
│   └── features/
│       ├── events/domain/usecases/create_event_test.dart
│       ├── events/domain/usecases/vote_on_poll_test.dart
│       ├── growth/domain/usecases/get_leaderboard_test.dart
│       └── analytics/domain/usecases/get_monthly_rankings_test.dart
│
├── widget/
│   └── features/
│       ├── auth/presentation/screens/verify_otp_screen_test.dart
│       ├── feed/presentation/widgets/post_card_test.dart
│       ├── feed/presentation/widgets/connect_buddy_post_card_test.dart
│       ├── events/presentation/widgets/poll_option_tile_test.dart
│       └── analytics/presentation/widgets/health_score_card_test.dart
│
├── integration/
│   └── features/
│       ├── auth_integration_test.dart
│       ├── feed_integration_test.dart
│       ├── events_integration_test.dart  # includes polls + attendance
│       ├── growth_integration_test.dart
│       ├── analytics_integration_test.dart
│       └── admin_integration_test.dart
│
└── helpers/
    ├── mock_repositories.dart
    ├── mock_use_cases.dart
    ├── test_fixtures.dart
    └── provider_overrides.dart
```

---

## `pubspec.yaml`

```yaml
name: manager_connect
description: Private manager community platform

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.1.0

  # Backend
  supabase_flutter: ^2.5.0

  # Data Models
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

  # Functional Result Types
  fpdart: ^1.1.0

  # Push Notifications
  firebase_core: ^3.3.0
  firebase_messaging: ^15.0.4
  flutter_local_notifications: ^17.2.2

  # Images
  cached_network_image: ^3.3.1
  image_picker: ^1.1.2
  image: ^4.2.0

  # Utilities
  intl: ^0.19.0
  connectivity_plus: ^6.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0

  # Testing
  mocktail: ^1.0.4
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter/Inter-Regular.ttf
        - asset: assets/fonts/Inter/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter/Inter-Bold.ttf
          weight: 700
  assets:
    - assets/images/
    - assets/icons/
```

---

## Key Structural Rules

| Rule | Rationale |
|---|---|
| Feature modules never import from other feature modules | Isolation; changes to one module cannot break another |
| Screens never import from `data/` | Clean Architecture boundary |
| `supabase_flutter` SDK called only in `data/datasources/` | Single Supabase access point per module; mockable in tests |
| All Edge Function calls go through a datasource, not directly from a notifier | Testability |
| `ProfileSummary` exported from `features/profile/domain/` and used by feed, events, analytics | Single definition of the lightweight user type |
| System accounts (`is_system_account=true`) never appear in member-facing pickers | Enforced in `get_all_member_profiles` use case and `getAllMemberProfiles()` datasource |
| Connect Buddy posts rendered distinctly in Feed | Identified by `post.isConnectBuddyPost` derived from author's `is_system_account` |
| Code generation files (`*.g.dart`, `*.freezed.dart`) are committed | Avoids mandatory `build_runner` run on every fresh clone |
| `shared_preferences` not used — no theme persistence needed | V1 is light mode only; ThemeMode is hardcoded |
