import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/features/feed/presentation/widgets/post_card.dart';
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
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(RouteNames.notifications),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePost(context),
        child: const Icon(Icons.edit),
      ),
      body: _buildBody(feedState),
    );
  }

  Widget _buildBody(FeedState feedState) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const LoadingState(message: 'Loading feed...');
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return ErrorState(
        message: 'Failed to load feed',
        onRetry: () => ref.read(feedProvider.notifier).loadFeed(),
      );
    }

    if (!feedState.isLoading && feedState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final itemCount = feedState.posts.length +
        (feedState.pinnedPost != null ? 1 : 0) +
        (feedState.isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          if (feedState.pinnedPost != null && index == 0) {
            return PostCard(
              post: feedState.pinnedPost!,
              onTap: () => _openPostDetail(feedState.pinnedPost!.id),
            );
          }

          final postIndex =
              index - (feedState.pinnedPost != null ? 1 : 0);

          if (postIndex >= feedState.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = feedState.posts[postIndex];
          return PostCard(
            post: post,
            onTap: () => _openPostDetail(post.id),
          );
        },
      ),
    );
  }

  void _openPostDetail(String postId) {
    context.push('/post/$postId');
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
