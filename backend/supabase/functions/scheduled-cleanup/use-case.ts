import { createAdminClient } from '../_shared/supabase-client.ts';
import { handleClosePoll } from '../close-poll/use-case.ts';
import { handleCloseChallenge } from '../close-challenge/use-case.ts';

export async function handleScheduledCleanup() {
  const adminClient = createAdminClient();
  const thirtyDaysAgo = new Date(
    Date.now() - 30 * 24 * 60 * 60 * 1000,
  ).toISOString();
  const ninetyDaysAgo = new Date(
    Date.now() - 90 * 24 * 60 * 60 * 1000,
  ).toISOString();

  const { data: deletedPosts } = await adminClient
    .from('posts')
    .select('id')
    .eq('is_deleted', true)
    .lt('deleted_at', thirtyDaysAgo);

  let hardDeletedPosts = 0;
  if (deletedPosts && deletedPosts.length > 0) {
    const ids = deletedPosts.map((p) => p.id);
    const { error } = await adminClient
      .from('posts')
      .delete()
      .in('id', ids);
    if (!error) {
      hardDeletedPosts = ids.length;
    }
  }

  const { data: deletedComments } = await adminClient
    .from('comments')
    .select('id')
    .eq('is_deleted', true)
    .lt('deleted_at', thirtyDaysAgo);

  let hardDeletedComments = 0;
  if (deletedComments && deletedComments.length > 0) {
    const ids = deletedComments.map((c) => c.id);
    const { error } = await adminClient
      .from('comments')
      .delete()
      .in('id', ids);
    if (!error) {
      hardDeletedComments = ids.length;
    }
  }

  const { count: expiredCount } = await adminClient
    .from('invitations')
    .update({ status: 'expired' }, { count: 'exact' })
    .eq('status', 'pending')
    .lt('expires_at', new Date().toISOString());

  const expiredInvitations = expiredCount ?? 0;

  const { data: oldNotifications } = await adminClient
    .from('notification_inbox')
    .select('id')
    .lt('created_at', ninetyDaysAgo);

  let prunedNotifications = 0;
  if (oldNotifications && oldNotifications.length > 0) {
    const ids = oldNotifications.map((n) => n.id);
    const { error } = await adminClient
      .from('notification_inbox')
      .delete()
      .in('id', ids);
    if (!error) {
      prunedNotifications = ids.length;
    }
  }

  await handleCloseChallenge({}, 'service_role');
  await handleClosePoll({}, 'service_role');

  return {
    hard_deleted_posts: hardDeletedPosts,
    hard_deleted_comments: hardDeletedComments,
    expired_invitations: expiredInvitations,
    pruned_notifications: prunedNotifications,
  };
}
