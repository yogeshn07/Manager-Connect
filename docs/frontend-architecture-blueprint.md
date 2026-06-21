# Frontend Architecture Blueprint

**Date:** 2026-06-21
**Stack:** Flutter 3.41.7, Dart 3.11.5, Riverpod 3.0.3, GoRouter 14.1, Supabase Flutter 2.5

---

## 1. Folder Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── config/
│   │   └── env.dart                       # SUPABASE_URL, SUPABASE_ANON_KEY
│   ├── constants/
│   │   ├── app_constants.dart             # Limits, IDs, durations
│   │   ├── interest_tags.dart             # Predefined interest tags
│   │   ├── route_names.dart               # All route path constants
│   │   └── supabase_constants.dart        # Table names, column names
│   ├── errors/
│   │   ├── app_exception.dart             # Typed exception hierarchy
│   │   └── failure.dart                   # Failure sealed class for UI
│   ├── extensions/
│   │   ├── context_extensions.dart        # Theme, navigator shortcuts
│   │   ├── datetime_extensions.dart       # Relative time, formatting
│   │   └── string_extensions.dart         # Truncate, capitalize
│   ├── router/
│   │   ├── app_router.dart                # Route tree definition
│   │   ├── route_guards.dart              # Auth + role-based redirects
│   │   └── router_provider.dart           # @riverpod GoRouter
│   ├── theme/
│   │   ├── app_colors.dart                # Color palette
│   │   ├── app_text_styles.dart           # Typography scale
│   │   ├── app_theme.dart                 # ThemeData factory
│   │   └── app_theme_extensions.dart      # Semantic color tokens
│   └── network/
│       ├── supabase_client_provider.dart   # @riverpod SupabaseClient
│       ├── api_error_handler.dart          # Map Supabase errors → Failure
│       └── connectivity_provider.dart      # Online/offline state
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/                    # Profile DTO, Invitation DTO
│   │   │   └── repositories/
│   │   │       ├── auth_repository.dart   # OTP, session management
│   │   │       └── profile_repository.dart # Profile CRUD
│   │   ├── domain/
│   │   │   └── models/                    # Profile entity, AuthState
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_notifier.dart     # Auth state machine
│   │       ├── screens/
│   │       │   ├── splash_screen.dart
│   │       │   ├── welcome_screen.dart
│   │       │   ├── verify_otp_screen.dart
│   │       │   └── create_profile_screen.dart
│   │       └── widgets/
│   │
│   ├── feed/
│   │   ├── data/
│   │   │   ├── models/                    # PostDto, CommentDto, ReactionDto
│   │   │   └── repositories/
│   │   │       ├── feed_repository.dart   # Posts CRUD, pagination
│   │   │       ├── comment_repository.dart
│   │   │       └── reaction_repository.dart
│   │   ├── domain/
│   │   │   └── models/                    # Post, Comment, Reaction entities
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── feed_provider.dart     # Paginated feed state
│   │       │   └── post_detail_provider.dart
│   │       ├── screens/
│   │       │   ├── feed_screen.dart
│   │       │   ├── create_post_screen.dart
│   │       │   └── post_detail_screen.dart
│   │       └── widgets/
│   │           ├── post_card.dart
│   │           ├── pinned_post_banner.dart
│   │           ├── connect_buddy_badge.dart
│   │           ├── reaction_bar.dart
│   │           └── comment_tile.dart
│   │
│   ├── events/
│   │   ├── data/
│   │   │   ├── models/                    # ActivityDto, RsvpDto, UpdateDto
│   │   │   └── repositories/
│   │   │       ├── activity_repository.dart
│   │   │       ├── rsvp_repository.dart
│   │   │       └── activity_update_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       │   ├── activities_list_screen.dart
│   │       │   ├── activity_detail_screen.dart
│   │       │   ├── create_activity_screen.dart
│   │       │   └── rsvp_list_screen.dart
│   │       └── widgets/
│   │           ├── activity_card.dart
│   │           ├── rsvp_button.dart
│   │           ├── category_filter_chips.dart
│   │           └── update_tile.dart
│   │
│   ├── polls/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   │       └── poll_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       │   ├── poll_list_screen.dart
│   │       │   ├── poll_detail_screen.dart
│   │       │   └── create_poll_screen.dart
│   │       └── widgets/
│   │           ├── poll_card.dart
│   │           ├── poll_option_tile.dart
│   │           └── poll_results_chart.dart
│   │
│   ├── growth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   │       ├── challenge_repository.dart
│   │   │       └── progress_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       │   ├── challenge_list_screen.dart
│   │       │   ├── challenge_detail_screen.dart
│   │       │   ├── create_challenge_screen.dart
│   │       │   └── log_progress_screen.dart
│   │       └── widgets/
│   │           ├── challenge_card.dart
│   │           ├── leaderboard_tile.dart
│   │           └── progress_input.dart
│   │
│   ├── recognition/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   │       └── recognition_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       │   ├── recognition_feed_screen.dart
│   │       │   └── create_recognition_screen.dart
│   │       └── widgets/
│   │           ├── recognition_card.dart
│   │           └── category_badge.dart
│   │
│   ├── notifications/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   │       └── notification_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       │   └── notification_center_screen.dart
│   │       └── widgets/
│   │           └── notification_tile.dart
│   │
│   ├── analytics/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   │       └── analytics_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       │   ├── personal_analytics_screen.dart
│   │       │   ├── community_analytics_screen.dart
│   │       │   └── rankings_screen.dart
│   │       └── widgets/
│   │           ├── stat_card.dart
│   │           ├── health_score_gauge.dart
│   │           └── ranking_tile.dart
│   │
│   ├── profile/
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   │   ├── my_profile_screen.dart
│   │   │   │   ├── edit_profile_screen.dart
│   │   │   │   └── settings_screen.dart
│   │   │   └── widgets/
│   │   │       ├── profile_header.dart
│   │   │       └── notification_pref_tile.dart
│   │   └── (shares auth/data/repositories/profile_repository)
│   │
│   └── admin/
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       │       ├── admin_member_repository.dart
│       │       ├── moderation_repository.dart
│       │       └── admin_event_repository.dart
│       ├── domain/
│       │   └── models/
│       └── presentation/
│           ├── providers/
│           ├── screens/
│           │   ├── admin_dashboard_screen.dart
│           │   ├── member_management_screen.dart
│           │   ├── moderation_queue_screen.dart
│           │   ├── attendance_recording_screen.dart
│           │   └── pin_management_screen.dart
│           └── widgets/
│               ├── member_action_sheet.dart
│               ├── flag_review_card.dart
│               └── attendance_toggle.dart
│
└── shared/
    ├── providers/
    │   ├── supabase_provider.dart          # SupabaseClient singleton
    │   ├── auth_state_provider.dart        # Global auth state stream
    │   └── current_profile_provider.dart   # Logged-in user's profile
    ├── services/
    │   ├── notification_service.dart       # FCM init, token management
    │   ├── deep_link_service.dart          # Notification tap → route
    │   ├── image_upload_service.dart       # Storage upload helper
    │   └── realtime_service.dart           # Channel subscription manager
    ├── models/
    │   └── paginated_list.dart             # Generic pagination wrapper
    └── widgets/
        ├── bottom_nav/
        │   └── main_scaffold.dart          # 5-tab navigation shell
        ├── placeholders/
        │   └── placeholder_screen.dart     # Dev placeholder
        ├── user_avatar.dart                # Cached avatar with fallback
        ├── empty_state.dart                # No-data illustration
        ├── error_state.dart                # Retry-able error display
        ├── loading_state.dart              # Shimmer or spinner
        ├── confirm_dialog.dart             # Destructive action confirmation
        └── toast.dart                      # Snackbar helper
