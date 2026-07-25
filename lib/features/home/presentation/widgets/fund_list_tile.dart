import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../data/models/fund_model.dart';

class FundListTile extends StatelessWidget {
  final FundModel fund;
  final int rank;

  const FundListTile({super.key, required this.fund, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              "$rank",
              style: FontStyles.labelLarge.copyWith(
                color: rank <= 3 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fund.name,
                  style: FontStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  fund.category,
                  style: FontStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${fund.currentNav} EGP",
                style: FontStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.greenAccent[400]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  "+${fund.ytdReturn}%",
                  style: FontStyles.labelSmall.copyWith(
                    color: Colors.greenAccent[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
