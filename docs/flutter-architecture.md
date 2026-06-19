# Flutter Application Architecture

## Overview

Manager Connect is built as a Flutter application targeting iOS and Android from a single Dart codebase. The architecture follows **Clean Architecture** principles — strict layer separation (data, domain, presentation) within each feature module — combined with **Riverpod** for state management, **GoRouter** for navigation, and **Material 3** for design.

The backend is Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions). Flutter communicates with Supabase exclusively through the `supabase_flutter` SDK.

**V1 Theme:** Light mode only. Dark mode is not implemented in V1.

For folder structure detail, see `flutter-folder-structure.md`.

---

## Architecture Diagram

```
┌───────────────────────────────────────────────────────────────────┐
│                     Flutter Application                           │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ Presentation Layer (features/*/presentation/)               │  │
│  │                                                             │  │
│  │   Screens ──► Widgets                                       │  │
│  │      │                                                      │  │
│  │      └──► Riverpod Providers (Notifiers, AsyncNotifiers,    │  │
│  │               StreamProviders)                              │  │
│  └───────────────────────────┬─────────────────────────────────┘  │
│                              │ calls Use Cases                     │
│  ┌───────────────────────────▼─────────────────────────────────┐  │
│  │ Domain Layer (features/*/domain/)                           │  │
│  │                                                             │  │
│  │   Use Cases ──► Repository Interfaces (abstract)            │  │
│  │   Entities (pure Dart, no Flutter)                          │  │
│  │   Failures (sealed class)                                   │  │
│  └───────────────────────────┬─────────────────────────────────┘  │
│                              │ implemented by                      │
│  ┌───────────────────────────▼─────────────────────────────────┐  │
│  │ Data Layer (features/*/data/)                               │  │
│  │                                                             │  │
│  │   Repository Implementations                                │  │
│  │   Remote Data Sources (supabase_flutter calls)              │  │
│  │   Models (JSON ↔ Dart, Freezed + JsonSerializable)          │  │
│  └───────────────────────────┬─────────────────────────────────┘  │
│                              │                                     │
└──────────────────────────────┼─────────────────────────────────────┘
                               │
            ┌──────────────────▼──────────────────┐
            │         Supabase Platform            │
            │  PostgreSQL + RLS + Realtime +        │
            │  Auth + Storage + Edge Functions      │
            └──────────────────────────────────────┘
```

---

## Architectural Layers

### Layer 1: Domain Layer

**Location:** `lib/features/<module>/domain/`

The core of the application. Contains the business model independent of how data is fetched or rendered. This layer has **zero Flutter imports** and **zero Supabase imports**. It is pure Dart.

| Sub-folder | Contents |
|---|---|
| `entities/` | Immutable Dart data classes (Event, Poll, LeaderboardEntry, HealthScore, etc.) |
| `repositories/` | Abstract `interface` classes (repository contracts) |
| `usecases/` | Single-responsibility callable classes orchestrating repository calls |

**Failure model:** All use case results return `Either<Failure, T>` using the `fpdart` package.

```
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure { ... }
class AuthFailure extends Failure { ... }
class ServerFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
class NotFoundFailure extends Failure { ... }
class PermissionFailure extends Failure { ... }
```

---

### Layer 2: Data Layer

**Location:** `lib/features/<module>/data/`

Implements repository interfaces. Handles all Supabase SDK calls, JSON parsing, and error translation.

| Sub-folder | Contents |
|---|---|
| `datasources/` | `*RemoteDatasource` classes with Supabase SDK calls |
| `models/` | DTO classes with `fromJson`/`toJson` (Freezed + JsonSerializable) |
| `repositories/` | Concrete implementations returning `Either<Failure, T>` |

**Rule:** Data sources throw typed exceptions. Repositories catch and map to domain `Failure` types. Repositories never throw — they return `Left(failure)`.

---

### Layer 3: Presentation Layer

**Location:** `lib/features/<module>/presentation/`

Flutter UI wired to the domain layer via Riverpod providers.

