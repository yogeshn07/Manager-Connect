import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/features/growth/data/models/challenge_dto.dart';
import 'package:manager_connect/features/growth/presentation/providers/challenge_provider.dart';
import 'package:manager_connect/features/recognition/data/repositories/recognition_repository.dart';
import 'package:manager_connect/features/recognition/presentation/providers/recognition_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_badges.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  const ChallengeDetailScreen({required this.challengeId, super.key});

  final String challengeId;

  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState
    extends ConsumerState<ChallengeDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(challengeDetailProvider(widget.challengeId).notifier).load();
    });
  }

  String? get _currentUserId {
    final authState = ref.read(authProvider);
    if (authState is AppAuthStateAuthenticated) {
      return authState.session.userId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeDetailProvider(widget.challengeId));

    return Scaffold(
      backgroundColor: MCColors.background,
      body: MCAmbientIdentityBackground(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: MCColors.card,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: MCSpacing.md,
        right: MCSpacing.md,
        bottom: MCSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MCColors.border, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MCColors.primaryPale,
                borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: MCColors.primary,
              ),
            ),
          ),
          const SizedBox(width: MCSpacing.sm),
          Text('Challenge', style: MCTypography.h3),
        ],
      ),
    );
  }

  Widget _buildBody(ChallengeDetailState state) {
    if (state.isLoading) return const LoadingState();
    if (state.error != null || state.challenge == null) {
      return ErrorState(
        message: 'Failed to load challenge',
        onRetry: () =>
            ref.read(challengeDetailProvider(widget.challengeId).notifier).load(),
      );
    }

    final challenge = state.challenge!;
    final userId = _currentUserId;
    final isParticipant = state.participants.any((p) => p.userId == userId);
    final myParticipant =
        state.participants.where((p) => p.userId == userId).toList();

    return RefreshIndicator(
      color: MCColors.primaryMid,
      onRefresh: () =>
          ref.read(challengeDetailProvider(widget.challengeId).notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(MCSpacing.md),
        children: [
          _buildHeroCard(challenge, state.participants.length),
          const SizedBox(height: MCSpacing.sm),

          // ── Sub-tasks / goal section ────────────────────────────────────
          if (challenge.selectedTasks.isNotEmpty && userId != null)
            _buildTasksCard(state, userId)
          else
            _buildLegacyDetailsCard(challenge, state.participants.length),
          const SizedBox(height: MCSpacing.sm),

          // ── Join / Leave ────────────────────────────────────────────────
          if (userId != null && !challenge.isEnded)
            _buildJoinLeaveButton(isParticipant: isParticipant, userId: userId),

          // ── Log Progress ────────────────────────────────────────────────
          if (isParticipant && !challenge.isEnded && myParticipant.isNotEmpty) ...[
            const SizedBox(height: MCSpacing.xs),
            MCGhostButton(
              label: 'Log Progress',
              icon: Icons.add_chart_outlined,
              onPressed: () => _showLogProgress(
                userId!,
                myParticipant.first.id,
                challenge,
              ),
            ),
          ],
          const SizedBox(height: MCSpacing.md),

          // ── Participants ────────────────────────────────────────────────
          _buildParticipantsSection(state.participants),

          // ── Progress board ───────────────────────────────────────────────
          if (state.progressLogs.isNotEmpty) ...[
            const SizedBox(height: MCSpacing.md),
            _buildLeaderboardSection(state),
          ],
        ],
      ),
    );
  }

  // ── Hero card ──────────────────────────────────────────────────────────────

  Widget _buildHeroCard(ChallengeDto challenge, int participantCount) {
    final statusInfo = _statusInfo(challenge.status);

    return Container(
      padding: const EdgeInsets.all(MCSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E4585), Color(0xFF1A3A6B)],
        ),
        borderRadius: BorderRadius.circular(MCSpacing.radiusLg),
        boxShadow: MCColors.primaryButtonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
                ),
                child: Icon(
                  _challengeTypeIcon(challenge.challengeType),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: MCSpacing.sm),
              Expanded(
                child: Text(
                  challenge.challengeType.replaceAll('_', ' ').toUpperCase(),
                  style: MCTypography.overline
                      .copyWith(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
              MCStatusPill(
                label: statusInfo.$1,
                color: statusInfo.$2,
                bgColor: statusInfo.$3,
              ),
            ],
          ),
          const SizedBox(height: MCSpacing.sm),
          Text(challenge.title, style: MCTypography.h2White),
          if (challenge.description != null) ...[
            const SizedBox(height: 4),
            Text(
              challenge.description!,
              style: MCTypography.bodySm
                  .copyWith(color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
          const SizedBox(height: MCSpacing.sm),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: MCSpacing.xs2),
              Text(
                '${_formatDate(challenge.startDate)} – ${_formatDate(challenge.endDate)}',
                style: MCTypography.bodySm
                    .copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(width: MCSpacing.md),
              Icon(Icons.people_outline,
                  size: 14, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: MCSpacing.xs2),
              Text(
                '$participantCount participant${participantCount == 1 ? '' : 's'}',
                style: MCTypography.bodySm
                    .copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tasks progress card ────────────────────────────────────────────────────

  Widget _buildTasksCard(ChallengeDetailState state, String userId) {
    final tasks = state.challenge!.selectedTasks;
    final progress = state.subtaskProgress(userId);
    final achieved = state.achievedSubtasks(userId);
    final achievedCount = achieved.length;

    return Container(
      padding: const EdgeInsets.all(MCSpacing.md),
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_outlined,
                  size: 18, color: MCColors.primaryMid),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Tasks Progress', style: MCTypography.h4),
              ),
              if (achievedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MCColors.successBg,
                    borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                  ),
                  child: Text(
                    '$achievedCount / ${tasks.length} Done',
                    style: MCTypography.overline
                        .copyWith(color: MCColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MCSpacing.sm),
          ...tasks.map((task) {
            final current = progress[task.id] ?? 0;
            final ratio = (current / task.target).clamp(0.0, 1.0);
            final isAchieved = achieved.contains(task.id);
            return Padding(
              padding: const EdgeInsets.only(top: MCSpacing.sm),
              child: _buildTaskTile(task, current, ratio, isAchieved),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaskTile(
    ChallengeTask task,
    double current,
    double ratio,
    bool achieved,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                task.label,
                style: MCTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: achieved ? MCColors.textMuted : MCColors.textPrimary,
                  decoration:
                      achieved ? TextDecoration.lineThrough : null,
                  decorationColor: MCColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (achieved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MCColors.successBg,
                  borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 12, color: MCColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Achieved',
                      style: MCTypography.overline
                          .copyWith(color: MCColors.success),
                    ),
                  ],
                ),
              )
            else
              Text(
                '${_fmtVal(current)} / ${_fmtVal(task.target)} ${task.unit}',
                style: MCTypography.caption
                    .copyWith(color: MCColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: MCColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              achieved ? MCColors.success : MCColors.primaryMid,
            ),
          ),
        ),
      ],
    );
  }

  // ── Legacy details card (for challenges without selected_tasks) ────────────

  Widget _buildLegacyDetailsCard(ChallengeDto challenge, int participantCount) {
    return Container(
      padding: const EdgeInsets.all(MCSpacing.md),
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MCColors.primaryPale,
              borderRadius:
                  BorderRadius.circular(MCSpacing.radiusPill),
            ),
            child: Text(
              'Goal: ${challenge.goalType.replaceAll('_', ' ')}',
              style: MCTypography.overline
                  .copyWith(color: MCColors.primaryMid),
            ),
          ),
          if (challenge.goalDescription != null) ...[
            const SizedBox(height: MCSpacing.sm),
            Text(challenge.goalDescription!, style: MCTypography.bodySm),
          ],
          if (challenge.description != null) ...[
            const SizedBox(height: MCSpacing.sm),
            Text(challenge.description!, style: MCTypography.body),
          ],
          const SizedBox(height: MCSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: (participantCount / 50).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: MCColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(MCColors.primaryMid),
            ),
          ),
          const SizedBox(height: MCSpacing.xs2),
          Text(
            '$participantCount participant${participantCount == 1 ? '' : 's'} joined',
            style: MCTypography.caption,
          ),
        ],
      ),
    );
  }

  // ── Join / Leave ───────────────────────────────────────────────────────────

  Widget _buildJoinLeaveButton({
    required bool isParticipant,
    required String userId,
  }) {
    if (isParticipant) {
      return MCGhostButton(
        label: 'Leave Challenge',
        icon: Icons.exit_to_app_outlined,
        onPressed: () => _leave(userId),
      );
    }
    return MCPrimaryButton(
      label: 'Join Challenge',
      icon: Icons.add,
      onPressed: () => _join(userId),
    );
  }

  // ── Participants ───────────────────────────────────────────────────────────

  Widget _buildParticipantsSection(List<ParticipantDto> participants) {
    if (participants.isEmpty) return const SizedBox.shrink();

    final avatarColors = [
      MCColors.primaryMid,
      MCColors.violet,
      MCColors.success,
      MCColors.amberDark,
      MCColors.primaryLight,
    ];
    final initials = participants.take(5).map((p) {
      final name = p.fullName ?? 'U';
      return name.isNotEmpty ? name[0].toUpperCase() : 'U';
    }).toList();
    final colors = List.generate(
        initials.length, (i) => avatarColors[i % avatarColors.length]);

    return Container(
      padding: const EdgeInsets.all(MCSpacing.md),
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Participants', style: MCTypography.h4),
          const SizedBox(height: MCSpacing.sm),
          Row(
            children: [
              if (initials.isNotEmpty)
                MCAvatarStack(
                  initialsList: initials,
                  colors: colors,
                  size: 32,
                  overlap: 8,
                ),
              const SizedBox(width: MCSpacing.sm),
              Text(
                participants.length > 5
                    ? '+${participants.length - 5} more'
                    : '${participants.length} joined',
                style: MCTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress board ─────────────────────────────────────────────────────────

  Widget _buildLeaderboardSection(ChallengeDetailState state) {
    final board = state.dailyProgressBoard;
    final unit = state.challenge?.selectedTasks.isNotEmpty == true
        ? state.challenge!.selectedTasks.first.unit
        : '';

    return Container(
      padding: const EdgeInsets.all(MCSpacing.md),
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_outlined,
                  size: 18, color: MCColors.primaryMid),
              const SizedBox(width: 6),
              Text('Progress Board', style: MCTypography.h4),
            ],
          ),
          const SizedBox(height: MCSpacing.sm),
          ...board.map(
            (entry) => _buildDailyLogTile(
              userId: entry.userId,
              logDate: entry.logDate,
              dayValue: entry.dayValue,
              unit: unit,
              participants: state.participants,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLogTile({
    required String userId,
    required String logDate,
    required double dayValue,
    required String unit,
    required List<ParticipantDto> participants,
  }) {
    final participant = participants.where((p) => p.userId == userId).toList();
    final name = participant.isNotEmpty
        ? (participant.first.fullName ?? 'Unknown')
        : 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final participantAvatarUrl =
        participant.isNotEmpty ? participant.first.avatarUrl : null;
    String formattedDate;
    try {
      formattedDate = DateFormat('MMM d').format(DateTime.parse(logDate));
    } catch (_) {
      formattedDate = logDate;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: MCSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              formattedDate,
              style: MCTypography.caption
                  .copyWith(color: MCColors.textSecondary),
            ),
          ),
          const SizedBox(width: MCSpacing.xs),
          MCAvatar(
            initials: initial,
            size: MCAvatar.sm,
            backgroundColor: MCColors.primaryMid,
            avatarUrl: participantAvatarUrl,
          ),
          const SizedBox(width: MCSpacing.xs),
          Expanded(child: Text(name, style: MCTypography.body)),
          Text(
            '${_fmtVal(dayValue)}${unit.isNotEmpty ? ' $unit' : ''}',
            style: MCTypography.captionBold
                .copyWith(color: MCColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // ── Log Progress sheet ─────────────────────────────────────────────────────

  void _showLogProgress(
    String userId,
    String participantId,
    ChallengeDto challenge,
  ) {
    final tasks = challenge.selectedTasks;
    final commonUnit = tasks.isNotEmpty ? tasks.first.unit : '';
    final valueController = TextEditingController();
    var selectedDate = DateTime.now();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Log Progress', style: MCTypography.h3),
                if (tasks.length > 1) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Your entry counts towards all ${tasks.length} tasks',
                    style: MCTypography.caption
                        .copyWith(color: MCColors.primaryMid),
                  ),
                ],
                const SizedBox(height: MCSpacing.md),

                // ── Date picker ───────────────────────────────────────────
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                      DateFormat('EEEE, MMMM d').format(selectedDate)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setSS(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: MCSpacing.sm),

                // ── Value input ───────────────────────────────────────────
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: commonUnit.isNotEmpty
                        ? 'Progress ($commonUnit)'
                        : 'Value',
                    hintText: commonUnit.isNotEmpty
                        ? 'Enter $commonUnit completed today'
                        : 'Enter value',
                    border: const OutlineInputBorder(),
                    suffixText: commonUnit.isNotEmpty ? commonUnit : null,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: MCSpacing.md),

                // ── Submit ────────────────────────────────────────────────
                FilledButton(
                  onPressed: () async {
                    final value =
                        double.tryParse(valueController.text.trim());
                    if (value == null || value <= 0) {
                      showErrorToast(ctx, 'Enter a valid value');
                      return;
                    }
                    Navigator.of(ctx).pop();

                    // Capture pre-log achievement state
                    final prevAchieved = ref
                        .read(challengeDetailProvider(widget.challengeId))
                        .achievedSubtasks(userId);

                    final logDate =
                        DateFormat('yyyy-MM-dd').format(selectedDate);
                    final notifier = ref.read(
                        challengeDetailProvider(widget.challengeId).notifier);

                    // Log to ALL tasks — same value counts for every task
                    if (tasks.isNotEmpty) {
                      for (final task in tasks) {
                        await notifier.logProgress(
                          userId: userId,
                          participantId: participantId,
                          logDate: logDate,
                          value: value,
                          subtaskId: task.id,
                        );
                      }
                    } else {
                      await notifier.logProgress(
                        userId: userId,
                        participantId: participantId,
                        logDate: logDate,
                        value: value,
                        subtaskId: '',
                      );
                    }

                    if (mounted) showSuccessToast(context, 'Progress logged!');

                    // Check for newly achieved tasks → auto-recognition + dialog
                    if (tasks.isNotEmpty && mounted) {
                      final newAchieved = ref
                          .read(challengeDetailProvider(widget.challengeId))
                          .achievedSubtasks(userId);
                      final allDone = newAchieved.length >= tasks.length;
                      final wasntAllDone = prevAchieved.length < tasks.length;
                      if (allDone && wasntAllDone) {
                        await _createCompletionRecognition(userId, challenge);
                        // Move challenge to Completed tab immediately
                        await ref.read(challengeListProvider.notifier).refreshProgress();
                        if (mounted) _showAchievementDialog(userId, challenge);
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
                const SizedBox(height: MCSpacing.xs),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAchievementDialog(String userId, ChallengeDto challenge) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 Challenge Complete!'),
        content: Text(
          'You\'ve achieved all tasks in "${challenge.title}"!\n\n'
          'A recognition has been added to the Recognition tab. '
          'Would you also like to share it to the main feed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _postAchievementToFeed(challenge);
            },
            child: const Text('Post to Feed'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCompletionRecognition(
    String userId,
    ChallengeDto challenge,
  ) async {
    try {
      final categoryTag = switch (challenge.challengeType) {
        'fitness'   => 'fitness_champion',
        'wellness'  => 'wellness_champion',
        'learning'  => 'community_contributor',
        'community' => 'community_contributor',
        _           => 'community_contributor',
      };
      final taskLabels = challenge.selectedTasks.map((t) => t.label).join(', ');
      final message = 'Completed the "${challenge.title}" challenge! '
          'All tasks achieved: $taskLabels 🏆';

      final client = ref.read(supabaseClientProvider);
      await RecognitionRepository(client).createRecognition(
        recipientIds: [userId],
        categoryTag:  categoryTag,
        message:      message,
      );
      await ref.read(recognitionFeedProvider.notifier).refresh();
    } catch (_) {
      // Non-blocking — feed post still proceeds
    }
  }

  Future<void> _postAchievementToFeed(ChallengeDto challenge) async {
    try {
      final taskLines = challenge.selectedTasks
          .map((t) => '✅ ${t.label}')
          .join('\n');
      final content =
          '🏆 Challenge Complete!\n\nI just finished all tasks in the '
          '"${challenge.title}" challenge! 💪\n\n$taskLines';
      final client = ref.read(supabaseClientProvider);
      await FeedRepository(client).createPost(content: content);
      await ref.read(feedProvider.notifier).refresh();
      if (mounted) showSuccessToast(context, '🎉 Achievement posted to feed!');
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to post achievement');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmtVal(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _formatDate(String dateStr) {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  (String, Color, Color) _statusInfo(String status) {
    return switch (status) {
      'active' => ('Active', MCColors.success, MCColors.successBg),
      'ended'  => ('Ended', MCColors.textMuted, MCColors.borderLight),
      _        => ('Upcoming', MCColors.amberDark, MCColors.amberLight),
    };
  }

  IconData _challengeTypeIcon(String type) {
    return switch (type) {
      'fitness'  => Icons.fitness_center,
      'wellness' => Icons.spa,
      'learning' => Icons.menu_book,
      'community'=> Icons.groups,
      _          => Icons.emoji_events,
    };
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _join(String userId) async {
    await ref
        .read(challengeDetailProvider(widget.challengeId).notifier)
        .join(userId);
    if (mounted) showSuccessToast(context, 'Joined challenge');
  }

  Future<void> _leave(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Challenge'),
        content:
            const Text('Your progress will be removed. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(challengeDetailProvider(widget.challengeId).notifier)
        .leave(userId);
    if (mounted) showSuccessToast(context, 'Left challenge');
  }
}
