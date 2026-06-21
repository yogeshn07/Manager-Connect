import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateClosePoll } from '../_shared/validators/admin.validators.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';
import { writeAuditLog } from '../_shared/services/audit.service.ts';

export async function handleClosePoll(body: unknown, adminId: string) {
  const input = validateClosePoll(body);
  const adminClient = createAdminClient();
  const closedIds: string[] = [];

  if (input.poll_id) {
    const { data: poll } = await adminClient
      .from('polls')
      .select('id, is_closed')
      .eq('id', input.poll_id)
      .single();

    if (!poll) {
      throw new AppError('NOT_FOUND', 'Poll not found');
    }
    if (poll.is_closed) {
      throw new AppError('CONFLICT', 'Poll is already closed');
    }

    await adminClient
      .from('polls')
      .update({ is_closed: true, closed_at: new Date().toISOString() })
      .eq('id', input.poll_id);

    closedIds.push(input.poll_id);
  } else {
    const { data: expiredPolls } = await adminClient
      .from('polls')
      .select('id')
      .eq('is_closed', false)
      .lt('closes_at', new Date().toISOString());

    if (expiredPolls && expiredPolls.length > 0) {
      const ids = expiredPolls.map((p) => p.id);

      await adminClient
        .from('polls')
        .update({ is_closed: true, closed_at: new Date().toISOString() })
        .in('id', ids);

      closedIds.push(...ids);
    }
  }

  for (const pollId of closedIds) {
    const { data: voters } = await adminClient
      .from('poll_votes')
      .select('user_id')
      .eq('poll_id', pollId);

    if (voters && voters.length > 0) {
      await dispatchNotification(adminClient, {
        recipientIds: voters.map((v) => v.user_id),
        type: 'poll_reminder',
        title: 'Poll closed',
        body: 'A poll you voted on has been closed. Results are now final.',
        referenceType: 'poll',
        referenceId: pollId,
      });
    }

    await writeAuditLog(adminClient, {
      adminId,
      actionType: 'poll_closed',
      targetType: 'poll',
      targetId: pollId,
    });
  }

  return { closed_count: closedIds.length, poll_ids: closedIds };
}
