import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/growth/data/models/challenge_dto.dart';
import 'package:manager_connect/features/growth/presentation/providers/challenge_provider.dart';
import 'package:manager_connect/features/growth/presentation/screens/create_challenge_screen.dart';
import 'package:manager_connect/features/recognition/presentation/screens/recognition_feed_screen.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

class ChallengeListScreen extends ConsumerStatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  ConsumerState<ChallengeListScreen> createState() =>
      _ChallengeListScreenState();
}

class _ChallengeListScreenState extends ConsumerState<ChallengeListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(challengeListProvider.notifier).load();
    });
  }

  static const _typeLabels = {
    'fitness': 'Fitness',
    'wellness': 'Wellness',
  };

  static const _typeIcons = {
    'fitness': Icons.fitness_center,
    'wellness': Icons.spa,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline),
            tooltip: 'Recognition',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecognitionFeedScreen(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(state.showCompleted
                ? Icons.rocket_launch
                : Icons.history),
            tooltip:
                state.showCompleted ? 'Show active' : 'Show completed',
            onPressed: () =>
                ref.read(challengeListProvider.notifier).toggleCompleted(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChallenge(context),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ChallengeListState state) {
    if (state.isLoading && state.active.isEmpty && state.completed.isEmpty) {
      return const LoadingState(message: 'Loading challenges...');
    }

    if (state.error != null &&
        state.active.isEmpty &&
        state.completed.isEmpty) {
      return ErrorState(
        message: 'Failed to load challenges',
        onRetry: () => ref.read(challengeListProvider.notifier).load(),
      );
    }

    final challenges =
        state.showCompleted ? state.completed : state.active;

    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.showCompleted
                  ? Icons.emoji_events_outlined
                  : Icons.rocket_launch_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              state.showCompleted
                  ? 'No completed challenges'
                  : 'No active challenges',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.showCompleted
                  ? 'Completed challenges will appear here'
                  : 'Tap + to create one',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(challengeListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: challenges.length,
        itemBuilder: (context, index) =>
            _buildChallengeCard(challenges[index]),
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeDto challenge) {
    final theme = Theme.of(context);
    final typeLabel =
        _typeLabels[challenge.challengeType] ?? challenge.challengeType;
    final typeIcon =
        _typeIcons[challenge.challengeType] ?? Icons.emoji_events;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/challenge/${challenge.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(challenge.status, theme),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    avatar: Icon(typeIcon, size: 16),
                    label: Text(typeLabel,
                        style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      challenge.goalType.replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(challenge.startDate)} – ${_formatDate(challenge.endDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    final Color chipColor;
    final String label;

    switch (status) {
      case 'active':
        chipColor = theme.colorScheme.primary;
        label = 'Active';
      case 'ended':
        chipColor = theme.colorScheme.outline;
        label = 'Ended';
      case 'upcoming':
        chipColor = theme.colorScheme.tertiary;
        label = 'Upcoming';
      default:
        chipColor = theme.colorScheme.outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: chipColor),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _showCreateChallenge(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateChallengeScreen(),
    );
  }
}
