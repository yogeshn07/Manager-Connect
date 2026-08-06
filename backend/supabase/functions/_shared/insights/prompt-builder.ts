// Catalyst Insights Pipeline — AI Prompt Builder (S3-BE-004)
// Assembles system and user prompts for the OpenAI enrichment call.
//
// Responsibilities:
//   • System prompt builder  — role, task instruction, category taxonomy, audience
//   • User prompt builder    — JSON schema spec + article context assembly
//   • Prompt template constants — named sections for readability and maintenance
//   • Prompt version identifier — PROMPT_VERSION for log/analytics correlation
//   • Prompt context assembly — typed PromptContext decoupled from RawWithSource
//   • IEEE abstract integration — appended when present in PromptContext
//   • Prompt validation — minimum length guards on both prompts
//   • Structured logging — debug-level log on every prompt assembly
//
// Callers: enrich_insight use-case.ts (step 7–8)
// Does NOT contain AI client logic, retry logic, or enrichment business rules.
// Prompt engineering decisions (categories, field specs, thresholds) live here.

import type { InsightCategory, OgMetadata } from './types.ts';
import { INSIGHT_CATEGORIES } from './constants.ts';
import { PipelineError } from './errors.ts';
import { logger } from './logger.ts';

// ─── Prompt version ───────────────────────────────────────────────────────────
// Increment when any template constant changes.
// Logged on every assembly so AI output can be correlated to the prompt version
// that produced it — essential for debugging confidence regressions.
export const PROMPT_VERSION = 'v1.0' as const;

// ─── Public interfaces ────────────────────────────────────────────────────────

// Decoupled from private RawWithSource — caller maps fields at the call site.
// Contains everything the prompt builder needs; nothing it does not.
export interface PromptContext {
  raw_url:       string;
  source_name:   string;
  source_tier:   number;
  og:            OgMetadata;
  ieee_abstract: string | null;
}

export interface PromptPair {
  system:  string;
  user:    string;
  version: typeof PROMPT_VERSION;
}

// ─── System prompt template constants ─────────────────────────────────────────
// Each named constant corresponds to a distinct instructional role in the prompt.
// Keeping them separate makes individual sections editable without touching others.

const SYSTEM_PREAMBLE =
  'You are the enrichment engine for Catalyst Insights, a curated content platform ' +
  'for power engineers and energy sector professionals.';

const SYSTEM_TASK_INSTRUCTION =
  'Your task is to analyze article metadata and produce structured enrichment data as a ' +
  'JSON object. You must return ONLY valid JSON — no markdown fences, no prose, no explanation.';

const SYSTEM_AUDIENCE =
  'The audience is senior electrical engineers, grid operations specialists, energy policy ' +
  'professionals, and engineering managers in the power sector.';

// Per-category descriptions drive classification accuracy.
// Keyed by InsightCategory so TypeScript enforces completeness when new categories are added.
const CATEGORY_DESCRIPTIONS: Record<InsightCategory, string> = {
  grid_technology:         'Power grids, transmission, distribution, substations, HVDC, smart grid, grid modernization',
  energy_transition:       'Renewable integration, decarbonization, clean energy, battery storage, hydrogen',
  industry_standards:      'IEEE standards, IEC standards, regulatory compliance, technical specifications, codes',
  engineering_leadership:  'Project management, technical leadership, workforce development, engineering culture',
  policy_markets:          'Energy regulation, electricity markets, policy, tariffs, capacity markets, carbon pricing',
  innovation:              'Emerging technologies, R&D, startups, novel applications, proof-of-concept deployments',
};

// ─── User prompt template constants ──────────────────────────────────────────
// Built at module-init time so it is computed once per cold start, not per call.

