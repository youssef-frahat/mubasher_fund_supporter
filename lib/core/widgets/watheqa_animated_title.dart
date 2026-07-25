import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app_config/app_colors.dart';

class WatheqaAnimatedTitle extends StatelessWidget {
  const WatheqaAnimatedTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'وثيقة',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.w,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: AppColors.primary)
        .slideX(begin: -0.1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),

        SizedBox(width: 6.w),

        Container(
          width: 6.r,
          height: 6.r,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(duration: 800.ms, begin: const Offset(0.5, 0.5), end: const Offset(1.3, 1.3)),
      ],
    );
  }
}
