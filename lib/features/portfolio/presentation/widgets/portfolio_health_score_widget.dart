import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../data/models/portfolio_item_model.dart';
import '../screens/portfolio_breakdown_screen.dart';

class PortfolioHealthScoreWidget extends StatelessWidget {
  final PortfolioHealthSummary healthSummary;

  const PortfolioHealthScoreWidget({
    super.key,
    required this.healthSummary,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PortfolioBreakdownScreen(healthSummary: healthSummary),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: healthSummary.scoreColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: healthSummary.scoreColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Score Ring Indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60.r,
                  height: 60.r,
                  child: CircularProgressIndicator(
                    value: healthSummary.score / 100.0,
                    strokeWidth: 6.w,
                    backgroundColor: border,
                    valueColor: AlwaysStoppedAnimation<Color>(healthSummary.scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${healthSummary.score}',
                      style: TextStyle(
                        color: healthSummary.scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(width: 16.w),

            // Score details and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.isArabic ? 'مؤشر صحة وتنويع المحفظة' : 'Portfolio Health & Diversification',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      FaIcon(
                        FontAwesomeIcons.chevronLeft,
                        color: textSecondary,
                        size: 12.r,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    healthSummary.getRatingText(context.isArabic),
                    style: TextStyle(
                      color: healthSummary.scoreColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.isArabic
                        ? 'اضغط هنا لاستعراض التحليل التفصيلي ورادار المخاطر 📊'
                        : 'Tap to view detailed breakdown & risk radar 📊',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
