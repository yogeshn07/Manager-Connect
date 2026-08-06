// Catalyst Insights Pipeline — shared constants
// These are pipeline-specific and intentionally separate from the app-level
// _shared/constants.ts (which holds PAGINATION_DEFAULT_LIMIT, invite tokens, etc.).

import type { RawStatus, InsightStatus, InsightCategory } from './types.ts';

// ─── Pipeline status sets (type-safe) ────────────────────────────────────────

export const RAW_STATUSES = {
  PENDING:      'pending',
  VALIDATED:    'validated',
  DUPLICATE:    'duplicate',
  REJECTED:     'rejected',
  AI_PROCESSED: 'ai_processed',
  REVIEW:       'review',
  SCHEDULED:    'scheduled',
  ACTIVE:       'active',
  ARCHIVED:     'archived',
  AI_ERROR:     'ai_error',
} as const satisfies Record<string, RawStatus>;

export const INSIGHT_STATUSES = {
  REVIEW:    'review',
  SCHEDULED: 'scheduled',
  ACTIVE:    'active',
  ARCHIVED:  'archived',
} as const satisfies Record<string, InsightStatus>;

export const INSIGHT_CATEGORIES: readonly InsightCategory[] = [
  'grid_technology',
  'energy_transition',
  'industry_standards',
  'engineering_leadership',
  'policy_markets',
  'innovation',
] as const;

// ─── Pipeline thresholds ──────────────────────────────────────────────────────

// batch_approve_high_confidence default — also enforced in M07 RPC.
export const AI_CONFIDENCE_THRESHOLD = 0.90;

// CF-01: recover_stalled_insights queries
//   WHERE status = 'validated' AND updated_at < now() - interval '15 minutes'
// Must match the cron interval to avoid false positives.
export const STALE_VALIDATED_MINUTES = 15;

// ─── HTTP / fetch settings ────────────────────────────────────────────────────

export const HTTP_TIMEOUT_MS      = 10_000;
export const OG_FETCH_TIMEOUT_MS  = 8_000;
export const AI_TIMEOUT_MS        = 30_000;

// ─── Feed / pagination ────────────────────────────────────────────────────────

export const INSIGHTS_FEED_PAGE_SIZE = 20;

// ─── Source tier values ───────────────────────────────────────────────────────

export const SOURCE_TIERS = { TIER_1: 1, TIER_2: 2, TIER_3: 3 } as const;
