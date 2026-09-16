import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../domain/models/fund_sort_option.dart';
import 'fund_sort_bottom_sheet.dart';

class FundSortBar extends StatelessWidget {
  final FundSortOption currentSort;
  final ValueChanged<FundSortOption> onSortChanged;
  final int totalCount;
  final String? customCountLabel;

  const FundSortBar({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    required this.totalCount,
    this.customCountLabel,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    final isAr = context.isArabic;
    final countText = customCountLabel ?? (isAr ? '$totalCount صندوق' : '$totalCount Funds');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Funds Count Badge
          Row(
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                countText,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Interactive Sort Selector Pill
          InkWell(
            onTap: () {
              FundSortBottomSheet.show(
                context: context,
                currentSort: currentSort,
                onSortSelected: onSortChanged,
              );
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: border, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentSort.icon,
                    size: 15.r,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    currentSort.getLabel(context),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18.r,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
