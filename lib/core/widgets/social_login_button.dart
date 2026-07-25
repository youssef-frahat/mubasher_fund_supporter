import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_config/font_styles.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        overlayColor: const Color(0xFF2563EB).withValues(alpha: 0.2), // Active Blue Ripple on Tap
        elevation: 1,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 22.r,
              width: 22.r,
              child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFEA4335), // Red
                      Color(0xFFFBBC05), // Yellow
                      Color(0xFF34A853), // Green
                      Color(0xFF4285F4), // Blue
                    ],
                  ).createShader(bounds),
                  child: FaIcon(
                    FontAwesomeIcons.google,
                    size: 20.r,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  label,
                  style: FontStyles.titleMedium.copyWith(
                    color: const Color(0xFF0F172A),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}
