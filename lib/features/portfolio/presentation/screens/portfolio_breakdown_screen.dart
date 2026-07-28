import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../data/models/portfolio_item_model.dart';

class PortfolioBreakdownScreen extends StatelessWidget {
  final PortfolioHealthSummary healthSummary;

  const PortfolioBreakdownScreen({super.key, required this.healthSummary});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isAr ? 'تحليل صحة وتنويع المحفظة' : 'Portfolio Health & Diversification',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Banner Header
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: healthSummary.scoreColor, width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: healthSummary.scoreColor.withValues(alpha: 0.2),
                    child: Text(
                      '${healthSummary.score}',
                      style: TextStyle(
                        color: healthSummary.scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          healthSummary.getRatingText(isAr),
                          style: TextStyle(
                            color: healthSummary.scoreColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${isAr ? 'إجمالي قيمة المحفظة' : 'Total Portfolio Value'}: ${healthSummary.totalPortfolioValue.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Donut Chart Asset Allocation
            Text(
              isAr ? '📊 توزيع الأصول المالي (Asset Allocation)' : '📊 Asset Allocation Breakdown',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 14.h),

            Container(
              height: 220.h,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: border),
              ),
              child: healthSummary.categoryPercentages.isEmpty
                  ? Center(
                      child: Text(
                        isAr ? 'لا توجد بيانات للعرض' : 'No data available',
                        style: TextStyle(color: textSecondary, fontSize: 13.sp),
                      ),
                    )
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 45.r,
                        sections: healthSummary.categoryPercentages.entries.map((entry) {
                          final category = entry.key;
                          final percentage = entry.value;
                          return PieChartSectionData(
                            color: category.color,
                            value: percentage,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 35.r,
                            titleStyle: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            SizedBox(height: 24.h),

            // Detailed Breakdown List per Category
            Text(
              isAr ? '📑 تفاصيل النسب حسب الفئة:' : '📑 Percentage Breakdown by Category:',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            ...healthSummary.categoryPercentages.entries.map((entry) {
              final category = entry.key;
              final percentage = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 22.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        category.getDisplayName(isAr),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: category.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
