import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Type Pill / Badge — categorize content type, status, tier.
/// Font: 9px / 500, uppercase, letter-spacing 0.05-0.07em.
/// Fill: category-50. Text: category-800.
class McTypePill extends StatelessWidget {
  const McTypePill({
    required this.text,
    required this.fillColor,
    required this.textColor,
    this.borderColor,
    super.key,
  });

  final String text;
  final Color fillColor;
  final Color textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Text(
        text.toUpperCase(),
        style: McTypography.pill.copyWith(color: textColor),
      ),
    );
  }
}
