import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6750A4);
  static const Color primaryVariant = Color(0xFF4F378B);
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryVariant = Color(0xFF4A4458);
  
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightAppBar = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1C1B1F);
  static const Color lightOnSurface = Color(0xFF1C1B1F);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  
  // Dark theme 
  static const Color darkBackground = Color(0xFF1C1B1F);
  static const Color darkSurface = Color(0xFF1C1B1F);
  static const Color darkOnBackground = Color(0xFFE6E1E5);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  
  static const Color accent = Color(0xFF7C4DFF);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}

extension ThemeColors on BuildContext {
  Color get primaryColor => Theme.of(this).colorScheme.primary;
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
}
