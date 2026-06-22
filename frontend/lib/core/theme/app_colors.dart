import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary brand — deep teal (professional, trust-evoking)
  static const Color brandSeed = Color(0xFF0A6B5E);
  static const Color brandPrimary = Color(0xFF0A6B5E);
  static const Color brandDark = Color(0xFF064D43);
  static const Color brandLight = Color(0xFFE0F2F1);

  // Accent — warm amber for CTAs and highlights
  static const Color accent = Color(0xFFFF8F00);
  static const Color accentLight = Color(0xFFFFF8E1);

  // Semantic
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warningAmber = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color dangerRed = Color(0xFFC62828);
  static const Color dangerLight = Color(0xFFFFEBEE);

  // Connect Buddy
  static const Color connectBuddyBadge = Color(0xFF7C4DFF);
  static const Color connectBuddyPostBg = Color(0xFFF3E5F5);

  // Pinned
  static const Color pinnedPostBg = Color(0xFFFFF8E1);

  // Surface & card
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F7FA);
  static const Color divider = Color(0xFFE8ECF0);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A6B5E), Color(0xFF0D8B7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF064D43), Color(0xFF0A6B5E), Color(0xFF0D8B7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
