class InvitationDto {
  const InvitationDto({
    required this.id,
    required this.inviteeName,
    this.inviteeEmail,
    this.inviteePhone,
    required this.status,
    required this.invitedBy,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String inviteeName;
  final String? inviteeEmail;
  final String? inviteePhone;
  final String status;
  final String invitedBy;
  final DateTime expiresAt;
  final DateTime createdAt;

  factory InvitationDto.fromJson(Map<String, dynamic> json) {
    return InvitationDto(
      id: json['id'] as String,
      inviteeName: json['invitee_name'] as String,
      inviteeEmail: json['invitee_email'] as String?,
      inviteePhone: json['invitee_phone'] as String?,
      status: json['status'] as String,
      invitedBy: json['invited_by'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FlaggedContentDto {
  const FlaggedContentDto({
    required this.id,
    required this.reporterId,
    required this.contentType,
    required this.contentId,
    this.reason,
    required this.status,
    required this.createdAt,
    this.reporterName,
  });

  final String id;
  final String reporterId;
  final String contentType;
  final String contentId;
  final String? reason;
  final String status;
  final DateTime createdAt;
  final String? reporterName;

  factory FlaggedContentDto.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return FlaggedContentDto(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      contentType: json['content_type'] as String,
      contentId: json['content_id'] as String,
      reason: json['reason'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reporterName: profiles is Map<String, dynamic>
          ? profiles['full_name'] as String?
          : null,
    );
  }
}
