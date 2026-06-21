import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/recognition/data/models/recognition_dto.dart';
import 'package:manager_connect/features/recognition/presentation/providers/recognition_provider.dart';
import 'package:manager_connect/features/recognition/presentation/screens/create_recognition_screen.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recognitionFeedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recognition Wall')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRecognition(context),
        child: const Icon(Icons.star),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(RecognitionFeedState state) {
    if (state.isLoading && state.recognitions.isEmpty) {
      return const LoadingState(message: 'Loading recognitions...');
    }
    if (state.error != null && state.recognitions.isEmpty) {
      return ErrorState(
        message: 'Failed to load recognitions',
        onRetry: () => ref.read(recognitionFeedProvider.notifier).load(),
      );
    }
    if (state.recognitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline, size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No recognitions yet',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(recognitionFeedProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.recognitions.length,
        itemBuilder: (context, index) =>
            _buildRecognitionCard(state.recognitions[index]),
      ),
    );
  }

  Widget _buildRecognitionCard(RecognitionDto recognition) {
    final theme = Theme.of(context);
    final label = _categoryLabels[recognition.categoryTag] ??
        recognition.categoryTag;
    final icon = _categoryIcons[recognition.categoryTag] ?? Icons.star;
    final recipientNames = recognition.recipients
        .map((r) => r.fullName ?? 'Unknown')
        .join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    (recognition.giver?.fullName ?? '?')[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recognition.giver?.fullName ?? 'Unknown',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        _formatTime(recognition.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(icon, size: 16),
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(recognition.message, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.arrow_forward, size: 14,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    recipientNames,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
