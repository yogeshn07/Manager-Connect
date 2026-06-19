# Testing Strategy

## Overview

Manager Connect follows a pragmatic testing approach suited to a small team and a 20-user private app. The focus is on fast feedback, high confidence in critical paths, and catching regressions automatically before they reach production.

---

## Test Pyramid

```
         /‾‾‾‾‾‾‾‾‾‾\
        /  E2E Tests  \        ← Small: critical flows only
       /‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
      / Integration Tests \    ← Medium: module API interactions
     /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
    /     Unit Tests        \  ← Wide: business logic, utilities
   /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
```

Target coverage: **60% overall**, with **90%+ on business logic utilities**.

---

## Testing Levels

### Level 1: Unit Tests

**Tool:** Jest + React Native Testing Library  
**Runner:** `npx jest`  
**Scope:** Pure functions and logic-heavy components.

What to unit test:
- Date formatting utilities (activity time display, challenge duration)
- Notification payload builders
- Leaderboard ranking calculations
- Input validation functions (profile form, activity form)
- OTP expiry checks
- Pagination helpers

What NOT to unit test:
- Simple UI components with no logic
- Supabase client calls (test at integration level)
- Navigation flows (test at E2E level)

Coverage target: 60% minimum, enforced in CI.

---

### Level 2: Integration Tests

**Tool:** Jest + Supabase local emulator (via Supabase CLI)  
**Scope:** Module-level data flows — service functions that call Supabase.

What to integration test:
- Auth module: invite token validation, OTP flow, session handling
- Feed module: post creation, comment insertion, reaction toggle
- Activities module: activity create, RSVP submission, cancellation
- Wellness module: challenge join, progress log, leaderboard query
- Recognition module: recognition creation and recipient notification trigger
- Admin module: user invite, flagged content resolution, audit log write

Each integration test runs against a local Supabase instance seeded with fixture data. Tests are isolated: each test resets relevant tables in the local DB.

---

### Level 3: End-to-End (E2E) Tests

**Tool:** Maestro (mobile E2E testing, works with Expo)  
**Runner:** Maestro CLI on simulator/emulator  
**Scope:** Critical user journeys only. Not exhaustive.

Critical flows to E2E test:
1. Onboarding: invite link → OTP → profile creation → feed landing
2. Create and RSVP to an activity
3. Post a recognition and verify notification (simulated)
4. Join a wellness challenge and log progress
5. Admin: invite a member and deactivate a member

E2E tests run on CI against a dedicated staging Supabase project with seeded test data.

---

## Testing by Module

| Module | Unit | Integration | E2E |
|--------|------|-------------|-----|
| Auth | Yes | Yes | Yes (onboarding) |
| Profile | Minimal | Yes | No |
| Feed | Yes (validation) | Yes | No |
| Activities | Yes (date logic) | Yes | Yes |
| Wellness | Yes (ranking) | Yes | Yes (challenge log) |
| Recognition | No | Yes | Yes |
| Messages | No | Yes | Yes (DM) |
| Admin | No | Yes | Yes (invite/deactivate) |

---

## Test Data Strategy

- Unit tests: inline test fixtures (no DB needed).
- Integration tests: local Supabase with seed scripts. Seeds reset before each test suite.
- E2E tests: dedicated staging Supabase project. Seed data loaded at CI start; cleaned up after run.
- **No production data is ever used in tests.**

---

## CI Integration

Tests run automatically on every pull request to `main` and `develop`:

```
PR Opened / Commit Pushed
       ↓
Run Unit Tests (fast: <1 min)
       ↓
Run Integration Tests (medium: <5 min)
       ↓
Run E2E Tests on Simulator (slow: <15 min)
       ↓
All pass → PR can be merged
```

If any test fails, the PR is blocked. No exceptions without team lead approval.

---

## Manual Testing

Manual testing is required before each production release:

- Device testing on: iPhone (latest iOS), iPhone (iOS–1), Android (recent flagship), Android (mid-range).
- Test matrix covers: happy paths, error states, offline behavior, push notification receipt, and deep link navigation.
- Manual test checklist maintained in `docs/production-readiness-checklist.md`.

---

## What We Do Not Test

- Supabase infrastructure itself (vendor responsibility).
- Push notification delivery at the FCM/APNs layer (vendor responsibility).
- Third-party libraries internals.
- UI pixel-perfection (no visual regression testing in V1).
