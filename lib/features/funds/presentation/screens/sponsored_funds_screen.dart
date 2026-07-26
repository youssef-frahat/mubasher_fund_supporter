import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../../calculator/data/repositories/calculator_repository.dart';
import '../../../home/data/models/fund_model.dart';

class SponsoredFundsScreen extends StatefulWidget {
  const SponsoredFundsScreen({super.key});

  @override
  State<SponsoredFundsScreen> createState() => _SponsoredFundsScreenState();
}

class _SponsoredFundsScreenState extends State<SponsoredFundsScreen> {
  List<FundModel> _sponsoredFunds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSponsoredFunds();
  }

  Future<void> _loadSponsoredFunds() async {
    try {
      final backendFunds = await CalculatorRepository().getSponsoredBackendFunds();
      if (mounted) {
        setState(() {
          _sponsoredFunds = backendFunds;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);
    final wishlistService = sl<WishlistService>();

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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr('sponsoredFundsTitle'),
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadSponsoredFunds,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Robo-Advisor Smart Creation Hero Banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F3822), Color(0xFF072718)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('roboAdvisorBannerTitle'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          context.tr('roboAdvisorBannerDesc'),
                          style: TextStyle(
                            color: const Color(0xFFA7F3D0),
                            fontSize: 11.sp,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              context.go(Routes.portfolio);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                context.tr('createPortfolioNow'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Header Title
                  Text(
                    '⭐ ${context.tr('selectedFundsForYou')}',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // List of Sponsored Funds
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sponsoredFunds.length,
                    itemBuilder: (context, index) {
                      final fund = _sponsoredFunds[index];
                      final nameText = fund.displayNameOnly;
                      final abbrText = fund.abbreviation;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: border),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16.r),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                            leading: Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: const FaIcon(FontAwesomeIcons.star, color: AppColors.gold, size: 18),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    nameText,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (abbrText != null) ...[
                                  SizedBox(height: 1.h),
                                  Text(
                                    '🏷️ $abbrText',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Text(
                                '${fund.managerName} | ${fund.category}',
                                style: TextStyle(color: textSecondary, fontSize: 11.sp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${fund.currentNav} ${fund.currency}',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        '+${fund.ytdReturn}% YTD',
                                        style: TextStyle(
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 6.w),
                                ValueListenableBuilder<Set<String>>(
                                  valueListenable: wishlistService.savedFundIds,
                                  builder: (context, savedIds, _) {
                                    final isSaved = savedIds.contains(fund.id);
                                    return IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: FaIcon(
                                        isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                                        size: 15.r,
                                        color: isSaved ? AppColors.gold : textSecondary.withValues(alpha: 0.5),
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
                            onTap: () {
                              context.push(Routes.fundDetails, extra: fund.toPlatformFeature());
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
    );
  }
}
