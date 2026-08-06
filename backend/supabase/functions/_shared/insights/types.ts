// Catalyst Insights Pipeline — shared TypeScript types
// Mirrors the Sprint 1 schema (S1-DB-001 through S1-DB-004) exactly.
// Imported by: collect_insight, validate_insight, enrich_insight, recover_stalled_insights,
//              activate_scheduled_insights, expire_old_insights, batch_approve_rpc callers.

// ─── Domain scalars ──────────────────────────────────────────────────────────

export type SourceTier = 1 | 2 | 3;

export type RawStatus =
  | 'pending'
  | 'validated'
  | 'duplicate'
  | 'rejected'
  | 'ai_processed'
  | 'review'
  | 'scheduled'
  | 'active'
  | 'archived'
  | 'ai_error';

export type InsightStatus = 'review' | 'scheduled' | 'active' | 'archived';

export type InsightCategory =
  | 'grid_technology'
  | 'energy_transition'
  | 'industry_standards'
  | 'engineering_leadership'
  | 'policy_markets'
  | 'innovation';

// ─── Database row types (one-to-one with table columns) ──────────────────────

export interface InsightsSource {
  id: string;
  name: string;
  approved_domain: string;
  tier: SourceTier;
  is_active: boolean;
  created_at: string;
}

export interface InsightsRaw {
  id: string;
  source_id: string;
  raw_url: string;
  url_fingerprint: string;
  title_fingerprint: string | null;
  status: RawStatus;
  og_title: string | null;
  og_description: string | null;
  og_image_url: string | null;
  submitted_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CatalystInsight {
  id: string;
  raw_id: string;
  source_id: string;
  url_fingerprint: string;
  ai_headline: string | null;
  ai_summary: string | null;
  ai_why_matters: string | null;
  ai_key_takeaway: string | null;
  ai_tags: string[];
  ai_confidence: number | null;
  source_name: string | null;
  source_url: string | null;
  article_date: string | null;
  reading_time_minutes: number | null;
  hero_image_url: string | null;
  category: InsightCategory;
  is_ai_generated: boolean;
  status: InsightStatus;
  scheduled_for: string | null;
  published_at: string | null;
  is_evergreen: boolean;
  reviewed_by: string | null;
  reviewed_at: string | null;
  created_at: string;
  updated_at: string;
}

// ─── Edge Function payload types ─────────────────────────────────────────────

export interface CollectInsightPayload {
  url: string;
  source_id: string;
  submitted_by?: string;
}

export interface CollectInsightResult {
  raw_id: string;
  status: RawStatus;
  message: string;
}

export interface ValidateInsightPayload {
  raw_id: string;
}

export interface ValidateInsightResult {
  raw_id: string;
  status: RawStatus;
  message: string;
}

export interface EnrichInsightPayload {
  raw_id: string;
}

export interface EnrichInsightResult {
  insight_id: string;
  status: InsightStatus;
  ai_confidence: number;
}

// ─── Pipeline sub-types ───────────────────────────────────────────────────────

export interface OgMetadata {
  title: string | null;
  description: string | null;
  image_url: string | null;
  article_date: string | null;
}

export interface AiEnrichmentResult {
  ai_headline: string;
  ai_summary: string;
  ai_why_matters: string;
  ai_key_takeaway: string;
  ai_tags: string[];
  ai_confidence: number;
  category: InsightCategory;
  reading_time_minutes: number;
}

export interface BatchApproveRpcResult {
  approved_count: number;
  insight_ids: string[];
}
