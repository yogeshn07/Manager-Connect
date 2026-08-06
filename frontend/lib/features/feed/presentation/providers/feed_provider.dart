import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'feed_provider.g.dart';

class FeedState {
  const FeedState({
    this.posts = const [],
    this.pinnedPost,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<PostDto> posts;
  final PostDto? pinnedPost;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  FeedState copyWith({
    List<PostDto>? posts,
    PostDto? Function()? pinnedPost,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? Function()? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      pinnedPost: pinnedPost != null ? pinnedPost() : this.pinnedPost,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error != null ? error() : this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class FeedNotifier extends _$FeedNotifier {
  FeedRepository? _repo;
  RealtimeChannel? _channel;
  final _knownPostIds = <String>{};

  @override
  FeedState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = FeedRepository(client);
    ref.onDispose(_disposeRealtime);
    return const FeedState();
  }

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final posts = await _repo!.getFeed();
      final pinned = await _repo!.getPinnedPost();
      _knownPostIds
        ..clear()
        ..addAll(posts.map((p) => p.id));
      state = state.copyWith(
        posts: posts,
        pinnedPost: () => pinned,
        isLoading: false,
        hasMore: posts.length >= AppConstants.paginationPageSize,
      );
      _subscribeRealtime();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.posts.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final cursor = state.posts.last.createdAt;
      final morePosts = await _repo!.getFeed(cursor: cursor);
      for (final p in morePosts) {
        _knownPostIds.add(p.id);
      }
      state = state.copyWith(
        posts: [...state.posts, ...morePosts],
        isLoadingMore: false,
        hasMore: morePosts.length >= AppConstants.paginationPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    try {
      final posts = await _repo!.getFeed();
      final pinned = await _repo!.getPinnedPost();
      _knownPostIds
        ..clear()
        ..addAll(posts.map((p) => p.id));
      state = state.copyWith(
        posts: posts,
        pinnedPost: () => pinned,
        hasMore: posts.length >= AppConstants.paginationPageSize,
        error: () => null,
      );
    } catch (_) {}
  }

  void removePost(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
    _knownPostIds.remove(postId);
  }

  void _subscribeRealtime() {
    _disposeRealtime();
    final client = Supabase.instance.client;
    _channel = client
        .channel('feed:posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: Table.posts,
          callback: (payload) {
            final postId = payload.newRecord['id'] as String?;
            if (postId == null) return;
            if (_knownPostIds.contains(postId)) return;
            _knownPostIds.add(postId);
            _fetchAndPrependPost(postId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: Table.posts,
          callback: (payload) {
            final postId = payload.newRecord['id'] as String?;
            if (postId == null) return;
            final isDeleted = payload.newRecord['is_deleted'] as bool? ?? false;
            if (isDeleted) {
              removePost(postId);
            } else {
              _refreshPost(postId);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: Table.pollVotes,
          callback: (payload) {
            final pollId = payload.newRecord['poll_id'] as String?;
            if (pollId == null) return;
            // Find the feed post that owns this poll and refresh just that post
            final post = state.posts
                .where((p) => p.poll?.id == pollId)
                .firstOrNull;
            if (post != null) _refreshPost(post.id);
          },
        )
        .subscribe();
  }

  Future<void> _fetchAndPrependPost(String postId) async {
    try {
      final post = await _repo!.getPost(postId);
      if (post.isDeleted) return;
      state = state.copyWith(posts: [post, ...state.posts]);
    } catch (_) {}
  }

  Future<void> _refreshPost(String postId) async {
    try {
      final fresh = await _repo!.getPost(postId);
      if (fresh.isDeleted) {
        removePost(postId);
        return;
      }
      state = state.copyWith(
        posts: state.posts.map((p) => p.id == postId ? fresh : p).toList(),
      );
    } catch (_) {}
  }

  void _disposeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
