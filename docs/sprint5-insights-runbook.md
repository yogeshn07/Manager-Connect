# Catalyst Insights — Operational Runbook

**Module:** Catalyst Insights  
**Version:** 1.0.0+1  
**Sprint:** Sprint 5 — Insights Integration  
**Date:** 2026-07-21

---

## Architecture Overview

```
Flutter App (The Catalysts)
    ├── InsightsFeedScreen     → catalyst_insights (RLS: status='active', auth required)
    ├── InsightDetailScreen    → catalyst_insights (single row, same RLS)
    ├── SubmitInsightScreen    → collect-insight Edge Function (JWT required)
    ├── SubmissionHistoryScreen → insights_raw (RLS: submitted_by = auth.uid())
    ├── ReviewQueueScreen      → review-insight Edge Function (admin JWT required)
    └── PipelineHealthScreen   → insights_raw + catalyst_insights (admin RLS SELECT)

Pipeline:
    URL submission → insights_raw (status: pending)
                  → [collect-insight EF] → validated / ai_error
                  → [AI enrichment] → ai_processed
                  → catalyst_insights (status: review)
                  → [Admin review] → active (published) / archived (rejected)
```

---

## 1. Monitoring

### What to Watch

| Signal | Location | Threshold to Investigate |
|--------|----------|--------------------------|
| `insights_raw` rows with `status = 'ai_error'` | DB query or PipelineHealthScreen | > 5 in 24h |
| `insights_raw` rows with `status = 'validated'` and `updated_at` > 15 min ago | PipelineHealthScreen "Stalled" counter | > 0 |
| `catalyst_insights` rows with `status = 'review'` | ReviewQueueScreen | Queue age > 48h (admin should review) |
| Edge Function errors | Supabase dashboard → Edge Functions → Logs | Any 5xx |
| `ingestedLast24h` metric | PipelineHealthScreen "Ingested (24h)" chip | < 1 sustained over 48h may indicate pipeline stall |

### Checking Pipeline Health (Admin)

In the app, navigate to Profile → Admin → Pipeline Health (or route directly to `/admin/insights/pipeline`).

The dashboard shows:
- **Failed**: rows in `insights_raw` with `status = 'ai_error'`
- **Stalled**: rows in `insights_raw` with `status = 'validated'` and `updated_at` older than 15 minutes
- **Ingested (24h)**: rows created in `insights_raw` within the last 24 hours

### Direct DB Queries (Supabase Dashboard)

```sql
-- Failed enrichment jobs
SELECT id, raw_url, updated_at
FROM insights_raw
WHERE status = 'ai_error'
ORDER BY updated_at DESC
LIMIT 20;

-- Stalled validation jobs (stuck > 15 min)
SELECT id, raw_url, updated_at
FROM insights_raw
WHERE status = 'validated'
  AND updated_at < now() - interval '15 minutes'
ORDER BY updated_at ASC
LIMIT 20;

-- Review queue depth
SELECT COUNT(*) FROM catalyst_insights WHERE status = 'review';

-- Published in last 7 days
SELECT COUNT(*) FROM catalyst_insights
WHERE status = 'active'
  AND published_at > now() - interval '7 days';
```

---

## 2. Common Issues and Resolutions

### Issue: Insights Feed Shows Error State ("Failed to load insights")

**Cause:** `catalyst_insights` RLS check failed or Supabase connection error.

**Diagnosis:**
1. Check Supabase status: https://status.supabase.com
2. In Supabase dashboard → Logs → API logs, look for 4xx/5xx on `catalyst_insights`
3. Test direct query: `select count(*) from catalyst_insights where status = 'active'`

**Resolution:**
- If Supabase is down: wait for recovery, communicate to beta testers
- If RLS mismatch: verify the user is authenticated (auth.uid() not null)
- If no rows: insert a test insight with `status = 'active'` to confirm the route works

---

### Issue: Submit Insight Returns Error ("Failed to submit")

**Cause:** `collect-insight` Edge Function returned a non-2xx response.

**Diagnosis:**
1. Supabase dashboard → Edge Functions → collect-insight → Logs
2. Look for the specific error body: `{"error": {"code": "...", "message": "..."}}`

**Common causes:**

| Error Code | Meaning | Action |
|------------|---------|--------|
| `VALIDATION_ERROR` | URL or source_id is invalid | Check form validation in SubmitInsightScreen |
| `DUPLICATE_URL` | URL already in pipeline | Not a bug; inform user the URL was already submitted |
| `UNAUTHORIZED` | JWT missing or expired | User needs to sign back in |
| `FUNCTION_ERROR` | Internal EF crash | Check EF logs for stack trace |

---

### Issue: Review Queue Shows "Failed to load" (Admin)

**Cause:** `review-insight { action: 'list' }` Edge Function failed.

**Diagnosis:**
1. Supabase dashboard → Edge Functions → review-insight → Logs
2. Confirm the user has `is_admin = true` in their `profiles` row
3. Test with service role in Supabase SQL editor

