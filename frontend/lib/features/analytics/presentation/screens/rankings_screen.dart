import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(rankingsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rankingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rankings')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(RankingsState state) {
    if (state.isLoading &&
        state.monthlyRankings.isEmpty &&
        state.allTimeRankings.isEmpty) {
      return const LoadingState(message: 'Loading rankings...');
    }

    if (state.error != null &&
        state.monthlyRankings.isEmpty &&
        state.allTimeRankings.isEmpty) {
      return ErrorState(
        message: 'Failed to load rankings',
        onRetry: () => ref.read(rankingsProvider.notifier).load(),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.calendar_month, size: 18),
                label: Text('Monthly'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.all_inclusive, size: 18),
                label: Text('All-Time'),
              ),
            ],
            selected: {state.showAllTime},
            onSelectionChanged: (selected) =>
                ref.read(rankingsProvider.notifier).toggleView(),
          ),
        ),
        Expanded(
          child: state.showAllTime
              ? _buildAllTimeList(state)
              : _buildMonthlyList(state),
        ),
      ],
    );
  }

  Widget _buildMonthlyList(RankingsState state) {
    if (state.monthlyRankings.isEmpty) {
      return _buildEmptyState('No monthly rankings yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: state.monthlyRankings.length,
      itemBuilder: (context, index) {
        final member = state.monthlyRankings[index];
        return _buildRankTile(
          rank: index + 1,
          name: member.fullName ?? 'Unknown',
          score: member.compositeScore,
        );
      },
    );
  }

  Widget _buildAllTimeList(RankingsState state) {
    if (state.allTimeRankings.isEmpty) {
      return _buildEmptyState('No all-time rankings yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: state.allTimeRankings.length,
      itemBuilder: (context, index) {
        final ranking = state.allTimeRankings[index];
        return _buildRankTile(
          rank: index + 1,
          name: ranking.fullName ?? 'Unknown',
          score: ranking.totalScore,
        );
      },
    );
  }

  Widget _buildRankTile({
    required int rank,
    required String name,
    required double score,
  }) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final Color? rankColor;
    final IconData? trophyIcon;
    switch (rank) {
      case 1:
        rankColor = theme.colorScheme.primary;
        trophyIcon = Icons.emoji_events;
      case 2:
        rankColor = theme.colorScheme.tertiary;
        trophyIcon = Icons.emoji_events;
      case 3:
        rankColor = theme.colorScheme.secondary;
        trophyIcon = Icons.emoji_events;
      default:
        rankColor = theme.colorScheme.onSurfaceVariant;
        trophyIcon = null;
    }

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            child: trophyIcon != null
                ? Icon(trophyIcon, color: rankColor, size: 22)
                : Text(
                    '#$rank',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            child: Text(initial, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
      title: Text(
        name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Text(
        score.toStringAsFixed(1),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: rankColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
