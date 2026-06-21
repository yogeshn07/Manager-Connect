import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/growth/data/models/challenge_dto.dart';
import 'package:manager_connect/features/growth/presentation/providers/challenge_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  const ChallengeDetailScreen({required this.challengeId, super.key});

  final String challengeId;

  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState
    extends ConsumerState<ChallengeDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(challengeDetailProvider(widget.challengeId).notifier).load();
    });
  }

  String? get _currentUserId {
    final authState = ref.read(authProvider);
    if (authState is AppAuthStateAuthenticated) {
      return authState.session.userId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeDetailProvider(widget.challengeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge Details')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ChallengeDetailState state) {
    if (state.isLoading) return const LoadingState();
    if (state.error != null || state.challenge == null) {
      return ErrorState(
        message: 'Failed to load challenge',
        onRetry: () => ref
            .read(challengeDetailProvider(widget.challengeId).notifier)
            .load(),
      );
    }

    final challenge = state.challenge!;
    final theme = Theme.of(context);
    final userId = _currentUserId;
    final isParticipant =
        state.participants.any((p) => p.userId == userId);
    final myParticipant = state.participants
        .where((p) => p.userId == userId)
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref
          .read(challengeDetailProvider(widget.challengeId).notifier)
          .load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(challenge.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          _infoRow(Icons.category_outlined,
              challenge.challengeType.replaceAll('_', ' ')),
          _infoRow(Icons.track_changes_outlined,
              'Goal: ${challenge.goalType.replaceAll('_', ' ')}'),
          if (challenge.goalDescription != null)
            _infoRow(Icons.description_outlined, challenge.goalDescription!),
          _infoRow(Icons.calendar_today,
              '${_formatDate(challenge.startDate)} – ${_formatDate(challenge.endDate)}'),
          _infoRow(Icons.info_outline,
              'Status: ${challenge.status}'),
          _infoRow(Icons.person_outline,
              'Created by ${challenge.authorName ?? 'Unknown'}'),
          if (challenge.description != null) ...[
            const Divider(height: 32),
            Text(challenge.description!, style: theme.textTheme.bodyLarge),
          ],
          const Divider(height: 32),

          // Join / Leave button
          if (userId != null && !challenge.isEnded)
            isParticipant
                ? OutlinedButton.icon(
                    onPressed: () => _leave(userId),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave Challenge'),
                  )
                : FilledButton.icon(
                    onPressed: () => _join(userId),
                    icon: const Icon(Icons.add),
                    label: const Text('Join Challenge'),
                  ),

          // Log Progress button
          if (isParticipant &&
              !challenge.isEnded &&
              myParticipant.isNotEmpty) ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () =>
                  _showLogProgress(userId!, myParticipant.first.id),
              child: const Text('Log Progress'),
            ),
          ],

          const SizedBox(height: 24),

          // Leaderboard
          Text('Leaderboard', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.leaderboard.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No progress logged yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...state.leaderboard.entries.toList().asMap().entries.map(
                  (entry) => _buildLeaderboardTile(
                    rank: entry.key + 1,
                    userId: entry.value.key,
                    totalValue: entry.value.value,
                    participants: state.participants,
                    theme: theme,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile({
    required int rank,
    required String userId,
    required double totalValue,
    required List<ParticipantDto> participants,
    required ThemeData theme,
  }) {
    final participant = participants
        .where((p) => p.userId == userId)
        .toList();
    final name = participant.isNotEmpty
        ? (participant.first.fullName ?? 'Unknown')
        : 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ListTile(
      dense: true,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: rank <= 3
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 16,
            child: Text(initial, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
      title: Text(name),
      trailing: Text(
        totalValue.toStringAsFixed(1),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _join(String userId) async {
    await ref
        .read(challengeDetailProvider(widget.challengeId).notifier)
        .join(userId);
    if (mounted) showSuccessToast(context, 'Joined challenge');
  }

  Future<void> _leave(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Challenge'),
        content:
            const Text('Your progress will be removed. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(challengeDetailProvider(widget.challengeId).notifier)
        .leave(userId);
    if (mounted) showSuccessToast(context, 'Left challenge');
  }

  void _showLogProgress(String userId, String participantId) {
    final valueController = TextEditingController();
    final noteController = TextEditingController();
    var selectedDate = DateTime.now();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log Progress',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('EEEE, MMMM d').format(selectedDate)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setSheetState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  hintText: 'e.g. 30 (minutes, steps, etc.)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'What did you do?',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final value =
                      double.tryParse(valueController.text.trim());
                  if (value == null || value <= 0) {
                    showErrorToast(ctx, 'Enter a valid value');
                    return;
                  }
                  Navigator.of(ctx).pop();
                  final logDate = DateFormat('yyyy-MM-dd')
                      .format(selectedDate);
                  final note = noteController.text.trim();
                  await ref
                      .read(challengeDetailProvider(widget.challengeId)
                          .notifier)
                      .logProgress(
                        userId: userId,
                        participantId: participantId,
                        logDate: logDate,
                        value: value,
                        note: note.isNotEmpty ? note : null,
                      );
                  if (mounted) {
                    showSuccessToast(context, 'Progress logged');
                  }
                },
                child: const Text('Submit'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
