import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class AttendanceRecordingScreen extends ConsumerStatefulWidget {
  const AttendanceRecordingScreen({super.key});

  @override
  ConsumerState<AttendanceRecordingScreen> createState() =>
      _AttendanceRecordingScreenState();
}

class _AttendanceRecordingScreenState
    extends ConsumerState<AttendanceRecordingScreen> {
  List<Map<String, dynamic>> _pastActivities = [];
  String? _selectedActivityId;
  String? _selectedActivityTitle;
  List<Map<String, dynamic>> _members = [];
  final _attendance = <String, String>{};
  bool _loadingActivities = true;
  bool _loadingMembers = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _loadingActivities = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client
          .from(Table.activities)
          .select('id, title, event_date')
          .lt('event_date', DateTime.now().toUtc().toIso8601String())
          .eq('status', 'active')
          .order('event_date', ascending: false)
          .limit(30);
      setState(() {
        _pastActivities = List<Map<String, dynamic>>.from(response);
        _loadingActivities = false;
      });
    } catch (e) {
      setState(() {
        _loadingActivities = false;
        _error = 'Failed to load activities';
      });
    }
  }

  Future<void> _selectActivity(String activityId, String title) async {
    setState(() {
      _selectedActivityId = activityId;
      _selectedActivityTitle = title;
      _loadingMembers = true;
      _attendance.clear();
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final members = await client
          .from(Table.profiles)
          .select('id, full_name')
          .eq('is_active', true)
          .eq('is_system_account', false)
          .order('full_name');

      final existing = await client
          .from(Table.eventAttendance)
          .select('user_id, status')
          .eq('activity_id', activityId);

      final presets = <String, String>{};
      for (final row in existing) {
        presets[row['user_id'] as String] = row['status'] as String;
      }

      setState(() {
        _members = List<Map<String, dynamic>>.from(members);
        _attendance.addAll(presets);
        _loadingMembers = false;
      });
    } catch (e) {
      setState(() => _loadingMembers = false);
      if (mounted) showErrorToast(context, 'Failed to load members');
    }
  }

  Future<void> _save() async {
    if (_selectedActivityId == null || _attendance.isEmpty) {
      showErrorToast(context, 'Mark at least one member');
      return;
    }

    setState(() => _saving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final records = _attendance.entries
          .map((e) => {'user_id': e.key, 'status': e.value})
          .toList();

      final response = await client.functions.invoke(
        'record-attendance',
        body: {
          'activity_id': _selectedActivityId,
          'records': records,
        },
      );

      if (response.status >= 400) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['error'] != null) {
          final error = data['error'] as Map<String, dynamic>;
          throw AppException(
            error['message'] as String? ?? 'Failed to record',
            response.status,
          );
        }
        throw AppException('Failed to record attendance', response.status);
      }

      if (mounted) showSuccessToast(context, 'Attendance recorded');
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to save attendance');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Attendance'),
        actions: [
          if (_selectedActivityId != null && _attendance.isNotEmpty)
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingActivities) return const LoadingState(message: 'Loading events...');
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _loadActivities);
    }

    if (_selectedActivityId == null) return _buildActivityPicker();
    if (_loadingMembers) return const LoadingState(message: 'Loading members...');
    return _buildAttendanceGrid();
  }

  Widget _buildActivityPicker() {
    if (_pastActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No past events', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Attendance can only be recorded for past events',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _pastActivities.length,
      itemBuilder: (context, index) {
        final act = _pastActivities[index];
        final title = act['title'] as String;
        final date = DateTime.parse(act['event_date'] as String);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.event),
            title: Text(title),
            subtitle: Text(DateFormat('EEE, MMM d').format(date.toLocal())),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectActivity(act['id'] as String, title),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceGrid() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedActivityId = null;
                  _attendance.clear();
                }),
              ),
              Expanded(
                child: Text(
                  _selectedActivityTitle ?? '',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_attendance.length} marked',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              final userId = member['id'] as String;
              final name = member['full_name'] as String;
              final status = _attendance[userId];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(name[0].toUpperCase()),
                ),
                title: Text(name),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'attended', label: Text('Present')),
                    ButtonSegment(value: 'absent', label: Text('Absent')),
                  ],
                  selected: status != null ? {status} : {},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (selected) {
                    setState(() {
                      if (selected.isEmpty) {
                        _attendance.remove(userId);
                      } else {
                        _attendance[userId] = selected.first;
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
