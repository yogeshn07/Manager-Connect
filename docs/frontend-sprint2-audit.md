# Frontend Sprint 2 Audit

**Date:** 2026-06-21

---

## Screens Implemented (3)

| # | Screen | File | Type |
|---|--------|------|------|
| F1 | Feed | `feed_screen.dart` | Tab root — paginated list, pinned post, realtime, pull-to-refresh, empty state |
| F2 | Create Post | `create_post_screen.dart` | Modal bottom sheet — text input, character limit, post via Edge Function |
| F3 | Post Detail | `post_detail_screen.dart` | Stack route — post content, reaction bar, comments list, comment input, delete |

## Providers Implemented (2)

| Provider | File | Type | Scope |
|----------|------|------|-------|
| `feedProvider` (FeedNotifier) | `feed_provider.dart` | Notifier | keepAlive — manages feed list, pinned post, pagination, realtime |
| `postDetailProvider(postId)` (PostDetailNotifier) | `post_detail_provider.dart` | Notifier (family) | auto-dispose — post detail + comments + reactions per post |

### FeedNotifier Methods

| Method | Purpose |
|--------|---------|
| `loadFeed()` | Initial feed load + pinned post + subscribe realtime |
| `loadMore()` | Keyset pagination (cursor by `created_at`) |
| `refresh()` | Pull-to-refresh re-fetch |
| `removePost(postId)` | Optimistic removal on delete |

### PostDetailNotifier Methods

| Method | Purpose |
|--------|---------|
| `load()` | Fetch post + comments + reactions in parallel |
| `addComment(authorId, content)` | Create comment + append to list |
| `deleteComment(commentId)` | Soft-delete + remove from list |
| `toggleReaction(userId, emoji)` | Upsert or remove reaction (optimistic) |

## Repositories Implemented (1)

| Repository | File | Operations |
|-----------|------|------------|
| `FeedRepository` | `feed_repository.dart` | `getFeed()`, `getPinnedPost()`, `getPost()`, `createPost()`, `deletePost()`, `getComments()`, `createComment()`, `deleteComment()`, `getReactions()`, `upsertReaction()`, `removeReaction()`, `flagContent()` |

## Models Implemented (3)

| Model | File | Purpose |
|-------|------|---------|
| `PostDto` | `post_dto.dart` | Post with author profile join |
| `CommentDto` | `post_dto.dart` | Comment with author profile join |
| `ReactionDto` | `post_dto.dart` | Reaction (emoji per user per post) |

## Widgets Implemented (1)

| Widget | File | Purpose |
|--------|------|---------|
| `PostCard` | `post_card.dart` | Reusable post card — Connect Buddy styling, pinned badge, relative time |

## Routes Added (1)

| Route | Screen |
|-------|--------|
| `/post/:id` | PostDetailScreen |

## Realtime Implementation

| Channel | Table | Event | Behavior |
|---------|-------|-------|----------|
| `feed:posts` | posts | INSERT | Fetch full post by ID, prepend to feed list |

### Duplicate Protection

`_knownPostIds` set tracks all post IDs currently in the feed. On realtime INSERT, the handler checks if the post ID is already known before fetching and prepending. This prevents duplicates when the user's own post appears via both the refresh-after-create and the realtime channel.

### Lifecycle

- Subscribe on `loadFeed()` (feed screen init)
- Unsubscribe on provider dispose via `ref.onDispose`
- Channel name: `feed:posts` (single global channel)

## Verification Results

| Check | Result |
|-------|--------|
| `flutter pub get` | **PASS** |
| `build_runner` | **PASS** — 6 outputs generated |
| `flutter analyze` | **PASS** — No issues found |
| `flutter test` | **PASS** — 1/1 tests passed |
| `flutter build web` | **PASS** — compiled in 80.6s |
| `flutter run -d chrome` | **PASS** — app launches, no errors |

## Issues Found and Fixed

| # | Issue | Fix |
|---|-------|-----|
| 1 | `.lt()` filter called after `.limit()` transform | Moved filter before `.order().limit()` chain |
| 2 | Closures used instead of tearoffs in `.map()` | Changed `(json) => Dto.fromJson(json)` to `Dto.fromJson` |
| 3 | Generated provider names use Riverpod 3.x convention (no "Notifier" suffix) | Changed `feedNotifierProvider` → `feedProvider`, `postDetailNotifierProvider` → `postDetailProvider` |
| 4 | `() => e.toString()` closure flagged as unnecessary lambda | Changed to `e.toString` tearoff |
| 5 | Unused import `app_constants.dart` in feed_screen | Removed |

All issues caught and fixed before final analysis pass.

## Verdict

| Metric | Value |
|--------|-------|
| Analyzer errors | **0** |
| Build errors | **0** |
| Provider generation errors | **0** |
| Realtime issues | **0** |
| Route issues | **0** |
| Critical issues | **0** |
| High issues | **0** |
