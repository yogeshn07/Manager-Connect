# Database Architecture Readiness Report

**Date:** 2026-06-19  
**Scope:** Complete cross-document review of all seven database design documents  
**Documents Reviewed:** database-schema-design.md, database-relationships.md, database-entity-catalogue.md, database-er-diagram.md, database-strategy.md, rls-security-policies.md, database-migrations-plan.md  
**Verdict:** **NOT READY — 25 inconsistencies identified across 7 documents requiring resolution before implementation**

---

## 1. Document Inventory

| Document | Status | Purpose |
|---|---|---|
| `database-schema-design.md` | ✓ Present | Authoritative column specifications for all 26 tables |
| `database-relationships.md` | ✓ Present | FK cardinality, ON DELETE strategy, Mermaid ER diagrams |
| `database-entity-catalogue.md` | ✓ Present | Earlier-generation entity definitions (partially stale) |
| `database-er-diagram.md` | ✓ Present | Domain-level and full-system ER diagrams |
| `database-strategy.md` | ✓ Present | Design principles, RLS matrix, indexing, lifecycle |
| `rls-security-policies.md` | ✓ Present | Per-table RLS policy design for all 26 tables |
| `database-migrations-plan.md` | ✓ Present | 70-file ordered migration plan with sprint alignment |

All seven documents are present. `database-schema-design.md` confirmed to exist.

---

## 2. Schema Verification: Tables and Domains

All documents agree on the total table count of **26 application tables** across **8 domain layers**.

| Domain | Tables | Count | Documents in Agreement |
|---|---|---|---|
| Identity | profiles, invitations | 2 | All 7 ✓ |
| Feed | posts, post_images, post_reactions, comments, post_mentions | 5 | All 7 ✓ |
| Events | activities, activity_rsvps, activity_updates, polls, poll_options, poll_votes, event_attendance | 7 | All 7 ✓ |
| Growth | challenges, challenge_participants, progress_logs | 3 | All 7 ✓ |
| Recognition | recognitions, recognition_recipients, recognition_reactions | 3 | 6/7 — see INC-01 |
| Analytics | member_monthly_stats, community_health_scores | 2 | All 7 ✓ |
| Notifications | notification_inbox | 1 | All 7 ✓ |
| Admin | flagged_content, pinned_announcements, admin_audit_log | 3 | All 7 ✓ |

---

## 3. Inconsistency Analysis

Twenty-five inconsistencies were identified across six categories. Each is numbered INC-01 through INC-25.

---

### Category A: FK Column Name Conflicts (INC-01 through INC-05)

These are the highest-risk issues. If the FK column name is inconsistent across documents, migrating using the migrations plan will create a schema that does not match what the schema-design document specifies.

---

**INC-01 — activities: `creator_id` vs `organizer_id`**

| Document | Column Name |
|---|---|
| database-schema-design.md | `creator_id` |
| database-entity-catalogue.md | `creator_id` |
| database-er-diagram.md | `creator_id` |
| database-relationships.md (Mermaid) | `organizer_id` |
| database-migrations-plan.md | `organizer_id` |

The authoritative schema-design document uses `creator_id`. The relationships document and migrations plan both use `organizer_id`. If migrations are applied as written, the built table will have `organizer_id` — not `creator_id` as the schema-design specifies.

**Resolution:** Choose one name and propagate it to all documents. `creator_id` is used in 3 of 5 documents; `organizer_id` appears more semantically precise. Decision required.

---

**INC-02 — challenges: `creator_id` vs `created_by`**

| Document | Column Name |
|---|---|
| database-schema-design.md | `creator_id` |
| database-entity-catalogue.md | `creator_id` |
| database-er-diagram.md | `creator_id` |
| database-relationships.md (Mermaid) | `created_by` |
| database-migrations-plan.md | `created_by` |

Same split as INC-01. The schema-design uses `creator_id`; the migration plan will build `created_by`.

**Resolution:** Align on one name. Note the parallel with activities — whichever name is chosen for activities should be applied consistently across all "created-by" FK columns.

---

**INC-03 — polls: `creator_id` vs `created_by`**

