import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/core/theme/app_colors.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/features/feed/presentation/widgets/post_card.dart';
import 'package:manager_connect/features/feed/presentation/widgets/feed_app_bar.dart';
import 'package:manager_connect/features/feed/presentation/widgets/composer_card.dart';
import 'package:manager_connect/features/feed/presentation/widgets/trending_header.dart';
import 'package:manager_connect/features/feed/presentation/screens/create_post_screen.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

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
      backgroundColor: AppColors.surfaceLight,
      appBar: FeedAppBar(
        onNotificationTap: () => context.push(RouteNames.notifications),
        onSearchTap: () {},
      ),
      body: _buildBody(feedState),
    );
  }

  Widget _buildBody(FeedState feedState) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const LoadingState(message: 'Loading your feed...');
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return ErrorState(
        message: 'Failed to load feed',
        onRetry: () => ref.read(feedProvider.notifier).loadFeed(),
      );
    }

    if (!feedState.isLoading && feedState.posts.isEmpty) {
      return _buildEmptyFeed();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: AppColors.brandPrimary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _itemCount(feedState),
        itemBuilder: (context, index) => _buildItem(feedState, index),
      ),
    );
  }

  int _itemCount(FeedState feedState) {
    // composer + trending header + pinned? + posts + loading?
    int count = 2; // composer + trending header
    if (feedState.pinnedPost != null) count++;
    count += feedState.posts.length;
    if (feedState.isLoadingMore) count++;
    return count;
  }

  Widget _buildItem(FeedState feedState, int index) {
    if (index == 0) {
      return ComposerCard(
        onTap: () => _showCreatePost(context),
        onRecognitionTap: () => context.go(RouteNames.growth),
        onPollTap: () => context.go(RouteNames.events),
        onEventTap: () => context.go(RouteNames.events),
      );
    }

    if (index == 1) {
      return const TrendingHeader();
    }

    int postStart = 2;
    if (feedState.pinnedPost != null) {
      if (index == 2) {
        return PostCard(
          post: feedState.pinnedPost!,
          onTap: () => _openPostDetail(feedState.pinnedPost!.id),
        );
      }
      postStart = 3;
    }

    final postIndex = index - postStart;
    if (postIndex >= feedState.posts.length) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.brandPrimary,
            ),
          ),
        ),
      );
    }

    final post = feedState.posts[postIndex];
    return PostCard(
      post: post,
      onTap: () => _openPostDetail(post.id),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum_outlined, size: 40, color: AppColors.brandPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Manager Connect',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share an update with\nyour leadership community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreatePost(context),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Share Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPostDetail(String postId) {
    context.push('/feed/post/$postId');
  }

  void _showCreatePost(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreatePostScreen(),
    );
  }
}
