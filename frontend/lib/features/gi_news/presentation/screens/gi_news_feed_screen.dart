import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manager_connect/features/gi_news/data/models/gi_news_item.dart';
import 'package:manager_connect/features/gi_news/data/services/gi_news_service.dart';
import 'package:manager_connect/features/gi_news/presentation/providers/gi_news_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_badges.dart';
import 'package:manager_connect/shared/widgets/mc/mc_cards.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_shimmer.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GI News Feed Screen — auto-fetched electrical engineering news
// ─────────────────────────────────────────────────────────────────────────────

class GINewsFeedScreen extends ConsumerStatefulWidget {
  const GINewsFeedScreen({super.key});

  @override
  ConsumerState<GINewsFeedScreen> createState() => _GINewsFeedScreenState();
}

class _GINewsFeedScreenState extends ConsumerState<GINewsFeedScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final s = ref.read(giNewsFeedProvider);
      if (s.items.isEmpty && !s.isLoading) {
        ref.read(giNewsFeedProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(giNewsFeedProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onRefresh: () => ref.read(giNewsFeedProvider.notifier).refresh()),
            _TopicChipsRow(
              selected: state.topicFilter,
              onChanged: (t) => ref.read(giNewsFeedProvider.notifier).setTopic(t),
            ),
            Expanded(
              child: RefreshIndicator(
                color: MCColors.primary,
                onRefresh: () => ref.read(giNewsFeedProvider.notifier).refresh(),
                child: _buildBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(GINewsFeedState state) {
    if (state.isLoading) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: MCSpacing.pageH,
          vertical: MCSpacing.sm,
        ),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: MCSpacing.cardGap),
        itemBuilder: (_, __) => const _NewsCardSkeleton(),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => ref.read(giNewsFeedProvider.notifier).load(),
      );
    }

    final items = state.displayed;

    if (items.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: MCSpacing.sm,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: MCSpacing.cardGap),
      itemBuilder: (context, i) => _NewsCard(item: items[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(bottom: BorderSide(color: MCColors.borderLight)),
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
                Text(
                  'Live electrical engineering news',
                  style: MCTypography.caption,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MCColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MCColors.border),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: MCColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topic filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _TopicChipsRow extends StatelessWidget {
  const _TopicChipsRow({
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
            ...GINewsService.feeds
                .map((f) => f.label)
                .toSet()
                .map(
                  (label) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: MCFilterChip(
                      label: label,
                      active: selected == label,
                      onTap: () => onChanged(label),
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
// File-level helpers shared by card and preview sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _launchUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w';
  if (diff.inDays >= 1) return '${diff.inDays}d';
  if (diff.inHours >= 1) return '${diff.inHours}h';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
  return 'just now';
}

// ─────────────────────────────────────────────────────────────────────────────
// News card — tapping opens the preview sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final GINewsItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _NewsPreviewSheet(item: item),
      ),
      child: MCCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null) _HeroImage(url: item.imageUrl!),
            Padding(
              padding: const EdgeInsets.all(MCSpacing.cardPadH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TopicPill(topic: item.topic),
                      const Spacer(),
                      Text(
                        _relativeTime(item.publishedAt),
                        style: MCTypography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: MCSpacing.xs),
                  Text(
                    item.title,
                    style: MCTypography.h3,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: MCSpacing.sm),
                  const Divider(height: 1, color: MCColors.borderLight),
                  const SizedBox(height: MCSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.newspaper_outlined,
                        size: 12,
                        color: MCColors.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.sourceName,
                          style: MCTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: MCColors.textMuted,
                      ),
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
// Preview sheet — description comes from the RSS feed, no async fetch needed
// ─────────────────────────────────────────────────────────────────────────────

class _NewsPreviewSheet extends StatelessWidget {
  const _NewsPreviewSheet({required this.item});
  final GINewsItem item;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasDesc = item.description != null && item.description!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        MCSpacing.pageH, 12, MCSpacing.pageH, 16 + bottomPad,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MCColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Topic pill + time
          Row(
            children: [
              _TopicPill(topic: item.topic),
              const Spacer(),
              Text(_relativeTime(item.publishedAt), style: MCTypography.caption),
            ],
          ),
          const SizedBox(height: 12),

          // Headline
          Text(
            item.title,
            style: MCTypography.h3,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Article summary from RSS description
          Text(
            hasDesc
                ? item.description!
                : 'Tap "Read Full Article" below to open the full story in your browser.',
            style: MCTypography.bodySm.copyWith(
              color: hasDesc ? MCColors.textSecondary : MCColors.textMuted,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: MCColors.borderLight),
          const SizedBox(height: 12),

          // Source
          Row(
            children: [
              const Icon(Icons.newspaper_outlined, size: 14, color: MCColors.primaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.sourceName,
                  style: MCTypography.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Read full article CTA
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              _launchUrl(item.articleUrl);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: MCColors.primary,
                borderRadius: BorderRadius.circular(MCSpacing.radiusButton),
                boxShadow: MCColors.primaryButtonShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Read Full Article',
                    style: MCTypography.labelSm.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero image
// ─────────────────────────────────────────────────────────────────────────────

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
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topic pill
// ─────────────────────────────────────────────────────────────────────────────

class _TopicPill extends StatelessWidget {
  const _TopicPill({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(topic),
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(
        topic.toUpperCase(),
        style: MCTypography.overline.copyWith(color: _fg(topic)),
      ),
    );
  }

  static Color _bg(String t) => switch (t) {
        'EEE'        => MCColors.infoBg,
        'Power Grid' => MCColors.primaryPale,
        'T&D'        => MCColors.amberLight,
        'Power Eng'  => MCColors.successBg,
        'Industry'   => MCColors.violetLight,
        'Leadership' => MCColors.errorBg,
        _            => MCColors.background,
      };

  static Color _fg(String t) => switch (t) {
        'EEE'        => MCColors.info,
        'Power Grid' => MCColors.primaryMid,
        'T&D'        => MCColors.amberDark,
        'Power Eng'  => MCColors.success,
        'Industry'   => MCColors.violet,
        'Leadership' => MCColors.error,
        _            => MCColors.textSecondary,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _NewsCardSkeleton extends StatelessWidget {
  const _NewsCardSkeleton();

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
                  Row(
                    children: [
                      MCShimmerBox(width: 80, height: 22, radius: MCSpacing.radiusPill),
                      Spacer(),
                      MCShimmerBox(width: 28, height: 12, radius: 4),
                    ],
                  ),
                  SizedBox(height: 10),
                  MCShimmerBox(height: 16),
                  SizedBox(height: 5),
                  MCShimmerBox(height: 16),
                  SizedBox(height: 5),
                  MCShimmerBox(width: 200, height: 16),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      MCShimmerBox(width: 14, height: 14, radius: 4),
                      SizedBox(width: 6),
                      MCShimmerBox(width: 120, height: 12, radius: 4),
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
                Icons.electric_bolt_outlined,
                size: 36,
                color: MCColors.primaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text('No news right now', style: MCTypography.h3),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh or check your connection.',
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
            Text('Could not load news', style: MCTypography.h4),
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
