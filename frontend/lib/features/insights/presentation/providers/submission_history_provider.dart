import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/insights/data/models/insight_raw_dto.dart';
import 'package:manager_connect/features/insights/data/repositories/insight_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'submission_history_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class SubmissionHistoryState {
  const SubmissionHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<InsightRawDto> items;
  final bool isLoading;
  final String? error;

  SubmissionHistoryState copyWith({
    List<InsightRawDto>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) => SubmissionHistoryState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error == _sentinel ? this.error : error as String?,
  );
}

const _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Notifier — auto-dispose: clean state each time the history screen opens
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class SubmissionHistoryNotifier extends _$SubmissionHistoryNotifier {
  InsightRepository? _repo;

  @override
  SubmissionHistoryState build() {
    _repo = InsightRepository(ref.watch(supabaseClientProvider));
    return const SubmissionHistoryState();
  }

  Future<void> load(String userId) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo!.getSubmissionHistory(userId);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo!.getSubmissionHistory(userId);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> getPublishedId(String rawId) =>
      _repo!.getPublishedInsightId(rawId);
}
