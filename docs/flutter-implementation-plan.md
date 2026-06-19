# Flutter Implementation Plan

## Overview

This document is the implementation blueprint for the Manager Connect Flutter application. It bridges the architecture design in `flutter-architecture.md` and `flutter-folder-structure.md` with the backend defined in `backend-implementation-plan.md`. No production code is written here — this is a sequenced, layer-by-layer planning reference.

**Mobile stack:** Flutter 3.22+ · Dart 3.3+ · Riverpod 2.x (code gen) · GoRouter 14.x · Supabase Flutter 2.x · Material 3 (light mode only)

**Architecture:** Clean Architecture — Domain → Data → Presentation — within each feature module. No module imports from another module. All dependencies flow through the Riverpod provider graph.

**Reference documents:**
- Folder structure: `flutter-folder-structure.md`
- Architecture rationale: `flutter-architecture.md`
- Backend contracts: `backend-api-contracts.md`
- Backend implementation: `backend-implementation-plan.md`
- Feature requirements: `functional-requirements.md`

---

## 1. Project Initialization

### 1.1 New Project Setup

```
flutter create manager_connect --org com.yourorg --platforms ios,android
cd manager_connect
```

Delete default template files: `test/widget_test.dart`, `lib/main.dart` stub contents.

### 1.2 analysis_options.yaml

Extend `flutter_lints` with stricter rules:
- `always_use_package_imports: true` — no relative imports across features
- `prefer_final_fields: true`
- `avoid_print: true` — use logging package
- `always_declare_return_types: true`

### 1.3 build.yaml

Configure `build_runner` targets:
- `riverpod_generator` — generates `*.g.dart` for all `@riverpod` providers
- `freezed` — generates `*.freezed.dart` for all `@freezed` classes
- `json_serializable` — generates `*.g.dart` for `@JsonSerializable` models

Generated files (`*.g.dart`, `*.freezed.dart`) are committed to the repository. This avoids mandatory `build_runner` execution on every fresh clone.

Run code generation:
```
dart run build_runner build --delete-conflicting-outputs
```

### 1.4 Firebase Setup

1. Create Firebase project (`manager-connect-{env}` per environment)
2. Add iOS app (bundle ID) and Android app (package name)
3. Download `GoogleService-Info.plist` (iOS) and `google-services.json` (Android)
4. Place in `ios/Runner/` and `android/app/` respectively — never committed to public repos
5. Enable FCM in Firebase Console

### 1.5 Environment Configuration

No `flutter_dotenv` — Supabase URL and anon key are compile-time constants per build flavor (dev/staging/prod). Use `--dart-define` at build time:

```
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Access in Dart:
```dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

The service role key is never in the Flutter app.

---

## 2. Entry Points

### 2.1 main.dart

Initialization sequence (order matters):

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
3. `await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey)`
4. `NotificationService.initialize()` — FCM foreground handler + background message handler
5. `ErrorWidget.builder = (details) => ProductionErrorWidget(details)` — replaces red screen
6. `runApp(ProviderScope(child: App()))`

### 2.2 app.dart

`App` is a `ConsumerWidget`. Reads `appRouterProvider`. Configures `MaterialApp.router`:
- `routerConfig: ref.watch(appRouterProvider)`
- `theme: AppTheme.light` — the only theme
- `themeMode: ThemeMode.light` — hardcoded; no user toggle
- `debugShowCheckedModeBanner: false`

---

## 3. Core Layer Implementation

### 3.1 constants/app_constants.dart

```
paginationPageSize: 20
maxPostImageCount: 4
maxPostContentLength: 1000
maxBioLength: 300
inviteTokenExpiryHours: 72
connectBuddySystemAccountId: '00000000-0000-4000-8000-000000000001'
```

`connectBuddySystemAccountId` matches the hardcoded UUID in `supabase/functions/_shared/constants.ts` and `supabase/seed.sql`. These three locations are the only places this UUID appears in the codebase. Changing it requires updating all three.

### 3.2 constants/supabase_constants.dart

String constants for every table name and storage bucket. Used in all datasource calls — no magic strings in production code.

```dart
abstract class Table {
  static const profiles = 'profiles';
  static const posts = 'posts';
  static const postImages = 'post_images';
  static const postReactions = 'post_reactions';
  static const comments = 'comments';
  static const postMentions = 'post_mentions';
  static const activities = 'activities';
  static const activityRsvps = 'activity_rsvps';
  static const activityUpdates = 'activity_updates';
  static const polls = 'polls';
  static const pollOptions = 'poll_options';
  static const pollVotes = 'poll_votes';
  static const eventAttendance = 'event_attendance';
  static const challenges = 'challenges';
  static const challengeParticipants = 'challenge_participants';
  static const progressLogs = 'progress_logs';
  static const recognitions = 'recognitions';
  static const recognitionRecipients = 'recognition_recipients';
  static const recognitionReactions = 'recognition_reactions';
  static const memberMonthlyStats = 'member_monthly_stats';
  static const communityHealthScores = 'community_health_scores';
  static const notificationInbox = 'notification_inbox';
  static const flaggedContent = 'flagged_content';
  static const pinnedAnnouncements = 'pinned_announcements';
  static const adminAuditLog = 'admin_audit_log';
  static const invitations = 'invitations';
}

abstract class Bucket {
  static const avatars = 'avatars';
  static const postImages = 'post-images';
}
```