| Sub-folder | Contents |
|---|---|
| `providers/` | Riverpod providers and Notifiers for this feature |
| `screens/` | Full-page screen widgets routed by GoRouter |
| `widgets/` | Feature-specific reusable widget components |

**Dependency direction:** Screens → Providers → Use Cases → Repositories. No layer skips another.

---

### Layer 4: Core Layer

**Location:** `lib/core/`

Shared infrastructure. No feature logic.

| Sub-folder | Contents |
|---|---|
| `router/` | GoRouter definition, guards, route name constants |
| `theme/` | Material 3 ThemeData (light only), color tokens, text styles, ThemeExtensions |
| `errors/` | Failure sealed class, AppException |
| `constants/` | App-wide constants, Supabase table/bucket names, route names |
| `extensions/` | Dart extension methods (DateTime, String, BuildContext) |
| `utils/` | Pure utility functions (date formatting, image compression, validation) |

---

## Module Organization

Six feature modules, each a self-contained vertical slice.

```
┌──────────┐  ┌──────────┐  ┌──────────┐
│   auth   │  │   feed   │  │  events  │
└──────────┘  └──────────┘  └──────────┘
┌──────────┐  ┌──────────┐  ┌──────────┐
│  growth  │  │analytics │  │ profile  │
└──────────┘  └──────────┘  └──────────┘
┌──────────┐
│  admin   │
└──────────┘
                    ▲
          ┌─────────┴────────┐
          │  notifications   │  ← shared infrastructure
          │  (cross-cutting) │
          └──────────────────┘
          ┌──────────────────┐
          │  connect_buddy   │  ← system account service
          │  (cross-cutting) │
          └──────────────────┘
```

### Module Ownership

| Module | Owns |
|---|---|
| auth | Auth screens, session management |
| feed | Posts, reactions, comments, mentions, pinned posts, Connect Buddy post rendering |
| events | Event categories (games/outings/social_connect), polls, RSVP, attendance |
| growth | Fitness challenges, wellness challenges, progress logs, leaderboard |
| analytics | Personal analytics, community analytics, health score, rankings, recognition |
| profile | Own profile, member profiles, notification preferences |
| admin | Member management, moderation, announcements, Connect Buddy management, attendance recording |

### Connect Buddy Integration

Connect Buddy is a system profile in the database (`is_system_account = true`). On the Flutter side:
- Connect Buddy posts appear in the Feed as regular posts, rendered with a distinct system badge
- `connectBuddyProfileProvider` holds the system account profile for display purposes
- The Feed identifies Connect Buddy posts by checking `post.author.isSystemAccount`
- Scheduled Edge Functions generate Connect Buddy content — no Flutter code authors CB posts directly

---

## State Management Strategy (Riverpod)

### Provider Types and Their Roles

**1. `Provider` — Dependency injection**

```
supabaseClientProvider              → SupabaseClient singleton
[feature]RepositoryProvider         → Repository instance (reads supabaseClient)
[useCase]Provider                   → Use case instance (reads repository)
connectBuddyProfileProvider         → Profile entity for the CB system account
```

**2. `NotifierProvider` — Synchronous mutable state**

```
authNotifierProvider                → AuthState (session, current user, role)
```

**3. `AsyncNotifierProvider` — Server data with async lifecycle**

```
feedPostsNotifierProvider           → AsyncValue<List<Post>> + create/delete mutations
eventsNotifierProvider              → AsyncValue<List<Event>> + create/cancel
pollsNotifierProvider               → AsyncValue<List<Poll>> + createPoll, vote
growthChallengesNotifierProvider    → AsyncValue<List<Challenge>> + join/leave/logProgress
analyticsPersonalProvider           → AsyncValue<PersonalAnalytics>
analyticsCommunityProvider          → AsyncValue<CommunityAnalytics>
communityHealthScoreProvider        → AsyncValue<HealthScore>
monthlyRankingsProvider             → AsyncValue<List<RankingEntry>>
allTimeRankingsProvider             → AsyncValue<List<RankingEntry>>
monthlyRecognitionProvider          → AsyncValue<List<Recognition>>
communityRecognitionProvider        → AsyncValue<List<Recognition>>
notificationInboxProvider           → AsyncValue<List<NotificationItem>>
```

