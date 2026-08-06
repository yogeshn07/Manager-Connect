import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/recognition/data/models/recognition_dto.dart';
import 'package:manager_connect/features/recognition/presentation/providers/recognition_provider.dart';
import 'package:manager_connect/features/recognition/presentation/screens/create_recognition_screen.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class RecognitionFeedScreen extends ConsumerStatefulWidget {
  const RecognitionFeedScreen({super.key});

  @override
  ConsumerState<RecognitionFeedScreen> createState() =>
      _RecognitionFeedScreenState();
}

class _RecognitionFeedScreenState
    extends ConsumerState<RecognitionFeedScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(recognitionFeedProvider.notifier).load();
    });
  }

  static const _categoryLabels = {
    'community_contributor': 'Community Contributor',
    'fitness_champion': 'Fitness Champion',
    'wellness_champion': 'Wellness Champion',
    'event_champion': 'Event Champion',
    'most_supportive_manager': 'Most Supportive',
  };

  static const _categoryIcons = {
    'community_contributor': Icons.groups,
    'fitness_champion': Icons.fitness_center,
    'wellness_champion': Icons.spa,
    'event_champion': Icons.emoji_events,
    'most_supportive_manager': Icons.favorite,
  };

  final Map<String, Set<String>> _myReactions = {};
  final Map<String, Map<String, int>> _reactionCounts = {};
  static const _emojis = ['👏', '🎉', '❤️', '⭐'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recognitionFeedProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: MCAmbientIdentityBackground(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRecognition(context),
        backgroundColor: MCColors.amber,
        foregroundColor: MCColors.textPrimary,
        child: const Icon(Icons.star_rounded),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: MCColors.card,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: MCSpacing.md,
        right: MCSpacing.md,
        bottom: MCSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MCColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MCColors.primaryPale,
                borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: MCColors.primary,
              ),
            ),
          ),
          const SizedBox(width: MCSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recognition Wall', style: MCTypography.h3),
              Text('Celebrate your team', style: MCTypography.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RecognitionFeedState state) {
    if (state.isLoading && state.recognitions.isEmpty) {
      return const LoadingState();
    }
    if (state.error != null && state.recognitions.isEmpty) {
      return ErrorState(
        message: 'Failed to load recognitions',
        onRetry: () => ref.read(recognitionFeedProvider.notifier).load(),
      );
    }
    if (state.recognitions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: MCColors.amber,
      onRefresh: () => ref.read(recognitionFeedProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
            horizontal: MCSpacing.md, vertical: MCSpacing.sm),
        itemCount: state.recognitions.length,
        itemBuilder: (context, index) =>
            _buildRecognitionCard(state.recognitions[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MCColors.amberLight,
              borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 36,
              color: MCColors.amber,
            ),
          ),
          const SizedBox(height: MCSpacing.md),
          Text('No recognitions yet', style: MCTypography.h4),
          const SizedBox(height: MCSpacing.xs),
          Text(
            'Be the first to celebrate someone!',
            style: MCTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildRecognitionCard(RecognitionDto recognition) {
    final label =
        _categoryLabels[recognition.categoryTag] ?? recognition.categoryTag;
    final icon = _categoryIcons[recognition.categoryTag] ?? Icons.star;
    final giverName = recognition.giver?.fullName ?? 'Someone';
    final giverInitial =
        giverName.isNotEmpty ? giverName[0].toUpperCase() : 'S';

    _reactionCounts.putIfAbsent(recognition.id, () => {});
    _myReactions.putIfAbsent(recognition.id, () => {});

    return Padding(
      padding: const EdgeInsets.only(bottom: MCSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          border: Border.all(color: MCColors.border),
          boxShadow: MCColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: MCSpacing.borderRecog,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [MCColors.amber, MCColors.amberLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MCSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(recognition, giverInitial, giverName),
                  const SizedBox(height: MCSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MCColors.amberLight,
                      borderRadius:
                          BorderRadius.circular(MCSpacing.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 12, color: MCColors.amberDark),
                        const SizedBox(width: MCSpacing.xs2),
                        Text(
                          label,
                          style: MCTypography.overline
                              .copyWith(color: MCColors.amberDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MCSpacing.xs),
                  Text(recognition.message, style: MCTypography.body),
                  const SizedBox(height: MCSpacing.sm),
                  Row(
                    children: [
                      ..._emojis.map((emoji) =>
                          _buildReactionPill(recognition.id, emoji)),
                      const Spacer(),
                      Text(
                        _formatTime(recognition.createdAt),
                        style: MCTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    RecognitionDto recognition,
    String giverInitial,
    String giverName,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MCAvatar(
          initials: giverInitial,
          size: MCAvatar.sm,
          backgroundColor: MCColors.primaryMid,
        ),
        const SizedBox(width: MCSpacing.xs),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: MCTypography.bodySm,
              children: [
                TextSpan(
                  text: giverName,
                  style: MCTypography.bodySm.copyWith(
                    color: MCColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' recognized '),
                ..._buildRecipientSpans(recognition.recipients),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<InlineSpan> _buildRecipientSpans(
      List<RecognitionRecipientDto> recipients) {
    if (recipients.isEmpty) {
      return [const TextSpan(text: 'someone')];
    }
    final spans = <InlineSpan>[];
    for (var i = 0; i < recipients.length; i++) {
      final name = recipients[i].fullName ?? 'someone';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: MCColors.amberPale,
              borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
              border: Border.all(color: MCColors.amberLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MCAvatar(
                  initials: initial,
                  size: 14,
                  backgroundColor: MCColors.amber,
                ),
                const SizedBox(width: 3),
                Text(
                  name,
                  style: MCTypography.overline
                      .copyWith(color: MCColors.amberDark),
                ),
              ],
            ),
          ),
        ),
      );
      if (i < recipients.length - 1) {
        spans.add(const TextSpan(text: ', '));
      }
    }
    return spans;
  }

  Widget _buildReactionPill(String recognitionId, String emoji) {
    final count = _reactionCounts[recognitionId]?[emoji] ?? 0;
    final hasReacted = _myReactions[recognitionId]?.contains(emoji) ?? false;

    return Padding(
      padding: const EdgeInsets.only(right: MCSpacing.xs2),
      child: GestureDetector(
        onTap: () => _toggleReaction(recognitionId, emoji),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasReacted ? MCColors.amberLight : MCColors.borderLight,
            borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
            border: Border.all(
              color: hasReacted ? MCColors.amber : MCColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              if (count > 0) ...[
                const SizedBox(width: 3),
                Text(
                  '$count',
                  style: MCTypography.overline.copyWith(
                    color: hasReacted
                        ? MCColors.amberDark
                        : MCColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleReaction(String recognitionId, String emoji) {
    setState(() {
      final mySet = _myReactions.putIfAbsent(recognitionId, () => {});
      final counts = _reactionCounts.putIfAbsent(recognitionId, () => {});
      if (mySet.contains(emoji)) {
        mySet.remove(emoji);
        counts[emoji] = ((counts[emoji] ?? 1) - 1).clamp(0, 9999);
      } else {
        mySet.add(emoji);
        counts[emoji] = (counts[emoji] ?? 0) + 1;
      }
    });
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showCreateRecognition(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateRecognitionScreen(),
    );
  }
}
