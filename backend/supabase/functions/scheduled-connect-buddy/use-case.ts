import { AppError } from '../_shared/errors.ts';
import { createAdminClient } from '../_shared/supabase-client.ts';
import { CONNECT_BUDDY_PROFILE_ID } from '../_shared/constants.ts';
import {
  validateScheduledConnectBuddy,
  type TriggerType,
} from '../_shared/validators/system.validators.ts';
import { dispatchNotification } from '../_shared/services/notification.service.ts';

export async function handleScheduledConnectBuddy(body: unknown) {
  const input = validateScheduledConnectBuddy(body);
  const adminClient = createAdminClient();

  const { data: cbProfile } = await adminClient
    .from('profiles')
    .select('id')
    .eq('id', CONNECT_BUDDY_PROFILE_ID)
    .single();

  if (!cbProfile) {
    throw new AppError(
      'SERVER_ERROR',
      'Connect Buddy system profile not found',
    );
  }

  const handler = TRIGGER_HANDLERS[input.trigger_type];
  return await handler(adminClient, input.context);
}

type Context = {
  user_id?: string | null;
  activity_id?: string | null;
  poll_id?: string | null;
  challenge_id?: string | null;
  past_activity_id?: string | null;
};

type SupabaseClient = Awaited<
  ReturnType<typeof import('../_shared/supabase-client.ts').createAdminClient>
>;

async function postAndNotify(
  adminClient: SupabaseClient,
  content: string,
  recipientIds: string[],
  notificationTitle: string,
  notificationBody: string,
  triggerType: TriggerType,
) {
  const { data: post, error } = await adminClient
    .from('posts')
    .insert({ author_id: CONNECT_BUDDY_PROFILE_ID, content })
    .select('id')
    .single();

  if (error || !post) {
    throw new AppError('SERVER_ERROR', 'Failed to create Connect Buddy post');
  }

  if (recipientIds.length > 0) {
    await dispatchNotification(adminClient, {
      recipientIds,
      type: 'connect_buddy_update',
      title: notificationTitle,
      body: notificationBody,
      referenceType: 'post',
      referenceId: post.id,
    });
  }

  return { trigger_type: triggerType, post_id: post.id, skipped: false };
}

async function getAllActiveMemberIds(
  adminClient: SupabaseClient,
): Promise<string[]> {
  const { data } = await adminClient
    .from('profiles')
    .select('id')
    .eq('is_active', true)
    .eq('is_system_account', false);
  return data?.map((m) => m.id) ?? [];
}

const TRIGGER_HANDLERS: Record<
  TriggerType,
  (
    client: SupabaseClient,
    ctx: Context,
  ) => Promise<{ trigger_type: string; post_id: string | null; skipped: boolean }>
