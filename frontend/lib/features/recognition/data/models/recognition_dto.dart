class RecognitionGiver {
  const RecognitionGiver({required this.fullName, this.avatarUrl});
  final String fullName;
  final String? avatarUrl;

  factory RecognitionGiver.fromJson(Map<String, dynamic> json) {
    return RecognitionGiver(
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class RecognitionRecipientDto {
  const RecognitionRecipientDto({
    required this.recipientId,
    this.fullName,
    this.avatarUrl,
  });
  final String recipientId;
  final String? fullName;
  final String? avatarUrl;

  factory RecognitionRecipientDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return RecognitionRecipientDto(
      recipientId: json['recipient_id'] as String,
      fullName:
          profiles is Map<String, dynamic> ? profiles['full_name'] as String? : null,
      avatarUrl:
          profiles is Map<String, dynamic> ? profiles['avatar_url'] as String? : null,
    );
  }
}

class RecognitionDto {
  const RecognitionDto({
    required this.id,
    required this.giverId,
    required this.categoryTag,
    required this.message,
    required this.createdAt,
    this.giver,
    this.recipients = const [],
  });

  final String id;
  final String giverId;
  final String categoryTag;
  final String message;
  final DateTime createdAt;
  final RecognitionGiver? giver;
  final List<RecognitionRecipientDto> recipients;

  factory RecognitionDto.fromJson(Map<String, dynamic> json) {
    final giverData = json['profiles'];
    final recipientsData = json['recognition_recipients'];
    return RecognitionDto(
      id: json['id'] as String,
      giverId: json['giver_id'] as String,
      categoryTag: json['category_tag'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      giver: giverData is Map<String, dynamic>
          ? RecognitionGiver.fromJson(giverData)
          : null,
      recipients: recipientsData is List
          ? recipientsData
              .map((r) =>
                  RecognitionRecipientDto.fromJson(r as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
