import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/features/feed/presentation/screens/create_post_screen.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_composer.dart';
import 'package:manager_connect/shared/widgets/mc/mc_feed_post_card.dart';
import 'package:manager_connect/shared/widgets/mc/mc_section_header.dart';
import 'package:manager_connect/shared/widgets/mc/mc_top_bar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(feedProvider.notifier).loadFeed();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: McColors.bgApp,
      appBar: McTopBarA(
        actions: [
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.search, size: 20, color: McColors.textSecondary),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Icon(Icons.notifications_outlined, size: 20, color: McColors.textSecondary),
          ),
        ],
      ),
      body: _buildBody(feedState),
    );
  }

  Widget _buildBody(FeedState feedState) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return Center(
        child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: McColors.brand800),
        ),
      );
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 32, color: McColors.textTertiary),
            const SizedBox(height: 12),
            Text('Failed to load feed', style: McTypography.body),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => ref.read(feedProvider.notifier).loadFeed(),
              child: Text('Retry', style: McTypography.h4.copyWith(color: McColors.textLink)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: McColors.brand800,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 4, bottom: 80),
        itemCount: _itemCount(feedState),
        itemBuilder: (context, index) => _buildItem(feedState, index),
      ),
    );
  }

  int _itemCount(FeedState feedState) {
    int count = 2; // composer + section header
    if (feedState.pinnedPost != null) count++;
    count += feedState.posts.length;
    if (feedState.isLoadingMore) count++;
    return count;
  }

  Widget _buildItem(FeedState feedState, int index) {
    if (index == 0) {
      return McComposer(
        onTap: () => _showCreatePost(),
        onRecognition: () => context.go('/growth'),
        onPoll: () => context.go('/events'),
        onEvent: () => context.go('/events'),
      );
    }

    if (index == 1) {
      return McSectionHeader(
        label: 'Trending in your org',
        icon: Icons.local_fire_department,
        iconColor: McColors.coral600,
        rightLabel: 'Recent',
      );
    }

    int postStart = 2;
    if (feedState.pinnedPost != null) {
      if (index == 2) {
        return _postCard(feedState.pinnedPost!, isPinned: true);
      }
      postStart = 3;
    }

    final postIndex = index - postStart;
    if (postIndex >= feedState.posts.length) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: McColors.brand400),
          ),
        ),
      );
    }

    return _postCard(feedState.posts[postIndex]);
  }

  Widget _postCard(PostDto post, {bool isPinned = false}) {
    final name = post.author?.fullName ?? 'Unknown';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isCB = post.author?.isSystemAccount == true ||
        post.authorId == AppConstants.connectBuddySystemAccountId;

    Color? avatarColor;
    String? pillText;
    Color? pillFill;
    Color? pillTextColor;
    Color? bannerBg;
    IconData? bannerIcon;
    String? bannerLabel;

    if (isCB) {
      avatarColor = McColors.purple600;
      pillText = 'Announcement';
      pillFill = McColors.brand50;
      pillTextColor = McColors.brand800;
    }

    if (isPinned) {
      bannerBg = McColors.brand800;
      bannerIcon = Icons.push_pin;
      bannerLabel = 'Pinned announcement';
    }

    return McFeedPostCard(
      authorName: name,
      authorInitials: initials,
      authorRole: isCB ? 'Community Bot' : 'Manager',
      timestamp: _formatTime(post.createdAt),
      body: post.content,
      avatarColor: avatarColor,
      typePill: pillText,
      typePillFill: pillFill,
      typePillText: pillTextColor,
      bannerColor: bannerBg,
      bannerIcon: bannerIcon,
      bannerLabel: bannerLabel,
      isConnectBuddy: isCB,
      isPinned: isPinned,
      onTap: () => context.push('/feed/post/${post.id}'),
      onReact: () {},
      onComment: () => context.push('/feed/post/${post.id}'),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
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
