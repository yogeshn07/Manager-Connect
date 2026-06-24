import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/features/feed/presentation/screens/create_post_screen.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';

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
    Future.microtask(() => ref.read(feedProvider.notifier).loadFeed());
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
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onSearch: () {},
              onNotification: () => context.push('/notifications'),
            ),
            Expanded(child: _buildBody(feedState)),
          ],
        ),
      ),
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

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: McColors.teal400,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        itemCount: _itemCount(feedState),
        itemBuilder: (context, index) => _buildItem(feedState, index),
      ),
    );
  }

  int _itemCount(FeedState s) {
    int c = 3; // stories + composer + section header
    if (s.pinnedPost != null) c++;
    c += s.posts.length;
    if (s.isLoadingMore) c++;
    if (!s.isLoadingMore && s.posts.isNotEmpty) c++; // end indicator
    return c;
  }

  Widget _buildItem(FeedState s, int index) {
    if (index == 0) return const _StoriesRail();
    if (index == 1) return _Composer(onTap: _showCreatePost);
    if (index == 2) return const _TrendingHeader();

    int postStart = 3;
    if (s.pinnedPost != null) {
      if (index == 3) return _PostCard(post: s.pinnedPost!, onTap: () => _openPost(s.pinnedPost!.id));
      postStart = 4;
    }

    final pi = index - postStart;
    if (pi < s.posts.length) {
      return _PostCard(post: s.posts[pi], onTap: () => _openPost(s.posts[pi].id));
    }
    if (s.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: McColors.teal400))),
      );
    }
    // End indicator
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'You\'re all caught up · ${s.posts.length} of ${s.posts.length} posts',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: McColors.teal400),
        ),
      ),
    );
  }

  void _openPost(String id) => context.push('/feed/post/$id');
  void _showCreatePost() {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const CreatePostScreen());
  }
}

// ─── TOP BAR (matches V0 screenshot 1) ───
class _TopBar extends StatelessWidget {
  const _TopBar({this.onSearch, this.onNotification});
  final VoidCallback? onSearch;
  final VoidCallback? onNotification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: McColors.bgCard,
        border: Border(bottom: BorderSide(color: McColors.borderDefault, width: 0.5)),
      ),
      child: Row(
        children: [
          // Teal gem icon
          Container(
            width: 33, height: 33,
            decoration: BoxDecoration(color: McColors.teal800, borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Icon(Icons.hub, size: 16, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Manager Connect', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: McColors.gray900)),
                Text('Leadership community', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: McColors.textTertiary)),
              ],
            ),
          ),
          GestureDetector(onTap: onSearch, child: Icon(Icons.search, size: 22, color: McColors.gray600)),
          const SizedBox(width: 16),
          GestureDetector(onTap: onNotification, child: Icon(Icons.notifications_outlined, size: 22, color: McColors.gray600)),
        ],
      ),
    );
  }
}

// ─── STORIES RAIL (matches V0 screenshot 1) ───
class _StoriesRail extends StatelessWidget {
  const _StoriesRail();

  @override
  Widget build(BuildContext context) {
    final stories = [
      ('You', McColors.gray400, false, true),
      ('Priya', McColors.teal800, true, false),
      ('Marcus', McColors.brand800, false, false),
      ('Sofia', McColors.purple600, true, false),
      ('Kenji', McColors.teal400, false, false),
      ('David', McColors.coral800, false, false),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: McColors.bgCard,
      child: SizedBox(
        height: 82,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final (name, color, isLive, isYou) = stories[i];
            return _StoryItem(name: name, color: color, isLive: isLive, isYou: isYou);
          },
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({required this.name, required this.color, this.isLive = false, this.isYou = false});
  final String name;
  final Color color;
  final bool isLive;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          SizedBox(
            width: 52, height: 52,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Outer ring
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isYou ? McColors.gray100 : McColors.teal800, width: 2.5),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    child: Center(
                      child: Text(name[0], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ),
                ),
                // LIVE badge
                if (isLive)
                  Positioned(
                    bottom: -3, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(color: McColors.red400, borderRadius: BorderRadius.circular(4), border: Border.all(color: McColors.bgApp, width: 1.5)),
                        child: const Text('LIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.3)),
                      ),
                    ),
                  ),
                // You "+" overlay
                if (isYou)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: McColors.teal400, border: Border.all(color: Colors.white, width: 2)),
                      child: const Center(child: Icon(Icons.add, size: 10, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: McColors.textSecondary), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── COMPOSER (matches V0 screenshot 1) ───
class _Composer extends StatelessWidget {
  const _Composer({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: McColors.bgCard,
        borderRadius: BorderRadius.circular(McSpacing.radiusCard),
        border: Border.all(color: McColors.borderDefault, width: 0.5),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: McColors.gray400),
                  child: const Center(child: Icon(Icons.person, size: 20, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: McColors.bgInput, borderRadius: BorderRadius.circular(22)),
                    child: Text('Share something with your leaders...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: McColors.textTertiary)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _composerAction(Icons.campaign_outlined, 'Share Update', McColors.teal50, McColors.teal800),
              _composerAction(Icons.emoji_events_outlined, 'Recognition', McColors.amber50, McColors.amber800),
              _composerAction(Icons.poll_outlined, 'Poll', McColors.purple50, McColors.purple800),
              _composerAction(Icons.event_outlined, 'Event', McColors.teal50, McColors.teal800),
            ],
          ),
        ],
      ),
    );
  }

  Widget _composerAction(IconData icon, String label, Color tileBg, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: tileBg, borderRadius: BorderRadius.circular(9)),
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: McColors.textSecondary)),
      ],
    );
  }
}

