import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/events/data/repositories/activity_repository.dart';
import 'package:manager_connect/features/events/presentation/providers/activities_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  ConsumerState<CreateActivityScreen> createState() =>
      _CreateActivityScreenState();
}

class _CreateActivityScreenState
    extends ConsumerState<CreateActivityScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _costController = TextEditingController();
  String _category = 'outings';
  String? _eventType;
  DateTime? _eventDate;
  bool _submitting = false;

  static const _categories = {
    'games': 'Games',
    'outings': 'Outings',
    'social_connect': 'Social Connect',
  };

  static const _eventTypes = {
    'games': ['cricket', 'badminton', 'pickleball', 'table_tennis', 'other'],
    'social_connect': [
      'coffee_connect',
      'lunch_meetup',
      'dinner_meetup',
      'other'
    ],
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _eventDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      showErrorToast(context, 'Title is required');
      return;
    }
    if (_eventDate == null) {
      showErrorToast(context, 'Date and time are required');
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! AppAuthStateAuthenticated) return;

    setState(() => _submitting = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = ActivityRepository(client);
      await repo.createActivity(
        createdBy: authState.session.userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        eventCategory: _category,
        eventType: _eventType,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        eventDate: _eventDate!,
        costNote: _costController.text.trim().isNotEmpty
            ? _costController.text.trim()
            : null,
      );
      await ref.read(activitiesProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Event created');
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to create event');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
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
              initialSelection: _category,
              label: const Text('Category *'),
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: _categories.entries
                  .map((e) =>
                      DropdownMenuEntry(value: e.key, label: e.value))
                  .toList(),
              onSelected: _submitting
                  ? null
                  : (v) => setState(() {
                        _category = v ?? _category;
                        _eventType = null;
                      }),
            ),
            if (_eventTypes.containsKey(_category)) ...[
              const SizedBox(height: 16),
              DropdownMenu<String>(
                initialSelection: _eventType,
                label: const Text('Type'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: _eventTypes[_category]!
                    .map((t) => DropdownMenuEntry(
                        value: t,
                        label: t.replaceAll('_', ' ')))
                    .toList(),
                onSelected:
                    _submitting ? null : (v) => setState(() => _eventType = v),
              ),
            ],
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              leading: const Icon(Icons.calendar_today),
              title: Text(_eventDate == null
                  ? 'Pick date & time *'
                  : DateFormat('EEE, MMM d · h:mm a')
                      .format(_eventDate!)),
              onTap: _submitting ? null : _pickDate,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
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
            const SizedBox(height: 16),
            TextField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost Note',
                hintText: 'e.g. Free, Rs 200 per person',
                border: OutlineInputBorder(),
              ),
              enabled: !_submitting,
            ),
          ],
        ),
      ),
    );
  }
}
