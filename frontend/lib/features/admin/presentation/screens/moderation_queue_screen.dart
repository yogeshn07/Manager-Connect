import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/admin/data/models/admin_dto.dart';
import 'package:manager_connect/features/admin/presentation/providers/admin_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
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
      backgroundColor: MCColors.background,
      body: Column(
        children: [
          _buildHeader(state),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(ModerationState state) {
    final count = state.flags.length;
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
          Expanded(child: Text('Moderation', style: MCTypography.h3)),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: MCColors.errorBg,
                borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
              ),
              child: Text(
                '$count pending',
                style: MCTypography.caption.copyWith(color: MCColors.error, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
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
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: MCColors.primaryMid,
      onRefresh: () => ref.read(moderationProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          MCSpacing.pageH, MCSpacing.md, MCSpacing.pageH, MCSpacing.xl),
        itemCount: state.flags.length,
        itemBuilder: (context, index) => _buildFlagCard(state.flags[index]),
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
              color: MCColors.successBg,
              borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: MCColors.success),
          ),
          const SizedBox(height: MCSpacing.md),
          Text('All clear!', style: MCTypography.h4),
          const SizedBox(height: 6),
          Text(
            'No flagged content to review',
            style: MCTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFlagCard(FlaggedContentDto flag) {
    final contentLabel = _contentTypeLabel(flag.contentType);

    return Container(
      margin: const EdgeInsets.only(bottom: MCSpacing.cardGap),
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flag header stripe
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MCSpacing.cardPadH, vertical: 10),
            decoration: const BoxDecoration(
              color: MCColors.errorBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(MCSpacing.radiusMd),
                topRight: Radius.circular(MCSpacing.radiusMd),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, size: 15, color: MCColors.error),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: MCColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                  ),
                  child: Text(
                    contentLabel,
                    style: MCTypography.caption.copyWith(
                      color: MCColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  _dateFormat.format(flag.createdAt),
                  style: MCTypography.caption.copyWith(
                    color: MCColors.error.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ),
          ),

          // Flag body
          Padding(
            padding: const EdgeInsets.all(MCSpacing.cardPadH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (flag.reason != null && flag.reason!.isNotEmpty) ...[
                  Text('Reason', style: MCTypography.overline.copyWith(color: MCColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(flag.reason!, style: MCTypography.body),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: MCColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Reported by ${flag.reporterName ?? 'Unknown'}',
                      style: MCTypography.caption.copyWith(color: MCColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: MCSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: MCGhostButton(
                        label: 'Dismiss',
                        onPressed: () => _confirmAction(
                          flag: flag,
                          action: 'dismiss',
                          title: 'Dismiss flag?',
                          message: 'This will dismiss the flag and keep the content.',
                          buttonLabel: 'Dismiss',
                          isDestructive: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MCDeleteButton(
                        onPressed: () => _confirmAction(
                          flag: flag,
                          action: 'delete',
                          title: 'Delete content?',
                          message:
                              'This will permanently delete the flagged '
                              '${contentLabel.toLowerCase()} and resolve the flag.',
                          buttonLabel: 'Delete',
                          isDestructive: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MCSpacing.radiusMd)),
        title: Text(title, style: MCTypography.h4),
        content: Text(message, style: MCTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: MCTypography.label.copyWith(color: MCColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              buttonLabel,
              style: MCTypography.label.copyWith(
                color: isDestructive ? MCColors.error : MCColors.primaryMid),
            ),
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
      if (mounted) showErrorToast(context, 'Failed to resolve flag');
    }
  }
}

class _MCDeleteButton extends StatelessWidget {
  const _MCDeleteButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: MCColors.errorBg,
          borderRadius: BorderRadius.circular(MCSpacing.radiusButton),
          border: Border.all(color: MCColors.error.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            'Delete Content',
            style: MCTypography.label.copyWith(color: MCColors.error),
          ),
        ),
      ),
    );
  }
}
