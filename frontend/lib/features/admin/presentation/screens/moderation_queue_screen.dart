import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/admin/data/models/admin_dto.dart';
import 'package:manager_connect/features/admin/presentation/providers/admin_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class ModerationQueueScreen extends ConsumerStatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  ConsumerState<ModerationQueueScreen> createState() =>
      _ModerationQueueScreenState();
}

class _ModerationQueueScreenState
    extends ConsumerState<ModerationQueueScreen> {
  static final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(moderationProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moderationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ModerationState state) {
    if (state.isLoading && state.flags.isEmpty) {
      return const LoadingState(message: 'Loading flags...');
    }

    if (state.error != null && state.flags.isEmpty) {
      return ErrorState(
        message: 'Failed to load flags',
        onRetry: () => ref.read(moderationProvider.notifier).load(),
      );
    }

    if (state.flags.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending flags',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'All flagged content has been reviewed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(moderationProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.flags.length,
        itemBuilder: (context, index) => _buildFlagCard(state.flags[index]),
      ),
    );
  }

  Widget _buildFlagCard(FlaggedContentDto flag) {
    final theme = Theme.of(context);
    final contentLabel = _contentTypeLabel(flag.contentType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contentLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _dateFormat.format(flag.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (flag.reason != null && flag.reason!.isNotEmpty) ...[
              Text(
                flag.reason!,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Reported by: ${flag.reporterName ?? 'Unknown'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _confirmAction(
                    flag: flag,
                    action: 'dismiss',
                    title: 'Dismiss flag?',
                    message:
                        'This will dismiss the flag and keep the content.',
                    buttonLabel: 'Dismiss',
                    isDestructive: false,
                  ),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _confirmAction(
                    flag: flag,
                    action: 'delete',
                    title: 'Delete content?',
                    message: 'This will permanently delete the flagged '
                        '${contentLabel.toLowerCase()} and resolve the flag.',
                    buttonLabel: 'Delete',
                    isDestructive: true,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Delete Content'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _contentTypeLabel(String contentType) {
    switch (contentType) {
      case 'post':
        return 'Post';
      case 'comment':
        return 'Comment';
      default:
        return contentType[0].toUpperCase() + contentType.substring(1);
    }
  }

  Future<void> _confirmAction({
    required FlaggedContentDto flag,
    required String action,
    required String title,
    required String message,
    required String buttonLabel,
    required bool isDestructive,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(moderationProvider.notifier).resolve(flag.id, action);
      if (mounted) {
        final label = action == 'delete' ? 'Content deleted' : 'Flag dismissed';
        showSuccessToast(context, label);
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Failed to resolve flag');
      }
    }
  }
}
