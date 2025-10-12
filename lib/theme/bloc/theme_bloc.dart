import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';

/// Theme BLoC class
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(_initialState()) {
    on<ThemeInitializeEvent>(_onInitialize);
    on<ThemeToggleEvent>(_onToggle);
    on<ThemeSetEvent>(_onSetTheme);
  }

  static const String _themeKey = 'theme_mode';

  /// Create initial state with default themes
  static ThemeState _initialState() {
    return ThemeState(
      themeMode: ThemeMode.system,
      isDarkMode: false,
      lightTheme: _createLightTheme(),
      darkTheme: _createDarkTheme(),
    );
  }

  /// Initialize theme from system preferences
  Future<void> _onInitialize(
    ThemeInitializeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey);
      
      var themeMode = ThemeMode.system;
      if (savedThemeIndex != null) {
        themeMode = ThemeMode.values[savedThemeIndex];
      }

      final brightness = PlatformDispatcher.instance.platformBrightness;
      final isDarkMode = brightness == Brightness.dark;

      emit(state.copyWith(
        themeMode: themeMode,
        isDarkMode: isDarkMode,
      ));
    } on Exception {
      // If there's an error, use default state
      emit(state);
    }
  }

  /// Toggle between light and dark theme
  Future<void> _onToggle(
    ThemeToggleEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      ThemeMode newThemeMode;
      
      if (state.themeMode == ThemeMode.system) {
        // If currently system, switch to opposite of current appearance
        newThemeMode = state.isDarkMode ? ThemeMode.light : ThemeMode.dark;
      } else {
        // If currently light/dark, switch to opposite
        newThemeMode = state.themeMode == ThemeMode.light 
            ? ThemeMode.dark 
            : ThemeMode.light;
      }

      await _saveThemeMode(newThemeMode);
      
      emit(state.copyWith(
        themeMode: newThemeMode,
        isDarkMode: newThemeMode == ThemeMode.dark,
      ));
    } on Exception {
      // Handle error silently or emit error state
    }
  }

  /// Set specific theme mode
  Future<void> _onSetTheme(
    ThemeSetEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      await _saveThemeMode(event.themeMode);
      
      emit(state.copyWith(
        themeMode: event.themeMode,
        isDarkMode: event.themeMode == ThemeMode.dark,
      ));
    } on Exception {
      // Handle error silently or emit error state
    }
  }

  /// Save theme mode to shared preferences
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeMode.index);
  }

  /// Create light theme
  static ThemeData _createLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6750A4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF49454F),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// Create dark theme
  static ThemeData _createDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1B1F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2B2930),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFFE6E1E5),
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFFE6E1E5),
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFFE6E1E5),
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFE6E1E5),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFE6E1E5),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: Color(0xFFCAC4D0),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
