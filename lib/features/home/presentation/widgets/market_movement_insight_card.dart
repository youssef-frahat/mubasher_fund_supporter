import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../data/models/fund_model.dart';

class MarketMovementInsightCard extends StatelessWidget {
  final List<FundModel> funds;

  const MarketMovementInsightCard({
    super.key,
    required this.funds,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final border = AppColors.getBorder(context);
    final isAr = context.isArabic;

    final total = funds.isNotEmpty ? funds.length : 1;

    // 1. Determine latest price update timestamp across funds
    DateTime? latestUpdate;
    for (var f in funds) {
      if (f.updatedAt != null) {
        if (latestUpdate == null || f.updatedAt!.isAfter(latestUpdate)) {
          latestUpdate = f.updatedAt;
        }
      }
    }

    final now = DateTime.now();
    final hoursSinceUpdate = latestUpdate != null ? now.difference(latestUpdate).inHours : 48;
    final daysSinceUpdate = latestUpdate != null ? now.difference(latestUpdate).inDays : 2;

    // 2. Determine if price movement actually occurred or if prices are static (> 24h / no dailyChange)
    final movedFundsCount = funds.where((f) => f.dailyChange != 0.0).length;
    final bool isStaticOrStale = hoursSinceUpdate >= 24 || (funds.isNotEmpty && movedFundsCount == 0);

    int gainedCount = 0;
    int declinedCount = 0;
    int stableCount = 0;

    if (isStaticOrStale) {
      // If no price changes occurred in > 24 hours, session is 100% stable/flat
      stableCount = funds.isNotEmpty ? funds.length : 1;
      gainedCount = 0;
      declinedCount = 0;
    } else {
      // Calculate actual movement based on real daily price changes
      gainedCount = funds.where((f) => f.dailyChange > 0).length;
      declinedCount = funds.where((f) => f.dailyChange < 0).length;
      stableCount = funds.where((f) => f.dailyChange == 0).length;
    }

    final gainPct = (gainedCount / total) * 100;
    final declinePct = (declinedCount / total) * 100;
    final stablePct = (stableCount / total) * 100;

    final gainFlex = (gainPct * 10).round().clamp(0, 1000);
    final declineFlex = (declinePct * 10).round().clamp(0, 1000);
    final stableFlex = (stablePct * 10).round().clamp(0, 1000);

    // Format human-readable time elapsed
    String timeAgoText = '';
    if (daysSinceUpdate >= 2) {
      timeAgoText = isAr ? 'منذ $daysSinceUpdate يوم' : '$daysSinceUpdate days ago';
    } else if (hoursSinceUpdate >= 1) {
      timeAgoText = isAr ? 'منذ $hoursSinceUpdate ساعة' : '$hoursSinceUpdate hours ago';
    } else {
      timeAgoText = isAr ? 'اليوم' : 'today';
    }

    String titleText;
    String insightText;
    Color insightBgColor;
    Color insightBorderColor;

    if (isStaticOrStale) {
      titleText = context.tr('marketMovementTitleStatic');
      insightText = isAr
          ? '⏸️ هدوء في التداولات واستقرار في الأسعار ($timeAgoText - لم تتغير الأسعار مؤخراً).'
          : '⏸️ Quiet session & stable prices (Last update: $timeAgoText).';
      insightBgColor = Colors.amber.shade600.withValues(alpha: 0.12);
      insightBorderColor = Colors.amber.shade600.withValues(alpha: 0.4);
    } else {
      titleText = context.tr('marketMovementTitleLive');
      if (gainPct >= 50) {
        insightText = context.tr('insightHighGain');
        insightBgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
        insightBorderColor = const Color(0xFF10B981).withValues(alpha: 0.3);
      } else if (declinePct >= 50) {
        insightText = context.tr('insightCaution');
        insightBgColor = AppColors.error.withValues(alpha: 0.12);
        insightBorderColor = AppColors.error.withValues(alpha: 0.3);
      } else {
        insightText = context.tr('insightBalanced');
        insightBgColor = Colors.blue.withValues(alpha: 0.12);
        insightBorderColor = Colors.blue.withValues(alpha: 0.3);
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: (isStaticOrStale ? Colors.amber.shade600 : const Color(0xFF10B981)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(isStaticOrStale ? '⏸️' : '📊', style: const TextStyle(fontSize: 16)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    titleText,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Multi-color Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: SizedBox(
              height: 12.h,
              child: Row(
                children: [
                  if (gainFlex > 0)
                    Expanded(
                      flex: gainFlex,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (stableFlex > 0)
                    Expanded(
                      flex: stableFlex,
                      child: Container(color: Colors.amber.shade600),
                    ),
                  if (declineFlex > 0)
                    Expanded(
                      flex: declineFlex,
                      child: Container(color: AppColors.error),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Numerical Breakdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gained
              if (gainedCount > 0 || !isStaticOrStale)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '📈 ${context.tr('gainLabel')}: $gainedCount (${gainPct.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            color: const Color(0xFF10B981),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Declined
              if (declinedCount > 0 || !isStaticOrStale)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '📉 ${context.tr('declineLabel')}: $declinedCount (${declinePct.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Stable
              if (stableCount > 0 || isStaticOrStale)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber.shade600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '⚪ ${context.tr('stableLabel')}: $stableCount (${stablePct.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            color: Colors.amber.shade600,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),

          // Dynamic Smart Insight Container
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: insightBgColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: insightBorderColor,
              ),
            ),
            child: Text(
              insightText,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
