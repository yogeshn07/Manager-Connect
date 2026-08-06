class PollVoteDto {
  const PollVoteDto({required this.optionId, required this.userId, this.voterName});
  final String optionId;
  final String userId;
  final String? voterName;

  factory PollVoteDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return PollVoteDto(
      optionId: json['poll_option_id'] as String,
      userId: json['user_id'] as String,
      voterName: profiles is Map ? profiles['full_name'] as String? : null,
    );
  }
}

class PollOptionDto {
  const PollOptionDto({required this.id, required this.optionText, required this.displayOrder, required this.votes});
  final String id;
  final String optionText;
  final int displayOrder;
  final List<PollVoteDto> votes;

  factory PollOptionDto.fromJson(Map<String, dynamic> json) => PollOptionDto(
        id: json['id'] as String,
        optionText: json['option_text'] as String,
        displayOrder: json['display_order'] as int? ?? 0,
        votes: (json['poll_votes'] as List? ?? [])
            .map((v) => PollVoteDto.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

class PollDto {
  const PollDto({
    required this.id,
    required this.question,
    required this.closesAt,
    required this.isClosed,
    required this.options,
    this.activityId,
  });
  final String id;
  final String question;
  final DateTime closesAt;
  final bool isClosed;
  final List<PollOptionDto> options;
  final String? activityId;

  bool get isExpired => DateTime.now().isAfter(closesAt);
  bool get isActive => !isClosed && !isExpired;
  int get totalVotes => options.fold(0, (sum, o) => sum + o.votes.length);

  factory PollDto.fromJson(Map<String, dynamic> json) {
    final options = (json['poll_options'] as List? ?? [])
        .map((o) => PollOptionDto.fromJson(o as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return PollDto(
      id: json['id'] as String,
      question: json['question'] as String,
      closesAt: DateTime.parse(json['closes_at'] as String),
      isClosed: json['is_closed'] as bool? ?? false,
      options: options,
      activityId: json['activity_id'] as String?,
    );
  }
}

class PostAuthor {
  const PostAuthor({
    required this.fullName,
    this.avatarUrl,
    required this.isSystemAccount,
  });

  final String fullName;
  final String? avatarUrl;
  final bool isSystemAccount;

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isSystemAccount: json['is_system_account'] as bool? ?? false,
    );
  }
}

class PostDto {
  const PostDto({
    required this.id,
    required this.authorId,
    required this.content,
    required this.isDeleted,
    required this.createdAt,
    this.author,
    this.isPinned = false,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.postType = 'post',
    this.imageUrls = const [],
    this.poll,
  });

  final String id;
  final String authorId;
  final String content;
  final bool isDeleted;
  final DateTime createdAt;
  final PostAuthor? author;
  final bool isPinned;
  final int reactionCount;
  final int commentCount;
  final String postType;
  final List<String> imageUrls;
  final PollDto? poll;

  static int _parseCount(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      final c = (raw.first as Map?)?.values.first;
      if (c is int) return c;
      if (c is String) return int.tryParse(c) ?? 0;
    }
    return 0;
  }

  factory PostDto.fromJson(Map<String, dynamic> json, {bool isPinned = false}) {
    final profiles = json['profiles'];
    final pollData = json['polls'];
    return PostDto(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: profiles is Map<String, dynamic>
          ? PostAuthor.fromJson(profiles)
          : null,
      isPinned: isPinned,
      reactionCount: _parseCount(json['post_reactions']),
      commentCount: _parseCount(json['comments']),
      postType: json['post_type'] as String? ?? 'post',
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? const [],
      poll: pollData is Map<String, dynamic> ? PollDto.fromJson(pollData) : null,
    );
  }
}

class StatusDto {
  const StatusDto({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.authorName,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String? imageUrl;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? authorName;
  final String? avatarUrl;

  factory StatusDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return StatusDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String?,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      authorName: profiles is Map ? profiles['full_name'] as String? : null,
      avatarUrl: profiles is Map ? profiles['avatar_url'] as String? : null,
    );
  }
}

class CommentDto {
  const CommentDto({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.author,
    this.parentCommentId,
  });

  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final PostAuthor? author;
  final String? parentCommentId;

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return CommentDto(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: profiles is Map<String, dynamic>
          ? PostAuthor.fromJson(profiles)
          : null,
      parentCommentId: json['parent_comment_id'] as String?,
    );
  }
}

class ReactionDto {
  const ReactionDto({
    required this.id,
    required this.postId,
    required this.userId,
    required this.emoji,
  });

  final String id;
  final String postId;
  final String userId;
  final String emoji;

  factory ReactionDto.fromJson(Map<String, dynamic> json) {
    return ReactionDto(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      emoji: json['emoji'] as String,
    );
  }
}
