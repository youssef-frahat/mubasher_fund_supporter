import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_config/app_colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double? size;
  final String? message;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double indicatorSize = size ?? 54.r;
    final Color activeColor = color ?? AppColors.primary;
    final textSecondary = AppColors.getTextSecondary(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glowing Pulsing Ring
              Container(
                width: indicatorSize,
                height: indicatorSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activeColor.withValues(alpha: 0.3),
                    width: 3.r,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(duration: 1000.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15)),

              // Inner Spinning Circular Progress Ring
              SizedBox(
                width: indicatorSize,
                height: indicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: 3.r,
                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                ),
              ),

              // Center Glowing Emblem
              FaIcon(
                FontAwesomeIcons.vault,
                color: activeColor,
                size: indicatorSize * 0.4,
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .shimmer(duration: 1500.ms, color: Colors.white),
            ],
          ),
          if (message != null) ...[
            SizedBox(height: 14.h),
            Text(
              message!,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 400.ms),
          ],
        ],
      ),
    );
  }
}
