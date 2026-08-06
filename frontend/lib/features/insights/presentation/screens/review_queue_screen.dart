import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manager_connect/features/insights/data/models/insight_dto.dart';
import 'package:manager_connect/features/insights/data/models/insight_review_dto.dart';
import 'package:manager_connect/features/insights/presentation/providers/review_queue_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reviewQueueProvider.notifier).load());
  }

  Future<void> _refresh() =>
      ref.read(reviewQueueProvider.notifier).refresh();

  Future<void> _onApprove(InsightReviewDto item) async {
    final confirmed = await _showApproveDialog(item);
    if (confirmed != true || !mounted) return;
    final success =
        await ref.read(reviewQueueProvider.notifier).approve(item.id);
    if (!mounted) return;
    if (success) {
      showSuccessToast(
        context,
        '"${item.aiHeadline ?? 'Insight'}" published to feed',
      );
    } else {
      showErrorToast(context, 'Failed to publish — please try again');
    }
  }

  Future<void> _onReject(InsightReviewDto item) async {
    final reason = await _showRejectDialog(item);
    if (reason == null || !mounted) return; // null = user cancelled
    final success = await ref
        .read(reviewQueueProvider.notifier)
        .reject(item.id, reason: reason.isEmpty ? null : reason);
    if (!mounted) return;
    if (success) {
      showSuccessToast(context, 'Insight archived');
    } else {
      showErrorToast(context, 'Failed to reject — please try again');
    }
  }

  Future<bool?> _showApproveDialog(InsightReviewDto item) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish this insight?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.aiHeadline != null) ...[
              Text(
                item.aiHeadline!,
                style: MCTypography.bodySm,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'This insight will appear in the member feed immediately.',
              style: MCTypography.bodySm.copyWith(color: MCColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: MCColors.success,
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  /// Returns null on cancel; empty string or reason text on confirm.
  Future<String?> _showRejectDialog(InsightReviewDto item) {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject this insight?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.aiHeadline != null) ...[
              Text(
                item.aiHeadline!,
                style: MCTypography.bodySm,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Why is this being rejected?',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, reasonController.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: MCColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewQueueProvider);
    return Scaffold(
      backgroundColor: MCColors.background,
      appBar: AppBar(
        backgroundColor: MCColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: MCColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Text(
              'Review Queue',
              style: MCTypography.h4.copyWith(color: MCColors.textPrimary),
            ),
            if (state.items.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MCColors.amberLight,
                  borderRadius:
                      BorderRadius.circular(MCSpacing.radiusPill),
                ),
                child: Text(
                  '${state.items.length}',
                  style: MCTypography.labelSm
                      .copyWith(color: MCColors.amberDark),
                ),
              ),
            ],
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: MCColors.border),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ReviewQueueState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingState(message: 'Loading review queue…');
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(reviewQueueProvider.notifier).load(),
      );
    }
    if (state.items.isEmpty) {
      return const _QueueEmptyState();
    }
    return RefreshIndicator(
      color: MCColors.primary,
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          MCSpacing.pageH,
          MCSpacing.cardGap,
          MCSpacing.pageH,
          MCSpacing.pageH + 24,
        ),
        itemCount: state.items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: MCSpacing.cardGap),
        itemBuilder: (context, index) {
          final item = state.items[index];
          return _ReviewCard(
            item: item,
            isProcessing: state.processingId == item.id,
            actionsDisabled: state.processingId != null,
            onApprove: () => _onApprove(item),
            onReject: () => _onReject(item),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review card
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.item,
    required this.isProcessing,
    required this.actionsDisabled,
    required this.onApprove,
    required this.onReject,
  });

  final InsightReviewDto item;
  final bool isProcessing;
  final bool actionsDisabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MCSpacing.cardPadH,
              MCSpacing.cardPadH,
              MCSpacing.cardPadH,
              0,
            ),
            child: _CardHeader(item: item),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MCSpacing.cardPadH,
              vertical: MCSpacing.sm,
            ),
            child: _CardBody(item: item),
          ),

          // ── Divider ─────────────────────────────────────────────────────
          const Divider(height: 1, color: MCColors.borderLight),

          // ── Action row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(MCSpacing.cardPadH),
            child: isProcessing
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: MCColors.primaryMid,
                      ),
                    ),
                  )
                : _ActionRow(
                    item: item,
                    disabled: actionsDisabled,
                    onApprove: onApprove,
                    onReject: onReject,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card header — category pill, AI confidence badge, evergreen mark, time
// ─────────────────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.item});
  final InsightReviewDto item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pills row
        Row(
          children: [
            _CategoryPill(item.insightCategory),
            const SizedBox(width: 6),
            if (item.aiConfidence != null)
              _ConfidenceBadge(item.aiConfidence!),
            if (item.isEvergreen) ...[
              const SizedBox(width: 6),
              const _EvergreenBadge(),
            ],
            const Spacer(),
            Text(
              _relativeTime(item.createdAt),
              style: MCTypography.caption
                  .copyWith(color: MCColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Headline
        Text(
          item.aiHeadline ?? 'Untitled insight',
          style: MCTypography.h3,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Source meta
        Text(
          _sourceMeta(item),
          style: MCTypography.caption
              .copyWith(color: MCColors.textMuted),
        ),
      ],
    );
  }

  static String _sourceMeta(InsightReviewDto item) {
    final parts = <String>[];
    if (item.sourceName != null) parts.add(item.sourceName!);
    if (item.articleDate != null) parts.add(item.articleDate!);
    if (item.readingTimeMinutes != null) {
      parts.add('${item.readingTimeMinutes} min read');
    }
    return parts.join(' · ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card body — summary, why it matters, key takeaway, tags
// ─────────────────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({required this.item});
  final InsightReviewDto item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.aiSummary != null) ...[
          const _SectionLabel('Summary'),
          const SizedBox(height: 4),
          Text(
            item.aiSummary!,
            style: MCTypography.bodySm,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: MCSpacing.sm),
        ],
        if (item.aiWhyMatters != null) ...[
          const _SectionLabel('Why it matters'),
          const SizedBox(height: 4),
          Text(
            item.aiWhyMatters!,
            style: MCTypography.bodySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: MCSpacing.sm),
        ],
        if (item.aiKeyTakeaway != null) ...[
          const _SectionLabel('Key takeaway'),
          const SizedBox(height: 4),
          Text(
            item.aiKeyTakeaway!,
            style: MCTypography.bodySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: MCSpacing.sm),
        ],
        if (item.aiTags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.aiTags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MCColors.borderLight,
                      borderRadius: BorderRadius.circular(
                          MCSpacing.radiusPill),
                      border: Border.all(color: MCColors.border),
                    ),
                    child: Text(
                      '#$tag',
                      style: MCTypography.caption
                          .copyWith(color: MCColors.textSecondary),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action row — View Article / Reject / Publish
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.item,
    required this.disabled,
    required this.onApprove,
    required this.onReject,
  });

  final InsightReviewDto item;
  final bool disabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (item.sourceUrl != null) ...[
          _ActionChip(
            label: 'View Article',
            icon: Icons.open_in_new_rounded,
            fgColor: MCColors.textSecondary,
            bgColor: MCColors.borderLight,
            onTap: () => _launchUrl(item.sourceUrl!),
          ),
          const Spacer(),
        ] else
          const Spacer(),
        _ActionChip(
          label: 'Reject',
          icon: Icons.close_rounded,
          fgColor: MCColors.error,
          bgColor: MCColors.errorBg,
          onTap: disabled ? null : onReject,
        ),
        const SizedBox(width: 8),
        _ActionChip(
          label: 'Publish',
          icon: Icons.check_rounded,
          fgColor: Colors.white,
          bgColor: MCColors.primary,
          onTap: disabled ? null : onApprove,
        ),
      ],
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category pill — mirrors logic from insights_feed_screen / insight_detail_screen
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  const _CategoryPill(this.category);
  final InsightCategory category;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (category) {
      InsightCategory.gridTechnology =>
        (MCColors.infoBg, MCColors.info),
      InsightCategory.energyTransition =>
        (MCColors.successBg, MCColors.success),
      InsightCategory.industryStandards =>
        (MCColors.primaryPale, MCColors.primaryMid),
      InsightCategory.engineeringLeadership =>
        (MCColors.violetLight, MCColors.violet),
      InsightCategory.policyMarkets =>
        (MCColors.amberLight, MCColors.amberDark),
      InsightCategory.innovation =>
        (MCColors.errorBg, MCColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(
        category.displayLabel,
        style: MCTypography.labelSm.copyWith(color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI confidence badge
// ─────────────────────────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge(this.confidence);
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final (bg, fg) = confidence >= 0.8
        ? (MCColors.successBg, MCColors.success)
        : confidence >= 0.6
            ? (MCColors.amberLight, MCColors.amberDark)
            : (MCColors.errorBg, MCColors.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            '$pct%',
            style: MCTypography.labelSm.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Evergreen badge
// ─────────────────────────────────────────────────────────────────────────────

class _EvergreenBadge extends StatelessWidget {
  const _EvergreenBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: MCColors.violetLight,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.all_inclusive, size: 11, color: MCColors.violet),
          const SizedBox(width: 3),
          Text(
            'Evergreen',
            style: MCTypography.labelSm.copyWith(color: MCColors.violet),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label — body divider inside card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: MCTypography.overline,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact action chip — Reject / Publish / View Article
// ─────────────────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.fgColor,
    required this.bgColor,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color fgColor;
  final Color bgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final fg = isDisabled ? MCColors.textMuted : fgColor;
    final bg = isDisabled ? MCColors.borderLight : bgColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: MCTypography.labelSm.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — queue is clear
// ─────────────────────────────────────────────────────────────────────────────

class _QueueEmptyState extends StatelessWidget {
  const _QueueEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 36,
                color: MCColors.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Queue is clear',
              style: MCTypography.h4.copyWith(color: MCColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'All insights have been reviewed.\nCheck back after the next pipeline run.',
              style: MCTypography.bodySm.copyWith(color: MCColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton (shown during initial fetch)
// ─────────────────────────────────────────────────────────────────────────────

// Note: LoadingState is used instead of a custom skeleton here to keep
// the loading experience consistent with the admin dashboard pattern.

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}
