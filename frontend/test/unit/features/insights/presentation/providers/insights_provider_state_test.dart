import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/insights_provider.dart';

import '../../../../../helpers/insight_fixtures.dart';

void main() {
  // ── InsightsFeedState ─────────────────────────────────────────────────────

  group('InsightsFeedState defaults', () {
    test('has sensible initial values', () {
      const state = InsightsFeedState();
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
      expect(state.categoryFilter, isNull);
      expect(state.hasMore, isTrue);
      expect(state.page, 0);
    });
  });

  group('InsightsFeedState.copyWith', () {
    test('preserves all fields when called with no arguments', () {
      final items = [makeInsightDto()];
      final state = InsightsFeedState(
        items: items,
        isLoading: true,
        error: 'Network error',
        categoryFilter: 'grid_technology',
        hasMore: false,
        page: 2,
      );

      final copy = state.copyWith();
      expect(copy.items, same(items));
      expect(copy.isLoading, isTrue);
      expect(copy.error, 'Network error');
      expect(copy.categoryFilter, 'grid_technology');
      expect(copy.hasMore, isFalse);
      expect(copy.page, 2);
    });

    test('error sentinel — null clears existing error', () {
      const state = InsightsFeedState(error: 'some error');
      final copy = state.copyWith(error: null);
      expect(
        copy.error,
        isNull,
        reason:
            'copyWith(error: null) must clear the error field (S5-INT-001 regression guard)',
      );
    });

    test('error sentinel — omitting preserves existing error', () {
      const state = InsightsFeedState(error: 'persistent error');
      final copy = state.copyWith(isLoading: false);
      expect(copy.error, 'persistent error');
    });

    test('error sentinel — setting a new error replaces old one', () {
      const state = InsightsFeedState(error: 'old error');
      final copy = state.copyWith(error: 'new error');
      expect(copy.error, 'new error');
    });

    test('categoryFilter sentinel — null clears the filter', () {
      const state = InsightsFeedState(categoryFilter: 'grid_technology');
      final copy = state.copyWith(categoryFilter: null);
      expect(copy.categoryFilter, isNull);
    });

    test('categoryFilter sentinel — omitting preserves the filter', () {
      const state = InsightsFeedState(categoryFilter: 'innovation');
      final copy = state.copyWith(isLoading: true);
      expect(copy.categoryFilter, 'innovation');
    });

    test('updates multiple fields atomically', () {
      const state = InsightsFeedState(isLoading: true, page: 0);
      final items = [makeInsightDto()];
      final copy = state.copyWith(
        items: items,
        isLoading: false,
        page: 1,
        hasMore: false,
      );
      expect(copy.items, items);
      expect(copy.isLoading, isFalse);
      expect(copy.page, 1);
      expect(copy.hasMore, isFalse);
    });
  });

  // ── InsightDetailState ────────────────────────────────────────────────────

  group('InsightDetailState defaults', () {
    test('has sensible initial values', () {
      const state = InsightDetailState();
      expect(state.insight, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });

  group('InsightDetailState.copyWith', () {
    test('preserves all fields when called with no arguments', () {
      final insight = makeInsightDto();
      final state = InsightDetailState(
        insight: insight,
        isLoading: true,
        error: 'Network error',
      );

      final copy = state.copyWith();
      expect(copy.insight, same(insight));
      expect(copy.isLoading, isTrue);
      expect(copy.error, 'Network error');
    });

    // ── CRITICAL: S5-INT-001 bug-fix regression guard ─────────────────────
    // Before the fix, copyWith(error: null) was a no-op. After, it clears.
    test('error sentinel — null clears existing error', () {
      const state = InsightDetailState(error: 'Network timeout');
      final cleared = state.copyWith(error: null);
      expect(
        cleared.error,
        isNull,
        reason:
            'Regression guard for S5-INT-001 fix: '
            'after a successful retry the detail screen must not remain '
            'stuck showing the stale error.',
      );
    });

    test('error sentinel — omitting preserves existing error', () {
      const state = InsightDetailState(error: 'Network timeout');
      final copy = state.copyWith(isLoading: true);
      expect(copy.error, 'Network timeout');
    });

    test('error sentinel — setting a new error replaces old one', () {
      const state = InsightDetailState(error: 'old error');
      final copy = state.copyWith(error: 'new error');
      expect(copy.error, 'new error');
    });

    test('successful retry sequence produces clean state', () {
      // Simulates: initial error → retry starts → retry succeeds
      const initialError = InsightDetailState(error: 'Network error');

      // Step 1: retry begins — isLoading: true, error should clear
      final loading = initialError.copyWith(isLoading: true, error: null);
      expect(loading.isLoading, isTrue);
      expect(
        loading.error,
        isNull,
        reason: 'Error must be cleared when load() begins its retry.',
      );

      // Step 2: load succeeds — insight is set, isLoading: false
      final insight = makeInsightDto();
      final success = loading.copyWith(insight: insight, isLoading: false);
      expect(success.insight, insight);
      expect(success.isLoading, isFalse);
      expect(
        success.error,
        isNull,
        reason: 'Final success state must have no error.',
      );
    });
  });
}
