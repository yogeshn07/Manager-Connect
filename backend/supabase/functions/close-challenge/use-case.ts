import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateCloseChallenge } from '../_shared/validators/admin.validators.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';

export async function handleCloseChallenge(body: unknown, adminId: string) {
  const input = validateCloseChallenge(body);
  const adminClient = createAdminClient();
  const closedIds: string[] = [];

  if (input.challenge_id) {
    const { data: challenge } = await adminClient
      .from('challenges')
      .select('id, status')
      .eq('id', input.challenge_id)
      .single();

    if (!challenge) {
      throw new AppError('NOT_FOUND', 'Challenge not found');
    }
    if (challenge.status === 'ended') {
      throw new AppError('CONFLICT', 'Challenge is already ended');
    }

    await adminClient
      .from('challenges')
      .update({ status: 'ended', ended_at: new Date().toISOString() })
      .eq('id', input.challenge_id);

    closedIds.push(input.challenge_id);
  } else {
    const today = new Date().toISOString().split('T')[0];
    const { data: expiredChallenges } = await adminClient
      .from('challenges')
      .select('id')
      .eq('status', 'active')
      .lt('end_date', today);

    if (expiredChallenges && expiredChallenges.length > 0) {
      const ids = expiredChallenges.map((c) => c.id);

      await adminClient
        .from('challenges')
        .update({ status: 'ended', ended_at: new Date().toISOString() })
        .in('id', ids);

      closedIds.push(...ids);
    }
  }

  for (const challengeId of closedIds) {
    const { data: participants } = await adminClient
      .from('challenge_participants')
      .select('user_id')
      .eq('challenge_id', challengeId);

    if (participants && participants.length > 0) {
      await dispatchNotification(adminClient, {
        recipientIds: participants.map((p) => p.user_id),
        type: 'challenge_ended',
        title: 'Challenge ended',
        body: 'A challenge you joined has ended. Check the final results!',
        referenceType: 'challenge',
        referenceId: challengeId,
      });
    }
  }

  return { closed_count: closedIds.length, challenge_ids: closedIds };
}
