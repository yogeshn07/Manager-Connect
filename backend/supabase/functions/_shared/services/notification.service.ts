import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

type NotificationType =
  | 'activity_created'
  | 'activity_reminder_24h'
  | 'activity_reminder_1h'
  | 'activity_cancelled'
  | 'activity_updated'
  | 'poll_reminder'
  | 'recognition_received'
  | 'challenge_created'
  | 'challenge_ending'
  | 'challenge_ended'
  | 'mention'
  | 'comment_on_post'
  | 'connect_buddy_update'
  | 'admin_flag'
  | 'admin_member_registered';

const PREFERENCE_MAP: Record<string, string> = {
  activity_created: 'new_activities',
  activity_reminder_24h: 'activity_reminders',
  activity_reminder_1h: 'activity_reminders',
  activity_cancelled: 'activity_reminders',
  activity_updated: 'activity_reminders',
  poll_reminder: 'poll_reminders',
  recognition_received: 'recognitions_received',
  challenge_created: 'new_challenges',
  challenge_ending: 'challenge_reminders',
  challenge_ended: 'challenge_reminders',
  mention: 'mentions',
  comment_on_post: 'comments_on_my_posts',
  connect_buddy_update: 'connect_buddy_updates',
};

interface NotificationPayload {
  recipientIds: string[];
  type: NotificationType;
  title: string;
  body: string;
  referenceType?: string | null;
  referenceId?: string | null;
}

export async function dispatchNotification(
  adminClient: SupabaseClient,
  payload: NotificationPayload,
): Promise<{ sentCount: number; skippedCount: number }> {
  if (payload.recipientIds.length === 0) {
    return { sentCount: 0, skippedCount: 0 };
  }

  const { data: recipients } = await adminClient
    .from('profiles')
    .select('id, push_token, notification_preferences')
    .in('id', payload.recipientIds)
    .eq('is_active', true);

  if (!recipients || recipients.length === 0) {
    return { sentCount: 0, skippedCount: payload.recipientIds.length };
  }

  const prefKey = PREFERENCE_MAP[payload.type];
  let sentCount = 0;
  let skippedCount = 0;
  const inboxRows: Record<string, unknown>[] = [];

  for (const recipient of recipients) {
    const prefs = recipient.notification_preferences as Record<string, boolean> | null;
    const isAdminNotification = payload.type === 'admin_flag' || payload.type === 'admin_member_registered';
    const isOptedIn = isAdminNotification || !prefKey || (prefs && prefs[prefKey] !== false);

    inboxRows.push({
      recipient_id: recipient.id,
      actor_id: null,
      type: payload.type,
      title: payload.title,
      body: payload.body,
      reference_type: payload.referenceType ?? null,
      reference_id: payload.referenceId ?? null,
    });

    if (isOptedIn && recipient.push_token) {
      sentCount++;
      // FCM push dispatch will be implemented when FCM_SERVER_KEY is configured
      // For now, notification is persisted in inbox but push is deferred
    } else {
      skippedCount++;
    }
  }

  if (inboxRows.length > 0) {
    const { error } = await adminClient.from('notification_inbox').insert(inboxRows);
    if (error) {
      console.error('Failed to insert notifications:', error.message);
    }
  }

  return { sentCount, skippedCount };
}
