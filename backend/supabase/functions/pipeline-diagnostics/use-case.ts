// pipeline-diagnostics — Use case
// S3-BE-010: End-to-End Pipeline Validation & Diagnostics for Catalyst Insights.
//
// Verifies all prerequisites required for the 10-stage Catalyst Insights pipeline.
// Never modifies any records. Never invokes other Edge Functions.
//
// Check categories:
//
//   ENV      — SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY
//              Presence only; format validated for SUPABASE_URL (https:// prefix).
//              OPENAI_API_KEY is checked in the AI section, not here.
//
//   DATABASE — 4 tables probed with COUNT(*) head:true (no rows transferred):
//              insights_sources, insights_raw, catalyst_insights, admin_audit_log.
//              All 4 probes run concurrently via Promise.all.
//              Per-probe latency_ms included; average returned at section level.
//
//   STORAGE  — insights bucket probed via list('defaults', {limit: 1}).
//              Non-destructive read. Failure = bucket not seeded or policy issue.
//
//   AI       — OPENAI_API_KEY presence + sk- prefix format check.
//              No actual API call is made (avoids credit consumption and latency).
//              Provider: 'openai', model: 'gpt-4o-mini' (from ai-client.ts).
//
//   MODULES  — 10 pipeline modules, each marked ready / degraded / blocked based on
//              the gathered ENV, DATABASE, STORAGE, and AI check results.
//              Derived check — no module is invoked.
//
//   SCHEDULER — 3 cron functions (CF-01 / CF-02 / CF-03), prerequisites derived
//               from ENV and DATABASE results. Cron registration itself is not
//               verified (requires pg_cron schema access outside service_role scope).
//
// Security:
//   Env var VALUES are never included in the report — only presence (boolean) and
//   format validity. This prevents accidental exposure of secrets in ops tooling.
//
// Result<T,E> is used for all IO operations (probeTable, probeBucket) so failures
// can be aggregated cleanly without try/catch at every call site.
//
// Parallel execution:
//   DB (4 probes) and Storage (1 probe) run concurrently via Promise.all.
//   ENV and AI checks are synchronous and run before/after IO.
//   If critical env vars are absent, IO checks are skipped entirely —
//   createAdminClient() relies on ! non-null assertions for SUPABASE_URL and
//   SUPABASE_SERVICE_ROLE_KEY; calling it with undefined args is avoided.
//
// Readiness classification:
//   'blocked'  — SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing, OR any DB
//                table unreachable, OR any module is blocked
//   'degraded' — non-critical issues: SUPABASE_ANON_KEY missing (collect-insight
//                and review-insight use user client), storage unavailable (hero
//                images fall back to category defaults), OPENAI_API_KEY issues
//   'ready'    — all 10 checks pass
//
// Summary check counts:
//   3 env + 4 DB + 1 storage + 2 AI = 10 total raw checks
//   Module and scheduler statuses are derived, not counted independently.

import { createAdminClient } from '../_shared/supabase-client.ts';
import { PipelineError } from '../_shared/insights/errors.ts';
import { logger } from '../_shared/insights/logger.ts';
import { ok, err, type Result } from '../_shared/insights/result.ts';

const FN = 'pipeline_diagnostics';

// ─── Check status type ────────────────────────────────────────────────────────
//
// 'pass' — check succeeded with no issues
// 'warn' — check has a non-blocking concern (format suspect, partial availability)
// 'fail' — check failed; dependent modules are 'blocked' or 'degraded'

export type CheckStatus = 'pass' | 'warn' | 'fail';

export interface CheckResult {
  status:  CheckStatus;
  message: string;
  detail?: string;
}

// ─── Section result types ─────────────────────────────────────────────────────

export interface EnvDiagnostics {
  ok:     boolean;
  checks: {
    SUPABASE_URL:              CheckResult;
    SUPABASE_SERVICE_ROLE_KEY: CheckResult;
    SUPABASE_ANON_KEY:         CheckResult;
  };
}

export interface TableCheckResult extends CheckResult {
  latency_ms: number | null;
}

export interface DatabaseDiagnostics {
  ok:         boolean;
  latency_ms: number | null;  // average across probed tables
  tables: {
    insights_sources:  TableCheckResult;
    catalyst_insights: TableCheckResult;
    insights_raw:      TableCheckResult;
    admin_audit_log:   TableCheckResult;
  };
}

