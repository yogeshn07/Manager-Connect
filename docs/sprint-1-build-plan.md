# Sprint 1 Build Plan — Manager Connect

## Overview

Sprint 1 delivers a working application from zero to a live community feed. A new manager can receive an invitation, authenticate via OTP, complete their profile, and see the community feed with posts and Connect Buddy content. This is the foundation everything else builds on.

**Duration:** 10 working days (2 weeks)
**Scope:** Project setup + Database foundation + Core Flutter infrastructure + Auth module + Feed module
**End State:** Working app with invite-only auth, profile creation, 5-tab navigation shell, and live community feed

---

## Scope Boundary

**In scope (this sprint):**
- Flutter project, Supabase project, Firebase project initialization
- All 26 database tables + RLS + triggers + indexes (full schema deployed once, not per-sprint)
- Storage buckets (avatars, post-images)
- Backend shared infrastructure (`_shared/`)
- Backend Edge Functions: `validate-invite-token`, `send-invitation`, `create-profile`, `create-post`, `post-connect-buddy-message`
- Core Flutter layer (constants, errors, theme, extensions, router, shared widgets)
- Auth feature module (data, domain, presentation — Welcome, OTP, Create Profile)
- Feed feature module (data, domain, presentation — Feed screen, post cards, reactions, comments, mentions)
- Profile module (basic — own profile screen, member profile, all-profiles provider)
- Navigation shell (5-tab bottom nav with placeholder screens for Events, Growth, Analytics)
- Connect Buddy welcome post on new member registration

**Out of scope:**
- Events, Growth, Analytics, Admin, Notifications modules (Sprint 2+)
- Push notification dispatch (stub only — token registration, no server dispatch)
- Calendar view, image upload in events, attendance recording

---

## Dependency Map

```
Phase 1: Project Setup ──────────────────────────────────────────────┐
  Flutter project init                                               │
  Supabase project init                                              │
  Firebase project init                                              │
  Git repository + CI                                                │
  Environment configuration                                          │
                                                                     │
Phase 2: Database + Backend ─────────────────────────────────────────┤
  Database migrations (all 68 files) ← needs Supabase project       │
  Storage buckets ← needs Supabase project                          │
  seed.sql (Connect Buddy) ← needs profiles table                   │
  _shared/ infrastructure ← needs Supabase project                  │
  Edge Functions: auth (3) ← needs _shared/ + migrations            │
  Edge Functions: feed (2) ← needs _shared/ + migrations            │
                                                                     │
Phase 3: Core Flutter + Auth ────────────────────────────────────────┤
  core/constants/ ← needs Phase 1                                   │
  core/errors/ ← needs nothing                                      │
  core/theme/ ← needs nothing                                       │
  core/extensions/ ← needs nothing                                  │
  shared/providers/ ← needs Supabase initialized                    │
  shared/widgets/ ← needs theme                                     │
  shared/services/ (stub) ← needs Firebase initialized              │
  core/router/ ← needs auth providers                               │
  app.dart + main.dart ← needs all of above                         │
  Auth module (data → domain → presentation) ← needs core + router  │
                                                                     │
Phase 4: Feed Module ────────────────────────────────────────────────┘
  Connect Buddy provider ← needs shared/providers                   
  Feed module (data → domain → presentation) ← needs core + auth   
  Profile module (basic) ← needs core                               
  Post creation + mentions ← needs Feed data + Profile provider     
  Realtime subscription ← needs Supabase Realtime channel           
```

---

## Phase 1: Project Setup (Days 1–2)

### Milestone 1.1: Flutter Project Initialization (Day 1, Morning)

**Tasks:**
1. Create Flutter project: `flutter create manager_connect --org com.managerconnect --platforms ios,android`
2. Delete default template files (`test/widget_test.dart`, default `lib/main.dart` stub)
3. Create `analysis_options.yaml` with strict lint rules
4. Create `build.yaml` for code generation (riverpod_generator, freezed, json_serializable)
5. Add all dependencies to `pubspec.yaml` (exact versions from `flutter-folder-structure.md`)
6. Run `flutter pub get` — verify clean dependency resolution
7. Create folder skeleton matching `flutter-folder-structure.md`:
   - `lib/core/constants/`, `lib/core/errors/`, `lib/core/theme/`, `lib/core/extensions/`, `lib/core/router/`
   - `lib/shared/providers/`, `lib/shared/services/`, `lib/shared/widgets/`
   - `lib/features/auth/`, `lib/features/feed/`, `lib/features/events/`, `lib/features/growth/`, `lib/features/analytics/`, `lib/features/profile/`, `lib/features/admin/`, `lib/features/notifications/`
   - `assets/fonts/Inter/`, `assets/images/`, `assets/icons/`
