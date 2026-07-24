import 'package:flutter/material.dart';
import '../app_config/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        surface: AppColors.surface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outlineVariant: AppColors.outlineVariant,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        primaryContainer: AppColors.darkPrimaryContainer,
        secondaryContainer: AppColors.darkSecondaryContainer,
        surface: AppColors.darkSurface,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }
}
