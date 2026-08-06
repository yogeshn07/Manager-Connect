import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/features/auth/data/models/profile_dto.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_badges.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_cards.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ── Profile data model ────────────────────────────────────────────────────────

class ProfileData {
  const ProfileData({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.title,
    this.bio,
    this.interestTags = const [],
    this.memberSince,
    this.isActive = true,
    this.appRole = 'member',
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? title;
  final String? bio;
  final List<String> interestTags;
  final String? memberSince;
  final bool isActive;
  final String appRole;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length.clamp(0, 2)).toUpperCase();
  }
}

// ── Profile provider ──────────────────────────────────────────────────────────

final profileDataProvider = FutureProvider.autoDispose<ProfileData>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) throw Exception('Not authenticated');

  final userId = session.user.id;
  final response = await client
      .from('profiles')
      .select(
        'id, full_name, avatar_url, title, bio, interest_tags, created_at, is_active, app_role',
      )
      .eq('id', userId)
      .maybeSingle();

  if (response == null) {
    return ProfileData(id: userId, fullName: session.user.email ?? 'User');
  }

  final tags = response['interest_tags'];
  final tagsList = tags is List ? tags.cast<String>() : <String>[];

  String? memberSince;
  final createdAt = response['created_at'];
  if (createdAt != null) {
    final dt = DateTime.tryParse(createdAt.toString());
    if (dt != null) {
      memberSince = '${_monthName(dt.month)} ${dt.year}';
    }
  }

  return ProfileData(
    id: response['id'] as String,
    fullName: (response['full_name'] as String?) ?? 'User',
    avatarUrl: response['avatar_url'] as String?,
    title: response['title'] as String?,
    bio: response['bio'] as String?,
    interestTags: tagsList,
    memberSince: memberSince,
    isActive: (response['is_active'] as bool?) ?? true,
    appRole: (response['app_role'] as String?) ?? 'member',
  );
});

