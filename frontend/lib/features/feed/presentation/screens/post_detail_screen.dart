import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/features/feed/presentation/providers/post_detail_provider.dart';
import 'package:manager_connect/features/feed/presentation/widgets/post_card.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(postDetailProvider(widget.postId).notifier).load();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String? get _currentUserId {
    final authState = ref.read(authProvider);
    if (authState is AppAuthStateAuthenticated) {
      return authState.session.userId;
    }
    return null;
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    final userId = _currentUserId;
    if (content.isEmpty || userId == null) return;

    setState(() => _sendingComment = true);
    try {
      await ref
          .read(postDetailProvider(widget.postId).notifier)
          .addComment(authorId: userId, content: content);
      _commentController.clear();
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to add comment');
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  void _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('This post will be removed from the feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    ref.read(feedProvider.notifier).removePost(widget.postId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final detailState =
        ref.watch(postDetailProvider(widget.postId));
    final userId = _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (detailState.post != null &&
              detailState.post!.authorId == userId)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deletePost,
            ),
        ],
      ),
      body: _buildBody(detailState, userId),
    );
  }

  Widget _buildBody(PostDetailState detailState, String? userId) {
    if (detailState.isLoading) {
      return const LoadingState();
    }
    if (detailState.error != null) {
      return ErrorState(
        message: 'Failed to load post',
        onRetry: () => ref
            .read(postDetailProvider(widget.postId).notifier)
            .load(),
      );
    }
    if (detailState.post == null) {
      return const LoadingState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              PostCard(post: detailState.post!),
              _buildReactionBar(detailState, userId),
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Comments (${detailState.comments.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (detailState.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No comments yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ...detailState.comments.map(
                (comment) => _buildCommentTile(comment, userId),
              ),
            ],
          ),
        ),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildReactionBar(PostDetailState detailState, String? userId) {
    final reactionCounts = <String, int>{};
    String? myEmoji;
    for (final r in detailState.reactions) {
      reactionCounts[r.emoji] = (reactionCounts[r.emoji] ?? 0) + 1;
      if (r.userId == userId) myEmoji = r.emoji;
    }

    const emojis = ['👍', '❤️', '😂', '🎉', '👏'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 4,
        children: emojis.map((emoji) {
          final count = reactionCounts[emoji] ?? 0;
          final isSelected = myEmoji == emoji;
          return ActionChip(
            avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
            label: Text('$count'),
            side: isSelected
                ? BorderSide(color: Theme.of(context).colorScheme.primary)
                : null,
            onPressed: userId == null
                ? null
                : () => ref
                    .read(
                        postDetailProvider(widget.postId).notifier)
                    .toggleReaction(userId: userId, emoji: emoji),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCommentTile(CommentDto comment, String? userId) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          (comment.author?.fullName ?? '?')[0].toUpperCase(),
        ),
      ),
      title: Text(comment.author?.fullName ?? 'Unknown'),
      subtitle: Text(comment.content),
      trailing: comment.authorId == userId
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => ref
                  .read(postDetailProvider(widget.postId).notifier)
                  .deleteComment(comment.id),
            )
          : null,
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                border: InputBorder.none,
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
              enabled: !_sendingComment,
            ),
          ),
          IconButton(
            icon: _sendingComment
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _sendingComment ? null : _submitComment,
          ),
        ],
      ),
    );
  }
}
