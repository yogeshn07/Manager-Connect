import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/insights/data/models/insight_source_dto.dart';
import 'package:manager_connect/features/insights/presentation/providers/submit_insight_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Submit Insight Screen
// ─────────────────────────────────────────────────────────────────────────────

class SubmitInsightScreen extends ConsumerStatefulWidget {
  const SubmitInsightScreen({super.key});

  @override
  ConsumerState<SubmitInsightScreen> createState() =>
      _SubmitInsightScreenState();
}

class _SubmitInsightScreenState extends ConsumerState<SubmitInsightScreen> {
  final _urlController = TextEditingController();
  final _urlFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(submitInsightProvider.notifier).loadSources(),
    );
    _urlController.addListener(
      () => ref.read(submitInsightProvider.notifier).setUrl(_urlController.text),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submitInsightProvider);

    // Show error dialog when a submission error arrives
    ref.listen<SubmitInsightState>(submitInsightProvider, (prev, next) {
      if (next.submissionError != null &&
          next.submissionError != prev?.submissionError) {
        _showErrorDialog(context, next.submissionError!,
            isDuplicate: next.submissionErrorCode == 'DUPLICATE_URL');
      }
    });

    return Scaffold(
      backgroundColor: MCColors.background,
      appBar: _buildAppBar(context, state),
      body: state.isSuccess
          ? _SuccessState(
              rawId: state.rawId,
              onBack: () => Navigator.of(context).pop(),
            )
          : _buildForm(context, state),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, SubmitInsightState state) {
    return AppBar(
      backgroundColor: MCColors.card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: MCColors.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text('Submit Insight', style: MCTypography.h4),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: MCColors.borderLight),
      ),
    );
  }

  Widget _buildForm(BuildContext context, SubmitInsightState state) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MCSpacing.pageH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Instruction card ──────────────────────────────────
                  const _InfoBanner(),
                  const SizedBox(height: MCSpacing.lg),

                  // ── URL field ─────────────────────────────────────────
                  const _FieldLabel(label: 'Article URL', required: true),
                  const SizedBox(height: MCSpacing.xs),
                  _UrlField(
                    controller: _urlController,
                    focusNode: _urlFocus,
                    error: state.urlError,
                    enabled: !state.isSubmitting,
                  ),
                  if (state.urlError != null) ...[
                    const SizedBox(height: 4),
                    _FieldError(message: state.urlError!),
                  ],
                  const SizedBox(height: MCSpacing.lg),

                  // ── Source picker ─────────────────────────────────────
                  const _FieldLabel(label: 'Source publication', required: true),
                  const SizedBox(height: MCSpacing.xs),
                  if (state.isLoadingSources)
                    const _SourceLoadingPlaceholder()
                  else if (state.sourcesError != null)
                    _SourceLoadError(
                      onRetry: () =>
                          ref.read(submitInsightProvider.notifier).loadSources(),
                    )
                  else
                    _SourcePickerField(
                      selected: state.selectedSource,
                      enabled: !state.isSubmitting,
                      onTap: () => _openSourcePicker(context, state),
                    ),
                  if (state.sourceError != null) ...[
                    const SizedBox(height: 4),
                    _FieldError(message: state.sourceError!),
                  ],

                  // ── Domain hint ────────────────────────────────────────
                  if (state.selectedSource != null) ...[
                    const SizedBox(height: MCSpacing.xs),
                    _DomainHint(source: state.selectedSource!),
                  ],

                  const SizedBox(height: MCSpacing.xl3),
                ],
              ),
            ),
          ),

          // ── Submit button (pinned to bottom) ──────────────────────────
          _SubmitBar(
            isSubmitting: state.isSubmitting,
            canSubmit: state.canSubmit,
            onSubmit: () => ref.read(submitInsightProvider.notifier).submit(),
          ),
        ],
      ),
    );
  }

  void _openSourcePicker(BuildContext context, SubmitInsightState state) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MCSpacing.radiusLg),
        ),
      ),
      builder: (_) => _SourcePickerSheet(
        sources: state.sources,
        selected: state.selectedSource,
        onSelect: (source) {
          ref.read(submitInsightProvider.notifier).setSource(source);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message,
      {bool isDuplicate = false}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          isDuplicate
              ? Icons.content_copy_outlined
              : Icons.error_outline_rounded,
          color: isDuplicate ? MCColors.amber : MCColors.error,
          size: 32,
        ),
        title: Text(
          isDuplicate ? 'Already in pipeline' : 'Submission failed',
          style: MCTypography.h3,
        ),
        content: Text(message, style: MCTypography.body),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(submitInsightProvider.notifier).clearSubmissionError();
            },
            child: Text(
              isDuplicate ? 'Got it' : 'Try again',
              style: MCTypography.label.copyWith(color: MCColors.primaryMid),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets — form
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MCSpacing.sm),
      decoration: BoxDecoration(
        color: MCColors.primaryPale,
        borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
        border: Border.all(color: MCColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: MCColors.primaryMid),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Paste a direct article URL from an approved source. '
              'The pipeline will validate, extract metadata, and queue '
              'it for AI enrichment.',
              style: MCTypography.bodySm,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: MCTypography.labelSm),
        if (required) ...[
          const SizedBox(width: 3),
          Text('*',
              style: MCTypography.labelSm.copyWith(color: MCColors.error)),
        ],
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 13, color: MCColors.error),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            message,
            style: MCTypography.caption.copyWith(color: MCColors.error),
          ),
        ),
      ],
    );
  }
}

