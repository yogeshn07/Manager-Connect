import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/presentation/providers/statuses_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/toast.dart';
import 'package:path_provider/path_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    required this.statuses,
    required this.initialIndex,
    required this.currentUserId,
    super.key,
  });

  final List<StatusDto> statuses;
  final int initialIndex;
  final String currentUserId;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _index;
  late AnimationController _progressCtrl;
  bool _canNavigate = false; // guard against the screen-open gesture
  bool _deleting = false;
  bool _saving = false;
  bool _timerStarted = false; // ensures the 5-second timer fires only once per story

  // Image byte cache keyed by URL — avoids re-downloading on rebuilds
  final Map<String, Future<Uint8List>> _imgFutures = {};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _goForward();
      });

    // Block navigation for 400ms so the screen-push gesture doesn't skip the first story
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _canNavigate = true);
    });

    // Text-only stories start immediately; image stories wait for _onImageReady
    if (_currentStatus.imageUrl == null) _startTimer();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  StatusDto get _currentStatus => widget.statuses[_index];

  void _startTimer() {
    _timerStarted = true;
    _progressCtrl.forward(from: 0);
  }

  void _onImageReady() {
    if (!mounted || _timerStarted) return;
    _startTimer();
  }

  void _goForward() {
    if (!mounted) return;
    if (_index < widget.statuses.length - 1) {
      setState(() => _index++);
      _timerStarted = false;
      _progressCtrl.reset();
      if (_currentStatus.imageUrl == null) _startTimer();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goBack() {
    if (!mounted) return;
    if (_index > 0) {
      setState(() => _index--);
      _timerStarted = false;
      _progressCtrl.reset();
      if (_currentStatus.imageUrl == null) _startTimer();
    } else {
      _startTimer(); // restart current story from beginning
    }
  }

  void _onTapLeft() {
    if (!_canNavigate) return;
    _goBack();
  }

  void _onTapRight() {
    if (!_canNavigate) return;
    _goForward();
  }

  // ── Image loading ──────────────────────────────────────────────────────────

  Future<Uint8List> _getImageBytes(String imageUrl) =>
      _imgFutures[imageUrl] ??= _downloadImage(imageUrl);

  Future<Uint8List> _downloadImage(String imageUrl) async {
    const prefix = '/object/public/${Bucket.statuses}/';
    final idx = imageUrl.indexOf(prefix);
    if (idx == -1) throw Exception('Cannot parse storage URL');
    final storagePath = imageUrl.substring(idx + prefix.length);
    final client = ref.read(supabaseClientProvider);
    return client.storage.from(Bucket.statuses).download(storagePath);
  }

  Future<void> _deleteStory() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await ref
          .read(statusesProvider.notifier)
          .removeStatus(_currentStatus.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showErrorToast(context, 'Failed to delete story');
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _saveStory() async {
    final imageUrl = _currentStatus.imageUrl;
    if (imageUrl == null) {
      showErrorToast(context, 'No image to save');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Extract the storage path from the public URL
      const prefix = '/object/public/${Bucket.statuses}/';
      final idx = imageUrl.indexOf(prefix);
      if (idx == -1) throw Exception('Cannot parse storage path');
      final storagePath = imageUrl.substring(idx + prefix.length);

      final client = ref.read(supabaseClientProvider);
      final bytes = await client.storage.from(Bucket.statuses).download(storagePath);

      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/story_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(filePath).writeAsBytes(bytes);

      if (mounted) showSuccessToast(context, 'Story saved to your device');
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to save story');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: MCColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: _deleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete story',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: _deleting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _deleteStory();
                    },
            ),
            ListTile(
              leading: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined,
                      color: MCColors.textPrimary),
              title: const Text('Save story'),
              onTap: _saving
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _saveStory();
                    },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentStatus;
    final name = status.authorName ?? 'Unknown';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final isOwnStory = status.userId == widget.currentUserId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Story content ────────────────────────────────────────
          if (status.imageUrl != null)
            FutureBuilder<Uint8List>(
              future: _getImageBytes(status.imageUrl!),
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white38, strokeWidth: 2),
                  );
                }
                if (snap.hasError || snap.data == null) {
                  return const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white38, size: 48),
                  );
                }
                // Start the 5-second timer once — guard prevents repeated calls on rebuilds
                if (!_timerStarted) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _onImageReady());
                }
                return Image.memory(
                  snap.data!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  status.caption ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ── 2. Left / right tap areas ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _onTapLeft,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _onTapRight,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
            ],
          ),

          // ── 3. Progress bars + header (on top of tap areas) ─────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: List.generate(widget.statuses.length, (i) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: i < _index
                                ? Container(height: 3, color: Colors.white)
                                : i == _index
                                    ? AnimatedBuilder(
                                        animation: _progressCtrl,
                                        builder: (_, __) =>
                                            LinearProgressIndicator(
                                          value: _progressCtrl.value,
                                          backgroundColor:
                                              Colors.white.withValues(
                                                  alpha: 0.4),
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  Colors.white),
                                          minHeight: 3,
                                        ),
                                      )
                                    : Container(
                                        height: 3,
                                        color: Colors.white
                                            .withValues(alpha: 0.4),
                                      ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Author row + close + optional 3-dot
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: MCColors.primary,
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                      if (isOwnStory)
                        GestureDetector(
                          onTap: _showOptions,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.more_vert,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
