import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/constants/interest_tags.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/data/repositories/auth_repository.dart';
import 'package:manager_connect/features/auth/data/repositories/profile_repository.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _selectedTags = <String>{};
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authProvider.notifier);
    final inviteToken = authNotifier.consumeInviteToken();

    if (inviteToken == null) {
      showErrorToast(context, 'No invitation token. Please start over.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = ProfileRepository(client);
      await repo.createProfile(
        token: inviteToken,
        fullName: _nameController.text.trim(),
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        interestTags: _selectedTags.toList(),
      );

      await authNotifier.handleProfileCreated();
    } on AppException catch (e) {
      if (mounted) {
        showErrorToast(context, e.message);
        authNotifier.setInviteToken(inviteToken);
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Failed to create profile');
        authNotifier.setInviteToken(inviteToken);
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
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _logout,
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_submitting,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Job Title',
                    hintText: 'e.g. Manager, Engineering',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_submitting,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.info_outline),
                    counterText:
                        '${_bioController.text.length}/${AppConstants.maxBioLength}',
                  ),
                  maxLines: 3,
                  maxLength: AppConstants.maxBioLength,
                  enabled: !_submitting,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                Text(
                  'Interests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your interests to connect with like-minded managers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: InterestTags.all.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: _submitting
                          ? null
                          : (value) {
                              setState(() {
                                if (value) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
