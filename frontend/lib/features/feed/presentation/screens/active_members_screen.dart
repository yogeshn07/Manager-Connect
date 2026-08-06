import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/features/auth/data/models/profile_dto.dart';
import 'package:manager_connect/features/feed/presentation/providers/presence_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

final _activeMembersProvider = FutureProvider<List<ProfileDto>>((ref) async {
  final data = await Supabase.instance.client
      .from(Table.profiles)
      .select()
      .eq('is_system_account', false)
      .eq('is_active', true)
      .order('full_name');
  return (data as List)
      .map((e) => ProfileDto.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ActiveMembersScreen extends ConsumerWidget {
  const ActiveMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(_activeMembersProvider);
    final onlineIds = ref.watch(presenceProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      appBar: AppBar(
        backgroundColor: MCColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MCColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: membersAsync.whenOrNull(
          data: (members) {
            final onlineCount =
                members.where((m) => onlineIds.contains(m.id)).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Members', style: MCTypography.h3),
                Text(
                  '$onlineCount online now',
                  style: MCTypography.caption.copyWith(
                    color: MCColors.success,
                    height: 1.2,
                  ),
                ),
              ],
            );
          },
        ) ??
            Text('Active Members', style: MCTypography.h3),
      ),
      body: MCAmbientIdentityBackground(
        child: membersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: MCColors.primary),
        ),
        error: (_, __) => Center(
          child: Text('Failed to load members', style: MCTypography.body),
        ),
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Text('No members found', style: MCTypography.body),
            );
          }

          // Online first, then alphabetical within each group.
          final sorted = [...members]
            ..sort((a, b) {
              final aOn = onlineIds.contains(a.id);
              final bOn = onlineIds.contains(b.id);
              if (aOn == bOn) return a.fullName.compareTo(b.fullName);
              return aOn ? -1 : 1;
            });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: MCColors.borderLight,
              indent: 72,
            ),
            itemBuilder: (context, i) {
              final m = sorted[i];
              return _MemberTile(
                member: m,
                isOnline: onlineIds.contains(m.id),
              );
            },
          );
        },
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isOnline});
  final ProfileDto member;
  final bool isOnline;

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/${member.id}'),
      child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: 12,
      ),
      child: Row(
        children: [
          MCAvatar(
            initials: _initials(member.fullName),
            size: MCAvatar.md,
            statusDot: isOnline ? MCColors.success : MCColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: MCTypography.label),
                if (member.title != null && member.title!.isNotEmpty)
                  Text(member.title!, style: MCTypography.caption),
              ],
            ),
          ),
          _PresenceTag(isOnline: isOnline),
        ],
      ),
      ),
    );
  }
}

class _PresenceTag extends StatelessWidget {
  const _PresenceTag({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? MCColors.success : MCColors.energyRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: MCTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
