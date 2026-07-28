import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../cubit/portfolio_cubit.dart';
import '../../data/models/portfolio_item_model.dart';

class FundTransactionHistorySheet extends StatefulWidget {
  final PortfolioItem item;

  const FundTransactionHistorySheet({super.key, required this.item});

  @override
  State<FundTransactionHistorySheet> createState() => _FundTransactionHistorySheetState();
}

class _FundTransactionHistorySheetState extends State<FundTransactionHistorySheet> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactionHistory();
  }

  Future<void> _fetchTransactionHistory() async {
    final client = SupabaseService.client;
    final userId = client?.auth.currentUser?.id;

    List<Map<String, dynamic>> fetchedHistory = [];

    if (client != null && userId != null) {
      try {
        final response = await client
            .from('transactions')
            .select()
            .eq('user_id', userId)
            .eq('fund_name', widget.item.fundName)
            .order('created_at', ascending: false);

        fetchedHistory = List<Map<String, dynamic>>.from(response);
      } catch (e) {
        debugPrint('Fetch history error: $e');
      }
    }

    if (fetchedHistory.isEmpty) {
      // Default initial transaction record
      fetchedHistory = [
        {
          'type': 'BUY',
          'units': widget.item.units,
          'purchase_price': widget.item.purchasePrice,
          'created_at': widget.item.purchaseDate.toIso8601String(),
        }
      ];
    }

    if (mounted) {
      setState(() {
        _history = fetchedHistory;
        _isLoading = false;
      });
    }
  }

  void _showAddOrderDialog(BuildContext context, bool isBuy) {
    final unitsController = TextEditingController();
    final priceController = TextEditingController(text: widget.item.currentNav.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20.r,
          right: 20.r,
          top: 20.r,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.r,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FaIcon(
                    isBuy ? FontAwesomeIcons.circleArrowUp : FontAwesomeIcons.circleArrowDown,
                    color: isBuy ? AppColors.success : AppColors.error,
                    size: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    isBuy ? context.tr('buyOrder') : context.tr('sellOrder'),
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Units Input
              TextFormField(
                controller: unitsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppColors.getTextPrimary(context)),
                decoration: InputDecoration(
                  labelText: context.tr('units'),
                  hintText: 'مثال: 10 أو 5',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return context.tr('invalidUnitsError');
                  final d = double.tryParse(val.trim());
                  if (d == null || d <= 0) return context.tr('invalidUnitsError');
                  if (!isBuy && d > widget.item.units) return 'عدد الوثائق المطلوبة أكبر من الرصيد المتاح';
                  return null;
                },
              ),
              SizedBox(height: 12.h),

              // Price Input
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppColors.getTextPrimary(context)),
                decoration: InputDecoration(
                  labelText: context.tr('purchasePriceLabel'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return context.tr('invalidPriceError');
                  final d = double.tryParse(val.trim());
                  if (d == null || d <= 0) return context.tr('invalidPriceError');
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              ElevatedButton.icon(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final enteredUnits = double.parse(unitsController.text.trim());
                    final enteredPrice = double.parse(priceController.text.trim());

                    final newUnits = isBuy
                        ? widget.item.units + enteredUnits
                        : (widget.item.units - enteredUnits).clamp(0.0, double.infinity);

                    // Update local portfolio cubit
                    context.read<PortfolioCubit>().updateTransactionUnits(
                          itemId: widget.item.id,
                          newUnits: newUnits,
                        );

                    // Sync Order to Supabase DB
                    final client = SupabaseService.client;
                    final userId = client?.auth.currentUser?.id;
                    if (client != null && userId != null) {
                      try {
                        await client.from('transactions').insert({
                          'user_id': userId,
                          'fund_name': widget.item.fundName,
                          'category': widget.item.category.name,
                          'type': isBuy ? 'BUY' : 'SELL',
                          'units': enteredUnits,
                          'purchase_price': enteredPrice,
                          'current_nav': widget.item.currentNav,
                          'created_at': DateTime.now().toIso8601String(),
                        });
                      } catch (e) {
                        debugPrint('Insert transaction order error: $e');
                      }
                    }

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    AppSnackBar.showSuccess(context, context.tr('newOrderAddedSuccess'));
                    _fetchTransactionHistory();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBuy ? AppColors.success : AppColors.error,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  isBuy ? 'تأكيد أمر الشراء 🟢' : 'تأكيد أمر البيع 🔴',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);
    final isAr = context.isArabic;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Header Fund Info
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: widget.item.category.color.withValues(alpha: 0.15),
                child: Icon(widget.item.category.icon, color: widget.item.category.color, size: 20.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.fundName,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.tr('orderHistory'),
                      style: TextStyle(color: AppColors.primary, fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Summary Stats Pill Card
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      context.tr('unitsOwned'),
                      style: TextStyle(color: textSecondary, fontSize: 10.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${widget.item.units.toStringAsFixed(1)} ${context.tr('units')}',
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ],
                ),
                Container(height: 24.h, width: 1, color: border),
                Column(
                  children: [
                    Text(
                      context.tr('totalValue'),
                      style: TextStyle(color: textSecondary, fontSize: 10.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${widget.item.currentValue.toStringAsFixed(0)} ${isAr ? 'ج.م' : 'EGP'}',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            isAr ? '📋 سجل الأوامر والعمليات' : '📋 Order History & Transactions',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp),
          ),
          SizedBox(height: 10.h),

          // History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _history.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('noTransactionsYet'),
                          style: TextStyle(color: textSecondary, fontSize: 12.sp),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final record = _history[index];
                          final isBuy = (record['type'] ?? 'BUY') == 'BUY';
                          final units = double.tryParse(record['units']?.toString() ?? '0') ?? 0.0;
                          final price = double.tryParse(record['purchase_price']?.toString() ?? '0') ?? 0.0;
                          final dateStr = record['created_at']?.toString().split('T').first ?? '';

                          return Container(
                            margin: EdgeInsets.only(bottom: 10.h),
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16.r,
                                  backgroundColor: (isBuy ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                                  child: FaIcon(
                                    isBuy ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
                                    color: isBuy ? AppColors.success : AppColors.error,
                                    size: 14.r,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isBuy ? context.tr('buyOrder') : context.tr('sellOrder'),
                                        style: TextStyle(
                                          color: isBuy ? AppColors.success : AppColors.error,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${isAr ? 'تاريخ الأمر:' : 'Order Date:'} $dateStr',
                                        style: TextStyle(color: textSecondary, fontSize: 10.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isBuy ? '+' : '-'}${units.toStringAsFixed(1)} ${context.tr('units')}',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '${isAr ? 'بسعر:' : 'Price:'} ${price.toStringAsFixed(1)} ${isAr ? 'ج.م' : 'EGP'}',
                                      style: TextStyle(color: textSecondary, fontSize: 10.sp),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          SizedBox(height: 14.h),

          // Bottom Action Buttons: Buy Order & Sell Order
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddOrderDialog(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
                  label: Text(
                    isAr ? 'أمر شراء 🟢' : 'Buy Order 🛒',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddOrderDialog(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: const Icon(Icons.sell_outlined, color: AppColors.error, size: 16),
                  label: Text(
                    isAr ? 'أمر بيع 🔴' : 'Sell Order 🔴',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12.sp),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
