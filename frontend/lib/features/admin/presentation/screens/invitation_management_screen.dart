import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/admin/data/models/admin_dto.dart';
import 'package:manager_connect/features/admin/presentation/providers/admin_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class InvitationManagementScreen extends ConsumerStatefulWidget {
  const InvitationManagementScreen({super.key});

  @override
  ConsumerState<InvitationManagementScreen> createState() =>
      _InvitationManagementScreenState();
}

class _InvitationManagementScreenState
    extends ConsumerState<InvitationManagementScreen> {
  static final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(invitationManagementProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invitationManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitations'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateInvitationDialog,
        child: const Icon(Icons.person_add),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(InvitationManagementState state) {
    if (state.isLoading && state.invitations.isEmpty) {
      return const LoadingState(message: 'Loading invitations...');
    }

    if (state.error != null && state.invitations.isEmpty) {
      return ErrorState(
        message: 'Failed to load invitations',
        onRetry: () =>
            ref.read(invitationManagementProvider.notifier).load(),
      );
    }

    if (state.invitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No invitations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to invite someone',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(invitationManagementProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: state.invitations.length,
        itemBuilder: (context, index) =>
            _buildInvitationTile(state.invitations[index]),
      ),
    );
  }

  Widget _buildInvitationTile(InvitationDto invitation) {
    final theme = Theme.of(context);
    final contact = invitation.inviteeEmail ?? invitation.inviteePhone ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.mail_outline,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(invitation.inviteeName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contact.isNotEmpty)
            Text(
              contact,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            _dateFormat.format(invitation.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip(invitation.status, theme),
          if (invitation.status == 'pending') ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.cancel_outlined,
                  size: 20, color: theme.colorScheme.error),
              tooltip: 'Revoke',
              onPressed: () => _confirmRevoke(invitation),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    final Color backgroundColor;
    final Color foregroundColor;

    switch (status) {
      case 'pending':
        backgroundColor = theme.colorScheme.tertiaryContainer;
        foregroundColor = theme.colorScheme.onTertiaryContainer;
      case 'accepted':
        backgroundColor = theme.colorScheme.primaryContainer;
        foregroundColor = theme.colorScheme.onPrimaryContainer;
      case 'expired':
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        foregroundColor = theme.colorScheme.onSurfaceVariant;
      case 'revoked':
        backgroundColor = theme.colorScheme.errorContainer;
        foregroundColor = theme.colorScheme.onErrorContainer;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        foregroundColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(color: foregroundColor),
      ),
    );
  }

  Future<void> _confirmRevoke(InvitationDto invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke invitation?'),
        content: Text(
          'Are you sure you want to revoke the invitation for '
          '${invitation.inviteeName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(invitationManagementProvider.notifier)
          .revoke(invitation.id);
      if (mounted) {
        showSuccessToast(context, 'Invitation revoked');
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Failed to revoke invitation');
      }
    }
  }

  void _showCreateInvitationDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Invitation'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Invitee full name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'invitee@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext);
              await _sendInvitation(
                name: nameController.text.trim(),
                email: emailController.text.trim().isNotEmpty
                    ? emailController.text.trim()
                    : null,
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvitation({
    required String name,
    String? email,
  }) async {
    try {
      final result = await ref
          .read(invitationManagementProvider.notifier)
          .send(name: name, email: email);

      if (!mounted) return;

      final inviteUrl = result['invite_url'] as String?;
      if (inviteUrl != null) {
        _showInviteUrlDialog(inviteUrl);
      } else {
        showSuccessToast(context, 'Invitation sent successfully');
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Failed to send invitation');
      }
    }
  }

  void _showInviteUrlDialog(String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invitation Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this link with the invitee:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(dialogContext)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              showSuccessToast(context, 'Link copied to clipboard');
            },
            child: const Text('Copy Link'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
