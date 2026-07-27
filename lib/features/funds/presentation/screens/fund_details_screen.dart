import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../home/data/models/platform_feature.dart';
import '../../../home/data/models/fund_model.dart';
import '../../../portfolio/data/models/portfolio_item_model.dart';
import '../../../portfolio/presentation/cubit/portfolio_cubit.dart';
import '../widgets/nav_chart_widget.dart';

class FundDetailsScreen extends StatelessWidget {
  final PlatformFeature fund;
  final FundModel? fundModel;

  const FundDetailsScreen({super.key, required this.fund, this.fundModel});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          fund.title,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: sl<WishlistService>().savedFundIds,
            builder: (context, savedIds, _) {
              final fundId = fund.id ?? '';
              final isSaved = savedIds.contains(fundId);
              return IconButton(
                tooltip: context.tr('addToWishlist'),
                icon: FaIcon(
                  isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                  color: isSaved ? AppColors.gold : textPrimary,
                  size: 18.r,
                ),
                onPressed: () async {
                  final added = await sl<WishlistService>().toggleWishlist(fundId);
                  if (!context.mounted) return;
                  if (added) {
                    AppSnackBar.showSuccess(
                      context,
                      'تمت إضافة "${fund.title}" للمفضلة ⭐️',
                    );
                  } else {
                    AppSnackBar.showInfo(
                      context,
                      'تم إزالة "${fund.title}" من المفضلة',
                    );
                  }
                },
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fund Header Card with NAV Date Badge
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: surface,
                gradient: AppColors.getCardGradient(context),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: fund.accentColor.withValues(alpha: 0.18),
                        radius: 26.r,
                        child: Icon(fund.icon, color: fund.accentColor, size: 24.r),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fund.title,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              fund.subtitle,
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
                  SizedBox(height: 14.h),
                  Divider(color: border),
                  SizedBox(height: 8.h),

                  // NAV Last Updated Date Badge
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.clock, color: AppColors.primary, size: 12.r),
                            SizedBox(width: 6.w),
                            Text(
                              context.tr('lastNavUpdate'),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          context.tr('expectedAnnualReturn'),
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // NAV Chart — real data or fallback mock
            NavChartWidget(
              fund: fundModel ?? FundModel(
                id: fund.id ?? 'unknown',
                name: fund.title,
                managerName: fund.subtitle.split('|').first.trim(),
                currentNav: 135.0,
                ytdReturn: 24.5,
                weeklyReturn: 0.48,
                fourWeeksReturn: 1.9,
                last12mReturn: 22.8,
                dailyChange: 0.07,
                riskLevel: 'Low',
                category: 'MoneyMarket',
                initialValue: 100.0,
              ),
            ),
            SizedBox(height: 24.h),

            // Simulation Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: () => _showAddTransactionDialog(context, fund),
                icon: const FaIcon(FontAwesomeIcons.circlePlus, color: Colors.black, size: 16),
                label: Text(
                  context.tr('addToPortfolioBtn'),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, PlatformFeature fund) {
    final unitsController = TextEditingController(text: '10');
    final priceController = TextEditingController(text: '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final surface = AppColors.getSurface(context);
        final textPrimary = AppColors.getTextPrimary(context);
        final textSecondary = AppColors.getTextSecondary(context);

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            left: 16.w,
            right: 16.w,
            top: 20.h,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${context.tr('newTransactionTitle')} ${fund.title}',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              TextFormField(
                controller: unitsController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: context.tr('unitsLabel'),
                  labelStyle: TextStyle(color: textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 12.h),

              TextFormField(
                controller: priceController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: context.tr('purchasePriceEgp'),
                  labelStyle: TextStyle(color: textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  onPressed: () {
                    final units = double.tryParse(unitsController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    if (units > 0 && price > 0) {
                      context.read<PortfolioCubit>().addTransaction(
                        fundName: fund.title,
                        category: FundCategory.moneyMarket,
                        units: units,
                        purchasePrice: price,
                        currentNav: price * 1.06,
                      );
                      Navigator.pop(ctx);
                      AppSnackBar.showSuccess(
                        context,
                        context.tr('dealSavedSuccess'),
                      );
                    } else {
                      AppSnackBar.showWarning(
                        context,
                        'يرجى إدخال عدد وثائق وسعر شراء صحيح أكبر من صفر',
                      );
                    }
                  },
                  child: Text(
                    context.tr('saveDeal'),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