| Document | Column Name |
|---|---|
| database-schema-design.md | `creator_id` |
| database-entity-catalogue.md | `creator_id` |
| database-er-diagram.md | `creator_id` |
| database-relationships.md (Mermaid) | `created_by` |
| database-migrations-plan.md | `created_by` |

Same split as INC-02.

---

**INC-04 — invitations: `invited_by`/`accepted_by` vs `created_by`/`used_by`**

| Document | Creator Column | Redeemer Column |
|---|---|---|
| database-schema-design.md | `invited_by` | `accepted_by` |
| database-entity-catalogue.md | `invited_by` | `accepted_by` |
| database-er-diagram.md | `invited_by` | `accepted_by` |
| database-relationships.md (cardinality table) | `created_by` | `used_by` |

The relationships document cardinality table uses completely different names for the invitation FK columns. The Mermaid diagram in that same document uses `created_by` and `used_by`. The migration plan (Phase 1) uses `created_by` and `used_by` in the narrative but does not explicitly specify the column names for invitations.

**Resolution:** Use `invited_by` / `accepted_by` per schema-design and entity-catalogue (majority). Update relationships.md cardinality table.

---

**INC-05 — flagged_content: `flagger_id` vs `flagged_by` vs `reporter_id`**

The most severe naming inconsistency. Three different names appear across the documents for the same column.

| Document | Column Name |
|---|---|
| database-schema-design.md | `flagger_id` |
| database-entity-catalogue.md | `flagged_by` |
| database-relationships.md | `reporter_id` |
| rls-security-policies.md | `reporter_id` |
| database-migrations-plan.md | `reporter_id` |

The RLS policy `flagged_content_insert_own` explicitly references `reporter_id = auth.uid()`. If the built table has `flagger_id` or `flagged_by`, the RLS policy condition will fail silently — any member could flag content with no ownership restriction.

**Resolution:** Choose `reporter_id` (used in 3 documents including the migration plan and RLS policies). Update schema-design.md and entity-catalogue.md.

---

### Category B: Column Name Mismatches (INC-06 through INC-09)

---

**INC-06 — notification_inbox: `type` vs `notification_type`**

| Document | Column Name |
|---|---|
| database-schema-design.md | `type` |
| database-entity-catalogue.md | `type` |
| database-relationships.md (Mermaid) | `notification_type` |
| database-migrations-plan.md | `notification_type` |

`type` is a PostgreSQL reserved word. `notification_type` is the safer and more descriptive choice and is used in the migrations plan.

**Resolution:** Use `notification_type`. Update schema-design.md and entity-catalogue.md.

---

**INC-07 — notification_inbox: `resource_type`/`resource_id` vs `reference_type`/`reference_id`**

| Document | Type Column | ID Column |
|---|---|---|
| database-schema-design.md | `resource_type` | `resource_id` |
| database-entity-catalogue.md | `resource_type` | `resource_id` |
| database-relationships.md | `reference_type` | `reference_id` |
| database-migrations-plan.md | `reference_type` | `reference_id` |

The migration plan will build columns named `reference_type` and `reference_id`. The Flutter app will be built against the schema-design which says `resource_type` and `resource_id`.

**Resolution:** Choose one pair and apply everywhere. `reference_type`/`reference_id` is used in the migration plan and relationships document (2 vs 2 documents).

---

**INC-08 — notification_inbox: missing `actor_id` in schema-design**

The `actor_id` column (FK → profiles, nullable, SET NULL on delete) appears in:
- database-relationships.md (Mermaid diagram, cardinality table, narrative)
- rls-security-policies.md (referenced in design narrative)
- database-migrations-plan.md (migration 60)

The column is entirely absent from:
- database-schema-design.md (no `actor_id` column in the notification_inbox column table)
- database-entity-catalogue.md (no `actor_id` column)

`actor_id` stores who triggered the notification (nullable for system-generated notifications). It is architecturally necessary for display ("X gave you a recognition") and referenced in the migrations plan. Its absence from schema-design.md is a documentation gap.

**Resolution:** Add `actor_id` to the notification_inbox column spec in schema-design.md and entity-catalogue.md.

---

**INC-09 — recognitions: `category_tag` vs `category`**

