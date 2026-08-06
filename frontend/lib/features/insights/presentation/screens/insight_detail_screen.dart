import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manager_connect/features/insights/data/models/insight_dto.dart';
import 'package:manager_connect/features/insights/presentation/providers/insights_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_shimmer.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insight Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class InsightDetailScreen extends ConsumerStatefulWidget {
  const InsightDetailScreen({super.key, required this.insightId});

  final String insightId;

  @override
  ConsumerState<InsightDetailScreen> createState() =>
      _InsightDetailScreenState();
}

class _InsightDetailScreenState extends ConsumerState<InsightDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(insightDetailProvider.notifier).load(widget.insightId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insightDetailProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      appBar: _buildAppBar(context, state.insight),
      body: _buildBody(state),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, InsightDto? insight) {
    return AppBar(
      backgroundColor: MCColors.card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: MCColors.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Insight',
        style: MCTypography.h4,
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: MCColors.borderLight),
      ),
      actions: [
        if (insight?.sourceUrl != null)
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            color: MCColors.textSecondary,
            tooltip: 'Open source article',
            onPressed: () => _launchSource(insight!.sourceUrl!),
          ),
      ],
    );
  }

  Widget _buildBody(InsightDetailState state) {
    if (state.isLoading) {
      return const _DetailSkeleton();
    }

    if (state.error != null) {
      return _DetailErrorState(
        message: state.error!,
        onRetry: () => ref
            .read(insightDetailProvider.notifier)
            .load(widget.insightId),
      );
    }

    final insight = state.insight;
    if (insight == null) return const SizedBox.shrink();

    return _DetailContent(insight: insight);
  }

  Future<void> _launchSource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail content
// ─────────────────────────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.insight});

  final InsightDto insight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header block ────────────────────────────────────────────────
          Container(
            color: MCColors.card,
            padding: const EdgeInsets.fromLTRB(
              MCSpacing.pageH,
              MCSpacing.md,
              MCSpacing.pageH,
              MCSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryPill(category: insight.category),
                    const Spacer(),
                    if (insight.readingTimeMinutes != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: MCColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${insight.readingTimeMinutes} min read',
                            style: MCTypography.caption,
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: MCSpacing.sm),
                Text(
                  insight.aiHeadline ?? insight.sourceUrl ?? 'Untitled insight',
                  style: MCTypography.h2,
                ),
                const SizedBox(height: MCSpacing.sm),
                _SourceLine(insight: insight),
              ],
            ),
          ),

          const SizedBox(height: MCSpacing.xs),

          // ── AI summary ──────────────────────────────────────────────────
          if (insight.aiSummary != null)
            _ContentSection(
              icon: Icons.auto_awesome_outlined,
              iconColor: MCColors.primaryLight,
              title: 'Summary',
              body: insight.aiSummary!,
            ),

          // ── Why it matters ──────────────────────────────────────────────
          if (insight.aiWhyMatters != null) ...[
            const _SectionDivider(),
            _ContentSection(
              icon: Icons.insights_outlined,
              iconColor: MCColors.success,
              title: 'Why it matters',
              body: insight.aiWhyMatters!,
            ),
          ],

          // ── Key takeaway ─────────────────────────────────────────────────
          if (insight.aiKeyTakeaway != null) ...[
            const _SectionDivider(),
            _KeyTakeawaySection(text: insight.aiKeyTakeaway!),
          ],

          // ── Tags ─────────────────────────────────────────────────────────
          if (insight.aiTags.isNotEmpty) ...[
            const _SectionDivider(),
            _TagsSection(tags: insight.aiTags),
          ],

          // ── Source link ──────────────────────────────────────────────────
          if (insight.sourceUrl != null) ...[
            const _SectionDivider(),
            _SourceLinkSection(
              sourceName: insight.sourceName,
              sourceUrl: insight.sourceUrl!,
              articleDate: insight.articleDate,
            ),
          ],

          // ── AI confidence note ────────────────────────────────────────────
          if (insight.isAiGenerated)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MCSpacing.pageH,
                MCSpacing.md,
                MCSpacing.pageH,
                0,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 14,
                    color: MCColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'AI-generated summary · always read the source before acting',
                      style: MCTypography.overline,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

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

class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.insight});

  final InsightDto insight;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (insight.sourceName != null) parts.add(insight.sourceName!);
    if (insight.articleDate != null) parts.add(insight.articleDate!);
    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.source_outlined, size: 14, color: MCColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: MCTypography.caption,
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: MCSpacing.xs);
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MCColors.card,
      padding: const EdgeInsets.all(MCSpacing.pageH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: MCTypography.labelSm),
            ],
          ),
          const SizedBox(height: MCSpacing.xs),
          Text(body, style: MCTypography.bodyLg),
        ],
      ),
    );
  }
}

