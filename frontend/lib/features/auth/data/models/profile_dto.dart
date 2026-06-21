class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.title,
    this.bio,
    required this.interestTags,
    required this.appRole,
    required this.isActive,
    required this.isSystemAccount,
    required this.onboardingCompleted,
    this.notificationPreferences = const {},
    this.lastActiveAt,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? title;
  final String? bio;
  final List<String> interestTags;
  final String appRole;
  final bool isActive;
  final bool isSystemAccount;
  final bool onboardingCompleted;
  final Map<String, bool> notificationPreferences;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final prefs = json['notification_preferences'];
    return ProfileDto(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      title: json['title'] as String?,
      bio: json['bio'] as String?,
      interestTags:
          (json['interest_tags'] as List<dynamic>?)?.cast<String>() ?? [],
      appRole: json['app_role'] as String,
      isActive: json['is_active'] as bool,
      isSystemAccount: json['is_system_account'] as bool,
      onboardingCompleted: json['onboarding_completed'] as bool,
      notificationPreferences: prefs is Map<String, dynamic>
          ? prefs.map((k, v) => MapEntry(k, v as bool? ?? true))
          : {},
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