8. Add Inter font files (Regular, Medium, SemiBold, Bold) to `assets/fonts/Inter/`
9. Run `flutter analyze` — verify zero issues

**Definition of Done:**
- `flutter analyze` passes with zero issues
- `flutter pub get` resolves all dependencies
- Folder structure matches `flutter-folder-structure.md`
- Project runs on iOS simulator and Android emulator (shows default empty app)

---

### Milestone 1.2: Supabase Project Initialization (Day 1, Afternoon)

**Tasks:**
1. Install Supabase CLI (`npm install -g supabase`)
2. Initialize local Supabase project: `supabase init`
3. Create Supabase cloud project (dev environment) via Supabase Dashboard
4. Link local project to cloud: `supabase link --project-ref <ref>`
5. Start local Supabase stack: `supabase start` — verify all services running (PostgreSQL, Auth, Storage, Realtime, Edge Functions)
6. Record local credentials (anon key, service role key, URL) in `.env.local` (gitignored)
7. Verify PostgREST is accessible: `curl http://localhost:54321/rest/v1/`

**Definition of Done:**
- `supabase start` runs successfully with all services healthy
- Local Supabase dashboard accessible at `http://localhost:54323`
- Cloud project created and linked

---

### Milestone 1.3: Firebase + Git + Environment Configuration (Day 2)

**Tasks:**
1. Create Firebase project (`manager-connect-dev`)
2. Register iOS app (bundle ID) and Android app (package name)
3. Download `GoogleService-Info.plist` → `ios/Runner/`
4. Download `google-services.json` → `android/app/`
5. Enable FCM in Firebase Console
6. Initialize Git repository with `.gitignore` (include Firebase config files, Supabase `.env.local`, generated `*.g.dart` and `*.freezed.dart` files in committed set)
7. Create initial commit with project skeleton
8. Set up GitHub repository with branch protection on `main` (require PR, no force push)
9. Create `.github/workflows/ci.yml` for basic CI: `flutter analyze` + `flutter test` on push
10. Create launch configurations for `--dart-define` environment variables (dev Supabase URL + anon key)
11. Verify `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` launches on emulator

**Definition of Done:**
- Firebase project created, FCM enabled
- Git repo initialized, pushed to GitHub, CI green
- App launches with `--dart-define` environment configuration
- No secrets in committed code

---

## Phase 2: Database + Backend (Days 3–5)

### Milestone 2.1: Database Schema Deployment (Day 3)