### 3.3 errors/failure.dart

Sealed class hierarchy. Used as the `Left` type in all `Either<Failure, T>` returns from use cases.

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure { ... }      // No connectivity
class AuthFailure extends Failure { ... }         // 401 — force logout
class PermissionFailure extends Failure { ... }   // 403
class NotFoundFailure extends Failure { ... }     // 404
class ConflictFailure extends Failure { ... }     // 409
class ValidationFailure extends Failure { ... }   // 422
class ServerFailure extends Failure { ... }       // 500 / unknown
```

### 3.4 router/app_router.dart

Full GoRouter tree. Key structural decisions:

**ShellRoute** wraps the 5-tab app scaffold (`MainScaffold`). Nested `GoRoute`s define each tab's root screen plus per-tab stack routes.

**Redirect logic** (evaluated on every navigation):
1. `authNotifier.value` is loading → no redirect (show splash)
2. No valid session → `/welcome`
3. Valid session + `onboarding_completed = false` → `/create-profile`
4. Valid session + attempting admin route + `role != 'admin'` → `/feed`
5. Valid session + attempting auth route (`/welcome`, `/verify-otp`) → `/feed`

**`GoRouterRefreshStream`** watches `authStateStreamProvider`. The router re-evaluates the redirect on every auth state change — login, logout, and deactivation all trigger automatic redirect without manual `context.go()` calls.

**Stack routes** (outside the ShellRoute, push over the tab bar):
```
/event/:id                → EventDetailScreen
/event/:id/poll/:pollId   → PollDetailScreen
/challenge/:id            → ChallengeDetailScreen
/recognition/:id          → RecognitionDetailScreen
/analytics/ranking        → FullRankingsScreen
/profile/:id              → MemberProfileScreen
/notifications            → NotificationsScreen
/admin                    → AdminOverviewScreen (role-gated)
/admin/members            → AdminMembersScreen
/admin/flagged            → AdminFlaggedScreen
/admin/announcements      → AdminAnnouncementsScreen
/admin/attendance         → AdminAttendanceScreen
/admin/connect-buddy      → AdminConnectBuddyScreen
```

### 3.5 theme/

`AppTheme.light` is the single `ThemeData` object. All component overrides are applied here. Never apply `Theme.of(context).copyWith()` in individual widgets — all overrides go in `AppTheme.light`.

`AppThemeExtension` carries semantic color tokens not in the Material 3 role system:

| Token | Used by |
|---|---|
| `rsvpGoingColor` | RSVP selector, attendee count badge |
| `rsvpMaybeColor` | RSVP selector |
| `rsvpNotGoingColor` | RSVP selector |
| `attendedColor` | Attendance recording sheet |
| `absentColor` | Attendance recording sheet |
| `connectBuddyBadgeColor` | CB post card badge, CB avatar overlay |
| `connectBuddyPostBackground` | Distinct CB post card background |
| `pinnedPostBackground` | Pinned announcement banner |
| `healthScoreHigh` | Health score card (score ≥ 70) |
| `healthScoreMedium` | Health score card (score 40–69) |
| `healthScoreLow` | Health score card (score < 40) |

---

## 4. Shared Layer Implementation

### 4.1 shared/providers/supabase_provider.dart

```dart
@riverpod
SupabaseClient supabaseClient(SupabaseClientRef ref) {
  return Supabase.instance.client;
}
```

Every datasource reads `supabaseClientProvider`. This is the single injection point — tests override it with a mock.

### 4.2 shared/providers/auth_state_provider.dart

```dart
@riverpod
Stream<AuthState> authStateStream(AuthStateStreamRef ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}
```

Used by `GoRouterRefreshStream` and `AuthNotifier`.

### 4.3 shared/providers/connect_buddy_provider.dart

Fetches the Connect Buddy system profile by its hardcoded UUID. Used by the Feed to verify the CB avatar and name without querying on every post render.

```dart
@riverpod
Future<Profile> connectBuddyProfile(ConnectBuddyProfileRef ref) async {
  // Fetches profile where id = AppConstants.connectBuddySystemAccountId
}
```

### 4.4 shared/services/notification_service.dart

**Initialization (called in main.dart):**
1. `FirebaseMessaging.instance.requestPermission()`
2. `FirebaseMessaging.instance.onTokenRefresh` stream → call `updatePushToken()`
3. `FirebaseMessaging.onMessage.listen(handleForegroundNotification)` — foreground display
4. `FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage)` — background handler (top-level function, outside any class)

**Token registration** (`registerToken`):
- Call `FirebaseMessaging.instance.getToken()` → get FCM token string
- PATCH `profiles.push_token` via REST only if token differs from stored value
- Called after successful OTP verification + profile load

**Foreground notification** (`handleForegroundNotification`):
- Display via `flutter_local_notifications` with Android channel and iOS presentation options
- Tapping the local notification calls `handleNotificationTap`

**Notification tap** (`handleNotificationTap`):
- Read `data['targetScreen']` from message payload
- Call `router.go(targetScreen)` — requires router reference passed at init
- Handle missing or malformed `targetScreen` gracefully (navigate to `/feed` as fallback)

**Cold start** (`getInitialMessage`):
- Check in `main.dart` after initialization: if `FirebaseMessaging.instance.getInitialMessage()` returns a message, route after app is ready

### 4.5 shared/services/deep_link_service.dart

Handles the mapping from `notification.data['type']` + `notification.data['targetId']` to a GoRouter path:

| type | Path template |
|---|---|
| `activity_created` | `/events` |
| `activity_reminder_24h`, `activity_reminder_1h`, `activity_cancelled`, `activity_updated` | `/event/${data['targetId']}` |
| `poll_reminder` | `/event/${data['activityId']}/poll/${data['targetId']}` |
| `recognition_received` | `/recognition/${data['targetId']}` |
| `challenge_created` | `/growth` |
| `challenge_ending`, `challenge_ended` | `/challenge/${data['targetId']}` |
| `mention`, `comment_on_post`, `connect_buddy_update` | `/feed` |
| `admin_flag` | `/admin/flagged` |
| `admin_member_registered` | `/admin/members` |

### 4.6 shared/widgets/

Build order (shared widgets are needed before any feature screen):

1. `mc_avatar.dart` — used in almost every screen; build first
2. `mc_cached_image.dart` — depends on `cached_network_image`
3. `skeleton_loader.dart` — shimmer base; feed/events/analytics skeletons depend on it
4. `mc_card.dart`, `mc_bottom_sheet.dart`, `confirm_dialog.dart`
5. `primary_button.dart`, `secondary_button.dart`, `icon_text_button.dart`
6. `empty_state_widget.dart`, `error_state_widget.dart`
7. `event_category_chip.dart`, `status_chip.dart`
8. `main_scaffold.dart` — NavigationBar; requires badge count from notification provider

---

## 5. Module Implementation Plans

Each module follows the same implementation order: Data layer → Domain layer → Presentation layer. This is the reverse of the dependency direction — build what's depended on first.

---

### Module 1: Auth (Sprint 1)

**Data layer**

`auth_remote_datasource.dart` — Five operations:
- `validateInviteToken(token)` → calls Edge Function `validate-invite-token`; returns `InvitationModel`
- `requestOtp(emailOrPhone)` → `supabase.auth.signInWithOtp()`
- `verifyOtp(emailOrPhone, otp, token)` → `supabase.auth.verifyOtp()`
- `createProfile(params)` → calls Edge Function `create-profile` with invite token re-verification
- `signOut()` → nullify push token via REST PATCH → `supabase.auth.signOut()`

`session_model.dart` — wraps `Session` from `supabase_flutter`; extracts `userId`, `role` from JWT claims.

`invitation_model.dart` — maps `validate-invite-token` response: `inviteeName`, `inviteeEmail`, `inviteePhone`.

**Domain layer**

`app_session.dart` entity — `userId`, `email`, `phone`, `role (AppRole)`, `isActive`. Derived from session + profiles row.

Use cases: `ValidateInviteToken`, `RequestOtp`, `VerifyOtp`, `CreateProfile`, `SignOut`. Each is a callable class with a single `call()` method returning `Either<Failure, T>`.

**Presentation layer**

`AuthNotifier` — state machine:
```
AuthState:
  initial        → checking stored session
  unauthenticated → no session
  authenticated(AppSession) → session valid, profile loaded
  deactivated    → session valid but is_active=false → show access denied
  loading        → transition in progress
