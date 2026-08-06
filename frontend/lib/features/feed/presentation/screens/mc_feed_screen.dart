import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/feed/presentation/providers/presence_provider.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/notifications/presentation/providers/notification_provider.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/features/feed/presentation/providers/saved_posts_provider.dart';
import 'package:manager_connect/features/feed/presentation/providers/statuses_provider.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/features/feed/presentation/screens/create_post_screen.dart';
import 'package:manager_connect/features/feed/presentation/screens/create_story_screen.dart';
import 'package:manager_connect/features/feed/presentation/screens/search_sheet.dart';
import 'package:manager_connect/features/feed/presentation/screens/story_viewer_screen.dart';
import 'package:manager_connect/features/feed/presentation/widgets/feed_poll_widget.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_badges.dart';
import 'package:manager_connect/shared/widgets/mc/mc_cards.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_shimmer.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class MCFeedScreen extends ConsumerStatefulWidget {
  const MCFeedScreen({super.key});

  @override
  ConsumerState<MCFeedScreen> createState() => _MCFeedScreenState();
}

class _MCFeedScreenState extends ConsumerState<MCFeedScreen> {
  final _scroll = ScrollController();
  int _filterIdx = 0;
  List<PostDto> _savedPosts = [];
  bool _loadingSaved = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(feedProvider.notifier).loadFeed();
      final auth = ref.read(authProvider);
      if (auth is AppAuthStateAuthenticated) {
        ref.read(notificationProvider.notifier).load(auth.session.userId);
        ref
            .read(presenceProvider.notifier)
            .startTracking(
              auth.session.userId,
              auth.session.fullName ?? 'Member',
            );
      }
    });
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  void _onFilterChanged(int idx) {
    setState(() => _filterIdx = idx);
    if (idx == 3) _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    if (_loadingSaved) return;
    final auth = ref.read(authProvider);
    if (auth is! AppAuthStateAuthenticated) return;
    setState(() => _loadingSaved = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final posts = await FeedRepository(
        client,
      ).getSavedPosts(auth.session.userId);
      if (mounted) {
        setState(() {
          _savedPosts = posts;
          _loadingSaved = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SearchSheet(),
        fullscreenDialog: true,
      ),
    );
  }

  List<PostDto> _visiblePosts(FeedState state) {
    if (_filterIdx == 3) return _savedPosts;
    return switch (_filterIdx) {
      1 => state.posts.where((p) => p.postType == 'post').toList(),
      2 => state.posts.where((p) => p.postType == 'event').toList(),
      _ => state.posts,
    };
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final authState = ref.watch(authProvider);
    final userInitials = authState is AppAuthStateAuthenticated
        ? _initials(authState.session.fullName ?? 'U')
        : 'U';
    final userId = authState is AppAuthStateAuthenticated
        ? authState.session.userId
        : '';

    return Scaffold(
      backgroundColor: MCColors.background,
      body: MCAmbientIdentityBackground(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(onCreatePost: _showCreatePost, onSearch: _openSearch),
              Expanded(
                child: RefreshIndicator(
                  color: MCColors.primary,
                  onRefresh: () => ref.read(feedProvider.notifier).refresh(),
                  child: ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: MCSpacing.pageH,
                      vertical: MCSpacing.sm,
                    ),
                    itemCount: _itemCount(feedState),
                    itemBuilder: (ctx, i) =>
                        _buildItem(ctx, i, feedState, userInitials, userId),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _itemCount(FeedState state) {
    const headers = 3;
    final posts = _visiblePosts(state);
    if (_filterIdx != 3 && state.isLoading && state.posts.isEmpty) {
      return headers + 4;
    }
    if (_filterIdx == 3 && _loadingSaved) return headers + 1;
    if (posts.isEmpty) return headers + 1;
    return headers +
        posts.length +
        (state.isLoadingMore && _filterIdx == 0 ? 1 : 0) +
        1;
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    FeedState state,
    String userInitials,
    String userId,
  ) {
    // 0 — stories row
    if (index == 0) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _StoriesRow(),
      );
    }
    // 1 — filter chips + composer
    if (index == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterChipsRow(selected: _filterIdx, onChanged: _onFilterChanged),
            const SizedBox(height: 12),
            _ComposerCard(onTap: _showCreatePost, initials: userInitials),
          ],
        ),
      );
    }
    // 2 — section heading
    if (index == 2) {
      final label = switch (_filterIdx) {
        1 => 'Posts',
        2 => 'Events',
        3 => 'Saved posts',
        _ => 'Recent posts',
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            const Icon(
              Icons.article_outlined,
              size: 16,
              color: MCColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(label, style: MCTypography.h4),
          ],
        ),
      );
    }

    final posts = _visiblePosts(state);
    final i = index - 3;

    // Loading skeletons (only for All feed initial load)
    if (_filterIdx == 0 && state.isLoading && state.posts.isEmpty) {
      if (i < 4) {
        return const Padding(
          padding: EdgeInsets.only(bottom: MCSpacing.cardGap),
          child: MCFeedCardSkeleton(),
        );
      }
      return const SizedBox.shrink();
    }

    // Saved loading
    if (_filterIdx == 3 && _loadingSaved) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: MCColors.primary),
        ),
      );
    }

    // Empty state
    if (posts.isEmpty) return _buildEmptyState();

    // Post cards
    if (i < posts.length) {
      return Padding(
        padding: const EdgeInsets.only(bottom: MCSpacing.cardGap),
        child: _FeedPostCard(post: posts[i], userId: userId),
      );
    }

    // Loading-more row
    if (state.isLoadingMore && _filterIdx == 0 && i == posts.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(MCColors.primaryMid),
            ),
          ),
        ),
      );
    }

    // Footer
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'All caught up · ${posts.length} posts',
          style: MCTypography.caption,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.article_outlined,
            size: 48,
            color: MCColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text('No posts yet', style: MCTypography.h4),
          const SizedBox(height: 4),
          Text(
            'Be the first to share something with the community!',
            style: MCTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreatePost() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreatePostScreen(),
    );
  }
}

