import 'package:flutter/material.dart';

/// Central color palette. Greens/teals evoke a calm, spiritual tone.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF00695C); // deep teal-green
  static const Color primaryLight = Color(0xFF439889);
  static const Color primaryDark = Color(0xFF003D33);
  static const Color accent = Color(0xFFC9A227); // muted gold

  // Light scheme
  static const Color lightBackground = Color(0xFFF7F9F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1A1C1B);
  static const Color lightMuted = Color(0xFF5F6B67);

  // Dark scheme
  static const Color darkBackground = Color(0xFF0E1513);
  static const Color darkSurface = Color(0xFF16201D);
  static const Color darkOnSurface = Color(0xFFE6EAE8);
  static const Color darkMuted = Color(0xFF9AA8A3);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFC62828);
}