class _UrlField extends StatelessWidget {
  const _UrlField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    this.error,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Container(
      decoration: BoxDecoration(
        color: enabled ? MCColors.inputBg : MCColors.background,
        borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
        border: Border.all(
          color: hasError ? MCColors.error : MCColors.border,
          width: hasError ? 1.5 : MCSpacing.borderThin,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.link_rounded, size: 18, color: MCColors.textMuted),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              style: MCTypography.body,
              decoration: InputDecoration(
                hintText: 'https://example.com/article',
                hintStyle:
                    MCTypography.body.copyWith(color: MCColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 13,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty && enabled)
            GestureDetector(
              onTap: controller.clear,
              child: const Padding(
                padding: EdgeInsets.only(right: 10),
                child:
                    Icon(Icons.cancel_rounded, size: 16, color: MCColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _SourcePickerField extends StatelessWidget {
  const _SourcePickerField({
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final InsightSourceDto? selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: enabled ? MCColors.inputBg : MCColors.background,
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          border: Border.all(color: MCColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.source_outlined,
                size: 18, color: MCColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected?.name ?? 'Select a source…',
                style: MCTypography.body.copyWith(
                  color: selected != null
                      ? MCColors.textPrimary
                      : MCColors.textMuted,
                ),
              ),
            ),
            if (selected != null)
              _TierBadge(tier: selected!.tier),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: MCColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final int tier;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (tier) {
      1 => ('T1', MCColors.primaryPale, MCColors.primaryMid),
      2 => ('T2', MCColors.successBg, MCColors.success),
      _ => ('T3', MCColors.background, MCColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(label,
          style: MCTypography.overline.copyWith(color: fg, fontSize: 10)),
    );
  }
}

class _DomainHint extends StatelessWidget {
  const _DomainHint({required this.source});

  final InsightSourceDto source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.verified_outlined, size: 13, color: MCColors.success),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Approved domain: ${source.approvedDomain}',
            style: MCTypography.caption.copyWith(color: MCColors.success),
          ),
        ),
      ],
    );
  }
}

class _SourceLoadingPlaceholder extends StatelessWidget {
  const _SourceLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: MCColors.inputBg,
        borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
        border: Border.all(color: MCColors.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(MCColors.primaryMid),
          ),
        ),
      ),
    );
  }
}

