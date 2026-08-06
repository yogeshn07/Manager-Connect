import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/review_queue_provider.dart';

import '../../../../../helpers/insight_fixtures.dart';

void main() {
  group('ReviewQueueState defaults', () {
    test('has sensible initial values', () {
      const state = ReviewQueueState();
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.processingId, isNull);
    });
  });

  group('ReviewQueueState.copyWith', () {
    test('preserves all fields when called with no arguments', () {
      final items = [makeReviewDto()];
      final state = ReviewQueueState(
        items: items,
        isLoading: true,
        error: 'EF error',
        processingId: 'ci-001',
      );

      final copy = state.copyWith();
      expect(copy.items, same(items));
      expect(copy.isLoading, isTrue);
      expect(copy.error, 'EF error');
      expect(copy.processingId, 'ci-001');
    });

    test('error sentinel — null clears the error', () {
      const state = ReviewQueueState(error: 'EF error');
      expect(state.copyWith(error: null).error, isNull);
    });

    test('error sentinel — omitting preserves the error', () {
      const state = ReviewQueueState(error: 'EF error');
      expect(state.copyWith(isLoading: false).error, 'EF error');
    });

    test('processingId sentinel — null clears the id', () {
      const state = ReviewQueueState(processingId: 'ci-001');
      expect(state.copyWith(processingId: null).processingId, isNull);
    });

    test('processingId sentinel — omitting preserves the id', () {
      const state = ReviewQueueState(processingId: 'ci-001');
      expect(state.copyWith(isLoading: true).processingId, 'ci-001');
    });

    test('optimistic removal sequence works', () {
      final items = [makeReviewDto(id: 'ci-001'), makeReviewDto(id: 'ci-002')];
      final state = ReviewQueueState(items: items);

      // Approve ci-001: set processingId
      final processing = state.copyWith(processingId: 'ci-001', error: null);
      expect(processing.processingId, 'ci-001');

      // Success: remove ci-001, clear processingId
      final remaining = processing.copyWith(
        items: processing.items.where((i) => i.id != 'ci-001').toList(),
        processingId: null,
      );
      expect(remaining.items.length, 1);
      expect(remaining.items.first.id, 'ci-002');
      expect(remaining.processingId, isNull);
    });
  });
}