class _KeyTakeawaySection extends StatelessWidget {
  const _KeyTakeawaySection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MCColors.card,
      padding: const EdgeInsets.all(MCSpacing.pageH),
      child: Container(
        padding: const EdgeInsets.all(MCSpacing.md),
        decoration: BoxDecoration(
          color: MCColors.primaryPale,
          borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
          border: Border.all(color: MCColors.primaryLight.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star_outline_rounded,
                  size: 16,
                  color: MCColors.primaryMid,
                ),
                const SizedBox(width: 8),
                Text(
                  'Key takeaway',
                  style: MCTypography.labelSm
                      .copyWith(color: MCColors.primaryMid),
                ),
              ],
            ),
            const SizedBox(height: MCSpacing.xs),
            Text(text, style: MCTypography.body),
          ],
        ),
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MCColors.card,
      padding: const EdgeInsets.all(MCSpacing.pageH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tags', style: MCTypography.labelSm),
          const SizedBox(height: MCSpacing.xs),
          Wrap(
            spacing: MCSpacing.xs,
            runSpacing: MCSpacing.xs2,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MCColors.background,
                      borderRadius:
                          BorderRadius.circular(MCSpacing.radiusPill),
                      border: Border.all(color: MCColors.border),
                    ),
                    child: Text(
                      tag,
                      style: MCTypography.caption,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SourceLinkSection extends StatelessWidget {
  const _SourceLinkSection({
    required this.sourceUrl,
    this.sourceName,
    this.articleDate,
  });

  final String sourceUrl;
  final String? sourceName;
  final String? articleDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MCColors.card,
      padding: const EdgeInsets.all(MCSpacing.pageH),
      child: GestureDetector(
        onTap: () => _launch(sourceUrl),
        child: Container(
          padding: const EdgeInsets.all(MCSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: MCColors.border),
            borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MCColors.primaryPale,
                  borderRadius: BorderRadius.circular(MCSpacing.radiusXs),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 20,
                  color: MCColors.primaryMid,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sourceName ?? 'Source article',
                      style: MCTypography.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (articleDate != null)
                      Text(articleDate!, style: MCTypography.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: MCColors.primaryMid,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: MCShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: MCColors.card,
              padding: const EdgeInsets.all(MCSpacing.pageH),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MCShimmerBox(width: 96, height: 22, radius: MCSpacing.radiusPill),
                      Spacer(),
                      MCShimmerBox(width: 56, height: 14, radius: 4),
                    ],
                  ),
                  SizedBox(height: 14),
                  MCShimmerBox(height: 22),
                  SizedBox(height: 6),
                  MCShimmerBox(height: 22),
                  SizedBox(height: 6),
                  MCShimmerBox(width: 200, height: 22),
                  SizedBox(height: 12),
                  MCShimmerBox(width: 140, height: 14, radius: 4),
                ],
              ),
            ),
            const SizedBox(height: MCSpacing.xs),
            // Summary section
            Container(
              color: MCColors.card,
              padding: const EdgeInsets.all(MCSpacing.pageH),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MCShimmerBox(width: 80, height: 14, radius: 4),
                  SizedBox(height: 12),
                  MCShimmerBox(height: 15),
                  SizedBox(height: 6),
                  MCShimmerBox(height: 15),
                  SizedBox(height: 6),
                  MCShimmerBox(height: 15),
                  SizedBox(height: 6),
                  MCShimmerBox(width: 240, height: 15),
                ],
              ),
            ),
            const SizedBox(height: MCSpacing.xs),
            // Why it matters
            Container(
              color: MCColors.card,
              padding: const EdgeInsets.all(MCSpacing.pageH),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MCShimmerBox(width: 120, height: 14, radius: 4),
                  SizedBox(height: 12),
                  MCShimmerBox(height: 15),
                  SizedBox(height: 6),
                  MCShimmerBox(height: 15),
                  SizedBox(height: 6),
                  MCShimmerBox(width: 180, height: 15),
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
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.message, required this.onRetry});

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
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: MCColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text('Failed to load insight', style: MCTypography.h4),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: MCColors.primary,
                  borderRadius:
                      BorderRadius.circular(MCSpacing.radiusButton),
                  boxShadow: MCColors.primaryButtonShadow,
                ),
                child: Text(
                  'Try again',
                  style:
                      MCTypography.labelSm.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
