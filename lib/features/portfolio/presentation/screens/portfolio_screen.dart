import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../../data/models/portfolio_item_model.dart';
import '../../data/models/portfolio_model.dart';
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
          context.tr('portfolio'),
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
            final activePortfolio = state.activePortfolio;
            final allPortfolios = state.allPortfolios;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Portfolio Switcher Pill Bar
                  GestureDetector(
                    onTap: () => _openPortfolioSwitcherSheet(context, allPortfolios, activePortfolio),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.briefcase, color: AppColors.primary, size: 16.r),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('activePortfolio'),
                                  style: TextStyle(color: textSecondary, fontSize: 10.sp),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  activePortfolio.name,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'تبديل (${allPortfolios.length})',
                                  style: TextStyle(color: AppColors.primary, fontSize: 11.sp, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 4.w),
                                Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 16.r),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Portfolio Total Value Header Card
                  _buildTotalValueCard(context, health),
                  SizedBox(height: 16.h),

                  // Health Score Gauge Indicator
                  PortfolioHealthScoreWidget(healthSummary: health),
                  SizedBox(height: 20.h),

                  // Holdings Header with Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '💼 وثائق ${activePortfolio.name} (${items.length})',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      TextButton.icon(
                        onPressed: () => _openAddBottomSheet(context),
                        icon: FaIcon(FontAwesomeIcons.circlePlus, color: AppColors.primary, size: 15.r),
                        label: Text(
                          context.tr('addTransaction'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Holdings List
                  if (items.isEmpty)
                    Container(
                      padding: EdgeInsets.all(24.r),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          FaIcon(FontAwesomeIcons.wallet, color: textSecondary, size: 36.r),
                          SizedBox(height: 10.h),
                          Text(
                            'هذه المحفظة خالية، يمكنك إضافة وثائق إليها الآن.',
                            style: TextStyle(color: textSecondary, fontSize: 12.sp),
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
                          margin: EdgeInsets.only(bottom: 10.h),
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18.r,
                                backgroundColor: item.category.color.withValues(alpha: 0.15),
                                child: Icon(item.category.icon, color: item.category.color, size: 16.r),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.fundName,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '${item.units.toStringAsFixed(0)} وثائق | بسعر ${item.purchasePrice.toStringAsFixed(1)} ج.م',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 10.sp,
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
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '${isProfit ? '+' : ''}${item.profitLoss.toStringAsFixed(0)} (${item.profitLossPercentage.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      color: isProfit ? AppColors.success : AppColors.error,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: context.tr('editUnits'),
                                    icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Color(0xFF3B82F6), size: 15),
                                    onPressed: () => _showEditUnitsDialog(context, item),
                                  ),
                                  IconButton(
                                    tooltip: context.tr('delete'),
                                    icon: const FaIcon(FontAwesomeIcons.trashCan, color: AppColors.error, size: 15),
                                    onPressed: () {
                                      context.read<PortfolioCubit>().removeTransaction(item.id);
                                      AppSnackBar.showInfo(context, 'تم حذف الصفقة من المحفظة');
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  SizedBox(height: 40.h),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePortfolioDialog(context),
        backgroundColor: AppColors.primary,
        icon: const FaIcon(FontAwesomeIcons.folderPlus, color: Colors.black, size: 15),
        label: Text(
          context.tr('addPortfolio'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: AppColors.getCardGradient(context),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('totalValue'),
            style: TextStyle(
              color: textSecondary,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${health.totalPortfolioValue.toStringAsFixed(0)} ج.م',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 26.sp,
            ),
          ),
          SizedBox(height: 8.h),
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
                      size: 13.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${isProfit ? '+' : ''}${health.totalProfitLoss.toStringAsFixed(0)} ج.م (${health.totalProfitLossPercentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: isProfit ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                context.tr('profitLoss'),
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

  void _openPortfolioSwitcherSheet(
    BuildContext context,
    List<PortfolioModel> portfolios,
    PortfolioModel activePortfolio,
  ) {
    final cubit = context.read<PortfolioCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final surface = AppColors.getSurface(context);
        final textPrimary = AppColors.getTextPrimary(context);
        final textSecondary = AppColors.getTextSecondary(context);
        final border = AppColors.getBorder(context);

        return Container(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📁 منافذ المحافظ الاستثمارية الخاصّة بك',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              ListView.builder(
                shrinkWrap: true,
                itemCount: portfolios.length,
                itemBuilder: (context, index) {
                  final p = portfolios[index];
                  final isActive = p.id == activePortfolio.id;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Material(
                      color: isActive ? AppColors.primary.withValues(alpha: 0.12) : surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(
                          color: isActive ? AppColors.primary : border,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        tileColor: Colors.transparent,
                        leading: FaIcon(
                          FontAwesomeIcons.briefcase,
                          color: isActive ? AppColors.primary : textSecondary,
                          size: 18.r,
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13.sp,
                          ),
                        ),
                        subtitle: Text(
                          '(${p.items.length}) صناديق مضافة',
                          style: TextStyle(color: textSecondary, fontSize: 11.sp),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: const Text(
                                  'نشطة الان',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                            if (portfolios.length > 1)
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.trashCan, color: AppColors.error, size: 14),
                                onPressed: () {
                                  cubit.deletePortfolio(p.id);
                                  Navigator.pop(ctx);
                                  AppSnackBar.showInfo(context, 'تم حذف المحفظة بنجاح');
                                },
                              ),
                          ],
                        ),
                        onTap: () {
                          cubit.switchPortfolio(p.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 14.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCreatePortfolioDialog(context);
                  },
                  icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.black, size: 14),
                  label: Text(
                    context.tr('addPortfolio'),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePortfolioDialog(BuildContext context) {
    final nameController = TextEditingController();
    final cubit = context.read<PortfolioCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final surface = AppColors.getSurface(context);
        final textPrimary = AppColors.getTextPrimary(context);
        final textSecondary = AppColors.getTextSecondary(context);
        final border = AppColors.getBorder(context);

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            left: 20.w,
            right: 20.w,
            top: 20.h,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: const FaIcon(FontAwesomeIcons.folderPlus, color: AppColors.primary, size: 16),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'إضافة محفظة محاكاة جديدة',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'يمكنك تخصيص اسم للمحفظة وإضافة وثائق مستقلة بها (مثل: محفظة الذهب، محفظة التقاعد...)',
                style: TextStyle(color: textSecondary, fontSize: 11.sp),
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: nameController,
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp),
                decoration: InputDecoration(
                  labelText: 'اسم المحفظة الجديدة',
                  hintText: 'مثال: محفظة الطوارئ والذهب 2026',
                  labelStyle: TextStyle(color: textSecondary, fontSize: 12.sp),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      AppSnackBar.showWarning(context, 'يرجى إدخال اسم المحفظة الجديدة');
                      return;
                    }

                    final state = cubit.state;
                    if (state is PortfolioLoaded) {
                      final isDuplicate = state.allPortfolios.any(
                        (p) => p.name.trim().toLowerCase() == name.toLowerCase(),
                      );
                      if (isDuplicate) {
                        AppSnackBar.showError(
                          context,
                          context.tr('duplicatePortfolioError'),
                        );
                        return;
                      }
                    }

                    cubit.createPortfolio(name);
                    Navigator.pop(ctx);
                    AppSnackBar.showSuccess(
                      context,
                      'تم إنشاء وتفعيل محفظة "$name" بنجاح! 🚀',
                    );
                  },
                  child: const Text(
                    'إنشاء وتفعيل المحفظة',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  void _showEditUnitsDialog(BuildContext context, PortfolioItem item) {
    final cubit = context.read<PortfolioCubit>();
    final unitsController = TextEditingController(text: item.units.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final surface = AppColors.getSurface(context);
        final textPrimary = AppColors.getTextPrimary(context);
        final textSecondary = AppColors.getTextSecondary(context);
        final border = AppColors.getBorder(context);

        return StatefulBuilder(
          builder: (context, setStateModal) {
            final double currentVal = double.tryParse(unitsController.text) ?? 0;
            final double calculatedTotal = currentVal * item.currentNav;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(color: border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: const FaIcon(FontAwesomeIcons.penToSquare, color: Color(0xFF3B82F6), size: 16),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            context.tr('editUnits'),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.fundName,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  TextFormField(
                    controller: unitsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp),
                    onChanged: (_) => setStateModal(() {}),
                    decoration: InputDecoration(
                      labelText: 'إجمالي عدد الوثائق المملوكة حالياً',
                      labelStyle: TextStyle(color: textSecondary, fontSize: 12.sp),
                      suffixText: 'وثيقة',
                      suffixStyle: TextStyle(color: textSecondary, fontSize: 12.sp),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Quick Action Adjustment Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAdjustChip('+10 شراء', 10, unitsController, setStateModal),
                      _buildQuickAdjustChip('+50 شراء', 50, unitsController, setStateModal),
                      _buildQuickAdjustChip('-10 بيع', -10, unitsController, setStateModal),
                      _buildQuickAdjustChip('-50 بيع', -50, unitsController, setStateModal),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Summary Valuation Box
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'القيمة الإجمالية المقدرة:',
                          style: TextStyle(color: textSecondary, fontSize: 11.sp),
                        ),
                        Text(
                          '${calculatedTotal.toStringAsFixed(0)} ج.م',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () {
                        final newUnits = double.tryParse(unitsController.text) ?? 0;
                        if (newUnits > 0) {
                          cubit.updateTransactionUnits(itemId: item.id, newUnits: newUnits);
                          Navigator.pop(ctx);
                          AppSnackBar.showSuccess(
                            context,
                            'تم تحديث كمية وثائق "${item.fundName}" إلى $newUnits وثيقة بنجاح!',
                          );
                        } else {
                          AppSnackBar.showWarning(context, context.tr('invalidUnitsError'));
                        }
                      },
                      child: Text(
                        context.tr('save'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAdjustChip(
    String label,
    double delta,
    TextEditingController controller,
    StateSetter setStateModal,
  ) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
      onPressed: () {
        final current = double.tryParse(controller.text) ?? 0;
        final updated = (current + delta).clamp(0, 999999).toDouble();
        controller.text = updated.toStringAsFixed(0);
        setStateModal(() {});
      },
    );
  }
}