| Document | Column Name |
|---|---|
| database-schema-design.md | `category_tag` |
| database-entity-catalogue.md | `category_tag` |
| database-relationships.md (Mermaid) | `category` |
| database-migrations-plan.md | `category` |

**Resolution:** Choose one name. `category_tag` is more descriptive and appears in the authoritative schema-design.

---

### Category C: CHECK Constraint Value Conflicts (INC-10 through INC-12)

These are critical. The Flutter app's domain enums must match the database CHECK constraints exactly. If any document is used as the source of truth for enum values and it conflicts with another, the wrong values will be implemented.

---

**INC-10 — admin_audit_log: `action_type` CHECK values differ across documents**

| Source | action_type values |
|---|---|
| database-schema-design.md | `user_invited, user_deactivated, user_reactivated, user_removed, invitation_revoked, post_deleted, comment_deleted, flag_resolved_deleted, flag_resolved_dismissed, content_pinned, content_unpinned, attendance_recorded, poll_closed` |
| database-entity-catalogue.md | Same as schema-design (13 values) |
| database-migrations-plan.md | `member_deactivated, member_reactivated, member_role_changed, content_deleted, content_restored, flag_resolved, flag_dismissed, announcement_pinned, announcement_unpinned, attendance_recorded, challenge_created, challenge_ended, invite_created` |

These are entirely different value sets. The migration plan will build a constraint that does not match what the schema-design and entity-catalogue document.

Notable differences:
- `user_invited` (schema) vs `invite_created` (migrations)
- `user_removed` exists only in schema (missing from migrations)
- `member_role_changed`, `content_restored`, `challenge_created`, `challenge_ended` exist only in migrations
- `flag_resolved_deleted` / `flag_resolved_dismissed` (schema) vs `flag_resolved` / `flag_dismissed` (migrations)

**Resolution:** Reconcile the value sets into a single definitive list. The schema-design values appear more complete and better-named. The migration plan value list must be updated to match.

---

**INC-11 — challenges: `goal_type` CHECK values differ**

| Document | goal_type values |
|---|---|
| database-schema-design.md | `('steps', 'distance', 'duration', 'custom')` |
| database-entity-catalogue.md | `('steps', 'distance', 'duration', 'custom')` |
| database-migrations-plan.md | `('steps', 'minutes_active', 'workouts_completed', 'km_run', 'custom')` |

The migrations plan uses entirely different vocabulary: `minutes_active` instead of `duration`, `km_run` instead of `distance`, and adds `workouts_completed`. These would create a database schema that rejects values the application layer expects to write (e.g., writing `'duration'` would fail the CHECK constraint if the migrations plan is used).

**Resolution:** Use schema-design values (`steps, distance, duration, custom`). Update migrations-plan.md.

---

**INC-12 — recognitions: `category_tag` CHECK values differ**

| Document | category values |
|---|---|
| database-schema-design.md | `('community_contributor', 'fitness_champion', 'wellness_champion', 'event_champion', 'most_supportive_manager')` |
| database-entity-catalogue.md | `('community_contributor', 'fitness_champion', 'wellness_champion', 'event_champion', 'most_supportive_manager')` |
| database-migrations-plan.md | `('community_contributor', 'fitness_champion', 'wellness_champion', 'event_champion', 'most_supportive_manager')` |

**Resolution:** RESOLVED. All documents aligned to the canonical 5 values: `community_contributor`, `fitness_champion`, `wellness_champion`, `event_champion`, `most_supportive_manager`. Backend API contracts, user flows, folder structure, and frontend specifications all updated to match.

---

### Category D: Missing and Extra Columns (INC-13 through INC-17)

---

**INC-13 — progress_logs: `challenge_participant_id` missing from entity-catalogue**

`challenge_participant_id` (FK → challenge_participants.id, CASCADE) is documented in:
- database-schema-design.md ✓
- database-relationships.md ✓ (Mermaid diagram, cardinality table)
- database-migrations-plan.md ✓

Missing from:
- database-entity-catalogue.md — column is absent from the progress_logs table definition

**Resolution:** Add `challenge_participant_id` to entity-catalogue.md. This column is needed for the double-FK optimization documented in the Growth relationship narrative.

---

**INC-14 — challenges: column set divergence across 3 documents**

