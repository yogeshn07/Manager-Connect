# Database V1 Handover

## Complete Database Inventory

### Tables by Module (26 total)

| Module | Table | Trigger | Notes |
|--------|-------|---------|-------|
| **Identity** | profiles | ✓ | PK mirrors auth.users; 3 helper indexes |
| | invitations | ✓ | Token hash stored (never raw); 72h expiry |
| **Feed** | posts | ✓ | Soft delete; Connect Buddy posts via author.is_system_account |
| | post_images | — | Append-only; max 4 per post (CHECK) |
| | post_reactions | ✓ | One per user per post (UNIQUE); emoji app-enforced |
| | comments | ✓ | Soft delete; flat (non-threaded) |
| | post_mentions | — | Append-only; service_role INSERT only |
| **Events** | activities | ✓ | Games/Outings/Social Connect categories; active/cancelled status |
| | activity_rsvps | ✓ | Going/Not Going/Maybe; one per user per event (UNIQUE) |
| | activity_updates | — | Append-only; organizer messages |
| | polls | ✓ | Linked to activity or standalone; closes_at + is_closed |
| | poll_options | — | Append-only; display_order CHECK >= 0 |
| | poll_votes | — | Append-only; one vote per user per poll (UNIQUE) |
| | event_attendance | ✓ | Attended/Absent; admin-recorded; one per user per event |
| **Growth** | challenges | ✓ | Fitness/Wellness types; end_date > start_date CHECK |
| | challenge_participants | — | Append-only; one per user per challenge (UNIQUE) |
| | progress_logs | ✓ | Daily logs; one per user per day per challenge (UNIQUE); value >= 0 |
| **Recognition** | recognitions | ✓ | Soft delete; 5 category tags (CHECK) |
| | recognition_recipients | — | Append-only; one per recognition per recipient (UNIQUE) |
| | recognition_reactions | ✓ | One per user per recognition (UNIQUE); emoji app-enforced |
| **Analytics** | member_monthly_stats | ✓ | Service_role write only; all-member SELECT for rankings |
| | community_health_scores | — | Service_role write only; upserted not updated; score 0–100 |
| **Notifications** | notification_inbox | — | Service_role INSERT; own-only SELECT; own UPDATE (mark read) |
| **Admin** | flagged_content | ✓ | Any member flags; admin-only SELECT/UPDATE; polymorphic content_id |
| | pinned_announcements | ✓ | All-member SELECT; admin INSERT/UPDATE; single active pin |
| | admin_audit_log | — | Fully immutable; service_role INSERT only; no UPDATE/DELETE ever |

### Trigger Coverage: 16 of 26 tables

Tables WITH trigger: profiles, invitations, posts, post_reactions, comments, activities, activity_rsvps, polls, event_attendance, challenges, progress_logs, recognitions, recognition_reactions, member_monthly_stats, flagged_content, pinned_announcements

Tables WITHOUT trigger (10 — append-only or immutable): post_images, post_mentions, activity_updates, poll_options, poll_votes, challenge_participants, recognition_recipients, community_health_scores, notification_inbox, admin_audit_log

## Migration History

| Range | Phase | Count | Domain |
|-------|-------|-------|--------|
| 001–003 | 0 | 3 | Extensions + helper functions |
| 004–009 | 1 | 6 | Identity |
| 010–021 | 2 | 13 | Feed (includes 016100 trigger) |
| 022–029 | 3 | 8 | Events core |
| 030–039 | 4 | 10 | Polls + attendance |
| 040–047 | 5 | 8 | Growth |
| 048–055 | 6 | 8 | Recognition |
| 056–062 | 7 | 7 | Analytics + notifications |
| 063–070 | 8 | 8 | Admin |
| **Total** | | **71** | |

## RLS Summary

- **114 policies** across 26 tables
- Every table has RLS enabled
- 3 helper functions: `update_updated_at_column()`, `is_active_user()`, `is_admin()`
- `is_active_user()` and `is_admin()` use `SECURITY DEFINER` to prevent recursive RLS evaluation
- Active user guard applied to every policy on every table
- Deactivated users blocked from all data access
- Anonymous users blocked from all data access

## Realtime Tables (8)

Per `supabase-project-setup.md`, these tables need Realtime replication enabled:

| Table | Events |
|-------|--------|
| posts | INSERT |
| post_reactions | INSERT, UPDATE, DELETE |
| comments | INSERT |
| activity_rsvps | INSERT, UPDATE, DELETE |
| poll_votes | INSERT |
| progress_logs | INSERT, UPDATE |
| recognitions | INSERT |
| notification_inbox | INSERT |

## Storage Buckets (2)

| Bucket | Public | Max Size | Used By |
|--------|--------|----------|---------|
| avatars | Yes | 2 MB | profiles.avatar_url |
| post-images | No | 5 MB | post_images.storage_path |

## Known Technical Debt

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | Migration `20260620000016100` has non-standard timestamp | Low | Intentional CLI workaround; immutable per project rules |
| 2 | seed.sql is empty (Connect Buddy INSERT commented out) | Low | Will be restored when Phase 9 seed migration is created |
| 3 | Storage bucket RLS policies not yet configured | Medium | Must be configured before file upload features work |
| 4 | Realtime replication not yet enabled | Medium | Must be enabled per table before live updates work |

## Readiness for Backend API Implementation

| Component | Status |
|-----------|--------|
| All 26 tables | ✓ Created |
| All RLS policies | ✓ Active |
| All triggers | ✓ Attached |
| All indexes | ✓ Created |
| All constraints | ✓ Enforced |
| Schema drift | ✓ Zero |
| `supabase db reset` | ✓ Clean from scratch |
| Edge Function shared infra | ✓ 6 TypeScript files exist |
| Edge Function directories | ✓ 21 directories exist |

**The database is complete and ready for Edge Function implementation.**

Next steps:
1. Configure storage bucket RLS policies
2. Enable Realtime replication on 8 tables
3. Create Connect Buddy auth.users entry + restore seed.sql
4. Begin Edge Function implementation (send-notification → validate-invite-token → send-invitation → create-profile → create-post → post-connect-buddy-message)
