import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/auth/data/models/profile_dto.dart';
import 'package:manager_connect/features/auth/data/repositories/auth_repository.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/profile/presentation/providers/profile_provider.dart';
import 'package:manager_connect/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? get _userId {
    final authState = ref.read(authProvider);
    if (authState is AppAuthStateAuthenticated) {
      return authState.session.userId;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final uid = _userId;
      if (uid != null) ref.read(profileProvider(uid).notifier).load();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final client = ref.read(supabaseClientProvider);
    await AuthRepository(client).signOut();
    if (mounted) ref.read(authProvider.notifier).setUnauthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _userId;
    if (uid == null) return const LoadingState();

    final state = ref.watch(profileProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (state.profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditProfile(state.profile!),
            ),
        ],
      ),
      body: _buildBody(state, uid),
    );
  }

  Widget _buildBody(ProfileState state, String uid) {
    if (state.isLoading && state.profile == null) {
      return const LoadingState();
    }
    if (state.error != null && state.profile == null) {
      return ErrorState(
        message: 'Failed to load profile',
        onRetry: () => ref.read(profileProvider(uid).notifier).load(),
      );
    }
    if (state.profile == null) return const LoadingState();

    final profile = state.profile!;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider(uid).notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(profile, theme),
          const SizedBox(height: 24),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            Text(profile.bio!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],
          if (profile.interestTags.isNotEmpty) ...[
            Text('Interests', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: profile.interestTags
                  .map((t) => Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          _buildInfoSection(profile, theme),
          const Divider(height: 32),
          _buildNotificationPrefs(profile, uid, theme),
          const Divider(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(ProfileDto profile, ThemeData theme) {
    final initial = profile.fullName.isNotEmpty
        ? profile.fullName[0].toUpperCase()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            initial,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.fullName, style: theme.textTheme.titleLarge),
              if (profile.title != null)
                Text(
                  profile.title!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(
                profile.appRole == 'admin' ? 'Admin' : 'Member',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ProfileDto profile, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (profile.createdAt != null)
          ListTile(
            dense: true,
            leading: const Icon(Icons.calendar_today, size: 18),
            title: const Text('Member since'),
            trailing: Text(
              DateFormat('MMM d, yyyy').format(profile.createdAt!.toLocal()),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.verified_user, size: 18),
          title: const Text('Status'),
          trailing: Text(
            profile.isActive ? 'Active' : 'Deactivated',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationPrefs(
    ProfileDto profile,
    String uid,
    ThemeData theme,
  ) {
    const prefLabels = {
      'activity_reminders': 'Activity Reminders',
      'new_activities': 'New Activities',
      'recognitions_received': 'Recognitions Received',
      'new_challenges': 'New Challenges',
      'challenge_reminders': 'Challenge Reminders',
      'mentions': 'Mentions',
      'comments_on_my_posts': 'Comments on My Posts',
      'poll_reminders': 'Poll Reminders',
      'connect_buddy_updates': 'Connect Buddy Updates',
    };

    final prefs = Map<String, bool>.from(profile.notificationPreferences);
    for (final key in prefLabels.keys) {
      prefs.putIfAbsent(key, () => true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notification Preferences', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...prefLabels.entries.map((entry) {
          return SwitchListTile(
            dense: true,
            title: Text(entry.value),
            value: prefs[entry.key] ?? true,
            onChanged: (value) {
              final updated = Map<String, bool>.from(prefs);
              updated[entry.key] = value;
              ref
                  .read(profileProvider(uid).notifier)
                  .updateNotificationPreferences(updated);
            },
          );
        }),
      ],
    );
  }

  void _openEditProfile(ProfileDto profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditProfileScreen(profile: profile),
    ).then((_) {
      final uid = _userId;
      if (uid != null) ref.read(profileProvider(uid).notifier).load();
    });
  }
}
