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

  String _getMarketInsight(double gainPct, BuildContext context) {
    if (gainPct >= 60) {
      return context.tr('insightHighGain');
    } else if (gainPct >= 40) {
      return context.tr('insightBalanced');
    } else {
      return context.tr('insightCaution');
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    final total = funds.isNotEmpty ? funds.length : 1;
    final gainedCount = funds.where((f) => f.ytdReturn > 0).length;
    final declinedCount = funds.where((f) => f.ytdReturn < 0).length;
    final stableCount = funds.where((f) => f.ytdReturn == 0).length;

    final gainPct = (gainedCount / total) * 100;
    final declinePct = (declinedCount / total) * 100;
    final stablePct = (stableCount / total) * 100;

    final gainFlex = (gainPct * 10).round().clamp(1, 1000);
    final declineFlex = (declinePct * 10).round().clamp(1, 1000);
    final stableFlex = (stablePct * 10).round().clamp(0, 1000);

    final insightText = _getMarketInsight(gainPct, context);

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
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Text('📊', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    context.tr('marketMovementTitle'),
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
                  Expanded(
                    flex: gainFlex,
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                  if (stableFlex > 0)
                    Expanded(
                      flex: stableFlex,
                      child: Container(color: Colors.amber.shade600),
                    ),
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
              if (stableCount > 0)
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
                            color: textSecondary,
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
              color: gainPct >= 50
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: (gainPct >= 50 ? const Color(0xFF10B981) : AppColors.error).withValues(alpha: 0.3),
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
