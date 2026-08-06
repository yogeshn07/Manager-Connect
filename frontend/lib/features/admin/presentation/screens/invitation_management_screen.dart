import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/admin/data/models/admin_dto.dart';
import 'package:manager_connect/features/admin/presentation/providers/admin_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_inputs.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

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
      backgroundColor: MCColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody(state)),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: MCColors.card,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 4,
        right: MCSpacing.pageH,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: MCColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(child: Text('Invitations', style: MCTypography.h3)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MCColors.infoBg,
              borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
            ),
            child: Text('Admin', style: MCTypography.caption.copyWith(color: MCColors.info)),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _showCreateInvitationDialog,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: MCColors.primaryButtonGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: MCColors.primaryButtonShadow,
        ),
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(InvitationManagementState state) {
    if (state.isLoading && state.invitations.isEmpty) {
      return const LoadingState(message: 'Loading invitations...');
    }

    if (state.error != null && state.invitations.isEmpty) {
      return ErrorState(
        message: 'Failed to load invitations',
        onRetry: () => ref.read(invitationManagementProvider.notifier).load(),
      );
    }

    if (state.invitations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: MCColors.primaryMid,
      onRefresh: () => ref.read(invitationManagementProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          MCSpacing.pageH, MCSpacing.md, MCSpacing.pageH, 100),
        itemCount: state.invitations.length,
        itemBuilder: (context, index) =>
            _buildInvitationCard(state.invitations[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MCColors.primaryPale,
              borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
            ),
            child: const Icon(Icons.mail_outline_rounded, size: 36, color: MCColors.primaryMid),
          ),
          const SizedBox(height: MCSpacing.md),
          Text('No invitations yet', style: MCTypography.h4),
          const SizedBox(height: 6),
          Text(
            'Tap + to invite someone to the community',
            style: MCTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(InvitationDto invitation) {
    final contact = invitation.inviteeEmail ?? invitation.inviteePhone ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: MCSpacing.cardGap),
      padding: const EdgeInsets.all(MCSpacing.cardPadH),
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
      ),
      child: Row(
        children: [
          MCAvatar(
            initials: _initials(invitation.inviteeName),
            size: MCSpacing.avatarLg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invitation.inviteeName, style: MCTypography.label),
                if (contact.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(contact, style: MCTypography.caption),
                ],
                const SizedBox(height: 4),
                Text(
                  _dateFormat.format(invitation.createdAt),
                  style: MCTypography.caption.copyWith(color: MCColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusChip(invitation.status),
              if (invitation.status == 'pending') ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _confirmRevoke(invitation),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MCColors.errorBg,
                      borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                    ),
                    child: Text(
                      'Revoke',
                      style: MCTypography.caption.copyWith(
                        color: MCColors.error, fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final (Color bg, Color fg, String label) = switch (status) {
      'pending'  => (MCColors.warningBg,  MCColors.warning,    'Pending'),
      'accepted' => (MCColors.successBg,  MCColors.success,    'Accepted'),
      'expired'  => (MCColors.borderLight, MCColors.textMuted,  'Expired'),
      'revoked'  => (MCColors.errorBg,    MCColors.error,      'Revoked'),
      _          => (MCColors.borderLight, MCColors.textMuted,  status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(label, style: MCTypography.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _confirmRevoke(InvitationDto invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MCSpacing.radiusMd)),
        title: Text('Revoke invitation?', style: MCTypography.h4),
        content: Text(
          'This will revoke the invitation for ${invitation.inviteeName}.',
          style: MCTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: MCTypography.label.copyWith(color: MCColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Revoke', style: MCTypography.label.copyWith(color: MCColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(invitationManagementProvider.notifier).revoke(invitation.id);
      if (mounted) showSuccessToast(context, 'Invitation revoked');
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to revoke invitation');
    }
  }

  void _showCreateInvitationDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MCSpacing.radiusMd)),
        title: Text('Send Invitation', style: MCTypography.h4),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MCInput(
                controller: nameController,
                label: 'Name',
                hint: 'Invitee full name',
                focusColor: MCColors.primaryMid,
              ),
              const SizedBox(height: MCSpacing.md),
              MCInput(
                controller: emailController,
                label: 'Email',
                hint: 'invitee@example.com',
                keyboardType: TextInputType.emailAddress,
                focusColor: MCColors.primaryMid,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: MCTypography.label.copyWith(color: MCColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              await _sendInvitation(
                name: nameController.text.trim(),
                email: emailController.text.trim().isNotEmpty
                    ? emailController.text.trim()
                    : null,
              );
            },
            child: Text('Send', style: MCTypography.label.copyWith(color: MCColors.primaryMid)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvitation({required String name, String? email}) async {
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
      if (mounted) showErrorToast(context, 'Failed to send invitation');
    }
  }

  void _showInviteUrlDialog(String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MCSpacing.radiusMd)),
        title: Text('Invitation Sent', style: MCTypography.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this link with the invitee:', style: MCTypography.body),
            const SizedBox(height: MCSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MCColors.background,
                borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
                border: Border.all(color: MCColors.border),
              ),
              child: Text(
                url,
                style: MCTypography.caption.copyWith(fontFamily: 'monospace', fontSize: 11),
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
            child: Text('Copy Link', style: MCTypography.label.copyWith(color: MCColors.primaryMid)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Done', style: MCTypography.label.copyWith(color: MCColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
