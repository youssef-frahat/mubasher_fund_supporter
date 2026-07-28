import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/routing/routes.dart';
import '../../../home/data/models/platform_feature.dart';
import '../../../portfolio/data/repositories/portfolio_repository.dart';
import '../../data/models/risk_profile_model.dart';

class SponsoredRecommendationCard extends StatefulWidget {
  final RiskAssessmentResult riskResult;
  final double totalAmount;

  const SponsoredRecommendationCard({
    super.key,
    required this.riskResult,
    required this.totalAmount,
  });

  @override
  State<SponsoredRecommendationCard> createState() => _SponsoredRecommendationCardState();
}

class _SponsoredRecommendationCardState extends State<SponsoredRecommendationCard> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);
    final isAr = context.isArabic;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBg,
        gradient: AppColors.getCardGradient(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badges (flex-wrapped)
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.robot, color: AppColors.primary, size: 13.r),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        isAr
                            ? 'المستشار الذكي: ${widget.riskResult.getRiskCategory(isAr)}'
                            : 'Robo-Advisor: ${widget.riskResult.getRiskCategory(isAr)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  isAr
                      ? 'متوسط العائد: ${widget.riskResult.expectedRoiPercentage}% سنويًا'
                      : 'Avg Return: ${widget.riskResult.expectedRoiPercentage}% p.a.',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          Text(
            isAr
                ? '🤖 المحفظة الاستثمارية الموصى بها:'
                : '🤖 Recommended Investment Portfolio:',
            style: TextStyle(
              color: textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            widget.riskResult.getDescription(isAr),
            style: TextStyle(
              color: textSecondary,
              fontSize: 11.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),

          // Stacked Horizontal Percentage Allocation Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: SizedBox(
              height: 10.h,
              child: Row(
                children: widget.riskResult.recommendedPortfolioMix.map((alloc) {
                  return Expanded(
                    flex: alloc.percentage.toInt(),
                    child: Container(color: alloc.categoryColor),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // List of Allocated Funds with EGP Splits (Clickable to open FundDetailsScreen)
          ...widget.riskResult.recommendedPortfolioMix.map((alloc) {
            final allocatedEgp = alloc.getAllocatedAmount(widget.totalAmount);
            final platformFeature = PlatformFeature(
              id: alloc.fundName.replaceAll(' ', '-').toLowerCase(),
              title: alloc.fundName,
              subtitle: '${alloc.getCategoryName(isAr)} • ${alloc.getBadgeLabel(isAr)}',
              icon: Icons.account_balance,
              accentColor: alloc.categoryColor,
            );

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              child: InkWell(
                onTap: () {
                  context.push(Routes.fundDetails, extra: platformFeature);
                },
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18.r,
                        backgroundColor: alloc.categoryColor.withValues(alpha: 0.2),
                        child: Text(
                          '${alloc.percentage.toInt()}%',
                          style: TextStyle(
                            color: alloc.categoryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alloc.fundName,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${alloc.getCategoryName(isAr)} • ${alloc.getBadgeLabel(isAr)}',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 10.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${allocatedEgp.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}',
                            style: TextStyle(
                              color: alloc.categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr('details'),
                                style: TextStyle(color: textSecondary, fontSize: 9.sp),
                              ),
                              Icon(Icons.chevron_right, size: 12.r, color: textSecondary),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          SizedBox(height: 14.h),

          // Action Button - Save Portfolio to Simulation Page
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final router = GoRouter.of(context);
                      final isArabic = context.isArabic;

                      setState(() => _isSaving = true);
                      try {
                        final repo = PortfolioRepository();
                        final portfolioName = isArabic
                            ? 'محفظة المستشار (${widget.riskResult.riskCategory})'
                            : 'Advisor Portfolio (${widget.riskResult.riskCategory})';
                        final createdPortfolio = await repo.createPortfolioFromRecommendedMix(
                          name: portfolioName,
                          riskResult: widget.riskResult,
                          totalAmount: widget.totalAmount,
                        );

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? 'تم حفظ محفظة "${createdPortfolio.name}" بنجاح في صفحة المحافظ! 🚀'
                                  : 'Portfolio "${createdPortfolio.name}" saved successfully! 🚀',
                            ),
                            backgroundColor: AppColors.primary,
                            action: SnackBarAction(
                              label: isArabic ? 'عرض المحفظة' : 'View Portfolio',
                              textColor: Colors.black,
                              onPressed: () => router.go(Routes.portfolio),
                            ),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr ? 'خطأ في حفظ المحفظة: $e' : 'Error saving portfolio: $e',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              icon: _isSaving
                  ? SizedBox(
                      width: 14.r,
                      height: 14.r,
                      child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const FaIcon(FontAwesomeIcons.circlePlus, color: Colors.black, size: 14),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isSaving
                      ? (isAr ? 'جاري الحفظ في حسابك...' : 'Saving portfolio...')
                      : (isAr
                          ? 'حفظ وتطبيق هذه المحفظة في صفحة المحافظ'
                          : 'Save & Apply Portfolio to My Portfolio'),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
