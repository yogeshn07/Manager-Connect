import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/growth/data/models/challenge_dto.dart';
import 'package:manager_connect/features/growth/data/repositories/challenge_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'challenge_provider.g.dart';

class ChallengeListState {
  const ChallengeListState({
    this.active = const [],
    this.completed = const [],
    this.isLoading = false,
    this.showCompleted = false,
    this.error,
  });

  final List<ChallengeDto> active;
  final List<ChallengeDto> completed;
  final bool isLoading;
  final bool showCompleted;
  final String? error;

  ChallengeListState copyWith({
    List<ChallengeDto>? active,
    List<ChallengeDto>? completed,
    bool? isLoading,
    bool? showCompleted,
    String? Function()? error,
  }) {
    return ChallengeListState(
      active: active ?? this.active,
      completed: completed ?? this.completed,
      isLoading: isLoading ?? this.isLoading,
      showCompleted: showCompleted ?? this.showCompleted,
      error: error != null ? error() : this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class ChallengeListNotifier extends _$ChallengeListNotifier {
  ChallengeRepository? _repo;

  @override
  ChallengeListState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = ChallengeRepository(client);
    return const ChallengeListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final results = await Future.wait([
        _repo!.getActive(),
        _repo!.getCompleted(),
      ]);
      state = state.copyWith(
        active: results[0],
        completed: results[1],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        _repo!.getActive(),
        _repo!.getCompleted(),
      ]);
      state = state.copyWith(
        active: results[0],
        completed: results[1],
        error: () => null,
      );
    } catch (_) {}
  }

  void toggleCompleted() {
    state = state.copyWith(showCompleted: !state.showCompleted);
  }
}

class ChallengeDetailState {
  const ChallengeDetailState({
    this.challenge,
    this.participants = const [],
    this.progressLogs = const [],
    this.isLoading = false,
    this.error,
  });

  final ChallengeDto? challenge;
  final List<ParticipantDto> participants;
  final List<ProgressLogDto> progressLogs;
  final bool isLoading;
  final String? error;

  Map<String, double> get leaderboard {
    final totals = <String, double>{};
    for (final log in progressLogs) {
      totals[log.userId] = (totals[log.userId] ?? 0) + log.value;
    }
    return Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  ChallengeDetailState copyWith({
    ChallengeDto? challenge,
    List<ParticipantDto>? participants,
    List<ProgressLogDto>? progressLogs,
    bool? isLoading,
    String? Function()? error,
  }) {
    return ChallengeDetailState(
      challenge: challenge ?? this.challenge,
      participants: participants ?? this.participants,
      progressLogs: progressLogs ?? this.progressLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

@riverpod
class ChallengeDetailNotifier extends _$ChallengeDetailNotifier {
  ChallengeRepository? _repo;

  @override
  ChallengeDetailState build(String challengeId) {
    final client = ref.watch(supabaseClientProvider);
    _repo = ChallengeRepository(client);
    return const ChallengeDetailState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final results = await Future.wait([
        _repo!.getChallenge(challengeId),
        _repo!.getParticipants(challengeId),
        _repo!.getProgressLogs(challengeId),
      ]);
      state = state.copyWith(
        challenge: results[0] as ChallengeDto,
        participants: results[1] as List<ParticipantDto>,
        progressLogs: results[2] as List<ProgressLogDto>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> join(String userId) async {
    try {
      await _repo!.join(challengeId: challengeId, userId: userId);
      final participants = await _repo!.getParticipants(challengeId);
      state = state.copyWith(participants: participants);
    } catch (_) {}
  }

  Future<void> leave(String userId) async {
    try {
      await _repo!.leave(challengeId: challengeId, userId: userId);
      state = state.copyWith(
        participants:
            state.participants.where((p) => p.userId != userId).toList(),
      );
    } catch (_) {}
  }

  Future<void> logProgress({
    required String userId,
    required String participantId,
    required String logDate,
    required double value,
    String? note,
  }) async {
    try {
      await _repo!.logProgress(
        challengeId: challengeId,
        userId: userId,
        challengeParticipantId: participantId,
        logDate: logDate,
        value: value,
        note: note,
      );
      final logs = await _repo!.getProgressLogs(challengeId);
      state = state.copyWith(progressLogs: logs);
    } catch (_) {}
  }
}
