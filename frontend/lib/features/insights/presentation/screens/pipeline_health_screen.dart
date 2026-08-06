import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/features/insights/data/models/pipeline_health_dto.dart';
import 'package:manager_connect/features/insights/presentation/providers/pipeline_health_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class PipelineHealthScreen extends ConsumerStatefulWidget {
  const PipelineHealthScreen({super.key});

  @override
  ConsumerState<PipelineHealthScreen> createState() =>
      _PipelineHealthScreenState();
}

class _PipelineHealthScreenState
    extends ConsumerState<PipelineHealthScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(pipelineHealthProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pipelineHealthProvider);
    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(state),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PipelineHealthState state) {
    return Container(
      color: MCColors.card,
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: 14,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: MCColors.textPrimary,
            ),
          ),
          const SizedBox(width: MCSpacing.sm),
          Expanded(
            child: Text('Pipeline Health', style: MCTypography.h3),
          ),
          if (state.health != null)
            GestureDetector(
              onTap: state.isLoading
                  ? null
                  : () =>
                      ref.read(pipelineHealthProvider.notifier).refresh(),
              child: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: MCColors.textSecondary,
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(PipelineHealthState state) {
    if (state.isLoading && state.health == null) {
      return const LoadingState(message: 'Loading pipeline metrics...');
    }
    if (state.error != null && state.health == null) {
      return ErrorState(
        message: 'Failed to load pipeline metrics',
        onRetry: () =>
            ref.read(pipelineHealthProvider.notifier).load(),
      );
    }

    final h = state.health!;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(pipelineHealthProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          MCSpacing.pageH,
          MCSpacing.sm,
          MCSpacing.pageH,
          MCSpacing.xl4,
        ),
        children: [
          _buildCheckedAt(h.checkedAt),
          const SizedBox(height: MCSpacing.lg),
          _buildSectionLabel('HEALTH SIGNALS'),
          const SizedBox(height: MCSpacing.sm),
          _buildSignalsGrid(h),
          const SizedBox(height: MCSpacing.xl),
          _buildSectionLabel('RAW QUEUE  ·  ${h.rawTotal} total'),
          const SizedBox(height: MCSpacing.sm),
          _buildStatusBreakdown(h.rawQueueByStatus, _kRawStatuses),
          const SizedBox(height: MCSpacing.xl),
          _buildSectionLabel(
              'CATALYST INSIGHTS  ·  ${h.catalystTotal} total'),
          const SizedBox(height: MCSpacing.sm),
          _buildStatusBreakdown(
              h.catalystByStatus, _kCatalystStatuses),
          if (state.failedJobs.isNotEmpty) ...[
            const SizedBox(height: MCSpacing.xl),
            _buildSectionLabel(
                'FAILED ENRICHMENT  ·  ${state.failedJobs.length}'),
            const SizedBox(height: MCSpacing.sm),
            _buildJobList(state.failedJobs, isError: true),
          ],
          if (state.stalledJobs.isNotEmpty) ...[
            const SizedBox(height: MCSpacing.xl),
            _buildSectionLabel(
                'STALLED VALIDATION  ·  ${state.stalledJobs.length}'),
            const SizedBox(height: MCSpacing.sm),
            _buildJobList(state.stalledJobs, isError: false),
          ],
          if (state.failedJobs.isNotEmpty ||
              state.stalledJobs.isNotEmpty) ...[
            const SizedBox(height: MCSpacing.md),
            _buildOpsNote(),
          ],
        ],
      ),
    );
  }

  static const _kRawStatuses = <(String, String)>[
    ('pending', 'Pending'),
    ('validated', 'Validated'),
    ('ai_processed', 'AI Processed'),
    ('review', 'In Review'),
    ('scheduled', 'Scheduled'),
    ('active', 'Published'),
    ('archived', 'Archived'),
    ('duplicate', 'Duplicate'),
    ('rejected', 'Rejected'),
    ('ai_error', 'AI Error'),
  ];

  static const _kCatalystStatuses = <(String, String)>[
    ('review', 'In Review'),
    ('scheduled', 'Scheduled'),
    ('active', 'Published'),
    ('archived', 'Archived'),
  ];

  Widget _buildCheckedAt(DateTime checkedAt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Icon(
          Icons.access_time_rounded,
          size: 12,
          color: MCColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          'Refreshed ${_relativeTime(checkedAt)}',
          style: MCTypography.caption
              .copyWith(color: MCColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: MCTypography.overline.copyWith(
        letterSpacing: 0.1,
        color: MCColors.textMuted,
      ),
    );
  }

  Widget _buildSignalsGrid(PipelineHealthDto h) {
    final avgMs = h.avgTimeToPublishMs;
    final latencyLabel = avgMs == null
        ? '—'
        : avgMs < 60000
            ? '${(avgMs / 1000).toStringAsFixed(0)}s'
            : '${(avgMs / 60000).toStringAsFixed(1)}m';
    final latencySubLabel = h.latencySampleSize > 0
        ? 'Avg Publish (n=${h.latencySampleSize})'
        : 'Avg Publish';

    final signals = [
      _SignalData(
        icon: Icons.error_outline_rounded,
        label: 'Failed',
        value: '${h.failedEnrichmentCount}',
        iconBg: MCColors.errorBg,
        iconColor: MCColors.error,
        highlight: h.failedEnrichmentCount > 0,
      ),
      _SignalData(
        icon: Icons.hourglass_top_rounded,
        label: 'Stalled',
        value: '${h.stalledValidationCount}',
        iconBg: MCColors.amberLight,
        iconColor: MCColors.amberDark,
        highlight: h.stalledValidationCount > 0,
      ),
      _SignalData(
        icon: Icons.download_rounded,
        label: 'Ingested (24h)',
        value: '${h.ingestedLast24h}',
        iconBg: MCColors.primaryPale,
        iconColor: MCColors.primaryMid,
        highlight: false,
      ),
      _SignalData(
        icon: Icons.schedule_rounded,
        label: 'Scheduled',
        value: '${h.scheduledCount}',
        iconBg: MCColors.primaryPale,
        iconColor: MCColors.primaryMid,
        highlight: false,
      ),
      _SignalData(
        icon: Icons.archive_outlined,
        label: 'Archived',
        value: '${h.archivedCount}',
        iconBg: MCColors.borderLight,
        iconColor: MCColors.textSecondary,
        highlight: false,
      ),
      _SignalData(
        icon: Icons.timer_outlined,
        label: latencySubLabel,
        value: latencyLabel,
        iconBg: MCColors.successBg,
        iconColor: MCColors.success,
        highlight: false,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: MCSpacing.sm,
      crossAxisSpacing: MCSpacing.sm,
      childAspectRatio: 1.5,
      children: signals.map(_SignalCard.new).toList(),
    );
  }

  Widget _buildStatusBreakdown(
    Map<String, int> counts,
    List<(String, String)> statuses,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        boxShadow: MCColors.cardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < statuses.length; i++) ...[
            _buildStatusRow(
              statuses[i].$2,
              counts[statuses[i].$1] ?? 0,
              statuses[i].$1,
            ),
            if (i < statuses.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: MCColors.borderLight,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, String status) {
    final (bg, fg) = _statusColor(status);
    return SizedBox(
      height: 44,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: MCSpacing.pageH),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: MCTypography.label),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius:
                    BorderRadius.circular(MCSpacing.radiusPill),
              ),
              child: Text(
                '$count',
                style: MCTypography.pill.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (Color, Color) _statusColor(String status) => switch (status) {
        'ai_error' => (MCColors.errorBg, MCColors.error),
        'validated' => (MCColors.amberLight, MCColors.amberDark),
        'ai_processed' => (MCColors.violetLight, MCColors.violet),
        'review' => (MCColors.amberLight, MCColors.amberDark),
        'scheduled' => (MCColors.primaryPale, MCColors.primaryMid),
        'active' => (MCColors.successBg, MCColors.success),
        _ => (MCColors.borderLight, MCColors.textSecondary),
      };

  Widget _buildJobList(List<PipelineJobDto> jobs,
      {required bool isError}) {
    return Column(
      children: [
        for (var i = 0; i < jobs.length; i++) ...[
          if (i > 0) const SizedBox(height: MCSpacing.xs),
          _JobCard(job: jobs[i], isError: isError),
        ],
      ],
    );
  }

  Widget _buildOpsNote() {
    return Container(
      padding: const EdgeInsets.all(MCSpacing.md),
      decoration: BoxDecoration(
        color: MCColors.amberLight,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: MCColors.amberDark,
            ),
          ),
          const SizedBox(width: MCSpacing.sm),
          Expanded(
            child: Text(
              'Retry operations require ops tooling with service-role '
              'access. Records reset to validated state will be picked '
              'up by the recovery cron (CF-01, every 30 min).',
              style: MCTypography.caption
                  .copyWith(color: MCColors.amberDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private data class ────────────────────────────────────────────────────────

class _SignalData {
  _SignalData({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.iconColor,
    required this.highlight,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;
  final bool highlight;
}

// ── Signal card ───────────────────────────────────────────────────────────────

class _SignalCard extends StatelessWidget {
  const _SignalCard(this.data);

  final _SignalData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        boxShadow: MCColors.cardShadow,
        border: data.highlight
            ? Border.all(color: data.iconColor, width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.all(MCSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius:
                  BorderRadius.circular(MCSpacing.radiusSm),
            ),
            child: Icon(data.icon, size: 18, color: data.iconColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value, style: MCTypography.kpi),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: MCTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Job card ──────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.isError});

  final PipelineJobDto job;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        boxShadow: MCColors.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.md,
        vertical: MCSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.rawUrl,
            style: MCTypography.bodySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: MCSpacing.xs),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isError
                      ? MCColors.errorBg
                      : MCColors.amberLight,
                  borderRadius:
                      BorderRadius.circular(MCSpacing.radiusPill),
                ),
                child: Text(
                  isError ? 'ai_error' : 'stalled',
                  style: MCTypography.pill.copyWith(
                    color: isError
                        ? MCColors.error
                        : MCColors.amberDark,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _relativeTime(job.updatedAt),
                style: MCTypography.caption
                    .copyWith(color: MCColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
