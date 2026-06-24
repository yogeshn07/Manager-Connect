import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/features/admin/data/repositories/admin_repository.dart';
import 'package:manager_connect/features/admin/presentation/providers/admin_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/toast.dart';
import 'package:manager_connect/core/errors/app_exception.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {
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
      appBar: AppBar(
        title: const Text('Admin'),
      ),
      body: _buildBody(state),
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
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsSection(state.counts),
          const SizedBox(height: 24),
          _buildNavigationSection(),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, int> counts) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people,
                label: 'Active Members',
                value: '${counts['active_members'] ?? 0}'
                    ' / ${counts['total_members'] ?? 0}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.mail_outline,
                label: 'Pending Invitations',
                value: '${counts['pending_invitations'] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.flag_outlined,
                label: 'Pending Flags',
                value: '${counts['pending_flags'] ?? 0}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.article_outlined,
                label: 'Total Posts',
                value: '${counts['total_posts'] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.event,
                label: 'Total Activities',
                value: '${counts['total_activities'] ?? 0}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.fitness_center,
                label: 'Total Challenges',
                value: '${counts['total_challenges'] ?? 0}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manage', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _NavigationTile(
          icon: Icons.people,
          title: 'Members',
          subtitle: 'View and manage all members',
          onTap: () => context.push(RouteNames.adminMembers),
        ),
        _NavigationTile(
          icon: Icons.mail_outline,
          title: 'Invitations',
          subtitle: 'Send and manage invitations',
          onTap: () => context.push('/admin/invitations'),
        ),
        _NavigationTile(
          icon: Icons.flag_outlined,
          title: 'Moderation',
          subtitle: 'Review flagged content',
          onTap: () => context.push(RouteNames.adminFlagged),
        ),
        _NavigationTile(
          icon: Icons.calendar_today,
          title: 'Attendance',
          subtitle: 'Record event attendance',
          onTap: () => context.push(RouteNames.adminAttendance),
        ),
        const SizedBox(height: 24),
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _NavigationTile(
          icon: Icons.push_pin,
          title: 'Pin Announcement',
          subtitle: 'Pin a post to the top of the feed',
          onTap: () => _showPinDialog(),
        ),
        _NavigationTile(
          icon: Icons.push_pin_outlined,
          title: 'Unpin Announcement',
          subtitle: 'Remove the current pinned post',
          onTap: () => _confirmUnpin(),
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

  Future<void> _confirmUnpin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpin announcement?'),
        content: const Text('The current pinned post will be removed from the top of the feed.'),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
