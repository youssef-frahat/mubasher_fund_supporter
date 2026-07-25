import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../../../core/routing/routes.dart';
import '../../data/models/fund_model.dart';

class RecommendedFundsList extends StatelessWidget {
  final List<FundModel> funds;

  const RecommendedFundsList({super.key, required this.funds});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            "Recommended For You",
            style: FontStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 140.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: funds.length,
            itemBuilder: (context, index) {
              final fund = funds[index];
              return GestureDetector(
                onTap: () => context.push(Routes.fundDetails, extra: fund.toPlatformFeature()),
                child: Container(
                  width: 240.w,
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              fund.category,
                              style: FontStyles.labelSmall.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        fund.name,
                        style: FontStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${fund.currentNav} EGP",
                            style: FontStyles.bodySmall,
                          ),
                          Text(
                            "+${fund.ytdReturn}%",
                            style: FontStyles.labelMedium.copyWith(
                              color: Colors.greenAccent[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