export interface StorageDiagnostics {
  ok: boolean;
  checks: {
    insights_bucket: CheckResult;
  };
}

export interface AiDiagnostics {
  ok:       boolean;
  provider: 'openai';
  model:    string;
  checks: {
    api_key_present: CheckResult;
    api_key_format:  CheckResult;
  };
}

export type ModuleStatus = 'ready' | 'degraded' | 'blocked';

export interface ModuleDiagnostics {
  module:      string;
  description: string;
  status:      ModuleStatus;
  issues:      string[];
}

export interface CronDiagnostics {
  name:     string;
  function: string;
  schedule: string;
  status:   ModuleStatus;
  issues:   string[];
}

export interface SchedulerDiagnostics {
  ok:    boolean;
  crons: CronDiagnostics[];
}

export interface DiagnosticsSummary {
  total_checks:    number;
  passed:          number;
  warned:          number;
  failed:          number;
  blocking_issues: string[];
}

export type PipelineReadiness = 'ready' | 'degraded' | 'blocked';

export interface DiagnosticsReport {
  checked_at: string;
  readiness:  PipelineReadiness;
  env:        EnvDiagnostics;
  database:   DatabaseDiagnostics;
  storage:    StorageDiagnostics;
  ai:         AiDiagnostics;
  modules:    ModuleDiagnostics[];
  scheduler:  SchedulerDiagnostics;
  summary:    DiagnosticsSummary;
}

// ─── IO helpers — return Result<T,E> so errors can be aggregated ──────────────

type AdminClient = ReturnType<typeof createAdminClient>;

// Non-destructive COUNT(*) probe. head:true means no rows are transferred.
// Measures wall-clock latency to include in the DB diagnostics section.
async function probeTable(
  client:    AdminClient,
  tableName: string,
): Promise<Result<{ latencyMs: number }, PipelineError>> {
  const start = Date.now();
  const { error } = await client
    .from(tableName)
    .select('*', { count: 'exact', head: true });

  if (error) {
    return err(new PipelineError('DB_ERROR', `'${tableName}' probe failed: ${error.message}`));
  }
  return ok({ latencyMs: Date.now() - start });
}

// Non-destructive bucket existence probe via listing up to 1 item in a path.
// Returns ok with fileCount even if the path is empty (bucket exists but unseeded).
async function probeBucket(
  client:     AdminClient,
  bucketName: string,
  path:       string,
): Promise<Result<{ fileCount: number }, PipelineError>> {
  const { data, error } = await client.storage
    .from(bucketName)
    .list(path, { limit: 1 });

  if (error) {
    return err(new PipelineError(
      'DB_ERROR',
      `Storage '${bucketName}/${path}' probe failed: ${error.message}`,
    ));
  }
  return ok({ fileCount: (data ?? []).length });
}

// ─── Section checks ────────────────────────────────────────────────────────────

// Check env var presence only. Never reveals the actual value.
function checkEnvPresent(name: string): CheckResult {
  return Deno.env.get(name)
    ? { status: 'pass', message: `${name} is set` }
    : { status: 'fail', message: `${name} is not set` };
}

function runEnvChecks(): EnvDiagnostics {
  const supabaseUrl      = Deno.env.get('SUPABASE_URL');
  const urlFormatOk      = !!supabaseUrl && supabaseUrl.startsWith('https://');

  const urlCheck: CheckResult = !supabaseUrl
    ? { status: 'fail', message: 'SUPABASE_URL is not set' }
    : urlFormatOk
      ? { status: 'pass', message: 'SUPABASE_URL is set with https:// prefix' }
      : { status: 'warn', message: 'SUPABASE_URL is set but does not start with https://' };

  const checks = {
    SUPABASE_URL:              urlCheck,
    SUPABASE_SERVICE_ROLE_KEY: checkEnvPresent('SUPABASE_SERVICE_ROLE_KEY'),
    SUPABASE_ANON_KEY:         checkEnvPresent('SUPABASE_ANON_KEY'),
  };

  return {
    ok: Object.values(checks).every((c) => c.status !== 'fail'),
    checks,
  };
}

