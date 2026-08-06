import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class CreatePollSheet extends StatefulWidget {
  const CreatePollSheet({required this.onCreatePoll, super.key});

  final void Function(String question, List<String> options, int closesInDays) onCreatePoll;

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _closesInDays = 7;
  bool _submitting = false;

  static const _maxOptions = 4;
  static const _durations = [1, 3, 7, 14, 30];

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length >= _maxOptions) return;
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_optionCtrls.length <= 2) return;
    setState(() {
      _optionCtrls[i].dispose();
      _optionCtrls.removeAt(i);
    });
  }

  bool get _isValid {
    final question = _questionCtrl.text.trim();
    if (question.length < 3) return false;
    final filled = _optionCtrls.where((c) => c.text.trim().isNotEmpty).length;
    return filled >= 2;
  }

  void _submit() {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    final question = _questionCtrl.text.trim();
    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    Navigator.of(context).pop();
    widget.onCreatePoll(question, options, _closesInDays);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MCSpacing.pageH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: MCColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text('Create Poll', style: MCTypography.h3),
                const SizedBox(height: 4),
                Text(
                  'Community members can vote and see who voted for each option.',
                  style: MCTypography.caption,
                ),
                const SizedBox(height: 20),

                // Question
                Text('Question', style: MCTypography.h4),
                const SizedBox(height: 8),
                _InputField(
                  controller: _questionCtrl,
                  hint: 'Ask a question…',
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Options
                Text('Options', style: MCTypography.h4),
                const SizedBox(height: 8),
                ...List.generate(_optionCtrls.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            controller: _optionCtrls[i],
                            hint: 'Option ${i + 1}',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_optionCtrls.length > 2) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _removeOption(i),
                            child: const Icon(Icons.remove_circle_outline,
                                size: 20, color: MCColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (_optionCtrls.length < _maxOptions)
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add option'),
                    style: TextButton.styleFrom(
                      foregroundColor: MCColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),

                const SizedBox(height: 20),

                // Duration
                Text('Poll duration', style: MCTypography.h4),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _durations
                      .map((d) => GestureDetector(
                            onTap: () => setState(() => _closesInDays = d),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: _closesInDays == d
                                    ? MCColors.primaryMid
                                    : MCColors.background,
                                borderRadius: BorderRadius.circular(
                                    MCSpacing.radiusPill),
                                border: Border.all(
                                  color: _closesInDays == d
                                      ? MCColors.primaryMid
                                      : MCColors.border,
                                ),
                              ),
                              child: Text(
                                d == 1 ? '1 day' : '$d days',
                                style: MCTypography.labelSm.copyWith(
                                  color: _closesInDays == d
                                      ? Colors.white
                                      : MCColors.textSecondary,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _isValid ? _submit : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isValid ? MCColors.primary : MCColors.primaryPale,
                        borderRadius:
                            BorderRadius.circular(MCSpacing.radiusMd),
                      ),
                      child: Center(
                        child: Text(
                          'Create Poll',
                          style: MCTypography.h4.copyWith(
                            color: _isValid
                                ? Colors.white
                                : MCColors.primaryMid,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.background,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: MCTypography.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: MCTypography.body.copyWith(color: MCColors.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}
