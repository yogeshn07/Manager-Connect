import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';

/// Icon Tile — categorized visual anchor. Always has colored border.
/// Sizes: sm(24), md(30), lg(36), xl(42), 2xl(54).
class McIconTile extends StatelessWidget {
  const McIconTile({
    required this.icon,
    required this.fillColor,
    required this.borderColor,
    required this.iconColor,
    this.size = McSpacing.iconTileLg,
    this.locked = false,
    super.key,
  });

  final IconData icon;
  final Color fillColor;
  final Color borderColor;
  final Color iconColor;
  final double size;
  final bool locked;

  double get _radius {
    if (size <= McSpacing.iconTileSm) return McSpacing.radiusIconTileSm;
    if (size <= McSpacing.iconTileMd) return McSpacing.radiusIconTileMd;
    return McSpacing.radiusIconTileLg;
  }

  double get _iconSize => size * 0.48;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: borderColor,
            width: locked ? 1.0 : 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: Icon(icon, size: _iconSize, color: iconColor),
        ),
      ),
    );
  }
}
