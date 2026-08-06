import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/events/data/models/activity_dto.dart';
import 'package:manager_connect/features/events/presentation/providers/activities_provider.dart';
import 'package:manager_connect/features/events/presentation/screens/create_activity_screen.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class ActivitiesListScreen extends ConsumerStatefulWidget {
  const ActivitiesListScreen({super.key});

  @override
  ConsumerState<ActivitiesListScreen> createState() =>
      _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends ConsumerState<ActivitiesListScreen> {
  static const _categories = [null, 'games', 'outings', 'social_connect'];
  static const _categoryLabels = ['All', 'Games', 'Outings', 'Social'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activitiesProvider.notifier).load();
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _categoryColor(String category) {
    return switch (category) {
      'games'          => MCColors.primaryMid,
      'outings'        => MCColors.success,
      'social_connect' => MCColors.amber,
      _                => MCColors.textMuted,
    };
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'games'          => 'Games',
      'outings'        => 'Outings',
      'social_connect' => 'Social',
      _                => category,
    };
  }

  void _showCreateActivity() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateActivityScreen(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activitiesProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(state),
            _buildFilterChips(state),
            Expanded(child: _buildBody(state)),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(ActivitiesState state) {
    return Container(
      height: MCSpacing.topBarHeight,
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(
          bottom: BorderSide(color: MCColors.borderLight),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: MCSpacing.pageH),
      child: Row(
        children: [
          Expanded(child: Text('Events', style: MCTypography.h3)),
          _buildTogglePill(state),
        ],
      ),
    );
  }

  Widget _buildTogglePill(ActivitiesState state) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: MCColors.background,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        border: Border.all(color: MCColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pillSegment(
            label: 'Upcoming',
            selected: !state.showPast,
            onTap: () {
              if (state.showPast) {
                ref.read(activitiesProvider.notifier).togglePast();
              }
            },
          ),
          _pillSegment(
            label: 'Past',
            selected: state.showPast,
            onTap: () {
              if (!state.showPast) {
                ref.read(activitiesProvider.notifier).togglePast();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _pillSegment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? MCColors.primaryMid : Colors.transparent,
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: MCTypography.labelSm.copyWith(
            color: selected ? Colors.white : MCColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Category filter chips ──────────────────────────────────────────────────

  Widget _buildFilterChips(ActivitiesState state) {
    return Container(
      color: MCColors.card,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: List.generate(_categories.length, (i) {
            final selected = state.categoryFilter == _categories[i];
            return Padding(
              padding: EdgeInsets.only(
                right: i < _categories.length - 1 ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => ref
                    .read(activitiesProvider.notifier)
                    .setCategory(_categories[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? MCColors.primaryMid : MCColors.card,
                    borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                    border: Border.all(
                      color: selected ? MCColors.primaryMid : MCColors.border,
                    ),
                  ),
                  child: Text(
                    _categoryLabels[i],
                    style: MCTypography.labelSm.copyWith(
                      color: selected ? Colors.white : MCColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(ActivitiesState state) {
    if (state.isLoading && state.upcoming.isEmpty && state.past.isEmpty) {
      return const LoadingState();
    }

    if (state.error != null && state.upcoming.isEmpty && state.past.isEmpty) {
      return ErrorState(
        message: 'Failed to load events',
        onRetry: () => ref.read(activitiesProvider.notifier).load(),
      );
    }

    final activities = state.showPast ? state.past : state.upcoming;

    if (activities.isEmpty) {
      return _buildEmptyState(state.showPast);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(activitiesProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          MCSpacing.pageH,
          MCSpacing.sm,
          MCSpacing.pageH,
          MCSpacing.xl4,
        ),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < activities.length - 1 ? MCSpacing.sm : 0,
            ),
            child: _buildEventCard(activities[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool showPast) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available, size: 48, color: MCColors.textMuted),
          const SizedBox(height: 12),
          Text('No events yet', style: MCTypography.h4),
          const SizedBox(height: 4),
          Text(
            showPast
                ? 'Past events will appear here'
                : 'Upcoming events will appear here',
            style: MCTypography.caption,
          ),
        ],
      ),
    );
  }

  // ── Event card ─────────────────────────────────────────────────────────────

  Widget _buildEventCard(ActivityDto activity) {
    final catColor = _categoryColor(activity.eventCategory);
    final catLabel = _categoryLabel(activity.eventCategory);

    return GestureDetector(
      onTap: () => context.go('/events/event/${activity.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          border: Border.all(color: MCColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDateBlock(activity.eventDate, catColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(MCSpacing.cardPadH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: MCTypography.h4,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _buildCategoryChip(catLabel, catColor),
                      if (activity.location != null) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          activity.location!,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.schedule_outlined,
                        DateFormat('h:mm a').format(activity.eventDate),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBlock(DateTime date, Color color) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(MCSpacing.radiusMd),
          bottomLeft: Radius.circular(MCSpacing.radiusMd),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: MCTypography.overline.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            date.day.toString(),
            style: MCTypography.h2.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: MCTypography.overline.copyWith(color: color),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: MCColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: MCTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Create Event button ────────────────────────────────────────────────────

  Widget _buildCreateButton() {
    return Container(
      color: MCColors.background,
      padding: const EdgeInsets.fromLTRB(
        MCSpacing.pageH,
        MCSpacing.sm,
        MCSpacing.pageH,
        MCSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _showCreateActivity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: MCColors.primaryMid,
                borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Create Event',
                    style: MCTypography.labelSm.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
