import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app_config/font_styles.dart';
import '../app_config/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.iconWidget,
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
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 24.sp,
              width: 24.sp,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconWidget != null) iconWidget!
                else if (icon != null) Icon(icon, color: iconColor, size: 28.sp),
                SizedBox(width: 12.w),
                Text(label, style: FontStyles.titleMedium.copyWith(color: Colors.black87)),
              ],
            ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}
