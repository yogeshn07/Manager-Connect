import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ── Period ────────────────────────────────────────────────────────────────────

enum RankingPeriod { weekly, monthly, yearly }

extension RankingPeriodX on RankingPeriod {
  String get label => switch (this) {
        RankingPeriod.weekly  => 'Weekly',
        RankingPeriod.monthly => 'Monthly',
        RankingPeriod.yearly  => 'Yearly',
      };

  DateTime get since => switch (this) {
        RankingPeriod.weekly  => DateTime.now().subtract(const Duration(days: 7)),
        RankingPeriod.monthly => DateTime.now().subtract(const Duration(days: 30)),
        RankingPeriod.yearly  => DateTime.now().subtract(const Duration(days: 365)),
      };
}

// ── Model ─────────────────────────────────────────────────────────────────────

class RankedMember {
  const RankedMember({
    required this.rank,
    required this.userId,
    required this.fullName,
    this.title,
    this.score = 0,
    this.postPts = 0,
    this.commentPts = 0,
    this.reactionPts = 0,
    this.eventPts = 0,
    this.challengePts = 0,
    this.recognitionPts = 0,
    this.avatarColor,
  });

  final int rank;
  final String userId;
  final String fullName;
  final String? title;
  final int score;
  final int postPts;
  final int commentPts;
  final int reactionPts;
  final int eventPts;
  final int challengePts;
  final int recognitionPts;
  final Color? avatarColor;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return fullName.substring(0, fullName.length.clamp(0, 2)).toUpperCase();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

// Engagement score weights
const _wPost        = 25; // per post published
const _wComment     = 5;  // per comment made
const _wReaction    = 2;  // per reaction given
const _wEvent       = 15; // per event attended (RSVP going)
const _wChallenge   = 20; // per challenge joined
const _wRecognition = 30; // per recognition received

final rankingsProvider = FutureProvider.family
    .autoDispose<List<RankedMember>, RankingPeriod>((ref, period) async {
  final client  = ref.watch(supabaseClientProvider);
  final since   = period.since.toUtc().toIso8601String();
  final sinceDate = DateFormat('yyyy-MM-dd').format(period.since);

  const colors = [
    MCColors.primary, MCColors.primaryLight, MCColors.violet,
    MCColors.success, MCColors.amber,
  ];

  // ── Parallel queries ─────────────────────────────────────────────────────
  final results = await Future.wait([
    // 0: all active non-system members
    client
        .from('profiles')
        .select('id, full_name, title')
        .eq('is_active', true)
        .eq('is_system_account', false),

    // 1: posts in period
    client
        .from('posts')
        .select('author_id')
        .eq('is_deleted', false)
        .gte('created_at', since),

    // 2: comments in period
    client.from('comments').select('author_id').gte('created_at', since),

    // 3: reactions in period
    client.from('post_reactions').select('user_id').gte('created_at', since),

    // 4: event RSVPs (going) — filter by rsvp created_at
    client
        .from('activity_rsvps')
        .select('user_id')
        .eq('status', 'going')
        .gte('created_at', since),

    // 5: challenge participants joined in period
    client
        .from('challenge_participants')
        .select('user_id')
        .gte('joined_at', since),

    // 6: recognitions received in period (via parent recognitions table)
    client
        .from('recognitions')
        .select('recognition_recipients(recipient_id)')
        .eq('is_deleted', false)
        .gte('created_at', since),

    // 7: progress logs in period (unique dates per user)
    client
        .from('progress_logs')
        .select('user_id, log_date')
        .gte('log_date', sinceDate),
  ]);

  // ── Build count maps ──────────────────────────────────────────────────────
  Map<String, int> countMap(List rows, String key) {
    final m = <String, int>{};
    for (final row in rows) {
      final uid = (row as Map<String, dynamic>)[key] as String?;
      if (uid != null) m[uid] = (m[uid] ?? 0) + 1;
    }
    return m;
  }

  final members    = results[0] as List;
  final posts      = countMap(results[1] as List, 'author_id');
  final comments   = countMap(results[2] as List, 'author_id');
  final reactions  = countMap(results[3] as List, 'user_id');
  final events     = countMap(results[4] as List, 'user_id');
  final challenges = countMap(results[5] as List, 'user_id');

  // Recognitions received: nested recipients
  final recognitions = <String, int>{};
  for (final rec in results[6] as List) {
    final rList = (rec as Map<String, dynamic>)['recognition_recipients'] as List? ?? [];
    for (final r in rList) {
      final uid = (r as Map<String, dynamic>)['recipient_id'] as String?;
      if (uid != null) recognitions[uid] = (recognitions[uid] ?? 0) + 1;
    }
  }

  // Progress logs: count unique (user, date) pairs to avoid counting same-day
  // multi-task logs multiple times
  final progressUnique = <String, Set<String>>{};
  for (final row in results[7] as List) {
    final uid  = (row as Map<String, dynamic>)['user_id'] as String?;
    final date = row['log_date'] as String?;
    if (uid != null && date != null) {
      (progressUnique[uid] ??= {}).add(date);
    }
  }
  final progressDays = progressUnique.map((k, v) => MapEntry(k, v.length));

  // ── Score each member ─────────────────────────────────────────────────────
  final ranked = members.asMap().entries.map((entry) {
    final i   = entry.key;
    final row = entry.value as Map<String, dynamic>;
    final uid = row['id'] as String;

    final postPts        = (posts[uid]        ?? 0) * _wPost;
    final commentPts     = (comments[uid]     ?? 0) * _wComment;
    final reactionPts    = (reactions[uid]    ?? 0) * _wReaction;
    final eventPts       = (events[uid]       ?? 0) * _wEvent;
    final challengePts   = (challenges[uid]   ?? 0) * _wChallenge;
    final recognitionPts = (recognitions[uid] ?? 0) * _wRecognition;
    final progressPts    = (progressDays[uid] ?? 0) * 3;

    final score = postPts + commentPts + reactionPts + eventPts +
                  challengePts + recognitionPts + progressPts;

    return _ScoredMember(
      uid:             uid,
      fullName:        (row['full_name'] as String?) ?? 'Member',
      title:           row['title'] as String?,
      score:           score,
      postPts:         postPts,
      commentPts:      commentPts,
      reactionPts:     reactionPts,
      eventPts:        eventPts,
      challengePts:    challengePts,
      recognitionPts:  recognitionPts,
      colorIdx:        i % colors.length,
    );
  }).toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  return ranked.asMap().entries.map((entry) {
    final i = entry.key;
    final m = entry.value;
    return RankedMember(
      rank:           i + 1,
      userId:         m.uid,
      fullName:       m.fullName,
      title:          m.title,
      score:          m.score,
      postPts:        m.postPts,
      commentPts:     m.commentPts,
      reactionPts:    m.reactionPts,
      eventPts:       m.eventPts,
      challengePts:   m.challengePts,
      recognitionPts: m.recognitionPts,
      avatarColor:    colors[m.colorIdx],
    );
  }).toList();
});

class _ScoredMember {
  const _ScoredMember({
    required this.uid, required this.fullName, this.title,
    required this.score, required this.postPts, required this.commentPts,
    required this.reactionPts, required this.eventPts,
    required this.challengePts, required this.recognitionPts,
    required this.colorIdx,
  });
  final String uid;
  final String fullName;
  final String? title;
  final int score;
  final int postPts, commentPts, reactionPts, eventPts, challengePts, recognitionPts;
  final int colorIdx;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  RankingPeriod _period = RankingPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final rankingsAsync = ref.watch(rankingsProvider(_period));

