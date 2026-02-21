import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF511D18);
  static const Color primaryVariant = Color(0xFF4F378B);
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryVariant = Color(0xFF4A4458);

  // Light theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightAppBar = Color(0xFF8B1A1A);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFFD6D6D6);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);

  // Dark theme
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF8B1A1A);
  static const Color darkOnBackground = Color(0xFFE6E1E5);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);

  // Accent
  static const Color lightAccent = Color(0xFF511D18);
  static const Color darkAccent = Color(0xFFE6B453);

  // General semantic colors
  static const Color accent = Color(0xFF511D18);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Primary button background
  static const Color primaryButtonBGColorLight = Color(0xFF294B4D);
  static const Color primaryButtonBGColorDark = Color(0xFF2C5F5F);

  // Calendar – Backgrounds for day cells
  static const Color calendarTodayBGLight = Color(0xFFE3F2FD);
  static const Color calendarTodayBGDark = Color(0xFF0D47A1);

  static const Color calendarCompletedBGLight = Color(0xFFE8F5E8);
  static const Color calendarCompletedBGDark = Color(0xFF1B5E20);

  static const Color calendarMissedBGLight = Color(0xFFFCE4EC);
  static const Color calendarMissedBGDark = Color(0xFFB71C1C);

  static const Color calendarUpcomingBGLight = Colors.white;
  static const Color calendarUpcomingBGDark = Color(0xFF424242);

  // Calendar – Border colors (full dark-mode support)
  static const Color calendarTodayBorderLight = Color(0xFF60B7FF); // Blue
  static const Color calendarTodayBorderDark = Color(0xFF60B7FF);

  static const Color calendarCompletedBorderLight = Color(0xFF888888); // Green
  static const Color calendarCompletedBorderDark = Color(0xFF585858);

  static const Color calendarMissedBorderLight = Color(0xFF888888);
  static const Color calendarMissedBorderDark = Color(0xFF585858);

  static const Color calendarUpcomingBorderLight = Color(0xFF888888);
  static const Color calendarUpcomingBorderDark = Color(0xFF585858);

  // Calendar – Icons
  static const Color calendarCompletedIcon = Color(0xFF24A129);
  static const Color calendarMissedIcon = Color(0xFFFF1F1F);

  // Calendar – Headers & cell borders
  static const Color calendarDayHeaderLight = Color(0xFF000000);
  static const Color calendarDayHeaderDark = Color(0xFFFFFFFF);

  static const Color calendarCellBorderLight = Color(0xFF313131);
  static const Color calendarCellBorderDark = Color(0xFFFFFFFF);

  static const Color calendarTrailingDateLight = Color(0xFF313131);
  static const Color calendarTrailingDateDark = Color(0xFFFFFFFF);

  // Calendar – Text colors
  static const Color calendarDayTextLight = Color(0xFF000000);
  static const Color calendarDayTextDark = Color(0xFFFFFFFF);

  static const Color calendarDayTextSecondaryLight = Color(0xFF212121);
  static const Color calendarDayTextSecondaryDark = Color(0xFFFFFFFF);

  static const Color calendarUpcomingDayTextLight = Color(0xFF383838);
  static const Color calendarUpcomingDayTextDark = Color(0xFFFFFFFF);

  static const Color calendarMonthTextLight = Color(0xFF000000);
  static const Color calendarMonthTextDark = Color(0xFFFFFFFF);

  // Missed days badge
  static const Color missedDaysBadgeBGLight = Color(0xFFEEEEEE);
  static const Color missedDaysBadgeBGDark = Color(0xFF616161);
  static const Color missedDaysBadgeTextLight = Color(0xFF616161);
  static const Color missedDaysBadgeTextDark = Color(0xFFE0E0E0);

  // Legend
  static const Color legendBorderLight = Color(0xFFE0E0E0);
  static const Color legendBorderDark = Color(0xFF757575);
  static const Color legendTextLight = Color(0xFF616161);
  static const Color legendTextDark = Color(0xFFE0E0E0);

  // Dialog
  static const Color dialogBGLight = Color(0xFFFFFFFF);
  static const Color dialogBGDark = Color(0xFF212121);
  static const Color dialogTitleLight = Color(0xFF000000);
  static const Color dialogTitleDark = Color(0xFFFFFFFF);
  static const Color dialogContentLight = Color(0xFF616161);
  static const Color dialogContentDark = Color(0xFFE0E0E0);
  static const Color dialogCancelLight = Color(0xFF757575);
  static const Color dialogCancelDark = Color(0xFF9E9E9E);

  static const Color dialogMarkUnreadBG = Color(0xFFE53935);
  static const Color dialogMarkReadBG = Color(0xFF43A047);
  static const Color dialogButtonText = Color(0xFFFFFFFF);
}

extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get accent => isDarkMode ? AppColors.darkAccent : AppColors.lightAccent;
  Color get primaryColor => AppColors.primary;

  Color get backgroundColor =>
      isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;

  Color get surfaceColor =>
      isDarkMode ? AppColors.darkAccent : AppColors.darkAccent;
  Color get textColor =>
      isDarkMode ? AppColors.darkOnBackground : AppColors.lightOnBackground;

  Color get errorColor => Theme.of(this).colorScheme.error;
  Color get appBarColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.lightAppBar;

  Color get primaryButtonBGColor =>
      isDarkMode
          ? AppColors.primaryButtonBGColorDark
          : AppColors.primaryButtonBGColorLight;

  // Calendar – Backgrounds
  Color get calendarTodayBG =>
      isDarkMode
          ? AppColors.calendarTodayBGDark
          : AppColors.calendarTodayBGLight;

  Color get calendarCompletedBG =>
      isDarkMode
          ? AppColors.calendarCompletedBGDark
          : AppColors.calendarCompletedBGLight;

  Color get calendarMissedBG =>
      isDarkMode
          ? AppColors.calendarMissedBGDark
          : AppColors.calendarMissedBGLight;

  Color get calendarUpcomingBG =>
      isDarkMode
          ? AppColors.calendarUpcomingBGDark
          : AppColors.calendarUpcomingBGLight;

  // Calendar – Borders
  Color get calendarTodayBorder =>
      isDarkMode
          ? AppColors.calendarTodayBorderDark
          : AppColors.calendarTodayBorderLight;

  Color get calendarCompletedBorder =>
      isDarkMode
          ? AppColors.calendarCompletedBorderDark
          : AppColors.calendarCompletedBorderLight;

  Color get calendarMissedBorder =>
      isDarkMode
          ? AppColors.calendarMissedBorderDark
          : AppColors.calendarMissedBorderLight;

  Color get calendarUpcomingBorder =>
      isDarkMode
          ? AppColors.calendarUpcomingBorderDark
          : AppColors.calendarUpcomingBorderLight;

  // Calendar – Icons & misc
  Color get calendarCompletedIcon => AppColors.calendarCompletedIcon;
  Color get calendarMissedIcon => AppColors.calendarMissedIcon;

  Color get calendarDayHeader =>
      isDarkMode
          ? AppColors.calendarDayHeaderDark
          : AppColors.calendarDayHeaderLight;

  Color get calendarCellBorder =>
      isDarkMode
          ? AppColors.calendarCellBorderDark
          : AppColors.calendarCellBorderLight;

  Color get calendarTrailingDate =>
      isDarkMode
          ? AppColors.calendarTrailingDateDark
          : AppColors.calendarTrailingDateLight;

  Color get calendarDayText =>
      isDarkMode
          ? AppColors.calendarDayTextDark
          : AppColors.calendarDayTextLight;

  Color get calendarDayTextSecondary =>
      isDarkMode
          ? AppColors.calendarDayTextSecondaryDark
          : AppColors.calendarDayTextSecondaryLight;

  Color get calendarUpcomingDayText =>
      isDarkMode
          ? AppColors.calendarUpcomingDayTextDark
          : AppColors.calendarUpcomingDayTextLight;

  Color get calendarMonthText =>
      isDarkMode
          ? AppColors.calendarMonthTextDark
          : AppColors.calendarMonthTextLight;

  // Missed days badge
  Color get missedDaysBadgeBG =>
      isDarkMode
          ? AppColors.missedDaysBadgeBGDark
          : AppColors.missedDaysBadgeBGLight;

  Color get missedDaysBadgeText =>
      isDarkMode
          ? AppColors.missedDaysBadgeTextDark
          : AppColors.missedDaysBadgeTextLight;

  // Legend
  Color get legendBorder =>
      isDarkMode ? AppColors.legendBorderDark : AppColors.legendBorderLight;
  Color get legendText =>
      isDarkMode ? AppColors.legendTextDark : AppColors.legendTextLight;

  // Dialog
  Color get dialogBG =>
      isDarkMode ? AppColors.dialogBGDark : AppColors.dialogBGLight;
  Color get dialogTitle =>
      isDarkMode ? AppColors.dialogTitleDark : AppColors.dialogTitleLight;
  Color get dialogContent =>
      isDarkMode ? AppColors.dialogContentDark : AppColors.dialogContentLight;
  Color get dialogCancel =>
      isDarkMode ? AppColors.dialogCancelDark : AppColors.dialogCancelLight;
}
