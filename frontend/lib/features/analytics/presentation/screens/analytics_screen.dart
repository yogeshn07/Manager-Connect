import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class PersonalStats {
  const PersonalStats({
    this.eventsAttended = 0,
    this.challengesCompleted = 0,
    this.recognitionsReceived = 0,
    this.postsPublished = 0,
    this.compositeScore = 0,
  });

  final int eventsAttended;
  final int challengesCompleted;
  final int recognitionsReceived;
  final int postsPublished;
  final int compositeScore;
}

class CommunityHealth {
  const CommunityHealth({
    this.healthScore = 0,
    this.totalMembers = 0,
    this.activeThisMonth = 0,
    this.eventsThisMonth = 0,
    this.postsThisMonth = 0,
    this.recognitionsThisMonth = 0,
  });

  final int healthScore;
  final int totalMembers;
  final int activeThisMonth;
  final int eventsThisMonth;
  final int postsThisMonth;
  final int recognitionsThisMonth;
}

class AnalyticsData {
  const AnalyticsData({
    required this.personal,
    required this.community,
  });

  final PersonalStats personal;
  final CommunityHealth community;
}

// ── Provider ──────────────────────────────────────────────────────────────────

final analyticsDataProvider =
    FutureProvider.autoDispose<AnalyticsData>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    return const AnalyticsData(
      personal: PersonalStats(),
      community: CommunityHealth(),
    );
  }

  try {
    final userId = session.user.id;
    final now = DateTime.now();
    final firstOfMonth =
        DateTime(now.year, now.month, 1).toUtc().toIso8601String();

    final results = await Future.wait([
      // Personal stats (fixed table names)
      client
          .from('activity_rsvps')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'going')
          .count(),
      client
          .from('challenge_participants')
          .select('id')
          .eq('user_id', userId)
          .count(),
      client
          .from('recognition_recipients')
          .select('recognition_id')
          .eq('recipient_id', userId)
          .count(),
      client
          .from('posts')
          .select('id')
          .eq('author_id', userId)
          .eq('is_deleted', false)
          .count(),
      // Community stats (live queries replacing hardcoded values)
      client
          .from('profiles')
          .select('id')
          .eq('is_active', true)
          .eq('is_system_account', false)
          .count(),
      client
          .from('profiles')
          .select('id')
          .eq('is_active', true)
          .eq('is_system_account', false)
          .gte('last_active_at', firstOfMonth)
          .count(),
      client
          .from('activities')
          .select('id')
          .gte('created_at', firstOfMonth)
          .count(),
      client
          .from('posts')
          .select('id')
          .eq('is_deleted', false)
          .gte('created_at', firstOfMonth)
          .count(),
      client
          .from('recognitions')
          .select('id')
          .eq('is_deleted', false)
          .gte('created_at', firstOfMonth)
          .count(),
    ]);

    final events = results[0].count;
    final challenges = results[1].count;
    final recognitions = results[2].count;
    final posts = results[3].count;
    final totalMembers = results[4].count;
    final activeThisMonth = results[5].count;
    final eventsThisMonth = results[6].count;
    final postsThisMonth = results[7].count;
    final recognitionsThisMonth = results[8].count;

    final composite =
        (events * 10 + challenges * 20 + recognitions * 15 + posts * 5)
            .clamp(0, 999);

    // Health score: weighted formula based on real community activity
    final activeRatio =
        totalMembers > 0 ? activeThisMonth / totalMembers : 0.0;
    final healthScore = ((activeRatio * 40.0) +
            (eventsThisMonth.clamp(0, 5) / 5.0 * 20.0) +
            (postsThisMonth.clamp(0, 20) / 20.0 * 25.0) +
            (recognitionsThisMonth.clamp(0, 10) / 10.0 * 15.0))
        .round()
        .clamp(0, 100);

    return AnalyticsData(
      personal: PersonalStats(
        eventsAttended: events,
        challengesCompleted: challenges,
        recognitionsReceived: recognitions,
        postsPublished: posts,
        compositeScore: composite,
      ),
      community: CommunityHealth(
        healthScore: healthScore,
        totalMembers: totalMembers,
        activeThisMonth: activeThisMonth,
        eventsThisMonth: eventsThisMonth,
        postsThisMonth: postsThisMonth,
        recognitionsThisMonth: recognitionsThisMonth,
      ),
    );
  } catch (_) {
    return const AnalyticsData(
      personal: PersonalStats(),
      community: CommunityHealth(),
    );
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedTab = 0;

  void toggleView(int index) => setState(() => _selectedTab = index);

  void load() => ref.invalidate(analyticsDataProvider);

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(analyticsDataProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: MCAmbientIdentityBackground(
        child: SafeArea(
          child: Column(
            children: [
            Container(
              height: MCSpacing.topBarHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: MCSpacing.pageH,
                vertical: 8,
              ),
              decoration: const BoxDecoration(
                color: MCColors.card,
                border: Border(
                  bottom: BorderSide(color: MCColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Analytics', style: MCTypography.h3)),
                  GestureDetector(
                    onTap: () => context.push('/analytics/rankings'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: MCColors.primaryPale,
                        borderRadius:
                            BorderRadius.circular(MCSpacing.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.leaderboard_outlined,
                            size: 14,
                            color: MCColors.primaryMid,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Rankings',
                            style: MCTypography.labelSm
                                .copyWith(color: MCColors.primaryMid),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MCSpacing.pageH,
                MCSpacing.md,
                MCSpacing.pageH,
                MCSpacing.xs,
              ),
              child: _SegmentedControl(
                selected: _selectedTab,
                onTap: toggleView,
              ),
            ),
            Expanded(
              child: dataAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MCColors.primaryMid),
                  ),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load analytics',
                        style: MCTypography.body.copyWith(
                          color: MCColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: MCSpacing.sm),
                      GestureDetector(
                        onTap: load,
                        child: Text(
                          'Retry',
                          style: MCTypography.label
                              .copyWith(color: MCColors.primaryMid),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (data) => RefreshIndicator(
                  onRefresh: () async => load(),
                  color: MCColors.primaryMid,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(MCSpacing.pageH),
                    child: _selectedTab == 0
                        ? _PersonalTab(stats: data.personal)
                        : _CommunityTab(health: data.community),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Segmented control ─────────────────────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.selected, required this.onTap});

  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MCColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MCColors.border),
      ),
      child: Row(
        children: [
          _Segment(label: 'Personal', active: selected == 0, onTap: () => onTap(0)),
          _Segment(label: 'Network', active: selected == 1, onTap: () => onTap(1)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          decoration: BoxDecoration(
            color: active ? MCColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    const BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: MCTypography.labelSm.copyWith(
                color: active ? MCColors.textPrimary : MCColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Personal tab ──────────────────────────────────────────────────────────────

class _PersonalTab extends StatelessWidget {
  const _PersonalTab({required this.stats});
  final PersonalStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.event_available_outlined,
                iconColor: MCColors.primaryLight,
                iconBg: MCColors.primaryPale,
                value: '${stats.eventsAttended}',
                label: 'Events',
              ),
            ),
            const SizedBox(width: MCSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: Icons.fitness_center_outlined,
                iconColor: MCColors.violet,
                iconBg: MCColors.violetLight,
                value: '${stats.challengesCompleted}',
                label: 'Challenges',
              ),
            ),
          ],
        ),
        const SizedBox(height: MCSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_outlined,
                iconColor: MCColors.amberDark,
                iconBg: MCColors.amberLight,
                value: '${stats.recognitionsReceived}',
                label: 'Recognitions',
              ),
            ),
            const SizedBox(width: MCSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: Icons.article_outlined,
                iconColor: MCColors.success,
                iconBg: MCColors.successBg,
                value: '${stats.postsPublished}',
                label: 'Posts',
              ),
            ),
          ],
        ),
        const SizedBox(height: MCSpacing.sm),
        _CompositeScoreCard(score: stats.compositeScore),
        const SizedBox(height: MCSpacing.md),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: MCSpacing.sm),
          Text(value, style: MCTypography.kpi),
          const SizedBox(height: 2),
          Text(label, style: MCTypography.caption),
        ],
      ),
    );
  }
}

