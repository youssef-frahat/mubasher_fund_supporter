import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_config/app_colors.dart';

class AppSnackBar {
  static void showSuccess(BuildContext context, String message, {String? title}) {
    _showCustomSnackBar(
      context,
      message: message,
      title: title ?? 'تمت العملية بنجاح 🚀',
      backgroundColor: const Color(0xFF059669),
      borderColor: const Color(0xFF10B981),
      icon: FontAwesomeIcons.circleCheck,
      iconColor: const Color(0xFF34D399),
    );
  }

  static void showError(BuildContext context, String message, {String? title}) {
    _showCustomSnackBar(
      context,
      message: message,
      title: title ?? 'عذراً، حدث خطأ ⚠️',
      backgroundColor: const Color(0xFFDC2626),
      borderColor: const Color(0xFFEF4444),
      icon: FontAwesomeIcons.triangleExclamation,
      iconColor: const Color(0xFFFCA5A5),
    );
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    _showCustomSnackBar(
      context,
      message: message,
      title: title ?? 'تنبيه مهم ⚡️',
      backgroundColor: const Color(0xFFD97706),
      borderColor: const Color(0xFFF59E0B),
      icon: FontAwesomeIcons.circleExclamation,
      iconColor: const Color(0xFFFDE68A),
    );
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    _showCustomSnackBar(
      context,
      message: message,
      title: title ?? 'ملاحظة ℹ️',
      backgroundColor: const Color(0xFF2563EB),
      borderColor: const Color(0xFF3B82F6),
      icon: FontAwesomeIcons.circleInfo,
      iconColor: const Color(0xFF93C5FD),
    );
  }

  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required String title,
    required Color backgroundColor,
    required Color borderColor,
    required dynamic icon,
    required Color iconColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: EdgeInsets.all(16.r),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            gradient: LinearGradient(
              colors: [
                backgroundColor.withValues(alpha: 0.95),
                backgroundColor.withValues(alpha: 0.80),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(icon as FaIconData, color: iconColor, size: 18.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 11.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