| Column | schema-design | entity-catalogue | migrations-plan |
|---|---|---|---|
| `challenge_type` CHECK(fitness/wellness) | ✓ Present | ✗ Absent | ✗ Absent |
| `goal_type` | `steps/distance/duration/custom` | `steps/distance/duration/custom` | `steps/minutes_active/workouts_completed/km_run/custom` |
| `goal_description` | ✓ Present | ✗ Absent | ✗ Absent |
| `goal_unit` | ✗ Absent | ✓ Present | ✗ Absent |
| `goal_value` | ✗ Absent | ✓ Present | ✗ Absent |
| `goal_target` | ✗ Absent | ✗ Absent | ✓ Present |
| `unit_label` | ✗ Absent | ✗ Absent | ✓ Present |

The challenges table has a three-way split in how the goal is expressed. This indicates the column design was revisited at different stages without propagating updates across all documents.

**Resolution:** Decide the canonical column design for challenge goals. The schema-design.md pattern (`challenge_type`, `goal_type`, `goal_description`) uses the fewest columns but least flexibility. The entity-catalogue pattern (`goal_type`, `goal_unit`, `goal_value`) is more flexible. All documents must converge.

---

**INC-15 — member_monthly_stats: column differences across documents**

| Column | schema-design | entity-catalogue | migrations-plan |
|---|---|---|---|
| `events_attended` | ✓ | ✓ | ✓ |
| `attendance_rate` | ✓ (numeric 5,2) | ✗ Absent | ✗ Absent |
| `challenges_joined` | ✓ | ✓ | ✗ (`challenges_completed`) |
| `progress_logs_count` | ✓ | ✓ | ✗ Absent |
| `recognitions_received` | ✓ | ✓ | ✓ |
| `recognitions_given` | ✓ | ✓ | ✓ |
| `posts_count` | ✓ | ✓ | ✗ (`posts_authored`) |
| `composite_score` | ✓ | ✗ Absent | ✓ |
| `computed_at` | ✓ | ✓ | ✗ Absent |
| `comments_made` | ✗ Absent | ✗ Absent | ✓ |

The migrations plan uses `challenges_completed` instead of `challenges_joined`, `posts_authored` instead of `posts_count`, and adds `comments_made`. The schema-design includes `attendance_rate` and `composite_score` which the entity-catalogue lacks. These tables power the Analytics/Rankings screens — the column names must match the Flutter analytics providers exactly.

**Resolution:** The schema-design column set is the most complete. Reconcile entity-catalogue and migrations-plan against schema-design.

---

**INC-16 — community_health_scores: 3-way column split**

This is the most structurally diverged table.

| Column | schema-design | entity-catalogue | relationships + migrations |
|---|---|---|---|
| `score` | ✓ | ✗ | ✗ |
| `health_score` | ✗ | ✓ | ✗ |
| `overall_score` | ✗ | ✗ | ✓ |
| `active_member_count` | ✓ | ✗ | ✗ |
| `active_challenge_participants` | ✗ | ✓ | ✗ |
| `recognitions_count` | ✗ | ✓ | ✗ |
| `avg_attendance_rate` | ✓ | ✓ | ✗ (`event_attendance_rate`) |
| `challenge_engagement_rate` | ✓ | ✗ | ✓ (`challenge_completion_rate`) |
| `recognition_activity_rate` | ✓ | ✗ | ✓ (`recognition_rate`) |
| `participation_rate` | ✓ | ✓ | ✓ |
| `engagement_rate` | ✗ | ✗ | ✓ |

All three versions use different names for the primary score column (`score`, `health_score`, `overall_score`). Each document independently evolved a different column design.

**Resolution:** Requires a single authoritative column decision. The schema-design version is the most detailed. The relationships and migrations documents must be updated to match.

---

**INC-17 — Schema-design trigger list includes notification_inbox (internal inconsistency)**

Within database-schema-design.md itself:
- The `notification_inbox` table definition (column list) does **not** include an `updated_at` column — correct, as the table is described as append-only.
- However, the Trigger Specification section (line 1015) lists `notification_inbox` as one of the 17 tables with the `update_updated_at_column()` trigger.

A trigger cannot be attached to a table for a column that does not exist.

