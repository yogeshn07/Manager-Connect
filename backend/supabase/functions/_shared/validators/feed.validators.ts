import { AppError } from '../errors.ts';
import { MAX_POST_CONTENT_LENGTH, MAX_POST_IMAGE_COUNT } from '../constants.ts';

export interface CreatePostInput {
  content: string;
  image_storage_paths: string[];
}

export function validateCreatePost(body: unknown): CreatePostInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.content !== 'string' || !b.content.trim()) {
    throw new AppError('VALIDATION_ERROR', 'content is required');
  }
  if (b.content.length > MAX_POST_CONTENT_LENGTH) {
    throw new AppError('VALIDATION_ERROR', `content must be ${MAX_POST_CONTENT_LENGTH} characters or fewer`);
  }
  const paths = Array.isArray(b.image_storage_paths)
    ? b.image_storage_paths.filter((p): p is string => typeof p === 'string')
    : [];
  if (paths.length > MAX_POST_IMAGE_COUNT) {
    throw new AppError('VALIDATION_ERROR', `Maximum ${MAX_POST_IMAGE_COUNT} images allowed`);
  }
  return { content: b.content.trim(), image_storage_paths: paths };
}

export interface ConnectBuddyPostInput {
  content: string;
  image_storage_paths: string[];
  notify_all: boolean;
  notification_title: string | null;
  notification_body: string | null;
}

export function validateConnectBuddyPost(body: unknown): ConnectBuddyPostInput {
  const b = body as Record<string, unknown>;
  if (!b || typeof b.content !== 'string' || !b.content.trim()) {
    throw new AppError('VALIDATION_ERROR', 'content is required');
  }
  const notifyAll = b.notify_all === true;
  if (notifyAll) {
    if (typeof b.notification_title !== 'string' || !b.notification_title.trim()) {
      throw new AppError('VALIDATION_ERROR', 'notification_title is required when notify_all is true');
    }
    if (typeof b.notification_body !== 'string' || !b.notification_body.trim()) {
      throw new AppError('VALIDATION_ERROR', 'notification_body is required when notify_all is true');
    }
  }
  return {
    content: b.content.trim(),
    image_storage_paths: Array.isArray(b.image_storage_paths)
      ? b.image_storage_paths.filter((p): p is string => typeof p === 'string')
      : [],
    notify_all: notifyAll,
    notification_title: typeof b.notification_title === 'string' ? b.notification_title.trim() : null,
    notification_body: typeof b.notification_body === 'string' ? b.notification_body.trim() : null,
  };
}
