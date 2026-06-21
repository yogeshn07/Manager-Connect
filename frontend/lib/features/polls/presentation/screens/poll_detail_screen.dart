import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/polls/data/models/poll_dto.dart';
import 'package:manager_connect/features/polls/presentation/providers/poll_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
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
      appBar: AppBar(title: const Text('Poll')),
      body: _buildBody(state),
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
    final theme = Theme.of(context);
    final userId = _currentUserId;

    return RefreshIndicator(
      onRefresh: () async {
        if (userId != null) {
          await ref
              .read(pollDetailProvider(widget.pollId).notifier)
              .load(userId);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(poll.question, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                poll.isClosed ? Icons.lock : Icons.schedule,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                poll.isClosed
                    ? 'Closed'
                    : 'Closes ${DateFormat('MMM d, h:mm a').format(poll.closesAt.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${poll.totalVotes} vote${poll.totalVotes == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...poll.options.map((option) => _buildOption(
                option,
                poll,
                state.hasVoted,
                state.userVoteOptionId,
                userId,
              )),
        ],
      ),
    );
  }

  Widget _buildOption(
    PollOptionDto option,
    PollDto poll,
    bool hasVoted,
    String? votedOptionId,
    String? userId,
  ) {
    final theme = Theme.of(context);
    final showResults = hasVoted || poll.isClosed;
    final isMyVote = option.id == votedOptionId;
    final percentage =
        poll.totalVotes > 0 ? option.voteCount / poll.totalVotes : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        color: isMyVote
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: (!hasVoted && !poll.isClosed && userId != null)
              ? () => _vote(option.id, userId)
              : null,
          child: Stack(
            children: [
              if (showResults)
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    if (isMyVote)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_circle,
                            size: 18, color: theme.colorScheme.primary),
                      ),
                    Expanded(
                      child: Text(option.optionText,
                          style: theme.textTheme.bodyLarge),
                    ),
                    if (showResults)
                      Text(
                        '${(percentage * 100).round()}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _vote(String optionId, String userId) async {
    await ref
        .read(pollDetailProvider(widget.pollId).notifier)
        .vote(optionId: optionId, userId: userId);
    if (mounted) showSuccessToast(context, 'Vote recorded');
  }
}
