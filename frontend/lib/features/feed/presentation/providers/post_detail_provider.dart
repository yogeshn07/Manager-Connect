import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'post_detail_provider.g.dart';

class PostDetailState {
  const PostDetailState({
    this.post,
    this.comments = const [],
    this.reactions = const [],
    this.isLoading = false,
    this.error,
  });

  final PostDto? post;
  final List<CommentDto> comments;
  final List<ReactionDto> reactions;
  final bool isLoading;
  final String? error;

  PostDetailState copyWith({
    PostDto? post,
    List<CommentDto>? comments,
    List<ReactionDto>? reactions,
    bool? isLoading,
    String? Function()? error,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      reactions: reactions ?? this.reactions,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

@riverpod
class PostDetailNotifier extends _$PostDetailNotifier {
  FeedRepository? _repo;

  @override
  PostDetailState build(String postId) {
    final client = ref.watch(supabaseClientProvider);
    _repo = FeedRepository(client);
    return const PostDetailState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final results = await Future.wait([
        _repo!.getPost(postId),
        _repo!.getComments(postId),
        _repo!.getReactions(postId),
      ]);
      state = state.copyWith(
        post: results[0] as PostDto,
        comments: results[1] as List<CommentDto>,
        reactions: results[2] as List<ReactionDto>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> addComment({
    required String authorId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final comment = await _repo!.createComment(
        postId: postId,
        authorId: authorId,
        content: content,
        parentCommentId: parentCommentId,
      );
      state = state.copyWith(comments: [...state.comments, comment]);
    } catch (_) {}
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _repo!.deleteComment(commentId);
      state = state.copyWith(
        comments: state.comments.where((c) => c.id != commentId).toList(),
      );
    } catch (_) {}
  }

  Future<void> toggleReaction({
    required String userId,
    required String emoji,
  }) async {
    final existing = state.reactions
        .where((r) => r.userId == userId)
        .toList();

    try {
      if (existing.isNotEmpty && existing.first.emoji == emoji) {
        await _repo!.removeReaction(postId: postId, userId: userId);
        state = state.copyWith(
          reactions: state.reactions.where((r) => r.userId != userId).toList(),
        );
      } else {
        await _repo!.upsertReaction(
          postId: postId,
          userId: userId,
          emoji: emoji,
        );
        final updated = state.reactions
            .where((r) => r.userId != userId)
            .toList();
        updated.add(ReactionDto(
          id: '',
          postId: postId,
          userId: userId,
          emoji: emoji,
        ));
        state = state.copyWith(reactions: updated);
      }
    } catch (_) {}
  }
}
