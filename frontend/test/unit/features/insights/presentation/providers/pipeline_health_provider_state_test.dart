import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/pipeline_health_provider.dart';

import '../../../../../helpers/insight_fixtures.dart';

void main() {
  group('PipelineHealthState defaults', () {
    test('has sensible initial values', () {
      const state = PipelineHealthState();
      expect(state.health, isNull);
      expect(state.failedJobs, isEmpty);
      expect(state.stalledJobs, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });

  group('PipelineHealthState.copyWith', () {
    test('preserves all fields when called with no arguments', () {
      final health = makePipelineHealthDto();
      final failedJobs = [makePipelineJobDto(status: 'ai_error')];
      final stalledJobs = [makePipelineJobDto(status: 'validated')];
      final state = PipelineHealthState(
        health: health,
        failedJobs: failedJobs,
        stalledJobs: stalledJobs,
        isLoading: true,
        error: 'RLS error',
      );

      final copy = state.copyWith();
      expect(copy.health, same(health));
      expect(copy.failedJobs, same(failedJobs));
      expect(copy.stalledJobs, same(stalledJobs));
      expect(copy.isLoading, isTrue);
      expect(copy.error, 'RLS error');
    });

    test('error sentinel — null clears the error', () {
      const state = PipelineHealthState(error: 'RLS error');
      expect(state.copyWith(error: null).error, isNull);
    });

    test('error sentinel — omitting preserves the error', () {
      const state = PipelineHealthState(error: 'RLS error');
      expect(state.copyWith(isLoading: false).error, 'RLS error');
    });

    test('refresh sequence produces clean state with new data', () {
      final oldHealth = makePipelineHealthDto(failedEnrichmentCount: 3);
      final initialState = PipelineHealthState(
        health: oldHealth,
        error: 'stale error',
      );

      // Refresh starts: isLoading true, error cleared
      final refreshing = initialState.copyWith(isLoading: true, error: null);
      expect(refreshing.isLoading, isTrue);
      expect(refreshing.error, isNull);
      // Old health still shown while refreshing (enables shimmer-free refresh)
      expect(refreshing.health, same(oldHealth));

      // Refresh succeeds: new health, isLoading false
      final newHealth = makePipelineHealthDto(failedEnrichmentCount: 0);
      final newFailed = [makePipelineJobDto()];
      final done = refreshing.copyWith(
        health: newHealth,
        failedJobs: newFailed,
        stalledJobs: const [],
        isLoading: false,
      );
      expect(done.health, same(newHealth));
      expect(done.failedJobs, same(newFailed));
      expect(done.stalledJobs, isEmpty);
      expect(done.isLoading, isFalse);
      expect(done.error, isNull);
    });
  });
}
