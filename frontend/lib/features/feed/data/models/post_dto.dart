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
  });

  final String id;
  final String authorId;
  final String content;
  final bool isDeleted;
  final DateTime createdAt;
  final PostAuthor? author;
  final bool isPinned;

  factory PostDto.fromJson(Map<String, dynamic> json, {bool isPinned = false}) {
    final profiles = json['profiles'];
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
  });

  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final PostAuthor? author;

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
