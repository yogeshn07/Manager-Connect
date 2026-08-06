import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class SearchSheet extends ConsumerStatefulWidget {
  const SearchSheet({super.key});

  @override
  ConsumerState<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<SearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<PostDto> _posts = [];
  List<Map<String, dynamic>> _members = [];

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _posts = []; _members = []; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    final client = ref.read(supabaseClientProvider);
    final repo = FeedRepository(client);
    try {
      final results = await Future.wait([
        repo.searchPosts(q),
        repo.searchProfiles(q),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = results[0] as List<PostDto>;
        _members = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: MCSpacing.pageH, vertical: 12),
              decoration: const BoxDecoration(
                color: MCColors.card,
                border:
                    Border(bottom: BorderSide(color: MCColors.borderLight)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios,
                        size: 20, color: MCColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: MCColors.background,
                        borderRadius:
                            BorderRadius.circular(MCSpacing.radiusPill),
                        border: Border.all(color: MCColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              size: 22, color: MCColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              onChanged: _onChanged,
                              decoration: InputDecoration(
                                hintText: 'Search posts or members…',
                                hintStyle: MCTypography.bodyLg
                                    .copyWith(color: MCColors.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: MCTypography.bodyLg,
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                _onChanged('');
                              },
                              child: const Icon(Icons.close,
                                  size: 18, color: MCColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Results
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: MCColors.primary))
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_controller.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 48, color: MCColors.textMuted),
            const SizedBox(height: 12),
            Text('Search posts and members',
                style: MCTypography.caption),
          ],
        ),
      );
    }
    if (_posts.isEmpty && _members.isEmpty) {
      return Center(
        child: Text('No results for "${_controller.text}"',
            style: MCTypography.caption),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(MCSpacing.pageH),
      children: [
        if (_members.isNotEmpty) ...[
          Text('Members', style: MCTypography.h4),
          const SizedBox(height: 8),
          ..._members.map(_memberTile),
          const SizedBox(height: 20),
        ],
        if (_posts.isNotEmpty) ...[
          Text('Posts', style: MCTypography.h4),
          const SizedBox(height: 8),
          ..._posts.map(_postTile),
        ],
      ],
    );
  }

  Widget _memberTile(Map<String, dynamic> m) {
    final name = m['full_name'] as String? ?? '';
    final title = m['title'] as String? ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        context.push('/profile/${m['id'] as String}');
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            MCAvatar(
              initials: initials,
              size: MCAvatar.md,
              backgroundColor: MCColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: MCTypography.h4),
                  if (title.isNotEmpty)
                    Text(title, style: MCTypography.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: MCColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _postTile(PostDto post) {
    final name = post.author?.fullName ?? 'Unknown';
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        context.push('/feed/post/${post.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          border: Border.all(color: MCColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: MCTypography.labelSm
                    .copyWith(color: MCColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              post.content,
              style: MCTypography.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
