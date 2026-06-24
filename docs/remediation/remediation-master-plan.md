# Remediation Master Plan

**Date:** 2026-06-24
**Current Readiness:** 78%
**Target Readiness:** 93%

---

## Execution Order

| Order | Task | ID | Severity | Effort | Blocked By |
|-------|------|----|----------|--------|-----------|
| 1 | Web loading indicator | REM-04 | HIGH | 30 min | Nothing |
| 2 | Storage bucket RLS | REM-01 | CRITICAL | 1-2h | Nothing |
| 3 | Notification deep links | REM-03 | MEDIUM | 1-2h | Nothing |
| 4 | Auth URL cleanup | REM-07 | LOW | 30 min | Nothing |
| 5 | Admin missing actions | REM-05 | LOW | 2-3h | Nothing |
| 6 | Realtime replication | REM-06 | LOW | 30 min | Nothing |
| 7 | Firebase web config | REM-02 | HIGH | 2-3h | Firebase project |

---

## Milestone 1: Quick Wins (2 hours)

**Tasks:** REM-04 + REM-07

| Deliverable | Impact |
|-------------|--------|
| Loading spinner in index.html | Eliminates "blank white screen" perception |
| Preload hints for canvaskit.wasm | Faster resource fetching |
| Auth URL cleanup | Clean URLs after login |

**Readiness after M1:** 80% (+2%)

---

## Milestone 2: Security Hardening (2 hours)

**Tasks:** REM-01

| Deliverable | Impact |
|-------------|--------|
| Storage bucket RLS policies | Secure file upload path |
| Bucket creation in migration | Repeatable on fresh deploy |

**Unblocks:** Avatar upload, post image upload (frontend work needed separately)

**Readiness after M2:** 84% (+4%)

---

## Milestone 3: Engagement Completion (3 hours)

**Tasks:** REM-03 + REM-05

| Deliverable | Impact |
|-------------|--------|
| Notification tap → content navigation | Notifications drive return visits |
| Pin/unpin UI in admin dashboard | Full admin pinning capability |
| Remove user button in member management | Complete admin user lifecycle |

**Readiness after M3:** 89% (+5%)

---

## Milestone 4: Infrastructure (3 hours)

**Tasks:** REM-06 + REM-02

| Deliverable | Impact |
|-------------|--------|
| Realtime replication on 8 tables | V2 realtime channels unblocked |
| Firebase web configuration | Push notifications functional |
| FCM token registration | Users receive push on web |

**Note:** REM-02 requires a Google Cloud project with Firebase enabled. This is an external dependency.

**Readiness after M4:** 93% (+4%)

---

## Readiness Progression

```
Current:                    78%
After M1 (Quick Wins):      80%  (+2%)
After M2 (Security):        84%  (+4%)
After M3 (Engagement):      89%  (+5%)
After M4 (Infrastructure):  93%  (+4%)
```

---

## Remaining After All Milestones (93% → 100%)

| Gap | Category | Effort |
|-----|----------|--------|
| Image upload UI (avatar + posts) | Feature | 8h |
| @mention UI in composer | Feature | 4h |
| Member profile view (other users) | Feature | 4h |
| Stories rail with real user data | Feature | 3h |
| Production Supabase instance | Infrastructure | 4h |
| CI/CD pipeline | Infrastructure | 4h |
| Domain + SSL certificate | Infrastructure | 2h |
| UI visual polish to V0 specs | Design | 40h+ |

These items are feature additions and deployment infrastructure, not remediation of existing gaps.

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Firebase project setup blocked by org policy | Medium | Blocks push | Use in-app inbox only (already working) |
| Storage RLS migration conflicts with existing data | Low | Blocks files | Test on fresh `db reset` first |
| Realtime replication causes performance regression | Low | Degraded UX | Enable incrementally, monitor |
| Loading indicator CSS conflicts with Flutter bootstrap | Very Low | Visual glitch | Flutter auto-removes `#loading` div |

---

## Dependencies

```
REM-04 (loading indicator) ── no deps ── do first
REM-01 (storage RLS) ── no deps ── do second  
REM-03 (deep links) ── no deps
REM-07 (URL cleanup) ── no deps
REM-05 (admin actions) ── no deps
REM-06 (realtime) ── no deps
REM-02 (Firebase) ── requires Google Cloud project
```

All tasks except REM-02 are self-contained with zero external dependencies.

---

## Total Estimated Effort

| Category | Hours |
|----------|-------|
| Quick wins (REM-04, REM-07) | 1h |
| Security (REM-01) | 2h |
| Engagement (REM-03, REM-05) | 4h |
| Infrastructure (REM-06, REM-02) | 3.5h |
| **Total** | **10.5 hours** |

---

## Success Criteria

After all 7 remediation tasks:

- [ ] Loading spinner visible within 1 second of page load
- [ ] Storage buckets have RLS policies enforced
- [ ] Tapping a notification navigates to referenced content
- [ ] Auth callback URL is clean (no `?code=` parameter)
- [ ] Admin can pin/unpin posts and remove users from UI
- [ ] Realtime replication enabled on all 8 tables
- [ ] Firebase web SDK configured and FCM tokens registered
- [ ] `flutter analyze` passes with zero errors
- [ ] `flutter build web` succeeds
- [ ] `supabase db reset` + `supabase db diff` = zero drift