**4. `StreamProvider` — Supabase Realtime subscriptions**

```
feedRealtimeProvider                → Stream<void> (new posts → invalidate feed)
pollVotesRealtimeProvider           → Stream<void> per pollId (live vote counts)
eventRsvpRealtimeProvider           → Stream<void> per eventId (RSVP count updates)
challengeLeaderboardRealtimeProvider → Stream<void> per challengeId
notificationRealtimeProvider        → Stream<void> (inbox badge count)
```

**5. `FutureProvider` — One-shot reads**

```
memberProfileProvider(id)           → FutureProvider.family<Profile, String>
eventDetailProvider(id)             → FutureProvider.family<Event, String>
challengeDetailProvider(id)         → FutureProvider.family<Challenge, String>
recognitionDetailProvider(id)       → FutureProvider.family<Recognition, String>
adminMetricsProvider                → FutureProvider<AdminMetrics>
```

### State Invalidation Pattern

When a mutation succeeds, the notifier invalidates dependent providers via `ref.invalidate()` or updates state directly with `state = AsyncData(updatedList)`.

Optimistic update flow:
```
1. Capture current state snapshot
2. Immediately update state with optimistic value
3. Await server call
4. On success: retain (or replace with server value)
5. On failure: revert to snapshot + show error SnackBar
```

### Code Generation

All providers use `@riverpod` annotation from `riverpod_annotation` with `build_runner`. This gives compile-time safety on `ref.watch()` / `ref.read()` calls and eliminates boilerplate.

---

## Navigation Strategy (GoRouter)

### Route Structure

```
/                           → redirect to /feed (auth) or /welcome (no auth)

Auth Group (unauthenticated only):
  /welcome                  → WelcomeScreen
  /verify-otp               → VerifyOtpScreen
  /create-profile           → CreateProfileScreen

App Group (authenticated — ShellRoute with 5-tab bottom nav):
  /feed                     → FeedScreen (tab 1)
  /events                   → EventsScreen (tab 2)
  /growth                   → GrowthScreen (tab 3)
  /analytics                → AnalyticsScreen (tab 4)
  /profile                  → OwnProfileScreen (tab 5)

Stack routes (push on top of any tab):
  /event/:id                → EventDetailScreen
  /event/:id/poll/:pollId   → PollDetailScreen
  /challenge/:id            → ChallengeDetailScreen
  /recognition/:id          → RecognitionDetailScreen
  /analytics/ranking        → FullRankingsScreen
  /profile/:id              → MemberProfileScreen
  /notifications            → NotificationsScreen

Admin Group (authenticated + role == 'admin'):
  /admin                    → AdminOverviewScreen
  /admin/members            → AdminMembersScreen
  /admin/flagged            → AdminFlaggedScreen
  /admin/announcements      → AdminAnnouncementsScreen
  /admin/attendance         → AdminAttendanceScreen
  /admin/connect-buddy      → AdminConnectBuddyScreen
```

### Route Guards

Three guard outcomes evaluated in `redirect`:
1. No session → `/welcome`
2. Session + `onboarding_completed = false` → `/create-profile`
3. Admin route + `role != 'admin'` → `/feed`

`GoRouterRefreshStream` connected to auth state stream — router re-evaluates on login/logout/deactivation automatically.

### ShellRoute (Bottom Navigation)

Five-tab `NavigationBar` (Material 3) rendered by `MainScaffold`:

| Tab | Route | Badge |
|---|---|---|
| Feed | `/feed` | New unread Connect Buddy posts indicator |
| Events | `/events` | Upcoming event in next 24h indicator |
| Growth | `/growth` | Active challenge count |
| Analytics | `/analytics` | — |
| Profile | `/profile` | Notification bell count |

### Deep Links

All push notification taps deep-link via GoRouter:

