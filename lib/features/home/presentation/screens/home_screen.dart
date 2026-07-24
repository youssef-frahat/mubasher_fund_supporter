import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../../../core/localization/app_strings.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/feature_card.dart';

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
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                      sliver: SliverGrid.builder(
                        itemCount: state.features.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16.h,
                          crossAxisSpacing: 16.w,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final feature = state.features[index];
                          return FeatureCard(feature: feature);
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 32.h),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.r),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primaryContainer,
                                Theme.of(context).colorScheme.secondaryContainer,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.phase1Delivered.tr(),
                                style: FontStyles.titleMedium,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                AppStrings.phase1Description.tr(),
                                style: FontStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
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
