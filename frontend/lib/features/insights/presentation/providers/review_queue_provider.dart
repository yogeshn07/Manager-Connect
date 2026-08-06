import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/insights/data/models/insight_review_dto.dart';
import 'package:manager_connect/features/insights/data/repositories/insight_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'review_queue_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class ReviewQueueState {
  const ReviewQueueState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.processingId,
  });

  final List<InsightReviewDto> items;
  final bool isLoading;
  final String? error;

  /// The insight ID currently being approved or rejected (null = idle).
  final String? processingId;

  ReviewQueueState copyWith({
    List<InsightReviewDto>? items,
    bool? isLoading,
    Object? error = _sentinel,
    Object? processingId = _sentinel,
  }) => ReviewQueueState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error == _sentinel ? this.error : error as String?,
    processingId: processingId == _sentinel
        ? this.processingId
        : processingId as String?,
  );
}

const _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Notifier — auto-dispose: fresh state on each push to the review screen
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class ReviewQueueNotifier extends _$ReviewQueueNotifier {
  InsightRepository? _repo;

  @override
  ReviewQueueState build() {
    _repo = InsightRepository(ref.watch(supabaseClientProvider));
    return const ReviewQueueState();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo!.getReviewQueue();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo!.getReviewQueue();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Returns true on success; false if an error occurred.
  /// On success the item is removed from the local list immediately.
  Future<bool> approve(String insightId) async {
    state = state.copyWith(processingId: insightId, error: null);
    try {
      await _repo!.approveInsight(insightId);
      state = state.copyWith(
        items: state.items.where((i) => i.id != insightId).toList(),
        processingId: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(processingId: null);
      return false;
    }
  }

  /// Returns true on success; false if an error occurred.
  /// On success the item is removed from the local list immediately.
  Future<bool> reject(String insightId, {String? reason}) async {
    state = state.copyWith(processingId: insightId, error: null);
    try {
      await _repo!.rejectInsight(insightId, rejectionReason: reason);
      state = state.copyWith(
        items: state.items.where((i) => i.id != insightId).toList(),
        processingId: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(processingId: null);
      return false;
    }
  }
}
