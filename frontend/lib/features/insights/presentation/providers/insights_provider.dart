import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/insights/data/models/insight_dto.dart';
import 'package:manager_connect/features/insights/data/repositories/insight_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'insights_provider.g.dart';

// ---------------------------------------------------------------------------
// Feed state
// ---------------------------------------------------------------------------

class InsightsFeedState {
  const InsightsFeedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.categoryFilter,
    this.hasMore = true,
    this.page = 0,
  });

  final List<InsightDto> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? categoryFilter;
  final bool hasMore;
  final int page;

  InsightsFeedState copyWith({
    List<InsightDto>? items,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _sentinel,
    Object? categoryFilter = _sentinel,
    bool? hasMore,
    int? page,
  }) {
    return InsightsFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error == _sentinel ? this.error : error as String?,
      categoryFilter: categoryFilter == _sentinel
          ? this.categoryFilter
          : categoryFilter as String?,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// Feed notifier — keepAlive so feed survives tab switches
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class InsightsFeedNotifier extends _$InsightsFeedNotifier {
  InsightRepository? _repo;

  @override
  InsightsFeedState build() {
    _repo = InsightRepository(ref.watch(supabaseClientProvider));
    return const InsightsFeedState();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo!.getFeed(
        category: state.categoryFilter,
        page: 0,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        page: 0,
        hasMore: items.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final more = await _repo!.getFeed(
        category: state.categoryFilter,
        page: nextPage,
      );
      state = state.copyWith(
        items: [...state.items, ...more],
        isLoadingMore: false,
        page: nextPage,
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const InsightsFeedState();
    await load();
  }

  void setCategory(String? category) {
    state = InsightsFeedState(categoryFilter: category);
    load();
  }
}

// ---------------------------------------------------------------------------
// Detail state
// ---------------------------------------------------------------------------

class InsightDetailState {
  const InsightDetailState({this.insight, this.isLoading = false, this.error});

  final InsightDto? insight;
  final bool isLoading;
  final String? error;

  InsightDetailState copyWith({
    InsightDto? insight,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return InsightDetailState(
      insight: insight ?? this.insight,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Detail notifier — auto-dispose per navigation stack entry
// ---------------------------------------------------------------------------

@riverpod
class InsightDetailNotifier extends _$InsightDetailNotifier {
  InsightRepository? _repo;

  @override
  InsightDetailState build() {
    _repo = InsightRepository(ref.watch(supabaseClientProvider));
    return const InsightDetailState();
  }

  Future<void> load(String insightId) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final insight = await _repo!.getInsight(insightId);
      state = state.copyWith(insight: insight, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
