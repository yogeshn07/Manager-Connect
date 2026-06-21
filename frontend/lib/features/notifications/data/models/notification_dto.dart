class NotificationItemDto {
  const NotificationItemDto({
    required this.id,
    required this.recipientId,
    this.actorId,
    required this.type,
    required this.title,
    required this.body,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String recipientId;
  final String? actorId;
  final String type;
  final String title;
  final String body;
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  factory NotificationItemDto.fromJson(Map<String, dynamic> json) {
    return NotificationItemDto(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      actorId: json['actor_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
