import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/features/admin/data/repositories/admin_repository.dart';
import 'package:manager_connect/features/admin/presentation/providers/admin_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';
import 'package:manager_connect/core/errors/app_exception.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminDashboardProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: MCColors.card,
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Admin', style: MCTypography.h3),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MCColors.errorBg,
              borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
            ),
            child: Text(
              'Admin',
              style: MCTypography.pill.copyWith(color: MCColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AdminDashboardState state) {
    if (state.isLoading && state.counts.isEmpty) {
      return const LoadingState(message: 'Loading dashboard...');
    }

    if (state.error != null && state.counts.isEmpty) {
      return ErrorState(
        message: 'Failed to load dashboard',
        onRetry: () => ref.read(adminDashboardProvider.notifier).load(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminDashboardProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          MCSpacing.pageH,
          MCSpacing.sm,
          MCSpacing.pageH,
          MCSpacing.xl,
        ),
        children: [
          _buildStatsGrid(state.counts),
          const SizedBox(height: MCSpacing.xl),
          _buildSectionLabel('QUICK ACTIONS'),
          const SizedBox(height: MCSpacing.sm),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> counts) {
    final stats = <_StatItem>[
      _StatItem(
        icon: Icons.people_rounded,
        iconColor: MCColors.primaryMid,
        iconBg: MCColors.primaryPale,
        label: 'Total Members',
        value: '${counts['total_members'] ?? 0}',
      ),
      _StatItem(
        icon: Icons.mail_outline_rounded,
        iconColor: MCColors.amberDark,
        iconBg: MCColors.amberLight,
        label: 'Pending Invitations',
        value: '${counts['pending_invitations'] ?? 0}',
      ),
      _StatItem(
        icon: Icons.flag_outlined,
        iconColor: MCColors.error,
        iconBg: MCColors.errorBg,
        label: 'Flagged Content',
        value: '${counts['pending_flags'] ?? 0}',
      ),
      _StatItem(
        icon: Icons.fitness_center_rounded,
        iconColor: MCColors.success,
        iconBg: MCColors.successBg,
        label: 'Active Challenges',
        value: '${counts['total_challenges'] ?? 0}',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: MCSpacing.sm,
      crossAxisSpacing: MCSpacing.sm,
      childAspectRatio: 1.5,
      children: stats.map((s) => _StatCard(item: s)).toList(),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: MCTypography.overline.copyWith(
        letterSpacing: 0.1,
        color: MCColors.textMuted,
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    final tiles = <_TileData>[
      _TileData(
        icon: Icons.people_rounded,
        iconColor: MCColors.primaryMid,
        iconBg: MCColors.primaryPale,
        label: 'Members',
        onTap: () => context.push(RouteNames.adminMembers),
      ),
      _TileData(
        icon: Icons.mail_outline_rounded,
        iconColor: MCColors.amberDark,
        iconBg: MCColors.amberLight,
        label: 'Invitations',
        onTap: () => context.push('/admin/invitations'),
      ),
      _TileData(
        icon: Icons.flag_outlined,
        iconColor: MCColors.error,
        iconBg: MCColors.errorBg,
        label: 'Flagged Content',
        onTap: () => context.push(RouteNames.adminFlagged),
      ),
      _TileData(
        icon: Icons.calendar_today_rounded,
        iconColor: MCColors.primaryLight,
        iconBg: MCColors.primaryPale,
        label: 'Attendance',
        onTap: () => context.push(RouteNames.adminAttendance),
      ),
      _TileData(
        icon: Icons.push_pin_rounded,
        iconColor: MCColors.success,
        iconBg: MCColors.successBg,
        label: 'Post Announcement',
        onTap: _showPinDialog,
      ),
      _TileData(
        icon: Icons.rate_review_rounded,
        iconColor: MCColors.violet,
        iconBg: MCColors.violetLight,
        label: 'Insight Review',
        onTap: () => context.push(RouteNames.adminInsightReview),
      ),
      _TileData(
        icon: Icons.monitor_heart_rounded,
        iconColor: MCColors.success,
        iconBg: MCColors.successBg,
        label: 'Pipeline Health',
        onTap: () => context.push(RouteNames.adminInsightPipeline),
        isLast: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        boxShadow: MCColors.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: tiles.map(_buildTileRow).toList(),
      ),
    );
  }

  Widget _buildTileRow(_TileData tile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: tile.onTap,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: MCSpacing.pageH),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tile.iconBg,
                      borderRadius:
                          BorderRadius.circular(MCSpacing.radiusXs + 2),
                    ),
                    child: Icon(tile.icon, size: 18, color: tile.iconColor),
                  ),
                  const SizedBox(width: MCSpacing.sm),
                  Expanded(
                    child: Text(tile.label, style: MCTypography.label),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: MCColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!tile.isLast)
          const Divider(
            height: 1,
            thickness: 1,
            color: MCColors.borderLight,
          ),
      ],
    );
  }

  Future<void> _showPinDialog() async {
    final controller = TextEditingController();
    final postId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pin Announcement'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Post ID',
            hintText: 'Paste the post UUID to pin',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Pin'),
          ),
        ],
      ),
    );

    if (postId == null || postId.isEmpty || !mounted) return;

    try {
      final client = ref.read(supabaseClientProvider);
      final repo = AdminRepository(client);
      await repo.pinPost(postId);
      if (mounted) showSuccessToast(context, 'Post pinned to feed');
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to pin post');
    }
  }

  // ignore: unused_element
  Future<void> _confirmUnpin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpin announcement?'),
        content: const Text(
          'The current pinned post will be removed from the top of the feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unpin'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final client = ref.read(supabaseClientProvider);
      final repo = AdminRepository(client);
      await repo.unpinPost();
      if (mounted) showSuccessToast(context, 'Announcement unpinned');
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to unpin');
    }
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
}

class _TileData {
  const _TileData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;
  final bool isLast;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        boxShadow: MCColors.cardShadow,
      ),
      padding: const EdgeInsets.all(MCSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
            ),
            child: Icon(item.icon, size: 20, color: item.iconColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value, style: MCTypography.kpi),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: MCTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
