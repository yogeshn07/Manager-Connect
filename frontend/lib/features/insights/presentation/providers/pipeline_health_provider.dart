import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/insights/data/models/pipeline_health_dto.dart';
import 'package:manager_connect/features/insights/data/repositories/insight_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'pipeline_health_provider.g.dart';

class PipelineHealthState {
  const PipelineHealthState({
    this.health,
    this.failedJobs = const [],
    this.stalledJobs = const [],
    this.isLoading = false,
    this.error,
  });

  final PipelineHealthDto? health;
  final List<PipelineJobDto> failedJobs;
  final List<PipelineJobDto> stalledJobs;
  final bool isLoading;
  final String? error;

  PipelineHealthState copyWith({
    PipelineHealthDto? health,
    List<PipelineJobDto>? failedJobs,
    List<PipelineJobDto>? stalledJobs,
    bool? isLoading,
    Object? error = _sentinel,
  }) => PipelineHealthState(
    health: health ?? this.health,
    failedJobs: failedJobs ?? this.failedJobs,
    stalledJobs: stalledJobs ?? this.stalledJobs,
    isLoading: isLoading ?? this.isLoading,
    error: error == _sentinel ? this.error : error as String?,
  );
}

const _sentinel = Object();

@riverpod
class PipelineHealthNotifier extends _$PipelineHealthNotifier {
  InsightRepository? _repo;

  @override
  PipelineHealthState build() {
    _repo = InsightRepository(ref.watch(supabaseClientProvider));
    return const PipelineHealthState();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _fetchAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _fetchAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchAll() async {
    final healthFut = _repo!.getPipelineHealth();
    final failedFut = _repo!.listFailedJobs();
    final stalledFut = _repo!.listStalledJobs();
    final health = await healthFut;
    final failedJobs = await failedFut;
    final stalledJobs = await stalledFut;
    state = state.copyWith(
      health: health,
      failedJobs: failedJobs,
      stalledJobs: stalledJobs,
      isLoading: false,
    );
  }
}