```

On `authenticated`: load own profile, register push token, start notification Realtime channel.

`WelcomeScreen` — token input field + OTP request. Validates invite token first (calls `validate-invite-token`), then requests OTP to the email/phone on the invitation record.

`VerifyOtpScreen` — 6-box OTP widget, auto-advance on digit entry, paste support (paste 6-digit string fills all boxes), 60-second resend timer.

`CreateProfileScreen` — name, photo (avatar picker + upload), title, bio (300 char limit), interest tags (chip grid from `InterestTags` constant list). Calls `create-profile` Edge Function on submit.

---

### Module 2: Feed (Sprint 2)

**Data layer**

`feed_remote_datasource.dart` — Key query patterns:

**Get feed posts (paginated):**
```dart
supabase.from(Table.posts)
  .select('''
    id, content, created_at, is_deleted,
    profiles!author_id(id, full_name, avatar_url, is_system_account),
    post_images(storage_path, display_order),
    post_reactions(id, emoji, user_id)
  ''')
  .eq('is_deleted', false)
  .order('created_at', ascending: false)
  .range(offset, offset + pageSize - 1)
```

**Create post:** Calls Edge Function `create-post` with `content` and `image_storage_paths`.

**Image upload** (before calling create-post):
1. Pick image via `image_picker`
2. Compress via `image` package (target: ≤ 1MB, JPEG quality 80)
3. Upload to `post-images/{userId}/{uuid}.jpg` via `supabase.storage.from(Bucket.postImages).uploadBinary()`
4. Collect storage paths → pass to `create-post`

**React to post:** UPSERT on `post_reactions` with ON CONFLICT `(post_id, user_id)` — same call for add and change.

**Realtime stream (feed:posts):**
```dart
supabase.channel('feed:posts')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: Table.posts,
    callback: (_) => controller.add(null),
  )
  .subscribe();
