# Backend Scope Optimization

## Original Scope

- **21 Edge Functions** planned
- **63 REST operations** via PostgREST
- **7 Realtime channels**

## Function-by-Function Classification

### REQUIRED_EDGE_FUNCTION (15 functions)

These require server-side trust, multi-table atomicity, or third-party integration that cannot be done safely client-side.

| # | Function | Reason |
|---|----------|--------|
| 1 | `send-notification` | Multi-table write (notification_inbox) + FCM push API call + preference checking. Client cannot write to notification_inbox (RLS blocked). |
| 2 | `validate-invite-token` | **Public endpoint** (no JWT). Must hash raw token server-side and look up hash. Cannot expose token_hash logic to unauthenticated clients. |
| 3 | `send-invitation` | Generates UUID token, hashes it server-side (crypto), inserts invitation, writes audit log. Token generation must be server-side for security. |
| 4 | `create-profile` | Multi-step atomic: re-validate invite token + create profile + mark invitation accepted + trigger CB welcome post + notify admin. Cannot be a simple REST INSERT (profiles INSERT is RLS-blocked). |
| 5 | `create-post` | Multi-table atomic: insert post + insert post_images + parse @mentions + insert post_mentions + dispatch mention notifications. post_mentions INSERT is RLS-blocked (service_role only). |
| 6 | `create-recognition` | Multi-table atomic: insert recognition + insert recognition_recipients (1 per recipient) + dispatch notifications. Recipients INSERT via RLS requires parent giver check — Edge Function is simpler and safer. |
| 7 | `create-poll` | Multi-table atomic: insert poll + insert poll_options (2–10 rows). poll_options INSERT is RLS-blocked (admin only). Atomicity ensures no poll exists without options. |
| 8 | `cancel-activity` | Multi-step: update activity status + fetch all RSVPs + dispatch cancellation notifications. Notification dispatch requires service_role. |
| 9 | `post-activity-update` | Multi-step: verify caller is creator + insert activity_update + fetch RSVPs + dispatch notifications. activity_updates INSERT is RLS-blocked (admin only — Edge Function uses service_role). |
| 10 | `resolve-flag` | Multi-table: update flag status + optionally soft-delete post/comment + write 1–2 audit log entries. audit_log INSERT is RLS-blocked. |
| 11 | `remove-user` | Multi-step: anonymize profile (7 fields) + delete avatar from Storage + write audit log. Storage deletion requires service_role. PII compliance critical. |
| 12 | `compute-monthly-stats` | Complex aggregation across 6+ tables + upsert into 2 service_role-only tables. No client can write to member_monthly_stats or community_health_scores. |
| 13 | `scheduled-connect-buddy` | Scheduled: composes content from DB queries + calls post-connect-buddy-message. 7 trigger types with different logic. Service_role only. |
| 14 | `scheduled-cleanup` | Scheduled: hard-deletes expired soft-deleted content, expires old invitations, prunes old notifications. Hard DELETE bypasses soft-delete pattern — must be server-only. |
| 15 | `post-connect-buddy-message` | Internal: inserts post as Connect Buddy system account (service_role required — client can't impersonate system account) + optional all-member notification. |

### DIRECT_SUPABASE_OPERATION (6 functions → can be eliminated)

These can be replaced by direct Supabase PostgREST calls from the Flutter client, because RLS already protects them and they don't require multi-table atomicity or notifications.

| # | Function | Current Justification | Why It Can Be Eliminated |
|---|----------|----------------------|-------------------------|
| 16 | `close-poll` | Sets is_closed + notifies voters + audit log | **Split:** Scheduled batch → keep as EF. Manual admin close → admin can UPDATE polls directly via REST (RLS allows admin UPDATE). Notification can be triggered by a database webhook or deferred to next scheduled run. |
| 17 | `close-challenge` | Sets status='ended' + notifies participants | **Same pattern as close-poll.** Scheduled batch → keep. Manual close → admin REST UPDATE. |
| 18 | `record-attendance` | Batch upsert + audit log | Admin can UPSERT event_attendance directly via REST (RLS allows admin INSERT/UPDATE). Audit log can be written by a database trigger instead of Edge Function. **However:** batch validation (user_ids exist, event is past) is complex. **Verdict: KEEP as Edge Function** — reclassified as REQUIRED. |
| 19 | `pin-announcement` | Deactivate old pin + create new + audit log | Admin can UPDATE pinned_announcements directly (RLS allows). The "deactivate old before insert new" logic is simple enough for client-side. Audit log is the only blocker. **Verdict: COULD eliminate if audit logging moves to DB trigger.** |
| 20 | `deactivate-user` | Update is_active + nullify push_token + audit log | Admin can UPDATE profiles directly (RLS allows admin UPDATE). Push token nullification is just another column. Audit log is the blocker. **Verdict: COULD eliminate if audit logging moves to DB trigger.** |
| 21 | `revoke-invitation` | Update status='revoked' + audit log | Admin can UPDATE invitations directly (RLS allows admin UPDATE). Single column change. Audit log is the blocker. |

### Analysis of Eliminable Functions

The 6 potentially eliminable functions share one common dependency: **audit log writing**. The `admin_audit_log` table has INSERT blocked for ALL clients (including admin) — only service_role can write to it. This is by design: audit logs must be tamper-proof.

**Three options to eliminate these functions:**

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| A: Keep all as Edge Functions | Current plan | Consistent pattern; audit guaranteed | More code to maintain |
| B: DB trigger for audit | Create PostgreSQL trigger on admin tables that auto-logs changes | Zero Edge Function code | Complex trigger logic; harder to debug; trigger must run as privileged user |
| C: Client-side + separate audit EF | Client does REST operation, then calls a generic `log-admin-action` EF | Fewer specific EFs | Two round-trips; audit could fail silently if second call drops |

**Recommendation: Option A — keep all as Edge Functions.**

Rationale:
- 15–20 users means these functions are called rarely (a few times per week)
- Each is < 50 lines of use-case code
- The audit-guaranteed pattern is more reliable than triggers or two-call patterns
- Eliminating 5 simple functions saves ~3 days of implementation but adds trigger complexity and debugging risk

### UNNECESSARY (0 functions)

No function was found to be completely unnecessary. Every planned Edge Function either:
- Handles multi-table atomicity
- Requires service_role access to write to blocked tables
- Performs security-sensitive operations (token hashing, PII anonymization)
- Dispatches notifications (requires service_role for notification_inbox + FCM)

## Redundant Backend Layers: None Found

The architecture already follows BaaS-first:
- 63 REST operations go directly to PostgREST (no backend proxy)
- Edge Functions are only used where server trust is required
- No unnecessary middleware, API gateway, or backend-for-frontend pattern

## Operations Already Protected by RLS: Verified

All 63 REST operations rely on RLS exclusively. No Edge Function duplicates RLS protection. The only overlap is where Edge Functions use service_role to bypass RLS intentionally (for service-only tables).

## Operations Using Realtime Only: Verified

7 Realtime channels are correctly scoped to live UI updates. No Edge Function is used where Realtime alone would suffice. Realtime channels complement — not replace — the REST read operations.

## Optimized Architecture

### Recommended: Keep all 21 Edge Functions

| Category | Count | Justification |
|----------|-------|---------------|
| Auth | 3 | Token security, profile creation atomicity |
| Feed | 2 | Multi-table atomic + mention parsing |
| Events | 4 | Atomicity + notification dispatch |
| Growth | 1 | Scheduled batch + notifications |
| Recognition | 1 | Multi-table atomic + notifications |
| Analytics | 1 | Complex aggregation + service_role writes |
| Notifications | 1 | FCM integration + service_role writes |
| Admin | 5 | Audit log integrity + PII anonymization |
| System | 2 | Scheduled maintenance + content generation |
| **Total** | **21** | — |

No functions eliminated. The original scope is already optimized.

## Impact Assessment

| Metric | Original | Optimized | Change |
|--------|----------|-----------|--------|
| Edge Functions | 21 | **21** | 0 |
| REST Operations | 63 | **63** | 0 |
| Realtime Channels | 7 | **7** | 0 |
| Implementation effort | 17–25 days | **17–25 days** | 0 |

### Security Impact
No degradation. Every function that exists has a security justification (audit integrity, token security, service_role access, PII handling).

### Maintainability Impact
Keeping all functions as Edge Functions provides a consistent pattern: every admin action = one Edge Function = one audit log entry. This is easier to understand and debug than mixed patterns (some via EF, some via REST + trigger, some via REST + separate audit call).

## Conclusion

The backend scope is already at minimum viable size. The 21 Edge Functions represent the irreducible set of operations that cannot be safely or atomically performed client-side. No optimization reduces the count without introducing complexity, fragility, or security risk elsewhere.

**Proceed with the original 21-function roadmap.**
