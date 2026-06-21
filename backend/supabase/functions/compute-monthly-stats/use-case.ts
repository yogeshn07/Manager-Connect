import { createAdminClient } from '../_shared/supabase-client.ts';
import { validateComputeMonthlyStats } from '../_shared/validators/system.validators.ts';

export async function handleComputeMonthlyStats(body: unknown) {
  const input = validateComputeMonthlyStats(body);
  const adminClient = createAdminClient();

  const monthStart = new Date(input.stat_month);
  const monthEnd = new Date(
    monthStart.getFullYear(),
    monthStart.getMonth() + 1,
    1,
  );
  const monthStartISO = monthStart.toISOString();
  const monthEndISO = monthEnd.toISOString();

  const { data: members } = await adminClient
    .from('profiles')
    .select('id')
    .eq('is_active', true)
    .eq('is_system_account', false);

  if (!members || members.length === 0) {
    return {
      members_computed: 0,
      stat_month: input.stat_month,
      health_score: 0,
    };
  }

  const memberIds = members.map((m) => m.id);
  const statsRows: Record<string, unknown>[] = [];

  const { data: allAttendance } = await adminClient
    .from('event_attendance')
    .select('user_id, activity_id, status, activities!inner(event_date)')
    .eq('status', 'attended')
    .gte('activities.event_date', monthStartISO)
    .lt('activities.event_date', monthEndISO);

  const { data: allParticipants } = await adminClient
    .from('challenge_participants')
    .select('user_id')
    .gte('joined_at', monthStartISO)
    .lt('joined_at', monthEndISO);

  const { data: allProgressLogs } = await adminClient
    .from('progress_logs')
    .select('challenge_participant_id, challenge_participants!inner(user_id)')
    .gte('log_date', input.stat_month)
    .lt('log_date', monthEnd.toISOString().split('T')[0]);

  const { data: allRecognitionsReceived } = await adminClient
    .from('recognition_recipients')
    .select('recipient_id, recognitions!inner(created_at)')
    .gte('recognitions.created_at', monthStartISO)
    .lt('recognitions.created_at', monthEndISO);

  const { data: allRecognitionsGiven } = await adminClient
    .from('recognitions')
    .select('giver_id')
    .gte('created_at', monthStartISO)
    .lt('created_at', monthEndISO);

  const { data: allPosts } = await adminClient
    .from('posts')
    .select('author_id')
    .eq('is_deleted', false)
    .gte('created_at', monthStartISO)
    .lt('created_at', monthEndISO);

  const { data: monthActivities } = await adminClient
    .from('activities')
    .select('id')
    .gte('event_date', monthStartISO)
    .lt('event_date', monthEndISO);

  const totalEventsInMonth = monthActivities?.length ?? 0;

  for (const memberId of memberIds) {
    const eventsAttended =
      allAttendance?.filter((a) => a.user_id === memberId).length ?? 0;

    const challengesJoined =
      allParticipants?.filter((p) => p.user_id === memberId).length ?? 0;

    const progressLogsCount =
      allProgressLogs?.filter((l) => {
        const cp = l.challenge_participants as unknown as { user_id: string };
        return cp?.user_id === memberId;
      }).length ?? 0;

    const recognitionsReceived =
      allRecognitionsReceived?.filter((r) => r.recipient_id === memberId)
        .length ?? 0;

    const recognitionsGiven =
      allRecognitionsGiven?.filter((r) => r.giver_id === memberId).length ?? 0;

    const postsCount =
      allPosts?.filter((p) => p.author_id === memberId).length ?? 0;

    const attendanceRate =
      totalEventsInMonth > 0
        ? Math.round((eventsAttended / totalEventsInMonth) * 10000) / 100
        : 0;

    const compositeScore =
      eventsAttended * 10 +
      challengesJoined * 8 +
      progressLogsCount * 2 +
      recognitionsReceived * 5 +
      recognitionsGiven * 3 +
      postsCount * 4;

    statsRows.push({
      user_id: memberId,
      stat_month: input.stat_month,
      events_attended: eventsAttended,
      attendance_rate: attendanceRate,
      challenges_joined: challengesJoined,
      progress_logs_count: progressLogsCount,
      recognitions_received: recognitionsReceived,
      recognitions_given: recognitionsGiven,
      posts_count: postsCount,
      composite_score: compositeScore,
      computed_at: new Date().toISOString(),
    });
  }

  if (statsRows.length > 0) {
    await adminClient
      .from('member_monthly_stats')
      .upsert(statsRows, { onConflict: 'user_id,stat_month' });
  }

  const totalMembers = members.length;
  const membersWithAttendance =
    statsRows.filter((s) => (s.events_attended as number) > 0).length;
  const membersWithChallenges =
    statsRows.filter((s) => (s.challenges_joined as number) > 0).length;
  const membersWithRecognitions =
    statsRows.filter(
      (s) =>
        (s.recognitions_received as number) > 0 ||
        (s.recognitions_given as number) > 0,
    ).length;
  const membersWithPosts =
    statsRows.filter((s) => (s.posts_count as number) > 0).length;

  const avgAttendanceRate =
    totalMembers > 0
      ? Math.round(
          (statsRows.reduce(
            (sum, s) => sum + (s.attendance_rate as number),
            0,
          ) /
            totalMembers) *
            100,
        ) / 100
      : 0;

  const challengeEngagementRate =
    totalMembers > 0
      ? Math.round((membersWithChallenges / totalMembers) * 10000) / 100
      : 0;

  const recognitionActivityRate =
    totalMembers > 0
      ? Math.round((membersWithRecognitions / totalMembers) * 10000) / 100
      : 0;

  const participationRate =
    totalMembers > 0
      ? Math.round(
          ((membersWithAttendance + membersWithPosts) / (totalMembers * 2)) *
            10000,
        ) / 100
      : 0;

  const healthScore =
    Math.round(
      (avgAttendanceRate * 0.3 +
        challengeEngagementRate * 0.2 +
        recognitionActivityRate * 0.2 +
        participationRate * 0.3) *
        100,
    ) / 100;

  await adminClient.from('community_health_scores').upsert(
    {
      score_month: input.stat_month,
      score: healthScore,
      active_member_count: totalMembers,
      avg_attendance_rate: avgAttendanceRate,
      challenge_engagement_rate: challengeEngagementRate,
      recognition_activity_rate: recognitionActivityRate,
      participation_rate: participationRate,
      computed_at: new Date().toISOString(),
    },
    { onConflict: 'score_month' },
  );

  return {
    members_computed: statsRows.length,
    stat_month: input.stat_month,
    health_score: healthScore,
  };
}