// ─── TRENDING HEADER (matches V0 screenshot 1) ───
class _TrendingHeader extends StatelessWidget {
  const _TrendingHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, size: 18, color: McColors.amber400),
          const SizedBox(width: 6),
          Text('Trending in your org', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: McColors.gray900)),
          const Spacer(),
          Text('Recent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: McColors.textTertiary)),
        ],
      ),
    );
  }
}

// ─── POST CARD (matches V0 screenshots 1-4) ───
class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, this.onTap});
  final PostDto post;
  final VoidCallback? onTap;

  bool get _isCB => post.author?.isSystemAccount == true || post.authorId == AppConstants.connectBuddySystemAccountId;

  @override
  Widget build(BuildContext context) {
    final name = post.author?.fullName ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: McColors.bgCard,
          borderRadius: BorderRadius.circular(McSpacing.radiusCard),
          border: Border.all(color: McColors.borderDefault, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar (44px like V0)
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCB ? McColors.purple600 : McColors.teal800,
                    ),
                    child: Center(
                      child: _isCB
                          ? const Icon(Icons.smart_toy, size: 22, color: Colors.white)
                          : Text(initial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: McColors.gray900), overflow: TextOverflow.ellipsis)),
                            if (_isCB) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.verified, size: 15, color: McColors.teal400),
                            ],
                          ],
                        ),
                        Text(_isCB ? 'Community Bot' : 'Manager', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: McColors.textSecondary)),
                        Row(
                          children: [
                            Text(_formatTime(post.createdAt), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: McColors.textTertiary)),
                            const SizedBox(width: 3),
                            Text('·', style: TextStyle(fontSize: 10, color: McColors.textTertiary)),
                            const SizedBox(width: 3),
                            Icon(Icons.public, size: 11, color: McColors.textTertiary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz, size: 20, color: McColors.textTertiary),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(post.content, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.55, color: McColors.gray900)),
            ),
            // Engagement summary
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  // Reaction circles (stacked)
                  _reactionCircles(),
                  const SizedBox(width: 5),
                  Text('0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: McColors.textPrimary)),
                  const Spacer(),
                  Text('0 comments', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: McColors.textTertiary)),
                  Text('  ·  ', style: TextStyle(fontSize: 10, color: McColors.textTertiary)),
                  Text('0 reposts', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: McColors.textTertiary)),
                ],
              ),
            ),
            // Action row (4 equal columns with dividers)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: McColors.borderDefault, width: 0.5))),
              child: Row(
                children: [
                  _actionItem(Icons.auto_awesome_outlined, true),
                  _actionItem(Icons.chat_bubble_outline, false),
                  _actionItem(Icons.repeat, false),
                  _actionItem(Icons.send_outlined, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reactionCircles() {
    final types = [
      (McColors.amber50, McColors.amber400, Icons.emoji_events_outlined),
      (McColors.teal50, McColors.teal400, Icons.auto_awesome),
      (McColors.red50, McColors.red400, Icons.favorite_outline),
    ];
    return SizedBox(
      width: 52, height: 22,
      child: Stack(
        children: List.generate(3, (i) => Positioned(
          left: i * 15.0,
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, color: types[i].$1, border: Border.all(color: Colors.white, width: 2)),
            child: Center(child: Icon(types[i].$3, size: 10, color: types[i].$2)),
          ),
        )),
      ),
    );
  }

  Widget _actionItem(IconData icon, bool isFirst) {
    return Expanded(
      child: Container(
        decoration: isFirst ? null : BoxDecoration(border: Border(left: BorderSide(color: McColors.borderDefault, width: 0.5))),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Center(child: Icon(icon, size: 18, color: McColors.textSecondary)),
        ),
      ),
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
}
