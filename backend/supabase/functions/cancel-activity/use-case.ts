import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateCancelActivity } from '../_shared/validators/events.validators.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';

export async function handleCancelActivity(
  body: unknown,
  userId: string,
  userClient: SupabaseClient,
) {
  const input = validateCancelActivity(body);
  const adminClient = createAdminClient();

  // Fetch activity
  const { data: activity } = await adminClient
    .from('activities')
    .select('id, created_by, status')
    .eq('id', input.activity_id)
    .single();

  if (!activity) {
    throw new AppError('NOT_FOUND', 'Activity not found');
  }
  if (activity.status === 'cancelled') {
    throw new AppError('CONFLICT', 'Activity is already cancelled');
  }

  // Check authorization: must be creator or admin
  const isCreator = activity.created_by === userId;
  if (!isCreator) {
    const { data: profile } = await userClient
      .from('profiles')
      .select('app_role')
      .eq('id', userId)
      .single();
    if (!profile || profile.app_role !== 'admin') {
      throw new AppError('FORBIDDEN', 'Only the event creator or an admin can cancel this activity');
    }
  }

  // Cancel the activity
  await adminClient
    .from('activities')
    .update({ status: 'cancelled', cancelled_at: new Date().toISOString() })
    .eq('id', input.activity_id);

  // Notify RSVPed members (going + maybe)
  const { data: rsvps } = await adminClient
    .from('activity_rsvps')
    .select('user_id')
    .eq('activity_id', input.activity_id)
    .in('status', ['going', 'maybe']);

  if (rsvps && rsvps.length > 0) {
    await dispatchNotification(adminClient, {
      recipientIds: rsvps.map((r) => r.user_id),
      type: 'activity_cancelled',
      title: 'Event cancelled',
      body: 'An event you RSVPed to has been cancelled',
      referenceType: 'activity',
      referenceId: input.activity_id,
    });
  }

  return { cancelled: true };
}