```

**Domain layer**

`Post` entity has `bool isConnectBuddyPost` derived from `author.isSystemAccount`. No other CB-specific field is needed on the entity.

`PostMention` is not a domain entity — mention parsing is server-side (Edge Function). The client only passes raw content.

**Presentation layer**

`FeedNotifier` — `AsyncNotifier<List<Post>>`:
- Initial load: fetch page 0
- Pagination: `loadMore()` appends next page
- Optimistic create: immediately prepend new post, await Edge Function, update with server response
- Realtime: `feedRealtimeProvider` (StreamProvider) invalidates the feed on new INSERT → triggers refetch of page 0; new posts prepended

`PostCard` vs `ConnectBuddyPostCard` — selected by `post.isConnectBuddyPost`:
- `PostCard`: standard card with delete option for own posts
- `ConnectBuddyPostCard`: distinct background color, CB badge on avatar, no delete option for members (admin still sees delete)

`MentionInputField` — text field with `@` trigger: shows an autocomplete overlay filtered from `allProfilesProvider` (excludes system accounts). Selecting a member inserts their UUID into the content string as `@{uuid}`.

---

### Module 3: Events (Sprint 3)

**Data layer**

`events_remote_datasource.dart` — Key patterns:

**Get events (with category filter):**
```dart
supabase.from(Table.activities)
  .select('''
    id, title, description, event_category, event_type,
    event_date, location, cost_note, status, cancelled_at,
    profiles!created_by(id, full_name, avatar_url),
    activity_rsvps(count)
  ''')
  .eq('status', 'active')
  .gte('event_date', DateTime.now().toIso8601String())
  .maybeEq('event_category', category)  // null = all categories
  .order('event_date', ascending: true)
```

**Note on FK alias:** The FK from `activities` to `profiles` is named `created_by`. The PostgREST join syntax is `profiles!created_by(...)`. This differs from the example in `flutter-architecture.md` which incorrectly shows `profiles!creator_id` — use `profiles!created_by` in all activity queries.

**RSVP (upsert):**
```dart
supabase.from(Table.activityRsvps)
  .upsert({'activity_id': id, 'user_id': userId, 'status': status.value},
          onConflict: 'activity_id,user_id')
```

**Vote on poll:**
```dart
supabase.from(Table.pollVotes)
  .insert({'poll_id': pollId, 'option_id': optionId, 'user_id': userId})
```
The UNIQUE constraint `(poll_id, user_id)` at the database level enforces one vote per member — no client-side guard needed.

**Record attendance:** Calls Edge Function `record-attendance`. Payload field name is `records` (not `attendance_records`):
```dart
supabase.functions.invoke('record-attendance', body: {
  'activity_id': activityId,
  'records': [{'user_id': uid, 'status': 'attended'}, ...],
})
```

**Domain layer**

`EventCategory` enum: `games`, `outings`, `socialConnect` — maps to DB strings `'games'`, `'outings'`, `'social_connect'`.

`EventType` is a `String?` field on `Event` (not an enum) because values are open-ended within each category (cricket, badminton, coffeeConnect, etc.).

`RsvpStatus` enum: `going`, `notGoing`, `maybe`.

`AttendanceStatus` enum: `attended`, `absent`.

**Presentation layer**

`EventsScreen` — tab bar with four tabs: All / Games / Outings / Social Connect. Each tab is a separate `EventsNotifier.family(category)` to allow independent pagination and filtering without re-fetching all tabs.

`EventDetailScreen` — conditional content sections:
- If `event.status == cancelled`: show cancellation banner, hide RSVP controls
- If `event.eventDate > now`: show RSVP selector + RSVP count + updates + polls (if any)
- If `event.eventDate <= now` (past): hide RSVP selector, show attendance summary

`PollDetailScreen` — live vote percentages via `pollVotesRealtimeProvider(pollId)`. When Realtime fires, re-fetch poll vote counts from PostgREST. Results show as percentage bars per option. After voting, the member's selection is highlighted.

`CreateEventSheet` — two-level category selection: first select category chip (Games / Outings / Social Connect), then select specific type chip within that category. `event_type` defaults to `null` for "Other" selection.

---

### Module 4: Growth (Sprint 4)

**Data layer**

`growth_remote_datasource.dart` — Key patterns:

**Get leaderboard:**
```dart
supabase.from(Table.progressLogs)
  .select('user_id, value, profiles!user_id(id, full_name, avatar_url)')
  .eq('challenge_id', challengeId)
