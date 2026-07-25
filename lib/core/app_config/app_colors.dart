import 'package:flutter/material.dart';

class AppColors {
  // Brand Main Colors (Fintech Emerald & Midnight Slate)
  static const Color primary = Color(0xFF00E676);      // Electric Emerald (Growth & Wealth)
  static const Color primaryDark = Color(0xFF00B0FF);  // Deep Cyan Accent
  static const Color secondary = Color(0xFF1E293B);    // Slate Surface Container
  static const Color background = Color(0xFF0F172A);   // Midnight Navy Background
  static const Color surface = Color(0xFF1E293B);      // Surface Cards

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
}