**Resolution:** Remove `notification_inbox` from the trigger list in schema-design.md. The trigger count should be 16, not 17.

---

### Category E: Domain Classification (INC-18)

---

**INC-18 — recognitions domain: "Recognition" vs "Analytics"**

| Document | Domain for recognitions/recognition_recipients/recognition_reactions |
|---|---|
| database-schema-design.md | Recognition (Layer 5) |
| database-relationships.md | Recognition |
| database-strategy.md | Recognition |
| database-er-diagram.md | Recognition (Diagram 4), also Analytics (Diagram 6) |
| database-migrations-plan.md | Recognition (Phase 5) |
| database-entity-catalogue.md | Analytics (rows 18–20 in schema summary) |

The entity-catalogue classifies recognitions under Analytics, which contradicts all other documents. The er-diagram.md shows recognitions in both "Diagram 4: Recognition Wall" and "Diagram 6: Analytics" — a dual placement that should be resolved.

**Resolution:** Recognitions domain is "Recognition" per the final-zero-gap-audit.md and schema-design. Update entity-catalogue.md schema summary to reflect "Recognition" domain.

---

### Category F: RLS Policy Conflicts (INC-19 through INC-24)

The database-strategy.md contains an older RLS policy matrix that conflicts with the authoritative rls-security-policies.md on six points.

---

**INC-19 — activities INSERT: "Any authenticated" vs "Admin only"**

| Document | activities INSERT |
|---|---|
| database-strategy.md | Any authenticated |
| rls-security-policies.md | Admin only |

**Resolution:** rls-security-policies.md is the authoritative document. Activities are admin-created, not member-created. Update strategy.md matrix.

---

**INC-20 — challenges INSERT: "Any authenticated" vs "Admin only"**

| Document | challenges INSERT |
|---|---|
| database-strategy.md | Any authenticated |
| rls-security-policies.md | Admin only |

**Resolution:** rls-security-policies.md is authoritative. Update strategy.md matrix.

---

**INC-21 — polls INSERT: "Any authenticated" vs "Admin only"**

| Document | polls INSERT |
|---|---|
| database-strategy.md | Any authenticated (or Edge Fn) |
| rls-security-policies.md | Admin only |

**Resolution:** rls-security-policies.md is authoritative. Update strategy.md matrix.

---

**INC-22 — post_mentions SELECT: "Own mentions only" vs "All authenticated"**

| Document | post_mentions SELECT |
|---|---|
| database-strategy.md | Own mentions only (WHERE mentioned_user_id = auth.uid()) |
| rls-security-policies.md | All authenticated members |
| database-entity-catalogue.md | Own mentions only |

This is a security design decision: should members be able to see who else was mentioned in a post, or only their own mentions? The entity-catalogue aligns with strategy.md (own only). The rls-security-policies.md grants broader access. If this column drives notification routing only and is never exposed in UI, "own only" may be the correct stricter policy.

**Resolution:** Decide the intended access model. Update all three documents to match the decision.

---

**INC-23 — community_health_scores SELECT: "Admin only" vs "All authenticated"**

| Document | community_health_scores SELECT |
|---|---|
| database-strategy.md | Admin only (Edge Fn reads for analytics) |
| rls-security-policies.md | All authenticated members can view |

This is a product design decision: is the community health score visible to all members on the Analytics tab, or admin-only? The analytics screens are described as member-visible, suggesting all members should see it.

**Resolution:** If community health is shown to all members on the Analytics tab (as implied by the flutter-architecture.md), then rls-security-policies.md is correct. Update strategy.md matrix.

---

**INC-24 — notification_inbox DELETE: "Own rows" vs "Blocked"**

| Document | notification_inbox DELETE |
|---|---|
| database-strategy.md | Own rows (members can delete their own notifications) |
| rls-security-policies.md | Blocked for all — notifications are never deleted |

This affects the notification inbox UX: can a user clear/delete individual notifications, or is the inbox always append-only?

**Resolution:** Decide the product behavior. If the inbox is append-only (rls-security-policies.md), delete is blocked and notifications are only marked as read. Update strategy.md to reflect this.

---

### Category G: Erroneous Migration Files (INC-25)