| Notification Type | GoRouter Path |
|---|---|
| New event created | `/events` |
| Event reminder (24h or 1h) | `/event/:id` |
| Event cancelled | `/event/:id` |
| Event updated | `/event/:id` |
| Poll created / Poll reminder | `/event/:id/poll/:pollId` |
| New recognition received | `/recognition/:id` |
| New challenge created | `/growth` |
| Challenge ending soon | `/challenge/:id` |
| Challenge ended | `/challenge/:id` |
| @mention in post | `/feed` |
| Comment on own post | `/feed` |
| Connect Buddy post | `/feed` |
| Admin: flagged content | `/admin/flagged` |
| Admin: new member registered | `/admin/members` |

---

## Theme Strategy (Material 3 — Light Mode Only)

### Foundation

Material 3 is enabled via `useMaterial3: true`. V1 supports **light mode only**. `ThemeMode` is hardcoded to `ThemeMode.light` in `app.dart` — there is no user-facing theme toggle and no dark theme defined.

### Seed Color

One seed color drives the entire color system:

```dart
abstract class AppColors {
  static const Color brandSeed = Color(0xFF006B5F); // Teal
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningAmber = Color(0xFFF57F17);
  static const Color dangerRed    = Color(0xFFC62828);
}
```

`ColorScheme.fromSeed(seedColor: AppColors.brandSeed, brightness: Brightness.light)` generates the full tonal palette.

### Component Overrides (Applied Globally)

| Component | Override |
|---|---|
| `CardTheme` | 12px border radius, slightly elevated |
| `NavigationBarTheme` | Brand-tinted indicator |
| `FloatingActionButtonTheme` | Primary container color |
| `InputDecorationTheme` | Outlined style, consistent 12px border radius |
| `AppBarTheme` | Elevation 0, no center title |
| `BottomSheetTheme` | 24px top corner radius, drag handle |
| `SnackBarTheme` | Floating behavior, margin applied |
| `ChipTheme` | Used for event categories, interest tags, category badges |

### ThemeExtension

Custom tokens not in Material 3 roles:

```dart
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color successColor;
  final Color warningColor;
  final Color dangerColor;
  final Color rsvpGoingColor;
  final Color rsvpMaybeColor;
  final Color rsvpNotGoingColor;
  final Color attendedColor;
  final Color absentColor;
  final Color connectBuddyBadgeColor;
  final Color pinnedPostBackground;
  final Color healthScoreHigh;
  final Color healthScoreMedium;
  final Color healthScoreLow;
}
```

Access via: `Theme.of(context).extension<AppThemeExtension>()!`

### App Configuration

```dart
// app.dart
MaterialApp.router(
  routerConfig: ref.watch(appRouterProvider),
  theme: AppTheme.light,     // only theme — no darkTheme parameter
  themeMode: ThemeMode.light, // hardcoded
)
```

---

## Dependency Injection Strategy

All dependencies flow through the Riverpod provider graph. No service locator.

### Dependency Graph (per feature)

```
supabaseClientProvider                         (core/shared — Level 0)
       ↓
[Feature]RemoteDatasourceProvider              (data — Level 1)
       ↓
[Feature]RepositoryProvider                    (data — Level 2)
       ↓
[UseCase]Provider                              (domain — Level 3)
       ↓
[Feature]NotifierProvider                      (presentation — Level 4)
       ↓
Screen (ref.watch / ref.read)                  (presentation — Level 5)
```

### Testability via Riverpod Overrides

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      eventsRepositoryProvider.overrideWithValue(MockEventsRepository()),
    ],
    child: const MaterialApp(home: EventsScreen()),
  ),
);
```

---

## Supabase Integration Points

### Authentication

`supabase.auth.onAuthStateChange` stream → `StreamProvider<AuthState>` → single source of truth. Tokens stored in iOS Keychain / Android Keystore by `supabase_flutter` using `flutter_secure_storage` internally.

### Data Operations (PostgREST)

Standard CRUD via `supabase.from(table)` in data sources. Events use `event_category` filter:

```dart
// Get Games events only
supabase.from('activities')
  .select('*, profiles!creator_id(id, full_name, avatar_url), activity_rsvps(count)')
  .eq('event_category', 'games')
  .eq('status', 'active')
  .gte('event_date', DateTime.now().toIso8601String())
  .order('event_date', ascending: true);
