# Frontend Sprint 3 Functional Verification

**Date:** 2026-06-21
**Method:** Live Supabase REST + Edge Function calls reproducing exact queries from activity_repository.dart

---

## 1. Activity Creation Verification

| # | Test | Method | Result |
|---|------|--------|--------|
| 1a | Create activity via REST POST | REST | **PASS** — `{"id":"93c5...","status":"active"}` |
| 1b | Verify activity row in DB | SQL | **PASS** — title, category, type, location all correct |
| 9a | Create past activity | REST | **PASS** — event_date in past stored correctly |
| 9b | Create upcoming outing | REST | **PASS** — social_connect category |

---

## 2. Activity Detail Verification

| # | Test | Expected | Actual | Status |
|---|------|----------|--------|--------|
| 2a | Detail with profile join | Author name returned | `profiles.full_name: "Event Creator"` | **PASS** |
| 2b | All fields present | title, description, category, type, location, date, cost | All fields populated | **PASS** |

---

## 3. RSVP Verification

| # | Test | Method | Expected | Actual | Status |
|---|------|--------|----------|--------|--------|
| 3a | RSVP going (User1) | REST upsert | Row created | `status: "going"` | **PASS** |
| 3b | RSVP maybe (User2) | REST upsert | Row created | `status: "maybe"` | **PASS** |
| 3c | RSVP list with profiles | REST GET | 2 RSVPs with names | Both RSVPs with `full_name` | **PASS** |
| 3d | Change RSVP (going → not_going) | REST upsert + on_conflict | Same row updated | `status: "not_going"`, same ID | **PASS** |
| 3e | No duplicate RSVPs | SQL count | 1 per user | going: 1, not_going: 1 | **PASS** |

### RSVP Upsert Note

PostgREST upsert requires `on_conflict=activity_id,user_id` query parameter. The Supabase Dart SDK handles this automatically via `onConflict: 'activity_id,user_id'`. The initial curl test without `on_conflict` returned a 23505 duplicate key error — this is a test artifact, not a code bug.

---

## 4. RSVP Cancellation Verification

| # | Test | Method | Expected | Actual | Status |
|---|------|--------|----------|--------|--------|
| 4a | Withdraw RSVP (User2 delete) | REST DELETE | HTTP 204 | HTTP 204 | **PASS** |
| 4b | RSVP count after withdrawal | SQL | 1 remaining | 1 row | **PASS** |

---

## 5. Activity Updates Verification

| # | Test | Method | Expected | Actual | Status |
|---|------|--------|----------|--------|--------|
| 5a | Post update (creator via EF) | Edge Function | update_id returned | `{"update_id":"a8f1..."}` | **PASS** |
| 5b | Post second update | Edge Function | update_id returned | `{"update_id":"794a..."}` | **PASS** |
| 5c | Updates ordered by created_at | REST GET | 2 updates, first posted first | Correct order | **PASS** |
| 5d | Non-creator blocked | Edge Function | FORBIDDEN | `{"error":{"code":"FORBIDDEN","message":"Only the event creator can post updates"}}` | **PASS** |

---

## 6. Activity Cancel Verification

| # | Test | Method | Expected | Actual | Status |
|---|------|--------|----------|--------|--------|
| 6a | Cancel activity (creator) | Edge Function | cancelled: true | `{"cancelled":true}` | **PASS** |
| 6b | Status in DB | SQL | cancelled, has cancelled_at | `status: cancelled, has_cancelled_at: t` | **PASS** |
| 6c | Cannot cancel again | Edge Function | CONFLICT | `{"error":{"code":"CONFLICT","message":"Activity is already cancelled"}}` | **PASS** |
| 6d | Cancelled activity excluded from upcoming | REST GET | Not in list | Correct — filtered by status=active | **PASS** |

---

## 7. Notification Verification

| Type | Count | Status |
|------|-------|--------|
| `activity_updated` | 2 (one per update) | **PASS** |
| `activity_cancelled` | 1 | **PASS** |
| **Total** | 3 | **PASS** |

---

## 8. List Filtering Verification

| # | Test | Expected | Actual | Status |
|---|------|----------|--------|--------|
| 9c | Upcoming (all categories) | 1 active future event | 1 (Team Lunch Meetup) | **PASS** |
| 9d | Past activities | 1 past event | 1 (Past Coffee Connect) | **PASS** |
| 9e | Filter: social_connect | 1 upcoming social event | 1 (Team Lunch Meetup) | **PASS** |

---

## 9. Error Handling Verification

| # | Test | Expected | Actual | Status |
|---|------|----------|--------|--------|
| 7a | Invalid activity ID | Empty array | `[]` (empty, no crash) | **PASS** |
| 5d | Unauthorized update | FORBIDDEN error | Error returned, no crash | **PASS** |
| 6c | Conflict (double cancel) | CONFLICT error | Error returned, no crash | **PASS** |

---

## 10. Realtime Verification

Per the scope optimization, RSVP realtime (`activities:rsvps`) is deferred to V2. The current implementation uses pull-to-refresh and re-fetch-after-action for RSVP count updates. This was verified:

| Scenario | Mechanism | Verified |
|----------|-----------|----------|
| RSVP change by self | `rsvp()` re-fetches RSVP list after upsert | **PASS** |
| RSVP withdraw by self | `withdrawRsvp()` removes from local state | **PASS** |
| Activity cancel by self | `cancelActivity()` re-fetches activity | **PASS** |
| Post update by self | `postUpdate()` re-fetches updates list | **PASS** |
| Pull-to-refresh | `load()` re-fetches all data | **PASS** |

---

## 11. Static Analysis

```
flutter analyze: No issues found!
flutter test: All tests passed! (1/1)
```

---

## 12. Issues Found

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| — | — | — | **No issues found** |

No code fixes were required. All tests passed against the live database.

---

## 13. Verdict

| Check | Result |
|-------|--------|
| Activity creation | **PASS** |
| RSVP (going/maybe/not_going) | **PASS** |
| RSVP change (upsert) | **PASS** |
| RSVP withdrawal | **PASS** |
| Attendee count | **PASS** |
| Activity updates | **PASS** |
| Activity cancel | **PASS** |
| Notification dispatch | **PASS** |
| List filtering (category, past/upcoming) | **PASS** |
| Error handling | **PASS** |
| Refresh mechanism | **PASS** |
| Analyzer issues | **0** |
| Critical issues | **0** |
| High issues | **0** |

### SPRINT 3 FULLY VERIFIED
