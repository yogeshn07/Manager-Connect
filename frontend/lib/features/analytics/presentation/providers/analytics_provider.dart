import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/analytics/data/models/analytics_dto.dart';
import 'package:manager_connect/features/analytics/data/repositories/analytics_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'analytics_provider.g.dart';

class AnalyticsState {
  const AnalyticsState({
    this.personalStats = const [],
    this.healthScores = const [],
    this.isLoading = false,
    this.showCommunity = false,
    this.error,
  });

  final List<MemberStatsDto> personalStats;
  final List<HealthScoreDto> healthScores;
  final bool isLoading;
  final bool showCommunity;
  final String? error;

  HealthScoreDto? get latestHealthScore =>
      healthScores.isNotEmpty ? healthScores.first : null;

  AnalyticsState copyWith({
    List<MemberStatsDto>? personalStats,
    List<HealthScoreDto>? healthScores,
    bool? isLoading,
    bool? showCommunity,
    String? Function()? error,
  }) {
    return AnalyticsState(
      personalStats: personalStats ?? this.personalStats,
      healthScores: healthScores ?? this.healthScores,
      isLoading: isLoading ?? this.isLoading,
      showCommunity: showCommunity ?? this.showCommunity,
      error: error != null ? error() : this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class AnalyticsNotifier extends _$AnalyticsNotifier {
  AnalyticsRepository? _repo;

  @override
  AnalyticsState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = AnalyticsRepository(client);
    return const AnalyticsState();
  }

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final results = await Future.wait([
        _repo!.getPersonalStats(userId),
        _repo!.getHealthScores(),
      ]);
      state = state.copyWith(
        personalStats: results[0] as List<MemberStatsDto>,
        healthScores: results[1] as List<HealthScoreDto>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  void toggleView() {
    state = state.copyWith(showCommunity: !state.showCommunity);
  }
}

class RankingsState {
  const RankingsState({
    this.monthlyRankings = const [],
    this.allTimeRankings = const [],
    this.isLoading = false,
    this.showAllTime = false,
    this.error,
  });

  final List<MemberStatsDto> monthlyRankings;
  final List<AllTimeRanking> allTimeRankings;
  final bool isLoading;
  final bool showAllTime;
  final String? error;

  RankingsState copyWith({
    List<MemberStatsDto>? monthlyRankings,
    List<AllTimeRanking>? allTimeRankings,
    bool? isLoading,
    bool? showAllTime,
    String? Function()? error,
  }) {
    return RankingsState(
      monthlyRankings: monthlyRankings ?? this.monthlyRankings,
      allTimeRankings: allTimeRankings ?? this.allTimeRankings,
      isLoading: isLoading ?? this.isLoading,
      showAllTime: showAllTime ?? this.showAllTime,
      error: error != null ? error() : this.error,
    );
  }
}

class AllTimeRanking {
  const AllTimeRanking({
    required this.userId,
    required this.totalScore,
    this.fullName,
    this.avatarUrl,
  });

  final String userId;
  final double totalScore;
  final String? fullName;
  final String? avatarUrl;
}

@riverpod
class RankingsNotifier extends _$RankingsNotifier {
  AnalyticsRepository? _repo;

  @override
  RankingsState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = AnalyticsRepository(client);
    return const RankingsState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final now = DateTime.now();
      final currentMonth =
          DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];

      final results = await Future.wait([
        _repo!.getMonthlyRankings(currentMonth),
        _repo!.getAllStats(),
      ]);

      final monthly = results[0];
      final allStats = results[1];

      final totals = <String, _Accumulator>{};
      for (final s in allStats) {
        final acc = totals.putIfAbsent(
          s.userId,
          () => _Accumulator(
            fullName: s.fullName,
            avatarUrl: s.avatarUrl,
          ),
        );
        acc.totalScore += s.compositeScore;
      }

      final allTime = totals.entries
          .map((e) => AllTimeRanking(
                userId: e.key,
                totalScore: e.value.totalScore,
                fullName: e.value.fullName,
                avatarUrl: e.value.avatarUrl,
              ))
          .toList()
        ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

      state = state.copyWith(
        monthlyRankings: monthly,
        allTimeRankings: allTime,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  void toggleView() {
    state = state.copyWith(showAllTime: !state.showAllTime);
  }
}

class _Accumulator {
  _Accumulator({this.fullName, this.avatarUrl});
  final String? fullName;
  final String? avatarUrl;
  double totalScore = 0;
}
