// review-insight — Entry point
// Admin Review Workflow for Catalyst Insights (S3-BE-005)
// Provides list, approve, and reject operations on insights in 'review' status.
//
// Auth: Bearer JWT — authenticated admin required.
// Not a service-role endpoint: admin acts as a named user; reviewed_by = their user ID.
//
// POST /functions/v1/review-insight
// Authorization: Bearer <admin-jwt>
//
// Actions:
//   { action: 'list' }
//     → 200: { insights: ReviewInsight[], count: number }
//
//   { action: 'approve', insight_id: string }
//     → 200: { insight_id, previous_status, new_status, reviewed_by, reviewed_at }
//
//   { action: 'reject', insight_id: string, rejection_reason?: string }
//     → 200: { insight_id, previous_status, new_status, reviewed_by, reviewed_at }
//
// Error codes:
//   401 — missing or invalid token
//   403 — caller is not an active admin
//   404 — insight not found
//   409 — insight is not in 'review' status
//   422 — missing required fields or invalid UUID
//   500 — database error

import { corsResponse } from '../_shared/cors.ts';
import { toErrorResponse, AppError } from '../_shared/errors.ts';
import { jsonResponse } from '../_shared/response.ts';
import { requireAuth, requireAdmin } from '../_shared/auth.ts';
import {
  handleListReview,
  handleApproveInsight,
  handleRejectInsight,
} from './use-case.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return corsResponse();

  try {
    const { userId, client } = await requireAuth(req);
    await requireAdmin(userId, client);

    const body = await req.json() as { action?: string };

    switch (body?.action) {
      case 'list':
        return jsonResponse(await handleListReview());
      case 'approve':
        return jsonResponse(await handleApproveInsight(body, userId));
      case 'reject':
        return jsonResponse(await handleRejectInsight(body, userId));
      default:
        throw new AppError(
          'VALIDATION_ERROR',
          'action must be "list", "approve", or "reject"',
        );
    }
  } catch (error) {
    return toErrorResponse(error);
  }
});
