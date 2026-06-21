import { AppError } from '../errors.ts';

export interface SendInvitationInput {
  invitee_name: string;
  invitee_email: string | null;
  invitee_phone: string | null;
}

export function validateSendInvitation(body: unknown): SendInvitationInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.invitee_name !== 'string' || !b.invitee_name.trim()) {
    throw new AppError('VALIDATION_ERROR', 'invitee_name is required');
  }
  const email = typeof b.invitee_email === 'string' ? b.invitee_email : null;
  const phone = typeof b.invitee_phone === 'string' ? b.invitee_phone : null;
  if (!email && !phone) {
    throw new AppError('VALIDATION_ERROR', 'At least one of invitee_email or invitee_phone is required');
  }
  return { invitee_name: b.invitee_name.trim(), invitee_email: email, invitee_phone: phone };
}

export interface ValidateInviteTokenInput {
  token: string;
}

export function validateInviteToken(body: unknown): ValidateInviteTokenInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.token !== 'string' || !b.token.trim()) {
    throw new AppError('VALIDATION_ERROR', 'token is required');
  }
  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (!uuidPattern.test(b.token.trim())) {
    throw new AppError('VALIDATION_ERROR', 'token must be a valid UUID');
  }
  return { token: b.token.trim() };
}

export interface CreateProfileInput {
  token: string;
  full_name: string;
  title: string | null;
  bio: string | null;
  avatar_storage_path: string | null;
  interest_tags: string[];
}

export function validateCreateProfile(body: unknown): CreateProfileInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.token !== 'string' || !b.token.trim()) {
    throw new AppError('VALIDATION_ERROR', 'token is required');
  }
  if (typeof b.full_name !== 'string' || !b.full_name.trim()) {
    throw new AppError('VALIDATION_ERROR', 'full_name is required');
  }
  const bio = typeof b.bio === 'string' ? b.bio : null;
  if (bio && bio.length > 300) {
    throw new AppError('VALIDATION_ERROR', 'bio must be 300 characters or fewer');
  }
  return {
    token: b.token.trim(),
    full_name: b.full_name.trim(),
    title: typeof b.title === 'string' ? b.title.trim() : null,
    bio,
    avatar_storage_path: typeof b.avatar_storage_path === 'string' ? b.avatar_storage_path : null,
    interest_tags: Array.isArray(b.interest_tags) ? b.interest_tags.filter((t): t is string => typeof t === 'string') : [],
  };
}