**Tasks:**
1. Create all 68 migration files using `supabase migration new <name>` for each
2. Write SQL for Phase 0: Foundation (migrations #1–3)
   - Enable extensions (`uuid-ossp`, `pgcrypto`)
   - Create `update_updated_at_column()` trigger function
   - Create `is_admin()` helper function with `SECURITY DEFINER`
3. Write SQL for Phase 1: Identity Layer (migrations #4–9)
   - `profiles` table + RLS policies + `updated_at` trigger
   - `invitations` table + RLS policies + `updated_at` trigger
4. Write SQL for Phase 2: Feed Layer (migrations #10–21)
   - `posts` table + RLS + trigger
   - `post_images` table + RLS
   - `post_reactions` table + RLS
   - `comments` table + RLS + trigger
   - `post_mentions` table + RLS
5. Write SQL for Phase 3–8: Events, Growth, Recognition, Analytics, Notifications, Admin (migrations #22–68)
   - All remaining 47 migration files for the full 26-table schema
6. Apply all migrations to local: `supabase db push`
7. Verify all 26 tables exist: `supabase db dump --schema public`
8. Run `seed.sql` to create Connect Buddy system profile
9. Verify Connect Buddy profile exists: query `profiles WHERE is_system_account = true`

**Rationale for deploying ALL tables now:** Deploying the full schema in one pass avoids migration ordering issues in later sprints and ensures FK dependencies are satisfied. Tables not yet used by the app are inert — RLS blocks all client access, and no Edge Functions write to them yet.

**Definition of Done:**
- All 68 migrations applied to local Supabase without errors
- 26 tables visible in Supabase dashboard with RLS enabled on each
- Connect Buddy profile seeded (id = `00000000-0000-4000-8000-000000000001`)
- `is_admin()` helper function returns expected values
- `update_updated_at_column()` trigger fires on profile UPDATE

---

### Milestone 2.2: Storage Buckets (Day 3, alongside 2.1)

**Tasks:**
1. Create `avatars` bucket — public read, authenticated write (owner only)
2. Create `post-images` bucket — authenticated read, authenticated write (owner only)
3. Configure bucket policies in migration or Supabase Dashboard
4. Verify upload and read from each bucket using Supabase CLI or curl

**Definition of Done:**
- Both buckets exist in local Supabase Storage
- Upload + download works for authenticated user
- Public URL works for `avatars` bucket

---

### Milestone 2.3: Backend Shared Infrastructure (Day 4, Morning)

**Tasks:**
1. Create `supabase/functions/_shared/constants.ts`
   - `CONNECT_BUDDY_PROFILE_ID = '00000000-0000-4000-8000-000000000001'`
2. Create `supabase/functions/_shared/supabase-client.ts`
   - `createAdminClient()` (service role) and `createUserClient(jwt)` factories
3. Create `supabase/functions/_shared/cors.ts`
   - CORS headers factory for all responses
4. Create `supabase/functions/_shared/errors.ts`
   - `AppError` class, `toErrorResponse()` serializer
5. Create `supabase/functions/_shared/auth.ts`
   - `requireAuth(req)`, `requireAdmin(userId, client)`, `requireServiceRole(req)` guards
6. Create `supabase/functions/_shared/crypto.ts`
   - `hashToken(rawToken)` using Web Crypto SHA-256
7. Create `supabase/functions/_shared/types.ts`
   - Shared TypeScript interfaces matching database schema
   - `NotificationType` enum (15 values)
   - Request/response DTOs for each Edge Function
8. Create `supabase/functions/_shared/validators/auth.validators.ts`
   - Validate `send-invitation` input (name required, at least one of email/phone)
   - Validate `validate-invite-token` input (token required, UUID format)
   - Validate `create-profile` input (token, full_name required, bio max 300)
9. Create `supabase/functions/_shared/validators/feed.validators.ts`
   - Validate `create-post` input (content min 1 char, images max 4)
10. Create `supabase/functions/_shared/repositories/profiles.repository.ts`
11. Create `supabase/functions/_shared/repositories/invitations.repository.ts`
12. Create `supabase/functions/_shared/repositories/posts.repository.ts`
13. Create `supabase/functions/_shared/repositories/post-mentions.repository.ts`
14. Create `supabase/functions/_shared/repositories/connect-buddy.repository.ts`
15. Create `supabase/functions/_shared/services/audit.service.ts`
16. Create `supabase/functions/_shared/services/notification.service.ts` (stub — logs to console, no actual push dispatch yet)

**Definition of Done:**
- All `_shared/` files compile with `deno check`
- `hashToken()` returns consistent SHA-256 hex digest
- `createAdminClient()` returns a valid SupabaseClient
- Repository functions execute against local Supabase (unit tested manually via curl)

---

### Milestone 2.4: Auth Edge Functions (Day 4, Afternoon)

**Tasks:**
1. Create `supabase/functions/validate-invite-token/index.ts` + `use-case.ts`
   - Hash raw token → find by hash → check status pending → check not expired → return invitation metadata
2. Create `supabase/functions/send-invitation/index.ts` + `use-case.ts`
   - requireAdmin → validate input → check no pending invite for contact → generate UUID token → hash → insert invitation → write audit entry → return invite_url
3. Create `supabase/functions/create-profile/index.ts` + `use-case.ts`
   - requireAuth → re-validate invite token → check no existing profile → insert profile → update invitation status to accepted → return profile_id
4. Deploy all three functions to local: `supabase functions serve`
5. Test end-to-end flow via curl:
   - Call `send-invitation` with admin JWT → get invite_url
   - Call `validate-invite-token` with raw token → get invitation metadata
   - Create a Supabase auth user via OTP flow
   - Call `create-profile` with new user JWT + token → get profile_id
   - Verify profile exists in database, invitation status = accepted

**Definition of Done:**
- All 3 Edge Functions respond correctly to valid and invalid inputs
- Full invitation → registration flow works end-to-end via curl against local Supabase
- Error cases return proper HTTP status codes and error envelope
- Audit log entry created for `send-invitation`

---

### Milestone 2.5: Feed Edge Functions (Day 5, Morning)

**Tasks:**
1. Create `supabase/functions/create-post/index.ts` + `use-case.ts`
   - requireAuth → validate content → insert post → if images: insert post_images → parse @mentions → insert post_mentions → (stub) notify mentioned users
2. Create `supabase/functions/post-connect-buddy-message/index.ts` + `use-case.ts`
   - requireServiceRole → get CB system profile ID → insert post as CB → if notify_all: (stub) dispatch notifications
3. Deploy and test:
   - Create post with authenticated user → verify post in database
   - Create post with @mention → verify post_mentions row exists
   - Call post-connect-buddy-message → verify CB-authored post exists
4. Wire `create-profile` to trigger `post-connect-buddy-message` with welcome content

**Definition of Done:**
- `create-post` creates post with images and mentions parsed correctly
- `post-connect-buddy-message` creates post authored by Connect Buddy system profile
- New profile creation triggers a Connect Buddy welcome post
- All flows verified via curl against local Supabase

---

### Milestone 2.6: Deploy Backend to Cloud Dev (Day 5, Afternoon)

**Tasks:**
1. Push all migrations to cloud dev: `supabase db push --linked`
2. Run seed.sql on cloud dev
3. Deploy Edge Functions to cloud dev: `supabase functions deploy`
4. Verify all functions accessible from cloud dev URL
5. Test the full auth flow against cloud dev project
6. Record cloud dev Supabase URL and anon key for Flutter `--dart-define`

**Definition of Done:**
- Cloud dev Supabase matches local: 26 tables, RLS, 5 Edge Functions, 2 storage buckets, CB profile
- Full auth + post creation flow works against cloud dev

---

## Phase 3: Core Flutter Infrastructure + Auth (Days 6–8)

### Milestone 3.1: Core Constants + Errors + Extensions (Day 6, Morning)

**Tasks:**
1. `lib/core/constants/app_constants.dart`
   - `paginationPageSize: 20`, `maxPostImageCount: 4`, `maxPostContentLength: 1000`, `maxBioLength: 300`, `inviteTokenExpiryHours: 72`, `connectBuddySystemAccountId`
2. `lib/core/constants/supabase_constants.dart`
   - All `Table.*` string constants (26 tables), `Bucket.*` constants (2 buckets)
3. `lib/core/constants/route_names.dart`
   - All `RouteNames.*` constants (22 routes)
4. `lib/core/constants/interest_tags.dart`
   - Predefined interest tag list
5. `lib/core/errors/failure.dart`
   - Sealed class: `NetworkFailure`, `AuthFailure`, `ServerFailure`, `ValidationFailure`, `NotFoundFailure`, `PermissionFailure`, `ConflictFailure`
6. `lib/core/errors/app_exception.dart`
   - Data-layer exception base class
7. `lib/core/extensions/datetime_extensions.dart`
   - `.toDisplayDate()`, `.toDisplayTime()`, `.toRelative()`, `.isToday`, `.isTomorrow`, `.isPast`
8. `lib/core/extensions/string_extensions.dart`
   - `.capitalize()`, `.truncate(max)`, `.initials()`
9. `lib/core/extensions/context_extensions.dart`
   - `.theme`, `.colorScheme`, `.textTheme`, `.screenWidth`, `.screenHeight`, `.showSnackBar()`, `.showMcBottomSheet()`, `.appThemeExtension`
10. Run `flutter analyze` — zero issues

**Definition of Done:**
- All constant files compile and are importable
- All extension methods have correct signatures
- Failure sealed class has exhaustive `when` switch support
- `flutter analyze` clean

---

### Milestone 3.2: Theme System (Day 6, Afternoon)

**Tasks:**
1. `lib/core/theme/app_colors.dart`
   - `brandSeed: Color(0xFF006B5F)`, `successGreen`, `warningAmber`, `dangerRed`
2. `lib/core/theme/app_text_styles.dart`
   - Inter font family, full `TextTheme` override (displayLarge through labelSmall)
3. `lib/core/theme/app_theme_extensions.dart`
   - `AppThemeExtension` with all 13 semantic color tokens (RSVP, attendance, CB, health score, pinned)
4. `lib/core/theme/app_theme.dart`
   - `AppTheme.light` — single `ThemeData` with `ColorScheme.fromSeed`, all component overrides (CardTheme, NavigationBarTheme, FABTheme, InputDecorationTheme, AppBarTheme, BottomSheetTheme, SnackBarTheme, ChipTheme, DialogTheme, TabBarTheme, DividerTheme, BadgeTheme)
5. Verify: create a temporary test screen with all component variants to visually inspect theme application

**Definition of Done:**
- `AppTheme.light` produces a complete `ThemeData` with no runtime errors
- Material 3 color scheme generated from teal seed
- All component overrides applied (verify via temporary test screen)
- `AppThemeExtension` accessible via `Theme.of(context).extension<AppThemeExtension>()`

---

### Milestone 3.3: Shared Providers + Services Stub (Day 7, Morning)

**Tasks:**
1. `lib/shared/providers/supabase_provider.dart`
   - `@riverpod SupabaseClient supabaseClient(...)` — returns `Supabase.instance.client`
2. `lib/shared/providers/auth_state_provider.dart`
   - `@riverpod Stream<AuthState> authStateStream(...)` — wraps `supabase.auth.onAuthStateChange`
3. `lib/shared/services/notification_service.dart` (stub)
   - `initialize()` — request FCM permission, register `onTokenRefresh`
   - `registerToken(supabase, userId)` — PATCH `profiles.push_token`
   - Foreground/background handlers as no-op stubs
4. Run `dart run build_runner build --delete-conflicting-outputs` — generate provider code
5. Commit generated files

**Definition of Done:**
- `supabaseClientProvider` returns a valid client when Supabase is initialized
- `authStateStreamProvider` emits auth state changes
- `NotificationService.initialize()` runs without error (stub)
- All `*.g.dart` files generated and committed

---

### Milestone 3.4: Shared Widgets (Day 7, Afternoon)

**Tasks — build in dependency order:**
1. `shared/widgets/image/mc_avatar.dart` — circular avatar with initials fallback, 6 sizes (XS–XXL), CB variant
2. `shared/widgets/image/mc_cached_image.dart` — CachedNetworkImage with shimmer + error
3. `shared/widgets/loaders/skeleton_loader.dart` — shimmer base widget
4. `shared/widgets/loaders/feed_skeleton.dart` — 3 placeholder post cards
5. `shared/widgets/cards/mc_card.dart` — standard Card with consistent padding/radius
6. `shared/widgets/sheets/mc_bottom_sheet.dart` — DraggableScrollableSheet wrapper with drag handle
7. `shared/widgets/buttons/primary_button.dart` — FilledButton with loading state
8. `shared/widgets/buttons/secondary_button.dart` — OutlinedButton
9. `shared/widgets/buttons/icon_text_button.dart` — TextButton with icon
10. `shared/widgets/empty_states/empty_state_widget.dart` — icon + title + subtitle + optional CTA
11. `shared/widgets/error_states/error_state_widget.dart` — error + retry button
12. `shared/widgets/chips/event_category_chip.dart` — Games/Outings/Social Connect
13. `shared/widgets/chips/status_chip.dart` — Active/Ended/Cancelled
14. `shared/widgets/dialogs/confirm_dialog.dart` — Cancel + Confirm/Destructive
15. `shared/widgets/dialogs/error_dialog.dart` — Error + OK/Retry
16. `shared/widgets/app_bar/mc_app_bar.dart` — standard AppBar

**Definition of Done:**
- All 16 shared widgets compile and render correctly
- `McAvatar` displays initials fallback when no image URL
- `PrimaryButton` shows spinner in loading state
- `EmptyStateWidget` and `ErrorStateWidget` render with configurable text
- `McBottomSheet` opens, drags, and dismisses correctly

---

### Milestone 3.5: GoRouter + Navigation Shell (Day 8, Morning)

**Tasks:**
1. `lib/core/router/route_guards.dart`
   - `requireAuth()`, `requireAdmin()`, `requireNoAuth()`, `requireOnboarding()` — redirect functions
2. `lib/core/router/router_provider.dart`
   - `@riverpod GoRouter appRouter(...)` — watches `authNotifierProvider`, `GoRouterRefreshStream`
3. `lib/core/router/app_router.dart`
   - Full route tree per `navigation-architecture.md`:
   - Auth group: `/welcome`, `/verify-otp`, `/create-profile`
   - ShellRoute (5-tab): `/feed`, `/events`, `/growth`, `/analytics`, `/profile`
   - Stack routes: `/event/:id`, `/event/:id/poll/:pollId`, `/challenge/:id`, `/recognition/:id`, `/analytics/ranking`, `/profile/:id`, `/notifications`
   - Admin group: `/admin`, `/admin/members`, `/admin/flagged`, `/admin/announcements`, `/admin/attendance`, `/admin/connect-buddy`
   - 404 fallback route
4. `shared/widgets/bottom_nav/main_scaffold.dart`
   - `NavigationBar` with 5 tabs (Feed/Events/Growth/Analytics/Profile)
   - Outlined icons inactive, filled icons active
   - No badges yet (added in later sprints)
5. Create placeholder screens for each tab root:
   - `PlaceholderEventsScreen`, `PlaceholderGrowthScreen`, `PlaceholderAnalyticsScreen`
   - Each shows tab name centered with "Coming Soon" text
6. Wire `app.dart` and `main.dart`:
   - `main.dart`: initialization sequence (WidgetsBinding, Firebase, Supabase, NotificationService stub, ProviderScope)
   - `app.dart`: `MaterialApp.router` with `AppTheme.light`, `ThemeMode.light`, `appRouterProvider`

**Definition of Done:**
- App launches, evaluates auth state, redirects to `/welcome` (no session) or `/feed` (valid session)
- 5-tab bottom navigation renders correctly
- Tab switching works and preserves per-tab state
- Auth route guard prevents authenticated users from accessing `/welcome`
- Admin route guard redirects non-admin users to `/feed`
- Placeholder screens display for Events, Growth, Analytics tabs
- 404 route shows fallback screen

---

### Milestone 3.6: Auth Feature Module (Day 8, Afternoon + Day 9, Morning)

**Tasks — Data Layer:**
1. `features/auth/data/datasources/auth_remote_datasource.dart`
   - `validateInviteToken(token)` → calls `validate-invite-token` Edge Function
   - `requestOtp(emailOrPhone)` → `supabase.auth.signInWithOtp()`
   - `verifyOtp(emailOrPhone, otp, token)` → `supabase.auth.verifyOtp()`
   - `createProfile(params)` → calls `create-profile` Edge Function
   - `signOut()` → nullify push token → `supabase.auth.signOut()`
2. `features/auth/data/models/session_model.dart` — `@freezed` + `fromJson`
3. `features/auth/data/models/invitation_model.dart` — `@freezed` + `fromJson`
4. `features/auth/data/repositories/auth_repository_impl.dart` — `Either<Failure, T>` for all operations

**Tasks — Domain Layer:**
5. `features/auth/domain/entities/app_session.dart` — `userId`, `email`, `phone`, `role`, `isActive`
6. `features/auth/domain/entities/invitation.dart` — `inviteeName`, `inviteeEmail`, `inviteePhone`
7. `features/auth/domain/repositories/auth_repository.dart` — abstract interface
8. `features/auth/domain/usecases/validate_invite_token.dart`
9. `features/auth/domain/usecases/request_otp.dart`
10. `features/auth/domain/usecases/verify_otp.dart`
11. `features/auth/domain/usecases/sign_out.dart`

**Tasks — Presentation Layer:**
12. `features/auth/presentation/providers/auth_providers.dart` — DI providers for repo + use cases
13. `features/auth/presentation/providers/auth_notifier.dart`
    - `AuthState`: `initial`, `unauthenticated`, `authenticated(AppSession)`, `deactivated`, `loading`
    - On `authenticated`: load own profile, register push token
14. `features/auth/presentation/widgets/otp_input_widget.dart` — 6-box input, auto-advance, paste support, 60s resend timer
15. `features/auth/presentation/widgets/interest_tag_selector.dart` — FilterChip grid
16. `features/auth/presentation/screens/welcome_screen.dart` — token input + validate + request OTP
17. `features/auth/presentation/screens/verify_otp_screen.dart` — OTP entry + verify + route
18. `features/auth/presentation/screens/create_profile_screen.dart` — avatar picker + form + submit

**Tasks — Code Generation + Test:**
19. Run `build_runner` — generate all Freezed models, providers, JSON serializers
20. Commit generated files
21. Manual integration test: launch app → enter invite token → receive OTP → verify → create profile → land on Feed tab

**Definition of Done:**
- Full auth flow works end-to-end: Welcome → OTP → Create Profile → Feed
- Invalid token shows error state on Welcome screen
- Invalid OTP shows error, clears boxes
- Resend timer counts down, enables resend at 0
- OTP paste (6 digits) fills all boxes
- Profile creation with avatar upload works
- After profile creation, Connect Buddy welcome post appears in database
- Auth guard redirects correctly for all states (no session → welcome, session + !onboarded → create-profile, session + onboarded → feed)

---

## Phase 4: Feed Module (Days 9–10)

### Milestone 4.1: Feed Data + Domain Layer (Day 9, Afternoon)

**Tasks — Data Layer:**
1. `features/feed/data/datasources/feed_remote_datasource.dart`
   - `getFeedPosts(page)` — paginated, reverse chronological, includes CB posts, with author + images + reactions
   - `createPost(content, imageStoragePaths)` — calls `create-post` Edge Function
   - `deletePost(postId)` — PATCH `is_deleted = true`
   - `reactToPost(postId, emoji)` — UPSERT on `post_reactions`
   - `removeReaction(postId)` — DELETE from `post_reactions`
   - `getComments(postId)` — paginated, chronological
   - `addComment(postId, content)` — INSERT
   - `deleteComment(commentId)` — PATCH `is_deleted = true`
   - `flagPost(postId, reason)` — INSERT `flagged_content`
   - `getPinnedPost()` — GET active pinned announcement
   - Image upload: compress → upload to `post-images` bucket → return storage path
2. `features/feed/data/models/post_model.dart` — includes `author.isSystemAccount` for CB detection
3. `features/feed/data/models/comment_model.dart`
4. `features/feed/data/models/reaction_model.dart`
5. `features/feed/data/models/pinned_announcement_model.dart`
6. `features/feed/data/repositories/feed_repository_impl.dart`

**Tasks — Domain Layer:**
7. `features/feed/domain/entities/post.dart` — `bool isConnectBuddyPost` from `author.isSystemAccount`
8. `features/feed/domain/entities/comment.dart`
9. `features/feed/domain/entities/reaction.dart`
10. `features/feed/domain/entities/pinned_announcement.dart`
11. `features/feed/domain/repositories/feed_repository.dart` — abstract interface
12. `features/feed/domain/usecases/get_feed_posts.dart`
13. `features/feed/domain/usecases/create_post.dart`
14. `features/feed/domain/usecases/delete_post.dart`
15. `features/feed/domain/usecases/react_to_post.dart`
16. `features/feed/domain/usecases/get_comments.dart`
17. `features/feed/domain/usecases/add_comment.dart`
18. `features/feed/domain/usecases/delete_comment.dart`
19. `features/feed/domain/usecases/flag_post.dart`
20. Run `build_runner` for Freezed models

**Definition of Done:**
- All models serialize/deserialize correctly from Supabase JSON
- Repository returns `Either<Failure, T>` for all operations
- Use cases callable with correct signatures

---

### Milestone 4.2: Profile Module (Basic) (Day 9, alongside 4.1)

**Tasks:**
1. `features/profile/data/datasources/profile_remote_datasource.dart`
   - `getProfileById(id)` — rejects system accounts
   - `getAllMemberProfiles()` — active, non-system accounts
   - `uploadAvatar(userId, imageBytes)` → upload to `avatars` bucket
   - `updateProfile(params)` — PATCH profiles
2. `features/profile/data/models/profile_model.dart`
3. `features/profile/data/repositories/profile_repository_impl.dart`
4. `features/profile/domain/entities/profile.dart`
5. `features/profile/domain/entities/profile_summary.dart` — id, fullName, avatarUrl, title, isSystemAccount
6. `features/profile/domain/repositories/profile_repository.dart`
7. `features/profile/domain/usecases/get_profile.dart`
8. `features/profile/domain/usecases/get_all_member_profiles.dart`
9. `features/profile/domain/usecases/update_profile.dart`
10. `features/profile/domain/usecases/upload_avatar.dart`
11. `features/profile/presentation/providers/all_profiles_provider.dart` — `@Riverpod(keepAlive: true)` for @mention picker
12. `features/profile/presentation/providers/own_profile_notifier.dart`
13. `features/profile/presentation/screens/own_profile_screen.dart` — profile display + Edit Profile + Notification Prefs + Logout + Admin Panel entry
14. `features/profile/presentation/screens/member_profile_screen.dart` — read-only view
15. `shared/providers/connect_buddy_provider.dart` — fetches CB system profile once

**Definition of Done:**
- Own profile screen displays current user's profile data
- Member profile screen displays any member's profile (navigable from feed author tap)
- `allProfilesProvider` returns list of all active members (excluding system accounts)
- Connect Buddy provider fetches and caches system profile

---

### Milestone 4.3: Feed Presentation Layer (Day 10, Morning)

**Tasks:**
1. `features/feed/presentation/providers/feed_providers.dart` — DI providers
2. `features/feed/presentation/providers/feed_notifier.dart` — `AsyncNotifier<List<Post>>` with pagination + optimistic create
3. `features/feed/presentation/providers/feed_realtime_provider.dart` — `StreamProvider` on `feed:posts` channel
4. `features/feed/presentation/providers/post_comments_notifier.dart` — `.family` by postId
5. `features/feed/presentation/providers/post_reactions_notifier.dart` — `.family` by postId
6. `features/feed/presentation/widgets/post_card.dart` — standard member post card
7. `features/feed/presentation/widgets/connect_buddy_post_card.dart` — distinct CB card (purple bg, badge)
8. `features/feed/presentation/widgets/reaction_bar.dart` — emoji chips with counts, bounce animation
9. `features/feed/presentation/widgets/comment_tile.dart` — comment row with delete
10. `features/feed/presentation/widgets/comments_sheet.dart` — bottom sheet with comment list + input
11. `features/feed/presentation/widgets/create_post_sheet.dart` — text + photo + @mention
12. `features/feed/presentation/widgets/mention_input_field.dart` — @ autocomplete overlay
13. `features/feed/presentation/widgets/pinned_post_banner.dart` — amber background banner
14. `features/feed/presentation/screens/feed_screen.dart` — pinned banner + feed list + FAB + pull-to-refresh + infinite scroll

**Definition of Done:**
- Feed screen loads and displays posts from database
- Connect Buddy posts render with distinct purple background and badge
- Pull-to-refresh reloads feed
- Infinite scroll loads next page at scroll bottom
- Pinned announcement displays at top (if active)
- FAB opens Create Post bottom sheet
- Post creation with text works (post appears in feed)
- Image upload in post works (up to 4 images)
- @mention autocomplete appears on `@` keystroke, inserts selected member
- Emoji reactions toggle on tap with optimistic update
- Comments sheet opens from post, displays comments, allows new comment
- Realtime: new posts from other users appear in feed without refresh

---

### Milestone 4.4: End-to-End Integration Test (Day 10, Afternoon)

**Tasks:**
1. Full flow test against cloud dev:
   - Admin sends invitation via Edge Function
   - New user opens app → enters token → verifies OTP → creates profile
   - Connect Buddy welcome post appears in feed
   - User creates a text post → post appears in feed
   - User creates a post with photos → images display correctly
   - User reacts to a post → reaction count updates
   - User comments on a post → comment appears
   - User @mentions another user → mention parsed (notification stub logs)
   - User taps author avatar → navigates to member profile
   - User switches between all 5 tabs → placeholder screens for Events/Growth/Analytics
   - User logs out → redirected to Welcome screen
2. Fix any integration issues found
3. Code cleanup: remove any temporary test screens or debug code
4. Final `flutter analyze` — zero issues
5. Final commit and push

**Definition of Done — Sprint 1 Complete:**
- Admin invites manager → manager registers via OTP → completes profile → lands on Feed
- Connect Buddy welcome post visible in feed
- Feed displays posts with reactions, comments, mentions, images
- 5-tab navigation shell works (3 tabs show placeholder screens)
- Profile tab shows own profile with logout
- Admin route guard blocks non-admin access
- Auth guard redirects unauthenticated users
- Cloud dev backend fully operational with 5 Edge Functions
- CI pipeline green (analyze + test pass)

---

## Build Order Summary

```
Day 1  │ M1.1 Flutter project init
       │ M1.2 Supabase project init
       │
Day 2  │ M1.3 Firebase + Git + CI + Environment
       │
Day 3  │ M2.1 Database: all 68 migrations + seed
       │ M2.2 Storage buckets
       │
Day 4  │ M2.3 Backend _shared/ infrastructure
       │ M2.4 Auth Edge Functions (3)
       │
Day 5  │ M2.5 Feed Edge Functions (2)
       │ M2.6 Deploy backend to cloud dev
       │
Day 6  │ M3.1 Core constants + errors + extensions
       │ M3.2 Theme system
       │
Day 7  │ M3.3 Shared providers + services stub
       │ M3.4 Shared widgets (16 components)
       │
Day 8  │ M3.5 GoRouter + navigation shell + main.dart
       │ M3.6 Auth module (data + domain + presentation) [start]
       │
Day 9  │ M3.6 Auth module [complete]
       │ M4.1 Feed data + domain layer
       │ M4.2 Profile module (basic)
       │
Day 10 │ M4.3 Feed presentation layer
       │ M4.4 End-to-end integration test
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Supabase OTP delivery delays in dev | Use Supabase Auth dashboard to view OTP codes during development (no SMS/email needed) |
| Code generation failures | Run `build_runner` after every model/provider addition, commit generated files |
| Firebase setup complexity (iOS) | Use FlutterFire CLI (`flutterfire configure`) for automated platform setup |
| Edge Function cold start latency | Acceptable for dev; not a blocker for Sprint 1 |
| Full schema deployment causes confusion | Tables not yet used are inert — RLS blocks all access; document clearly |
| Image compression quality on device | Test on real devices early (Day 10); adjust quality threshold if needed |

---

## What Comes Next (Sprint 2 Preview)

Sprint 2 builds on Sprint 1's foundation:
- **Events module:** All event categories, RSVP, polls, event history
- **Realtime channels:** RSVP counts, poll vote percentages
- **Profile enhancements:** Edit profile, notification preferences screen
- **Edge Functions:** `cancel-activity`, `post-activity-update`, `create-poll`, `close-poll`
