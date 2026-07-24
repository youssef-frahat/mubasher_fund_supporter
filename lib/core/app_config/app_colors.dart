import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0F62FE); // Deep IBM Blue
  static const Color secondary = Color(0xFF8A3FFC); // Vibrant Purple
  static const Color background = Color(0xFFF4F7FB); // Very light greyish blue
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF161616);
  static const Color textSecondary = Color(0xFF525252);
  
  static const Color success = Color(0xFF24A148);
  static const Color error = Color(0xFFDA1E28);
  static const Color warning = Color(0xFFF1C21B);

  // Gradients for premium look
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F62FE), Color(0xFF8A3FFC)],
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
