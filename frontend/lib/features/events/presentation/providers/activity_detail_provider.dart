import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/events/data/models/activity_dto.dart';
import 'package:manager_connect/features/events/data/repositories/activity_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'activity_detail_provider.g.dart';

class ActivityDetailState {
  const ActivityDetailState({
    this.activity,
    this.rsvps = const [],
    this.updates = const [],
    this.isLoading = false,
    this.error,
  });

  final ActivityDto? activity;
  final List<RsvpDto> rsvps;
  final List<ActivityUpdateDto> updates;
  final bool isLoading;
  final String? error;

  int get goingCount => rsvps.where((r) => r.status == 'going').length;
  int get maybeCount => rsvps.where((r) => r.status == 'maybe').length;

  ActivityDetailState copyWith({
    ActivityDto? activity,
    List<RsvpDto>? rsvps,
    List<ActivityUpdateDto>? updates,
    bool? isLoading,
    String? Function()? error,
  }) {
    return ActivityDetailState(
      activity: activity ?? this.activity,
      rsvps: rsvps ?? this.rsvps,
      updates: updates ?? this.updates,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

@riverpod
class ActivityDetailNotifier extends _$ActivityDetailNotifier {
  ActivityRepository? _repo;

  @override
  ActivityDetailState build(String activityId) {
    final client = ref.watch(supabaseClientProvider);
    _repo = ActivityRepository(client);
    return const ActivityDetailState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final results = await Future.wait([
        _repo!.getActivity(activityId),
        _repo!.getRsvps(activityId),
        _repo!.getUpdates(activityId),
      ]);
      state = state.copyWith(
        activity: results[0] as ActivityDto,
        rsvps: results[1] as List<RsvpDto>,
        updates: results[2] as List<ActivityUpdateDto>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> rsvp({
    required String userId,
    required String status,
  }) async {
    try {
      await _repo!.upsertRsvp(
        activityId: activityId,
        userId: userId,
        status: status,
      );
      final rsvps = await _repo!.getRsvps(activityId);
      state = state.copyWith(rsvps: rsvps);
    } catch (_) {}
  }

  Future<void> withdrawRsvp(String userId) async {
    try {
      await _repo!.withdrawRsvp(activityId: activityId, userId: userId);
      state = state.copyWith(
        rsvps: state.rsvps.where((r) => r.userId != userId).toList(),
      );
    } catch (_) {}
  }

  Future<void> cancelActivity() async {
    try {
      await _repo!.cancelActivity(activityId);
      final activity = await _repo!.getActivity(activityId);
      state = state.copyWith(activity: activity);
    } catch (_) {}
  }

  Future<void> postUpdate(String content) async {
    try {
      await _repo!.postUpdate(activityId: activityId, content: content);
      final updates = await _repo!.getUpdates(activityId);
      state = state.copyWith(updates: updates);
    } catch (_) {}
  }
}