// Ordered list of output fields the model must produce.
// category line is computed from INSIGHT_CATEGORIES to stay in sync with the type system.
const USER_FIELD_SPEC = [
  'Analyze the article below and return a JSON object with EXACTLY these 8 fields:',
  '',
  '  ai_headline          (string)  — Compelling, specific headline for power engineers. Max 120 chars.',
  '  ai_summary           (string)  — 3-5 sentences covering what happened, key figures, and technical details.',
  '  ai_why_matters       (string)  — 2-3 sentences on significance to power engineering professionals.',
  '  ai_key_takeaway      (string)  — Single most important insight in one sentence.',
  '  ai_tags              (string[]) — 3-7 specific, lowercase, hyphenated technical tags.',
  '  ai_confidence        (number)  — 0.0–1.0. Use ≥0.95 for core grid/energy content, 0.70–0.94 for adjacent, <0.70 for borderline.',
  `  category             (string)  — Exactly one of: ${(INSIGHT_CATEGORIES as readonly InsightCategory[]).map((c) => `"${c}"`).join(' | ')}`,
  '  reading_time_minutes (integer) — Estimated reading time, 1–20.',
].join('\n');

// ─── Validation thresholds ────────────────────────────────────────────────────

const MIN_SYSTEM_CHARS = 200;  // guards against accidental empty/truncated template
const MIN_USER_CHARS   = 100;  // guards against missing context (url + source are required)

const FN = 'prompt_builder';

// ─── Private builders ─────────────────────────────────────────────────────────

function buildSystemPrompt(): string {
  const categoryLines = (INSIGHT_CATEGORIES as readonly InsightCategory[]).map(
    (cat) => `- ${cat}: ${CATEGORY_DESCRIPTIONS[cat]}`,
  );

  return [
    SYSTEM_PREAMBLE,
    '',
    SYSTEM_TASK_INSTRUCTION,
    '',
    'The six content categories are:',
    ...categoryLines,
    '',
    SYSTEM_AUDIENCE,
  ].join('\n');
}

function buildUserPrompt(ctx: PromptContext): string {
  const lines: string[] = [
    USER_FIELD_SPEC,
    '',
    '--- Article Context ---',
    `URL:    ${ctx.raw_url}`,
    `Source: ${ctx.source_name} (Tier ${ctx.source_tier})`,
  ];

  if (ctx.og.title)        lines.push(`Title:  ${ctx.og.title}`);
  if (ctx.og.description)  lines.push(`Description: ${ctx.og.description}`);
  if (ctx.og.article_date) lines.push(`Published: ${ctx.og.article_date}`);

  if (ctx.ieee_abstract) {
    lines.push('');
    lines.push('--- IEEE Xplore Abstract (authoritative technical source) ---');
    lines.push(ctx.ieee_abstract);
  }

  lines.push('');
  lines.push('Return ONLY the JSON object. No markdown fences, no explanation.');

  return lines.join('\n');
}

// Validates that both assembled prompts meet minimum length requirements.
// Throws PipelineError(VALIDATION_FAILED, retryable=false) — a too-short prompt
// indicates a template bug, not a transient failure.
function validatePromptPair(system: string, user: string): void {
  if (!system.trim() || system.length < MIN_SYSTEM_CHARS) {
    throw new PipelineError(
      'VALIDATION_FAILED',
      `System prompt too short: ${system.length} chars (min ${MIN_SYSTEM_CHARS}) — template bug`,
    );
  }
  if (!user.trim() || user.length < MIN_USER_CHARS) {
    throw new PipelineError(
      'VALIDATION_FAILED',
      `User prompt too short: ${user.length} chars (min ${MIN_USER_CHARS}) — missing context`,
    );
  }
}

// ─── Exported entry point ─────────────────────────────────────────────────────

// Builds and validates the system + user prompt pair for a single enrichment call.
// Pure function: no DB access, no network calls.
// Throws PipelineError(VALIDATION_FAILED) only if the assembled prompts are
// shorter than the expected minimums — indicates a template or data bug.
export function buildPrompts(ctx: PromptContext): PromptPair {
  const system = buildSystemPrompt();
  const user   = buildUserPrompt(ctx);

  validatePromptPair(system, user);

  logger.debug('Prompts assembled', {
    fn:                  FN,
    prompt_version:      PROMPT_VERSION,
    system_chars:        system.length,
    user_chars:          user.length,
    has_og_title:        ctx.og.title !== null,
    has_og_description:  ctx.og.description !== null,
    has_og_date:         ctx.og.article_date !== null,
    has_ieee_abstract:   ctx.ieee_abstract !== null,
  });

  return { system, user, version: PROMPT_VERSION };
}
