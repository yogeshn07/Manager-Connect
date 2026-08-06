import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/features/growth/data/models/challenge_dto.dart';
import 'package:manager_connect/features/growth/presentation/providers/challenge_provider.dart';
import 'package:manager_connect/features/recognition/presentation/screens/recognition_feed_screen.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class ChallengeAchievementsScreen extends ConsumerStatefulWidget {
  const ChallengeAchievementsScreen({super.key});

  @override
  ConsumerState<ChallengeAchievementsScreen> createState() =>
      _ChallengeAchievementsScreenState();
}

class _ChallengeAchievementsScreenState
    extends ConsumerState<ChallengeAchievementsScreen> {
  final Set<String> _posting = {};

  String? get _userId {
    final auth = ref.read(authProvider);
    return auth is AppAuthStateAuthenticated ? auth.session.userId : null;
  }

  Future<void> _postToFeed(ChallengeDto challenge) async {
    final userId = _userId;
    if (userId == null) return;
    setState(() => _posting.add(challenge.id));
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = FeedRepository(client);

      final taskLabels = challenge.selectedTasks.map((t) => t.label).join(', ');
      final content = taskLabels.isNotEmpty
          ? '🏆 I just completed the "${challenge.title}" challenge!\n\n'
                'Tasks I crushed: $taskLabels 💪\n\n'
                'Drop a 👏 to celebrate! #growth #challenge #achievement'
          : '🏆 I just completed the "${challenge.title}" challenge on Manager Connect!\n\n'
                'Drop a 👏 to celebrate! #growth #achievement';

      await repo.createPost(content: content);
      if (mounted) showSuccessToast(context, 'Achievement posted to feed!');
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to post — try again');
    } finally {
      if (mounted) setState(() => _posting.remove(challenge.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeListProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: state.isLoading && state.completed.isEmpty
                  ? const LoadingState()
                  : state.completed.isEmpty
                  ? _buildEmptyState()
                  : _buildList(state.completed),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: MCColors.card,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top > 0 ? 0 : 8,
        bottom: 10,
        left: 4,
        right: 8,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MCColors.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: MCColors.primary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(child: Text('Achievements 🏆', style: MCTypography.h3)),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecognitionFeedScreen(),
              ),
            ),
            icon: const Icon(Icons.people_outline, size: 15),
            label: const Text('Team Kudos'),
            style: TextButton.styleFrom(
              foregroundColor: MCColors.textSecondary,
              textStyle: MCTypography.caption,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 56,
              color: MCColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text('No completed challenges yet', style: MCTypography.h4),
            const SizedBox(height: 8),
            Text(
              "Challenges that have ended will appear here.\nKeep going — you've got this!",
              style: MCTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Challenges'),
            ),
          ],
        ),
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList(List<ChallengeDto> completed) {
    return RefreshIndicator(
      onRefresh: () => ref.read(challengeListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          MCSpacing.pageH,
          MCSpacing.sm,
          MCSpacing.pageH,
          MCSpacing.xl,
        ),
        itemCount: completed.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(
            bottom: index < completed.length - 1 ? MCSpacing.sm : 0,
          ),
          child: _buildAchievementCard(completed[index]),
        ),
      ),
    );
  }

  // ── Achievement card ───────────────────────────────────────────────────────

  Widget _buildAchievementCard(ChallengeDto challenge) {
    final isPosting = _posting.contains(challenge.id);
    final isWellness = challenge.challengeType == 'wellness';

    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top gradient accent strip ────────────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWellness
                    ? const [Color(0xFF059669), Color(0xFF10B981)]
                    : const [Color(0xFF1E4585), Color(0xFF2563EB)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(MCSpacing.cardPadH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ───────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isWellness
                            ? MCColors.successBg
                            : MCColors.primaryPale,
                        borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
                      ),
                      child: Icon(
                        isWellness ? Icons.spa : Icons.fitness_center,
                        size: 20,
                        color: isWellness
                            ? MCColors.success
                            : MCColors.primaryMid,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(challenge.title, style: MCTypography.h4),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _chip(
                                challenge.challengeType == 'fitness'
                                    ? 'Fitness'
                                    : 'Wellness',
                              ),
                              const SizedBox(width: 4),
                              _chip(
                                _toTitleCase(
                                  challenge.goalType.replaceAll('_', ' '),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: MCColors.amberLight,
                        borderRadius: BorderRadius.circular(
                          MCSpacing.radiusPill,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 12,
                            color: MCColors.amberDark,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: MCColors.amberDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MCSpacing.sm),

                // ── Date range ────────────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.date_range_outlined,
                      size: 13,
                      color: MCColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmt(challenge.startDate)} – ${_fmt(challenge.endDate)}',
                      style: MCTypography.caption,
                    ),
                  ],
                ),

                // ── Task list ─────────────────────────────────────────
                if (challenge.selectedTasks.isNotEmpty) ...[
                  const SizedBox(height: MCSpacing.sm),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: challenge.selectedTasks
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: MCColors.successBg,
                              borderRadius: BorderRadius.circular(
                                MCSpacing.radiusPill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 11,
                                  color: MCColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  t.label,
                                  style: MCTypography.overline.copyWith(
                                    color: MCColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: MCSpacing.md),

                // ── Action row ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/growth/challenge/${challenge.id}'),
                        icon: const Icon(Icons.bar_chart_outlined, size: 15),
                        label: const Text('View Progress'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MCColors.primaryMid,
                          side: const BorderSide(color: MCColors.primaryMid),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: MCTypography.labelSm,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isPosting
                            ? null
                            : () => _postToFeed(challenge),
                        icon: isPosting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.ios_share_outlined, size: 15),
                        label: Text(isPosting ? 'Posting...' : 'Post to Feed'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isWellness
                              ? MCColors.success
                              : MCColors.primaryMid,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: MCTypography.labelSm,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: MCColors.background,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(label, style: MCTypography.overline),
    );
  }

  String _fmt(String dateStr) {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  String _toTitleCase(String raw) => raw
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
