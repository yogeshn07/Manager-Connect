class ChallengeTask {
  const ChallengeTask({
    required this.id,
    required this.label,
    required this.target,
    required this.unit,
  });

  final String id;
  final String label;
  final double target;
  final String unit;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'target': target,
        'unit': unit,
      };

  factory ChallengeTask.fromJson(Map<String, dynamic> json) {
    return ChallengeTask(
      id: json['id'] as String,
      label: json['label'] as String,
      target: (json['target'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }
}

class ChallengeDto {
  const ChallengeDto({
    required this.id,
    required this.createdBy,
    required this.title,
    this.description,
    required this.challengeType,
    required this.goalType,
    this.goalDescription,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
    this.selectedTasks = const [],
  });

  final String id;
  final String createdBy;
  final String title;
  final String? description;
  final String challengeType;
  final String goalType;
  final String? goalDescription;
  final String startDate;
  final String endDate;
  final String status;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final List<ChallengeTask> selectedTasks;

  bool get isEnded => status == 'ended';

  factory ChallengeDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    final tasksRaw = json['selected_tasks'];
    final tasks = <ChallengeTask>[];
    if (tasksRaw is List) {
      for (final t in tasksRaw) {
        if (t is Map<String, dynamic>) {
          try {
            tasks.add(ChallengeTask.fromJson(t));
          } catch (_) {}
        }
      }
    }
    return ChallengeDto(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      challengeType: json['challenge_type'] as String,
      goalType: json['goal_type'] as String,
      goalDescription: json['goal_description'] as String?,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: profiles is Map<String, dynamic>
          ? profiles['full_name'] as String?
          : null,
      authorAvatarUrl: profiles is Map<String, dynamic>
          ? profiles['avatar_url'] as String?
          : null,
      selectedTasks: tasks,
    );
  }
}

class ParticipantDto {
  const ParticipantDto({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.joinedAt,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String challengeId;
  final String userId;
  final DateTime joinedAt;
  final String? fullName;
  final String? avatarUrl;

  factory ParticipantDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return ParticipantDto(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      fullName: profiles is Map<String, dynamic>
          ? profiles['full_name'] as String?
          : null,
      avatarUrl: profiles is Map<String, dynamic>
          ? profiles['avatar_url'] as String?
          : null,
    );
  }
}

class ProgressLogDto {
  const ProgressLogDto({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.logDate,
    required this.value,
    this.note,
    this.subtaskId = '',
  });

  final String id;
  final String challengeId;
  final String userId;
  final String logDate;
  final double value;
  final String? note;
  final String subtaskId;

  factory ProgressLogDto.fromJson(Map<String, dynamic> json) {
    return ProgressLogDto(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      logDate: json['log_date'] as String,
      value: (json['value'] as num).toDouble(),
      note: json['note'] as String?,
      subtaskId: json['subtask_id'] as String? ?? '',
    );
  }
}
