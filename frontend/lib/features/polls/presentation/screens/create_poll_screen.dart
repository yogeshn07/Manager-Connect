import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/polls/data/repositories/poll_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_inputs.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class CreatePollScreen extends ConsumerStatefulWidget {
  const CreatePollScreen({super.key});

  @override
  ConsumerState<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends ConsumerState<CreatePollScreen> {
  final _questionController = TextEditingController();
  final _optionControllers  = [TextEditingController(), TextEditingController()];
  DateTime? _closesAt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _questionController.addListener(() => setState(() {}));
  }

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

  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate:   now,
      lastDate:    now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _closesAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
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
      final repo   = PollRepository(client);
      await repo.createPoll(
        question: question,
        options:  options,
        closesAt: _closesAt!,
      );
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Poll created');
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to create poll');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: const BoxDecoration(
                color: MCColors.card,
                border: Border(bottom: BorderSide(color: MCColors.borderLight)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    color: MCColors.textPrimary,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Create Poll', style: MCTypography.h3),
                      Text('Community vote', style: MCTypography.caption),
                    ],
                  ),
                  const Spacer(),
                  // Violet CTA
                  GestureDetector(
                    onTap: _submitting ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      decoration: BoxDecoration(
                        color: MCColors.violet,
                        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                        boxShadow: [
                          BoxShadow(
                            color: MCColors.violet.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Launch',
                              style: MCTypography.labelSm.copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MCSpacing.pageH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Violet accent banner ──────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MCColors.violetLight,
                        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
                        border: const Border(
                          left: BorderSide(
                            color: MCColors.violet,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: MCColors.violetLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.poll,
                              color: MCColors.violet,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Community Poll',
                                  style: MCTypography.h4.copyWith(
                                    color: MCColors.violet,
                                  ),
                                ),
                                Text(
                                  'Results shared with all members',
                                  style: MCTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Question ──────────────────────────────────────
                    Text('Poll question *', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    MCInput(
                      controller: _questionController,
                      hint: 'What would you like to ask?',
                      prefixIcon: Icons.help_outline,
                      maxLines: 3,
                      minLines: 2,
                      enabled: !_submitting,
                      focusColor: MCColors.violet,
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Options ───────────────────────────────────────
                    Row(
                      children: [
                        Text('Options', style: MCTypography.h4),
                        const Spacer(),
                        Text(
                          '${_optionControllers.length}/10',
                          style: MCTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_optionControllers.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: MCColors.violetLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: MCTypography.labelSm.copyWith(
                                    color: MCColors.violet,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MCInput(
                                controller: _optionControllers[i],
                                hint: 'Option ${i + 1}',
                                enabled: !_submitting,
                                focusColor: MCColors.violet,
                              ),
                            ),
                            if (_optionControllers.length > 2) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeOption(i),
                                child: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                  color: MCColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    if (_optionControllers.length < 10)
                      GestureDetector(
                        onTap: _submitting ? null : _addOption,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: MCColors.card,
                            borderRadius:
                                BorderRadius.circular(MCSpacing.radiusSm),
                            border: Border.all(
                              color: MCColors.violet.withValues(alpha: 0.4),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 16,
                                color: MCColors.violet,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Add option',
                                style: MCTypography.label.copyWith(
                                  color: MCColors.violet,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Closing date ──────────────────────────────────
                    Text('Closing date *', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _submitting ? null : _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: MCColors.card,
                          borderRadius:
                              BorderRadius.circular(MCSpacing.radiusInput),
                          border: Border.all(color: MCColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 18,
                              color: MCColors.violet,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _closesAt == null
                                  ? 'Set closing date & time'
                                  : 'Closes ${DateFormat('EEE, MMM d · h:mm a').format(_closesAt!)}',
                              style: MCTypography.body.copyWith(
                                color: _closesAt == null
                                    ? MCColors.textMuted
                                    : MCColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: MCColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Submit ────────────────────────────────────────
                    GestureDetector(
                      onTap: _submitting ? null : _submit,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: MCColors.violet,
                          borderRadius:
                              BorderRadius.circular(MCSpacing.radiusButton),
                          boxShadow: [
                            BoxShadow(
                              color: MCColors.violet.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Launch Poll',
                                  style: MCTypography.labelLg.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
