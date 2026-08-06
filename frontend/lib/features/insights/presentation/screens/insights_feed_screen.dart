import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/features/insights/data/models/insight_dto.dart';
import 'package:manager_connect/features/insights/presentation/providers/insights_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_badges.dart';
import 'package:manager_connect/shared/widgets/mc/mc_cards.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_shimmer.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insights Feed Screen
// ─────────────────────────────────────────────────────────────────────────────

class InsightsFeedScreen extends ConsumerStatefulWidget {
  const InsightsFeedScreen({super.key});

  @override
  ConsumerState<InsightsFeedScreen> createState() => _InsightsFeedScreenState();
}

class _InsightsFeedScreenState extends ConsumerState<InsightsFeedScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final s = ref.read(insightsFeedProvider);
      if (s.items.isEmpty && !s.isLoading) {
        ref.read(insightsFeedProvider.notifier).load();
      }
    });
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(insightsFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insightsFeedProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _InsightsTopBar(),
            _CategoryChipsRow(
              selected: state.categoryFilter,
              onChanged: (cat) =>
                  ref.read(insightsFeedProvider.notifier).setCategory(cat),
            ),
            Expanded(
              child: RefreshIndicator(
                color: MCColors.primary,
                onRefresh: () =>
                    ref.read(insightsFeedProvider.notifier).refresh(),
                child: _buildBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(InsightsFeedState state) {
    // Initial load — full-screen shimmer
    if (state.isLoading && state.items.isEmpty) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: MCSpacing.pageH,
          vertical: MCSpacing.sm,
        ),
        itemCount: 4,
        separatorBuilder: (_, __) =>
            const SizedBox(height: MCSpacing.cardGap),
        itemBuilder: (_, __) => const _InsightCardSkeleton(),
      );
    }

    // Error — no data yet
    if (state.error != null && state.items.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => ref.read(insightsFeedProvider.notifier).load(),
      );
    }

    // Empty — loaded but no results
    if (state.items.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: MCSpacing.sm,
      ),
      itemCount: _itemCount(state),
      separatorBuilder: (_, __) => const SizedBox(height: MCSpacing.cardGap),
      itemBuilder: (context, i) => _buildItem(context, i, state),
    );
  }

  int _itemCount(InsightsFeedState state) {
    final base = state.items.length;
    final hasSpinner = state.isLoadingMore;
    final hasFooter = !state.hasMore;
    return base + (hasSpinner ? 1 : 0) + (hasFooter ? 1 : 0);
  }

  Widget _buildItem(BuildContext context, int i, InsightsFeedState state) {
    if (i < state.items.length) {
      return _InsightCard(
        insight: state.items[i],
        onTap: () => context.push('/insights/${state.items[i].id}'),
      );
    }
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(MCColors.primaryMid),
            ),
          ),
        ),
      );
    }
    // Footer
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'All ${state.items.length} insights · up to date',
          style: MCTypography.caption,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsTopBar extends StatelessWidget {
  const _InsightsTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(
          bottom: BorderSide(color: MCColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: MCColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.electric_bolt_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('GI Insights', style: MCTypography.h4),
                Text('Electrical engineering & industry news', style: MCTypography.caption),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.insightHistory),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MCColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MCColors.border),
              ),
              child: const Icon(Icons.history_rounded, size: 18, color: MCColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push(RouteNames.insightSubmit),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MCColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_link_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chips row
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChipsRow extends StatelessWidget {
  const _CategoryChipsRow({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MCColors.card,
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: MCSpacing.xs,
      ),
      child: SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            MCFilterChip(
              label: 'All',
              active: selected == null,
              onTap: () => onChanged(null),
            ),
            const SizedBox(width: 8),
            ...InsightCategory.values.map(
              (cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: MCFilterChip(
                  label: cat.displayLabel,
                  active: selected == cat.toJson(),
                  onTap: () => onChanged(cat.toJson()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insight card
// ─────────────────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.onTap});

  final InsightDto insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MCCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (insight.heroImageUrl != null)
              _HeroImage(url: insight.heroImageUrl!),
            Padding(
              padding: const EdgeInsets.all(MCSpacing.cardPadH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardMeta(insight: insight),
                  const SizedBox(height: MCSpacing.xs),
                  Text(
                    insight.aiHeadline ?? insight.sourceUrl ?? 'Untitled insight',
                    style: MCTypography.h3,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (insight.aiSummary != null) ...[
                    const SizedBox(height: MCSpacing.xs2),
                    Text(
                      insight.aiSummary!,
                      style: MCTypography.bodySm,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: MCSpacing.sm),
                  const Divider(height: 1, color: MCColors.borderLight),
                  const SizedBox(height: MCSpacing.xs),
                  _CardFooter(insight: insight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(MCSpacing.radiusMd),
      ),
      child: CachedNetworkImage(
        imageUrl: url,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 160,
          color: MCColors.background,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(MCColors.primaryMid),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 160,
          color: MCColors.primaryPale,
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 32,
              color: MCColors.primaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  const _CardMeta({required this.insight});

  final InsightDto insight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CategoryPill(category: insight.category),
        const Spacer(),
        if (insight.isEvergreen) ...[
          const Icon(Icons.all_inclusive, size: 12, color: MCColors.success),
          const SizedBox(width: 4),
        ],
        if (insight.readingTimeMinutes != null)
          Text(
            '${insight.readingTimeMinutes} min',
            style: MCTypography.caption,
          ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final InsightCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(category),
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(
        category.displayLabel.toUpperCase(),
        style: MCTypography.overline.copyWith(color: _fg(category)),
      ),
    );
  }

  static Color _bg(InsightCategory cat) => switch (cat) {
        InsightCategory.gridTechnology        => MCColors.infoBg,
        InsightCategory.energyTransition      => MCColors.successBg,
        InsightCategory.industryStandards     => MCColors.primaryPale,
        InsightCategory.engineeringLeadership => MCColors.violetLight,
        InsightCategory.policyMarkets         => MCColors.amberLight,
        InsightCategory.innovation            => MCColors.errorBg,
      };

  static Color _fg(InsightCategory cat) => switch (cat) {
        InsightCategory.gridTechnology        => MCColors.info,
        InsightCategory.energyTransition      => MCColors.success,
        InsightCategory.industryStandards     => MCColors.primaryMid,
        InsightCategory.engineeringLeadership => MCColors.violet,
        InsightCategory.policyMarkets         => MCColors.amberDark,
        InsightCategory.innovation            => MCColors.error,
      };
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.insight});

  final InsightDto insight;

  @override
  Widget build(BuildContext context) {
    final hasLink = insight.sourceUrl != null && insight.sourceUrl!.isNotEmpty;
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 12, color: MCColors.primaryLight),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: hasLink ? () => _launchUrl(insight.sourceUrl!) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    insight.sourceName ?? 'AI curated',
                    style: MCTypography.caption.copyWith(
                      color: hasLink ? MCColors.primaryMid : null,
                      decoration: hasLink ? TextDecoration.underline : null,
                      decorationColor: MCColors.primaryMid,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasLink) ...[
                  const SizedBox(width: 3),
                  const Icon(Icons.open_in_new, size: 10, color: MCColors.primaryMid),
                ],
              ],
            ),
          ),
        ),
        if (insight.publishedAt != null) ...[
          Text(
            _relativeTime(insight.publishedAt!),
            style: MCTypography.caption,
          ),
        ],
        const SizedBox(width: MCSpacing.xs),
        const Icon(
          Icons.chevron_right,
          size: 16,
          color: MCColors.textMuted,
        ),
      ],
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insight card skeleton — shimmer loading state
// ─────────────────────────────────────────────────────────────────────────────

class _InsightCardSkeleton extends StatelessWidget {
  const _InsightCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return MCShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          border: Border.all(color: MCColors.border),
          boxShadow: MCColors.cardShadow,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image placeholder
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(MCSpacing.radiusMd),
              ),
              child: MCShimmerBox(height: 140, radius: 0),
            ),
            Padding(
              padding: EdgeInsets.all(MCSpacing.cardPadH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category pill + reading time
                  Row(
                    children: [
                      MCShimmerBox(width: 96, height: 22, radius: MCSpacing.radiusPill),
                      Spacer(),
                      MCShimmerBox(width: 40, height: 14, radius: 4),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Headline
                  MCShimmerBox(height: 16),
                  SizedBox(height: 5),
                  MCShimmerBox(height: 16),
                  SizedBox(height: 5),
                  MCShimmerBox(width: 200, height: 16),
                  SizedBox(height: 10),
                  // Summary
                  MCShimmerBox(height: 13),
                  SizedBox(height: 4),
                  MCShimmerBox(height: 13),
                  SizedBox(height: 4),
                  MCShimmerBox(width: 180, height: 13),
                  SizedBox(height: 14),
                  // Footer
                  Row(
                    children: [
                      MCShimmerBox(width: 14, height: 14, radius: 4),
                      SizedBox(width: 6),
                      MCShimmerBox(width: 120, height: 12, radius: 4),
                      Spacer(),
                      MCShimmerBox(width: 32, height: 12, radius: 4),
                    ],
                  ),
                ],
              ),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MCColors.primaryPale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 36,
                color: MCColors.primaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text('No insights yet', style: MCTypography.h3),
            const SizedBox(height: 8),
            Text(
              'The team is curating content for your feed. Check back soon.',
              style: MCTypography.bodySm,
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
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: MCColors.textMuted),
            const SizedBox(height: 16),
            Text('Failed to load insights', style: MCTypography.h4),
            const SizedBox(height: 6),
            Text(
              message,
              style: MCTypography.bodySm,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: MCColors.primary,
                  borderRadius: BorderRadius.circular(MCSpacing.radiusButton),
                  boxShadow: MCColors.primaryButtonShadow,
                ),
                child: Text(
                  'Try again',
                  style: MCTypography.labelSm.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
