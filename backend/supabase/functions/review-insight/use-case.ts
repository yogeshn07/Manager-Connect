// review-insight — Use case
// Admin Review Workflow for Catalyst Insights (S3-BE-005)
//
// Responsibilities:
//   ✅ Fetch pending review insights — status='review', ordered ai_confidence DESC
//   ✅ Approve insight: review → active, published_at = now(), reviewed_by, reviewed_at
//   ✅ Reject insight:  review → archived,                    reviewed_by, reviewed_at
//   ✅ Status guard: approve/reject both verify status='review' before writing
//   ✅ Optimistic lock: UPDATE WHERE status='review' + RETURNING prevents races
//   ✅ Audit log: insight_approved / insight_rejected → admin_audit_log (non-fatal on failure)
//   ✅ Input validation: insight_id required, UUID format enforced
//   ✅ Authorization: admin identity passed from index.ts (requireAdmin enforced upstream)
//
//   ❌ Does NOT transition to 'scheduled' status (separate sprint)
//   ❌ Does NOT send member notifications
//   ❌ Does NOT touch insights_raw, collect_insight, validate_insight, or enrich_insight
//
// Audit note: writes directly to admin_audit_log without going through the shared
// audit.service.ts, to avoid modifying that production-stable shared module (Phase 9).
// Requires migration 20260718000001 which extends the action_type and target_type
// CHECK constraints to include 'insight_approved', 'insight_rejected', and 'insight'.

import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';

// ─── UUID validation ──────────────────────────────────────────────────────────
const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ─── Status constants (mirror catalyst_insights CHECK constraint) ──────────────
const STATUS_REVIEW   = 'review'   as const;
const STATUS_ACTIVE   = 'active'   as const;
const STATUS_ARCHIVED = 'archived' as const;

// ─── Public result types ───────────────────────────────────────────────────────

export interface ReviewInsight {
  id:                   string;
  ai_headline:          string | null;
  ai_summary:           string | null;
  ai_why_matters:       string | null;
  ai_key_takeaway:      string | null;
  ai_tags:              string[];
  ai_confidence:        number | null;
  category:             string;
  source_name:          string | null;
  source_url:           string | null;
  article_date:         string | null;
  reading_time_minutes: number | null;
  hero_image_url:       string | null;
  is_evergreen:         boolean;
  created_at:           string;
}

export interface ReviewListResult {
  insights: ReviewInsight[];
  count:    number;
}

export interface ReviewActionResult {
  insight_id:      string;
  previous_status: string;
  new_status:      string;
  reviewed_by:     string;
  reviewed_at:     string;
}

// ─── Input validators ──────────────────────────────────────────────────────────

interface ApproveInput {
  insight_id: string;
}

interface RejectInput {
  insight_id:       string;
  rejection_reason: string | null;
}

function validateApproveInput(body: unknown): ApproveInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.insight_id !== 'string' || !b.insight_id.trim()) {
    throw new AppError('VALIDATION_ERROR', 'insight_id is required');
  }
  if (!UUID_REGEX.test(b.insight_id.trim())) {
    throw new AppError('VALIDATION_ERROR', 'insight_id must be a valid UUID');
  }
  return { insight_id: b.insight_id.trim() };
}

function validateRejectInput(body: unknown): RejectInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.insight_id !== 'string' || !b.insight_id.trim()) {
    throw new AppError('VALIDATION_ERROR', 'insight_id is required');
  }
  if (!UUID_REGEX.test(b.insight_id.trim())) {
    throw new AppError('VALIDATION_ERROR', 'insight_id must be a valid UUID');
  }
  const rejectionReason =
    typeof b.rejection_reason === 'string' && b.rejection_reason.trim()
      ? b.rejection_reason.trim()
      : null;
  return { insight_id: b.insight_id.trim(), rejection_reason: rejectionReason };
}

// ─── Audit log writer ──────────────────────────────────────────────────────────
// Writes directly to admin_audit_log rather than going through the shared
// writeAuditLog() helper (which has a TypeScript union that doesn't include
// insight action types, and modifying it would violate Phase 9 new-files-only rule).
//
// Non-fatal: a failed audit log write logs to stderr but does NOT roll back the
// primary status transition. Admin action already succeeded; losing the audit entry
// is operationally preferable to leaving the insight stuck in 'review'.

async function writeInsightAuditLog(
  adminClient:  ReturnType<typeof createAdminClient>,
  adminId:      string,
  actionType:   'insight_approved' | 'insight_rejected',
  insightId:    string,
  metadata:     Record<string, unknown>,
): Promise<void> {
  if (!UUID_REGEX.test(adminId)) return;

  const { error } = await adminClient.from('admin_audit_log').insert({
    admin_id:    adminId,
    action_type: actionType,
    target_type: 'insight',
    target_id:   insightId,
    metadata,
  });

  if (error) {
    console.error('Failed to write insight audit log:', error.message);
  }
}

// ─── Handlers ─────────────────────────────────────────────────────────────────

