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

class FundListTile extends StatelessWidget {
  final FundModel fund;
  final int rank;

  const FundListTile({super.key, required this.fund, required this.rank});

  @override
  Widget build(BuildContext context) {
    final wishlistService = sl<WishlistService>();

    return GestureDetector(
      onTap: () => context.push(Routes.fundDetails, extra: fund.toPlatformFeature()),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.r),
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
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
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
            SizedBox(width: 12.w),
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
            SizedBox(width: 8.w),
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
                    color: Colors.greenAccent[400]!.withValues(alpha: 0.1),
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
            SizedBox(width: 4.w),
            // Bookmark Toggle Button
            ValueListenableBuilder<Set<String>>(
              valueListenable: wishlistService.savedFundIds,
              builder: (context, savedIds, _) {
                final isSaved = savedIds.contains(fund.id);
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: FaIcon(
                    isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                    size: 16.r,
                    color: isSaved ? AppColors.gold : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  onPressed: () async {
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
