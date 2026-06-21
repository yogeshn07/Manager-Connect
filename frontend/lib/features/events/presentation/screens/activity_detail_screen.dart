import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/core/theme/app_theme_extensions.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/events/data/models/activity_dto.dart';
import 'package:manager_connect/features/events/presentation/providers/activities_provider.dart';
import 'package:manager_connect/features/events/presentation/providers/activity_detail_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({required this.activityId, super.key});

  final String activityId;

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState
    extends ConsumerState<ActivityDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activityDetailProvider(widget.activityId).notifier).load();
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
    final state = ref.watch(activityDetailProvider(widget.activityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (state.activity != null &&
              state.activity!.createdBy == _currentUserId &&
              !state.activity!.isCancelled)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') _cancelActivity();
                if (value == 'update') _showPostUpdate();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'update', child: Text('Post Update')),
                const PopupMenuItem(
                    value: 'cancel', child: Text('Cancel Event')),
              ],
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ActivityDetailState state) {
    if (state.isLoading) return const LoadingState();
    if (state.error != null || state.activity == null) {
      return ErrorState(
        message: 'Failed to load event',
        onRetry: () => ref
            .read(activityDetailProvider(widget.activityId).notifier)
            .load(),
      );
    }

    final activity = state.activity!;
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final userId = _currentUserId;
    final myRsvp = state.rsvps
        .where((r) => r.userId == userId)
        .toList();
    final myStatus = myRsvp.isNotEmpty ? myRsvp.first.status : null;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(activityDetailProvider(widget.activityId).notifier)
          .load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activity.isCancelled)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Text('This event has been cancelled',
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
              ),
            ),
          Text(activity.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          _infoRow(Icons.calendar_today,
              DateFormat('EEEE, MMMM d · h:mm a').format(activity.eventDate.toLocal())),
          if (activity.location != null)
            _infoRow(Icons.location_on_outlined, activity.location!),
          _infoRow(Icons.category_outlined,
              '${activity.eventCategory.replaceAll('_', ' ')}${activity.eventType != null ? ' · ${activity.eventType!.replaceAll('_', ' ')}' : ''}'),
          if (activity.costNote != null)
            _infoRow(Icons.payments_outlined, activity.costNote!),
          _infoRow(Icons.person_outline,
              'Organized by ${activity.author?.fullName ?? 'Unknown'}'),
          if (activity.description != null) ...[
            const Divider(height: 32),
            Text(activity.description!, style: theme.textTheme.bodyLarge),
          ],
          const Divider(height: 32),
          Row(
            children: [
              Text('Attendees', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${state.goingCount} going · ${state.maybeCount} maybe',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!activity.isCancelled && userId != null)
            _buildRsvpButtons(userId, myStatus, ext),
          if (state.rsvps.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...state.rsvps
                .where((r) => r.status != 'not_going')
                .map(_buildRsvpTile),
          ],
          if (state.updates.isNotEmpty) ...[
            const Divider(height: 32),
            Text('Updates', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.updates.map(_buildUpdateTile),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildRsvpButtons(
      String userId, String? myStatus, AppThemeExtension? ext) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'going',
          icon: Icon(Icons.check_circle_outline, size: 18),
          label: Text('Going'),
        ),
        ButtonSegment(
          value: 'maybe',
          icon: Icon(Icons.help_outline, size: 18),
          label: Text('Maybe'),
        ),
        ButtonSegment(
          value: 'not_going',
          icon: Icon(Icons.cancel_outlined, size: 18),
          label: Text('No'),
        ),
      ],
      selected: myStatus != null ? {myStatus} : {},
      emptySelectionAllowed: true,
      onSelectionChanged: (selected) {
        if (selected.isEmpty) {
          ref
              .read(activityDetailProvider(widget.activityId).notifier)
              .withdrawRsvp(userId);
        } else {
          ref
              .read(activityDetailProvider(widget.activityId).notifier)
              .rsvp(userId: userId, status: selected.first);
        }
      },
    );
  }

  Widget _buildRsvpTile(RsvpDto rsvp) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final color = switch (rsvp.status) {
      'going' => ext?.rsvpGoingColor,
      'maybe' => ext?.rsvpMaybeColor,
      _ => null,
    };

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        child: Text(
          (rsvp.userName ?? '?')[0].toUpperCase(),
          style: const TextStyle(fontSize: 14),
        ),
      ),
      title: Text(rsvp.userName ?? 'Unknown'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          rsvp.status.replaceAll('_', ' '),
          style: TextStyle(fontSize: 12, color: color),
        ),
      ),
    );
  }

  Widget _buildUpdateTile(ActivityUpdateDto update) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(update.content),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(update.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelActivity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Event'),
        content: const Text(
            'All RSVPed members will be notified. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Event'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(activityDetailProvider(widget.activityId).notifier)
        .cancelActivity();
    await ref.read(activitiesProvider.notifier).refresh();
    if (mounted) showSuccessToast(context, 'Event cancelled');
  }

  void _showPostUpdate() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post Update'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Write an update for attendees...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isEmpty) return;
              Navigator.of(ctx).pop();
              await ref
                  .read(activityDetailProvider(widget.activityId).notifier)
                  .postUpdate(content);
              if (mounted) showSuccessToast(context, 'Update posted');
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
