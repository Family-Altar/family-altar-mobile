import 'package:family_altar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App font configuration with a simple, commonly used book font
class AppFonts {
  // Private constructor to prevent instantiation
  AppFonts._();

  /// Using Open Sans - a clean, readable sans-serif font perfect for books
  // static const String _fontFamily = 'Open Sans';

  // Font variants
  /// Normal font style (400 weight)
  static TextStyle normal(BuildContext context,
          {FontSize size = FontSize.medium}) =>
      GoogleFonts.openSans(
        fontSize: _getFontSize(size),
        fontWeight: FontWeight.w400,
        color: context.textColor,
      );

  /// Bold font style (700 weight)
  static TextStyle bold(BuildContext context,
          {FontSize size = FontSize.medium}) =>
      GoogleFonts.openSans(
        fontSize: _getFontSize(size),
        fontWeight: FontWeight.w700,
        color: context.textColor,
      );

  /// Extra bold font style (900 weight)
  static TextStyle extraBold(BuildContext context,
          {FontSize size = FontSize.medium}) =>
      GoogleFonts.openSans(
        fontSize: _getFontSize(size),
        fontWeight: FontWeight.w900,
        color: context.textColor,
      );

  /// Italics font style (400 weight, italic)
  static TextStyle italics(BuildContext context,
          {FontSize size = FontSize.medium}) =>
      GoogleFonts.openSans(
        fontSize: _getFontSize(size),
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: context.textColor,
      );

  /// Helper method to get font size based on enum
  static double _getFontSize(FontSize size) {
    switch (size) {
      case FontSize.small:
        return 14;
      case FontSize.medium:
        return 16;
      case FontSize.large:
        return 18;
    }
  }
}

/// Font size enum for consistent sizing
enum FontSize {
  small,
  medium,
  large,
}