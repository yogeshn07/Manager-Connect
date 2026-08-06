import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/recognition/data/repositories/recognition_repository.dart';
import 'package:manager_connect/features/recognition/presentation/providers/recognition_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_inputs.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
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
    'fitness_champion':      'Fitness Champion',
    'wellness_champion':     'Wellness Champion',
    'event_champion':        'Event Champion',
    'most_supportive_manager': 'Most Supportive Manager',
  };

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
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
      final repo   = RecognitionRepository(client);
      final members = await repo.getActiveMembers();
      if (mounted) {
        setState(() { _members = members; _loadingMembers = false; });
      }
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
      showErrorToast(context, 'Write a recognition message');
      return;
    }
    setState(() => _submitting = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo   = RecognitionRepository(client);
      await repo.createRecognition(
        recipientIds: _selectedRecipients.toList(),
        categoryTag:  _categoryTag!,
        message:      _messageController.text.trim(),
      );
      await ref.read(recognitionFeedProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Recognition sent! 🎉');
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to send recognition');
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
                  Text('Give Recognition', style: MCTypography.h3),
                  const Spacer(),
                  MCAmberButton(
                    label: 'Send',
                    loading: _submitting,
                    icon: Icons.send,
                    onPressed: _submit,
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
                    // ── Hero banner ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [MCColors.amberLight, MCColors.amberPale],
                        ),
                        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
                        border: Border.all(
                          color: MCColors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: MCColors.amberLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: MCColors.amberDark.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: MCColors.amber,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Celebrate someone who\nmade a difference',
                                  style: MCTypography.h4.copyWith(
                                    color: MCColors.amberDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Recognitions are shared with the community',
                                  style: MCTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Category ──────────────────────────────────────
                    Text('Category *', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.entries.map((e) {
                        final sel = _categoryTag == e.key;
                        return GestureDetector(
                          onTap: _submitting
                              ? null
                              : () => setState(() => _categoryTag = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:   sel ? MCColors.amber.withValues(alpha: 0.15) : MCColors.card,
                              borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                              border: Border.all(
                                color: sel ? MCColors.amberDark : MCColors.border,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              e.value,
                              style: MCTypography.labelSm.copyWith(
                                color: sel ? MCColors.amberDark : MCColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Recipients ────────────────────────────────────
                    Text('Who are you recognizing? *', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    if (_loadingMembers)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _members.map((m) {
                          final id   = m['id'] as String;
                          final name = m['full_name'] as String;
                          final sel  = _selectedRecipients.contains(id);
                          return GestureDetector(
                            onTap: _submitting
                                ? null
                                : () => setState(() {
                                      if (sel) {
                                        _selectedRecipients.remove(id);
                                      } else {
                                        _selectedRecipients.add(id);
                                      }
                                    }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? MCColors.amber.withValues(alpha: 0.12)
                                    : MCColors.card,
                                borderRadius:
                                    BorderRadius.circular(MCSpacing.radiusPill),
                                border: Border.all(
                                  color: sel ? MCColors.amberDark : MCColors.border,
                                  width: sel ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MCAvatar(
                                    initials: name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    size: 24,
                                    backgroundColor: sel
                                        ? MCColors.amber
                                        : MCColors.textMuted,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    name,
                                    style: MCTypography.labelSm.copyWith(
                                      color: sel
                                          ? MCColors.amberDark
                                          : MCColors.textSecondary,
                                    ),
                                  ),
                                  if (sel) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: MCColors.amberDark,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Message ───────────────────────────────────────
                    Text('Recognition message *', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: MCColors.card,
                        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
                        border: Border.all(color: MCColors.border),
                      ),
                      child: MCInput(
                        controller: _messageController,
                        hint: 'Why are you recognizing them? What did they do?',
                        maxLines: 4,
                        maxLength: AppConstants.maxRecognitionMessageLength,
                        enabled: !_submitting,
                      ),
                    ),
                    const SizedBox(height: 24),

                    MCAmberButton(
                      label: 'Send Recognition',
                      loading: _submitting,
                      icon: Icons.emoji_events,
                      onPressed: _submit,
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
