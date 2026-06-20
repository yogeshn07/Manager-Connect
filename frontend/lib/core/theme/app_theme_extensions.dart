import 'package:flutter/material.dart';
import 'package:manager_connect/core/theme/app_colors.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
    required this.rsvpGoingColor,
    required this.rsvpMaybeColor,
    required this.rsvpNotGoingColor,
    required this.attendedColor,
    required this.absentColor,
    required this.connectBuddyBadgeColor,
    required this.connectBuddyPostBackground,
    required this.pinnedPostBackground,
    required this.healthScoreHigh,
    required this.healthScoreMedium,
    required this.healthScoreLow,
  });

  final Color successColor;
  final Color warningColor;
  final Color dangerColor;
  final Color rsvpGoingColor;
  final Color rsvpMaybeColor;
  final Color rsvpNotGoingColor;
  final Color attendedColor;
  final Color absentColor;
  final Color connectBuddyBadgeColor;
  final Color connectBuddyPostBackground;
  final Color pinnedPostBackground;
  final Color healthScoreHigh;
  final Color healthScoreMedium;
  final Color healthScoreLow;

  static const AppThemeExtension light = AppThemeExtension(
    successColor: AppColors.successGreen,
    warningColor: AppColors.warningAmber,
    dangerColor: AppColors.dangerRed,
    rsvpGoingColor: AppColors.successGreen,
    rsvpMaybeColor: AppColors.warningAmber,
    rsvpNotGoingColor: AppColors.dangerRed,
    attendedColor: AppColors.successGreen,
    absentColor: AppColors.dangerRed,
    connectBuddyBadgeColor: AppColors.connectBuddyBadge,
    connectBuddyPostBackground: AppColors.connectBuddyPostBg,
    pinnedPostBackground: AppColors.pinnedPostBg,
    healthScoreHigh: AppColors.successGreen,
    healthScoreMedium: AppColors.warningAmber,
    healthScoreLow: AppColors.dangerRed,
  );

  @override
  AppThemeExtension copyWith({
    Color? successColor,
    Color? warningColor,
    Color? dangerColor,
    Color? rsvpGoingColor,
    Color? rsvpMaybeColor,
    Color? rsvpNotGoingColor,
    Color? attendedColor,
    Color? absentColor,
    Color? connectBuddyBadgeColor,
    Color? connectBuddyPostBackground,
    Color? pinnedPostBackground,
    Color? healthScoreHigh,
    Color? healthScoreMedium,
    Color? healthScoreLow,
  }) {
    return AppThemeExtension(
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      dangerColor: dangerColor ?? this.dangerColor,
      rsvpGoingColor: rsvpGoingColor ?? this.rsvpGoingColor,
      rsvpMaybeColor: rsvpMaybeColor ?? this.rsvpMaybeColor,
      rsvpNotGoingColor: rsvpNotGoingColor ?? this.rsvpNotGoingColor,
      attendedColor: attendedColor ?? this.attendedColor,
      absentColor: absentColor ?? this.absentColor,
      connectBuddyBadgeColor:
          connectBuddyBadgeColor ?? this.connectBuddyBadgeColor,
      connectBuddyPostBackground:
          connectBuddyPostBackground ?? this.connectBuddyPostBackground,
      pinnedPostBackground:
          pinnedPostBackground ?? this.pinnedPostBackground,
      healthScoreHigh: healthScoreHigh ?? this.healthScoreHigh,
      healthScoreMedium: healthScoreMedium ?? this.healthScoreMedium,
      healthScoreLow: healthScoreLow ?? this.healthScoreLow,
    );
  }

  @override
  AppThemeExtension lerp(covariant AppThemeExtension? other, double t) {
    if (other == null) return this;
    return AppThemeExtension(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      dangerColor: Color.lerp(dangerColor, other.dangerColor, t)!,
      rsvpGoingColor: Color.lerp(rsvpGoingColor, other.rsvpGoingColor, t)!,
      rsvpMaybeColor: Color.lerp(rsvpMaybeColor, other.rsvpMaybeColor, t)!,
      rsvpNotGoingColor:
          Color.lerp(rsvpNotGoingColor, other.rsvpNotGoingColor, t)!,
      attendedColor: Color.lerp(attendedColor, other.attendedColor, t)!,
      absentColor: Color.lerp(absentColor, other.absentColor, t)!,
      connectBuddyBadgeColor:
          Color.lerp(connectBuddyBadgeColor, other.connectBuddyBadgeColor, t)!,
      connectBuddyPostBackground: Color.lerp(
        connectBuddyPostBackground,
        other.connectBuddyPostBackground,
        t,
      )!,
      pinnedPostBackground:
          Color.lerp(pinnedPostBackground, other.pinnedPostBackground, t)!,
      healthScoreHigh:
          Color.lerp(healthScoreHigh, other.healthScoreHigh, t)!,
      healthScoreMedium:
          Color.lerp(healthScoreMedium, other.healthScoreMedium, t)!,
      healthScoreLow: Color.lerp(healthScoreLow, other.healthScoreLow, t)!,
    );
  }
}