const DB_TABLES = [
  'insights_sources',
  'insights_raw',
  'catalyst_insights',
  'admin_audit_log',
] as const;

type DbTable = typeof DB_TABLES[number];

async function runDatabaseChecks(client: AdminClient): Promise<DatabaseDiagnostics> {
  // All 4 table probes run concurrently — total wall clock ≈ slowest single probe.
  const results = await Promise.all(DB_TABLES.map((t) => probeTable(client, t)));

  const tables = {} as Record<DbTable, TableCheckResult>;
  let sumMs = 0;
  let successCount = 0;
  let allOk = true;

  for (let i = 0; i < DB_TABLES.length; i++) {
    const name   = DB_TABLES[i];
    const result = results[i];

    if (result.ok) {
      sumMs += result.value.latencyMs;
      successCount++;
      tables[name] = {
        status:     'pass',
        message:    `Table '${name}' is accessible`,
        latency_ms: result.value.latencyMs,
      };
    } else {
      allOk = false;
      tables[name] = {
        status:     'fail',
        message:    `Table '${name}' is not accessible`,
        detail:     result.error.message,
        latency_ms: null,
      };
    }
  }

  return {
    ok:         allOk,
    latency_ms: successCount > 0 ? Math.round(sumMs / successCount) : null,
    tables: tables as DatabaseDiagnostics['tables'],
  };
}

async function runStorageChecks(client: AdminClient): Promise<StorageDiagnostics> {
  // Probe insights/defaults/ — non-destructive list, limit 1.
  // Verifies the insights bucket exists and the defaults prefix is seeded.
  const result = await probeBucket(client, 'insights', 'defaults');

  const insightsBucketCheck: CheckResult = result.ok
    ? {
        status:  result.value.fileCount > 0 ? 'pass' : 'warn',
        message: result.value.fileCount > 0
          ? `insights/defaults/ is accessible (${result.value.fileCount} default image(s) found)`
          : 'insights/defaults/ is accessible but appears unseeded (0 files) — hero image fallbacks may be broken',
      }
    : {
        status:  'fail',
        message: 'insights bucket is not accessible — hero image mirroring will use broken fallbacks',
        detail:  result.error.message,
      };

  return {
    ok:     insightsBucketCheck.status !== 'fail',
    checks: { insights_bucket: insightsBucketCheck },
  };
}

// OPENAI_API_KEY is checked here, not in runEnvChecks(), to keep the env section
// focused on infrastructure connectivity variables and the AI section on provider config.
function buildAiDiagnostics(): AiDiagnostics {
  const keyValue = Deno.env.get('OPENAI_API_KEY');

  const presentCheck: CheckResult = keyValue
    ? { status: 'pass', message: 'OPENAI_API_KEY is set' }
    : { status: 'fail', message: 'OPENAI_API_KEY is not set — enrich-insight will fail' };

  const formatCheck: CheckResult = !keyValue
    ? { status: 'fail', message: 'OPENAI_API_KEY is not set' }
    : keyValue.startsWith('sk-')
      ? { status: 'pass', message: 'OPENAI_API_KEY has expected sk- prefix' }
      : { status: 'warn', message: 'OPENAI_API_KEY does not start with sk- — verify the key type (project keys use sk-proj-)' };

  const allOk =
    presentCheck.status !== 'fail' &&
    formatCheck.status  !== 'fail';

  return {
    ok:       allOk,
    provider: 'openai',
    model:    'gpt-4o-mini',
    checks: {
      api_key_present: presentCheck,
      api_key_format:  formatCheck,
    },
  };
}

// ─── Skipped section builders (when critical env vars are absent) ─────────────

function buildSkippedDatabaseDiagnostics(): DatabaseDiagnostics {
  const skipped: TableCheckResult = {
    status:     'fail',
    message:    'Skipped — SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set',
    latency_ms: null,
  };
  return {
    ok:         false,
    latency_ms: null,
    tables: {
      insights_sources:  { ...skipped },
      insights_raw:      { ...skipped },
      catalyst_insights: { ...skipped },
      admin_audit_log:   { ...skipped },
    },
  };
}

function buildSkippedStorageDiagnostics(): StorageDiagnostics {
  return {
    ok: false,
    checks: {
      insights_bucket: {
        status:  'fail',
        message: 'Skipped — SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set',
      },
    },
  };
}

