import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/app_colors.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. ما هو هدفك الأساسي من الاستثمار؟',
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
              label: '🛡️ أمان وحفظ رأس المال',
            ),
            _buildGoalChip(
              context: context,
              goal: InvestmentGoal.balancedGrowth,
              label: '⚖️ نمو متوازن بعائد ممتاز',
            ),
            _buildGoalChip(
              context: context,
              goal: InvestmentGoal.highYield,
              label: '🚀 أقصى نمو وأرباح (أسهم)',
            ),
            _buildGoalChip(
              context: context,
              goal: InvestmentGoal.islamicSharia,
              label: '🌙 استثمار إسلامي 100%',
            ),
            _buildGoalChip(
              context: context,
              goal: InvestmentGoal.goldHedging,
              label: '🥇 تحوط وحماية ضد التضخم (ذهب)',
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Text(
          '2. ما هي المدة الزمنية المخططة للاستثمار؟',
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
                title: 'قصيرة الأجل',
                subtitle: 'أقل من سنة',
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildDurationCard(
                context: context,
                duration: InvestmentDuration.mediumTerm,
                title: 'متوسطة الأجل',
                subtitle: '1 - 3 سنوات',
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildDurationCard(
                context: context,
                duration: InvestmentDuration.longTerm,
                title: 'طويلة الأجل',
                subtitle: 'أكثر من 3 سنوات',
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
