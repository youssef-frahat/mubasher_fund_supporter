import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/watheqa_top_app_bar.dart';
import '../../../../core/language/language_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/market_movement_insight_card.dart';
import '../widgets/today_opportunity_card.dart';
import '../widgets/top_performing_card.dart';
import '../widgets/recommended_funds_list.dart';
import '../widgets/fund_list_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    return BlocProvider(
      create: (context) => sl<HomeCubit>()..loadData(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: const WatheqaTopAppBar(),
        body: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state is HomeLoaded) {
                final recommendedFirst = state.recommendedFunds.isNotEmpty ? state.recommendedFunds.first : null;
                final rankedFundsPreview = state.rankedFunds.take(3).toList();

                return CustomScrollView(
                  slivers: [
                    // 1. Search Bar Widget at Top of Home Page
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                        child: GestureDetector(
                          onTap: () => context.push(Routes.allFunds),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: FaIcon(FontAwesomeIcons.sliders, color: AppColors.primary, size: 13.r),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    context.tr('searchPlaceholder'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Icon(Icons.search, color: AppColors.primary, size: 20.r),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. Today's AI Opportunity Green Hero Banner (Matching Screenshots)
                    SliverToBoxAdapter(
                      child: TodayOpportunityCard(recommendedFund: recommendedFirst)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.05, end: 0, curve: Curves.easeOutQuart),
                    ),

                    // 3. Top Performing Fund Card Header & Card (Links to Top 10 League)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '🏅 ${context.tr('topPerformingThisMonth')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () => context.push(Routes.top10League),
                                  child: Text(
                                    '${context.tr('seeAll')} 🏆',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TopPerformingCard(fund: state.topPerformingFund)
                              .animate()
                              .fadeIn(delay: 150.ms)
                              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutQuart),
                        ],
                      ),
                    ),

                    // 4. Recommended / Curated Sponsored Funds List with See All (Links to Sponsored Funds Screen)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 6.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '⭐️ ${context.tr('selectedFundsForYou')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () => context.push(Routes.sponsoredFunds),
                                  child: Text(
                                    '${context.tr('seeAll')} ⭐',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RecommendedFundsList(funds: state.recommendedFunds)
                              .animate()
                              .fadeIn(delay: 250.ms)
                              .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
                        ],
                      ),
                    ),

                    // 5. All Funds Preview Section (Limited to 3 Items + See All Button to AllFundsScreen)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '📋 ${context.tr('allFunds')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () => context.push(Routes.allFunds),
                              child: Text(
                                '${context.tr('seeAll')} 📋',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      sliver: SliverList.builder(
                        itemCount: rankedFundsPreview.length,
                        itemBuilder: (context, index) {
                          return FundListTile(
                            fund: rankedFundsPreview[index],
                            rank: index + 1,
                          ).animate().fadeIn(delay: (200 + (50 * index)).ms).slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutQuart);
                        },
                      ),
                    ),

                    // 6. Final Crown Jewel: Daily Funds Market Movement Card (CardView ختام الهوم)
                    SliverToBoxAdapter(
                      child: MarketMovementInsightCard(funds: state.rankedFunds)
                          .animate()
                          .fadeIn(delay: 350.ms)
                          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 30.h)),
                  ],
                );
              }
              return AppLoadingIndicator(message: context.tr('loadingFundsData'));
            },
          ),
        ),
      ),
    );
  }
}
