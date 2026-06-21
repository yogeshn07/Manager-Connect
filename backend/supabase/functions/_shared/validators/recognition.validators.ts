import { AppError } from '../errors.ts';
import { MAX_RECOGNITION_MESSAGE_LENGTH } from '../constants.ts';

const VALID_CATEGORY_TAGS = [
  'community_contributor',
  'fitness_champion',
  'wellness_champion',
  'event_champion',
  'most_supportive_manager',
] as const;

export interface CreateRecognitionInput {
  recipient_ids: string[];
  category_tag: string;
  message: string;
}

export function validateCreateRecognition(body: unknown): CreateRecognitionInput {
  const b = body as Record<string, unknown>;
  if (!b || !Array.isArray(b.recipient_ids) || b.recipient_ids.length === 0) {
    throw new AppError('VALIDATION_ERROR', 'At least one recipient_id is required');
  }
  const recipientIds = b.recipient_ids.filter((id): id is string => typeof id === 'string' && id.trim().length > 0);
  if (recipientIds.length === 0) {
    throw new AppError('VALIDATION_ERROR', 'At least one valid recipient_id is required');
  }
  if (typeof b.category_tag !== 'string' || !VALID_CATEGORY_TAGS.includes(b.category_tag as typeof VALID_CATEGORY_TAGS[number])) {
    throw new AppError('VALIDATION_ERROR', `category_tag must be one of: ${VALID_CATEGORY_TAGS.join(', ')}`);
  }
  if (typeof b.message !== 'string' || !b.message.trim()) {
    throw new AppError('VALIDATION_ERROR', 'message is required');
  }
  if (b.message.length > MAX_RECOGNITION_MESSAGE_LENGTH) {
    throw new AppError('VALIDATION_ERROR', `message must be ${MAX_RECOGNITION_MESSAGE_LENGTH} characters or fewer`);
  }
  return { recipient_ids: recipientIds, category_tag: b.category_tag, message: b.message.trim() };
}
