import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF9D00FF); // Vibrant Neon Purple
  static const Color secondary = Color(0xFF180A32); // Deep Splash Purple
  static const Color background = Color(0xFF0D051A); // Deeper background for dark theme
  static const Color surface = Color(0xFF180A32);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  
  static const Color success = Color(0xFF24A148);
  static const Color error = Color(0xFFDA1E28);
  static const Color warning = Color(0xFFF1C21B);

  // Gradients for premium look
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF9D00FF), Color(0xFF5B00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x99FFFFFF), // 60% White
      Color(0x33FFFFFF), // 20% White
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
