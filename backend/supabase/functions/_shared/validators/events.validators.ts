import { AppError } from '../errors.ts';

export interface CreatePollInput {
  question: string;
  options: string[];
  closes_at: string;
  activity_id: string | null;
}

export function validateCreatePoll(body: unknown): CreatePollInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.question !== 'string' || !b.question.trim()) {
    throw new AppError('VALIDATION_ERROR', 'question is required');
  }
  if (!Array.isArray(b.options) || b.options.length < 2) {
    throw new AppError('VALIDATION_ERROR', 'At least 2 options are required');
  }
  if (b.options.length > 10) {
    throw new AppError('VALIDATION_ERROR', 'Maximum 10 options allowed');
  }
  const validOptions = b.options.filter((o): o is string => typeof o === 'string' && o.trim().length > 0);
  if (validOptions.length < 2) {
    throw new AppError('VALIDATION_ERROR', 'At least 2 non-empty options are required');
  }
  if (typeof b.closes_at !== 'string' || !b.closes_at) {
    throw new AppError('VALIDATION_ERROR', 'closes_at is required');
  }
  const closesAt = new Date(b.closes_at);
  if (isNaN(closesAt.getTime())) {
    throw new AppError('VALIDATION_ERROR', 'closes_at must be a valid ISO 8601 timestamp');
  }
  if (closesAt <= new Date()) {
    throw new AppError('VALIDATION_ERROR', 'closes_at must be in the future');
  }
  const activityId = typeof b.activity_id === 'string' && b.activity_id.trim() ? b.activity_id.trim() : null;
  return { question: b.question.trim(), options: validOptions.map((o) => o.trim()), closes_at: closesAt.toISOString(), activity_id: activityId };
}

export interface CancelActivityInput {
  activity_id: string;
}

export function validateCancelActivity(body: unknown): CancelActivityInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.activity_id !== 'string' || !b.activity_id.trim()) {
    throw new AppError('VALIDATION_ERROR', 'activity_id is required');
  }
  return { activity_id: b.activity_id.trim() };
}

export interface PostActivityUpdateInput {
  activity_id: string;
  content: string;
}

export function validatePostActivityUpdate(body: unknown): PostActivityUpdateInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.activity_id !== 'string' || !b.activity_id.trim()) {
    throw new AppError('VALIDATION_ERROR', 'activity_id is required');
  }
  if (typeof b.content !== 'string' || !b.content.trim()) {
    throw new AppError('VALIDATION_ERROR', 'content is required');
  }
  return { activity_id: b.activity_id.trim(), content: b.content.trim() };
}
