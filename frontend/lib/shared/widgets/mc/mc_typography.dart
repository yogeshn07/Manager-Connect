import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';

/// Typography tokens from design-system.md.
/// Only weight 400 and 500. No bold. No 600. No 700.
abstract final class McTypography {
  static const String fontSans = 'Inter';

  // Display — 22px / 500
  static const TextStyle display = TextStyle(
    fontFamily: fontSans,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: McColors.textPrimary,
  );

  // H1 — 18-20px / 500
  static const TextStyle h1 = TextStyle(
    fontFamily: fontSans,
    fontSize: 19,
    fontWeight: FontWeight.w500,
    height: 1.28,
    color: McColors.textPrimary,
  );

  // H2 — 16-17px / 500
  static const TextStyle h2 = TextStyle(
    fontFamily: fontSans,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: McColors.textPrimary,
  );

  // H3 — 14-15px / 500
  static const TextStyle h3 = TextStyle(
    fontFamily: fontSans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.32,
    color: McColors.textPrimary,
  );

  // H4 — 13-14px / 500
  static const TextStyle h4 = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: McColors.textPrimary,
  );

  // Body Large — 13px / 400
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.62,
    color: McColors.textPrimary,
  );

  // Body — 12px / 400
  static const TextStyle body = TextStyle(
    fontFamily: fontSans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.58,
    color: McColors.textPrimary,
  );

  // Body Small — 11px / 400
  static const TextStyle bodySm = TextStyle(
    fontFamily: fontSans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.48,
    color: McColors.textSecondary,
  );

  // Caption — 10-11px / 400
  static const TextStyle caption = TextStyle(
    fontFamily: fontSans,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: McColors.textTertiary,
  );

  // Label — 9-10px / 500, uppercase
  static const TextStyle label = TextStyle(
    fontFamily: fontSans,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.7,
    color: McColors.textSecondary,
  );

  // Pill — 8-9px / 500, uppercase
  static const TextStyle pill = TextStyle(
    fontFamily: fontSans,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.5,
  );

  // KPI Number — 20-24px / 500
  static const TextStyle kpi = TextStyle(
    fontFamily: fontSans,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: McColors.textPrimary,
  );

  // Rank Hero — 36-42px / 500
  static const TextStyle rank = TextStyle(
    fontFamily: fontSans,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: McColors.textPrimary,
  );

  // Action Row — 10px / 500
  static const TextStyle actionRow = TextStyle(
    fontFamily: fontSans,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: McColors.textSecondary,
  );
}