```

---

## 2. State Management — Riverpod 3.x

### Provider Types

| Type | Use Case | Example |
|------|----------|---------|
| `@riverpod` (auto-dispose) | Screen-scoped data, detail views | `postDetailProvider(postId)` |
| `@Riverpod(keepAlive: true)` | App-lifetime state | `authProvider`, `currentProfileProvider` |
| `StreamProvider` | Realtime subscriptions | `feedRealtimeProvider`, `notificationCountProvider` |
| `FutureProvider` | One-shot data fetch | `activityDetailProvider(activityId)` |
| `Notifier` / `AsyncNotifier` | Mutable state with actions | `AuthNotifier`, `FeedNotifier` |

### Provider Architecture

```
Screen (ConsumerWidget)
  └── watches provider
        └── calls repository method
              └── calls Supabase client (REST or Edge Function)
                    └── returns DTO
              └── maps DTO → domain model
        └── returns AsyncValue<T> to screen
```

### Code Generation

- `riverpod_generator` 3.0.3 + `riverpod_annotation` 3.0.3
- `freezed` 3.2.1 for immutable models + sealed unions
- `json_serializable` 6.9.5 for JSON DTOs
- All generated code in `.g.dart` and `.freezed.dart` files
- Run: `dart run build_runner build --delete-conflicting-outputs`

---

## 3. Repository Layer

Each feature module has a repository that:
1. Accepts domain-level parameters (not raw JSON)
2. Calls Supabase client (REST or Edge Function)
3. Maps response to domain model or throws `AppException`
4. Handles pagination via keyset cursor pattern

### Repository Pattern

```dart
@riverpod
FeedRepository feedRepository(Ref ref) {
  return FeedRepository(ref.watch(supabaseClientProvider));
}

