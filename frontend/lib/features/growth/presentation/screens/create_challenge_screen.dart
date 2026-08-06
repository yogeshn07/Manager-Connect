import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/growth/data/repositories/challenge_repository.dart';
import 'package:manager_connect/features/growth/presentation/providers/challenge_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

// ── Task library ─────────────────────────────────────────────────────────────

const _fitnessTaskLibrary = <String, List<Map<String, dynamic>>>{
  'walking': [
    {'id': 'w_5k',  'label': '5,000 Steps',  'target': 5000.0,  'unit': 'steps'},
    {'id': 'w_10k', 'label': '10,000 Steps', 'target': 10000.0, 'unit': 'steps'},
    {'id': 'w_15k', 'label': '15,000 Steps', 'target': 15000.0, 'unit': 'steps'},
    {'id': 'w_20k', 'label': '20,000 Steps', 'target': 20000.0, 'unit': 'steps'},
    {'id': 'w_30k', 'label': '30,000 Steps', 'target': 30000.0, 'unit': 'steps'},
  ],
  'running': [
    {'id': 'r_5km',  'label': '5 km Run',            'target': 5.0,  'unit': 'km'},
    {'id': 'r_10km', 'label': '10 km Run',            'target': 10.0, 'unit': 'km'},
    {'id': 'r_21km', 'label': 'Half Marathon (21 km)', 'target': 21.0, 'unit': 'km'},
    {'id': 'r_42km', 'label': 'Full Marathon (42 km)', 'target': 42.0, 'unit': 'km'},
  ],
  'cycling': [
    {'id': 'c_20km',  'label': '20 km Ride',  'target': 20.0,  'unit': 'km'},
    {'id': 'c_30km',  'label': '30 km Ride',  'target': 30.0,  'unit': 'km'},
    {'id': 'c_50km',  'label': '50 km Ride',  'target': 50.0,  'unit': 'km'},
    {'id': 'c_100km', 'label': '100 km Ride', 'target': 100.0, 'unit': 'km'},
  ],
  'trekking': [
    {'id': 't_5km',  'label': '5 km Trek',  'target': 5.0,  'unit': 'km'},
    {'id': 't_10km', 'label': '10 km Trek', 'target': 10.0, 'unit': 'km'},
    {'id': 't_20km', 'label': '20 km Trek', 'target': 20.0, 'unit': 'km'},
    {'id': 't_30km', 'label': '30 km Trek', 'target': 30.0, 'unit': 'km'},
  ],
  'swimming': [
    {'id': 's_500m', 'label': '500 m Swim', 'target': 500.0,  'unit': 'm'},
    {'id': 's_1km',  'label': '1 km Swim',  'target': 1000.0, 'unit': 'm'},
    {'id': 's_2km',  'label': '2 km Swim',  'target': 2000.0, 'unit': 'm'},
    {'id': 's_5km',  'label': '5 km Swim',  'target': 5000.0, 'unit': 'm'},
  ],
  'gym': [
    {'id': 'g_5sessions',   'label': '5 Workouts',       'target': 5.0,   'unit': 'sessions'},
    {'id': 'g_10sessions',  'label': '10 Workouts',      'target': 10.0,  'unit': 'sessions'},
    {'id': 'g_20sessions',  'label': '20 Workouts',      'target': 20.0,  'unit': 'sessions'},
    {'id': 'g_bench50',     'label': 'Bench Press 50 kg','target': 50.0,  'unit': 'kg'},
    {'id': 'g_squat80',     'label': 'Squat 80 kg',      'target': 80.0,  'unit': 'kg'},
    {'id': 'g_deadlift100', 'label': 'Deadlift 100 kg',  'target': 100.0, 'unit': 'kg'},
    {'id': 'g_pushups100',  'label': '100 Push-ups',     'target': 100.0, 'unit': 'reps'},
    {'id': 'g_hiit10',      'label': '10 HIIT Sessions', 'target': 10.0,  'unit': 'sessions'},
    {'id': 'g_pullups50',   'label': '50 Pull-ups',      'target': 50.0,  'unit': 'reps'},
  ],
  'dieting': [
    {'id': 'd_1kg',      'label': 'Lose 1 kg',               'target': 1.0,  'unit': 'kg'},
    {'id': 'd_2kg',      'label': 'Lose 2 kg',               'target': 2.0,  'unit': 'kg'},
    {'id': 'd_3kg',      'label': 'Lose 3 kg',               'target': 3.0,  'unit': 'kg'},
    {'id': 'd_sugar30',  'label': 'Sugar Cut — 30 Days',      'target': 30.0, 'unit': 'days'},
    {'id': 'd_nojunk30', 'label': 'No Junk Food — 30 Days',   'target': 30.0, 'unit': 'days'},
    {'id': 'd_calorie30','label': 'Calorie Control — 30 Days','target': 30.0, 'unit': 'days'},
    {'id': 'd_water90',  'label': '3 L Water/Day — 30 Days',  'target': 90.0, 'unit': 'litres'},
  ],
};

