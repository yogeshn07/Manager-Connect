import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/growth/data/repositories/challenge_repository.dart';
import 'package:manager_connect/features/growth/presentation/providers/challenge_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState
    extends ConsumerState<CreateChallengeScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _goalDescController = TextEditingController();
  String _challengeType = 'fitness';
  String _goalType = 'steps';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  static const _challengeTypes = {'fitness': 'Fitness', 'wellness': 'Wellness'};
  static const _goalTypes = {
    'steps': 'Steps',
    'distance': 'Distance',
    'duration': 'Duration',
    'custom': 'Custom',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _goalDescController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? now : now.add(const Duration(days: 7)),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = date;
        if (_endDate != null && _endDate!.isBefore(date)) _endDate = null;
      } else {
        _endDate = date;
      }
    });
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      showErrorToast(context, 'Title is required');
      return;
    }
    if (_startDate == null || _endDate == null) {
      showErrorToast(context, 'Start and end dates are required');
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! AppAuthStateAuthenticated) return;

    setState(() => _submitting = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = ChallengeRepository(client);
      await repo.createChallenge(
        createdBy: authState.session.userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        challengeType: _challengeType,
        goalType: _goalType,
        goalDescription: _goalDescController.text.trim().isNotEmpty
            ? _goalDescController.text.trim()
            : null,
        startDate: _startDate!.toIso8601String().split('T')[0],
        endDate: _endDate!.toIso8601String().split('T')[0],
      );
      await ref.read(challengeListProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Challenge created');
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to create challenge');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              enabled: !_submitting,
            ),
            const SizedBox(height: 16),
            DropdownMenu<String>(
              initialSelection: _challengeType,
              label: const Text('Type *'),
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: _challengeTypes.entries
                  .map((e) => DropdownMenuEntry(value: e.key, label: e.value))
                  .toList(),
              onSelected: _submitting
                  ? null
                  : (v) => setState(() => _challengeType = v ?? _challengeType),
            ),
            const SizedBox(height: 16),
            DropdownMenu<String>(
              initialSelection: _goalType,
              label: const Text('Goal Type *'),
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: _goalTypes.entries
                  .map((e) => DropdownMenuEntry(value: e.key, label: e.value))
                  .toList(),
              onSelected: _submitting
                  ? null
                  : (v) => setState(() => _goalType = v ?? _goalType),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    leading: const Icon(Icons.calendar_today, size: 18),
                    title: Text(_startDate == null
                        ? 'Start *'
                        : DateFormat('MMM d').format(_startDate!)),
                    onTap: _submitting ? null : () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    leading: const Icon(Icons.event, size: 18),
                    title: Text(_endDate == null
                        ? 'End *'
                        : DateFormat('MMM d').format(_endDate!)),
                    onTap: _submitting ? null : () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _goalDescController,
              decoration: const InputDecoration(
                labelText: 'Goal Description',
                hintText: 'e.g. Walk 10,000 steps daily',
                border: OutlineInputBorder(),
              ),
              enabled: !_submitting,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_submitting,
            ),
          ],
        ),
      ),
    );
  }
}
