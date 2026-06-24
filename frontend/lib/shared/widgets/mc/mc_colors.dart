import 'package:flutter/material.dart';

/// Design tokens from design-system.md — exact hex values.
/// No substitutions. No interpretation.
abstract final class McColors {
  // Brand Primary Ramp
  static const Color brand900 = Color(0xFF042C53);
  static const Color brand800 = Color(0xFF0C447C);
  static const Color brand700 = Color(0xFF185FA5);
  static const Color brand400 = Color(0xFF378ADD);
  static const Color brand200 = Color(0xFF85B7EB);
  static const Color brand100 = Color(0xFFB5D4F4);
  static const Color brand50 = Color(0xFFE6F1FB);
  static const Color brandWhisper = Color(0xFFF5F9FF);

  // Teal (Success / Wellness / Confirmed)
  static const Color teal50 = Color(0xFFE1F5EE);
  static const Color teal100 = Color(0xFF9FE1CB);
  static const Color teal400 = Color(0xFF1D9E75);
  static const Color teal600 = Color(0xFF0F6E56);
  static const Color teal800 = Color(0xFF085041);
  static const Color tealBorder = Color(0xFF5DCAA5);

  // Amber (Recognition / Gold / Achievements)
  static const Color amber50 = Color(0xFFFAEEDA);
  static const Color amber100 = Color(0xFFFAC775);
  static const Color amber400 = Color(0xFFBA7517);
  static const Color amber600 = Color(0xFF854F0B);
  static const Color amber800 = Color(0xFF633806);
  static const Color amberBorder = Color(0xFFEF9F27);

  // Coral (Sports / Events / Urgency)
  static const Color coral50 = Color(0xFFFAECE7);
  static const Color coral400 = Color(0xFFD85A30);
  static const Color coral600 = Color(0xFF993C1D);
  static const Color coral800 = Color(0xFF712B13);

  // Purple (Mindset / Mentions / Wellness Hub)
  static const Color purple50 = Color(0xFFEEEDFE);
  static const Color purple200 = Color(0xFFAFA9EC);
  static const Color purple400 = Color(0xFF7F77DD);
  static const Color purple600 = Color(0xFF534AB7);
  static const Color purple800 = Color(0xFF3C3489);
  static const Color purple900 = Color(0xFF26215C);

  // Red (Urgent / Unread / Error)
  static const Color red50 = Color(0xFFFCEBEB);
  static const Color red100 = Color(0xFFF7C1C1);
  static const Color red200 = Color(0xFFF09595);
  static const Color red400 = Color(0xFFE24B4A);
  static const Color red600 = Color(0xFFA32D2D);
  static const Color red800 = Color(0xFF791F1F);

  // Gray (Neutral / Structural)
  static const Color gray50 = Color(0xFFF1EFE8);
  static const Color gray100 = Color(0xFFD3D1C7);
  static const Color gray200 = Color(0xFFB4B2A9);
  static const Color gray400 = Color(0xFF888780);
  static const Color gray600 = Color(0xFF5F5E5A);
  static const Color gray800 = Color(0xFF444441);
  static const Color gray900 = Color(0xFF2C2C2A);

  // Green (Achievement / Unlocked)
  static const Color green50 = Color(0xFFEAF3DE);
  static const Color green400 = Color(0xFF639922);
  static const Color green600 = Color(0xFF3B6D11);

  // Backgrounds
  static const Color bgApp = Color(0xFFF4F5F7);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF4F5F7);
  static const Color bgHeroPrimary = Color(0xFF0C447C);
  static const Color bgHeroWellness = Color(0xFF085041);
  static const Color bgHeroChallenge = Color(0xFF1D9E75);
  static const Color bgHeroAdminMod = Color(0xFFA32D2D);

  // Borders — 0.5px solid at 10% black opacity
  static Color get borderDefault => Colors.black.withValues(alpha: 0.10);
  static Color get borderHover => Colors.black.withValues(alpha: 0.20);
  static const Color borderUnread = Color(0xFFB5D4F4);
  static const Color borderCelebrate = Color(0xFFEF9F27);
  static const Color borderStripe = Color(0xFF0C447C);

  // Text
  static const Color textPrimary = Color(0xFF2C2C2A);
  static const Color textSecondary = Color(0xFF5F5E5A);
  static const Color textTertiary = Color(0xFF888780);
  static const Color textLink = Color(0xFF185FA5);

  // Celebration card bg
  static const Color bgCelebration = Color(0xFFFFFBF4);
}
