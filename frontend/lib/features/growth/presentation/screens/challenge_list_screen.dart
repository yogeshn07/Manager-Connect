import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/growth/data/models/challenge_dto.dart';
import 'package:manager_connect/features/growth/presentation/providers/challenge_provider.dart';
import 'package:manager_connect/features/growth/presentation/screens/create_challenge_screen.dart';
import 'package:manager_connect/features/growth/presentation/screens/challenge_achievements_screen.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class ChallengeListScreen extends ConsumerStatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  ConsumerState<ChallengeListScreen> createState() =>
      _ChallengeListScreenState();
}

class _ChallengeListScreenState extends ConsumerState<ChallengeListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(challengeListProvider.notifier).load();
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  IconData _typeIcon(String type) {
    return switch (type) {
      'fitness'  => Icons.fitness_center,
      'wellness' => Icons.spa,
      _          => Icons.emoji_events,
    };
  }

  Color _typeIconColor(String type) {
    return switch (type) {
      'fitness'  => MCColors.primaryMid,
      'wellness' => MCColors.success,
      _          => MCColors.textMuted,
    };
  }

  Color _typeIconBg(String type) {
    return switch (type) {
      'fitness'  => MCColors.primaryPale,
      'wellness' => MCColors.successBg,
      _          => MCColors.borderLight,
    };
  }

  String _typeLabel(String type) {
    return switch (type) {
      'fitness'  => 'Fitness',
      'wellness' => 'Wellness',
      _          => type,
    };
  }

  String _toTitleCase(String raw) => raw
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String _formatDate(String dateStr) {
    try {
      return DateFormat('MMM d').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  void _showCreateChallenge() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateChallengeScreen(),
    );
  }

  void _confirmDelete(ChallengeDto challenge) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete challenge?'),
        content: Text('This will permanently delete "${challenge.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(challengeListProvider.notifier).delete(challenge.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeListProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: MCAmbientIdentityBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(state),
              _buildTabRow(state),
              _buildCreateButton(),
              Expanded(child: _buildBody(state)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(ChallengeListState state) {
    return Container(
      height: MCSpacing.topBarHeight,
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(
          bottom: BorderSide(color: MCColors.borderLight),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: MCSpacing.pageH),
      child: Row(
        children: [
          Expanded(child: Text('Challenges', style: MCTypography.h3)),
          if (state.tabIndex == 0) _buildTogglePill(state),
        ],
      ),
    );
  }

  Widget _buildTogglePill(ChallengeListState state) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: MCColors.background,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        border: Border.all(color: MCColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pillSegment(
            label: 'Active',
            selected: !state.showCompleted,
            onTap: () {
              if (state.showCompleted) {
                ref.read(challengeListProvider.notifier).toggleCompleted();
              }
            },
          ),
          _pillSegment(
            label: 'Completed',
            selected: state.showCompleted,
            onTap: () {
              if (!state.showCompleted) {
                ref.read(challengeListProvider.notifier).toggleCompleted();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _pillSegment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? MCColors.primaryMid : Colors.transparent,
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: MCTypography.labelSm.copyWith(
            color: selected ? Colors.white : MCColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Create button (pinned below tabs) ──────────────────────────────────────

  Widget _buildCreateButton() {
    return Container(
      color: MCColors.card,
      padding: const EdgeInsets.fromLTRB(MCSpacing.pageH, 10, MCSpacing.pageH, 10),
      child: MCPrimaryButton(
        label: '+ Create Challenge',
        onPressed: _showCreateChallenge,
      ),
    );
  }

  // ── Tab row ────────────────────────────────────────────────────────────────

  Widget _buildTabRow(ChallengeListState state) {
    return Container(
      color: MCColors.card,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            _tabPill(
              label: 'Challenges',
              selected: state.tabIndex == 0,
              onTap: () => ref.read(challengeListProvider.notifier).setTabIndex(0),
            ),
            const SizedBox(width: 8),
            _tabPill(
              label: 'Challenges Joined',
              selected: state.tabIndex == 1,
              onTap: () => ref.read(challengeListProvider.notifier).setTabIndex(1),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChallengeAchievementsScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: MCColors.card,
                  borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                  border: Border.all(color: MCColors.border),
                ),
                child: Text(
                  'Recognition',
                  style: MCTypography.labelSm.copyWith(
                    color: MCColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? MCColors.primaryMid : MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
          border: selected ? null : Border.all(color: MCColors.border),
        ),
        child: Text(
          label,
          style: MCTypography.labelSm.copyWith(
            color: selected ? Colors.white : MCColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(ChallengeListState state) {
    if (state.isLoading && state.active.isEmpty && state.completed.isEmpty) {
      return const LoadingState();
    }

    if (state.error != null && state.active.isEmpty && state.completed.isEmpty) {
      return ErrorState(
        message: 'Failed to load challenges',
        onRetry: () => ref.read(challengeListProvider.notifier).load(),
      );
    }

    if (state.tabIndex == 1) {
      return _buildChallengeList(
        state.joined,
        state,
        emptyWidget: _buildEmptyJoinedState(),
      );
    }

    final challenges = state.showCompleted ? state.completed : state.active;
    return _buildChallengeList(
      challenges,
      state,
      emptyWidget: _buildEmptyState(state.showCompleted),
    );
  }

  Widget _buildChallengeList(
    List<ChallengeDto> challenges,
    ChallengeListState state, {
    required Widget emptyWidget,
  }) {
    if (challenges.isEmpty) return emptyWidget;
    return RefreshIndicator(
      onRefresh: () => ref.read(challengeListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          MCSpacing.pageH,
          MCSpacing.sm,
          MCSpacing.pageH,
          MCSpacing.sm,
        ),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < challenges.length - 1 ? MCSpacing.sm : 0,
            ),
            child: _buildChallengeCard(challenges[index], state),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool showCompleted) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.rocket_launch_outlined,
            size: 48,
            color: MCColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text('No challenges', style: MCTypography.h4),
          const SizedBox(height: 4),
          Text(
            showCompleted
                ? 'Completed challenges will appear here'
                : 'Create a challenge above to get started',
            style: MCTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyJoinedState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.group_outlined,
            size: 48,
            color: MCColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text('No joined challenges', style: MCTypography.h4),
          const SizedBox(height: 4),
          const Text(
            'Join a challenge to see it here',
          ),
        ],
      ),
    );
  }

  // ── Challenge card ─────────────────────────────────────────────────────────

  Widget _buildChallengeCard(ChallengeDto challenge, ChallengeListState state) {
    final icon = _typeIcon(challenge.challengeType);
    final iconColor = _typeIconColor(challenge.challengeType);
    final iconBg = _typeIconBg(challenge.challengeType);
    final typeLabel = _typeLabel(challenge.challengeType);
    final isActive = challenge.status == 'active';

    return GestureDetector(
      onTap: () => context.push('/growth/challenge/${challenge.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          border: Border.all(color: MCColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(MCSpacing.cardPadH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + title + status + 3-dot menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: MCTypography.h4,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(challenge.status),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: MCColors.textMuted),
                  padding: EdgeInsets.zero,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete challenge',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') _confirmDelete(challenge);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Type + goal chips row
            Row(
              children: [
                _buildSmallChip(typeLabel),
                const SizedBox(width: 6),
                _buildSmallChip(
                  _toTitleCase(challenge.goalType.replaceAll('_', ' ')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Author row
            Row(
              children: [
                _authorAvatar(challenge),
                const SizedBox(width: 6),
                Text(
                  challenge.authorName ?? 'Unknown',
                  style: MCTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Date range
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: MCColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(challenge.startDate)} – ${_formatDate(challenge.endDate)}',
                  style: MCTypography.caption,
                ),
              ],
            ),
            // Progress bar for active challenges
            if (isActive) ...[
              const SizedBox(height: 10),
              _buildProgressBar(challenge, state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _authorAvatar(ChallengeDto challenge) {
    const size = 20.0;
    final url = challenge.authorAvatarUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => MCAvatar(
            initials: _initials(challenge.authorName),
            size: size,
            backgroundColor: MCColors.primary,
          ),
          errorWidget: (_, __, ___) => MCAvatar(
            initials: _initials(challenge.authorName),
            size: size,
            backgroundColor: MCColors.primary,
          ),
        ),
      );
    }
    return MCAvatar(
      initials: _initials(challenge.authorName),
      size: size,
      backgroundColor: MCColors.primary,
    );
  }

  Widget _buildStatusPill(String status) {
    final (label, bg, fg) = switch (status) {
      'active'   => ('Active', MCColors.successBg, MCColors.success),
      'ended'    => ('Ended', MCColors.borderLight, MCColors.textMuted),
      'upcoming' => ('Upcoming', MCColors.amberLight, MCColors.amberDark),
      _          => (status, MCColors.borderLight, MCColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: MCTypography.overline.copyWith(color: fg),
      ),
    );
  }

  Widget _buildSmallChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MCColors.background,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: MCTypography.overline,
      ),
    );
  }

  Widget _buildProgressBar(ChallengeDto challenge, ChallengeListState state) {
    final fraction = state.progressFraction(
        challenge.id, challenge.selectedTasks);
    return ClipRRect(
      borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 4,
        backgroundColor: MCColors.borderLight,
        valueColor: AlwaysStoppedAnimation<Color>(
          fraction >= 1.0 ? MCColors.success : MCColors.primaryMid,
        ),
      ),
    );
  }
}