// ─── Module spec table ────────────────────────────────────────────────────────
// Captures the prerequisites for each pipeline module so readiness can be
// derived without invoking the module itself.

type EnvKey = keyof EnvDiagnostics['checks'];

interface ModuleSpec {
  module:          string;
  description:     string;
  requiresEnv:     EnvKey[];
  requiresTables:  (keyof DatabaseDiagnostics['tables'])[];
  requiresStorage: boolean;
  requiresAi:      boolean;
}

const MODULE_SPECS: readonly ModuleSpec[] = [
  {
    module:          'collect-insight',
    description:     'URL ingestion and deduplication (pipeline entry point)',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_ANON_KEY'],
    requiresTables:  ['insights_sources', 'insights_raw'],
    requiresStorage: false,
    requiresAi:      false,
  },
  {
    module:          'validate-insight',
    description:     'Content validation and OG metadata extraction',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables:  ['insights_raw'],
    requiresStorage: false,
    requiresAi:      false,
  },
  {
    module:          'enrich-insight',
    description:     'AI enrichment, categorization, and hero image mirroring',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables:  ['insights_raw', 'catalyst_insights'],
    requiresStorage: true,   // insights bucket for hero images (fallback on failure)
    requiresAi:      true,   // OPENAI_API_KEY required
  },
  {
    module:          'recover-stalled-insights',
    description:     'Stalled validation recovery cron CF-01 (every 30 min)',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables:  ['insights_raw'],
    requiresStorage: false,
    requiresAi:      false,
  },
  {
    module:          'review-insight',
    description:     'Admin moderation API — approve / reject / list',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_ANON_KEY'],
    requiresTables:  ['catalyst_insights', 'admin_audit_log'],
    requiresStorage: false,
    requiresAi:      false,
  },
  {
    module:          'activate-scheduled-insights',
    description:     'Scheduled publication cron CF-02 (every minute)',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables:  ['catalyst_insights'],
    requiresStorage: false,
    requiresAi:      false,
  },
  {
    module:          'expire-old-insights',
    description:     'Insight expiration cron CF-03 (daily at 02:00 UTC)',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables:  ['catalyst_insights'],
    requiresStorage: false,
    requiresAi:      false,
  },
  {
    module:          'pipeline-health',
    description:     'Pipeline monitoring — queue depth and latency metrics',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables:  ['insights_raw', 'catalyst_insights'],
    requiresStorage: false,
    requiresAi:      false,
  },
  {
    module:          'pipeline-operations',
    description:     'Manual ops control — list / retry / recover jobs',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables:  ['insights_raw'],
    requiresStorage: false,
    requiresAi:      false,
  },
  {
    module:          'pipeline-diagnostics',
    description:     'End-to-end pipeline validation and readiness check (this module)',
    requiresEnv:     ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables:  ['insights_sources', 'insights_raw', 'catalyst_insights', 'admin_audit_log'],
    requiresStorage: true,   // probes the insights bucket
    requiresAi:      false,
  },
];

function deriveModuleDiagnostics(
  envResult:     EnvDiagnostics,
  dbResult:      DatabaseDiagnostics,
  storageResult: StorageDiagnostics,
  aiResult:      AiDiagnostics,
): ModuleDiagnostics[] {
  return MODULE_SPECS.map((spec): ModuleDiagnostics => {
    const issues: string[] = [];
    let hasBlocker     = false;
    let hasDegradation = false;

    // ENV: missing env var → blocked; format warn → degraded
    for (const envKey of spec.requiresEnv) {
      const check = envResult.checks[envKey];
      if (check.status === 'fail') {
        issues.push(`Missing env var: ${envKey}`);
        hasBlocker = true;
      } else if (check.status === 'warn') {
        issues.push(`Env var format warning: ${envKey} — ${check.message}`);
        hasDegradation = true;
      }
    }

    // DATABASE: unreachable table → blocked
    for (const tableName of spec.requiresTables) {
      const tableCheck = dbResult.tables[tableName];
      if (!tableCheck || tableCheck.status === 'fail') {
        issues.push(`DB table unreachable: ${tableName}`);
        hasBlocker = true;
      }
    }

    // STORAGE: unavailable → degraded for enrich-insight (uses category fallback),
    //          degraded for pipeline-diagnostics (partial probe result)
    if (spec.requiresStorage && !storageResult.ok) {
      issues.push('Storage bucket unavailable — hero images will use category defaults');
      hasDegradation = true;
    }

    // AI: key missing or invalid format → blocked for enrich-insight
    if (spec.requiresAi) {
      if (aiResult.checks.api_key_present.status === 'fail') {
        issues.push('OPENAI_API_KEY is not set — AI enrichment will fail');
        hasBlocker = true;
      } else if (aiResult.checks.api_key_format.status === 'warn') {
        issues.push('OPENAI_API_KEY format unexpected — AI calls may be rejected at runtime');
        hasDegradation = true;
      }
    }

    const status: ModuleStatus = hasBlocker
      ? 'blocked'
      : hasDegradation
        ? 'degraded'
        : 'ready';

    return { module: spec.module, description: spec.description, status, issues };
  });
}