// File-level helpers shared by _MCFeedScreenState and _FeedPostCard

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return name.isEmpty ? 'U' : name[0].toUpperCase();
}

Color _avatarColor(String id) {
  const palette = [
    MCColors.primary,
    MCColors.success,
    MCColors.amber,
    MCColors.primaryLight,
    MCColors.violet,
  ];
  if (id.isEmpty) return MCColors.primary;
  return palette[id.codeUnitAt(0) % palette.length];
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays}d';
  if (diff.inHours >= 1) return '${diff.inHours}h';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
  return 'now';
}

// ── Feed post card ─────────────────────────────────────────────────────────────

class _FeedPostCard extends ConsumerStatefulWidget {
  const _FeedPostCard({required this.post, required this.userId});
  final PostDto post;
  final String userId;

  @override
  ConsumerState<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<_FeedPostCard> {
  late bool _liked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _liked = false;
    _likeCount = widget.post.reactionCount;
    _syncState();
  }

  Future<void> _syncState() async {
    if (widget.userId.isEmpty) return;
    final client = ref.read(supabaseClientProvider);
    final rows = await client
        .from('post_reactions')
        .select('user_id')
        .eq('post_id', widget.post.id);
    if (!mounted) return;
    final list = rows as List;
    setState(() {
      _likeCount = list.length;
      _liked = list.any((r) => (r as Map)['user_id'] == widget.userId);
    });
  }

