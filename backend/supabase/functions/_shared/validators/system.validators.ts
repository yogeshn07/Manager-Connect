import { AppError } from '../errors.ts';

export interface ComputeMonthlyStatsInput {
  stat_month: string;
}

export function validateComputeMonthlyStats(
  body: unknown,
): ComputeMonthlyStatsInput {
  const b = body as Record<string, unknown>;
  let statMonth: string;

  if (!b || !b.stat_month || typeof b.stat_month !== 'string') {
    const now = new Date();
    const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    statMonth = prev.toISOString().split('T')[0];
  } else {
    const parsed = new Date(b.stat_month);
    if (isNaN(parsed.getTime())) {
      throw new AppError(
        'VALIDATION_ERROR',
        'stat_month must be a valid date string (YYYY-MM-DD)',
      );
    }
    const firstOfMonth = new Date(
      parsed.getFullYear(),
      parsed.getMonth(),
      1,
    );
    if (firstOfMonth > new Date()) {
      throw new AppError(
        'VALIDATION_ERROR',
        'stat_month cannot be in the future',
      );
    }
    statMonth = firstOfMonth.toISOString().split('T')[0];
  }

  return { stat_month: statMonth };
}

const VALID_TRIGGER_TYPES = [
  'welcome',
  'monthly_highlights',
  'event_reminder',
  'poll_reminder',
  'achievement',
  'community_update',
  'memory',
] as const;

export type TriggerType = (typeof VALID_TRIGGER_TYPES)[number];

export interface ScheduledConnectBuddyInput {
  trigger_type: TriggerType;
  context: {
    user_id?: string | null;
    activity_id?: string | null;
    poll_id?: string | null;
    challenge_id?: string | null;
    past_activity_id?: string | null;
  };
}

const REQUIRED_CONTEXT_FIELDS: Record<string, string> = {
  welcome: 'user_id',
  event_reminder: 'activity_id',
  poll_reminder: 'poll_id',
  achievement: 'challenge_id',
  memory: 'past_activity_id',
};

export function validateScheduledConnectBuddy(
  body: unknown,
): ScheduledConnectBuddyInput {
  const b = body as Record<string, unknown>;
  if (
    !b ||
    typeof b.trigger_type !== 'string' ||
    !VALID_TRIGGER_TYPES.includes(b.trigger_type as TriggerType)
  ) {
    throw new AppError(
      'VALIDATION_ERROR',
      `trigger_type must be one of: ${VALID_TRIGGER_TYPES.join(', ')}`,
    );
  }

  const triggerType = b.trigger_type as TriggerType;
  const ctx = (b.context as Record<string, unknown>) ?? {};
  const requiredField = REQUIRED_CONTEXT_FIELDS[triggerType];

  if (requiredField) {
    const value = ctx[requiredField];
    if (!value || typeof value !== 'string' || !value.trim()) {
      throw new AppError(
        'VALIDATION_ERROR',
        `context.${requiredField} is required for trigger_type "${triggerType}"`,
      );
    }
  }

  return {
    trigger_type: triggerType,
    context: {
      user_id:
        typeof ctx.user_id === 'string' ? ctx.user_id.trim() || null : null,
      activity_id:
        typeof ctx.activity_id === 'string'
          ? ctx.activity_id.trim() || null
          : null,
      poll_id:
        typeof ctx.poll_id === 'string' ? ctx.poll_id.trim() || null : null,
      challenge_id:
        typeof ctx.challenge_id === 'string'
          ? ctx.challenge_id.trim() || null
          : null,
      past_activity_id:
        typeof ctx.past_activity_id === 'string'
          ? ctx.past_activity_id.trim() || null
          : null,
    },
  };
}
