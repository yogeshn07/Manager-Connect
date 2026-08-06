import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/submit_insight_provider.dart';

import '../../../../../helpers/insight_fixtures.dart';

void main() {
  // ── SubmitInsightState defaults ───────────────────────────────────────────

  group('SubmitInsightState defaults', () {
    test('has sensible initial values', () {
      const state = SubmitInsightState();
      expect(state.sources, isEmpty);
      expect(state.isLoadingSources, isFalse);
      expect(state.sourcesError, isNull);
      expect(state.url, '');
      expect(state.urlError, isNull);
      expect(state.selectedSource, isNull);
      expect(state.sourceError, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.rawId, isNull);
      expect(state.submissionError, isNull);
      expect(state.submissionErrorCode, isNull);
    });
  });

  // ── canSubmit getter ──────────────────────────────────────────────────────

  group('SubmitInsightState.canSubmit', () {
    final source = makeSourceDto();

    test('false when url is empty', () {
      final state = SubmitInsightState(url: '', selectedSource: source);
      expect(state.canSubmit, isFalse);
    });

    test('false when url is whitespace only', () {
      final state = SubmitInsightState(url: '   ', selectedSource: source);
      expect(state.canSubmit, isFalse);
    });

    test('false when selectedSource is null', () {
      const state = SubmitInsightState(url: 'https://example.com');
      expect(state.canSubmit, isFalse);
    });

    test('false when isSubmitting', () {
      final state = SubmitInsightState(
        url: 'https://example.com',
        selectedSource: source,
        isSubmitting: true,
      );
      expect(state.canSubmit, isFalse);
    });

    test('false when isSuccess', () {
      final state = SubmitInsightState(
        url: 'https://example.com',
        selectedSource: source,
        isSuccess: true,
      );
      expect(state.canSubmit, isFalse);
    });

    test('true when url and source are set and not submitting/success', () {
      final state = SubmitInsightState(
        url: 'https://energymonitor.ai/article/1',
        selectedSource: source,
      );
      expect(state.canSubmit, isTrue);
    });
  });

  // ── copyWith sentinels ────────────────────────────────────────────────────

  group('SubmitInsightState.copyWith', () {
    test('preserves unspecified fields', () {
      final source = makeSourceDto();
      final state = SubmitInsightState(
        url: 'https://example.com',
        selectedSource: source,
        urlError: 'bad url',
        sourcesError: 'sources failed',
        submissionError: 'sub error',
        submissionErrorCode: 'DUPLICATE_URL',
        rawId: 'raw-001',
      );

      final copy = state.copyWith();
      expect(copy.url, 'https://example.com');
      expect(copy.selectedSource, same(source));
      expect(copy.urlError, 'bad url');
      expect(copy.sourcesError, 'sources failed');
      expect(copy.submissionError, 'sub error');
      expect(copy.submissionErrorCode, 'DUPLICATE_URL');
      expect(copy.rawId, 'raw-001');
    });

    test('sourcesError sentinel — null clears the error', () {
      const state = SubmitInsightState(sourcesError: 'failed');
      expect(state.copyWith(sourcesError: null).sourcesError, isNull);
    });

    test('urlError sentinel — null clears the error', () {
      const state = SubmitInsightState(urlError: 'Invalid URL');
      expect(state.copyWith(urlError: null).urlError, isNull);
    });

    test('sourceError sentinel — null clears the error', () {
      const state = SubmitInsightState(sourceError: 'Select a source');
      expect(state.copyWith(sourceError: null).sourceError, isNull);
    });

    test('submissionError sentinel — null clears the error', () {
      const state = SubmitInsightState(submissionError: 'Pipeline error');
      expect(state.copyWith(submissionError: null).submissionError, isNull);
    });

    test('submissionErrorCode sentinel — null clears the code', () {
      const state = SubmitInsightState(submissionErrorCode: 'DUPLICATE_URL');
      expect(
        state.copyWith(submissionErrorCode: null).submissionErrorCode,
        isNull,
      );
    });

    test('selectedSource sentinel — null clears the source', () {
      final state = SubmitInsightState(selectedSource: makeSourceDto());
      expect(state.copyWith(selectedSource: null).selectedSource, isNull);
    });

    test('rawId sentinel — null clears rawId', () {
      const state = SubmitInsightState(rawId: 'raw-001');
      expect(state.copyWith(rawId: null).rawId, isNull);
    });
  });
}
