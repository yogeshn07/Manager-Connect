import 'package:flutter/material.dart';

abstract final class MCColors {
  // ── Brand Blue ramp ──────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF1A3A6B);
  static const Color primaryMid  = Color(0xFF2451A3);
  static const Color primaryLight= Color(0xFF3B6FD4);
  static const Color primaryPale = Color(0xFFEEF2FA);

  // ── Amber ─────────────────────────────────────────────────────────────────
  static const Color amber      = Color(0xFFFFB840);
  static const Color amberDark  = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color amberPale  = Color(0xFFFFFBEB);

  // ── Energy Red (signal / LIVE / notification indicator) ─────────────────
  static const Color energyRed       = Color(0xFFCC1C22); // deeper than error — identity signal
  static const Color energyRedSubtle = Color(0x1ACC1C22); // 10% tint for pulse backgrounds

  // ── Lime (Active nav indicator) ───────────────────────────────────────────
  static const Color navLime      = Color(0xFFC5FF55);
  static const Color navLimeStrong = Color(0xFFB0E64D);

  // ── Violet (Polls / AI Assist) ────────────────────────────────────────────
  static const Color violet      = Color(0xFF7C3AED);
  static const Color violetLight = Color(0xFFEDE9FE);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success    = Color(0xFF10B981);
  static const Color successBg  = Color(0xFFD1FAE5);
  static const Color error      = Color(0xFFEF4444);
  static const Color errorBg    = Color(0xFFFEF2F2);
  static const Color warning    = Color(0xFFD97706);
  static const Color warningBg  = Color(0xFFFEF3C7);
  static const Color info       = Color(0xFF3B82F6);
  static const Color infoBg     = Color(0xFFDBEAFE);

  // ── Surface ───────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF4F5F7);
  static const Color card       = Color(0xFFFFFFFF);
  static const Color inputBg    = Color(0xFFF8FAFC);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted     = Color(0xFF9CA3AF);

  // ── Border ────────────────────────────────────────────────────────────────
  static const Color border      = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const List<Color> splashGradient = [Color(0xFF1A3A6B), Color(0xFF0F2D5E)];

  static const List<Color> primaryButtonGradient = [
    Color(0xFF1E4585),
    Color(0xFF1A3A6B),
    Color(0xFF0F2D5E),
  ];

  static const List<Color> amberButtonGradient = [
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
  ];

  static const List<Color> rsvpButtonGradient = [
    Color(0xFF3B6FD4),
    Color(0xFF60A5FA),
  ];

  // ── Story ring ────────────────────────────────────────────────────────────
  static const Color storyRingActive  = Color(0xFF3B6FD4);
  static const Color storyRingActive2 = Color(0xFF60A5FA);
  static const Color storyRingViewed  = Color(0xFFD1D5DB);

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
        const BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get primaryButtonShadow => [
        BoxShadow(
          color: const Color(0xFF0F2D5E).withValues(alpha: 0.30),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get amberButtonShadow => [
        BoxShadow(
          color: const Color(0xFFFFB840).withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
