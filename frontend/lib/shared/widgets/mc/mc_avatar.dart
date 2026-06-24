import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Avatar — always circular. Size hierarchy from component-library.md.
/// Colors: role-mapped from 6 ramp options. Fallback: gray-400.
class McAvatar extends StatelessWidget {
  const McAvatar({
    required this.initials,
    this.size = 38,
    this.backgroundColor,
    this.statusDot,
    this.badgeIcon,
    this.badgeColor,
    super.key,
  });

  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? statusDot;
  final IconData? badgeIcon;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? McColors.brand800;
    final fontSize = size * 0.38;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
            ),
            child: Center(
              child: Text(
                initials.length > 2 ? initials.substring(0, 2) : initials,
                style: TextStyle(
                  fontFamily: McTypography.fontSans,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
          if (statusDot != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusDot,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          if (badgeIcon != null)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor ?? McColors.brand800,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Icon(badgeIcon, size: 9, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Stacked avatar strip — max 4 avatars, -4px overlap, 1.5px white border.
  static Widget stack({
    required List<String> initialsList,
    required List<Color> colors,
    double size = 20,
  }) {
    final count = initialsList.length.clamp(0, 4);
    return SizedBox(
      width: size + (count - 1) * (size - 4),
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (size - 4),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < colors.length ? colors[i] : McColors.gray400,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  initialsList[i],
                  style: TextStyle(
                    fontFamily: McTypography.fontSans,
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w500,
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
