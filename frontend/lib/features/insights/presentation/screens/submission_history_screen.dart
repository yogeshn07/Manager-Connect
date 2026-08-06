import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/features/insights/data/models/insight_raw_dto.dart';
import 'package:manager_connect/features/insights/presentation/providers/submission_history_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_cards.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_shimmer.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SubmissionHistoryScreen extends ConsumerStatefulWidget {
  const SubmissionHistoryScreen({super.key});

  @override
  ConsumerState<SubmissionHistoryScreen> createState() =>
      _SubmissionHistoryScreenState();
}

class _SubmissionHistoryScreenState
    extends ConsumerState<SubmissionHistoryScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  void _init() {
    _userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (_userId != null) {
      ref.read(submissionHistoryProvider.notifier).load(_userId!);
    }
  }

  Future<void> _refresh() async {
    if (_userId == null) return;
    await ref.read(submissionHistoryProvider.notifier).refresh(_userId!);
  }

  Future<void> _handleTap(InsightRawDto item) async {
    try {
      final publishedId = await ref
          .read(submissionHistoryProvider.notifier)
          .getPublishedId(item.id);
      if (!mounted) return;
      if (publishedId != null) {
        await context.push('/insights/$publishedId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Published insight not yet available'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load insight')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submissionHistoryProvider);
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
        title: Text(
          'My Submissions',
          style: MCTypography.h4.copyWith(color: MCColors.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: MCColors.border),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(SubmissionHistoryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const _LoadingSkeleton();
    }
    if (state.error != null && state.items.isEmpty) {
      return _ErrorState(message: state.error!, onRetry: _init);
    }
    if (state.items.isEmpty) {
      return const _EmptyState();
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
        separatorBuilder: (_, __) => const SizedBox(height: MCSpacing.cardGap),
        itemBuilder: (context, index) {
          final item = state.items[index];
          return _HistoryCard(
            item: item,
            onTap: item.status == 'active'
                ? () {
                    _handleTap(item);
                  }
                : null,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History card
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, this.onTap});
  final InsightRawDto item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title =
        item.ogTitle?.isNotEmpty == true ? item.ogTitle! : _domain(item.rawUrl);
    final domain = _domain(item.rawUrl);
    final isActive = item.status == 'active';

    return MCCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(item.status),
              const Spacer(),
              Text(
                _relativeTime(item.createdAt),
                style: MCTypography.caption.copyWith(color: MCColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: MCTypography.labelLg.copyWith(color: MCColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  domain,
                  style: MCTypography.caption.copyWith(color: MCColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: MCColors.textMuted,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _domain(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.host.replaceFirst('www.', '');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: MCTypography.labelSm.copyWith(color: fg),
      ),
    );
  }

  static (String, Color, Color) _resolve(String s) => switch (s) {
        'pending'      => ('Pending',    MCColors.amberLight,  MCColors.amberDark),
        'validated'    => ('Validated',  MCColors.primaryPale, MCColors.primaryMid),
        'duplicate'    => ('Duplicate',  MCColors.borderLight, MCColors.textSecondary),
        'rejected'     => ('Rejected',   MCColors.errorBg,     MCColors.error),
        'ai_processed' => ('AI Done',    MCColors.violetLight, MCColors.violet),
        'review'       => ('In Review',  MCColors.amberLight,  MCColors.amberDark),
        'scheduled'    => ('Scheduled',  MCColors.primaryPale, MCColors.primaryMid),
        'active'       => ('Published',  MCColors.successBg,   MCColors.success),
        'archived'     => ('Archived',   MCColors.borderLight, MCColors.textSecondary),
        'ai_error'     => ('AI Error',   MCColors.errorBg,     MCColors.error),
        _              => ('Unknown',    MCColors.borderLight, MCColors.textSecondary),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        MCSpacing.pageH,
        MCSpacing.cardGap,
        MCSpacing.pageH,
        MCSpacing.pageH,
      ),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: MCSpacing.cardGap),
      itemBuilder: (_, __) => const _HistoryCardSkeleton(),
    );
  }
}

class _HistoryCardSkeleton extends StatelessWidget {
  const _HistoryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return MCShimmer(
      child: Container(
        padding: const EdgeInsets.all(MCSpacing.cardPadH),
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          border: Border.all(color: MCColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MCShimmerBox(width: 72, height: 22, radius: MCSpacing.radiusPill),
                Spacer(),
                MCShimmerBox(width: 52, height: 12, radius: MCSpacing.radiusXs),
              ],
            ),
            SizedBox(height: 10),
            MCShimmerBox(height: 15),
            SizedBox(height: 6),
            MCShimmerBox(width: 200, height: 15),
            SizedBox(height: 8),
            MCShimmerBox(width: 100, height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
                color: MCColors.primaryPale,
                borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 36,
                color: MCColors.primaryMid,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No submissions yet',
              style: MCTypography.h4.copyWith(color: MCColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Articles you submit through the pipeline\nwill appear here with their status.',
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
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: MCColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load submissions',
              style: MCTypography.h4.copyWith(color: MCColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: MCTypography.bodySm.copyWith(color: MCColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: MCColors.primary,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

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
