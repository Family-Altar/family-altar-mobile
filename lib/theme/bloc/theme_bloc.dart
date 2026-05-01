import 'dart:ui';

import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(_initialState) {
    on<ThemeInitializeEvent>(_onInitialize);
    on<ThemeToggleEvent>(_onToggle);
    on<ThemeSetEvent>(_onSetTheme);
    on<ThemeReadingFontSizeChanged>(_onReadingFontSizeChanged);
  }

  static const _themeKey = 'theme_mode';
  static const _readingFontSizeKey = 'reading_font_size';

  static final ThemeState _initialState = ThemeState(
    themeMode: ThemeMode.system,
    isDarkMode: false,
    lightTheme: _createLightTheme(),
    darkTheme: _createDarkTheme(),
    readingFontSize: 16,
  );


  Future<void> _onInitialize(
    ThemeInitializeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIdx = prefs.getInt(_themeKey);
      final savedSize = prefs.getDouble(_readingFontSizeKey);

      var mode = ThemeMode.system;
      if (savedIdx != null && savedIdx < ThemeMode.values.length) {
        mode = ThemeMode.values[savedIdx];
      }

      final isSysDark = PlatformDispatcher.instance.platformBrightness ==
          Brightness.dark;

      final isDark = mode == ThemeMode.dark ||
          (mode == ThemeMode.system && isSysDark);

      emit(state.copyWith(
        themeMode: mode,
        isDarkMode: isDark,
        readingFontSize: savedSize ?? 16,
      ));
    } on Exception {
      emit(state);
    }
  }

  Future<void> _onToggle(
    ThemeToggleEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final newMode = state.themeMode == ThemeMode.system
        ? (state.isDarkMode ? ThemeMode.light : ThemeMode.dark)
        : state.themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light;

    await _saveThemeMode(newMode);
    emit(state.copyWith(
      themeMode: newMode,
      isDarkMode: newMode == ThemeMode.dark,
    ));
  }

  Future<void> _onSetTheme(
    ThemeSetEvent event,
    Emitter<ThemeState> emit,
  ) async {
    await _saveThemeMode(event.themeMode);
    emit(state.copyWith(
      themeMode: event.themeMode,
      isDarkMode: event.themeMode == ThemeMode.dark,
    ));
  }

  Future<void> _onReadingFontSizeChanged(
    ThemeReadingFontSizeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    final size = event.fontSize.clamp(12.0, 28.0);
    await _saveReadingFontSize(size);
    emit(state.copyWith(readingFontSize: size));
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> _saveReadingFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_readingFontSizeKey, size);
  }

  static  ThemeData _createLightTheme() {
    const p = AppColors.primary;
    const on = AppColors.lightOnBackground;

    return  ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: p,
        secondary: AppColors.secondary,
        error: AppColors.lightError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: p,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme:const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            AppColors.primaryButtonBGColorLight,
          ),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ),
      textTheme:const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: on,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: on,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: on,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: on,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: on),
        bodyMedium: TextStyle(fontSize: 14, color: on),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
    );
  }

  static ThemeData _createDarkTheme() {
    const on = AppColors.darkOnBackground;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkAccent,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryVariant,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        error: AppColors.darkError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: on,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme:const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme:const ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            AppColors.primaryButtonBGColorDark,
          ),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: on,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: on,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: on,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: on,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: on),
        bodyMedium: TextStyle(fontSize: 14, color: on),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }
}