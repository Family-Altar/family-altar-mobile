import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Theme state class
class ThemeState extends Equatable {
  const ThemeState({
    required this.themeMode,
    required this.isDarkMode,
    required this.lightTheme,
    required this.darkTheme,
  });

  final ThemeMode themeMode;
  final bool isDarkMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  /// Get the current theme based on the theme mode
  ThemeData get currentTheme {
    switch (themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return isDarkMode ? darkTheme : lightTheme;
    }
  }

  /// Copy with method for state updates
  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isDarkMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }

  @override
  List<Object?> get props => [themeMode, isDarkMode, lightTheme, darkTheme];
}