class FeedRepository {
  FeedRepository(this._client);
  final SupabaseClient _client;

  Future<List<Post>> getFeed({DateTime? cursor, int limit = 20}) async {
    var query = _client
        .from('posts')
        .select('id,content,author_id,created_at,profiles(full_name,avatar_url,is_system_account)')
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(limit);

    if (cursor != null) {
      query = query.lt('created_at', cursor.toIso8601String());
    }

    final response = await query;
    return response.map((json) => Post.fromJson(json)).toList();
  }
}
```

### Repository Inventory (14 repositories)

| Repository | Feature | Tables | Operations |
|-----------|---------|--------|------------|
| `auth_repository` | auth | auth.users | OTP, session, signOut |
| `profile_repository` | auth/profile | profiles | Get, update, search |
| `feed_repository` | feed | posts, pinned_announcements | Get feed, create post (EF) |
| `comment_repository` | feed | comments | Get, create, soft-delete |
| `reaction_repository` | feed | post_reactions | Upsert, delete |
| `activity_repository` | events | activities, activity_updates | CRUD, cancel (EF), update (EF) |
| `rsvp_repository` | events | activity_rsvps | Upsert, delete, list |
| `poll_repository` | polls | polls, poll_options, poll_votes | CRUD, vote, create (EF) |
| `challenge_repository` | growth | challenges, challenge_participants | CRUD, join, leave |
| `progress_repository` | growth | progress_logs | Upsert, list |
| `recognition_repository` | recognition | recognitions, recognition_recipients, recognition_reactions | Get, create (EF), react |
| `notification_repository` | notifications | notification_inbox | Get, mark read, count |
| `analytics_repository` | analytics | member_monthly_stats, community_health_scores | Get stats, rankings |
| `admin_repository` | admin | flagged_content, invitations, event_attendance | All admin EF calls |

---

## 4. DTO / Model Strategy

### Two-Layer Model

```
Supabase JSON → DTO (data layer, @JsonSerializable) → Domain Model (freezed)
```

- **DTOs** live in `features/<feature>/data/models/`, named `*_dto.dart`
- **Domain models** live in `features/<feature>/domain/models/`, named `*.dart`
- DTOs have `fromJson`/`toJson` (json_serializable)
- Domain models are `@freezed` for immutability + `copyWith`
- Repositories map DTO → domain model internally

### Model Count Estimate

| Feature | DTOs | Domain Models |
|---------|------|---------------|
| auth | 2 (Profile, Invitation) | 2 |
| feed | 3 (Post, Comment, Reaction) | 3 |
| events | 3 (Activity, Rsvp, Update) | 3 |
| polls | 3 (Poll, PollOption, PollVote) | 3 |
| growth | 3 (Challenge, Participant, ProgressLog) | 3 |
| recognition | 3 (Recognition, Recipient, Reaction) | 3 |
| notifications | 1 (NotificationItem) | 1 |
| analytics | 2 (MemberStats, HealthScore) | 2 |
| admin | 2 (FlaggedContent, AuditEntry) | 2 |
| **Total** | **22** | **22** |

---

## 5. Error Handling Strategy

### Exception → Failure Pipeline

```
Supabase throws → Repository catches → maps to AppException → Provider exposes AsyncError → Screen shows error_state widget
```

### AppException Hierarchy

```dart
sealed class AppException implements Exception {
  String get message;
}

class NetworkException extends AppException { ... }
class UnauthorizedException extends AppException { ... }
class ForbiddenException extends AppException { ... }
class NotFoundException extends AppException { ... }
class ConflictException extends AppException { ... }
class ValidationException extends AppException { ... }
class ServerException extends AppException { ... }
```

### HTTP Status Mapping (matches API contracts)

| HTTP | Exception | UI Action |
|------|-----------|-----------|
| 401 | UnauthorizedException | Force logout, redirect to Welcome |
| 403 | ForbiddenException | Toast: "You don't have access" |
| 404 | NotFoundException | Show "Not found" state |
| 409 | ConflictException | Toast with specific message |
| 422 | ValidationException | Show field-level errors |
| 500 | ServerException | Toast: "Something went wrong" |
| Network | NetworkException | Offline banner |

---

## 6. Caching Strategy

### Approach: Riverpod `keepAlive` + `ref.invalidate()`

- **No offline-first persistence.** This is a private community app — always online.
- Riverpod auto-dispose handles short-lived screen data
- `keepAlive: true` for app-level state: auth, current profile, unread notification count
- Pull-to-refresh on list screens calls `ref.invalidate(provider)` to re-fetch
- Optimistic updates for reactions, RSVPs, votes (update UI first, revert on error)

### Image Caching

- `cached_network_image` for avatars and post images
- Supabase Storage signed URLs with 1-hour expiry
- Disk cache managed by the package (auto eviction)

---

## 7. Realtime Strategy

### Architecture

```dart
// shared/services/realtime_service.dart
class RealtimeService {
  final SupabaseClient _client;