  Future<void> _toggleLike() async {
    if (widget.userId.isEmpty) return;
    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _likeCount = wasLiked
          ? (_likeCount - 1).clamp(0, 999999)
          : _likeCount + 1;
    });
    final client = ref.read(supabaseClientProvider);
    final repo = FeedRepository(client);
    try {
      if (wasLiked) {
        await repo.removeReaction(
          postId: widget.post.id,
          userId: widget.userId,
        );
      } else {
        await repo.upsertReaction(
          postId: widget.post.id,
          userId: widget.userId,
          emoji: '❤️',
        );
      }
    } catch (_) {
      setState(() {
        _liked = wasLiked;
        _likeCount = wasLiked
            ? _likeCount + 1
            : (_likeCount - 1).clamp(0, 999999);
      });
    }
  }

  Future<void> _toggleSave() async {
    await ref.read(savedPostsProvider.notifier).toggle(widget.post.id);
  }

  Future<void> _deletePost() async {
    final client = ref.read(supabaseClientProvider);
    try {
      await client.from('posts').delete().eq('id', widget.post.id);
      if (mounted) await ref.read(feedProvider.notifier).refresh();
    } catch (_) {}
  }

  void _showPostMenu(bool isOwn) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwn)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _deletePost();
                },
              ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Save post'),
              onTap: () {
                Navigator.of(context).pop();
                _toggleSave();
              },
            ),
            if (!isOwn)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report post'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy text'),
              onTap: () {
                Navigator.of(context).pop();
                // copy handled in detail screen
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.post.author?.fullName ?? 'Unknown';
    final isOwn = widget.post.authorId == widget.userId;
    final savedIds = switch (ref.watch(savedPostsProvider)) {
      AsyncData(:final value) => value,
      _ => <String>{},
    };
    final saved = savedIds.contains(widget.post.id);

    return GestureDetector(
      onTap: () => context.push('/feed/post/${widget.post.id}'),
      child: MCCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PostHeader(
              name: name,
              role: '',
              initials: _initials(name),
              color: _avatarColor(widget.post.authorId),
              avatarUrl: widget.post.author?.avatarUrl,
              time: _relativeTime(widget.post.createdAt),
              label: widget.post.isPinned ? 'Pinned' : null,
              onMore: () => _showPostMenu(isOwn),
            ),
            const SizedBox(height: 10),
            if (widget.post.content.isNotEmpty)
              Text(widget.post.content, style: MCTypography.body),
            if (widget.post.imageUrls.isNotEmpty) ...[
              if (widget.post.content.isNotEmpty) const SizedBox(height: 10),
              _PostImageGrid(imageUrls: widget.post.imageUrls),
            ],
            if (widget.post.poll != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {}, // absorb tap so card navigation doesn't fire
                behavior: HitTestBehavior.opaque,
                child: FeedPollWidget(
                  poll: widget.post.poll!,
                  userId: widget.userId,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: MCColors.borderLight),
            const SizedBox(height: 10),
            _EngagementRow(
              reactions: _likeCount,
              comments: widget.post.commentCount,
              liked: _liked,
              saved: saved,
              onLike: _toggleLike,
              onComment: () => context.push('/feed/post/${widget.post.id}'),
              onSave: _toggleSave,
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Top bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.onCreatePost, required this.onSearch});
  final VoidCallback onCreatePost;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MCSpacing.pageH,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(
          bottom: BorderSide(color: MCColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: MCColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('The Catalysts', style: MCTypography.h4),
                Text('Leadership community', style: MCTypography.caption),
              ],
            ),
          ),
          _TopBarIcon(
            icon: Icons.people_outline,
            onTap: () => context.push(RouteNames.activeMembers),
          ),
          const SizedBox(width: 4),
          _TopBarIcon(icon: Icons.search, onTap: onSearch),
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _TopBarIcon(
                icon: Icons.notifications_outlined,
                onTap: () => context.push('/notifications'),
              ),
              Positioned(
                top: -2,
                right: -4,
                child: MCBadgeDot(
                  count: ref.watch(
                    notificationProvider.select((s) => s.unreadCount),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: MCColors.textSecondary),
      ),
    );
  }
}

// â”€â”€ Stories row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StoriesRow extends ConsumerWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final userId = auth is AppAuthStateAuthenticated ? auth.session.userId : '';
    final userName = auth is AppAuthStateAuthenticated
        ? (auth.session.fullName ?? 'Me')
        : 'Me';
    final statuses = switch (ref.watch(statusesProvider)) {
      AsyncData(:final value) => value,
      _ => <StatusDto>[],
    };

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 1 + statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == 0) {
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreateStoryScreen(),
                  fullscreenDialog: true,
                ),
              ),
              child: SizedBox(
                width: 68,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        MCStoryAvatar(
                          initials: _initials(userName),
                          label: '',
                          backgroundColor: MCColors.primaryLight,
                          viewed: true,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: MCColors.primary,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text('Add', style: MCTypography.caption),
                  ],
                ),
              ),
            );
          }
          final status = statuses[i - 1];
          final name = status.authorName ?? 'Unknown';
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StoryViewerScreen(
                  statuses: statuses,
                  initialIndex: i - 1,
                  currentUserId: userId,
                ),
                fullscreenDialog: true,
              ),
            ),
            child: SizedBox(
              width: 68,
              child: MCStoryAvatar(
                initials: _initials(name),
                label: name.split(' ').first,
                backgroundColor: _avatarColor(status.userId),
                viewed: status.userId == userId,
              ),
            ),
          );
        },
      ),
    );
  }
}

