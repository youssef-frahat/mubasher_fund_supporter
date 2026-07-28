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

  const FundListTile({super.key, required this.rank, required this.fund});

  dynamic _getCategoryIcon(String category, String name) {
    final cat = category.toLowerCase();
    final n = name.toLowerCase();

    if (cat.contains('gold') || cat.contains('silver') || cat.contains('metal') || n.contains('ذهب') || n.contains('فضة') || n.contains('معادن')) {
      return FontAwesomeIcons.gem;
    } else if (cat.contains('real') || cat.contains('estate') || cat.contains('property') || n.contains('عقار') || n.contains('عقاري')) {
      return FontAwesomeIcons.building;
    } else if (cat.contains('islamic') || cat.contains('sharia') || n.contains('إسلام') || n.contains('شريعة') || n.contains('وفاق')) {
      return FontAwesomeIcons.kaaba;
    } else if (cat.contains('money') || cat.contains('cash') || n.contains('سيولة') || n.contains('نقدي') || n.contains('يومي') || n.contains('جذور')) {
      return FontAwesomeIcons.moneyBill1Wave;
    } else if (cat.contains('fixed') || cat.contains('treasury') || cat.contains('bill') || n.contains('سند') || n.contains('أذون') || n.contains('خزانة')) {
      return FontAwesomeIcons.landmark;
    }
    return FontAwesomeIcons.chartLine;
  }

  Color _getCategoryColor(String category, String name) {
    final cat = category.toLowerCase();
    final n = name.toLowerCase();

    if (cat.contains('gold') || cat.contains('silver') || cat.contains('metal') || n.contains('ذهب') || n.contains('فضة') || n.contains('معادن')) {
      return const Color(0xFFF59E0B);
    } else if (cat.contains('real') || cat.contains('estate') || cat.contains('property') || n.contains('عقار') || n.contains('عقاري')) {
      return const Color(0xFF0284C7);
    } else if (cat.contains('islamic') || cat.contains('sharia') || n.contains('إسلام') || n.contains('شريعة') || n.contains('وفاق')) {
      return const Color(0xFF059669);
    } else if (cat.contains('money') || cat.contains('cash') || n.contains('سيولة') || n.contains('نقدي') || n.contains('يومي') || n.contains('جذور')) {
      return const Color(0xFF10B981);
    } else if (cat.contains('fixed') || cat.contains('treasury') || cat.contains('bill') || n.contains('سند') || n.contains('أذون') || n.contains('خزانة')) {
      return const Color(0xFF6366F1);
    }
    return const Color(0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context) {
    final wishlistService = sl<WishlistService>();
    final isPositive = fund.ytdReturn >= 0;
    final badgeColor = isPositive ? const Color(0xFF10B981) : AppColors.error;
    final changeText = isPositive ? '▲ +${fund.ytdReturn}%' : '▼ ${fund.ytdReturn}%';

    final categoryIcon = _getCategoryIcon(fund.category, fund.name);
    final categoryColor = _getCategoryColor(fund.category, fund.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nameText = fund.displayNameOnly;
    final abbrText = fund.abbreviation;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: wishlistService.savedFundIds,
      builder: (context, savedIds, _) {
        final isSaved = savedIds.contains(fund.id);

        return GestureDetector(
          onTap: () => context.push(Routes.fundDetails, extra: fund.toPlatformFeature()),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: isSaved
                  ? AppColors.gold.withValues(alpha: 0.08)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSaved
                    ? AppColors.gold.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.outlineVariant,
                width: isSaved ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Spacious Circular Category Avatar (Matching Image 2)
                Container(
                  width: 44.r,
                  height: 44.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    categoryIcon,
                    color: categoryColor,
                    size: 19.r,
                  ),
                ),
                SizedBox(width: 12.w),

                // Organized 3-Line Text Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Line 1: Fund Name & Abbreviation
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nameText,
                              style: FontStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5.sp,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          if (abbrText != null) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                abbrText,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3.h),

                      // Line 2: Manager & Category
                      Text(
                        '${fund.managerName} | ${fund.category}',
                        style: FontStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                      SizedBox(height: 2.h),

                      // Line 3: Structured NAV Price Line
                      Text(
                        'NAV: ${fund.currentNav} ${fund.currency}',
                        style: FontStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),

                // Right Actions Column: Price Badge, Bookmark, Chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Price Movement Badge (Green for Gain ▲, Red for Decline ▼)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        changeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: FaIcon(
                            isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                            size: 15.r,
                            color: isSaved ? AppColors.gold : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.chevron_right,
                          size: 18.r,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
