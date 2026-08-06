import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/features/growth/data/models/challenge_dto.dart';
import 'package:manager_connect/features/growth/data/repositories/challenge_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'challenge_provider.g.dart';

class ChallengeListState {
  const ChallengeListState({
    this.active = const [],
    this.completed = const [],
    this.joined = const [],
    this.isLoading = false,
    this.showCompleted = false,
    this.tabIndex = 0,
    this.progressMap = const {},
    this.error,
  });

  final List<ChallengeDto> active;
  final List<ChallengeDto> completed;
  final List<ChallengeDto> joined;
  final bool isLoading;
  final bool showCompleted;
  /// 0 = All Challenges, 1 = Challenges Joined
  final int tabIndex;
  final String? error;

  /// challengeId → subtaskId → cumulative value (current user only)
  final Map<String, Map<String, double>> progressMap;

  /// Fraction of subtasks completed (0.0–1.0) for the current user.
  double progressFraction(String challengeId, List<ChallengeTask> tasks) {
    if (tasks.isEmpty) return 0;
    final tp = progressMap[challengeId] ?? {};
    final done = tasks.where((t) => (tp[t.id] ?? 0) >= t.target).length;
    return done / tasks.length;
  }

  ChallengeListState copyWith({
    List<ChallengeDto>? active,
    List<ChallengeDto>? completed,
    List<ChallengeDto>? joined,
    bool? isLoading,
    bool? showCompleted,
    int? tabIndex,
    Map<String, Map<String, double>>? progressMap,
    String? Function()? error,
  }) {
    return ChallengeListState(
      active: active ?? this.active,
      completed: completed ?? this.completed,
      joined: joined ?? this.joined,
      isLoading: isLoading ?? this.isLoading,
      showCompleted: showCompleted ?? this.showCompleted,
      tabIndex: tabIndex ?? this.tabIndex,
      progressMap: progressMap ?? this.progressMap,
      error: error != null ? error() : this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class ChallengeListNotifier extends _$ChallengeListNotifier {
  ChallengeRepository? _repo;
  SupabaseClient? _client;
  RealtimeChannel? _channel;

  @override
  ChallengeListState build() {
    _client = ref.watch(supabaseClientProvider);
    _repo = ChallengeRepository(_client!);
    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });
    return const ChallengeListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final userId = _client?.auth.currentUser?.id;
      final (active, ended) = await (
        _repo!.getActive(),
        _repo!.getCompleted(),
      ).wait;
      final joined = userId != null
          ? await _repo!.getJoined(userId)
          : <ChallengeDto>[];
      await _applyProgress(active, ended, joined: joined);
      state = state.copyWith(isLoading: false);
      _subscribeRealtime();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> refresh() async {
    try {
      final userId = _client?.auth.currentUser?.id;
      final (active, ended) = await (
        _repo!.getActive(),
        _repo!.getCompleted(),
      ).wait;
      final joined = userId != null
          ? await _repo!.getJoined(userId)
          : <ChallengeDto>[];
      await _applyProgress(active, ended, joined: joined, clearError: true);
    } catch (_) {}
  }

  void setTabIndex(int index) {
    state = state.copyWith(tabIndex: index);
  }

  /// Cheaply re-checks progress for challenges already in state.
  /// Called from the detail screen after the user logs progress.
  Future<void> refreshProgress() async {
    final userId = _client?.auth.currentUser?.id;
    if (userId == null) return;

    // All challenges we know about that still have active status in DB
    final allActive = [
      ...state.active,
      ...state.completed.where((c) => c.status == 'active'),
    ];
    if (allActive.isEmpty) return;

    try {
      final progressMap = await _repo!.getMyProgressForChallenges(
        userId, allActive.map((c) => c.id).toList());

      final stillActive     = <ChallengeDto>[];
      final personallyDone  = <ChallengeDto>[];

      for (final c in allActive) {
        if (_isDone(c, progressMap)) {
          personallyDone.add(c);
        } else {
          stillActive.add(c);
        }
      }

      final dbEnded = state.completed.where((c) => c.status == 'ended').toList();

      state = state.copyWith(
        active: stillActive,
        completed: [...personallyDone, ...dbEnded],
        progressMap: progressMap,
      );
    } catch (_) {}
  }

  void toggleCompleted() {
    state = state.copyWith(showCompleted: !state.showCompleted);
  }

  Future<void> delete(String challengeId) async {
    try {
      await _client!.from(Table.challenges).delete().eq('id', challengeId);
      state = state.copyWith(
        active: state.active.where((c) => c.id != challengeId).toList(),
        completed: state.completed.where((c) => c.id != challengeId).toList(),
      );
    } catch (_) {}
  }

  // ── Realtime ───────────────────────────────────────────────────────────────

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('challenges:list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: Table.challenges,
          callback: (_) => refresh(),
        )
        .subscribe();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _applyProgress(
    List<ChallengeDto> allActive,
    List<ChallengeDto> ended, {
    List<ChallengeDto> joined = const [],
    bool clearError = false,
  }) async {
    final userId = _client?.auth.currentUser?.id;

    if (userId == null || allActive.isEmpty) {
      state = state.copyWith(
        active: allActive,
        completed: ended,
        joined: joined,
        progressMap: {},
        error: clearError ? () => null : null,
      );
      return;
    }

    final progressMap = await _repo!.getMyProgressForChallenges(
      userId, allActive.map((c) => c.id).toList());

    final stillActive    = <ChallengeDto>[];
    final personallyDone = <ChallengeDto>[];

    for (final c in allActive) {
      if (_isDone(c, progressMap)) {
        personallyDone.add(c);
      } else {
        stillActive.add(c);
      }
    }

    state = state.copyWith(
      active: stillActive,
      completed: [...personallyDone, ...ended],
      joined: joined,
      progressMap: progressMap,
      error: clearError ? () => null : null,
    );
  }

  bool _isDone(ChallengeDto c, Map<String, Map<String, double>> progressMap) {
    final tasks = c.selectedTasks;
    if (tasks.isEmpty) return false;
    final tp = progressMap[c.id] ?? {};
    return tasks.every((t) => (tp[t.id] ?? 0) >= t.target);
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

  // Cumulative progress per subtask_id for a given user
  Map<String, double> subtaskProgress(String userId) {
    final totals = <String, double>{};
    for (final log in progressLogs) {
      if (log.userId == userId) {
        totals[log.subtaskId] = (totals[log.subtaskId] ?? 0) + log.value;
      }
    }
    return totals;
  }

  // Set of subtask IDs that have been fully achieved by a given user
  Set<String> achievedSubtasks(String userId) {
    final progress = subtaskProgress(userId);
    final tasks = challenge?.selectedTasks ?? [];
    return {
      for (final t in tasks)
        if ((progress[t.id] ?? 0) >= t.target) t.id,
    };
  }

  // Overall leaderboard: total progress value per user (all subtasks summed)
  Map<String, double> get leaderboard {
    final totals = <String, double>{};
    for (final log in progressLogs) {
      totals[log.userId] = (totals[log.userId] ?? 0) + log.value;
    }
    return Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  // Per-user, per-date entries for the progress board.
  // When the same value is logged to multiple tasks on the same day, shows it
  // only once (uses the value from the first log seen for that date).
  List<({String userId, String logDate, double dayValue})> get dailyProgressBoard {
    final map = <String, Map<String, double>>{}; // userId -> logDate -> value
    for (final log in progressLogs) {
      (map[log.userId] ??= {}).putIfAbsent(log.logDate, () => log.value);
    }
    final entries = <({String userId, String logDate, double dayValue})>[];
    for (final ue in map.entries) {
      for (final de in ue.value.entries) {
        entries.add((userId: ue.key, logDate: de.key, dayValue: de.value));
      }
    }
    entries.sort((a, b) => b.logDate.compareTo(a.logDate));
    return entries;
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
  RealtimeChannel? _channel;

  @override
  ChallengeDetailState build(String challengeId) {
    final client = ref.watch(supabaseClientProvider);
    _repo = ChallengeRepository(client);
    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });
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
      _subscribeRealtime();
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
    required String subtaskId,
    String? note,
  }) async {
    try {
      await _repo!.logProgress(
        challengeId: challengeId,
        userId: userId,
        challengeParticipantId: participantId,
        logDate: logDate,
        value: value,
        subtaskId: subtaskId,
        note: note,
      );
      final logs = await _repo!.getProgressLogs(challengeId);
      state = state.copyWith(progressLogs: logs);
    } catch (_) {}
  }

  // ── Realtime ───────────────────────────────────────────────────────────────

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('challenge:detail:$challengeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: Table.challengeParticipants,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'challenge_id',
            value: challengeId,
          ),
          callback: (_) => _refreshParticipants(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: Table.progressLogs,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'challenge_id',
            value: challengeId,
          ),
          callback: (_) => _refreshProgressLogs(),
        )
        .subscribe();
  }

  Future<void> _refreshParticipants() async {
    try {
      final participants = await _repo!.getParticipants(challengeId);
      state = state.copyWith(participants: participants);
    } catch (_) {}
  }

  Future<void> _refreshProgressLogs() async {
    try {
      final logs = await _repo!.getProgressLogs(challengeId);
      state = state.copyWith(progressLogs: logs);
    } catch (_) {}
  }
}