class _SourceLoadError extends StatelessWidget {
  const _SourceLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MCColors.errorBg,
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          border: Border.all(color: MCColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.refresh_rounded, size: 16, color: MCColors.error),
            const SizedBox(width: 8),
            Text(
              'Failed to load sources — tap to retry',
              style: MCTypography.bodySm.copyWith(color: MCColors.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isSubmitting,
    required this.canSubmit,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        MCSpacing.pageH,
        MCSpacing.sm,
        MCSpacing.pageH,
        MCSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(top: BorderSide(color: MCColors.borderLight)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: GestureDetector(
          onTap: canSubmit ? onSubmit : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: canSubmit ? MCColors.primary : MCColors.border,
              borderRadius: BorderRadius.circular(MCSpacing.radiusButton),
              boxShadow: canSubmit ? MCColors.primaryButtonShadow : null,
            ),
            alignment: Alignment.center,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'Submit to pipeline',
                    style: MCTypography.label.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SourcePickerSheet extends StatefulWidget {
  const _SourcePickerSheet({
    required this.sources,
    required this.selected,
    required this.onSelect,
  });

  final List<InsightSourceDto> sources;
  final InsightSourceDto? selected;
  final ValueChanged<InsightSourceDto> onSelect;

  @override
  State<_SourcePickerSheet> createState() => _SourcePickerSheetState();
}

class _SourcePickerSheetState extends State<_SourcePickerSheet> {
  final _search = TextEditingController();
  List<InsightSourceDto> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.sources;
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.sources
          : widget.sources
              .where((s) =>
                  s.name.toLowerCase().contains(q) ||
                  s.approvedDomain.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group by tier
    final byTier = <int, List<InsightSourceDto>>{};
    for (final s in _filtered) {
      byTier.putIfAbsent(s.tier, () => []).add(s);
    }
    final tiers = byTier.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MCColors.border,
                borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: MCSpacing.pageH),
              child: Row(
                children: [
                  Text('Select source', style: MCTypography.h3),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        size: 20, color: MCColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: MCSpacing.pageH),
              child: Container(
                decoration: BoxDecoration(
                  color: MCColors.inputBg,
                  borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
                  border: Border.all(color: MCColors.border),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(Icons.search,
                          size: 18, color: MCColors.textMuted),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        style: MCTypography.body,
                        decoration: InputDecoration(
                          hintText: 'Search sources…',
                          hintStyle: MCTypography.body
                              .copyWith(color: MCColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: MCColors.borderLight),

            // Source list
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text('No sources match',
                          style: MCTypography.bodySm),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: tiers.fold<int>(
                        0,
                        (sum, t) => sum + 1 + (byTier[t]?.length ?? 0),
                      ),
                      itemBuilder: (_, i) {
                        int offset = 0;
                        for (final tier in tiers) {
                          final rows = byTier[tier]!;
                          if (i == offset) {
                            // Tier header
                            final label = switch (tier) {
                              1 => 'Tier 1 — Premier',
                              2 => 'Tier 2 — Validated',
                              _ => 'Tier 3 — Trade',
                            };
                            return _TierHeader(label: label);
                          }
                          offset++;
                          if (i < offset + rows.length) {
                            final source = rows[i - offset];
                            return _SourceRow(
                              source: source,
                              isSelected:
                                  widget.selected?.id == source.id,
                              onTap: () => widget.onSelect(source),
                            );
                          }
                          offset += rows.length;
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MCSpacing.pageH,
        MCSpacing.md,
        MCSpacing.pageH,
        MCSpacing.xs2,
      ),
      child: Text(label, style: MCTypography.overline),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.source,
    required this.isSelected,
    required this.onTap,
  });

  final InsightSourceDto source;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MCSpacing.pageH,
          vertical: 11,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source.name, style: MCTypography.label),
                  Text(source.approvedDomain, style: MCTypography.caption),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: MCColors.primary)
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success state
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessState extends StatelessWidget {
  const _SuccessState({this.rawId, required this.onBack});

  final String? rawId;
  final VoidCallback onBack;

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
                color: MCColors.successBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 40,
                color: MCColors.success,
              ),
            ),
            const SizedBox(height: 20),
            Text('Insight submitted!', style: MCTypography.h2),
            const SizedBox(height: 8),
            Text(
              'The pipeline will validate the URL, extract metadata, '
              'and AI-enrich the article. It will appear in the feed '
              'once reviewed and scheduled.',
              style: MCTypography.bodySm,
              textAlign: TextAlign.center,
            ),
            if (rawId != null) ...[
              const SizedBox(height: 12),
              Text(
                'Pipeline ID: $rawId',
                style: MCTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: MCColors.primary,
                  borderRadius:
                      BorderRadius.circular(MCSpacing.radiusButton),
                  boxShadow: MCColors.primaryButtonShadow,
                ),
                child: Text(
                  'Back to Insights',
                  style: MCTypography.label.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
