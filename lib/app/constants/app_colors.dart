import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Blue
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFF60A5FA);

  // Delete / Destructive
  static const rose = Color(0xFFF43F5E);
  static const roseDark = Color(0xFFE11D48);

  // Surfaces
  static const dark = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceElevated = Color(0xFF334155);
  static const slate = Color(0xFF1E293B);

  static const lightBg = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF1F5F9);

  // Functional
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFF43F5E);

  // Aliases for backward compatibility
  static const secondary = rose;
  static const accent = rose;
  static const cyanAccent = primaryLight;
  static const amberAccent = Color(0xFFF59E0B);
  static const primaryGlow = primaryLight;

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
  );

  static const darkMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
  );
}
