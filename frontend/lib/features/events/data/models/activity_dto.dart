class ActivityAuthor {
  const ActivityAuthor({required this.fullName, this.avatarUrl});

  final String fullName;
  final String? avatarUrl;

  factory ActivityAuthor.fromJson(Map<String, dynamic> json) {
    return ActivityAuthor(
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ActivityDto {
  const ActivityDto({
    required this.id,
    required this.createdBy,
    required this.title,
    this.description,
    required this.eventCategory,
    this.eventType,
    this.location,
    required this.eventDate,
    this.costNote,
    required this.status,
    required this.createdAt,
    this.author,
  });

  final String id;
  final String createdBy;
  final String title;
  final String? description;
  final String eventCategory;
  final String? eventType;
  final String? location;
  final DateTime eventDate;
  final String? costNote;
  final String status;
  final DateTime createdAt;
  final ActivityAuthor? author;

  bool get isCancelled => status == 'cancelled';
  bool get isPast => eventDate.isBefore(DateTime.now());

  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return ActivityDto(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventCategory: json['event_category'] as String,
      eventType: json['event_type'] as String?,
      location: json['location'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      costNote: json['cost_note'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: profiles is Map<String, dynamic>
          ? ActivityAuthor.fromJson(profiles)
          : null,
    );
  }
}

class RsvpDto {
  const RsvpDto({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.status,
    this.userName,
    this.userAvatar,
  });

  final String id;
  final String activityId;
  final String userId;
  final String status;
  final String? userName;
  final String? userAvatar;

  factory RsvpDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return RsvpDto(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      userName: profiles is Map<String, dynamic>
          ? profiles['full_name'] as String?
          : null,
      userAvatar: profiles is Map<String, dynamic>
          ? profiles['avatar_url'] as String?
          : null,
    );
  }
}

class ActivityUpdateDto {
  const ActivityUpdateDto({
    required this.id,
    required this.activityId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String activityId;
  final String authorId;
  final String content;
  final DateTime createdAt;

  factory ActivityUpdateDto.fromJson(Map<String, dynamic> json) {
    return ActivityUpdateDto(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