  RealtimeChannel subscribeTo(String channelName, String table, {
    required RealtimeListenTypes event,
    String? filter,
    required void Function(Map<String, dynamic>) onPayload,
  }) { ... }

  void unsubscribe(String channelName) { ... }
}
```

### Channel Lifecycle

- Subscribe on screen mount (via `ref.onDispose` in provider)
- Unsubscribe on screen dispose (auto-dispose provider handles this)
- On payload received: update local provider state (append to list, update count)

### Channels (7)

| Channel | Subscribed When | On Payload |
|---------|----------------|------------|
| `feed:posts` | Feed screen visible | Prepend new post to feed list |
| `feed:reactions:{post_id}` | Post detail open | Update reaction count |
| `feed:comments:{post_id}` | Post detail open | Append new comment |
| `activities:rsvps:{activity_id}` | Activity detail open | Update RSVP counts |
| `events:poll_votes:{poll_id}` | Poll detail open | Update vote counts |
| `growth:leaderboard:{challenge_id}` | Challenge detail open | Update leaderboard |
| `notifications:inbox:{user_id}` | App-wide (keepAlive) | Increment unread badge |

---

## 8. Notification Strategy

### Push (FCM)

1. `firebase_messaging` requests permission on first launch
2. On token obtained: PATCH `profiles.push_token` via REST
3. On token refresh: PATCH again
4. Background handler: `firebaseMessagingBackgroundHandler` (already stubbed)
5. Foreground: `flutter_local_notifications` shows banner
6. Tap: `deep_link_service` maps `reference_type` + `reference_id` → GoRouter path

### In-App Inbox

1. `notification_repository.getInbox()` fetches paginated list
2. `notificationCountProvider` (keepAlive) polls unread count or uses Realtime
3. Mark-read on tap: PATCH `notification_inbox` via REST
4. Badge on app bar notification icon

### Deep Link Mapping

| reference_type | Route |
|---------------|-------|
| `activity` | `/event/:id` |
| `challenge` | `/challenge/:id` |
| `recognition` | `/recognition/:id` |
| `poll` | `/event/:id/poll/:pollId` |
| `post` | Post detail (via feed) |
| `user` | `/profile/:id` |

---

## 9. Navigation Architecture

### Shell Structure

```
GoRouter
├── / → redirect to /feed
├── /welcome (auth)
├── /verify-otp (auth)
├── /create-profile (auth)
├── ShellRoute (MainScaffold with 5-tab NavigationBar)
│   ├── /feed
│   ├── /events
│   ├── /growth
│   ├── /analytics
│   └── /profile
├── /event/:id (stack over shell)
├── /event/:id/poll/:pollId
├── /challenge/:id
├── /recognition/:id
├── /profile/:id (member profile)
├── /analytics/ranking
├── /notifications (stack over shell)
├── /admin (stack over shell)
├── /admin/members
├── /admin/flagged
├── /admin/announcements
├── /admin/attendance
└── /admin/connect-buddy
```

### Guards

- **Auth guard:** Unauthenticated → redirect to `/welcome`
- **Profile guard:** Authenticated without profile → redirect to `/create-profile`
- **Admin guard:** Non-admin accessing `/admin/*` → redirect to `/feed`
- **Deactivated guard:** Deactivated user → show access-denied screen, sign out

---

## 10. Estimate Summary

| Metric | Count |
|--------|-------|
| Screens | **34** |
| Feature modules | **10** (auth, feed, events, polls, growth, recognition, notifications, analytics, profile, admin) |
| Repositories | **14** |
| DTOs | **22** |
| Domain models | **22** |
| Riverpod providers | **~40** (list, detail, action, stream per feature) |
| Reusable widgets | **~20** (post_card, activity_card, challenge_card, poll_card, recognition_card, user_avatar, stat_card, empty_state, error_state, loading_state, confirm_dialog, toast, reaction_bar, comment_tile, leaderboard_tile, ranking_tile, category_badge, rsvp_button, notification_tile, health_score_gauge) |
| Realtime channels | **7** |
| Services | **4** (notification, deep_link, image_upload, realtime) |
