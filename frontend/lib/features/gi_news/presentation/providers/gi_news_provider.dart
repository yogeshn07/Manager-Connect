import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/gi_news/data/models/gi_news_item.dart';
import 'package:manager_connect/features/gi_news/data/services/gi_news_service.dart';

part 'gi_news_provider.g.dart';

class GINewsFeedState {
  const GINewsFeedState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.topicFilter,
  });

  final List<GINewsItem> items;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final String? topicFilter;

  List<GINewsItem> get displayed => topicFilter == null
      ? items
      : items.where((i) => i.topic == topicFilter).toList();

  GINewsFeedState copyWith({
    List<GINewsItem>? items,
    bool? isLoading,
    bool? isRefreshing,
    Object? error = _sentinel,
    Object? topicFilter = _sentinel,
  }) {
    return GINewsFeedState(
      items:         items         ?? this.items,
      isLoading:     isLoading     ?? this.isLoading,
      isRefreshing:  isRefreshing  ?? this.isRefreshing,
      error:         error == _sentinel ? this.error : error as String?,
      topicFilter:   topicFilter == _sentinel ? this.topicFilter : topicFilter as String?,
    );
  }
}

const _sentinel = Object();

@Riverpod(keepAlive: true)
class GiNewsFeedNotifier extends _$GiNewsFeedNotifier {
  final _service = GINewsService();

  @override
  GINewsFeedState build() => const GINewsFeedState();

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.fetchAll();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true);
    try {
      final items = await _service.fetchAll();
      state = state.copyWith(items: items, isRefreshing: false, error: null);
    } catch (_) {
      state = state.copyWith(isRefreshing: false);
    }
  }

  void setTopic(String? topic) {
    state = state.copyWith(topicFilter: topic);
  }
}
