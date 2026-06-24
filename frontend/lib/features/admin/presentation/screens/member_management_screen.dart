import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/admin/presentation/providers/admin_provider.dart';
import 'package:manager_connect/features/auth/data/models/profile_dto.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class MemberManagementScreen extends ConsumerStatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  ConsumerState<MemberManagementScreen> createState() =>
      _MemberManagementScreenState();
}

class _MemberManagementScreenState
    extends ConsumerState<MemberManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(memberManagementProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(MemberManagementState state) {
    if (state.isLoading && state.members.isEmpty) {
      return const LoadingState(message: 'Loading members...');
    }

    if (state.error != null && state.members.isEmpty) {
      return ErrorState(
        message: 'Failed to load members',
        onRetry: () => ref.read(memberManagementProvider.notifier).load(),
      );
    }

    if (state.members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(memberManagementProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: state.members.length,
        itemBuilder: (context, index) =>
            _buildMemberTile(state.members[index]),
      ),
    );
  }

  Widget _buildMemberTile(ProfileDto member) {
    final theme = Theme.of(context);
    final initial = member.fullName.isNotEmpty
        ? member.fullName[0].toUpperCase()
        : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          initial,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(member.fullName),
      subtitle: member.title != null ? Text(member.title!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRoleBadge(member.appRole, theme),
          const SizedBox(width: 8),
          _buildStatusChip(member.isActive, theme),
        ],
      ),
      onTap: () => _showMemberActions(member),
    );
  }

  Widget _buildRoleBadge(String role, ThemeData theme) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isAdmin
              ? theme.colorScheme.onTertiaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, ThemeData theme) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
        shape: BoxShape.circle,
      ),
    );
  }

  void _showMemberActions(ProfileDto member) {
    showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
        final isActive = member.isActive;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          member.fullName.isNotEmpty
                              ? member.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.fullName,
                              style: theme.textTheme.titleMedium,
                            ),
                            if (member.title != null)
                              Text(
                                member.title!,
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
                const SizedBox(height: 16),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    isActive ? Icons.person_off : Icons.person_add,
                    color: isActive ? theme.colorScheme.error : null,
                  ),
                  title: Text(
                    isActive ? 'Deactivate Member' : 'Reactivate Member',
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _confirmToggleActive(member);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                  title: Text('Remove Member', style: TextStyle(color: theme.colorScheme.error)),
                  subtitle: const Text('Anonymizes profile permanently'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _confirmRemove(member);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmToggleActive(ProfileDto member) async {
    final isActive = member.isActive;
    final action = isActive ? 'deactivate' : 'reactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} member?'),
        content: Text(
          'Are you sure you want to $action ${member.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: isActive
                ? FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (isActive) {
        await ref
            .read(memberManagementProvider.notifier)
            .deactivate(member.id);
      } else {
        await ref
            .read(memberManagementProvider.notifier)
            .reactivate(member.id);
      }
      if (mounted) {
        showSuccessToast(context, 'Member ${action}d successfully');
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Failed to $action member');
      }
    }
  }

  Future<void> _confirmRemove(ProfileDto member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member permanently?'),
        content: Text(
          'This will anonymize ${member.fullName}\'s profile to "Removed Member" and deactivate their account. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(memberManagementProvider.notifier).remove(member.id);
      if (mounted) {
        showSuccessToast(context, 'Member removed and anonymized');
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Failed to remove member');
      }
    }
  }
}
