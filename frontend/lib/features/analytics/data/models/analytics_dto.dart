class MemberStatsDto {
  const MemberStatsDto({
    required this.userId,
    required this.statMonth,
    required this.eventsAttended,
    required this.attendanceRate,
    required this.challengesJoined,
    required this.progressLogsCount,
    required this.recognitionsReceived,
    required this.recognitionsGiven,
    required this.postsCount,
    required this.compositeScore,
    this.fullName,
    this.avatarUrl,
  });

  final String userId;
  final String statMonth;
  final int eventsAttended;
  final double attendanceRate;
  final int challengesJoined;
  final int progressLogsCount;
  final int recognitionsReceived;
  final int recognitionsGiven;
  final int postsCount;
  final double compositeScore;
  final String? fullName;
  final String? avatarUrl;

  factory MemberStatsDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return MemberStatsDto(
      userId: json['user_id'] as String,
      statMonth: json['stat_month'] as String,
      eventsAttended: json['events_attended'] as int,
      attendanceRate: (json['attendance_rate'] as num).toDouble(),
      challengesJoined: json['challenges_joined'] as int,
      progressLogsCount: json['progress_logs_count'] as int,
      recognitionsReceived: json['recognitions_received'] as int,
      recognitionsGiven: json['recognitions_given'] as int,
      postsCount: json['posts_count'] as int,
      compositeScore: (json['composite_score'] as num).toDouble(),
      fullName: profiles is Map<String, dynamic>
          ? profiles['full_name'] as String?
          : null,
      avatarUrl: profiles is Map<String, dynamic>
          ? profiles['avatar_url'] as String?
          : null,
    );
  }
}

class HealthScoreDto {
  const HealthScoreDto({
    required this.scoreMonth,
    required this.score,
    required this.activeMemberCount,
    required this.avgAttendanceRate,
    required this.challengeEngagementRate,
    required this.recognitionActivityRate,
    required this.participationRate,
  });

  final String scoreMonth;
  final double score;
  final int activeMemberCount;
  final double avgAttendanceRate;
  final double challengeEngagementRate;
  final double recognitionActivityRate;
  final double participationRate;

  factory HealthScoreDto.fromJson(Map<String, dynamic> json) {
    return HealthScoreDto(
      scoreMonth: json['score_month'] as String,
      score: (json['score'] as num).toDouble(),
      activeMemberCount: json['active_member_count'] as int,
      avgAttendanceRate: (json['avg_attendance_rate'] as num).toDouble(),
      challengeEngagementRate:
          (json['challenge_engagement_rate'] as num).toDouble(),
      recognitionActivityRate:
          (json['recognition_activity_rate'] as num).toDouble(),
      participationRate: (json['participation_rate'] as num).toDouble(),
    );
  }
}
