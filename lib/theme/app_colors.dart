import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF511D18);
  static const Color primaryVariant = Color(0xFF4F378B);
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryVariant = Color(0xFF4A4458);
  
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightAppBar = Color(0xFFFFFFFF);
  static const Color lightOnBackground =Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFFD6D6D6);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  
  // Dark theme 
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface =Color(0xFF131313);
  static const Color darkOnBackground = Color(0xFFE6E1E5);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  

  static const Color lightAccent = Color(0xFF511D18);
static const Color darkAccent =Color(0xFFE6B453);

  static const Color accent = Color(0xFF511D18);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Primary button colors (teal/dark green) - used in calendar and primary actions
  static const Color primaryButtonBGColorLight = Color(0xFF294B4D);
  static const Color primaryButtonBGColorDark = Color(0xFF2C5F5F);
  
  // Calendar colors - Background colors for day cells
  // Light blue
  static const Color calendarTodayBGLight = Color(0xFFE3F2FD);
  // Dark blue
  static const Color calendarTodayBGDark = Color(0xFF0D47A1);
  // Light green
  static const Color calendarCompletedBGLight = Color(0xFFE8F5E8);
  // Dark green
  static const Color calendarCompletedBGDark = Color(0xFF1B5E20);
  // Light pink
  static const Color calendarMissedBGLight = Color(0xFFFCE4EC);
  // Dark red
  static const Color calendarMissedBGDark = Color(0xFFB71C1C);
  static const Color calendarUpcomingBGLight = Colors.white;
  // Dark grey
  static const Color calendarUpcomingBGDark = Color(0xFF424242);
  
  // Calendar colors - Border colors
  // Blue
  static const Color calendarTodayBorder = Color(0xFF2196F3);
  // Green
  static const Color calendarCompletedBorder = Color(0xFF4CAF50);
  // Pink/Red
  static const Color calendarMissedBorder = Color(0xFFE91E63);
  // Grey 300
  static const Color calendarUpcomingBorderLight = Color(0xFFE0E0E0);
  // Grey 600
  static const Color calendarUpcomingBorderDark = Color(0xFF757575);
  
  // Calendar colors - Icon colors
  // Green
  static const Color calendarCompletedIcon = Color(0xFF4CAF50);
  // Pink/Red
  static const Color calendarMissedIcon = Color(0xFFE91E63);
  
  // Calendar colors - Day header colors
  // Grey 600
  static const Color calendarDayHeaderLight = Color(0xFF757575);
  // Grey 400
  static const Color calendarDayHeaderDark = Color(0xFF9E9E9E);
  
  // Calendar colors - Cell border colors
  // Grey 200
  static const Color calendarCellBorderLight = Color(0xFFEEEEEE);
  // Grey 600
  static const Color calendarCellBorderDark = Color(0xFF757575);
  
  // Calendar colors - Trailing/leading date colors
  // Grey 400
  static const Color calendarTrailingDateLight = Color(0xFF9E9E9E);
  // Grey 600
  static const Color calendarTrailingDateDark = Color(0xFF757575);
  
  // Calendar colors - Day text for upcoming
  // Grey 600
  static const Color calendarUpcomingDayTextLight = Color(0xFF757575);
  // Grey 400
  static const Color calendarUpcomingDayTextDark = Color(0xFF9E9E9E);
  
  // Calendar colors - Regular day text
  // Black
  static const Color calendarDayTextLight = Color(0xFF000000);
  // White
  static const Color calendarDayTextDark = Color(0xFFFFFFFF);
  // Black 87%
  static const Color calendarDayTextSecondaryLight = Color(0xFF212121);
  // White
  static const Color calendarDayTextSecondaryDark = Color(0xFFFFFFFF);
  
  // Calendar header - Month name and navigation
  // Black
  static const Color calendarMonthTextLight = Color(0xFF000000);
  // White
  static const Color calendarMonthTextDark = Color(0xFFFFFFFF);
  
  // Missed days badge colors
  // Grey 200
  static const Color missedDaysBadgeBGLight = Color(0xFFEEEEEE);
  // Grey 700
  static const Color missedDaysBadgeBGDark = Color(0xFF616161);
  // Grey 700
  static const Color missedDaysBadgeTextLight = Color(0xFF616161);
  // Grey 300
  static const Color missedDaysBadgeTextDark = Color(0xFFE0E0E0);
  
  // Legend colors
  // Grey 300
  static const Color legendBorderLight = Color(0xFFE0E0E0);
  // Grey 600
  static const Color legendBorderDark = Color(0xFF757575);
  // Grey 700
  static const Color legendTextLight = Color(0xFF616161);
  // Grey 300
  static const Color legendTextDark = Color(0xFFE0E0E0);
  
  // Dialog colors
  // White
  static const Color dialogBGLight = Color(0xFFFFFFFF);
  // Grey 900
  static const Color dialogBGDark = Color(0xFF212121);
  // Black
  static const Color dialogTitleLight = Color(0xFF000000);
  // White
  static const Color dialogTitleDark = Color(0xFFFFFFFF);
  // Grey 700
  static const Color dialogContentLight = Color(0xFF616161);
  // Grey 300
  static const Color dialogContentDark = Color(0xFFE0E0E0);
  // Grey 600
  static const Color dialogCancelLight = Color(0xFF757575);
  // Grey 400
  static const Color dialogCancelDark = Color(0xFF9E9E9E);
  // Red 600
  static const Color dialogMarkUnreadBG = Color(0xFFE53935);
  // Green 600
  static const Color dialogMarkReadBG = Color(0xFF43A047);
  // White
  static const Color dialogButtonText = Color(0xFFFFFFFF);
}

