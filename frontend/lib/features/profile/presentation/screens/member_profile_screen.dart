import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_badges.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

final _memberProfileProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, profileId) async {
    final client = ref.watch(supabaseClientProvider);
    final response = await client
        .from('profiles')
        .select('id, full_name, avatar_url, title, bio, interest_tags, created_at, app_role')
        .eq('id', profileId)
        .maybeSingle();
    return response;
  },
);

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({required this.profileId, super.key});
  final String profileId;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_memberProfileProvider(profileId));

    return Scaffold(
      backgroundColor: MCColors.background,
      appBar: AppBar(
        backgroundColor: MCColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
          color: MCColors.textPrimary,
        ),
        title: Text('Profile', style: MCTypography.h3),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: MCColors.borderLight),
        ),
      ),
      body: MCAmbientIdentityBackground(
        child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: MCColors.primary)),
        error: (_, __) => Center(
          child: Text('Could not load profile', style: MCTypography.caption),
        ),
        data: (data) {
          if (data == null) {
            return Center(
              child: Text('Member not found', style: MCTypography.caption),
            );
          }
          final name = data['full_name'] as String? ?? 'Member';
          final avatarUrl = data['avatar_url'] as String?;
          final title = data['title'] as String?;
          final bio = data['bio'] as String?;
          final role = data['app_role'] as String? ?? 'member';
          final tags = (data['interest_tags'] as List?)?.cast<String>() ?? [];
          final createdAt = data['created_at'] as String?;
          String? memberSince;
          if (createdAt != null) {
            final dt = DateTime.tryParse(createdAt);
            if (dt != null) memberSince = '${_monthName(dt.month)} ${dt.year}';
          }

          return ListView(
            padding: const EdgeInsets.all(MCSpacing.pageH),
            children: [
              const SizedBox(height: 12),
              Center(
                child: MCAvatar(
                  initials: _initials(name),
                  size: 72,
                  backgroundColor: MCColors.primary,
                  avatarUrl: avatarUrl,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(name, style: MCTypography.h2)),
              if (title != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(title,
                      style: MCTypography.body
                          .copyWith(color: MCColors.textSecondary)),
                ),
              ],
              if (role == 'admin') ...[
                const SizedBox(height: 8),
                Center(child: MCStatusPill.info('Admin')),
              ],
              if (memberSince != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text('Member since $memberSince',
                      style: MCTypography.caption),
                ),
              ],
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(MCSpacing.cardPadH),
                  decoration: BoxDecoration(
                    color: MCColors.card,
                    borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
                    border: Border.all(color: MCColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About', style: MCTypography.h4),
                      const SizedBox(height: 8),
                      Text(bio, style: MCTypography.body),
                    ],
                  ),
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(MCSpacing.cardPadH),
                  decoration: BoxDecoration(
                    color: MCColors.card,
                    borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
                    border: Border.all(color: MCColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Interests', style: MCTypography.h4),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: MCColors.primaryPale,
                                    borderRadius:
                                        BorderRadius.circular(MCSpacing.radiusPill),
                                  ),
                                  child: Text(t,
                                      style: MCTypography.labelSm
                                          .copyWith(color: MCColors.primaryMid)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
        ),
      ),
    );
  }
}
