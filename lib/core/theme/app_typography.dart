import 'package:flutter/material.dart';

/// Typography scale. Uses the platform default font family (no bundled font
/// asset in Phase 1) but centralizes sizes/weights so a custom font can be
/// dropped in later by setting [fontFamily].
class AppTypography {
  AppTypography._();

  static const String? fontFamily = null;

  static TextTheme textTheme(Color onSurface, Color muted) {
    return TextTheme(
      displayLarge: TextStyle(
          fontSize: 40, fontWeight: FontWeight.w700, color: onSurface),
      headlineMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, color: onSurface),
      titleLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: onSurface),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: TextStyle(fontSize: 16, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, color: onSurface),
      bodySmall: TextStyle(fontSize: 12, color: muted),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
    );
  }
}