// ─── Scheduler diagnostics ────────────────────────────────────────────────────

interface CronSpec {
  name:           string;
  function:       string;
  schedule:       string;
  requiresEnv:    EnvKey[];
  requiresTables: (keyof DatabaseDiagnostics['tables'])[];
}

const CRON_SPECS: readonly CronSpec[] = [
  {
    name:           'CF-01 Stalled Recovery',
    function:       'recover-stalled-insights',
    schedule:       '*/30 * * * *',
    requiresEnv:    ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables: ['insights_raw'],
  },
  {
    name:           'CF-02 Scheduled Publication',
    function:       'activate-scheduled-insights',
    schedule:       '* * * * *',
    requiresEnv:    ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables: ['catalyst_insights'],
  },
  {
    name:           'CF-03 Insight Expiration',
    function:       'expire-old-insights',
    schedule:       '0 2 * * *',
    requiresEnv:    ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'],
    requiresTables: ['catalyst_insights'],
  },
];

function deriveSchedulerDiagnostics(
  envResult: EnvDiagnostics,
  dbResult:  DatabaseDiagnostics,
): SchedulerDiagnostics {
  const crons: CronDiagnostics[] = CRON_SPECS.map((spec): CronDiagnostics => {
    const issues: string[] = [];
    let hasBlocker = false;

    for (const envKey of spec.requiresEnv) {
      if (envResult.checks[envKey]?.status === 'fail') {
        issues.push(`Missing env var: ${envKey}`);
        hasBlocker = true;
      }
    }

    for (const tableName of spec.requiresTables) {
      const tableCheck = dbResult.tables[tableName];
      if (!tableCheck || tableCheck.status === 'fail') {
        issues.push(`DB table unreachable: ${tableName}`);
        hasBlocker = true;
      }
    }

    return {
      name:     spec.name,
      function: spec.function,
      schedule: spec.schedule,
      status:   hasBlocker ? 'blocked' : 'ready',
      issues,
    };
  });

  return { ok: crons.every((c) => c.status === 'ready'), crons };
}

// ─── Readiness classification ──────────────────────────────────────────────────

function classifyReadiness(
  envResult: EnvDiagnostics,
  dbResult:  DatabaseDiagnostics,
  modules:   ModuleDiagnostics[],
): PipelineReadiness {
  // Critical env vars missing → nothing can connect
  const criticalEnvBlocked =
    envResult.checks['SUPABASE_URL'].status              === 'fail' ||
    envResult.checks['SUPABASE_SERVICE_ROLE_KEY'].status === 'fail';

  if (criticalEnvBlocked) return 'blocked';

  // DB unreachable → pipeline cannot read or write any state
  if (!dbResult.ok) return 'blocked';

  // Any module blocked → pipeline is incomplete
  if (modules.some((m) => m.status === 'blocked')) return 'blocked';

  // Non-critical issues: partial connectivity, format warnings
  if (modules.some((m) => m.status === 'degraded')) return 'degraded';

  return 'ready';
}

// ─── Summary ──────────────────────────────────────────────────────────────────
//
// Total raw check count: 3 (env) + 4 (DB tables) + 1 (storage) + 2 (AI) = 10.
// Module and scheduler statuses are derived, not raw check counts.

