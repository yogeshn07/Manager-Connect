import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/features/events/presentation/providers/activities_provider.dart';
import 'package:manager_connect/features/events/presentation/widgets/activity_card.dart';
import 'package:manager_connect/features/events/presentation/screens/create_activity_screen.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

class ActivitiesListScreen extends ConsumerStatefulWidget {
  const ActivitiesListScreen({super.key});

  @override
  ConsumerState<ActivitiesListScreen> createState() =>
      _ActivitiesListScreenState();
}

class _ActivitiesListScreenState
    extends ConsumerState<ActivitiesListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activitiesProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: Icon(state.showPast
                ? Icons.upcoming
                : Icons.history),
            tooltip: state.showPast ? 'Show upcoming' : 'Show past',
            onPressed: () =>
                ref.read(activitiesProvider.notifier).togglePast(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateActivity(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(state),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(ActivitiesState state) {
    const categories = [null, 'games', 'outings', 'social_connect'];
    const labels = ['All', 'Games', 'Outings', 'Social'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: List.generate(categories.length, (i) {
          final selected = state.categoryFilter == categories[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[i]),
              selected: selected,
              onSelected: (_) => ref
                  .read(activitiesProvider.notifier)
                  .setCategory(categories[i]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody(ActivitiesState state) {
    if (state.isLoading && state.upcoming.isEmpty && state.past.isEmpty) {
      return const LoadingState(message: 'Loading events...');
    }

    if (state.error != null &&
        state.upcoming.isEmpty &&
        state.past.isEmpty) {
      return ErrorState(
        message: 'Failed to load events',
        onRetry: () => ref.read(activitiesProvider.notifier).load(),
      );
    }

    final activities = state.showPast ? state.past : state.upcoming;

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.showPast ? Icons.history : Icons.event_available,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              state.showPast ? 'No past events' : 'No upcoming events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(activitiesProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ActivityCard(
            activity: activity,
            onTap: () => context.push('/events/event/${activity.id}'),
          );
        },
      ),
    );
  }

  void _showCreateActivity(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateActivityScreen(),
    );
  }
}
