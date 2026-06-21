import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validatePostActivityUpdate } from '../_shared/validators/events.validators.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';

export async function handlePostActivityUpdate(body: unknown, userId: string) {
  const input = validatePostActivityUpdate(body);
  const adminClient = createAdminClient();

  // Fetch activity and verify creator
  const { data: activity } = await adminClient
    .from('activities')
    .select('id, created_by, status')
    .eq('id', input.activity_id)
    .single();

  if (!activity) {
    throw new AppError('NOT_FOUND', 'Activity not found');
  }
  if (activity.created_by !== userId) {
    throw new AppError('FORBIDDEN', 'Only the event creator can post updates');
  }
  if (activity.status === 'cancelled') {
    throw new AppError('CONFLICT', 'Cannot post updates on a cancelled activity');
  }

  // Insert activity update
  const { data: update, error } = await adminClient
    .from('activity_updates')
    .insert({
      activity_id: input.activity_id,
      author_id: userId,
      content: input.content,
    })
    .select('id, created_at')
    .single();

  if (error || !update) {
    throw new AppError('SERVER_ERROR', 'Failed to post activity update');
  }

  // Notify RSVPed members (going + maybe)
  const { data: rsvps } = await adminClient
    .from('activity_rsvps')
    .select('user_id')
    .eq('activity_id', input.activity_id)
    .in('status', ['going', 'maybe']);

  if (rsvps && rsvps.length > 0) {
    await dispatchNotification(adminClient, {
      recipientIds: rsvps.map((r) => r.user_id),
      type: 'activity_updated',
      title: 'Event update',
      body: 'The organizer posted an update to an event you RSVPed to',
      referenceType: 'activity',
      referenceId: input.activity_id,
    });
  }

  return { update_id: update.id, created_at: update.created_at };
}
