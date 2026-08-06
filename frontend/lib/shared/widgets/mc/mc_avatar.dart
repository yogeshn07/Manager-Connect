import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class MCAvatar extends StatelessWidget {
  const MCAvatar({
    required this.initials,
    this.size = MCAvatar.md,
    this.backgroundColor,
    this.borderColor,
    this.statusDot,
    this.avatarUrl,
    super.key,
  });

  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? statusDot;
  final String? avatarUrl;

  static const double xs  = 24;
  static const double sm  = 32;
  static const double md  = 44;
  static const double lg  = 56;
  static const double xl  = 64;

  @override
  Widget build(BuildContext context) {
    final bg       = backgroundColor ?? MCColors.primary;
    final border   = borderColor;
    final fontSize = size * 0.36;
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;

    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: border != null ? Border.all(color: border, width: 2) : null,
      ),
      child: Center(
        child: Text(
          initials.length > 2 ? initials.substring(0, 2) : initials,
          style: MCTypography.labelSm.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (hasPhoto)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => circle,
                errorWidget: (_, __, ___) => circle,
              ),
            )
          else
            circle,
          if (statusDot != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.27,
                height: size * 0.27,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusDot,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stacked avatar row with -overlap (like engagement proof row).
class MCAvatarStack extends StatelessWidget {
  const MCAvatarStack({
    required this.initialsList,
    required this.colors,
    this.size = 24,
    this.overlap = 6,
    super.key,
  });

  final List<String> initialsList;
  final List<Color> colors;
  final double size;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final count = initialsList.length.clamp(0, 4);
    final stride = size - overlap;
    return SizedBox(
      width: size + (count - 1) * stride,
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          final bg = i < colors.length ? colors[i] : MCColors.textMuted;
          return Positioned(
            left: i * stride,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  initialsList[i],
                  style: MCTypography.overline.copyWith(
                    fontSize: size * 0.36,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Story ring avatar (used in the stories row on the feed).
class MCStoryAvatar extends StatelessWidget {
  const MCStoryAvatar({
    required this.initials,
    required this.label,
    this.backgroundColor,
    this.viewed = false,
    super.key,
  });

  final String initials;
  final String label;
  final Color? backgroundColor;
  final bool viewed;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    const ringW = 2.5;
    const gap   = 3.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + (ringW + gap) * 2,
          height: size + (ringW + gap) * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: viewed
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: MCColors.rsvpButtonGradient,
                  ),
            color: viewed ? MCColors.storyRingViewed : null,
          ),
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor ?? MCColors.primary,
                border: Border.all(color: Colors.white, width: gap),
              ),
              child: Center(
                child: Text(
                  initials.length > 2 ? initials.substring(0, 2) : initials,
                  style: MCTypography.label.copyWith(color: Colors.white, height: 1.0),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: MCTypography.caption, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
