import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

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
      backgroundColor: MCColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final markedCount = _attendance.length;
    return Container(
      color: MCColors.card,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 4,
        right: MCSpacing.pageH,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _selectedActivityId != null ? Icons.arrow_back : Icons.close,
              color: MCColors.textPrimary,
            ),
            onPressed: _selectedActivityId != null
                ? () => setState(() {
                      _selectedActivityId = null;
                      _attendance.clear();
                    })
                : () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record Attendance', style: MCTypography.h3),
                if (_selectedActivityTitle != null)
                  Text(
                    _selectedActivityTitle!,
                    style: MCTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (_selectedActivityId != null && _attendance.isNotEmpty)
            MCPrimaryButton(
              label: 'Save ($markedCount)',
              onPressed: _saving ? null : _save,
              loading: _saving,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingActivities) return const LoadingState(message: 'Loading events...');
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _loadActivities);
    }
    if (_selectedActivityId == null) return _buildActivityPicker();
    if (_loadingMembers) return const LoadingState(message: 'Loading members...');
    return _buildAttendanceList();
  }

  Widget _buildActivityPicker() {
    if (_pastActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MCColors.primaryPale,
                borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
              ),
              child: const Icon(Icons.event_busy_outlined, size: 36, color: MCColors.primaryMid),
            ),
            const SizedBox(height: MCSpacing.md),
            Text('No past events', style: MCTypography.h4),
            const SizedBox(height: 6),
            Text(
              'Attendance can only be recorded for past events',
              style: MCTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        MCSpacing.pageH, MCSpacing.md, MCSpacing.pageH, MCSpacing.xl),
      itemCount: _pastActivities.length,
      itemBuilder: (context, index) {
        final act = _pastActivities[index];
        final title = act['title'] as String;
        final date = DateTime.parse(act['event_date'] as String);

        return GestureDetector(
          onTap: () => _selectActivity(act['id'] as String, title),
          child: Container(
            margin: const EdgeInsets.only(bottom: MCSpacing.cardGap),
            padding: const EdgeInsets.all(MCSpacing.cardPadH),
            decoration: BoxDecoration(
              color: MCColors.card,
              borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
              border: Border.all(color: MCColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MCColors.primaryPale,
                    borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.event_outlined, color: MCColors.primaryMid, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: MCTypography.label),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(date.toLocal()),
                        style: MCTypography.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: MCColors.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        MCSpacing.pageH, MCSpacing.md, MCSpacing.pageH, MCSpacing.xl),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final userId = member['id'] as String;
        final name = member['full_name'] as String;
        final status = _attendance[userId];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: MCSpacing.cardPadH, vertical: 10),
          decoration: BoxDecoration(
            color: MCColors.card,
            borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
            border: Border.all(
              color: status == 'attended'
                  ? MCColors.success
                  : status == 'absent'
                      ? MCColors.error
                      : MCColors.border,
            ),
          ),
          child: Row(
            children: [
              MCAvatar(initials: _initials(name), size: MCSpacing.avatarMd),
              const SizedBox(width: 10),
              Expanded(child: Text(name, style: MCTypography.label)),
              const SizedBox(width: 8),
              _buildAttendanceToggle(userId, status),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceToggle(String userId, String? status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleChip(
          label: 'Present',
          active: status == 'attended',
          activeColor: MCColors.success,
          activeBg: MCColors.successBg,
          onTap: () => setState(() {
            if (status == 'attended') {
              _attendance.remove(userId);
            } else {
              _attendance[userId] = 'attended';
            }
          }),
        ),
        const SizedBox(width: 6),
        _buildToggleChip(
          label: 'Absent',
          active: status == 'absent',
          activeColor: MCColors.error,
          activeBg: MCColors.errorBg,
          onTap: () => setState(() {
            if (status == 'absent') {
              _attendance.remove(userId);
            } else {
              _attendance[userId] = 'absent';
            }
          }),
        ),
      ],
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool active,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? activeBg : MCColors.background,
          border: Border.all(
            color: active ? activeColor : MCColors.border,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: MCTypography.caption.copyWith(
            color: active ? activeColor : MCColors.textMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