// â”€â”€ Filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  static const _filters = ['All', 'Posts', 'Events', 'Saved'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => MCFilterChip(
          label: _filters[i],
          active: i == selected,
          onTap: () => onChanged(i),
        ),
      ),
    );
  }
}

// â”€â”€ Composer card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({required this.onTap, this.initials = 'U'});
  final VoidCallback onTap;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          border: Border.all(color: MCColors.border),
          boxShadow: MCColors.cardShadow,
        ),
        child: Row(
          children: [
            MCAvatar(
              initials: initials,
              size: MCAvatar.md,
              backgroundColor: MCColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "What's on your mind?",
                style: MCTypography.body.copyWith(color: MCColors.textMuted),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: MCColors.primaryPale,
                borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
              ),
              child: Text(
                'Post',
                style: MCTypography.labelSm.copyWith(
                  color: MCColors.primaryMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Post card shared header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.name,
    required this.role,
    required this.initials,
    required this.color,
    required this.time,
    this.avatarUrl,
    this.label,
    this.onMore,
  });

  final String name;
  final String role;
  final String initials;
  final Color color;
  final String time;
  final String? avatarUrl;
  final String? label;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatarUrl != null && avatarUrl!.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  width: MCAvatar.md,
                  height: MCAvatar.md,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => MCAvatar(
                    initials: initials,
                    size: MCAvatar.md,
                    backgroundColor: color,
                  ),
                  errorWidget: (_, __, ___) => MCAvatar(
                    initials: initials,
                    size: MCAvatar.md,
                    backgroundColor: color,
                  ),
                ),
              )
            : MCAvatar(
                initials: initials,
                size: MCAvatar.md,
                backgroundColor: color,
              ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: MCTypography.h4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (label != null) ...[
                    const SizedBox(width: 6),
                    MCStatusPill.amber(label!),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Text(
                role,
                style: MCTypography.caption,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(time, style: MCTypography.caption),
            ],
          ),
        ),
        GestureDetector(
          onTap: onMore,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Icon(Icons.more_horiz, size: 18, color: MCColors.textMuted),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Engagement row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EngagementRow extends StatelessWidget {
  const _EngagementRow({
    required this.reactions,
    required this.comments,
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onComment,
    required this.onSave,
  });

  final int reactions;
  final int comments;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionBtn(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          count: reactions,
          color: liked ? MCColors.error : null,
          onTap: onLike,
        ),
        const SizedBox(width: 16),
        _ActionBtn(
          icon: Icons.chat_bubble_outline,
          count: comments,
          onTap: onComment,
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSave,
          child: Icon(
            saved ? Icons.bookmark : Icons.bookmark_border,
            size: 18,
            color: saved ? MCColors.primary : MCColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.count,
    this.onTap,
    this.color,
  });
  final IconData icon;
  final int count;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color ?? MCColors.textSecondary),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(_fmt(count), style: MCTypography.caption),
          ],
        ],
      ),
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

// ── Post image grid ────────────────────────────────────────────────────────

class _PostImageGrid extends StatelessWidget {
  const _PostImageGrid({required this.imageUrls});
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls.take(4).toList();
    if (urls.length == 1) return _tile(urls[0], height: 200);
    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: _tile(urls[0], height: 150)),
          const SizedBox(width: 3),
          Expanded(child: _tile(urls[1], height: 150)),
        ],
      );
    }
    if (urls.length == 3) {
      return Row(
        children: [
          Expanded(child: _tile(urls[0], height: 150)),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              children: [
                _tile(urls[1], height: 73),
                const SizedBox(height: 3),
                _tile(urls[2], height: 73),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _tile(urls[0], height: 100)),
            const SizedBox(width: 3),
            Expanded(child: _tile(urls[1], height: 100)),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(child: _tile(urls[2], height: 100)),
            const SizedBox(width: 3),
            Expanded(child: _tile(urls[3], height: 100)),
          ],
        ),
      ],
    );
  }

  Widget _tile(String url, {required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: MCColors.background,
            child: const Icon(
              Icons.broken_image_outlined,
              color: MCColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
