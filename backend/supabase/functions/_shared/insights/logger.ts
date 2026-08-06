// Catalyst Insights Pipeline — structured JSON logger
// Outputs one JSON object per line to stdout/stderr.
// Each Edge Function passes { fn: 'collect_insight' } as baseline context
// so log lines can be correlated across the pipeline stages in Supabase logs.

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export interface LogContext {
  fn?: string;       // Edge Function name
  raw_id?: string;
  insight_id?: string;
  source_id?: string;
  url?: string;
  status?: string;
  duration_ms?: number;
  [key: string]: unknown;
}

function emit(level: LogLevel, msg: string, ctx: LogContext): void {
  const line = JSON.stringify({ level, ts: new Date().toISOString(), msg, ...ctx });
  if (level === 'error' || level === 'warn') {
    console.error(line);
  } else {
    console.log(line);
  }
}

export const logger = {
  debug: (msg: string, ctx: LogContext = {}) => emit('debug', msg, ctx),
  info:  (msg: string, ctx: LogContext = {}) => emit('info',  msg, ctx),
  warn:  (msg: string, ctx: LogContext = {}) => emit('warn',  msg, ctx),
  error: (msg: string, ctx: LogContext = {}) => emit('error', msg, ctx),
};

// Convenience: time an async operation and log its duration.
export async function timed<T>(
  label: string,
  ctx: LogContext,
  fn: () => Promise<T>,
): Promise<T> {
  const start = Date.now();
  try {
    const result = await fn();
    logger.info(label, { ...ctx, duration_ms: Date.now() - start });
    return result;
  } catch (e) {
    logger.error(label, { ...ctx, duration_ms: Date.now() - start, error: String(e) });
    throw e;
  }
}
