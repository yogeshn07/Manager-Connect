import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/features/feed/presentation/providers/post_detail_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/features/feed/presentation/widgets/feed_poll_widget.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.postId, super.key});
  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  bool _sendingComment = false;
  String? _replyingToId;
  String? _replyingToAuthor;
  final _expandedReplies = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(postDetailProvider(widget.postId).notifier).load(),
    );
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _replyTo(String commentId, String authorName) {
    setState(() {
      _replyingToId = commentId;
      _replyingToAuthor = authorName;
      _expandedReplies.add(commentId);
    });
    _commentController.clear();
    _commentFocusNode.requestFocus();
  }

  String? get _currentUserId {
    final s = ref.read(authProvider);
    if (s is AppAuthStateAuthenticated) return s.session.userId;
    return null;
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    final userId = _currentUserId;
    if (content.isEmpty || userId == null) return;
    final parentId = _replyingToId;
    setState(() => _sendingComment = true);
    try {
      await ref
          .read(postDetailProvider(widget.postId).notifier)
          .addComment(
              authorId: userId, content: content, parentCommentId: parentId);
      _commentController.clear();
      setState(() {
        _replyingToId = null;
        _replyingToAuthor = null;
        if (parentId != null) _expandedReplies.add(parentId);
      });
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to add comment');
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _deletePost() async {
    final ok = await showDialog<bool>(
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
    if (ok != true || !mounted) return;
    ref.read(feedProvider.notifier).removePost(widget.postId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailProvider(widget.postId));
    final userId = _currentUserId;

    return Scaffold(
      backgroundColor: MCColors.background,
      body: MCAmbientIdentityBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(state, userId),
              Expanded(child: _body(state, userId)),
              _commentBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(PostDetailState state, String? userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(bottom: BorderSide(color: MCColors.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            color: MCColors.textPrimary,
          ),
          Text('Post', style: MCTypography.h3),
          const Spacer(),
          if (state.post != null && state.post!.authorId == userId)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: _deletePost,
              color: MCColors.textMuted,
            ),
        ],
      ),
    );
  }

  Widget _body(PostDetailState state, String? userId) {
    if (state.isLoading) return const LoadingState();
    if (state.error != null) {
      return ErrorState(
        message: 'Failed to load post',
        onRetry: () =>
            ref.read(postDetailProvider(widget.postId).notifier).load(),
      );
    }
    if (state.post == null) return const LoadingState();

    final comments = state.comments;
    final topLevelCount =
        comments.where((c) => c.parentCommentId == null).length;

    return ListView(
      padding: const EdgeInsets.all(MCSpacing.pageH),
      children: [
        _PostContent(
          post: state.post!,
          reactions: state.reactions,
          userId: userId,
          onToggle: (e) {
            if (userId == null) return;
            ref
                .read(postDetailProvider(widget.postId).notifier)
                .toggleReaction(userId: userId, emoji: e);
          },
        ),
        const SizedBox(height: MCSpacing.md),
        _commentsSectionHeader(topLevelCount),
        const SizedBox(height: 12),
        if (comments.isEmpty)
          _emptyComments()
        else
          ..._buildThreaded(comments, userId),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _commentsSectionHeader(int count) {
    return Row(
      children: [
        const Icon(Icons.chat_bubble_outline,
            size: 15, color: MCColors.textMuted),
        const SizedBox(width: 6),
        Text(
          '$count Comment${count == 1 ? '' : 's'}',
          style: MCTypography.h4,
        ),
        const Spacer(),
        if (count > 0)
          Text('Most recent', style: MCTypography.caption),
      ],
    );
  }

  Widget _emptyComments() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 36, color: MCColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text('Be the first to comment', style: MCTypography.caption),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  List<Widget> _buildThreaded(List<CommentDto> comments, String? userId) {
    final topLevel =
        comments.where((c) => c.parentCommentId == null).toList();
    final result = <Widget>[];

    for (final parent in topLevel) {
      final parentName = parent.author?.fullName ?? 'Unknown';
      result.add(_CommentTile(
        comment: parent,
        isOwn: parent.authorId == userId,
        onDelete: () => ref
            .read(postDetailProvider(widget.postId).notifier)
            .deleteComment(parent.id),
        onReply: () => _replyTo(parent.id, parentName),
      ));

      final replies =
          comments.where((c) => c.parentCommentId == parent.id).toList();
      if (replies.isEmpty) continue;

      final expanded = _expandedReplies.contains(parent.id);
      result.add(
        Padding(
          padding: const EdgeInsets.only(left: 36, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  if (expanded) {
                    _expandedReplies.remove(parent.id);
                  } else {
                    _expandedReplies.add(parent.id);
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right,
                            size: 14, color: MCColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expanded
                            ? 'Hide replies'
                            : 'View ${replies.length} repl${replies.length == 1 ? 'y' : 'ies'}',
                        style: MCTypography.captionBold
                            .copyWith(color: MCColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 4),
                        color: MCColors.borderLight),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: replies.map((r) {
                          final rName = r.author?.fullName ?? 'Unknown';
                          return _CommentTile(
                            comment: r,
                            isOwn: r.authorId == userId,
                            onDelete: () => ref
                                .read(postDetailProvider(widget.postId)
                                    .notifier)
                                .deleteComment(r.id),
                            onReply: () => _replyTo(parent.id, rName),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }
    return result;
  }

  Widget _commentBar() {
    final auth = ref.read(authProvider);
    final userInitials = auth is AppAuthStateAuthenticated
        ? _initials(auth.session.fullName ?? '')
        : 'U';
    final hasText = _commentController.text.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(top: BorderSide(color: MCColors.borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply banner
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _replyingToId != null
                ? Container(
                    key: const ValueKey('reply-banner'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    color: MCColors.primaryPale,
                    child: Row(
                      children: [
                        const Icon(Icons.reply,
                            size: 13, color: MCColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Replying to ${_replyingToAuthor ?? 'comment'}',
                            style: MCTypography.caption.copyWith(
                                color: MCColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _replyingToId = null;
                            _replyingToAuthor = null;
                          }),
                          child: const Icon(Icons.close,
                              size: 15, color: MCColors.primary),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-reply')),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MCAvatar(
                  initials: userInitials,
                  size: MCAvatar.sm,
                  backgroundColor: MCColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: MCColors.background,
                      borderRadius:
                          BorderRadius.circular(MCSpacing.radiusPill),
                      border: Border.all(color: MCColors.border),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      decoration: InputDecoration(
                        hintText: _replyingToId != null
                            ? 'Reply to ${_replyingToAuthor ?? 'comment'}…'
                            : 'Add to the discussion…',
                        hintStyle: MCTypography.body
                            .copyWith(color: MCColors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: MCTypography.body,
                      maxLines: 4,
                      minLines: 1,
                      enabled: !_sendingComment,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendingComment || !hasText ? null : _submitComment,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasText ? MCColors.primary : MCColors.background,
                    ),
                    child: _sendingComment
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: hasText
                                ? Colors.white
                                : MCColors.textMuted,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post content ──────────────────────────────────────────────────────────────

class _PostContent extends StatelessWidget {
  const _PostContent({
    required this.post,
    required this.reactions,
    required this.userId,
    required this.onToggle,
  });

  final PostDto post;
  final List<ReactionDto> reactions;
  final String? userId;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final name = post.author?.fullName ?? 'Unknown';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final counts = <String, int>{};
    String? mine;
    for (final r in reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
      if (r.userId == userId) mine = r.emoji;
    }

    return Container(
      padding: const EdgeInsets.all(MCSpacing.cardPadH),
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: MCColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MCAvatar(
                initials: initials,
                size: MCAvatar.md,
                backgroundColor: MCColors.primary,
                avatarUrl: post.author?.avatarUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: MCTypography.h4),
                    Text(_timeAgo(post.createdAt), style: MCTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (post.content.isNotEmpty) Text(post.content, style: MCTypography.bodyLg),
          if (post.imageUrls.isNotEmpty) ...[
            if (post.content.isNotEmpty) const SizedBox(height: 10),
            _PostDetailImageGrid(imageUrls: post.imageUrls),
          ],
          if (post.poll != null) ...[
            const SizedBox(height: 12),
            FeedPollWidget(poll: post.poll!, userId: userId ?? ''),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: MCColors.borderLight),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['👍', '❤️', '🎉', '💡', '👏'].map((e) {
              final count = counts[e] ?? 0;
              final selected = mine == e;
              return GestureDetector(
                onTap: userId == null ? null : () => onToggle(e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? MCColors.primaryPale
                        : MCColors.background,
                    borderRadius:
                        BorderRadius.circular(MCSpacing.radiusPill),
                    border: Border.all(
                      color:
                          selected ? MCColors.primary : MCColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e, style: const TextStyle(fontSize: 15)),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: MCTypography.captionBold.copyWith(
                            color: selected
                                ? MCColors.primary
                                : MCColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

// ── Comment tile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.isOwn,
    required this.onDelete,
    required this.onReply,
  });

  final CommentDto comment;
  final bool isOwn;
  final VoidCallback onDelete;
  final VoidCallback onReply;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile>
    with SingleTickerProviderStateMixin {
  bool _liked = false;
  int _likeCount = 0;
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartScale;

  // Floating heart overlay state
  bool _showFloatingHeart = false;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.6), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _onLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    _heartCtrl.forward(from: 0);
  }

  void _onDoubleTap() {
    if (!_liked) _onLike();
    // Show floating heart animation
    setState(() => _showFloatingHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showFloatingHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.comment.author?.fullName ?? 'Unknown';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MCAvatar(
            initials: initials,
            size: MCAvatar.sm,
            backgroundColor: MCColors.textMuted,
            avatarUrl: widget.comment.author?.avatarUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bubble with double-tap to like
                GestureDetector(
                  onDoubleTap: _onDoubleTap,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 10),
                        decoration: BoxDecoration(
                          color: MCColors.background,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                            topLeft: Radius.circular(4),
                          ),
                          border: Border.all(color: MCColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: MCTypography.labelSm
                                  .copyWith(color: MCColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.comment.content,
                              style:
                                  MCTypography.body.copyWith(height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      // Floating heart on double-tap
                      if (_showFloatingHeart)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 700),
                                builder: (_, t, child) {
                                  return Transform.translate(
                                    offset: Offset(0, -30 * t),
                                    child: Opacity(
                                      opacity: t < 0.7 ? 1.0 : (1.0 - t) / 0.3,
                                      child: child,
                                    ),
                                  );
                                },
                                child: const Text('❤️',
                                    style: TextStyle(fontSize: 36)),
                              ),
                            ),
                          ),
                        ),
                      // Like count badge (top-right of bubble)
                      if (_likeCount > 0)
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MCColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: MCColors.borderLight, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 1)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('❤️',
                                    style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 2),
                                Text(
                                  '$_likeCount',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // Action row below bubble
                Row(
                  children: [
                    Text(_timeAgo(widget.comment.createdAt),
                        style: MCTypography.caption),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: widget.onReply,
                      child: Text(
                        'Reply',
                        style: MCTypography.caption.copyWith(
                          color: MCColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.isOwn) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: Text(
                          'Delete',
                          style: MCTypography.caption.copyWith(
                            color: MCColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Heart button with bounce animation
                    GestureDetector(
                      onTap: _onLike,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 2),
                        child: ScaleTransition(
                          scale: _heartScale,
                          child: Icon(
                            _liked ? Icons.favorite : Icons.favorite_border,
                            size: 17,
                            color: _liked
                                ? Colors.redAccent
                                : MCColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

// ── Post image grid (detail) ───────────────────────────────────────────────

class _PostDetailImageGrid extends StatelessWidget {
  const _PostDetailImageGrid({required this.imageUrls});
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls.take(4).toList();
    if (urls.length == 1) return _tile(context, urls[0], height: 240);
    if (urls.length == 2) {
      return Row(children: [
        Expanded(child: _tile(context, urls[0], height: 180)),
        const SizedBox(width: 3),
        Expanded(child: _tile(context, urls[1], height: 180)),
      ]);
    }
    if (urls.length == 3) {
      return Row(children: [
        Expanded(child: _tile(context, urls[0], height: 180)),
        const SizedBox(width: 3),
        Expanded(
          child: Column(children: [
            _tile(context, urls[1], height: 88),
            const SizedBox(height: 3),
            _tile(context, urls[2], height: 88),
          ]),
        ),
      ]);
    }
    return Column(children: [
      Row(children: [
        Expanded(child: _tile(context, urls[0], height: 120)),
        const SizedBox(width: 3),
        Expanded(child: _tile(context, urls[1], height: 120)),
      ]),
      const SizedBox(height: 3),
      Row(children: [
        Expanded(child: _tile(context, urls[2], height: 120)),
        const SizedBox(width: 3),
        Expanded(child: _tile(context, urls[3], height: 120)),
      ]),
    ]);
  }

  Widget _tile(BuildContext context, String url, {required double height}) {
    return GestureDetector(
      onTap: () => _showFullscreen(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: MCColors.background,
              child: const Icon(Icons.broken_image_outlined,
                  color: MCColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: InteractiveViewer(
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
