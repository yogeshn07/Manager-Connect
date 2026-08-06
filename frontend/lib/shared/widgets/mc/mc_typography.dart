import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';

abstract final class MCTypography {
  // ── Font families (runtime-cached getters, not const) ─────────────────────
  static String? _gs;
  static String get _gs_ => _gs ??= GoogleFonts.dmSans().fontFamily!;

  static String? _it;
  static String get _it_ => _it ??= GoogleFonts.inter().fontFamily!;

  // ── Display (splash / login wordmark) ────────────────────────────────────
  static TextStyle get displayLg => TextStyle(
        fontFamily: _gs_,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: Colors.white,
        height: 1.1,
      );

  static TextStyle get displayMd => TextStyle(
        fontFamily: _gs_,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: Colors.white,
        height: 1.15,
      );

  // ── Page headings ─────────────────────────────────────────────────────────
  static TextStyle get h1 => TextStyle(
        fontFamily: _gs_,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: MCColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: _gs_,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: MCColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: _gs_,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: MCColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get h4 => TextStyle(
        fontFamily: _gs_,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: MCColors.textPrimary,
        height: 1.4,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLg => TextStyle(
        fontFamily: _it_,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
        color: MCColors.textPrimary,
        height: 1.65,
      );

  static TextStyle get body => TextStyle(
        fontFamily: _it_,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
        color: MCColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get bodySm => TextStyle(
        fontFamily: _it_,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.01,
        color: MCColors.textSecondary,
        height: 1.5,
      );

  // ── UI labels / buttons ───────────────────────────────────────────────────
  static TextStyle get labelLg => TextStyle(
        fontFamily: _gs_,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.01,
        color: MCColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get label => TextStyle(
        fontFamily: _gs_,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01,
        color: MCColors.textPrimary,
        height: 1.45,
      );

  static TextStyle get labelSm => TextStyle(
        fontFamily: _gs_,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01,
        color: MCColors.textPrimary,
        height: 1.45,
      );

  // ── Caption / meta ────────────────────────────────────────────────────────
  static TextStyle get caption => TextStyle(
        fontFamily: _it_,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.02,
        color: MCColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get captionBold => TextStyle(
        fontFamily: _it_,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.02,
        color: MCColors.textSecondary,
        height: 1.5,
      );

  // ── Overline / tag ────────────────────────────────────────────────────────
  static TextStyle get overline => TextStyle(
        fontFamily: _gs_,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.07,
        color: MCColors.textMuted,
        height: 1.4,
      );

  static TextStyle get pill => TextStyle(
        fontFamily: _gs_,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
        color: MCColors.textPrimary,
        height: 1.3,
      );

  // ── Navigation ────────────────────────────────────────────────────────────
  static TextStyle get navActive => TextStyle(
        fontFamily: _gs_,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.01,
        color: MCColors.primaryMid,
        height: 1.3,
      );

  static TextStyle get navInactive => TextStyle(
        fontFamily: _gs_,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.01,
        color: MCColors.textMuted,
        height: 1.3,
      );

  // ── Version / hint on dark bg ─────────────────────────────────────────────
  static TextStyle get hint => TextStyle(
        fontFamily: _it_,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.04,
        color: Colors.white.withValues(alpha: 0.5),
        height: 1.5,
      );

  // ── White variants (dark surfaces) ───────────────────────────────────────
  static TextStyle get h1White    => h1.copyWith(color: Colors.white);
  static TextStyle get h2White    => h2.copyWith(color: Colors.white);
  static TextStyle get h3White    => h3.copyWith(color: Colors.white);
  static TextStyle get bodyWhite  => body.copyWith(color: Colors.white.withValues(alpha: 0.85));

  static TextStyle get taglineDark => TextStyle(
        fontFamily: _gs_,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.07,
        color: Colors.white.withValues(alpha: 0.55),
        height: 1.4,
      );

  // ── KPI / rank numbers ────────────────────────────────────────────────────
  static TextStyle get kpi => TextStyle(
        fontFamily: _gs_,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: MCColors.textPrimary,
      );
}