---

**INC-25 — Migrations plan creates two updated_at triggers for tables without updated_at columns**

The migrations plan includes trigger attachment migrations for two tables that have no `updated_at` column per schema-design.md:

| Migration | Table | Issue |
|---|---|---|
| `20240101000030_create_activity_updates_updated_at_trigger.sql` | `activity_updates` | schema-design.md lists this as append-only with no updated_at; trigger section confirms it is NOT in the 17-table list |
| `20240101000059_create_community_health_scores_updated_at_trigger.sql` | `community_health_scores` | schema-design.md explicitly states "No updates needed; rows are upserted by primary key"; trigger section confirms NOT in the list |

If these migrations are applied, PostgreSQL will throw an error when the trigger tries to reference a non-existent `updated_at` column, aborting the migration sequence.

**Resolution:** Remove these two migration files from the plan. Total migration count reduces from 70 to 68.

---

## 4. Severity Summary

| Severity | Count | INC Numbers |
|---|---|---|
| Critical — will cause migration failure or silent RLS bypass | 5 | INC-05, INC-10, INC-11, INC-25 (×2 files) |
| High — column name will break application-layer integration | 9 | INC-01, INC-02, INC-03, INC-04, INC-06, INC-07, INC-08, INC-09, INC-12 |
| Medium — column design incomplete or diverged | 5 | INC-13, INC-14, INC-15, INC-16, INC-17 |
| Low — documentation alignment only | 6 | INC-18, INC-19, INC-20, INC-21, INC-22, INC-23, INC-24 |

---

## 5. Document Trust Hierarchy

Based on this review, the following trust order applies when conflicts exist:

1. **database-schema-design.md** — Most complete, most detailed, most recently aligned. Use as the authoritative source for column names, types, constraints, and indexes. Exception: `notification_inbox` trigger list (INC-17) is internally inconsistent and must be corrected.

2. **rls-security-policies.md** — Authoritative for all RLS policy design. The strategy.md matrix is older and should be treated as a summary that requires updating.

3. **database-migrations-plan.md** — Authoritative for migration file ordering and sprint alignment, but contains FK column name variants and CHECK constraint value differences that must be reconciled against schema-design.md before migrations are written.

4. **database-relationships.md** — Authoritative for ON DELETE strategy and relationship cardinality narratives. Mermaid diagrams use slightly different column names (INC-01 through INC-04, INC-09) that require updates.

5. **database-er-diagram.md** — Largely consistent with entity-catalogue. Diagrams should be updated after column names are finalized.

6. **database-entity-catalogue.md** — Partially stale. Several tables (notification_inbox, challenges, member_monthly_stats) have incomplete column sets relative to schema-design. The domain classification for recognitions (INC-18) requires correction. Treat as a secondary reference until updated.

7. **database-strategy.md** — RLS matrix (Category F inconsistencies) is outdated relative to rls-security-policies.md. Design principles and scalability sections remain valid.

---

## 6. Resolution Plan

### Before Writing Any Migration

These must be resolved first — implementing migrations with these conflicts will produce a broken schema:

1. **Decide `creator_id` vs `created_by` vs `organizer_id`** for activities, challenges, polls (INC-01, INC-02, INC-03). Apply the chosen pattern consistently across all documents.
2. **Decide `invited_by`/`accepted_by` vs `created_by`/`used_by`** for invitations (INC-04).
3. **Settle on `reporter_id`** for flagged_content (INC-05) — the RLS policy depends on this name.
4. **Decide `notification_type` vs `type`**, and `reference_type`/`reference_id` vs `resource_type`/`resource_id`** for notification_inbox (INC-06, INC-07).
5. **Add `actor_id`** to notification_inbox in schema-design.md (INC-08).
6. **Reconcile admin_audit_log action_type values** into one definitive list (INC-10).
7. **Reconcile challenges goal_type CHECK values** (INC-11).
8. **Remove two erroneous trigger migrations** from migrations-plan.md (INC-25).

### Before Sprint 1 Development

