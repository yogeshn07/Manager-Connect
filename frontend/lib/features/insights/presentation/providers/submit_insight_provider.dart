import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/insights/data/models/insight_source_dto.dart';
import 'package:manager_connect/features/insights/data/repositories/insight_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'submit_insight_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class SubmitInsightState {
  const SubmitInsightState({
    this.sources = const [],
    this.isLoadingSources = false,
    this.sourcesError,
    this.url = '',
    this.urlError,
    this.selectedSource,
    this.sourceError,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.rawId,
    this.submissionError,
    this.submissionErrorCode,
  });

  final List<InsightSourceDto> sources;
  final bool isLoadingSources;
  final String? sourcesError;

  final String url;
  final String? urlError;
  final InsightSourceDto? selectedSource;
  final String? sourceError;

  final bool isSubmitting;
  final bool isSuccess;
  final String? rawId;
  final String? submissionError;

  /// Pipeline error code from the Edge Function (e.g. 'DUPLICATE_URL').
  final String? submissionErrorCode;

  bool get canSubmit =>
      url.trim().isNotEmpty &&
      selectedSource != null &&
      !isSubmitting &&
      !isSuccess;

  SubmitInsightState copyWith({
    List<InsightSourceDto>? sources,
    bool? isLoadingSources,
    Object? sourcesError = _sentinel,
    String? url,
    Object? urlError = _sentinel,
    Object? selectedSource = _sentinel,
    Object? sourceError = _sentinel,
    bool? isSubmitting,
    bool? isSuccess,
    Object? rawId = _sentinel,
    Object? submissionError = _sentinel,
    Object? submissionErrorCode = _sentinel,
  }) {
    return SubmitInsightState(
      sources: sources ?? this.sources,
      isLoadingSources: isLoadingSources ?? this.isLoadingSources,
      sourcesError: sourcesError == _sentinel
          ? this.sourcesError
          : sourcesError as String?,
      url: url ?? this.url,
      urlError: urlError == _sentinel ? this.urlError : urlError as String?,
      selectedSource: selectedSource == _sentinel
          ? this.selectedSource
          : selectedSource as InsightSourceDto?,
      sourceError: sourceError == _sentinel
          ? this.sourceError
          : sourceError as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      rawId: rawId == _sentinel ? this.rawId : rawId as String?,
      submissionError: submissionError == _sentinel
          ? this.submissionError
          : submissionError as String?,
      submissionErrorCode: submissionErrorCode == _sentinel
          ? this.submissionErrorCode
          : submissionErrorCode as String?,
    );
  }
}

const _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Notifier — auto-dispose so each submit screen push gets a clean state
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class SubmitInsightNotifier extends _$SubmitInsightNotifier {
  InsightRepository? _repo;

  @override
  SubmitInsightState build() {
    _repo = InsightRepository(ref.watch(supabaseClientProvider));
    return const SubmitInsightState();
  }

  // ── Source list ────────────────────────────────────────────────────────────

  Future<void> loadSources() async {
    if (state.isLoadingSources || state.sources.isNotEmpty) return;
    state = state.copyWith(isLoadingSources: true, sourcesError: null);
    try {
      final sources = await _repo!.getAvailableSources();
      state = state.copyWith(sources: sources, isLoadingSources: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingSources: false,
        sourcesError: e.toString(),
      );
    }
  }

  // ── Form input ─────────────────────────────────────────────────────────────

  void setUrl(String url) {
    state = state.copyWith(
      url: url,
      urlError: null,
      submissionError: null,
      submissionErrorCode: null,
    );
  }

  void setSource(InsightSourceDto? source) {
    state = state.copyWith(
      selectedSource: source,
      sourceError: null,
      submissionError: null,
      submissionErrorCode: null,
    );
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validate() {
    final trimmed = state.url.trim();
    String? urlError;
    String? sourceError;

    if (trimmed.isEmpty) {
      urlError = 'URL is required';
    } else {
      final uri = Uri.tryParse(trimmed);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        urlError = 'Enter a valid URL';
      } else if (uri.scheme != 'https' && uri.scheme != 'http') {
        urlError = 'URL must start with https://';
      }
    }

    if (state.selectedSource == null) {
      sourceError = 'Select a source publication';
    }

    state = state.copyWith(urlError: urlError, sourceError: sourceError);
    return urlError == null && sourceError == null;
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  Future<void> submit() async {
    if (!_validate() || state.isSubmitting) return;

    state = state.copyWith(
      isSubmitting: true,
      submissionError: null,
      submissionErrorCode: null,
    );

    try {
      final result = await _repo!.collectInsight(
        url: state.url.trim(),
        sourceId: state.selectedSource!.id,
      );
      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        rawId: result['raw_id'] as String?,
      );
    } on AppException catch (e) {
      // Extract pipeline error code from the response body if present.
      // collectInsight throws AppException with the pipeline error message.
      final code = _extractCode(e.message);
      state = state.copyWith(
        isSubmitting: false,
        submissionError: _friendlyMessage(code, e.message),
        submissionErrorCode: code,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submissionError: e.toString(),
      );
    }
  }

  void clearSubmissionError() {
    state = state.copyWith(submissionError: null, submissionErrorCode: null);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String? _extractCode(String message) {
    // Pipeline errors have the format: "Failed to collect insight" or
    // include the code in the message from the edge function error body.
    const codes = [
      'SOURCE_NOT_FOUND',
      'DUPLICATE_URL',
      'DOMAIN_MISMATCH',
      'VALIDATION_FAILED',
      'OG_EXTRACTION_FAILED',
      'DB_ERROR',
      'CONFIG_MISSING',
      'FETCH_FAILED',
      'AI_ENRICHMENT_FAILED',
    ];
    for (final c in codes) {
      if (message.contains(c)) return c;
    }
    return null;
  }

  static String _friendlyMessage(
    String? code,
    String fallback,
  ) => switch (code) {
    'SOURCE_NOT_FOUND' => 'The selected source is no longer active.',
    'DUPLICATE_URL' => 'This article is already in the pipeline.',
    'DOMAIN_MISMATCH' => 'The URL domain does not match the selected source.',
    'VALIDATION_FAILED' => 'Please check the URL and source, then try again.',
    'OG_EXTRACTION_FAILED' =>
      'Could not read the article. Use a direct article URL.',
    'FETCH_FAILED' => 'Could not reach the article. Check the URL and retry.',
    'AI_ENRICHMENT_FAILED' =>
      'AI processing failed. The article was queued for manual review.',
    'DB_ERROR' => 'A database error occurred. Please try again.',
    _ => fallback,
  };
}
