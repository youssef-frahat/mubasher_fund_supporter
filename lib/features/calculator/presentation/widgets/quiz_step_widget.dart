import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../data/models/risk_profile_model.dart';

class QuizStepWidget extends StatelessWidget {
  final InvestmentGoal selectedGoal;
  final InvestmentDuration selectedDuration;
  final ValueChanged<InvestmentGoal> onGoalChanged;
  final ValueChanged<InvestmentDuration> onDurationChanged;

  const QuizStepWidget({
    super.key,
    required this.selectedGoal,
    required this.selectedDuration,
    required this.onGoalChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final isAr = context.isArabic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? '1. ما هو هدفك الأساسي من الاستثمار؟' : '1. What is your primary investment goal?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildGoalChip(
              context: context,
              goal: InvestmentGoal.capitalPreservation,
              label: isAr ? '🛡️ أمان وحفظ رأس المال' : '🛡️ Safety & Capital Preservation',
            ),
            _buildGoalChip(
              context: context,
              goal: InvestmentGoal.balancedGrowth,
              label: isAr ? '⚖️ نمو متوازن بعائد ممتاز' : '⚖️ Balanced Growth',
            ),
            _buildGoalChip(
              context: context,
              goal: InvestmentGoal.highYield,
              label: isAr ? '🚀 أقصى نمو وأرباح (أسهم)' : '🚀 Max Growth & Profit (Equity)',
            ),
            _buildGoalChip(
              context: context,
              goal: InvestmentGoal.islamicSharia,
              label: isAr ? '🌙 استثمار إسلامي 100%' : '🌙 100% Islamic Investment',
            ),
            _buildGoalChip(
              context: context,
              goal: InvestmentGoal.goldHedging,
              label: isAr ? '🥇 تحوط وحماية ضد التضخم (ذهب)' : '🥇 Inflation Hedge (Gold)',
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Text(
          isAr ? '2. ما هي المدة الزمنية المخططة للاستثمار؟' : '2. What is your planned investment horizon?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildDurationCard(
                context: context,
                duration: InvestmentDuration.shortTerm,
                title: isAr ? 'قصيرة الأجل' : 'Short-Term',
                subtitle: isAr ? 'أقل من سنة' : '< 1 year',
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildDurationCard(
                context: context,
                duration: InvestmentDuration.mediumTerm,
                title: isAr ? 'متوسطة الأجل' : 'Medium-Term',
                subtitle: isAr ? '1 - 3 سنوات' : '1 - 3 years',
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildDurationCard(
                context: context,
                duration: InvestmentDuration.longTerm,
                title: isAr ? 'طويلة الأجل' : 'Long-Term',
                subtitle: isAr ? 'أكثر من 3 سنوات' : '> 3 years',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalChip({
    required BuildContext context,
    required InvestmentGoal goal,
    required String label,
  }) {
    final isSelected = selectedGoal == goal;
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final border = AppColors.getBorder(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onGoalChanged(goal),
      selectedColor: AppColors.primary,
      backgroundColor: surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13.sp,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : border,
      ),
    );
  }

  Widget _buildDurationCard({
    required BuildContext context,
    required InvestmentDuration duration,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedDuration == duration;
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    return GestureDetector(
      onTap: () => onDurationChanged(duration),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
