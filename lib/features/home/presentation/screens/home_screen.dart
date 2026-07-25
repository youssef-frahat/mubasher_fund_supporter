import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../../../core/localization/app_strings.dart';
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
    return BlocProvider(
      create: (context) => sl<HomeCubit>()..loadData(),
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state is HomeLoaded) {
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Icon(Icons.insights, size: 28.sp),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.appName.tr(),
                                        style: FontStyles.headlineSmall,
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        AppStrings.appDescription.tr(),
                                        style: FontStyles.bodyMedium.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            Wrap(
                              spacing: 12.w,
                              runSpacing: 12.h,
                              children: state.metrics
                                  .map(
                                    (metric) => ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: 140.w),
                                      child: Container(
                                        padding: EdgeInsets.all(16.r),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(18.r),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.outlineVariant,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              metric.value,
                                              style: FontStyles.titleLarge,
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              metric.label,
                                              style: FontStyles.bodySmall.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
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

                    // Top Performing Fund
                    SliverToBoxAdapter(
                      child: TopPerformingCard(fund: state.topPerformingFund)
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutQuart),
                    ),

                    // Recommended Funds
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: RecommendedFundsList(funds: state.recommendedFunds)
                            .animate()
                            .fadeIn(delay: 300.ms)
                            .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
                      ),
                    ),

                    // Ranked Funds Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 12.h),
                        child: Text(
                          "Funds Ranked by Yield",
                          style: FontStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Ranked Funds List
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverList.builder(
                        itemCount: state.rankedFunds.length,
                        itemBuilder: (context, index) {
                          return FundListTile(
                            fund: state.rankedFunds[index],
                            rank: index + 1,
                          ).animate().fadeIn(delay: (400 + (100 * index)).ms).slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutQuart);
                        },
                      ),
                    ),
                    
                    // Keep the old features for now if needed, or remove them. 
                    // We'll keep them at the bottom as "Other Features"
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 12.h),
                        child: Text(
                          "Platform Features",
                          style: FontStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverList.builder(
                        itemCount: state.features.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: FeatureCard(feature: state.features[index]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}
