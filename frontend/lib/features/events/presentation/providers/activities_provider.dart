import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/events/data/models/activity_dto.dart';
import 'package:manager_connect/features/events/data/repositories/activity_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'activities_provider.g.dart';

class ActivitiesState {
  const ActivitiesState({
    this.upcoming = const [],
    this.past = const [],
    this.isLoading = false,
    this.error,
    this.categoryFilter,
    this.showPast = false,
  });

  final List<ActivityDto> upcoming;
  final List<ActivityDto> past;
  final bool isLoading;
  final String? error;
  final String? categoryFilter;
  final bool showPast;

  ActivitiesState copyWith({
    List<ActivityDto>? upcoming,
    List<ActivityDto>? past,
    bool? isLoading,
    String? Function()? error,
    String? Function()? categoryFilter,
    bool? showPast,
  }) {
    return ActivitiesState(
      upcoming: upcoming ?? this.upcoming,
      past: past ?? this.past,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      categoryFilter:
          categoryFilter != null ? categoryFilter() : this.categoryFilter,
      showPast: showPast ?? this.showPast,
    );
  }
}

@Riverpod(keepAlive: true)
class ActivitiesNotifier extends _$ActivitiesNotifier {
  ActivityRepository? _repo;

  @override
  ActivitiesState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = ActivityRepository(client);
    return const ActivitiesState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final upcoming =
          await _repo!.getUpcoming(category: state.categoryFilter);
      final past = await _repo!.getPast();
      state = state.copyWith(
        upcoming: upcoming,
        past: past,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> refresh() async {
    try {
      final upcoming =
          await _repo!.getUpcoming(category: state.categoryFilter);
      final past = await _repo!.getPast();
      state = state.copyWith(
        upcoming: upcoming,
        past: past,
        error: () => null,
      );
    } catch (_) {}
  }

  void setCategory(String? category) {
    state = state.copyWith(categoryFilter: () => category);
    load();
  }

  void togglePast() {
    state = state.copyWith(showPast: !state.showPast);
  }
}