**Resolution:**
- If non-admin accidentally reached the screen: route guard issue — check `RouteGuard.requireAdmin`
- If admin user affected: redeploy `review-insight` if logs show EF crash

---

### Issue: Pipeline Health Reads Stale Data

**Cause:** `getPipelineHealth()` runs two queries on every refresh but has no caching layer. If queries run 10+ seconds apart, the `checkedAt` timestamp may not represent both reads.

**Behaviour:** Expected and documented. The `checkedAt` field in `PipelineHealthDto` represents when the second query completed. For monitoring purposes this is accurate within seconds.

**Resolution:** No action needed. This is by design — `getPipelineHealth()` is a read-only diagnostic, not an audit record.

---

### Issue: PipelineHealthScreen Shows Incorrect "Avg Time to Publish"

**Cause:** `avgTimeToPublishMs` is computed from a sample of up to 50 `active` insights where both `published_at` and `created_at` are non-null. If few insights are published, the sample is small and the average may be skewed.

**Resolution:** Monitor trend over time, not individual values. No code fix needed.

---

### Issue: SubmissionHistoryScreen Shows "Could not load submissions"

**Cause:** `insights_raw` RLS `WHERE submitted_by = auth.uid()` failed.

**Diagnosis:**
- Check that the current user's session is valid
- Verify `profiles.id` matches `auth.users.id` for this user
- Check `insights_raw` RLS policy: `SELECT` where `submitted_by = auth.uid()`

---

## 3. Admin Workflows

### Publishing an Insight

1. Admin navigates to `/admin/insights/review`
2. Reviews the headline, summary, why-matters, key-takeaway, tags, and confidence score
3. Taps **Publish** → calls `review-insight { action: 'approve', insight_id: ... }`
4. Row in `catalyst_insights` transitions: `review` → `active`, `published_at = now()`, `reviewed_by = admin_user_id`
5. Insight appears in member feed within seconds (RLS selects `status = 'active'`)

### Rejecting an Insight

1. Admin taps **Reject** on a review queue item
2. Optionally enters a rejection reason in the dialog
3. Taps Confirm → calls `review-insight { action: 'reject', insight_id: ..., rejection_reason: ... }`
4. Row transitions: `review` → `archived`
5. Item disappears from queue immediately

### Investigating a Failed Enrichment Job

1. Admin navigates to `/admin/insights/pipeline`
2. Notes the **Failed** count in the signals grid
3. Scrolls down to the **Failed Jobs** list (if visible)
4. In Supabase, queries `insights_raw WHERE status = 'ai_error'` for the raw URL
5. Manually re-triggers enrichment (currently only possible via Supabase dashboard direct UPDATE or service-role API call)

> Note: The Flutter client cannot update `insights_raw` rows. The `insights_raw_update_blocked` RLS policy blocks all UPDATEs for authenticated users. Re-triggering failed jobs requires the Supabase dashboard or a service-role call.

---

## 4. Edge Function Reference

### collect-insight

| Field | Value |
|-------|-------|
| Path | `supabase/functions/collect-insight/` |
| Auth | JWT (any authenticated user) |
| Input | `{ url: string, source_id: string }` |
| Success response | `{ raw_id: string, status: "queued" }` |
| Failure response | `{ error: { code: string, message: string } }` |

### review-insight

| Field | Value |
|-------|-------|
| Path | `supabase/functions/review-insight/` |
| Auth | JWT (admin only — checked against `profiles.is_admin`) |
| Input (list) | `{ action: "list" }` |
| Input (approve) | `{ action: "approve", insight_id: string }` |
| Input (reject) | `{ action: "reject", insight_id: string, rejection_reason?: string }` |
| Success response | Varies per action |
| Failure response | `{ error: { code: string, message: string } }` |

---

## 5. Database Table Reference

| Table | Primary Key | Key Columns | Notes |
|-------|-------------|-------------|-------|
| `insights_sources` | `id` (uuid) | `name`, `approved_domain`, `tier`, `is_active` | Source allow-list. Members see only `is_active = true` rows. |
| `insights_raw` | `id` (uuid) | `raw_url`, `status`, `submitted_by`, `source_id` | Pipeline queue. Status: pending → validated / ai_error → ai_processed |
| `catalyst_insights` | `id` (uuid) | `raw_id`, `status`, `ai_headline`, `category`, `published_at` | Published content. Status: review → active / archived |

---

## 6. On-Call Decision Matrix

| Observation | Urgency | First Action |
|-------------|---------|-------------|
| App crashes on launch | Immediate | APK rollback → investigate |
| Feed shows error for all users | High | Check Supabase status → check RLS |
| Submit fails for all users | High | Check collect-insight EF logs |
| Review queue inaccessible for admin | Medium | Verify admin JWT → check review-insight EF |
| Pipeline health shows high failed count | Medium | Check insights_raw → investigate EF |
| Single user can't see their submissions | Low | Verify auth session → check submitted_by |
| Performance degradation (slow feed) | Low | Check Supabase connection pool / cold start |