// Returns all catalyst_insights in 'review' status, sorted so the highest-confidence
// insights appear first (aids admin decision-making — high confidence = approve quickly).
// Secondary sort: newest first within the same confidence band.
export async function handleListReview(): Promise<ReviewListResult> {
  const adminClient = createAdminClient();

  const { data, error } = await adminClient
    .from('catalyst_insights')
    .select([
      'id',
      'ai_headline',
      'ai_summary',
      'ai_why_matters',
      'ai_key_takeaway',
      'ai_tags',
      'ai_confidence',
      'category',
      'source_name',
      'source_url',
      'article_date',
      'reading_time_minutes',
      'hero_image_url',
      'is_evergreen',
      'created_at',
    ].join(', '))
    .eq('status', STATUS_REVIEW)
    .order('ai_confidence', { ascending: false })
    .order('created_at',    { ascending: false });

  if (error) {
    throw new AppError('SERVER_ERROR', `Failed to fetch review queue: ${error.message}`);
  }

  const insights = (data ?? []) as ReviewInsight[];
  return { insights, count: insights.length };
}

// Transitions a single insight from 'review' to 'active' (published).
// Sets published_at = now(), reviewed_by = adminId, reviewed_at = now().
// Uses an optimistic WHERE status='review' on the UPDATE with RETURNING to detect
// concurrent modifications — if another admin approved/rejected simultaneously,
// the update touches 0 rows and we surface a CONFLICT error instead of silently succeeding.
export async function handleApproveInsight(
  body:    unknown,
  adminId: string,
): Promise<ReviewActionResult> {
  const input = validateApproveInput(body);
  const adminClient = createAdminClient();
  const now = new Date().toISOString();

  // Verify existence and current status before attempting write
  const { data: insight, error: fetchError } = await adminClient
    .from('catalyst_insights')
    .select('id, status')
    .eq('id', input.insight_id)
    .single();

  if (fetchError || !insight) {
    throw new AppError('NOT_FOUND', `Insight ${input.insight_id} not found`);
  }
  if (insight.status !== STATUS_REVIEW) {
    throw new AppError(
      'CONFLICT',
      `Insight is in status '${insight.status}' — only 'review' insights can be approved`,
    );
  }

  // Atomic transition with optimistic lock on status
  const { data: updated, error: updateError } = await adminClient
    .from('catalyst_insights')
    .update({
      status:       STATUS_ACTIVE,
      published_at: now,
      reviewed_by:  adminId,
      reviewed_at:  now,
    })
    .eq('id', input.insight_id)
    .eq('status', STATUS_REVIEW)  // optimistic lock: fails if concurrently modified
    .select('id');

  if (updateError) {
    throw new AppError('SERVER_ERROR', `Failed to approve insight: ${updateError.message}`);
  }
  if (!updated || updated.length === 0) {
    throw new AppError(
      'CONFLICT',
      'Insight status was modified by a concurrent request — please retry',
    );
  }

  // Audit (non-fatal)
  await writeInsightAuditLog(adminClient, adminId, 'insight_approved', input.insight_id, {
    previous_status: STATUS_REVIEW,
    new_status:      STATUS_ACTIVE,
  });

  return {
    insight_id:      input.insight_id,
    previous_status: STATUS_REVIEW,
    new_status:      STATUS_ACTIVE,
    reviewed_by:     adminId,
    reviewed_at:     now,
  };
}

// Transitions a single insight from 'review' to 'archived' (rejected).
// Sets reviewed_by = adminId, reviewed_at = now().
// Optional rejection_reason is persisted in the audit log metadata for ops visibility.
export async function handleRejectInsight(
  body:    unknown,
  adminId: string,
): Promise<ReviewActionResult> {
  const input = validateRejectInput(body);
  const adminClient = createAdminClient();
  const now = new Date().toISOString();

  const { data: insight, error: fetchError } = await adminClient
    .from('catalyst_insights')
    .select('id, status')
    .eq('id', input.insight_id)
    .single();

  if (fetchError || !insight) {
    throw new AppError('NOT_FOUND', `Insight ${input.insight_id} not found`);
  }
  if (insight.status !== STATUS_REVIEW) {
    throw new AppError(
      'CONFLICT',
      `Insight is in status '${insight.status}' — only 'review' insights can be rejected`,
    );
  }

  // Atomic transition with optimistic lock on status
  const { data: updated, error: updateError } = await adminClient
    .from('catalyst_insights')
    .update({
      status:      STATUS_ARCHIVED,
      reviewed_by: adminId,
      reviewed_at: now,
    })
    .eq('id', input.insight_id)
    .eq('status', STATUS_REVIEW)  // optimistic lock
    .select('id');

  if (updateError) {
    throw new AppError('SERVER_ERROR', `Failed to reject insight: ${updateError.message}`);
  }
  if (!updated || updated.length === 0) {
    throw new AppError(
      'CONFLICT',
      'Insight status was modified by a concurrent request — please retry',
    );
  }

  // Audit (non-fatal) — rejection_reason preserved for post-mortem / calibration
  await writeInsightAuditLog(adminClient, adminId, 'insight_rejected', input.insight_id, {
    previous_status:  STATUS_REVIEW,
    new_status:       STATUS_ARCHIVED,
    rejection_reason: input.rejection_reason,
  });

  return {
    insight_id:      input.insight_id,
    previous_status: STATUS_REVIEW,
    new_status:      STATUS_ARCHIVED,
    reviewed_by:     adminId,
    reviewed_at:     now,
  };
}
