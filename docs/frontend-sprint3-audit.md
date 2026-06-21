# Frontend Sprint 3 Audit

**Date:** 2026-06-21

---

## Screens Implemented (2 screens + 1 modal)

| # | Screen | File | Type |
|---|--------|------|------|
| E1 | Activities List | `activities_list_screen.dart` | Tab root — upcoming/past toggle, category filter chips, pull-to-refresh |
| E2 | Activity Detail | `activity_detail_screen.dart` | Stack route — full info, RSVP buttons, attendee list, updates, cancel/post-update for organizer |
| E3 | Create Activity | `create_activity_screen.dart` | Modal — title, category, type, date picker, location, description, cost note |

## Providers Implemented (2)

| Provider | File | Type | Scope |
|----------|------|------|-------|
| `activitiesProvider` (ActivitiesNotifier) | `activities_provider.dart` | Notifier | keepAlive — upcoming + past lists, category filter, past toggle |
| `activityDetailProvider(activityId)` (ActivityDetailNotifier) | `activity_detail_provider.dart` | Notifier (family) | auto-dispose — activity + RSVPs + updates per activity |

### ActivitiesNotifier Methods

| Method | Purpose |
|--------|---------|
| `load()` | Fetch upcoming (with optional category filter) + past activities |
| `refresh()` | Pull-to-refresh re-fetch |
| `setCategory(category)` | Filter by games/outings/social_connect/all |
| `togglePast()` | Toggle between upcoming and past views |

### ActivityDetailNotifier Methods

| Method | Purpose |
|--------|---------|
| `load()` | Fetch activity + RSVPs + updates in parallel |
| `rsvp(userId, status)` | RSVP going/maybe/not_going (upsert) |
| `withdrawRsvp(userId)` | Remove RSVP |
| `cancelActivity()` | Cancel via Edge Function (creator/admin) |
| `postUpdate(content)` | Post organizer update via Edge Function |

## Repositories Implemented (1)

| Repository | File | Operations |
|-----------|------|------------|
| `ActivityRepository` | `activity_repository.dart` | `getUpcoming()`, `getPast()`, `getActivity()`, `createActivity()`, `cancelActivity()`, `getRsvps()`, `upsertRsvp()`, `withdrawRsvp()`, `getUpdates()`, `postUpdate()` |

## Models Implemented (3)

| Model | File | Purpose |
|-------|------|---------|
| `ActivityDto` | `activity_dto.dart` | Activity with author profile join, computed `isCancelled`/`isPast` |
| `RsvpDto` | `activity_dto.dart` | RSVP with user profile join |
| `ActivityUpdateDto` | `activity_dto.dart` | Organizer update message |

## Widgets Implemented (1)

| Widget | File | Purpose |
|--------|------|---------|
| `ActivityCard` | `activity_card.dart` | Category icon, date formatting, location, type badge, cancelled chip |

## Routes Added (1)

| Route | Screen |
|-------|--------|
| `/event/:id` | ActivityDetailScreen |

## Router Changes

- Events tab: `PlaceholderScreen` → `ActivitiesListScreen`

## Verification Results

| Check | Result |
|-------|--------|
| `flutter test` | **PASS** — 1/1 |
| `build_runner` | **PASS** — 10 outputs |
| `flutter analyze` | **PASS** — No issues found |
| `flutter build web` | **PASS** — compiled in 62s |
| `flutter run -d chrome` | **PASS** — app launches |

## Issues Found and Fixed

| # | Issue | Fix |
|---|-------|-----|
| 1 | Backslash in import path (`\providers\`) | Changed to forward slash |
| 2 | `DropdownButtonFormField.value` deprecated in Flutter 3.38+ | Migrated to `DropdownMenu` with `initialSelection` |
| 3 | Non-const `ButtonSegment` list in `SegmentedButton` | Added `const` to segments list |

## Verdict

| Metric | Value |
|--------|-------|
| Analyzer errors | **0** |
| Build errors | **0** |
| Provider generation errors | **0** |
| Route issues | **0** |
| Critical issues | **0** |
| High issues | **0** |