function buildSummary(
  envResult:     EnvDiagnostics,
  dbResult:      DatabaseDiagnostics,
  storageResult: StorageDiagnostics,
  aiResult:      AiDiagnostics,
): DiagnosticsSummary {
  const rawChecks: CheckResult[] = [
    ...Object.values(envResult.checks),
    ...Object.values(dbResult.tables),
    ...Object.values(storageResult.checks),
    ...Object.values(aiResult.checks),
  ];

  const passed = rawChecks.filter((c) => c.status === 'pass').length;
  const warned = rawChecks.filter((c) => c.status === 'warn').length;
  const failed = rawChecks.filter((c) => c.status === 'fail').length;

  const blockingIssues: string[] = [];

  // Critical env vars
  const criticalEnvKeys = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'] as const;
  for (const key of criticalEnvKeys) {
    if (envResult.checks[key].status === 'fail') {
      blockingIssues.push(`Critical env var missing: ${key}`);
    }
  }

  // DB failures
  for (const [name, check] of Object.entries(dbResult.tables) as Array<[string, TableCheckResult]>) {
    if (check.status === 'fail') {
      blockingIssues.push(`DB table unreachable: ${name}`);
    }
  }

  // AI provider missing
  if (aiResult.checks.api_key_present.status === 'fail') {
    blockingIssues.push('AI provider not configured: OPENAI_API_KEY is not set');
  }

  return {
    total_checks:    rawChecks.length,
    passed,
    warned,
    failed,
    blocking_issues: blockingIssues,
  };
}

// ─── Entry point ──────────────────────────────────────────────────────────────

export async function handlePipelineDiagnostics(): Promise<DiagnosticsReport> {
  const checkedAt = new Date().toISOString();

  logger.info('Pipeline diagnostics initiated', { fn: FN, checked_at: checkedAt });

  // Step 1: Synchronous env and AI checks — no external calls.
  const envResult = runEnvChecks();
  const aiResult  = buildAiDiagnostics();

  // Step 2: IO checks — only if critical env vars are present.
  // createAdminClient() uses ! assertions on SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY;
  // calling it when either is absent would produce a broken client that fails with
  // unhelpful TypeError. Skipping IO when critical vars are absent gives a clear report.
  const canConnect =
    envResult.checks['SUPABASE_URL'].status              !== 'fail' &&
    envResult.checks['SUPABASE_SERVICE_ROLE_KEY'].status !== 'fail';

  let dbResult:      DatabaseDiagnostics;
  let storageResult: StorageDiagnostics;

  if (canConnect) {
    const adminClient = createAdminClient();
    // DB and Storage probes run concurrently — total wall clock ≈ slowest single call.
    [dbResult, storageResult] = await Promise.all([
      runDatabaseChecks(adminClient),
      runStorageChecks(adminClient),
    ]);
  } else {
    dbResult      = buildSkippedDatabaseDiagnostics();
    storageResult = buildSkippedStorageDiagnostics();
    logger.warn('Pipeline diagnostics — IO checks skipped (critical env vars absent)', { fn: FN });
  }

  // Step 3: Derive module and scheduler status from gathered check results.
  const modules   = deriveModuleDiagnostics(envResult, dbResult, storageResult, aiResult);
  const scheduler = deriveSchedulerDiagnostics(envResult, dbResult);

  // Step 4: Classify readiness and build summary.
  const readiness = classifyReadiness(envResult, dbResult, modules);
  const summary   = buildSummary(envResult, dbResult, storageResult, aiResult);

  logger.info('Pipeline diagnostics check results', {
    fn:              FN,
    readiness,
    env_ok:          envResult.ok,
    db_ok:           dbResult.ok,
    storage_ok:      storageResult.ok,
    ai_ok:           aiResult.ok,
    modules_ready:   modules.filter((m) => m.status === 'ready').length,
    modules_blocked: modules.filter((m) => m.status === 'blocked').length,
    scheduler_ok:    scheduler.ok,
  });

  return {
    checked_at: checkedAt,
    readiness,
    env:        envResult,
    database:   dbResult,
    storage:    storageResult,
    ai:         aiResult,
    modules,
    scheduler,
    summary,
  };
}