```

### Edge Functions

Server-side operations:

```dart
await supabase.functions.invoke('create-poll', body: {
  'activity_id': activityId,
  'question': question,
  'options': options,
  'closes_at': closesAt.toIso8601String(),
});

await supabase.functions.invoke('record-attendance', body: {
  'activity_id': activityId,
  'attendance_records': [
    {'user_id': userId, 'status': 'attended'},
    ...
  ],
});
```

### Realtime

Minimal-scope subscriptions per screen:

```dart
@riverpod
Stream<void> pollVotesRealtimeStream(PollVotesRealtimeStreamRef ref, String pollId) {
  final supabase = ref.watch(supabaseClientProvider);
  final controller = StreamController<void>.broadcast();
  
  final channel = supabase
    .channel('events:poll_votes:$pollId')
    .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'poll_votes',
      filter: PostgresChangeFilter(type: FilterType.eq, column: 'poll_id', value: pollId),
      callback: (_) => controller.add(null),
    )
    .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
}
```

---

## Push Notifications

Handled in `shared/services/notification_service.dart`.

**Token registration:** On auth, request FCM/APNs permission → get FCM token → update `profiles.push_token` if changed.

**Foreground notifications:** Displayed via `flutter_local_notifications`.

**Notification tap handling:**
```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final targetScreen = message.data['targetScreen'] as String?;
  if (targetScreen != null) context.go(targetScreen);
});
```

**Handled notification types (all 15 NotificationType enum values):**

| Type | targetScreen |
|---|---|
| `activity_created` | `/events` |
| `activity_reminder_24h` | `/event/:id` |
| `activity_reminder_1h` | `/event/:id` |
| `activity_cancelled` | `/event/:id` |
| `activity_updated` | `/event/:id` |
| `poll_reminder` | `/event/:id/poll/:pollId` |
| `recognition_received` | `/recognition/:id` |
| `challenge_created` | `/growth` |
| `challenge_ending` | `/challenge/:id` |
| `challenge_ended` | `/challenge/:id` |
| `mention` | `/feed` |
| `comment_on_post` | `/feed` |
| `connect_buddy_update` | `/feed` |
| `admin_flag` | `/admin/flagged` |
| `admin_member_registered` | `/admin/members` |

---

## Error Handling Strategy

- **Domain layer:** Use cases return `Either<Failure, T>`
- **Data layer:** Repositories catch `PostgrestException` / `AuthException` → map to `Failure`
- **Presentation layer:** `AsyncValue.when(data:, loading:, error:)` for all async states
- **Mutations:** Notifier catches failures, shows `SnackBar` via `context.showSnackBar()`
- **Global:** `ErrorWidget.builder` override in `main.dart` for production builds

---

## Offline and Caching Strategy

Riverpod `AsyncNotifierProvider` caches data in memory for the app session. No persistent disk cache in V1.

- **Offline read:** Cached provider data from current session remains visible
- **Offline write:** Mutations fail with `NetworkFailure` — shown to user
- **Reconnect:** `ConnectivityPlus` stream in app root triggers `ref.invalidate()` on key providers

---

## Package Dependency Summary

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `riverpod_annotation` | Code generation annotations |
| `riverpod_generator` (dev) | Riverpod code generator |
| `go_router` | Navigation and deep links |
| `supabase_flutter` | Supabase client (auth, DB, storage, realtime) |
| `freezed_annotation` | Immutable data classes |
| `freezed` (dev) | Freezed code generator |
| `json_annotation` | JSON serialization |
| `json_serializable` (dev) | JSON code generator |
| `build_runner` (dev) | Runs all code generation |
| `fpdart` | `Either` type for Result pattern |
| `firebase_messaging` | FCM push notifications |
| `flutter_local_notifications` | Foreground notification display |
| `firebase_core` | Firebase initialization |
| `cached_network_image` | CDN image caching |
| `image_picker` | Camera and gallery image selection |
| `image` | Client-side image compression |
| `intl` | Date and number formatting |
| `connectivity_plus` | Network state detection |
| `flutter_test` (dev) | Widget testing |
| `mocktail` (dev) | Mock generation for tests |