> = {
  async welcome(client, ctx) {
    const { data: member } = await client
      .from('profiles')
      .select('full_name')
      .eq('id', ctx.user_id!)
      .single();

    const name = member?.full_name ?? 'New Member';
    const content = `Welcome to the community, ${name}! We're excited to have you here. Feel free to introduce yourself and explore upcoming events and challenges.`;

    return postAndNotify(
      client,
      content,
      [ctx.user_id!],
      'Welcome to Manager Connect!',
      `${name}, your community awaits!`,
      'welcome',
    );
  },

  async monthly_highlights(client, _ctx) {
    const prevMonth = new Date();
    prevMonth.setMonth(prevMonth.getMonth() - 1);
    const statMonth = new Date(
      prevMonth.getFullYear(),
      prevMonth.getMonth(),
      1,
    )
      .toISOString()
      .split('T')[0];

    const { data: topMembers } = await client
      .from('member_monthly_stats')
      .select('user_id, composite_score, profiles!inner(full_name)')
      .eq('stat_month', statMonth)
      .order('composite_score', { ascending: false })
      .limit(3);

    if (!topMembers || topMembers.length === 0) {
      return {
        trigger_type: 'monthly_highlights' as string,
        post_id: null,
        skipped: true,
      };
    }

    const highlights = topMembers
      .map((m, i) => {
        const profile = m.profiles as unknown as { full_name: string };
        return `${i + 1}. ${profile.full_name} — Score: ${m.composite_score}`;
      })
      .join('\n');

    const content = `Monthly Highlights! Here are our top performers last month:\n\n${highlights}\n\nKeep up the amazing work, everyone!`;
    const memberIds = await getAllActiveMemberIds(client);

    return postAndNotify(
      client,
      content,
      memberIds,
      'Monthly Highlights',
      'Check out last month\'s top performers!',
      'monthly_highlights',
    );
  },

  async event_reminder(client, ctx) {
    const { data: activity } = await client
      .from('activities')
      .select('id, title, event_date, location')
      .eq('id', ctx.activity_id!)
      .single();

    if (!activity) {
      throw new AppError('NOT_FOUND', 'Activity not found');
    }

    const eventDate = new Date(activity.event_date).toLocaleDateString(
      'en-US',
      { weekday: 'long', month: 'long', day: 'numeric' },
    );
    const locationText = activity.location
      ? ` at ${activity.location}`
      : '';
    const content = `Reminder: "${activity.title}" is happening ${eventDate}${locationText}. Don't forget to show up!`;

    const { data: rsvps } = await client
      .from('activity_rsvps')
      .select('user_id')
      .eq('activity_id', ctx.activity_id!)
      .in('status', ['going', 'maybe']);

    const recipientIds = rsvps?.map((r) => r.user_id) ?? [];

    return postAndNotify(
      client,
      content,
      recipientIds,
      'Event Reminder',
      `"${activity.title}" is coming up soon!`,
      'event_reminder',
    );
  },

  async poll_reminder(client, ctx) {
    const { data: poll } = await client
      .from('polls')
      .select('id, question, closes_at')
      .eq('id', ctx.poll_id!)
      .single();

    if (!poll) {
      throw new AppError('NOT_FOUND', 'Poll not found');
    }

    const closesAt = new Date(poll.closes_at).toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
    });
    const content = `Poll closing soon! "${poll.question}" closes on ${closesAt}. Cast your vote before it's too late!`;

    const { data: voters } = await client
      .from('poll_votes')
      .select('user_id')
      .eq('poll_id', ctx.poll_id!);

    const voterIds = new Set(voters?.map((v) => v.user_id) ?? []);
    const allMembers = await getAllActiveMemberIds(client);
    const nonVoters = allMembers.filter((id) => !voterIds.has(id));

    return postAndNotify(
      client,
      content,
      nonVoters,
      'Poll Reminder',
      `Vote on "${poll.question}" before it closes!`,
      'poll_reminder',
    );
  },

  async achievement(client, ctx) {
    const { data: challenge } = await client
      .from('challenges')
      .select('id, title')
      .eq('id', ctx.challenge_id!)
      .single();

    if (!challenge) {
      throw new AppError('NOT_FOUND', 'Challenge not found');
    }

    const content = `The "${challenge.title}" challenge has been completed! Congratulations to all participants who gave it their best. Check the final leaderboard!`;
    const memberIds = await getAllActiveMemberIds(client);

    return postAndNotify(
      client,
      content,
      memberIds,
      'Challenge Complete!',
      `"${challenge.title}" has ended — see the results!`,
      'achievement',
    );
  },

  async community_update(client, _ctx) {
    const { data: members } = await client
      .from('profiles')
      .select('id')
      .eq('is_active', true)
      .eq('is_system_account', false);

    const memberCount = members?.length ?? 0;
    const content = `Community Update: We now have ${memberCount} active members! Thank you for being part of this amazing community. Let's keep growing together!`;
    const memberIds = members?.map((m) => m.id) ?? [];

    return postAndNotify(
      client,
      content,
      memberIds,
      'Community Update',
      `We've reached ${memberCount} active members!`,
      'community_update',
    );
  },

  async memory(client, ctx) {
    const { data: activity } = await client
      .from('activities')
      .select('id, title, event_date, location')
      .eq('id', ctx.past_activity_id!)
      .single();

    if (!activity) {
      throw new AppError('NOT_FOUND', 'Past activity not found');
    }

    const eventDate = new Date(activity.event_date).toLocaleDateString(
      'en-US',
      { month: 'long', year: 'numeric' },
    );
    const locationText = activity.location
      ? ` at ${activity.location}`
      : '';
    const content = `Remember when we had "${activity.title}"${locationText} back in ${eventDate}? Those were great times! What's your favorite memory from that event?`;
    const memberIds = await getAllActiveMemberIds(client);

    return postAndNotify(
      client,
      content,
      memberIds,
      'Community Memory',
      `Remember "${activity.title}"?`,
      'memory',
    );
  },
};
