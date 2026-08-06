import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

abstract final class MCTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: MCColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MCColors.primary,
        brightness: Brightness.light,
        primary: MCColors.primary,
        surface: MCColors.background,
        onSurface: MCColors.textPrimary,
      ),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      cardTheme: CardThemeData(
        elevation: 0,
        color: MCColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          side: const BorderSide(color: MCColors.border, width: MCSpacing.borderThin),
        ),
        margin: const EdgeInsets.only(bottom: MCSpacing.cardGap),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MCColors.card,
        surfaceTintColor: Colors.transparent,
        foregroundColor: MCColors.textPrimary,
        titleTextStyle: MCTypography.h3.copyWith(color: MCColors.textPrimary),
        iconTheme: const IconThemeData(color: MCColors.textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return const Color(0xFFCBD5E1);
            return MCColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return const Color(0xFF94A3B8);
            return Colors.white;
          }),
          textStyle: WidgetStatePropertyAll(MCTypography.labelLg.copyWith(color: Colors.white)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(MCSpacing.radiusButton)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MCColors.textPrimary,
          elevation: 0,
          side: const BorderSide(color: MCColors.border, width: MCSpacing.borderMed),
          textStyle: MCTypography.labelLg,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MCSpacing.radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MCColors.primaryMid,
          textStyle: MCTypography.label,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MCColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          borderSide: const BorderSide(color: MCColors.border, width: MCSpacing.borderMed),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          borderSide: const BorderSide(color: MCColors.border, width: MCSpacing.borderMed),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          borderSide: const BorderSide(color: MCColors.primary, width: MCSpacing.borderMed),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          borderSide: const BorderSide(color: MCColors.error, width: MCSpacing.borderMed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          borderSide: const BorderSide(color: MCColors.error, width: MCSpacing.borderMed),
        ),
        hintStyle: MCTypography.body.copyWith(color: MCColors.textMuted),
        labelStyle: MCTypography.label.copyWith(color: MCColors.textSecondary),
        prefixIconColor: MCColors.textMuted,
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        backgroundColor: MCColors.card,
        selectedColor: MCColors.primary,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
          side: const BorderSide(color: MCColors.border, width: MCSpacing.borderThin),
        ),
        labelStyle: MCTypography.labelSm,
        padding: const EdgeInsets.symmetric(horizontal: MCSpacing.sm, vertical: MCSpacing.xs2),
      ),
      dividerTheme: const DividerThemeData(
        color: MCColors.borderLight,
        thickness: MCSpacing.borderThin,
        space: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MCColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(MCSpacing.radiusXl)),
        ),
        showDragHandle: true,
        dragHandleColor: MCColors.border,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: MCColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusLg),
        ),
        titleTextStyle: MCTypography.h3,
        contentTextStyle: MCTypography.body,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: MCColors.textPrimary,
        contentTextStyle: MCTypography.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
        ),
      ),
      canvasColor: MCColors.card,
    );
  }
}
