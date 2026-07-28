import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
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

class _InvestmentCalculatorContent extends StatefulWidget {
  const _InvestmentCalculatorContent();

  @override
  State<_InvestmentCalculatorContent> createState() => _InvestmentCalculatorContentState();
}

class _InvestmentCalculatorContentState extends State<_InvestmentCalculatorContent> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CalculatorCubit>();
    _amountController = TextEditingController(
      text: cubit.selectedAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _syncAmountText(double amount) {
    final newText = amount.toStringAsFixed(0);
    if (_amountController.text != newText) {
      _amountController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isAr ? 'حاسبة ومستشار الاستثمار الذكي' : 'Smart Investment Robo-Advisor',
          style: TextStyle(
            color: textPrimary,
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
                    color: surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: FaIcon(FontAwesomeIcons.calculator, color: AppColors.primary, size: 22.r),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'قارن استثمارك بذكاء' : 'Compare Your Investment Smartly',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              isAr
                                  ? 'حدد هدفك وسنحدد لك الخيار الأفضل عائداً مع المقارنة الفورية بالشهادات البنكية والذهب.'
                                  : 'Select your goal and we will recommend the top yield options compared with bank certs & gold.',
                              style: TextStyle(
                                color: textSecondary,
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

                // Step 3: Investment Amount Input & Slider
                Text(
                  isAr ? '3. ما هو المبلغ المخطط استثماره؟' : '3. Planned Investment Amount',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr
                                ? 'المبلغ الاستثماري (أدخل يدويًا أو عبر الشريط):'
                                : 'Investment Amount (Enter manually or slider):',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Editable Number Keyboard TextField
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48.h,
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.edit_note, color: AppColors.primary, size: 20.r),
                                  suffixText: isAr ? 'ج.م' : 'EGP',
                                  suffixStyle: TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                  filled: true,
                                  fillColor: bg,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                    borderSide: BorderSide(color: border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                                onChanged: (val) {
                                  final doubleVal = double.tryParse(val);
                                  if (doubleVal != null && doubleVal > 0) {
                                    cubit.updateAmount(doubleVal);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // Synchronized Slider
                      Slider(
                        value: cubit.selectedAmount.clamp(10000, 1000000),
                        min: 10000,
                        max: 1000000,
                        divisions: 99,
                        activeColor: AppColors.primary,
                        inactiveColor: border,
                        onChanged: (value) {
                          cubit.updateAmount(value);
                          _syncAmountText(value);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Results Section
                if (calculatedState != null) ...[
                  Text(
                    isAr ? '📊 نتائج وتوصية الاستثمار:' : '📊 Investment Results & Recommendation:',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Sponsored Match Card
                  SponsoredRecommendationCard(
                    riskResult: calculatedState.riskResult,
                    totalAmount: calculatedState.amount,
                  ),
                  SizedBox(height: 16.h),

                  // ROI Comparison Breakdown Cards
                  Text(
                    isAr ? 'مقارنة العائد المتوقع بنهاية المدة:' : 'Expected Return Comparison at Maturity:',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  _buildComparisonTile(
                    context: context,
                    title: isAr
                        ? 'الصندوق الموصى به (${calculatedState.riskResult.expectedRoiPercentage}% سنويًا)'
                        : 'Recommended Fund (${calculatedState.riskResult.expectedRoiPercentage}% p.a.)',
                    amount: calculatedState.fundEstimatedReturn,
                    color: AppColors.primary,
                    icon: FontAwesomeIcons.chartLine,
                    isBestOption: true,
                  ),
                  SizedBox(height: 8.h),
                  _buildComparisonTile(
                    context: context,
                    title: isAr ? 'شهادة بنكية تقليدية (23.5% سنويًا)' : 'Traditional Bank Certificate (23.5% p.a.)',
                    amount: calculatedState.bankCertificateReturn,
                    color: Colors.blueAccent,
                    icon: FontAwesomeIcons.landmark,
                  ),
                  SizedBox(height: 8.h),
                  _buildComparisonTile(
                    context: context,
                    title: isAr ? 'صناديق/أصول الذهب (28% سنوياً متوقع)' : 'Gold Funds / Assets (28% p.a. est.)',
                    amount: calculatedState.goldEstimatedReturn,
                    color: AppColors.gold,
                    icon: FontAwesomeIcons.coins,
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
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
    required dynamic icon,
    bool isBestOption = false,
  }) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);
    final isAr = context.isArabic;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isBestOption ? color.withValues(alpha: 0.12) : surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isBestOption ? color : border,
          width: isBestOption ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: color.withValues(alpha: 0.2),
            child: FaIcon(icon, color: color, size: 16.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12.sp,
                    fontWeight: isBestOption ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isAr ? 'المبلغ الإجمالي المتوقع' : 'Total Expected Amount',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}',
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
