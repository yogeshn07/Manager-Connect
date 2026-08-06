import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/features/feed/presentation/screens/create_poll_sheet.dart';
import 'package:manager_connect/features/feed/presentation/screens/share_achievement_sheet.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

const int _maxImages = 4;

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _images = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // close bottom sheet
    try {
      if (source == ImageSource.gallery && _images.length < _maxImages) {
        final picked = await _picker.pickMultiImage(imageQuality: 85);
        if (picked.isNotEmpty && mounted) {
          final remaining = _maxImages - _images.length;
          setState(() {
            for (final f in picked.take(remaining)) {
              _images.add(File(f.path));
            }
          });
        }
      } else {
        final picked = await _picker.pickImage(
            source: source, imageQuality: 85);
        if (picked != null && mounted) {
          setState(() => _images.add(File(picked.path)));
        }
      }
    } catch (_) {
      if (mounted) showErrorToast(context, 'Could not pick image');
    }
  }

  void _showImagePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPollSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreatePollSheet(
        onCreatePoll: (question, options, closesInDays) =>
            _submitPoll(question: question, options: options, closesInDays: closesInDays),
      ),
    );
  }

  Future<void> _submitPoll({
    required String question,
    required List<String> options,
    required int closesInDays,
  }) async {
    setState(() => _submitting = true);
    try {
      final auth = ref.read(authProvider);
      final userId =
          auth is AppAuthStateAuthenticated ? auth.session.userId : '';
      final client = ref.read(supabaseClientProvider);
      await FeedRepository(client).createPollPost(
        userId: userId,
        question: question,
        options: options,
        closesInDays: closesInDays,
      );
      await ref.read(feedProvider.notifier).refresh();
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

  void _showAchievementSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ShareAchievementSheet(
        onShared: () {
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _images.isEmpty) {
      showErrorToast(context, 'Add text or an image');
      return;
    }
    setState(() => _submitting = true);
    try {
      final auth = ref.read(authProvider);
      final userId =
          auth is AppAuthStateAuthenticated ? auth.session.userId : '';
      final client = ref.read(supabaseClientProvider);
      final repo = FeedRepository(client);

      // Upload images first
      final storagePaths = <String>[];
      for (final img in _images) {
        final bytes = await img.readAsBytes();
        final path = await repo.uploadPostImage(
          userId: userId,
          filePath: img.path,
          bytes: bytes,
        );
        storagePaths.add(path);
      }

      await repo.createPost(
        content: content,
        imageStoragePaths: storagePaths.isEmpty ? null : storagePaths,
      );
      await ref.read(feedProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Post created');
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to create post');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final userInitials = auth is AppAuthStateAuthenticated
        ? _initials(auth.session.fullName ?? '')
        : 'U';
    final hasContent =
        _controller.text.trim().isNotEmpty || _images.isNotEmpty;

    return Scaffold(
      backgroundColor: MCColors.card,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: MCColors.borderLight)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    color: MCColors.textPrimary,
                  ),
                  Text('New Post', style: MCTypography.h3),
                  const Spacer(),
                  GestureDetector(
                    onTap: (_submitting || !hasContent) ? null : _submit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 9),
                      decoration: BoxDecoration(
                        color: hasContent
                            ? MCColors.primaryMid
                            : MCColors.primaryPale,
                        borderRadius:
                            BorderRadius.circular(MCSpacing.radiusPill),
                      ),
                      child: _submitting
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: hasContent
                                    ? Colors.white
                                    : MCColors.primaryMid,
                              ),
                            )
                          : Text(
                              'Post',
                              style: MCTypography.labelSm.copyWith(
                                color: hasContent
                                    ? Colors.white
                                    : MCColors.primaryMid,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // ── Composer area ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MCSpacing.pageH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MCAvatar(
                          initials: userInitials,
                          size: MCAvatar.md,
                          backgroundColor: MCColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "What's on your mind?",
                              hintStyle: MCTypography.bodyLg.copyWith(
                                color: MCColors.textMuted,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.only(top: 4),
                            ),
                            style: MCTypography.bodyLg,
                            maxLines: null,
                            maxLength: AppConstants.maxPostContentLength,
                            textCapitalization:
                                TextCapitalization.sentences,
                            enabled: !_submitting,
                            autofocus: true,
                          ),
                        ),
                      ],
                    ),
                    // ── Image preview grid ────────────────────────────
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ImagePreviewGrid(
                        images: _images,
                        onRemove: (i) =>
                            setState(() => _images.removeAt(i)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Toolbar ───────────────────────────────────────────────
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: MCColors.borderLight)),
              ),
              child: Row(
                children: [
                  _ToolbarIcon(
                    icon: Icons.image_outlined,
                    onTap: _images.length < _maxImages
                        ? _showImagePicker
                        : null,
                    badge: _images.isNotEmpty
                        ? '${_images.length}/$_maxImages'
                        : null,
                  ),
                  const SizedBox(width: 4),
                  _ToolbarIcon(icon: Icons.poll_outlined, onTap: _showPollSheet),
                  const SizedBox(width: 4),
                  _ToolbarIcon(
                      icon: Icons.emoji_events_outlined,
                      onTap: _showAchievementSheet),
                  const Spacer(),
                  if (_controller.text.isNotEmpty)
                    Text(
                      '${_controller.text.length}/${AppConstants.maxPostContentLength}',
                      style: MCTypography.caption,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image preview grid ─────────────────────────────────────────────────────

class _ImagePreviewGrid extends StatelessWidget {
  const _ImagePreviewGrid({required this.images, required this.onRemove});
  final List<File> images;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return _tile(images[0], 0, height: 200);
    }
    if (images.length == 2) {
      return Row(
        children: [
          Expanded(child: _tile(images[0], 0, height: 160)),
          const SizedBox(width: 4),
          Expanded(child: _tile(images[1], 1, height: 160)),
        ],
      );
    }
    if (images.length == 3) {
      return Row(
        children: [
          Expanded(child: _tile(images[0], 0, height: 160)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                _tile(images[1], 1, height: 78),
                const SizedBox(height: 4),
                _tile(images[2], 2, height: 78),
              ],
            ),
          ),
        ],
      );
    }
    // 4 images
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _tile(images[0], 0, height: 110)),
            const SizedBox(width: 4),
            Expanded(child: _tile(images[1], 1, height: 110)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _tile(images[2], 2, height: 110)),
            const SizedBox(width: 4),
            Expanded(child: _tile(images[3], 3, height: 110)),
          ],
        ),
      ],
    );
  }

  Widget _tile(File file, int index, {required double height}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Toolbar icon ───────────────────────────────────────────────────────────

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({required this.icon, this.onTap, this.badge});
  final IconData icon;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: MCColors.background,
              borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              size: 18,
              color: onTap != null
                  ? MCColors.textSecondary
                  : MCColors.textMuted,
            ),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: MCColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
