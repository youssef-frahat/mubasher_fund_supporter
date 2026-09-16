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
import '../../../home/data/sources/official_egyptian_funds_data.dart';
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

    final resolvedFund = fundModel ??
        OfficialEgyptianFundsData.allFunds.firstWhere(
          (f) => f.id == fund.id || f.name == fund.title || (f.nameEn != null && f.nameEn == fund.title),
          orElse: () => FundModel(
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
        );

    final isAr = context.isArabic;
    final displayTitle = resolvedFund.localizedName(context);

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
          displayTitle,
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
              final fundId = resolvedFund.id;
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
                      isAr ? 'تمت إضافة "$displayTitle" للمفضلة ⭐️' : 'Added "$displayTitle" to favorites ⭐️',
                    );
                  } else {
                    AppSnackBar.showInfo(
                      context,
                      isAr ? 'تم إزالة "$displayTitle" من المفضلة' : 'Removed "$displayTitle" from favorites',
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
            // 1. Shariah Compliance Prominent Status Card
            _buildShariahStatusCard(context, resolvedFund, surface, border),
            SizedBox(height: 14.h),

            // 2. Fund Header Card with NAV Date & Category
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
                              displayTitle,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    resolvedFund.localizedCategory(context),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    resolvedFund.managerName,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 11.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Divider(color: border),
                  SizedBox(height: 8.h),

                  // NAV Last Updated Date Badge & Return
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
                          '${context.tr('expectedYield')}: ${resolvedFund.ytdReturn.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),

            // 3. Interactive NAV Chart
            NavChartWidget(fund: resolvedFund),
            SizedBox(height: 20.h),

            // 4. Institutional Deep Details Card (Bank, Inception, Custodian, Auditor)
            _buildInstitutionalCard(context, resolvedFund, surface, border, textPrimary, textSecondary),
            SizedBox(height: 24.h),

            // 5. Simulation Investment Action Button
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
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildShariahStatusCard(BuildContext context, FundModel fund, Color surface, Color border) {
    final isShariah = fund.isShariahCompliant;
    final isAr = context.isArabic;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isShariah ? const Color(0xFF06331E) : surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isShariah ? const Color(0xFF10B981).withValues(alpha: 0.5) : border,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isShariah ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.blueGrey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isShariah ? Icons.nightlight_round : Icons.account_balance_outlined,
              color: isShariah ? const Color(0xFF34D399) : Colors.blueGrey,
              size: 22.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isShariah ? context.tr('shariahCompliant') : context.tr('conventionalFund'),
                      style: TextStyle(
                        color: isShariah ? const Color(0xFF34D399) : AppColors.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      isShariah ? Icons.check_circle : Icons.info_outline,
                      size: 14.r,
                      color: isShariah ? const Color(0xFF34D399) : Colors.grey,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  isShariah
                      ? (fund.shariahBoard ?? context.tr('shariahSupervisoryBoardSub'))
                      : (isAr ? 'خاضع لتعليمات ومعايير الهيئة العامة للرقابة المالية (FRA)' : 'Regulated by Financial Regulatory Authority (FRA) standards'),
                  style: TextStyle(
                    color: isShariah ? const Color(0xFFA7F3D0) : AppColors.getTextSecondary(context),
                    fontSize: 10.5.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionalCard(
    BuildContext context,
    FundModel fund,
    Color surface,
    Color border,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: AppColors.primary, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                context.tr('institutionalDetails'),
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(color: border, height: 1),
          SizedBox(height: 10.h),

          // 1. Issuing Entity
          _buildInfoRow(
            icon: Icons.domain_rounded,
            label: context.tr('foundingEntity'),
            value: fund.localizedIssuingEntity(context),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // 2. Inception Year
          _buildInfoRow(
            icon: Icons.calendar_month_outlined,
            label: context.tr('inceptionYearLabel'),
            value: fund.inceptionYear != null ? '${fund.inceptionYear}' : '1995',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // 3. Fund Manager
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: context.tr('fundManagerLabel'),
            value: fund.managerName,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // 4. Custodian Bank
          _buildInfoRow(
            icon: Icons.shield_outlined,
            label: context.tr('custodianLabel'),
            value: fund.localizedCustodian(context),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // 5. Fund Administration
          _buildInfoRow(
            icon: Icons.storefront_outlined,
            label: context.tr('fundAdminLabel'),
            value: fund.fundAdministrator ?? 'فروع البنك وتطبيق مباشر كابيتال',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // 6. Independent Auditor
          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            label: context.tr('independentAuditor'),
            value: fund.auditor ?? 'حازم حسن (KPMG) ومراقبون مستقلون',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // 7. Trading Currency
          _buildInfoRow(
            icon: Icons.monetization_on_outlined,
            label: context.tr('nominalCurrency'),
            value: fund.currency == 'USD' ? 'دولار أمريكي (USD)' : 'الجنيه المصري (EGP)',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // 8. Valuation Frequency
          _buildInfoRow(
            icon: Icons.update_rounded,
            label: context.tr('tradingFrequency'),
            value: context.tr('dailyValuation'),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // 9. Dividend Policy
          _buildInfoRow(
            icon: Icons.pie_chart_outline,
            label: context.tr('dividendPolicyLabel'),
            value: fund.dividendPolicy ?? 'إعادة استثمار العوائد تلقائياً (Growth)',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.r, color: textSecondary),
          SizedBox(width: 8.w),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 11.sp),
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
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
                        context.isArabic
                            ? 'يرجى إدخال عدد وثائق وسعر شراء صحيح أكبر من صفر'
                            : 'Please enter valid units and purchase price greater than zero',
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
