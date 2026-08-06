import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/admin/presentation/providers/admin_provider.dart';
import 'package:manager_connect/features/auth/data/models/profile_dto.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_badges.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class MemberManagementScreen extends ConsumerStatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  ConsumerState<MemberManagementScreen> createState() =>
      _MemberManagementScreenState();
}

class _MemberManagementScreenState
    extends ConsumerState<MemberManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(memberManagementProvider.notifier).load();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProfileDto> _filteredMembers(List<ProfileDto> members) {
    return members.where((m) {
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Active' && m.isActive) ||
          (_filter == 'Inactive' && !m.isActive);
      final matchesSearch = _searchQuery.isEmpty ||
          m.fullName.toLowerCase().contains(_searchQuery) ||
          (m.title?.toLowerCase().contains(_searchQuery) ?? false);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberManagementProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: MCColors.card,
      padding: const EdgeInsets.only(
        left: MCSpacing.pageH,
        right: MCSpacing.pageH,
        top: 10,
        bottom: 14,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MCColors.background,
                borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: MCColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: MCSpacing.sm),
          Text('Members', style: MCTypography.h3),
        ],
      ),
    );
  }

  Widget _buildBody(MemberManagementState state) {
    if (state.isLoading && state.members.isEmpty) {
      return const LoadingState(message: 'Loading members...');
    }

    if (state.error != null && state.members.isEmpty) {
      return ErrorState(
        message: 'Failed to load members',
        onRetry: () => ref.read(memberManagementProvider.notifier).load(),
      );
    }

    final filtered = _filteredMembers(state.members);

    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterPills(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(memberManagementProvider.notifier).load(),
            child: filtered.isEmpty
                ? _buildEmptyState()
                : _buildMemberList(filtered),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MCSpacing.pageH,
        MCSpacing.md,
        MCSpacing.pageH,
        MCSpacing.xs,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: MCColors.background,
          borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
          border: Border.all(
            color: MCColors.border,
            width: MCSpacing.borderMed,
          ),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: MCSpacing.sm),
              child: Icon(
                Icons.search_rounded,
                size: 18,
                color: MCColors.textMuted,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: MCTypography.body,
                decoration: InputDecoration(
                  hintText: 'Search members…',
                  hintStyle:
                      MCTypography.body.copyWith(color: MCColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: _searchController.clear,
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: MCSpacing.sm),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: MCColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: MCSpacing.sm,
      ),
      child: Row(
        children: ['All', 'Active', 'Inactive'].map((f) {
          final active = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: MCSpacing.xs),
            child: MCFilterChip(
              label: f,
              active: active,
              onTap: () => setState(() => _filter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 56,
            color: MCColors.textMuted,
          ),
          const SizedBox(height: MCSpacing.md),
          Text(
            'No members found',
            style: MCTypography.h4.copyWith(color: MCColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(List<ProfileDto> members) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        MCSpacing.pageH,
        0,
        MCSpacing.pageH,
        MCSpacing.xl,
      ),
      itemCount: 1,
      itemBuilder: (context, _) => Container(
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          boxShadow: MCColors.cardShadow,
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: members.asMap().entries.map((entry) {
            final isLast = entry.key == members.length - 1;
            return _buildMemberRow(entry.value, isLast: isLast);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMemberRow(ProfileDto member, {required bool isLast}) {
    final initials = _initials(member.fullName);
    final avatarColor = member.appRole == 'admin'
        ? MCColors.primaryMid
        : MCColors.primaryLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _showMemberActions(member),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MCSpacing.pageH,
              vertical: MCSpacing.sm,
            ),
            child: Row(
              children: [
                MCAvatar(
                  initials: initials,
                  size: MCAvatar.md,
                  backgroundColor: avatarColor,
                ),
                const SizedBox(width: MCSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: MCTypography.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (member.title != null && member.title!.isNotEmpty)
                        Text(
                          member.title!,
                          style: MCTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: MCSpacing.xs),
                _buildRoleChip(member.appRole),
                const SizedBox(width: MCSpacing.xs),
                member.isActive
                    ? MCStatusPill.success('Active')
                    : MCStatusPill.error('Inactive'),
                const SizedBox(width: MCSpacing.xs),
                const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: MCColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: MCColors.borderLight),
      ],
    );
  }

  Widget _buildRoleChip(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? MCColors.primaryPale : MCColors.borderLight,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(
        role,
        style: MCTypography.overline.copyWith(
          color: isAdmin ? MCColors.primaryMid : MCColors.textSecondary,
        ),
      ),
    );
  }

  void _showMemberActions(ProfileDto member) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MCColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MCSpacing.radiusLg),
        ),
      ),
      builder: (bottomSheetContext) {
        final isActive = member.isActive;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: MCSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MCColors.border,
                    borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                  ),
                ),
                const SizedBox(height: MCSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: MCSpacing.pageH),
                  child: Row(
                    children: [
                      MCAvatar(
                        initials: _initials(member.fullName),
                        size: MCAvatar.md,
                        backgroundColor: member.appRole == 'admin'
                            ? MCColors.primaryMid
                            : MCColors.primaryLight,
                      ),
                      const SizedBox(width: MCSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.fullName, style: MCTypography.h4),
                            if (member.title != null)
                              Text(member.title!, style: MCTypography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MCSpacing.md),
                const Divider(height: 1, color: MCColors.borderLight),
                ListTile(
                  leading: Icon(
                    isActive ? Icons.person_off_outlined : Icons.person_add_outlined,
                    color: isActive ? MCColors.error : MCColors.success,
                  ),
                  title: Text(
                    isActive ? 'Deactivate Member' : 'Reactivate Member',
                    style: MCTypography.label.copyWith(
                      color: isActive ? MCColors.error : MCColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _confirmToggleActive(member);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined,
                      color: MCColors.error),
                  title: Text(
                    'Remove Member',
                    style: MCTypography.label.copyWith(color: MCColors.error),
                  ),
                  subtitle: Text(
                    'Anonymizes profile permanently',
                    style: MCTypography.caption,
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _confirmRemove(member);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmToggleActive(ProfileDto member) async {
    final isActive = member.isActive;
    final action = isActive ? 'deactivate' : 'reactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} member?'),
        content: Text('Are you sure you want to $action ${member.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: isActive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (isActive) {
        await ref.read(memberManagementProvider.notifier).deactivate(member.id);
      } else {
        await ref.read(memberManagementProvider.notifier).reactivate(member.id);
      }
      if (mounted) {
        showSuccessToast(context, 'Member ${action}d successfully');
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Failed to $action member');
      }
    }
  }

  Future<void> _confirmRemove(ProfileDto member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member permanently?'),
        content: Text(
          "This will anonymize ${member.fullName}'s profile to "
          '"Removed Member" and deactivate their account. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(memberManagementProvider.notifier).remove(member.id);
      if (mounted) {
        showSuccessToast(context, 'Member removed and anonymized');
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Failed to remove member');
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || name.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