```

Leaderboard aggregation (`SUM(value) GROUP BY user_id ORDER BY total DESC`) is done client-side. At 15–20 participants this is trivial: group by `user_id`, sum `value`, sort descending. A separate `LeaderboardEntry` model holds `userId`, `profile`, `totalValue`, `rank`.

**Log progress (upsert — one entry per user per day):**
```dart
supabase.from(Table.progressLogs)
  .upsert({
    'challenge_id': challengeId,
    'user_id': userId,
    'challenge_participant_id': participantId,
    'log_date': date.toIso8601String().substring(0, 10),
    'value': value,
    'note': note,
  }, onConflict: 'challenge_id,user_id,log_date')
```

**Presentation layer**

`GrowthScreen` — three tabs: Active / My Challenges / Completed.
- Active: all challenges with `status = 'active'`
- My Challenges: filtered to challenges where current user is a participant (join `challenge_participants`)
- Completed: all with `status = 'ended'`

`ChallengeDetailScreen` — sections:
1. Challenge info (title, goal type, dates, creator)
2. Join/Leave button (if active)
3. Log Progress sheet (if joined and active)
4. Leaderboard (live via Realtime)

`GoalTypeSelector` — within `CreateChallengeSheet`: shows Steps / Distance / Duration for Fitness challenges; Custom for Wellness. For Custom, a free-text goal description field appears.

---

### Module 5: Analytics (Sprint 5)

**Data layer**

`analytics_remote_datasource.dart` — Key patterns:

**Get personal analytics:**
```dart
// Latest 12 months of member stats
supabase.from(Table.memberMonthlyStats)
  .select('*')
  .eq('user_id', userId)
  .order('stat_month', ascending: false)
  .limit(12)
```

**Get monthly rankings:**
```dart
supabase.from(Table.memberMonthlyStats)
  .select('user_id, events_attended, recognitions_received, posts_count, composite_score, profiles!user_id(id, full_name, avatar_url)')
  .eq('stat_month', monthIso)
  .order('composite_score', ascending: false)
