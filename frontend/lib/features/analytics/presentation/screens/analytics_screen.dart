import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = _currentUserId;
      if (userId != null) {
        ref.read(analyticsProvider.notifier).load(userId);
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
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/analytics/rankings'),
            icon: const Icon(Icons.leaderboard),
            label: const Text('Rankings'),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AnalyticsState state) {
    if (state.isLoading &&
        state.personalStats.isEmpty &&
        state.healthScores.isEmpty) {
      return const LoadingState(message: 'Loading analytics...');
    }

    if (state.error != null &&
        state.personalStats.isEmpty &&
        state.healthScores.isEmpty) {
      return ErrorState(
        message: 'Failed to load analytics',
        onRetry: () {
          final userId = _currentUserId;
          if (userId != null) {
            ref.read(analyticsProvider.notifier).load(userId);
          }
        },
      );
    }

    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.person, size: 18),
                label: Text('Personal'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.groups, size: 18),
                label: Text('Community'),
              ),
            ],
            selected: {state.showCommunity},
            onSelectionChanged: (selected) =>
                ref.read(analyticsProvider.notifier).toggleView(),
          ),
        ),
        Expanded(
          child: state.showCommunity
              ? _buildCommunityTab(state, theme)
              : _buildPersonalTab(state, theme),
        ),
      ],
    );
  }

  Widget _buildPersonalTab(AnalyticsState state, ThemeData theme) {
    if (state.personalStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No stats yet',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Participate in events and challenges to see your stats',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final latest = state.personalStats.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('This Month', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme: theme,
                icon: Icons.event,
                label: 'Events Attended',
                value: latest.eventsAttended.toString(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                theme: theme,
                icon: Icons.fitness_center,
                label: 'Challenges',
                value: latest.challengesJoined.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme: theme,
                icon: Icons.star,
                label: 'Recognitions',
                value: latest.recognitionsReceived.toString(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                theme: theme,
                icon: Icons.forum,
                label: 'Posts',
                value: latest.postsCount.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildStatCard(
          theme: theme,
          icon: Icons.emoji_events,
          label: 'Composite Score',
          value: latest.compositeScore.toStringAsFixed(1),
          wide: true,
        ),
      ],
    );
  }

  Widget _buildCommunityTab(AnalyticsState state, ThemeData theme) {
    final health = state.latestHealthScore;

    if (health == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No community data yet',
                style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Health score hero
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Community Health Score',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                  health.score.toStringAsFixed(0),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _scoreColor(health.score, theme),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'out of 100',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Engagement Breakdown', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildMetricTile(
          theme: theme,
          icon: Icons.event,
          label: 'Avg Attendance Rate',
          value: '${(health.avgAttendanceRate * 100).toStringAsFixed(0)}%',
        ),
        _buildMetricTile(
          theme: theme,
          icon: Icons.fitness_center,
          label: 'Challenge Engagement',
          value:
              '${(health.challengeEngagementRate * 100).toStringAsFixed(0)}%',
        ),
        _buildMetricTile(
          theme: theme,
          icon: Icons.star,
          label: 'Recognition Activity',
          value:
              '${(health.recognitionActivityRate * 100).toStringAsFixed(0)}%',
        ),
        _buildMetricTile(
          theme: theme,
          icon: Icons.people,
          label: 'Participation Rate',
          value:
              '${(health.participationRate * 100).toStringAsFixed(0)}%',
        ),
        const Divider(height: 32),
        _buildMetricTile(
          theme: theme,
          icon: Icons.groups,
          label: 'Active Members',
          value: health.activeMemberCount.toString(),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    bool wide = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      trailing: Text(
        value,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _scoreColor(double score, ThemeData theme) {
    if (score >= 75) return theme.colorScheme.primary;
    if (score >= 50) return theme.colorScheme.tertiary;
    return theme.colorScheme.error;
  }
}