class _CompositeScoreCard extends StatelessWidget {
  const _CompositeScoreCard({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
        color: MCColors.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MCSpacing.cardPadH,
              vertical: MCSpacing.sm,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E4585), Color(0xFF0F2D5E)],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_outlined, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  'Composite Score',
                  style: MCTypography.labelSm.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MCSpacing.cardPadH),
            child: Row(
              children: [
                Text('$score', style: MCTypography.kpi.copyWith(fontSize: 32)),
                const SizedBox(width: MCSpacing.sm),
                Expanded(
                  child: Text(
                    'points earned across\nevents, challenges & more',
                    style: MCTypography.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Community tab ─────────────────────────────────────────────────────────────

class _CommunityTab extends StatelessWidget {
  const _CommunityTab({required this.health});
  final CommunityHealth health;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HealthScoreHero(score: health.healthScore),
        const SizedBox(height: MCSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: MCColors.card,
            borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
            border: Border.all(color: MCColors.border),
            boxShadow: MCColors.cardShadow,
          ),
          padding: const EdgeInsets.all(MCSpacing.cardPadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Community Activity', style: MCTypography.h4),
              const SizedBox(height: MCSpacing.md),
              _MetricRow(
                icon: Icons.group_outlined,
                iconColor: MCColors.primaryLight,
                iconBg: MCColors.primaryPale,
                label: 'Total Members',
                value: '${health.totalMembers}',
              ),
              const _MetricDivider(),
              _MetricRow(
                icon: Icons.person_outlined,
                iconColor: MCColors.success,
                iconBg: MCColors.successBg,
                label: 'Active This Month',
                value: '${health.activeThisMonth}',
              ),
              const _MetricDivider(),
              _MetricRow(
                icon: Icons.event_outlined,
                iconColor: MCColors.violet,
                iconBg: MCColors.violetLight,
                label: 'Events This Month',
                value: '${health.eventsThisMonth}',
              ),
              const _MetricDivider(),
              _MetricRow(
                icon: Icons.article_outlined,
                iconColor: MCColors.primaryMid,
                iconBg: MCColors.primaryPale,
                label: 'Posts This Month',
                value: '${health.postsThisMonth}',
              ),
              const _MetricDivider(),
              _MetricRow(
                icon: Icons.emoji_events_outlined,
                iconColor: MCColors.amberDark,
                iconBg: MCColors.amberLight,
                label: 'Recognitions',
                value: '${health.recognitionsThisMonth}',
              ),
            ],
          ),
        ),
        const SizedBox(height: MCSpacing.md),
      ],
    );
  }
}

class _HealthScoreHero extends StatelessWidget {
  const _HealthScoreHero({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MCSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E4585), Color(0xFF0F2D5E)],
        ),
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        boxShadow: MCColors.primaryButtonShadow,
      ),
      child: Column(
        children: [
          Text(
            'Community Health',
            style: MCTypography.labelSm.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: MCSpacing.sm),
          Text(
            '$score',
            style: MCTypography.kpi.copyWith(color: Colors.white, fontSize: 48),
          ),
          const SizedBox(height: 4),
          Text(
            'out of 100',
            style: MCTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: MCSpacing.sm),
          Expanded(child: Text(label, style: MCTypography.body)),
          Text(value, style: MCTypography.labelLg),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: MCColors.borderLight,
      height: 1,
      thickness: 1,
    );
  }
}
