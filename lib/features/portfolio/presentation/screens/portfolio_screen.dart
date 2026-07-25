import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/app_config/app_colors.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../../data/models/portfolio_item_model.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/portfolio_health_score_widget.dart';

import '../../../../core/widgets/app_loading_indicator.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PortfolioCubit(
        repository: PortfolioRepository(),
      )..loadPortfolio(),
      child: const _PortfolioContentView(),
    );
  }
}

class _PortfolioContentView extends StatelessWidget {
  const _PortfolioContentView();

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'محفظتي الاستثمارية (المحاكاة)',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const AppLoadingIndicator(message: 'جاري حساب أداء وتحليل المحفظة...');
          } else if (state is PortfolioError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.error),
              ),
            );
          } else if (state is PortfolioLoaded) {
            final health = state.healthSummary;
            final items = state.items;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Portfolio Total Value Header Card
                  _buildTotalValueCard(context, health),
                  SizedBox(height: 16.h),

                  // Health Score Gauge Indicator (Red <50, Yellow 50-85, Green >85)
                  PortfolioHealthScoreWidget(healthSummary: health),
                  SizedBox(height: 24.h),

                  // Holdings Header with Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '💼 أصولي ووثائقي الحالية (${items.length})',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openAddBottomSheet(context),
                        icon: FaIcon(FontAwesomeIcons.circlePlus, color: AppColors.primary, size: 16.r),
                        label: Text(
                          'إضافة صفقة',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // Holdings List
                  if (items.isEmpty)
                    Container(
                      padding: EdgeInsets.all(30.r),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          FaIcon(FontAwesomeIcons.wallet, color: textSecondary, size: 42.r),
                          SizedBox(height: 10.h),
                          Text(
                            'لم تقم بإضافة أي وثيقة في محفظتك حتى الآن.',
                            style: TextStyle(color: textSecondary, fontSize: 13.sp),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isProfit = item.profitLoss >= 0;

                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundColor: item.category.color.withValues(alpha: 0.15),
                                child: Icon(item.category.icon, color: item.category.color, size: 18.r),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.fundName,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '${item.units.toStringAsFixed(0)} وثائق | بسعر ${item.purchasePrice.toStringAsFixed(1)} ج.م',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.currentValue.toStringAsFixed(0)} ج.م',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '${isProfit ? '+' : ''}${item.profitLoss.toStringAsFixed(0)} (${item.profitLossPercentage.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      color: isProfit ? AppColors.success : AppColors.error,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.trashCan, color: AppColors.error, size: 16),
                                onPressed: () {
                                  context.read<PortfolioCubit>().removeTransaction(item.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  SizedBox(height: 30.h),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddBottomSheet(context),
        backgroundColor: AppColors.primary,
        icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.black, size: 14),
        label: const Text(
          'إضافة وثيقة محاكاة',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTotalValueCard(BuildContext context, PortfolioHealthSummary health) {
    final isProfit = health.totalProfitLoss >= 0;
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: AppColors.getCardGradient(context),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجمالي قيمة المحفظة الحالية',
            style: TextStyle(
              color: textSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '${health.totalPortfolioValue.toStringAsFixed(0)} ج.م',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 28.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (isProfit ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      isProfit ? FontAwesomeIcons.arrowTrendUp : FontAwesomeIcons.arrowTrendDown,
                      color: isProfit ? AppColors.success : AppColors.error,
                      size: 14.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${isProfit ? '+' : ''}${health.totalProfitLoss.toStringAsFixed(0)} ج.م (${health.totalProfitLossPercentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: isProfit ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'صافي الأرباح/الخسائر',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddBottomSheet(BuildContext context) {
    final cubit = context.read<PortfolioCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AddTransactionBottomSheet(
          onAdd: ({
            required String fundName,
            required FundCategory category,
            required double units,
            required double purchasePrice,
            required double currentNav,
          }) {
            cubit.addTransaction(
              fundName: fundName,
              category: category,
              units: units,
              purchasePrice: purchasePrice,
              currentNav: currentNav,
            );
          },
        );
      },
    );
  }
}
