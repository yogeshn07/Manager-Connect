import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/polls/data/models/poll_dto.dart';
import 'package:manager_connect/features/polls/presentation/providers/poll_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_badges.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class PollDetailScreen extends ConsumerStatefulWidget {
  const PollDetailScreen({required this.pollId, super.key});

  final String pollId;

  @override
  ConsumerState<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends ConsumerState<PollDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = _currentUserId;
      if (userId != null) {
        ref.read(pollDetailProvider(widget.pollId).notifier).load(userId);
      }
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
    final state = ref.watch(pollDetailProvider(widget.pollId));

    return Scaffold(
      backgroundColor: MCColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(child: _buildBody(state)),
        ],
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
        border: Border(
          bottom: BorderSide(color: MCColors.border, width: 1),
        ),
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
          Text('Poll', style: MCTypography.h3),
        ],
      ),
    );
  }

  Widget _buildBody(PollDetailState state) {
    if (state.isLoading) return const LoadingState();
    if (state.error != null || state.poll == null) {
      return ErrorState(
        message: 'Failed to load poll',
        onRetry: () {
          final userId = _currentUserId;
          if (userId != null) {
            ref.read(pollDetailProvider(widget.pollId).notifier).load(userId);
          }
        },
      );
    }

    final poll = state.poll!;
    final userId = _currentUserId;

    return RefreshIndicator(
      color: MCColors.violet,
      onRefresh: () async {
        if (userId != null) {
          await ref
              .read(pollDetailProvider(widget.pollId).notifier)
              .load(userId);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(MCSpacing.md),
        children: [
          _buildQuestionCard(poll),
          const SizedBox(height: MCSpacing.sm),
          ...poll.options.map(
            (option) => _buildOptionCard(
              option,
              poll,
              state.hasVoted,
              state.userVoteOptionId,
              userId,
            ),
          ),
          const SizedBox(height: MCSpacing.sm),
          _buildFooter(poll, userId),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(PollDto poll) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: MCColors.violet),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(MCSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poll.question, style: MCTypography.h2),
                    const SizedBox(height: MCSpacing.xs),
                    Row(
                      children: [
                        Text(
                          'Created ${DateFormat('MMM d, yyyy').format(poll.createdAt.toLocal())}',
                          style: MCTypography.caption,
                        ),
                        const Spacer(),
                        _buildClosesChip(poll),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosesChip(PollDto poll) {
    if (poll.isClosed) {
      return MCStatusPill.error('Poll Closed');
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MCLivePill(),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: MCColors.amberLight,
            borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
          ),
          child: Text(
            'Closes ${DateFormat('MMM d').format(poll.closesAt.toLocal())}',
            style: MCTypography.overline.copyWith(color: MCColors.amberDark),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    PollOptionDto option,
    PollDto poll,
    bool hasVoted,
    String? votedOptionId,
    String? userId,
  ) {
    final isMyVote = option.id == votedOptionId;
    final showResults = hasVoted || poll.isClosed;
    final percentage =
        poll.totalVotes > 0 ? option.voteCount / poll.totalVotes : 0.0;
    final maxVotes = poll.totalVotes > 0
        ? poll.options.map((o) => o.voteCount).reduce((a, b) => a > b ? a : b)
        : 0;
    final isLeading = showResults &&
        poll.totalVotes > 0 &&
        option.voteCount == maxVotes &&
        maxVotes > 0;
    final canVote = !hasVoted && !poll.isClosed && userId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: MCSpacing.xs),
      child: GestureDetector(
        onTap: canVote ? () => _vote(option.id, userId) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isMyVote ? MCColors.violetLight : MCColors.card,
            borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
            border: Border(
              left: BorderSide(
                color: isMyVote ? MCColors.violet : Colors.transparent,
                width: 3,
              ),
              top: const BorderSide(color: MCColors.border),
              right: const BorderSide(color: MCColors.border),
              bottom: const BorderSide(color: MCColors.border),
            ),
            boxShadow: MCColors.cardShadow,
          ),
          padding: const EdgeInsets.all(MCSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isMyVote) ...[
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: MCColors.violet),
                    const SizedBox(width: MCSpacing.xs2),
                  ],
                  Expanded(
                    child: Text(option.optionText, style: MCTypography.body),
                  ),
                  if (showResults) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: MCColors.violetLight,
                        borderRadius:
                            BorderRadius.circular(MCSpacing.radiusPill),
                      ),
                      child: Text(
                        '${option.voteCount}',
                        style: MCTypography.captionBold
                            .copyWith(color: MCColors.violet),
                      ),
                    ),
                  ],
                ],
              ),
              if (showResults) ...[
                const SizedBox(height: MCSpacing.xs),
                _buildProgressBar(percentage, isLeading),
                const SizedBox(height: MCSpacing.xs2),
                Text(
                  '${(percentage * 100).round()}%',
                  style: MCTypography.overline
                      .copyWith(color: MCColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double percentage, bool isLeading) {
    return LayoutBuilder(builder: (context, constraints) {
      final fillWidth = constraints.maxWidth * percentage;
      return Container(
        height: 8,
        width: double.infinity,
        decoration: BoxDecoration(
          color: MCColors.violetLight,
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: fillWidth.clamp(0.0, constraints.maxWidth),
            height: 8,
            decoration: BoxDecoration(
              color: MCColors.violet,
              borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
              boxShadow: isLeading
                  ? [
                      BoxShadow(
                        color: MCColors.violet.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFooter(PollDto poll, String? userId) {
    final isCreator = userId == poll.createdBy;
    return Row(
      children: [
        Text(
          '${poll.totalVotes} vote${poll.totalVotes == 1 ? '' : 's'} total',
          style: MCTypography.caption,
        ),
        const Spacer(),
        if (isCreator && !poll.isClosed)
          const MCGhostButton(
            label: 'Close Poll',
            icon: Icons.lock_outline,
          ),
      ],
    );
  }

  void _vote(String optionId, String userId) async {
    await ref
        .read(pollDetailProvider(widget.pollId).notifier)
        .vote(optionId: optionId, userId: userId);
    if (mounted) showSuccessToast(context, 'Vote recorded');
  }
}
