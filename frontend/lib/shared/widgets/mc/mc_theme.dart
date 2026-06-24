import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Theme built from design-system.md.
/// Zero shadows. Border-only depth. Weight 400/500 only.
abstract final class McTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: McTypography.fontSans,
      scaffoldBackgroundColor: McColors.bgApp,
      colorScheme: ColorScheme.fromSeed(
        seedColor: McColors.brand800,
        brightness: Brightness.light,
        surface: McColors.bgApp,
        onSurface: McColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: McColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(McSpacing.radiusCard),
          side: BorderSide(color: McColors.borderDefault, width: McSpacing.borderThin),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: McSpacing.pageMargin,
          vertical: McSpacing.cardGap / 2,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: McColors.bgCard,
        surfaceTintColor: Colors.transparent,
        foregroundColor: McColors.textPrimary,
        titleTextStyle: McTypography.h3.copyWith(color: McColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: McColors.bgCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 56,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: McColors.brand800,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: McTypography.h4.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(McSpacing.radiusPillButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: McColors.brand700,
          elevation: 0,
          side: BorderSide(color: McColors.borderDefault),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(McSpacing.radiusPillButton),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: McColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(McSpacing.radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(McSpacing.radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(McSpacing.radiusInput),
          borderSide: BorderSide(color: McColors.brand700, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        hintStyle: McTypography.body.copyWith(color: McColors.textTertiary),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        backgroundColor: McColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(McSpacing.radiusChip),
          side: BorderSide(color: McColors.borderDefault, width: McSpacing.borderThin),
        ),
        labelStyle: McTypography.bodySm.copyWith(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      dividerTheme: DividerThemeData(
        color: McColors.borderDefault,
        thickness: McSpacing.borderThin,
        space: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: McColors.bgCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(McSpacing.radiusSheet),
          ),
        ),
        showDragHandle: true,
        dragHandleSize: const Size(32, 4),
        dragHandleColor: McColors.gray200,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: McColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(McSpacing.radiusCardFeatured),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(McSpacing.radiusCardSmall),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return McColors.brand800;
            return McColors.bgCard;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return McColors.textSecondary;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: McColors.borderDefault, width: McSpacing.borderThin),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(McSpacing.radiusChip)),
          ),
          textStyle: WidgetStatePropertyAll(McTypography.bodySm.copyWith(fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
