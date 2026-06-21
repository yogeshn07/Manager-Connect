import { AppError } from '../errors.ts';

export interface ClosePollInput {
  poll_id: string | null;
}

export function validateClosePoll(body: unknown): ClosePollInput {
  const b = body as Record<string, unknown>;
  if (!b) {
    return { poll_id: null };
  }
  const pollId =
    typeof b.poll_id === 'string' && b.poll_id.trim()
      ? b.poll_id.trim()
      : null;
  return { poll_id: pollId };
}

export interface CloseChallengeInput {
  challenge_id: string | null;
}

export function validateCloseChallenge(body: unknown): CloseChallengeInput {
  const b = body as Record<string, unknown>;
  if (!b) {
    return { challenge_id: null };
  }
  const challengeId =
    typeof b.challenge_id === 'string' && b.challenge_id.trim()
      ? b.challenge_id.trim()
      : null;
  return { challenge_id: challengeId };
}

export interface AttendanceRecord {
  user_id: string;
  status: 'attended' | 'absent';
}

export interface RecordAttendanceInput {
  activity_id: string;
  records: AttendanceRecord[];
}

export function validateRecordAttendance(
  body: unknown,
): RecordAttendanceInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.activity_id !== 'string' || !b.activity_id.trim()) {
    throw new AppError('VALIDATION_ERROR', 'activity_id is required');
  }
  if (!Array.isArray(b.records) || b.records.length === 0) {
    throw new AppError(
      'VALIDATION_ERROR',
      'records must be a non-empty array',
    );
  }
  const validStatuses = ['attended', 'absent'];
  const records: AttendanceRecord[] = [];
  for (const r of b.records) {
    const rec = r as Record<string, unknown>;
    if (!rec || typeof rec.user_id !== 'string' || !rec.user_id.trim()) {
      throw new AppError(
        'VALIDATION_ERROR',
        'Each record must have a valid user_id',
      );
    }
    if (
      typeof rec.status !== 'string' ||
      !validStatuses.includes(rec.status)
    ) {
      throw new AppError(
        'VALIDATION_ERROR',
        'Each record status must be "attended" or "absent"',
      );
    }
    records.push({
      user_id: rec.user_id.trim(),
      status: rec.status as 'attended' | 'absent',
    });
  }
  return { activity_id: b.activity_id.trim(), records };
}

export interface PinAnnouncementInput {
  post_id: string | null;
  action: 'pin' | 'unpin';
}

export function validatePinAnnouncement(body: unknown): PinAnnouncementInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.action !== 'string') {
    throw new AppError('VALIDATION_ERROR', 'action is required');
  }
  if (b.action !== 'pin' && b.action !== 'unpin') {
    throw new AppError(
      'VALIDATION_ERROR',
      'action must be "pin" or "unpin"',
    );
  }
  if (
    b.action === 'pin' &&
    (typeof b.post_id !== 'string' || !b.post_id.trim())
  ) {
    throw new AppError(
      'VALIDATION_ERROR',
      'post_id is required when action is "pin"',
    );
  }
  const postId =
    typeof b.post_id === 'string' && b.post_id.trim()
      ? b.post_id.trim()
      : null;
  return { post_id: postId, action: b.action as 'pin' | 'unpin' };
}