    return Scaffold(
      backgroundColor: MCColors.background,
      body: MCAmbientIdentityBackground(
        child: SafeArea(
          child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: const BoxDecoration(
                color: MCColors.card,
                border: Border(bottom: BorderSide(color: MCColors.borderLight)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, size: 22, color: MCColors.textSecondary),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Leaderboard', style: MCTypography.h3),
                        Text('Engagement Rankings', style: MCTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Period tabs ──────────────────────────────────────────────
            Container(
              color: MCColors.card,
              padding: const EdgeInsets.fromLTRB(
                  MCSpacing.pageH, 0, MCSpacing.pageH, MCSpacing.sm),
              child: Row(
                children: RankingPeriod.values.map((p) {
                  final selected = _period == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? MCColors.primary : MCColors.background,
                          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                          border: Border.all(
                            color: selected ? MCColors.primary : MCColors.border,
                          ),
                        ),
                        child: Text(
                          p.label,
                          style: MCTypography.captionBold.copyWith(
                            color: selected ? Colors.white : MCColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Ranking list ─────────────────────────────────────────────
            Expanded(
              child: rankingsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MCColors.primaryMid),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Could not load rankings',
                    style: MCTypography.body.copyWith(color: MCColors.textSecondary),
                  ),
                ),
                data: (members) {
                  if (members.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.leaderboard_outlined,
                              size: 48, color: MCColors.textMuted),
                          const SizedBox(height: MCSpacing.sm),
                          Text('No activity yet this period',
                              style: MCTypography.body
                                  .copyWith(color: MCColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Post, attend events or join challenges to appear here',
                              style: MCTypography.caption,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }

                  final top3 = members.take(3).toList();
                  final rest = members.skip(3).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(MCSpacing.pageH),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Score formula chip ──────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: MCColors.primaryPale,
                            borderRadius:
                                BorderRadius.circular(MCSpacing.radiusSm),
                          ),
                          child: Text(
                            'Score: Posts×25  Events×15  Challenges×20  '
                            'Recognitions×30  Comments×5  Reactions×2',
                            style: MCTypography.caption.copyWith(
                                color: MCColors.primaryMid),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: MCSpacing.md),

                        if (top3.isNotEmpty) ...[
                          _PodiumSection(members: top3),
                          const SizedBox(height: MCSpacing.md),
                        ],

                        if (rest.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: MCColors.card,
                              borderRadius:
                                  BorderRadius.circular(MCSpacing.radiusMd),
                              border: Border.all(color: MCColors.border),
                              boxShadow: MCColors.cardShadow,
                            ),
                            child: Column(
                              children: rest.asMap().entries.map((entry) {
                                final i = entry.key;
                                final member = entry.value;
                                return Column(
                                  children: [
                                    _RankRow(member: member),
                                    if (i < rest.length - 1)
                                      const Divider(
                                        color: MCColors.borderLight,
                                        height: 1,
                                        thickness: 1,
                                        indent: MCSpacing.cardPadH,
                                        endIndent: MCSpacing.cardPadH,
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: MCSpacing.xl),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({required this.members});
  final List<RankedMember> members;

  @override
  Widget build(BuildContext context) {
    final first  = members.isNotEmpty     ? members[0] : null;
    final second = members.length > 1 ? members[1] : null;
    final third  = members.length > 2 ? members[2] : null;

    return Container(
      padding: const EdgeInsets.all(MCSpacing.lg),
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) Expanded(child: _PodiumSlot(member: second, isFirst: false)),
          const SizedBox(width: MCSpacing.sm),
          if (first != null)  Expanded(child: _PodiumSlot(member: first, isFirst: true)),
          const SizedBox(width: MCSpacing.sm),
          if (third != null)  Expanded(child: _PodiumSlot(member: third, isFirst: false)),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({required this.member, required this.isFirst});
  final RankedMember member;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isFirst ? 64.0 : 48.0;
    final medalColor = member.rank == 1
        ? MCColors.amber
        : member.rank == 2
            ? const Color(0xFFD4D4D4)
            : const Color(0xFFCD7F32);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst)
          Container(
            width: avatarSize + 6,
            height: avatarSize + 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MCColors.amber, width: 3),
            ),
            child: Center(
              child: MCAvatar(
                initials: member.initials,
                size: avatarSize,
                backgroundColor: member.avatarColor ?? MCColors.primary,
              ),
            ),
          )
        else
          MCAvatar(
            initials: member.initials,
            size: avatarSize,
            backgroundColor: member.avatarColor ?? MCColors.primary,
          ),
        const SizedBox(height: MCSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: medalColor,
            borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
          ),
          child: Text(
            '#${member.rank}',
            style: MCTypography.overline.copyWith(
              color: member.rank == 1 ? MCColors.textPrimary : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          member.fullName.split(' ').first,
          style: MCTypography.labelSm,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: MCColors.primaryPale,
            borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
          ),
          child: Text(
            '${member.score} pts',
            style: MCTypography.overline.copyWith(color: MCColors.primaryMid),
          ),
        ),
      ],
    );
  }
}

// ── Rank row ──────────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  const _RankRow({required this.member});
  final RankedMember member;

  @override
  Widget build(BuildContext context) {
    final isTop10 = member.rank <= 10;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: MCSpacing.cardPadH, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${member.rank}',
              style: MCTypography.label.copyWith(
                color: isTop10 ? MCColors.primary : MCColors.textMuted,
                fontWeight: isTop10 ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: MCSpacing.sm),
          MCAvatar(
            initials: member.initials,
            size: MCAvatar.md,
            backgroundColor: member.avatarColor ?? MCColors.primary,
          ),
          const SizedBox(width: MCSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: MCTypography.labelSm, overflow: TextOverflow.ellipsis),
                if (member.title != null && member.title!.isNotEmpty)
                  Text(member.title!,
                      style: MCTypography.caption, overflow: TextOverflow.ellipsis),
                // Breakdown mini-row
                const SizedBox(height: 2),
                _ScoreBreakdown(member: member),
              ],
            ),
          ),
          const SizedBox(width: MCSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MCColors.primaryPale,
              borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
            ),
            child: Text(
              '${member.score} pts',
              style: MCTypography.labelSm.copyWith(color: MCColors.primaryMid),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.member});
  final RankedMember member;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (member.postPts        > 0) parts.add('📝${member.postPts ~/ _wPost}');
    if (member.eventPts       > 0) parts.add('🎯${member.eventPts ~/ _wEvent}');
    if (member.challengePts   > 0) parts.add('🏆${member.challengePts ~/ _wChallenge}');
    if (member.recognitionPts > 0) parts.add('⭐${member.recognitionPts ~/ _wRecognition}');
    if (member.commentPts     > 0) parts.add('💬${member.commentPts ~/ _wComment}');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join('  '),
      style: MCTypography.caption.copyWith(color: MCColors.textMuted, fontSize: 10),
    );
  }
}
