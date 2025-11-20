import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Base class for all theme events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to toggle between light and dark theme
class ThemeToggleEvent extends ThemeEvent {
  const ThemeToggleEvent();
}

/// Event to set a specific theme mode
class ThemeSetEvent extends ThemeEvent {
  const ThemeSetEvent(this.themeMode);
  
  final ThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];
}

/// Event to update the reading font size
class ThemeReadingFontSizeChanged extends ThemeEvent {
  const ThemeReadingFontSizeChanged(this.fontSize);

  final double fontSize;

  @override
  List<Object?> get props => [fontSize];
}

/// Event to initialize theme from system preferences
class ThemeInitializeEvent extends ThemeEvent {
  const ThemeInitializeEvent();
}