const _wellnessTaskLibrary = <String, List<Map<String, dynamic>>>{
  'breathing': [
    {'id': 'br_5min_30',   'label': '5 min Breathing — 30 Days',  'target': 150.0, 'unit': 'min'},
    {'id': 'br_10min_30',  'label': '10 min Breathing — 30 Days', 'target': 300.0, 'unit': 'min'},
    {'id': 'br_pranayama', 'label': '30 Pranayama Sessions',       'target': 30.0,  'unit': 'sessions'},
    {'id': 'br_box20',     'label': '20 Box Breathing Sessions',   'target': 20.0,  'unit': 'sessions'},
    {'id': 'br_4_7_8',     'label': '4-7-8 Technique — 21 Days',  'target': 21.0,  'unit': 'days'},
  ],
  'meditation': [
    {'id': 'med_5min_30',  'label': '5 min Meditation — 30 Days',  'target': 150.0, 'unit': 'min'},
    {'id': 'med_10min_30', 'label': '10 min Meditation — 30 Days', 'target': 300.0, 'unit': 'min'},
    {'id': 'med_20min_30', 'label': '20 min Meditation — 30 Days', 'target': 600.0, 'unit': 'min'},
    {'id': 'med_30sess',   'label': '30 Meditation Sessions',       'target': 30.0,  'unit': 'sessions'},
  ],
  'sleep': [
    {'id': 'sl_7h_30',   'label': '7 h Sleep — 30 Nights',           'target': 210.0, 'unit': 'hours'},
    {'id': 'sl_8h_30',   'label': '8 h Sleep — 30 Nights',           'target': 240.0, 'unit': 'hours'},
    {'id': 'sl_early21', 'label': 'Early to Bed (before 11 PM) — 21 Days', 'target': 21.0, 'unit': 'days'},
    {'id': 'sl_noscrn21','label': 'No Screen 1 h Before Bed — 21 Days',    'target': 21.0, 'unit': 'days'},
  ],
  'hydration': [
    {'id': 'hyd_2l_30',    'label': '2 L Water/Day — 30 Days',     'target': 60.0, 'unit': 'litres'},
    {'id': 'hyd_3l_30',    'label': '3 L Water/Day — 30 Days',     'target': 90.0, 'unit': 'litres'},
    {'id': 'hyd_nosug_30', 'label': 'No Sugary Drinks — 30 Days',  'target': 30.0, 'unit': 'days'},
    {'id': 'hyd_green21',  'label': 'Daily Green Tea — 21 Days',   'target': 21.0, 'unit': 'days'},
  ],
  'mindfulness': [
    {'id': 'mf_journal30',  'label': 'Gratitude Journal — 30 Days',       'target': 30.0, 'unit': 'entries'},
    {'id': 'mf_noscrn_21',  'label': 'No Screen Before Bed — 21 Days',    'target': 21.0, 'unit': 'days'},
    {'id': 'mf_walk21',     'label': '21 Mindful Walks',                  'target': 21.0, 'unit': 'walks'},
    {'id': 'mf_digital30',  'label': 'Digital Detox 1 h/Day — 30 Days',   'target': 30.0, 'unit': 'days'},
  ],
  'yoga': [
    {'id': 'yg_10sess',  'label': '10 Yoga Sessions',           'target': 10.0,  'unit': 'sessions'},
    {'id': 'yg_20sess',  'label': '20 Yoga Sessions',           'target': 20.0,  'unit': 'sessions'},
    {'id': 'yg_30min30', 'label': '30 min Yoga/Day — 30 Days',  'target': 900.0, 'unit': 'min'},
    {'id': 'yg_21day',   'label': '21-Day Yoga Challenge',      'target': 21.0,  'unit': 'days'},
  ],
};

const _fitnessGoalTypeLabels = <String, String>{
  'walking':  'Walking',
  'running':  'Running',
  'cycling':  'Cycling',
  'trekking': 'Trekking',
  'swimming': 'Swimming',
  'gym':      'Gym',
  'dieting':  'Dieting',
};

const _wellnessGoalTypeLabels = <String, String>{
  'breathing':   'Breathing Exercises',
  'meditation':  'Meditation',
  'sleep':       'Sleep Improvement',
  'hydration':   'Hydration',
  'mindfulness': 'Mindfulness',
  'yoga':        'Yoga',
};

