import 'dart:ui';

import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:family_altar/theme/app_colors.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(_initialState()) {
    on<ThemeInitializeEvent>(_onInitialize);
    on<ThemeToggleEvent>(_onToggle);
    on<ThemeSetEvent>(_onSetTheme);
    on<ThemeReadingFontSizeChanged>(_onReadingFontSizeChanged);
  }

  static const String _themeKey = 'theme_mode';
  static const String _readingFontSizeKey = 'reading_font_size';

  static ThemeState _initialState() {
    return ThemeState(
      themeMode: ThemeMode.system,
      isDarkMode: false,
      lightTheme: _createLightTheme(),
      darkTheme: _createDarkTheme(),
      readingFontSize: 16.0,
    );
  }

  Future<void> _onInitialize(ThemeInitializeEvent event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey);
      final savedFontSize = prefs.getDouble(_readingFontSizeKey);

      var themeMode = ThemeMode.system;
      if (savedThemeIndex != null) {
        themeMode = ThemeMode.values[savedThemeIndex];
      }

      final brightness = PlatformDispatcher.instance.platformBrightness;
      final isDarkMode = brightness == Brightness.dark;

      emit(state.copyWith(
        themeMode: themeMode,
        isDarkMode: isDarkMode,
        readingFontSize: savedFontSize ?? state.readingFontSize,
      ));
    } on Exception {
      emit(state);
    }
  }

  Future<void> _onToggle(ThemeToggleEvent event, Emitter<ThemeState> emit) async {
    try {
      ThemeMode newThemeMode = state.themeMode == ThemeMode.system
          ? (state.isDarkMode ? ThemeMode.light : ThemeMode.dark)
          : (state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

      await _saveThemeMode(newThemeMode);

      emit(state.copyWith(
        themeMode: newThemeMode,
        isDarkMode: newThemeMode == ThemeMode.dark,
      ));
    } on Exception {}
  }

  Future<void> _onSetTheme(ThemeSetEvent event, Emitter<ThemeState> emit) async {
    await _saveThemeMode(event.themeMode);
    emit(state.copyWith(
      themeMode: event.themeMode,
      isDarkMode: event.themeMode == ThemeMode.dark,
    ));
  }

  Future<void> _onReadingFontSizeChanged(ThemeReadingFontSizeChanged event, Emitter<ThemeState> emit) async {
    final clampedSize = event.fontSize.clamp(12.0, 28.0);
    await _saveReadingFontSize(clampedSize);
    emit(state.copyWith(readingFontSize: clampedSize));
  }

  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeMode.index);
  }

  Future<void> _saveReadingFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_readingFontSizeKey, fontSize);
  }

  static ThemeData _createLightTheme() {
    const primary = AppColors.primary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        background: AppColors.lightBackground,
        onBackground: AppColors.lightOnBackground,
        error: AppColors.lightError,
        onError: AppColors.lightOnError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButtonBGColorLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.lightOnBackground),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.lightOnBackground),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.lightOnBackground),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.lightOnBackground),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.lightOnBackground),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.lightOnBackground),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
    );
  }

  static ThemeData _createDarkTheme() {
    const primary = AppColors.primary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryVariant,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkOnBackground,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnBackground,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButtonBGColorDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.darkOnBackground),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.darkOnBackground),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.darkOnBackground),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkOnBackground),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkOnBackground),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkOnBackground),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }
}