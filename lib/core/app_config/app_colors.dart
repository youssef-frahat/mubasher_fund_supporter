import 'package:flutter/material.dart';

class AppColors {
  // Brand Main Colors (Fintech Emerald & Midnight Slate)
  static const Color primary = Color(0xFF00E676);      // Electric Emerald (Growth & Wealth)
  static const Color primaryDark = Color(0xFF00B0FF);  // Deep Cyan Accent
  static const Color secondary = Color(0xFF1E293B);    // Slate Surface Container
  static const Color background = Color(0xFF0F172A);   // Midnight Navy Background
  static const Color midnightNavy = Color(0xFF0F172A); // Midnight Navy Background Alias
  static const Color surface = Color(0xFF1E293B);      // Surface Cards
  static const Color slateCard = Color(0xFF1E293B);    // Slate Surface Container Alias

  // Text & Border Colors
  static const Color textPrimary = Color(0xFFF8FAFC);  // Crisp White Text
  static const Color textSecondary = Color(0xFF94A3B8);// Cool Muted Slate
  static const Color border = Color(0xFF334155);       // Subtle Divider Line
  static const Color gold = Color(0xFFF59E0B);         // Gold Funds Accent

  // Status Indicators
  static const Color success = Color(0xFF10B981);      // Profit Green
  static const Color error = Color(0xFFEF4444);        // Loss Red
  static const Color warning = Color(0xFFF59E0B);      // Warning Yellow

  // Gradients for Premium Fintech UI
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // 10% White Glass
      Color(0x05FFFFFF), // 2% White Glass
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dynamic Theme Adaptive Helpers (Light & Dark Theme Support)
  static Color getBackground(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color getSurface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color getTextPrimary(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF64748B);
  static Color getBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF334155)
          : const Color(0xFFE2E8F0);
  static LinearGradient getCardGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
          : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}


