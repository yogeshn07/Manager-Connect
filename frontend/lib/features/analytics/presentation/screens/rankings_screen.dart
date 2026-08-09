import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class RankedMember {
  const RankedMember({
    required this.rank,
    required this.userId,
    required this.fullName,
    this.title,
    this.score = 0,
    this.avatarColor,
  });

  final int rank;
  final String userId;
  final String fullName;
  final String? title;
  final int score;
  final Color? avatarColor;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length.clamp(0, 2)).toUpperCase();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final rankingsProvider =
    FutureProvider.autoDispose<List<RankedMember>>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  const _colors = [
    MCColors.primary,
    MCColors.primaryLight,
    MCColors.violet,
    MCColors.success,
    MCColors.amber,
  ];

  try {
    final response = await client
        .from('member_rankings')
        .select('rank, user_id, full_name, title, composite_score')
        .order('rank')
        .limit(20);

    return (response as List).asMap().entries.map((entry) {
      final i = entry.key;
      final row = entry.value as Map<String, dynamic>;
      return RankedMember(
        rank: (row['rank'] as int?) ?? (i + 1),
        userId: (row['user_id'] as String?) ?? '',
        fullName: (row['full_name'] as String?) ?? 'Member',
        title: row['title'] as String?,
        score: (row['composite_score'] as int?) ?? 0,
        avatarColor: _colors[i % _colors.length],
      );
    }).toList();
  } catch (_) {
    return [];
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class RankingsScreen extends ConsumerWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingsAsync = ref.watch(rankingsProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: const BoxDecoration(
                color: MCColors.card,
                border: Border(
                  bottom: BorderSide(color: MCColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 22,
                      color: MCColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Leaderboard', style: MCTypography.h3),
                        Text('Community Rankings', style: MCTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
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
                    style: MCTypography.body.copyWith(
                      color: MCColors.textSecondary,
                    ),
                  ),
                ),
                data: (members) {
                  if (members.isEmpty) {
                    return Center(
                      child: Text(
                        'No rankings yet',
                        style: MCTypography.body.copyWith(
                          color: MCColors.textSecondary,
                        ),
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
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({required this.members});
  final List<RankedMember> members;

  @override
  Widget build(BuildContext context) {
    final first = members.isNotEmpty ? members[0] : null;
    final second = members.length > 1 ? members[1] : null;
    final third = members.length > 2 ? members[2] : null;

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
          if (second != null)
            Expanded(child: _PodiumSlot(member: second, isFirst: false)),
          const SizedBox(width: MCSpacing.sm),
          if (first != null)
            Expanded(child: _PodiumSlot(member: first, isFirst: true)),
          const SizedBox(width: MCSpacing.sm),
          if (third != null)
            Expanded(child: _PodiumSlot(member: third, isFirst: false)),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar — amber ring for #1
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

        // Rank badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: member.rank == 1
                ? MCColors.amber
                : member.rank == 2
                    ? const Color(0xFFD4D4D4)
                    : const Color(0xFFCD7F32),
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

        // Score badge
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
        horizontal: MCSpacing.cardPadH,
        vertical: 10,
      ),
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
                Text(
                  member.fullName,
                  style: MCTypography.labelSm,
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.title != null && member.title!.isNotEmpty)
                  Text(
                    member.title!,
                    style: MCTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
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
              '${member.score}',
              style: MCTypography.labelSm.copyWith(color: MCColors.primaryMid),
            ),
          ),
        ],
      ),
    );
  }
}
