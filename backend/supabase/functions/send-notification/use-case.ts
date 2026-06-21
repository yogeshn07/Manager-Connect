import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';

interface SendNotificationRequest {
  recipient_ids: string[];
  type: string;
  title: string;
  body: string;
  resource_type?: string | null;
  resource_id?: string | null;
}

export async function handleSendNotification(body: unknown): Promise<{
  sent_count: number;
  skipped_count: number;
}> {
  const b = body as SendNotificationRequest;

  if (!b || !Array.isArray(b.recipient_ids) || b.recipient_ids.length === 0) {
    throw new AppError('VALIDATION_ERROR', 'recipient_ids is required and must be non-empty');
  }
  if (typeof b.type !== 'string' || !b.type) {
    throw new AppError('VALIDATION_ERROR', 'type is required');
  }
  if (typeof b.title !== 'string' || !b.title) {
    throw new AppError('VALIDATION_ERROR', 'title is required');
  }
  if (typeof b.body !== 'string' || !b.body) {
    throw new AppError('VALIDATION_ERROR', 'body is required');
  }

  const adminClient = createAdminClient();

  const result = await dispatchNotification(adminClient, {
    recipientIds: b.recipient_ids,
    type: b.type as Parameters<typeof dispatchNotification>[1]['type'],
    title: b.title,
    body: b.body,
    referenceType: b.resource_type ?? null,
    referenceId: b.resource_id ?? null,
  });

  return { sent_count: result.sentCount, skipped_count: result.skippedCount };
}