extension ThemeColors on BuildContext {
    Color get accent => isDarkMode
      ? AppColors.darkAccent
      : AppColors.lightAccent;
  Color get primaryColor => AppColors.primary;
  Color get backgroundColor => isDarkMode
      ? AppColors.darkBackground
      : AppColors.lightBackground;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get textColor => isDarkMode
      ? AppColors.darkOnBackground
      : AppColors.lightOnBackground;
  Color get errorColor => Theme.of(this).colorScheme.error;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get appBarColor => isDarkMode
      ? AppColors.darkSurface
      : AppColors.lightAppBar;
  Color get primaryButtonBGColor => isDarkMode
      ? AppColors.primaryButtonBGColorDark
      : AppColors.primaryButtonBGColorLight;
  
  // Calendar colors - Background
  Color get calendarTodayBG => isDarkMode
      ? AppColors.calendarTodayBGDark
      : AppColors.calendarTodayBGLight;
  Color get calendarCompletedBG => isDarkMode
      ? AppColors.calendarCompletedBGDark
      : AppColors.calendarCompletedBGLight;
  Color get calendarMissedBG => isDarkMode
      ? AppColors.calendarMissedBGDark
      : AppColors.calendarMissedBGLight;
  Color get calendarUpcomingBG => isDarkMode
      ? AppColors.calendarUpcomingBGDark
      : AppColors.calendarUpcomingBGLight;
  
  // Calendar colors - Borders
  Color get calendarUpcomingBorder => isDarkMode
      ? AppColors.calendarUpcomingBorderDark
      : AppColors.calendarUpcomingBorderLight;
  
  // Calendar colors - Day header
  Color get calendarDayHeader => isDarkMode
      ? AppColors.calendarDayHeaderDark
      : AppColors.calendarDayHeaderLight;
  
  // Calendar colors - Cell border
  Color get calendarCellBorder => isDarkMode
      ? AppColors.calendarCellBorderDark
      : AppColors.calendarCellBorderLight;
  
  // Calendar colors - Trailing/leading dates
  Color get calendarTrailingDate => isDarkMode
      ? AppColors.calendarTrailingDateDark
      : AppColors.calendarTrailingDateLight;
  
  // Calendar colors - Day text
  Color get calendarDayText => isDarkMode
      ? AppColors.calendarDayTextDark
      : AppColors.calendarDayTextLight;
  Color get calendarDayTextSecondary => isDarkMode
      ? AppColors.calendarDayTextSecondaryDark
      : AppColors.calendarDayTextSecondaryLight;
  Color get calendarUpcomingDayText => isDarkMode
      ? AppColors.calendarUpcomingDayTextDark
      : AppColors.calendarUpcomingDayTextLight;
  
  // Calendar header - Month name
  Color get calendarMonthText => isDarkMode
      ? AppColors.calendarMonthTextDark
      : AppColors.calendarMonthTextLight;
  
  // Missed days badge
  Color get missedDaysBadgeBG => isDarkMode
      ? AppColors.missedDaysBadgeBGDark
      : AppColors.missedDaysBadgeBGLight;
  Color get missedDaysBadgeText => isDarkMode
      ? AppColors.missedDaysBadgeTextDark
      : AppColors.missedDaysBadgeTextLight;
  
  // Legend
  Color get legendBorder => isDarkMode
      ? AppColors.legendBorderDark
      : AppColors.legendBorderLight;
  Color get legendText => isDarkMode
      ? AppColors.legendTextDark
      : AppColors.legendTextLight;
  
  // Dialog
  Color get dialogBG => isDarkMode
      ? AppColors.dialogBGDark
      : AppColors.dialogBGLight;
  Color get dialogTitle => isDarkMode
      ? AppColors.dialogTitleDark
      : AppColors.dialogTitleLight;
  Color get dialogContent => isDarkMode
      ? AppColors.dialogContentDark
      : AppColors.dialogContentLight;
  Color get dialogCancel => isDarkMode
      ? AppColors.dialogCancelDark
      : AppColors.dialogCancelLight;
}
