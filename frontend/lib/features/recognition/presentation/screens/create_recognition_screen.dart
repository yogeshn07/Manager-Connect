import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/recognition/data/repositories/recognition_repository.dart';
import 'package:manager_connect/features/recognition/presentation/providers/recognition_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class CreateRecognitionScreen extends ConsumerStatefulWidget {
  const CreateRecognitionScreen({super.key});

  @override
  ConsumerState<CreateRecognitionScreen> createState() =>
      _CreateRecognitionScreenState();
}

class _CreateRecognitionScreenState
    extends ConsumerState<CreateRecognitionScreen> {
  final _messageController = TextEditingController();
  final _selectedRecipients = <String>{};
  String? _categoryTag;
  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = true;
  bool _submitting = false;

  static const _categories = {
    'community_contributor': 'Community Contributor',
    'fitness_champion': 'Fitness Champion',
    'wellness_champion': 'Wellness Champion',
    'event_champion': 'Event Champion',
    'most_supportive_manager': 'Most Supportive Manager',
  };

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = RecognitionRepository(client);
      final members = await repo.getActiveMembers();
      if (mounted) setState(() { _members = members; _loadingMembers = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedRecipients.isEmpty) {
      showErrorToast(context, 'Select at least one recipient');
      return;
    }
    if (_categoryTag == null) {
      showErrorToast(context, 'Select a category');
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      showErrorToast(context, 'Write a message');
      return;
    }

    setState(() => _submitting = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = RecognitionRepository(client);
      await repo.createRecognition(
        recipientIds: _selectedRecipients.toList(),
        categoryTag: _categoryTag!,
        message: _messageController.text.trim(),
      );
      await ref.read(recognitionFeedProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Recognition sent!');
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to send recognition');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Give Recognition'),
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
                : const Text('Send'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Category *',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.entries.map((e) {
                final selected = _categoryTag == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _categoryTag = e.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Recipients *',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loadingMembers)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _members.map((m) {
                  final id = m['id'] as String;
                  final name = m['full_name'] as String;
                  final selected = _selectedRecipients.contains(id);
                  return FilterChip(
                    label: Text(name),
                    selected: selected,
                    onSelected: _submitting
                        ? null
                        : (v) => setState(() {
                              if (v) {
                                _selectedRecipients.add(id);
                              } else {
                                _selectedRecipients.remove(id);
                              }
                            }),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message *',
                hintText: 'Why are you recognizing them?',
                border: const OutlineInputBorder(),
                counterText:
                    '${_messageController.text.length}/${AppConstants.maxRecognitionMessageLength}',
              ),
              maxLines: 4,
              maxLength: AppConstants.maxRecognitionMessageLength,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_submitting,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