```

**Get all-time rankings:**
Aggregate `SUM` across all months grouped by `user_id`. PostgREST does not support GROUP BY aggregation directly. Options:
- Use a database view (`all_time_rankings_view`) defined in migrations
- Or: fetch all `member_monthly_stats` and aggregate client-side (acceptable at 15–20 users × 12 months = ≤ 240 rows)

Decision for V1: client-side aggregation. If performance degrades, add a materialized view in a migration.

**Create recognition:** Calls Edge Function `create-recognition`.

**Recognition reactions:** UPSERT on `recognition_reactions` with ON CONFLICT `(recognition_id, user_id)`.

**Presentation layer**

`AnalyticsScreen` — four tabs: Personal / Community / Rankings / Recognition.

`PersonalAnalyticsScreen` — shows current month stats cards (events attended, attendance rate, challenges joined, progress logs, recognitions received/given, posts). Month selector allows viewing previous months from stored `member_monthly_stats` rows.

`CommunityAnalyticsScreen` — community aggregates + `HealthScoreCard`. The health score composite is `0–100` with color coding:
- ≥ 70: `healthScoreHigh` (green)
- 40–69: `healthScoreMedium` (amber)
- < 40: `healthScoreLow` (red)

`RankingsScreen` — Monthly / All-Time toggle. Each ranking entry shows rank number, avatar, name, composite score. Tapping a member navigates to `/profile/:id`.

`RecognitionScreen` — two sub-tabs: Monthly Recognition (this month's recognitions) / Community Wall (all-time, paginated). `GiveRecognitionSheet` is accessible from this screen.

`GiveRecognitionSheet` — recipient search (searches `allProfilesProvider`, excludes system accounts + self), category tag selector (5 values: community_contributor, fitness_champion, wellness_champion, event_champion, most_supportive_manager), message text field (500 char max).

`CategoryTagBadge` — displays the human-readable label for each category_tag value:
| DB value | Display label |
|---|---|
| `community_contributor` | Community Contributor |
| `fitness_champion` | Fitness Champion |
| `wellness_champion` | Wellness Champion |
| `event_champion` | Event Champion |
| `most_supportive_manager` | Most Supportive Manager |

---

### Module 6: Profile (Sprint 1 + Sprint 2)

**Data layer**

`profile_remote_datasource.dart`:
- `getProfileById(id)` — rejects system accounts (`is_system_account = true`); member-facing profile never shows CB
- `getAllMemberProfiles()` — `is_active = true` AND `is_system_account = false` — used for @mention, recognition recipient picker
- `uploadAvatar(userId, imageBytes)` → uploads to `avatars/{userId}/profile.jpg` (overwrite); returns storage path
- `updateNotificationPreferences(prefs)` → PATCH `profiles.notification_preferences` column (JSONB)

`notification_preferences_model.dart` — JSONB column mapped to 9 boolean fields:
```dart
activityReminders / newEvents / pollReminders / recognitionsReceived
newChallenges / challengeReminders / mentions / commentsOnMyPosts / connectBuddyUpdates
```

Default values (all `true`) are applied in the model's `fromJson` using `?? true` so new preference keys added in the future default to enabled without a migration.

**Presentation layer**

`OwnProfileScreen` — own profile display + settings entry points (edit profile, notification preferences, logout). Shows own received recognitions (loaded from `recognition_recipients` join, same data as Analytics recognition wall filtered to this user).

`MemberProfileScreen` — read-only view of another member's profile. Accessed via `/profile/:id`. Shows their recognition history.

`NotificationPreferencesScreen` — 9 toggle switches, one per preference category. Changes saved immediately on toggle (no save button) via PATCH.

---

### Module 7: Admin (Sprint 6)

**Data layer**

`admin_remote_datasource.dart` — Notable:
- `sendInvitation(name, email, phone)` → calls Edge Function `send-invitation`; reads `invite_url` from response; returns it to the caller so the UI can display it for the admin to share
- `getAllMembers()` → `is_system_account = false` (admin sees all including `is_active = false`)
- `getEventsNeedingAttendance()` → past activities where no `event_attendance` rows exist yet

**Presentation layer**

`AdminMembersScreen` — two sections: Active Members + Pending Invitations. Long-press or swipe on member row reveals deactivate/remove actions (with confirm dialog).

`InviteMemberSheet` — name field + email OR phone field (at least one required). On submit: call `send-invitation` Edge Function → display returned `invite_url` in a copy-to-clipboard dialog. Admin then shares the URL manually.

`AdminFlaggedScreen` — list of pending flags with flagged content preview. Each item has Delete and Dismiss action buttons. Calls `resolve-flag` Edge Function.

`AdminAttendanceScreen` — list of past events with no attendance recorded (from `getEventsNeedingAttendance()`). Tapping an event opens `AttendanceRecordingSheet`.

`AttendanceRecordingSheet` — list of all Going RSVPs for the event. Each row has an Attended/Absent toggle. Submit calls `record-attendance` Edge Function with the `records` array.

`AdminConnectBuddyScreen` — read-only list of recent CB posts from the feed. Manual trigger controls for: Welcome (requires member selector), Monthly Highlights, Memory. Calls `post-connect-buddy-message` Edge Function directly.

---

## 6. Notifications Module (Sprint 5)

This is a presentation-only module. No domain or data layers — the notification inbox is read/updated via direct PostgREST calls in `NotificationInboxNotifier`, backed by the shared notification service.

`NotificationInboxNotifier` — `AsyncNotifier<List<NotificationItem>>`:
- On build: fetch all inbox rows for current user, ordered by `created_at DESC`, paginated
- `markAsRead(id)`: PATCH `is_read = true`, `read_at = now()` on single row; optimistic update
- `markAllAsRead()`: PATCH `is_read = true` on all unread rows for current user
- Badge count: derived from `state.value?.where((n) => !n.isRead).length ?? 0`

`notificationRealtimeProvider` — `StreamProvider<void>`:
- Channel: `notifications:inbox:{userId}` — INSERT on `notification_inbox`
- On INSERT: call `ref.invalidate(notificationInboxNotifierProvider)` to refresh the inbox list
- Badge count updates automatically because it is derived from the notifier state

---

## 7. State Management Implementation Guide

### 7.1 Provider Type Selection Rules

| Situation | Provider type |
|---|---|
| Dependency injection (repo, datasource, use case) | `@riverpod` function (auto-dispose) |
| Auth state machine (persists for app lifetime) | `@Riverpod(keepAlive: true)` Notifier |
| List that can be mutated (feed, events, challenges) | `AsyncNotifier` |
| Single item detail, read-only | `FutureProvider.family` |
| Supabase Realtime subscription | `StreamProvider` or `StreamProvider.family` |
| Cross-module global (all profiles for pickers) | `@Riverpod(keepAlive: true)` AsyncNotifier |

### 7.2 Optimistic Update Pattern

```
1. Save snapshot of current AsyncValue state
2. state = AsyncData(optimisticUpdate(currentList))   // immediate UI update
3. final result = await useCase.call(params)
4a. On Right: state = AsyncData(serverConfirmedValue)  // or keep optimistic
4b. On Left:  state = snapshot                         // revert
             showSnackBar(context, failure.message, isError: true)
