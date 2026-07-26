import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/routing/routes.dart';
import '../../data/models/fund_model.dart';

class TodayOpportunityCard extends StatelessWidget {
  final FundModel? recommendedFund;

  const TodayOpportunityCard({super.key, this.recommendedFund});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LanguageCubit>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0F2D1F), Color(0xFF0B1F15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE8F7EE), Color(0xFFF3FAF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final borderColor = isDark ? const Color(0xFF1B4D35) : const Color(0xFFC2EBCD);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B331E);
    final textSecondary = isDark ? const Color(0xFFA3CDB5) : const Color(0xFF386B52);
    final fundNameText = recommendedFund?.name ?? 'EFG Hermes Growth Fund';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Pill Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF163E2B) : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isDark ? const Color(0xFF235C40) : const Color(0xFFA6E0B8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 4.w),
                      Text(
                        isAr ? 'فرصة اليوم' : "Today's Opportunity",
                        style: TextStyle(
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF047857),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // Main Title
                Text(
                  isAr ? 'حلّل الذكاء الاصطناعي السوق اليوم' : "AI analyzed today's market",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),

                // Subtitle
                Text(
                  isAr ? 'صناديق الأسهم تظهر أقوى زخم اليوم.' : 'Equity Funds are showing the strongest momentum today.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.sp,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 12.h),

                // Recommended Fund Badge
                Row(
                  children: [
                    const Text('⭐️', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 4.w),
                    Text(
                      isAr ? 'الصندوق الموصى به' : 'Recommended Fund',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Fund Name
                Text(
                  fundNameText,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),

                // Button
                ElevatedButton(
                  onPressed: () => context.push(Routes.allFunds),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF044E2B),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAr ? 'استكشف الآن' : 'Explore Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        isAr ? Icons.arrow_back : Icons.arrow_forward,
                        size: 14.r,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Right Graphic Illustration (3D Financial Chart Graphic)
          SizedBox(
            width: 90.w,
            height: 120.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Glow Circle
                Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  ),
                ),
                // Pie & Bar Chart Graphic
                CustomPaint(
                  size: Size(80.w, 100.h),
                  painter: _ChartGraphicPainter(isDark: isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartGraphicPainter extends CustomPainter {
  final bool isDark;

  _ChartGraphicPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bar1Paint = Paint()
      ..color = const Color(0xFFA7F3D0)
      ..style = PaintingStyle.fill;

    final bar2Paint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.fill;

    final bar3Paint = Paint()
      ..color = const Color(0xFF059669)
      ..style = PaintingStyle.fill;

    final arrowPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowHeadPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    // Draw Bars
    double barWidth = 14.w;
    double bottomY = size.height - 10.h;

    // Bar 1 (Shortest)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10.w, bottomY - 30.h, barWidth, 30.h),
        Radius.circular(4.r),
      ),
      bar1Paint,
    );

    // Bar 2 (Medium)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30.w, bottomY - 50.h, barWidth, 50.h),
        Radius.circular(4.r),
      ),
      bar2Paint,
    );

    // Bar 3 (Tallest)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(50.w, bottomY - 75.h, barWidth, 75.h),
        Radius.circular(4.r),
      ),
      bar3Paint,
    );

    // Draw Arrow Curved Line
    Path arrowPath = Path();
    arrowPath.moveTo(8.w, bottomY - 15.h);
    arrowPath.quadraticBezierTo(25.w, bottomY - 55.h, 68.w, bottomY - 85.h);
    canvas.drawPath(arrowPath, arrowPaint);

    // Arrow Head
    Path headPath = Path();
    headPath.moveTo(68.w, bottomY - 85.h);
    headPath.lineTo(58.w, bottomY - 82.h);
    headPath.lineTo(65.w, bottomY - 72.h);
    headPath.close();
    canvas.drawPath(headPath, arrowHeadPaint);

    // Draw Top Floating Pie Arc
    final piePaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromLTWH(15.w, 5.h, 40.w, 40.w),
      -0.5,
      4.5,
      true,
      piePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
