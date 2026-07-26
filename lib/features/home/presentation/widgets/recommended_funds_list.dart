import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_config/app_colors.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../data/models/fund_model.dart';

class RecommendedFundsList extends StatelessWidget {
  final List<FundModel> funds;

  const RecommendedFundsList({super.key, required this.funds});

  @override
  Widget build(BuildContext context) {
    final wishlistService = sl<WishlistService>();

    if (funds.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 22.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'لا توجد صناديق مخصصة في التوصيات حالياً',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                          ValueListenableBuilder<Set<String>>(
                            valueListenable: wishlistService.savedFundIds,
                            builder: (context, savedIds, _) {
                              final isSaved = savedIds.contains(fund.id);
                              return GestureDetector(
                                onTap: () async {
                                  final added = await wishlistService.toggleWishlist(fund.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 2),
                                      content: Text(
                                        added ? 'تمت إضافة "${fund.name}" للمفضلة ⭐️' : 'تم مسح "${fund.name}" من المفضلة',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(4.r),
                                  child: FaIcon(
                                    isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                                    size: 16.r,
                                    color: isSaved ? AppColors.gold : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            },
                          ),
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