9. **Decide recognition category values** (INC-12) — this is a product decision.
10. **Reconcile community_health_scores column set** across all three versions (INC-16).
11. **Reconcile member_monthly_stats column set** (INC-15).
12. **Finalize challenges column design** (`challenge_type` + `goal_description` vs `goal_unit`/`goal_value`) (INC-14).
13. **Fix schema-design trigger list** — remove notification_inbox, count should be 16 tables (INC-17).

### Documentation Cleanup

14. **Update entity-catalogue** recognitions domain from "Analytics" to "Recognition" (INC-18).
15. **Update strategy.md RLS matrix** for activities, challenges, polls, post_mentions, community_health_scores, notification_inbox DELETE (INC-19 through INC-24).
16. **Add challenge_participant_id** to entity-catalogue progress_logs definition (INC-13).
17. **Align recognitions column name** to `category_tag` in relationships.md and migrations-plan.md (INC-09).
18. **Update relationships.md** Mermaid diagrams and cardinality table to use the finalized column names once INC-01 through INC-05 are resolved.

---

## 7. Verified Consistent Elements

The following elements are consistent across all relevant documents and require no changes:

| Element | Status |
|---|---|
| Total table count (26) | ✓ All documents agree |
| Domain layer structure (8 layers) | ✓ All documents agree |
| UUID primary keys throughout | ✓ All documents agree |
| Soft delete pattern (is_deleted, deleted_at, deleted_by) on posts, comments, recognitions | ✓ All documents agree |
| UNIQUE constraints on all junction tables | ✓ All documents agree |
| poll_votes immutability (no UPDATE or DELETE) | ✓ All documents agree |
| admin_audit_log immutability (no updated_at, no UPDATE/DELETE) | ✓ All documents agree |
| pinned_announcements single-active-pin invariant | ✓ All documents agree |
| flagged_content polymorphic content_id (no FK constraint) | ✓ All documents agree |
| notification_inbox polymorphic reference column (no FK constraint) | ✓ All documents agree |
| is_admin() SECURITY DEFINER function | ✓ All documents agree |
| Active user guard pattern across all RLS policies | ✓ All documents agree |
| 15 notification type values | ✓ All documents agree |
| Storage buckets (avatars, post-images) | ✓ All documents agree |
| ON DELETE CASCADE strategy for child tables | ✓ All documents agree |
| ON DELETE RESTRICT for authored content parents | ✓ All documents agree |
| Forward-only migration philosophy | ✓ All documents agree |
| Sprint alignment (Phase 0–3 Sprint 1, Phase 4–5 Sprint 2, Phase 6–8 Sprint 3) | ✓ All documents agree |
| Edge Functions bypass RLS via service_role | ✓ All documents agree |
| PII anonymization on user removal (not cascade delete) | ✓ All documents agree |

---

## 8. Final Readiness Verdict

| Readiness Gate | Status |
|---|---|
| All 7 documents present | ✓ PASS |
| database-schema-design.md exists | ✓ PASS |
| Table count consistent across documents | ✓ PASS |
| Domain classification consistent | ✗ FAIL — INC-18 |
| FK column names consistent | ✗ FAIL — INC-01 through INC-05 |
| Notification_inbox complete (actor_id, column names) | ✗ FAIL — INC-06, INC-07, INC-08 |
| CHECK constraint values consistent | ✗ FAIL — INC-10, INC-11, INC-12 |
| Analytics table columns consistent | ✗ FAIL — INC-15, INC-16 |
| Challenges table columns consistent | ✗ FAIL — INC-14 |
| RLS policies consistent (strategy vs policies doc) | ✗ FAIL — INC-19 through INC-24 |
| Migration plan free of erroneous operations | ✗ FAIL — INC-25 |
| Schema-design.md internally consistent | ✗ FAIL — INC-17 |

**Overall verdict: NOT READY FOR IMPLEMENTATION**

**25 inconsistencies identified.** 5 are critical (will cause migration failure or silent security bypass). 9 are high severity (will break application-layer integration at build time). The database design phase requires a reconciliation pass before any migration file is written.

The recommended path forward:
1. Resolve all Critical and High severity items (INC-01 through INC-12, INC-25) in a single reconciliation session
2. Update all affected documents to reflect the resolved decisions
3. Re-run this readiness review to confirm zero remaining inconsistencies
4. Only then proceed to writing and applying migration files
