import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/constants/interest_tags.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/data/repositories/auth_repository.dart';
import 'package:manager_connect/features/auth/data/repositories/profile_repository.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_badges.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_inputs.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController  = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController   = TextEditingController();
  final _selectedTags    = <String>{};
  bool _submitting = false;
  int _step = 0;
  File? _imageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authProvider.notifier);
    final inviteToken  = authNotifier.consumeInviteToken();

    setState(() => _submitting = true);
    try {
      final client = ref.read(supabaseClientProvider);

      // Upload photo first if one was selected (non-fatal if it fails)
      String? avatarUrl;
      if (_imageFile != null) {
        try {
          final userId = client.auth.currentUser!.id;
          final path = '$userId/avatar.jpg';
          await client.storage.from('avatars').upload(
            path,
            _imageFile!,
            fileOptions: const FileOptions(upsert: true),
          );
          avatarUrl = client.storage.from('avatars').getPublicUrl(path);
        } catch (_) {}
      }

      if (inviteToken != null) {
        // Invitation-based flow (user signed up via an invite link)
        final repo = ProfileRepository(client);
        await repo.createProfile(
          token:        inviteToken,
          fullName:     _nameController.text.trim(),
          title:        _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
          bio:          _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
          interestTags: _selectedTags.toList(),
        );
        // Patch avatar_url after profile is created
        if (avatarUrl != null) {
          final uid = client.auth.currentUser?.id;
          if (uid != null) {
            await client.from('profiles').update({'avatar_url': avatarUrl}).eq('id', uid);
          }
        }
      } else {
        // Open registration: insert profile directly
        final userId = client.auth.currentUser!.id;
        await client.from('profiles').insert({
          'id':                   userId,
          'full_name':            _nameController.text.trim(),
          if (_titleController.text.trim().isNotEmpty)
            'title':              _titleController.text.trim(),
          if (_bioController.text.trim().isNotEmpty)
            'bio':                _bioController.text.trim(),
          'interest_tags':        _selectedTags.toList(),
          'app_role':             'member',
          'is_active':            true,
          'is_system_account':    false,
          'onboarding_completed': true,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        });
      }

      await authNotifier.handleProfileCreated();
    } on AppException catch (e) {
      if (mounted) {
        showErrorToast(context, e.message);
        if (inviteToken != null) authNotifier.setInviteToken(inviteToken);
      }
    } catch (_) {
      if (mounted) {
        showErrorToast(context, 'Failed to create profile. Please try again.');
        if (inviteToken != null) authNotifier.setInviteToken(inviteToken);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _logout() async {
    final client = ref.read(supabaseClientProvider);
    final repo = AuthRepository(client);
    await repo.signOut();
    ref.read(authProvider.notifier).setUnauthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  color: MCColors.card,
                  border: Border(bottom: BorderSide(color: MCColors.borderLight)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Set Up Your Profile', style: MCTypography.h3),
                          Text(
                            'Step ${_step + 1} of 2',
                            style: MCTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _submitting ? null : _logout,
                      child: Text('Cancel', style: MCTypography.label.copyWith(color: MCColors.textSecondary)),
                    ),
                  ],
                ),
              ),

              // ── Step indicator ────────────────────────────────────────
              LinearProgressIndicator(
                value: (_step + 1) / 2,
                backgroundColor: MCColors.borderLight,
                valueColor: const AlwaysStoppedAnimation(MCColors.primary),
                minHeight: 3,
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(MCSpacing.pageH),
                  child: _step == 0 ? _buildStep0() : _buildStep1(),
                ),
              ),

              // ── Bottom CTA ────────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                  MCSpacing.pageH,
                  MCSpacing.sm,
                  MCSpacing.pageH,
                  MCSpacing.sm + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: MCColors.card,
                  border: Border(top: BorderSide(color: MCColors.borderLight)),
                ),
                child: _step == 0
                    ? MCPrimaryButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
                        onPressed: _validateStep0,
                      )
                    : MCPrimaryButton(
                        label: 'Create Profile',
                        loading: _submitting,
                        onPressed: _submit,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _validateStep0() {
    if (_nameController.text.trim().isEmpty) {
      showErrorToast(context, 'Please enter your full name');
      return;
    }
    setState(() => _step = 1);
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MCSpacing.lg),

        // Photo picker
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _imageFile != null
                    ? ClipOval(
                        child: Image.file(
                          _imageFile!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: MCColors.primaryPale,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Icon(Icons.person_outline, size: 56, color: MCColors.primary),
                      ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MCColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MCSpacing.xl),

        Text('Who are you?', style: MCTypography.h1),
        const SizedBox(height: 6),
        Text(
          'Tell the community about yourself',
          style: MCTypography.body.copyWith(color: MCColors.textSecondary),
        ),
        const SizedBox(height: MCSpacing.xl),

        MCInput(
          controller: _nameController,
          label: 'Full Name *',
          hint: 'e.g. Alex Johnson',
          prefixIcon: Icons.person_outline,
          enabled: !_submitting,
        ),
        const SizedBox(height: 12),
        MCInput(
          controller: _titleController,
          label: 'Job Title',
          hint: 'e.g. Engineering Manager',
          prefixIcon: Icons.work_outline,
          enabled: !_submitting,
        ),
        const SizedBox(height: 12),
        MCInput(
          controller: _bioController,
          label: 'Bio',
          hint: 'Tell us about your leadership journey',
          prefixIcon: Icons.info_outline,
          maxLines: 3,
          maxLength: AppConstants.maxBioLength,
          enabled: !_submitting,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MCSpacing.lg),

        Text('Your interests', style: MCTypography.h1),
        const SizedBox(height: 6),
        Text(
          'Select topics to connect with like-minded managers',
          style: MCTypography.body.copyWith(color: MCColors.textSecondary),
        ),
        const SizedBox(height: MCSpacing.xl),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: InterestTags.all.map((tag) {
            final selected = _selectedTags.contains(tag);
            return MCFilterChip(
              label: tag,
              active: selected,
              onTap: _submitting
                  ? null
                  : () => setState(() {
                        if (selected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      }),
            );
          }).toList(),
        ),
      ],
    );
  }
}
