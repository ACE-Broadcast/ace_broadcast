import 'package:flutter/material.dart';

final lightColorScheme = ColorScheme.light(
  primary: const Color(0xFF6C63FF),
  secondary: const Color(0xFF8B85FF),
  surface: Colors.white,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: Colors.black,
  surfaceTint: const Color(0xFF6C63FF).withValues(alpha: 0.1),
  shadow: Colors.black.withValues(alpha: 0.2),
  inversePrimary: const Color(0xFF2B2930),
  surfaceDim: const Color(0xFFF7F7F7),
  surfaceContainer: const Color(0xFFF3F2FF),
  secondaryContainer: const Color(0xFFECEBFF),
  onSecondaryContainer: const Color(0xFF6C63FF),
  outline: const Color(0xFFE0E0E0),
);

final darkColorScheme = ColorScheme.dark(
  primary: const Color(0xFF8B85FF),
  secondary: const Color(0xFF6C63FF),
  surface: const Color(0xFF121212),
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: Colors.white,
  surfaceTint: const Color(0xFF6C63FF).withValues(alpha: 0.1),
  shadow: Colors.black.withValues(alpha: 0.3),
  inversePrimary: Colors.white,
  surfaceDim: const Color(0xFF1C1B1F),
  surfaceContainer: const Color(0xFF2D2C31),
  secondaryContainer: const Color(0xFF3C3B3F),
  onSecondaryContainer: Colors.white,
  outline: const Color(0xFF444448),
);
