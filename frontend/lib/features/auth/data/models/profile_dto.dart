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

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
