import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/features/feed/presentation/providers/statuses_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _captionCtrl = TextEditingController();
  final _canvasKey = GlobalKey();

  // ── Image ──────────────────────────────────────────────────────────────────
  Uint8List? _imageBytes;

  // Image interactive transform (drag + pinch-scale + two-finger rotate)
  Offset _imgPos = Offset.zero;
  double _imgScale = 1.0;
  double _imgAngle = 0.0;

  // Gesture anchor values captured at ScaleStart
  Offset _imgFocalStart = Offset.zero;
  Offset _imgPosStart = Offset.zero;
  double _imgScaleStart = 1.0;
  double _imgAngleStart = 0.0;

  // ── Text ───────────────────────────────────────────────────────────────────
  // Text transform
  Offset _textPos = const Offset(0, 90); // slight below center
  double _textScale = 1.0;
  double _textAngle = 0.0;

  Offset _textFocalStart = Offset.zero;
  Offset _textPosStart = Offset.zero;
  double _textScaleStart = 1.0;
  double _textAngleStart = 0.0;

  // ── Single-canvas gesture routing ─────────────────────────────────────────
  // Determined at ScaleStart: 'image' or 'text', based on focal proximity
  String? _activeElement;
  // Screen centre cached in build() so gesture handlers can compute proximity
  Offset _screenCenter = Offset.zero;

  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _captionCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  // ── Canvas gesture handlers (single detector routes to image or text) ───────

  void _onCanvasScaleStart(ScaleStartDetails d) {
    final focal = d.focalPoint;
    final hasImage = _imageBytes != null;
    final hasText = _captionCtrl.text.trim().isNotEmpty;

    if (hasImage && hasText) {
      final distImg = (focal - (_screenCenter + _imgPos)).distance;
      final distText = (focal - (_screenCenter + _textPos)).distance;
      _activeElement = distImg <= distText ? 'image' : 'text';
    } else if (hasImage) {
      _activeElement = 'image';
    } else if (hasText) {
      _activeElement = 'text';
    } else {
      _activeElement = null;
      return;
    }

    if (_activeElement == 'image') {
      _imgFocalStart = focal;
      _imgPosStart = _imgPos;
      _imgScaleStart = _imgScale;
      _imgAngleStart = _imgAngle;
    } else {
      _textFocalStart = focal;
      _textPosStart = _textPos;
      _textScaleStart = _textScale;
      _textAngleStart = _textAngle;
    }
  }

  void _onCanvasScaleUpdate(ScaleUpdateDetails d) {
    if (_activeElement == null) return;
    setState(() {
      if (_activeElement == 'image') {
        _imgScale = (_imgScaleStart * d.scale).clamp(0.1, 10.0);
        _imgAngle = _imgAngleStart + d.rotation;
        _imgPos = _imgPosStart + (d.focalPoint - _imgFocalStart);
      } else {
        _textScale = (_textScaleStart * d.scale).clamp(0.3, 6.0);
        _textAngle = _textAngleStart + d.rotation;
        _textPos = _textPosStart + (d.focalPoint - _textFocalStart);
      }
    });
  }

  // ── Pick image ─────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        // Reset transform when a new image is picked
        _imgPos = Offset.zero;
        _imgScale = 1.0;
        _imgAngle = 0.0;
      });
    }
  }

  // ── Share ──────────────────────────────────────────────────────────────────

  Future<void> _share() async {
    FocusScope.of(context).unfocus();
    // Capture context-dependent values before any async gap
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Give keyboard time to dismiss so it isn't captured
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    final hasImage = _imageBytes != null;
    final hasText = _captionCtrl.text.trim().isNotEmpty;

    if (!hasImage && !hasText) {
      showErrorToast(context, 'Add an image or some text');
      return;
    }

    setState(() => _posting = true);
    try {
      final auth = ref.read(authProvider);
      if (auth is! AppAuthStateAuthenticated) return;
      final userId = auth.session.userId;
      final client = ref.read(supabaseClientProvider);
      final repo = FeedRepository(client);

      // Capture the canvas (image + text as a single composite PNG)
      final boundary =
          _canvasKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final captured = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await captured.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final compositeBytes = byteData!.buffer.asUint8List();

      final storagePath = await repo.uploadStatusImage(
        userId: userId,
        filePath: 'story.png',
        bytes: compositeBytes,
      );

      await ref
          .read(statusesProvider.notifier)
          .addStatus(
            imageStoragePath: storagePath,
            // Text is baked into the composite PNG; no separate caption stored
            caption: null,
            userId: userId,
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to share story');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Cache screen centre so gesture handlers can compute element proximity
    _screenCenter = Offset(mq.size.width / 2, mq.size.height / 2);
    final hasImage = _imageBytes != null;
    final hasText = _captionCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Canvas (captured by RepaintBoundary) ────────────────────
          // No GestureDetectors inside — the single detector below handles all
          // canvas touches so two-finger scale/rotate is never split across
          // separate recognisers.
          RepaintBoundary(
            key: _canvasKey,
            child: Container(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Empty-state hint
                  if (!hasImage && !hasText)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 72,
                            color: Colors.white38,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Add a photo or write something below',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  // ── Image element (static — gesture handled by canvas GD)
                  if (hasImage)
                    Positioned.fill(
                      child: Center(
                        child: Transform.translate(
                          offset: _imgPos,
                          child: Transform.rotate(
                            angle: _imgAngle,
                            child: Transform.scale(
                              scale: _imgScale,
                              child: Image.memory(
                                _imageBytes!,
                                width: mq.size.width,
                                height: mq.size.height,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Text element (static — gesture handled by canvas GD)
                  if (hasText)
                    Positioned.fill(
                      child: Center(
                        child: Transform.translate(
                          offset: _textPos,
                          child: Transform.rotate(
                            angle: _textAngle,
                            child: Transform.scale(
                              scale: _textScale,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: const BoxConstraints(
                                  maxWidth: 280,
                                ),
                                child: Text(
                                  _captionCtrl.text.trim(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 6,
                                        color: Colors.black87,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── 2. Single canvas gesture detector ─────────────────────────
          // Sits above the canvas but below the control bars so it sees
          // both touch points for any pinch gesture, routes to the element
          // whose centre is closest to the focal point.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _onCanvasScaleStart,
              onScaleUpdate: _onCanvasScaleUpdate,
            ),
          ),

          // ── 3. Top controls (not captured, drawn on top) ───────────────
          Positioned(
            top: mq.padding.top,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _circleIconBtn(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (hasImage)
                    _pillBtn(
                      label: 'Remove photo',
                      onTap: () => setState(() {
                        _imageBytes = null;
                      }),
                    ),
                ],
              ),
            ),
          ),

          // ── 4. Bottom controls (not captured, drawn on top) ────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: mq.padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasText)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 14,
                            color: Colors.white54,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Drag · Pinch to scale · Two fingers to rotate',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Text field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _captionCtrl,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Add text to your story…',
                        hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _CircleBtn(
                        icon: Icons.camera_alt_outlined,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 10),
                      _CircleBtn(
                        icon: Icons.photo_library_outlined,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _posting ? null : _share,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: MCColors.primary,
                            borderRadius: BorderRadius.circular(
                              MCSpacing.radiusPill,
                            ),
                          ),
                          child: _posting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Share Story',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _pillBtn({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white24,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
