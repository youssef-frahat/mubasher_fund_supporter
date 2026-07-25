import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../data/repositories/calculator_repository.dart';
import '../cubit/calculator_cubit.dart';
import '../cubit/calculator_state.dart';
import '../widgets/quiz_step_widget.dart';
import '../widgets/sponsored_recommendation_card.dart';

class InvestmentCalculatorScreen extends StatelessWidget {
  const InvestmentCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CalculatorCubit(
        repository: CalculatorRepository(),
      )..calculate(),
      child: const _InvestmentCalculatorContent(),
    );
  }
}

class _InvestmentCalculatorContent extends StatelessWidget {
  const _InvestmentCalculatorContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'حاسبة ومستشار الاستثمار الذكي',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: BlocBuilder<CalculatorCubit, CalculatorState>(
        builder: (context, state) {
          final cubit = context.read<CalculatorCubit>();

          if (state is CalculatorCalculating && state is! CalculatorCalculated) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final calculatedState = state is CalculatorCalculated ? state : null;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Icon(Icons.calculate, color: AppColors.primary, size: 28.r),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'قارن استثمارك بذكاء',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'حدد هدفك وسنحدد لك الخيار الأفضل عائداً مع المقارنة الفورية بالشهادات البنكية والذهب.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Step 1 & 2: Quiz Assessment
                QuizStepWidget(
                  selectedGoal: cubit.selectedGoal,
                  selectedDuration: cubit.selectedDuration,
                  onGoalChanged: (goal) => cubit.updateGoal(goal),
                  onDurationChanged: (duration) => cubit.updateDuration(duration),
                ),
                SizedBox(height: 20.h),

                // Step 3: Investment Amount Slider
                Text(
                  '3. ما هو المبلغ المخطط استثماره؟',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المبلغ الاستثماري:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.sp,
                            ),
                          ),
                          Text(
                            '${cubit.selectedAmount.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: cubit.selectedAmount,
                        min: 10000,
                        max: 1000000,
                        divisions: 99,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.border,
                        onChanged: (value) => cubit.updateAmount(value),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Results Section
                if (calculatedState != null) ...[
                  Text(
                    '📊 نتائج وتوصية الاستثمار:',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Sponsored Match Card
                  SponsoredRecommendationCard(
                    riskResult: calculatedState.riskResult,
                    sponsoredFund: calculatedState.sponsoredFund,
                  ),
                  SizedBox(height: 16.h),

                  // ROI Comparison Breakdown Cards
                  Text(
                    'مقارنة العائد المتوقع بنهاية المدة:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  _buildComparisonTile(
                    title: 'الصندوق الموصى به (${calculatedState.riskResult.expectedRoiPercentage}% سنويًا)',
                    amount: calculatedState.fundEstimatedReturn,
                    color: AppColors.primary,
                    icon: Icons.trending_up,
                    isBestOption: true,
                  ),
                  SizedBox(height: 8.h),
                  _buildComparisonTile(
                    title: 'شهادة بنكية تقليدية (23.5% سنويًا)',
                    amount: calculatedState.bankCertificateReturn,
                    color: Colors.blueAccent,
                    icon: Icons.account_balance,
                  ),
                  SizedBox(height: 8.h),
                  _buildComparisonTile(
                    title: 'صناديق/أصول الذهب (28% سنويًا متوقع)',
                    amount: calculatedState.goldEstimatedReturn,
                    color: AppColors.gold,
                    icon: Icons.workspace_premium,
                  ),
                ],
                SizedBox(height: 30.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonTile({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    bool isBestOption = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isBestOption ? color.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isBestOption ? color : AppColors.border,
          width: isBestOption ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: isBestOption ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'المبلغ الإجمالي المتوقع',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} ج.م',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
            ),
          ),
        ],
      ),
    );
  }
}
