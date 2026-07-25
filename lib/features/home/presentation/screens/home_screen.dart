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
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/feature_card.dart';
import '../widgets/ai_insight_banner.dart';
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
                return CustomScrollView(
                  slivers: [
                    // Search Bar Widget at Top of Home Page
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
                                Icon(Icons.search, color: AppColors.primary, size: 20.r),
                                SizedBox(width: 10.w),
                                Text(
                                  'ابحث في دليل الصناديق، البنوك، الذهب والأذون...',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: FaIcon(FontAwesomeIcons.sliders, color: AppColors.primary, size: 12.r),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top Stats Metrics Row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
                        child: Wrap(
                          spacing: 10.w,
                          runSpacing: 10.h,
                          children: state.metrics
                              .map(
                                (metric) => ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: 140.w),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                                    decoration: BoxDecoration(
                                      color: surface,
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(color: border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          metric.value,
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          metric.label,
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),

                    // AI Insight Banner
                    SliverToBoxAdapter(
                      child: AiInsightBanner(insight: state.aiInsight)
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
                    ),

                    // Top Performing Fund Card
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '🥇 الصندوق الأعلى أداءً هذا الشهر',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push(Routes.allFunds),
                                  child: Text(
                                    'عرض الكل ➔',
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
                              .fadeIn(delay: 200.ms)
                              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutQuart),
                        ],
                      ),
                    ),

                    // Recommended Funds List with See All
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 6.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '💡 صناديق استثمارية مختارة لك',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push(Routes.allFunds),
                                  child: Text(
                                    'عرض الكل ➔',
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
                              .fadeIn(delay: 300.ms)
                              .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
                        ],
                      ),
                    ),

                    // Ranked Funds Header with See All
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '🏆 ترتيب الصناديق الأعلى عائداً سنويًا',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push(Routes.allFunds),
                              child: Text(
                                'عرض الكل ➔',
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

                    // Ranked Funds List
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      sliver: SliverList.builder(
                        itemCount: state.rankedFunds.length,
                        itemBuilder: (context, index) {
                          return FundListTile(
                            fund: state.rankedFunds[index],
                            rank: index + 1,
                          ).animate().fadeIn(delay: (300 + (80 * index)).ms).slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutQuart);
                        },
                      ),
                    ),

                    // Platform Features Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 10.h),
                        child: Text(
                          '⚡ أدوات ومنظومة وثيقة الذكية',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverList.builder(
                        itemCount: state.features.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: FeatureCard(feature: state.features[index]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return const AppLoadingIndicator(message: 'جاري جلب أحدث بيانات الصناديق المصرية...');
            },
          ),
        ),
      ),
    );
  }
}