String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[(month - 1).clamp(0, 11)];
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notifyAnnouncements = true;
  bool _notifyEvents = true;
  bool _notifyRecognitions = true;
  bool _notifyComments = false;

  Future<void> _logout() async {
    final client = ref.read(supabaseClientProvider);
    await client.auth.signOut();
    ref.read(authProvider.notifier).setUnauthenticated();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final file = File(picked.path);
      final path = '$userId/avatar.jpg';
      await client.storage.from('avatars').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      final url = client.storage.from('avatars').getPublicUrl(path);
      await client.from('profiles').update({'avatar_url': url}).eq('id', userId);
      ref.invalidate(profileDataProvider);
    } catch (_) {}
  }

  Future<void> _editProfile() async {
    final profile = ref.read(profileDataProvider).asData?.value;
    if (profile == null) return;

    final dto = ProfileDto(
      id: profile.id,
      fullName: profile.fullName,
      title: profile.title,
      bio: profile.bio,
      interestTags: profile.interestTags,
      appRole: profile.appRole,
      isActive: profile.isActive,
      isSystemAccount: false,
      onboardingCompleted: true,
    );

    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: dto)),
    );

    ref.invalidate(profileDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileDataProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: MCAmbientIdentityBackground(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: MCSpacing.topBarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: MCColors.card,
                border: Border(
                  bottom: BorderSide(color: MCColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: MCSpacing.sm),
                  Expanded(child: Text('Profile', style: MCTypography.h3)),
                  IconButton(
                    onPressed: _editProfile,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 22,
                      color: MCColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: profileAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MCColors.primaryMid),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Could not load profile',
                    style: MCTypography.body.copyWith(
                      color: MCColors.textSecondary,
                    ),
                  ),
                ),
                data: _buildBody,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBody(ProfileData profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: MCSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(profile: profile, onEditPhoto: _pickAndUploadPhoto),
          const SizedBox(height: MCSpacing.sm),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            MCCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: MCTypography.h4),
                  const SizedBox(height: MCSpacing.xs),
                  Text(
                    profile.bio!,
                    style: MCTypography.body.copyWith(
                      color: MCColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MCSpacing.sm),
          ],
          if (profile.interestTags.isNotEmpty) ...[
            MCCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interests', style: MCTypography.h4),
                  const SizedBox(height: MCSpacing.sm),
                  Wrap(
                    spacing: MCSpacing.xs,
                    runSpacing: MCSpacing.xs,
                    children: profile.interestTags
                        .map((tag) => _InterestPill(label: tag))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MCSpacing.sm),
          ],
          MCCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications', style: MCTypography.h4),
                const SizedBox(height: MCSpacing.md),
                _NotifRow(
                  label: 'Announcements',
                  icon: Icons.campaign_outlined,
                  value: _notifyAnnouncements,
                  onChanged: (v) => setState(() => _notifyAnnouncements = v),
                ),
                const SizedBox(height: MCSpacing.sm),
                _NotifRow(
                  label: 'Events & Sessions',
                  icon: Icons.event_outlined,
                  value: _notifyEvents,
                  onChanged: (v) => setState(() => _notifyEvents = v),
                ),
                const SizedBox(height: MCSpacing.sm),
                _NotifRow(
                  label: 'Recognitions',
                  icon: Icons.emoji_events_outlined,
                  value: _notifyRecognitions,
                  onChanged: (v) => setState(() => _notifyRecognitions = v),
                ),
                const SizedBox(height: MCSpacing.sm),
                _NotifRow(
                  label: 'Comments & Replies',
                  icon: Icons.chat_bubble_outline,
                  value: _notifyComments,
                  onChanged: (v) => setState(() => _notifyComments = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: MCSpacing.md),
          MCGhostButton(
            label: 'Sign Out',
            icon: Icons.logout,
            onPressed: _logout,
          ),
          const SizedBox(height: MCSpacing.xl),
        ],
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile, this.onEditPhoto});
  final ProfileData profile;
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context) {
    return MCCard(
      child: Column(
        children: [
          const SizedBox(height: MCSpacing.xs),
          Stack(
            clipBehavior: Clip.none,
            children: [
              profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profile.avatarUrl!,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => MCAvatar(
                          initials: profile.initials,
                          size: 88,
                          backgroundColor: MCColors.primary,
                        ),
                        errorWidget: (_, __, ___) => MCAvatar(
                          initials: profile.initials,
                          size: 88,
                          backgroundColor: MCColors.primary,
                        ),
                      ),
                    )
                  : MCAvatar(
                      initials: profile.initials,
                      size: 88,
                      backgroundColor: MCColors.primary,
                    ),
              if (onEditPhoto != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onEditPhoto,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: MCColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MCSpacing.sm),
          Text(profile.fullName, style: MCTypography.h2),
          if (profile.title != null && profile.title!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.title!,
              style: MCTypography.body.copyWith(color: MCColors.textSecondary),
            ),
          ],
          const SizedBox(height: MCSpacing.sm),
          MCStatusPill(
            label: profile.appRole == 'admin' ? 'Admin' : 'Member',
            color: profile.appRole == 'admin'
                ? MCColors.amberDark
                : MCColors.primaryMid,
            bgColor: profile.appRole == 'admin'
                ? MCColors.amberLight
                : MCColors.primaryPale,
          ),
          const SizedBox(height: MCSpacing.lg),
          const Divider(color: MCColors.borderLight, height: 1, thickness: 1),
          const SizedBox(height: MCSpacing.md),
          Row(
            children: [
              _StatCell(
                label: 'Member Since',
                value: profile.memberSince ?? '—',
              ),
              _VertDivider(),
              _StatCell(
                label: 'Status',
                value: profile.isActive ? 'Active' : 'Inactive',
                valueColor:
                    profile.isActive ? MCColors.success : MCColors.textMuted,
              ),
              _VertDivider(),
              _StatCell(
                label: 'Role',
                value: profile.appRole == 'admin' ? 'Admin' : 'Member',
              ),
            ],
          ),
          const SizedBox(height: MCSpacing.xs),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: MCTypography.labelSm.copyWith(
              color: valueColor ?? MCColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: MCTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: MCColors.borderLight);
  }
}

// ── Interest pill ─────────────────────────────────────────────────────────────

class _InterestPill extends StatelessWidget {
  const _InterestPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: MCColors.primaryPale,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: MCTypography.labelSm.copyWith(color: MCColors.primaryMid),
      ),
    );
  }
}

// ── Notification toggle row ───────────────────────────────────────────────────

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MCColors.textSecondary),
        const SizedBox(width: MCSpacing.sm),
        Expanded(child: Text(label, style: MCTypography.body)),
        _MCToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ── Animated toggle ───────────────────────────────────────────────────────────

class _MCToggle extends StatelessWidget {
  const _MCToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? MCColors.primaryMid : MCColors.border,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 25,
            height: 25,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