// ── Screen ────────────────────────────────────────────────────────────────────

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState
    extends ConsumerState<CreateChallengeScreen> {
  final _descController = TextEditingController();
  String _challengeType = 'fitness';
  String? _goalType;
  final List<String> _selectedTaskIds = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Map<String, String> get _currentGoalTypeLabels =>
      _challengeType == 'fitness' ? _fitnessGoalTypeLabels : _wellnessGoalTypeLabels;

  List<Map<String, dynamic>> get _currentTaskLibrary =>
      (_challengeType == 'fitness' ? _fitnessTaskLibrary : _wellnessTaskLibrary)[_goalType ?? ''] ?? [];

  String get _generatedTitle {
    final goalLabel = _currentGoalTypeLabels[_goalType ?? ''] ?? 'Challenge';
    return '$goalLabel Challenge';
  }

  IconData _goalTypeIcon(String key) {
    return switch (key) {
      'walking'    => Icons.directions_walk_outlined,
      'running'    => Icons.directions_run_outlined,
      'cycling'    => Icons.directions_bike_outlined,
      'trekking'   => Icons.hiking,
      'swimming'   => Icons.pool,
      'gym'        => Icons.fitness_center_outlined,
      'dieting'    => Icons.restaurant_menu_outlined,
      'breathing'  => Icons.air_outlined,
      'meditation' => Icons.self_improvement_outlined,
      'sleep'      => Icons.bedtime_outlined,
      'hydration'  => Icons.water_drop_outlined,
      'mindfulness'=> Icons.psychology_outlined,
      'yoga'       => Icons.accessibility_new_outlined,
      _            => Icons.star_outline,
    };
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? now : now.add(const Duration(days: 30)),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_goalType == null) {
      showErrorToast(context, 'Select a goal type');
      return;
    }
    if (_selectedTaskIds.isEmpty) {
      showErrorToast(context, 'Select at least one task');
      return;
    }
    if (_startDate == null || _endDate == null) {
      showErrorToast(context, 'Select start and end dates');
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! AppAuthStateAuthenticated) return;

    final allTasks = _currentTaskLibrary;
    final selectedTasks = allTasks
        .where((t) => _selectedTaskIds.contains(t['id']))
        .toList();

    setState(() => _submitting = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = ChallengeRepository(client);
      await repo.createChallenge(
        createdBy: authState.session.userId,
        title: _generatedTitle,
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        challengeType: _challengeType,
        goalType: _goalType!,
        startDate: _startDate!.toIso8601String().split('T')[0],
        endDate: _endDate!.toIso8601String().split('T')[0],
        selectedTasks: selectedTasks,
      );
      await ref.read(challengeListProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Challenge created!');
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to create challenge');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MCColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MCSpacing.pageH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroBanner(),
                  const SizedBox(height: MCSpacing.lg),
                  _buildSection('Challenge Type', _buildTypeCards()),
                  const SizedBox(height: MCSpacing.lg),
                  _buildSection(
                    _challengeType == 'fitness' ? 'Fitness Goal Type' : 'Wellness Goal Type',
                    _buildGoalTypeChips(),
                  ),
                  if (_goalType != null) ...[
                    const SizedBox(height: MCSpacing.lg),
                    _buildSection('Tasks (select all that apply)', _buildTaskSelector()),
                  ],
                  const SizedBox(height: MCSpacing.lg),
                  _buildSection('Dates', _buildDateRow()),
                  const SizedBox(height: MCSpacing.lg),
                  _buildSection('Description (optional)', _buildDescField()),
                  const SizedBox(height: MCSpacing.xl3),
                  MCPrimaryButton(
                    label: 'Create Challenge',
                    icon: Icons.flag_outlined,
                    onPressed: _submitting ? null : _submit,
                    loading: _submitting,
                  ),
                  const SizedBox(height: MCSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
            icon: const Icon(Icons.close, color: MCColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(child: Text('Create Challenge', style: MCTypography.h3)),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    final isWellness = _challengeType == 'wellness';
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWellness
              ? const [Color(0xFF059669), Color(0xFF10B981)]
              : const [Color(0xFF1E4585), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              isWellness ? Icons.spa_outlined : Icons.emoji_events_outlined,
              size: 110,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MCSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                  ),
                  child: Text(
                    'NEW CHALLENGE',
                    style: MCTypography.overline.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isWellness ? 'Nurture your well-being' : 'Build healthy habits together',
                  style: MCTypography.h4.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: MCTypography.overline.copyWith(color: MCColors.textMuted),
        ),
        const SizedBox(height: MCSpacing.xs),
        content,
      ],
    );
  }

  // ── Challenge type cards ────────────────────────────────────────────────────

  Widget _buildTypeCards() {
    return Row(
      children: [
        _typeCard('fitness', 'Fitness', Icons.fitness_center_outlined,
            const [Color(0xFF1E4585), Color(0xFF2563EB)]),
        const SizedBox(width: 8),
        _typeCard('wellness', 'Wellness', Icons.self_improvement_outlined,
            const [Color(0xFF059669), Color(0xFF10B981)]),
      ],
    );
  }

  Widget _typeCard(String key, String label, IconData icon, List<Color> gradient) {
    final active = _challengeType == key;
    return Expanded(
      child: GestureDetector(
        onTap: _submitting
            ? null
            : () => setState(() {
                  _challengeType = key;
                  _goalType = null;
                  _selectedTaskIds.clear();
                }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? null : MCColors.card,
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  )
                : null,
            border: Border.all(
              color: active ? Colors.transparent : MCColors.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
            boxShadow: active ? MCColors.primaryButtonShadow : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: active ? Colors.white : MCColors.textMuted,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: MCTypography.label.copyWith(
                  color: active ? Colors.white : MCColors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Goal type chips ─────────────────────────────────────────────────────────

  Widget _buildGoalTypeChips() {
    final labels = _currentGoalTypeLabels;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.entries.map((e) {
        final active = _goalType == e.key;
        return GestureDetector(
          onTap: _submitting
              ? null
              : () => setState(() {
                    _goalType = e.key;
                    _selectedTaskIds.clear();
                  }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active ? MCColors.primaryMid : MCColors.card,
              border: Border.all(
                color: active ? MCColors.primaryMid : MCColors.border,
                width: active ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: MCColors.primaryMid.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _goalTypeIcon(e.key),
                  size: 15,
                  color: active ? Colors.white : MCColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  e.value,
                  style: MCTypography.caption.copyWith(
                    color: active ? Colors.white : MCColors.textSecondary,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Task multi-select ───────────────────────────────────────────────────────

  Widget _buildTaskSelector() {
    final tasks = _currentTaskLibrary;
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.checklist_outlined, size: 16, color: MCColors.primaryMid),
                const SizedBox(width: 6),
                Text(
                  'Pick one or more targets',
                  style: MCTypography.caption.copyWith(color: MCColors.textSecondary),
                ),
                const Spacer(),
                if (_selectedTaskIds.isNotEmpty)
                  Text(
                    '${_selectedTaskIds.length} selected',
                    style: MCTypography.caption.copyWith(
                      color: MCColors.primaryMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...tasks.map((task) {
            final id = task['id'] as String;
            final label = task['label'] as String;
            final target = task['target'] as double;
            final unit = task['unit'] as String;
            final selected = _selectedTaskIds.contains(id);

            return InkWell(
              onTap: _submitting
                  ? null
                  : () => setState(() {
                        selected
                            ? _selectedTaskIds.remove(id)
                            : _selectedTaskIds.add(id);
                      }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                color: selected
                    ? MCColors.primaryPale
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: selected ? MCColors.primaryMid : Colors.transparent,
                        border: Border.all(
                          color: selected ? MCColors.primaryMid : MCColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: selected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: MCTypography.body.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? MCColors.primaryMid
                                  : MCColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Target: ${_formatTarget(target)} $unit',
                            style: MCTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatTarget(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  // ── Dates ───────────────────────────────────────────────────────────────────

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(child: _buildDateTile(isStart: true)),
        const SizedBox(width: 8),
        Expanded(child: _buildDateTile(isStart: false)),
      ],
    );
  }

  Widget _buildDateTile({required bool isStart}) {
    final date = isStart ? _startDate : _endDate;
    final label = isStart ? 'Start Date' : 'End Date';
    final hasDate = date != null;

    return GestureDetector(
      onTap: _submitting ? null : () => _pickDate(isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: MCColors.card,
          border: Border.all(
              color: hasDate ? MCColors.primaryMid : MCColors.border),
          borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: hasDate ? MCColors.primaryMid : MCColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: MCTypography.caption
                        .copyWith(color: MCColors.textMuted, fontSize: 10),
                  ),
                  Text(
                    hasDate
                        ? DateFormat('MMM d, yyyy').format(date)
                        : 'required',
                    style: MCTypography.label.copyWith(
                      color:
                          hasDate ? MCColors.textPrimary : MCColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Description ─────────────────────────────────────────────────────────────

  Widget _buildDescField() {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
      ),
      child: TextField(
        controller: _descController,
        enabled: !_submitting,
        maxLines: 3,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Describe the challenge or set any rules...',
          hintStyle: TextStyle(color: MCColors.textMuted, fontSize: 14),
          contentPadding: EdgeInsets.all(MCSpacing.md),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
