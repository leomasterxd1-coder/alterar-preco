import 'package:flutter/material.dart';

class AppColors {
  static const red = Color(0xFFB01C1C);
  static const redDark = Color(0xFF8F1515);
  static const headerGray = Color(0xFF7C878A);
  static const cyan = Color(0xFF5FC5D6);
  static const background = Color(0xFFF0F0F0);
  static const textDark = Color(0xFF333333);
  static const textMuted = Color(0xFF8A8A8A);
  static const divider = Color(0xFFE0E0E0);
  static const gold = Color(0xFFB68A2E);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.red,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.red,
    secondary: AppColors.cyan,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      border: InputBorder.none,
    ),
  );
}
