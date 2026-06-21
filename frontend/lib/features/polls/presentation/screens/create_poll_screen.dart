import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/polls/data/repositories/poll_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class CreatePollScreen extends ConsumerStatefulWidget {
  const CreatePollScreen({super.key});

  @override
  ConsumerState<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends ConsumerState<CreatePollScreen> {
  final _questionController = TextEditingController();
  final _optionControllers = [TextEditingController(), TextEditingController()];
  DateTime? _closesAt;
  bool _submitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _pickClosesAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _closesAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      showErrorToast(context, 'Question is required');
      return;
    }
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (options.length < 2) {
      showErrorToast(context, 'At least 2 options are required');
      return;
    }
    if (_closesAt == null) {
      showErrorToast(context, 'Closing date is required');
      return;
    }

    setState(() => _submitting = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = PollRepository(client);
      await repo.createPoll(
        question: question,
        options: options,
        closesAt: _closesAt!,
      );
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Poll created');
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to create poll');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Poll'),
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
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              enabled: !_submitting,
            ),
            const SizedBox(height: 24),
            Text('Options', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(_optionControllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _optionControllers[i],
                  decoration: InputDecoration(
                    labelText: 'Option ${i + 1}',
                    border: const OutlineInputBorder(),
                    suffixIcon: _optionControllers.length > 2
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeOption(i),
                          )
                        : null,
                  ),
                  enabled: !_submitting,
                ),
              );
            }),
            if (_optionControllers.length < 10)
              TextButton.icon(
                onPressed: _submitting ? null : _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              leading: const Icon(Icons.schedule),
              title: Text(_closesAt == null
                  ? 'Set closing date *'
                  : 'Closes ${DateFormat('EEE, MMM d · h:mm a').format(_closesAt!)}'),
              onTap: _submitting ? null : _pickClosesAt,
            ),
          ],
        ),
      ),
    );
  }
}