```

Applied to: post reactions, RSVP changes, poll votes, progress log, recognition reactions.

### 7.3 Invalidation vs Direct State Update

**Use `ref.invalidate(provider)`** when:
- Realtime fires a change (safest — fetches current server state)
- An action creates a new item that needs server-assigned fields (id, created_at)

**Use direct state update** when:
- Optimistic mutations where you have all data client-side
- Mark-as-read (single field change, no server fields needed)

### 7.4 Provider Scoping

All providers are auto-disposed by default (`@riverpod` annotation). `keepAlive: true` is used only for:
- `authNotifierProvider` — must survive screen transitions
- `connectBuddyProfileProvider` — fetch once, reuse across all feed renders
- `allProfilesProvider` — used by @mention, recognition picker, admin; expensive to re-fetch

---

## 8. Supabase Integration Patterns

### 8.1 PostgREST Column Selection

All queries explicitly name columns. No `select('*')` in production.

**Embedded join syntax for FK relationships:**
- `profiles!created_by(id, full_name, avatar_url)` — activities FK
- `profiles!author_id(id, full_name, avatar_url, is_system_account)` — posts FK
- `profiles!giver_id(id, full_name, avatar_url)` — recognitions FK
- `profiles!user_id(id, full_name, avatar_url)` — most user-action tables

### 8.2 Error Translation (Data Layer)

In every repository `impl`:

```dart
try {
  final data = await datasource.operation();
  return Right(entity);
} on PostgrestException catch (e) {
  if (e.code == '401') return Left(AuthFailure(e.message));
  if (e.code == '403') return Left(PermissionFailure(e.message));
  if (e.code == '404' || data == null) return Left(NotFoundFailure(e.message));
  if (e.code == '409') return Left(ConflictFailure(e.message));
  return Left(ServerFailure(e.message));
} on AuthException catch (e) {
  return Left(AuthFailure(e.message));
} on SocketException {
  return Left(NetworkFailure('No internet connection'));
}
```

Edge Function errors (from `supabase.functions.invoke()`) return a `FunctionException`. Map its `status` code the same way.

### 8.3 Auth Failure Global Handling

`AuthNotifier` watches `authStateStreamProvider`. On `AuthChangeEvent.signedOut` or a 401 from any datasource → `state = AuthState.unauthenticated`. The GoRouter redirect then sends to `/welcome`. This is the only logout path — no screen manually calls `context.go('/welcome')`.

### 8.4 Pagination

All list datasources accept `int page` parameter (0-indexed). Offset: `page * AppConstants.paginationPageSize`. Feed and recognition wall use this pattern. Events are not paginated in V1 (bounded set; max ~100 events total).

---

## 9. Code Generation Workflow

Four generated file types — all must be re-run after changes to annotated classes:

```
dart run build_runner build --delete-conflicting-outputs
```

| Annotation | Generator | Output |
|---|---|---|
| `@riverpod` | `riverpod_generator` | `*.g.dart` (provider definitions) |
| `@freezed` | `freezed` | `*.freezed.dart` (immutable classes) |
| `@JsonSerializable` | `json_serializable` | `*.g.dart` (fromJson/toJson) |

Generated files are committed. Rationale: fresh clones work without running `build_runner`; CI does not need a generation step before tests.

When to re-run: after adding/changing any entity, model, or provider. CI should run `build_runner` and fail if generated files are out of date (compare git diff).

---

## 10. Testing Strategy

### 10.1 Unit Tests (Domain Layer)

Target: all use cases and pure utility functions. Use cases receive mock repository implementations via constructor injection. No Flutter widget dependencies.

Key unit test scenarios:
- `CreatePost`: validates content length, image count limit
- `VoteOnPoll`: verifies one-vote constraint is checked before calling repository
- `GetLeaderboard`: client-side SUM aggregation produces correct ranking order
- `GetMonthlyRankings`: correct ordering by composite_score
- `ValidateInviteToken`: expired token returns `Left(ValidationFailure)`

### 10.2 Widget Tests (Presentation Layer)

Target: stateful widgets with complex interaction logic. Use Riverpod `ProviderScope.overrides` to inject mock notifiers.

Key widget test scenarios:
- `VerifyOtpScreen`: 6-digit auto-advance works, paste fills all boxes, resend timer counts down
- `PostCard`: shows delete button for own posts only, not for other users' posts
- `ConnectBuddyPostCard`: shows CB badge, delete button hidden for non-admin
- `PollOptionTile`: live progress bar reflects correct percentage
- `HealthScoreCard`: correct color applied for high/medium/low thresholds

### 10.3 Integration Tests

One integration test file per module. Use local Supabase instance (`supabase start`). Tests run against real database schema — not mocked.

Critical integration test flows (from `development-roadmap.md` Sprint 6 E2E list):
1. Onboarding: validate invite token → OTP → create profile → feed loads → CB welcome post appears
2. Create event (Games/Cricket) → RSVP Going → RSVP count increments
3. Create poll → vote → live percentage visible to second test user
4. Admin records post-event attendance → appears in personal analytics
5. Join challenge → log progress → leaderboard rank changes
6. Give recognition → recipient's analytics updated
7. Admin: send invitation → `invite_url` returned in response → copy confirmed

---

## 11. Sprint-by-Sprint Implementation Order

### Sprint 1: Foundation

**Infrastructure first:**
1. Project init, `analysis_options.yaml`, `build.yaml`, Firebase setup
2. `core/constants/` all files
3. `core/errors/failure.dart`
4. `core/theme/` all files
5. `core/extensions/` all files
6. `shared/providers/supabase_provider.dart`, `auth_state_provider.dart`
7. `shared/services/notification_service.dart` (stub — token registration only; push dispatch in Sprint 5)
8. `shared/widgets/` — all shared widgets

**Auth module:**
9. `auth/data/` — datasource, models, repository
10. `auth/domain/` — entities, use cases
11. `auth/presentation/` — AuthNotifier, Welcome/OTP/CreateProfile screens

**Navigation shell:**
12. `core/router/` — full GoRouter with stubs for each tab screen
13. `shared/widgets/main_scaffold.dart` — NavigationBar (no badges yet)
14. `app.dart`, `main.dart` — wire ProviderScope, Firebase init, Supabase init

**Definition of Done:** Admin can trigger `send-invitation` via Supabase dashboard → invited manager opens link → validates token → OTP → creates profile → lands on Feed tab with placeholder screens.

---

### Sprint 2: Feed Module

1. `shared/providers/connect_buddy_provider.dart`
2. `feed/data/` — datasource (including image upload), models, repository
3. `feed/domain/` — entities, use cases
4. `feed/presentation/providers/` — FeedNotifier, Realtime stream provider
5. `feed/presentation/widgets/` — all feed widgets (PostCard before ConnectBuddyPostCard)
6. `feed/presentation/screens/feed_screen.dart`
7. Profile module (basic — needed for avatar display in posts): `profile/data/`, `profile/domain/`, `profile/presentation/screens/own_profile_screen.dart`

---

### Sprint 3: Events Module

1. `events/data/` — datasource, models, repository
2. `events/domain/` — entities, use cases
3. `events/presentation/providers/` — EventsNotifier (family), PollVotesNotifier, Realtime providers
4. `events/presentation/widgets/` — event and poll widgets
5. `events/presentation/screens/` — EventsScreen, EventDetailScreen, PollDetailScreen, EventHistoryScreen

---

### Sprint 4: Growth Module + Attendance

1. `growth/data/` — datasource (includes client-side leaderboard aggregation), models, repository
2. `growth/domain/` — entities, use cases
3. `growth/presentation/` — all providers, widgets, screens
4. Admin attendance datasource methods + `AdminAttendanceScreen` + `AttendanceRecordingSheet` (admin-facing only; can deploy independently)

---

### Sprint 5: Analytics, Recognition, Connect Buddy, Notifications

1. `analytics/data/` — datasource (includes client-side all-time rankings aggregation), models, repository
2. `analytics/domain/` — entities, use cases
3. `analytics/presentation/` — all providers, widgets, screens (including Recognition screens)
4. `shared/services/notification_service.dart` — complete implementation: foreground display, tap routing, all 15 notification types
5. `features/notifications/presentation/` — inbox notifier, Realtime provider, NotificationsScreen, NotificationTile
6. `shared/widgets/main_scaffold.dart` — add notification badge count to Profile tab
7. Profile notification preferences screen

---

### Sprint 6: Admin Panel, Polish, Testing

1. `admin/data/`, `admin/domain/`, `admin/presentation/` — complete admin module
2. Empty states — add to all list screens
3. Loading skeletons — add to feed, events, analytics screens
4. Error states with retry — all `AsyncValue.when` error: handlers
5. Offline banner (`ConnectivityPlus` stream → show banner when offline)
6. Accessibility review: tap targets ≥ 48×48dp, contrast ratios
7. Unit test suite
8. Widget test suite
9. Integration test suite (local Supabase)
10. Device testing (iOS simulator, Android emulator, real devices)

---

## 12. Known Discrepancies to Fix During Implementation

These are inconsistencies found between existing documentation and the finalized database schema. Fix at the time the affected datasource is implemented.

| Location | Issue | Correct value |
|---|---|---|
| `flutter-architecture.md` (line 460) | PostgREST join uses `profiles!creator_id` for activities | `profiles!created_by` |
| `flutter-architecture.md` (line 481) | Edge Function body uses `attendance_records` key | `records` (per `backend-api-contracts.md`) |
| `flutter-folder-structure.md` (line 79) | `connectBuddySystemAccountId` described as "UUID, seeded" | Add note: matches hardcoded constant `00000000-0000-4000-8000-000000000001` in `_shared/constants.ts` |

---

## Document Cross-References

| Topic | Authoritative Document |
|---|---|
| Flutter folder structure (complete tree) | `flutter-folder-structure.md` |
| Architecture principles, provider types, Realtime patterns | `flutter-architecture.md` |
| Edge Function contracts (request/response shapes) | `backend-api-contracts.md` |
| Backend implementation (Edge Functions, repositories, services) | `backend-implementation-plan.md` |
| Database schema (column names, FK names, CHECK values) | `database-schema-design.md` |
| Notification types, preferences, deep link targets | `notification-strategy.md` |
| Route structure, deep link paths | `flutter-architecture.md` §Navigation Strategy |
| Sprint tasks and Definition of Done | `development-roadmap.md` |
| Feature requirements | `functional-requirements.md` |
