import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class ShareAchievementSheet extends ConsumerStatefulWidget {
  const ShareAchievementSheet({this.onShared, super.key});

  final VoidCallback? onShared;

  @override
  ConsumerState<ShareAchievementSheet> createState() =>
      _ShareAchievementSheetState();
}

class _ShareAchievementSheetState
    extends ConsumerState<ShareAchievementSheet> {
  bool _loading = true;
  bool _posting = false;
  List<Map<String, dynamic>> _recognitions = [];
  String? _error;

  static const _categoryLabels = <String, String>{
    'community_contributor': 'Community Contributor',
    'fitness_champion': 'Fitness Champion',
    'wellness_champion': 'Wellness Champion',
    'event_champion': 'Event Champion',
    'most_supportive_manager': 'Most Supportive Manager',
  };

  static const _categoryIcons = <String, IconData>{
    'community_contributor': Icons.people_outline,
    'fitness_champion': Icons.fitness_center,
    'wellness_champion': Icons.spa_outlined,
    'event_champion': Icons.emoji_events_outlined,
    'most_supportive_manager': Icons.handshake_outlined,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (auth is! AppAuthStateAuthenticated) {
      setState(() { _loading = false; _error = 'Not authenticated'; });
      return;
    }
    try {
      final client = ref.read(supabaseClientProvider);
      final rows = await FeedRepository(client)
          .getUserRecognitions(auth.session.userId);
      if (mounted) setState(() { _recognitions = rows; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _shareRecognition(Map<String, dynamic> rec) async {
    if (_posting) return;
    final auth = ref.read(authProvider);
    if (auth is! AppAuthStateAuthenticated) return;

    final tag = rec['category_tag'] as String? ?? '';
    final message = rec['message'] as String? ?? '';
    final giverName = rec['giver_name'] as String? ?? 'a teammate';
    final label = _categoryLabels[tag] ?? tag;

    final postContent =
        '🏆 Achievement Unlocked: $label\n\n"$message"\n\n— Recognized by $giverName';

    setState(() => _posting = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await FeedRepository(client).createPost(content: postContent);
      await ref.read(feedProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        widget.onShared?.call();
        showSuccessToast(context, 'Achievement shared!');
      }
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to share achievement');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle + header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  MCSpacing.pageH, MCSpacing.pageH, MCSpacing.pageH, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: MCColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Share Achievement', style: MCTypography.h3),
                  const SizedBox(height: 4),
                  Text(
                    'Post a recognition you received to the community feed.',
                    style: MCTypography.caption,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: MCColors.borderLight),
                ],
              ),
            ),

            // Body
            Flexible(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: MCColors.primary)),
      );
    }
    if (_error != null || _recognitions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_outlined,
                  size: 48, color: MCColors.textMuted),
              const SizedBox(height: 12),
              Text('No new achievement to post',
                  style: MCTypography.h4, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Achievements will appear here once your teammates recognize you.',
                style: MCTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: MCSpacing.pageH, vertical: MCSpacing.sm),
      itemCount: _recognitions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: MCColors.borderLight),
      itemBuilder: (ctx, i) => _recognitionTile(_recognitions[i]),
    );
  }

  Widget _recognitionTile(Map<String, dynamic> rec) {
    final tag = rec['category_tag'] as String? ?? '';
    final message = rec['message'] as String? ?? '';
    final giverName = rec['giver_name'] as String? ?? 'Unknown';
    final label = _categoryLabels[tag] ?? tag;
    final icon = _categoryIcons[tag] ?? Icons.star_outline;

    return GestureDetector(
      onTap: _posting ? null : () => _shareRecognition(rec),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: MCColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
              ),
              child: Icon(icon, size: 22, color: MCColors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: MCTypography.labelSm
                          .copyWith(color: MCColors.primaryMid)),
                  const SizedBox(height: 4),
                  Text(message, style: MCTypography.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('From $giverName', style: MCTypography.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _posting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MCColors.primary))
                : const Icon(Icons.share_outlined,
                    size: 18, color: MCColors.textMuted),
          ],
        ),
      ),
    );
  }
}
