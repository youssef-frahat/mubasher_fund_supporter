import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../calculator/data/repositories/calculator_repository.dart';
import '../../../home/data/models/fund_model.dart';
import '../../data/models/portfolio_item_model.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final List<String> existingFundNames;
  final Function({
    required String fundName,
    required FundCategory category,
    required double units,
    required double purchasePrice,
    required double currentNav,
  }) onAdd;

  const AddTransactionBottomSheet({
    super.key,
    required this.onAdd,
    this.existingFundNames = const [],
  });

  @override
  State<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController(text: '10');
  final _customPriceController = TextEditingController();
  final _searchController = TextEditingController();

  List<FundModel> _backendFunds = [];
  List<FundModel> _filteredFunds = [];
  FundModel? _selectedFund;
  bool _isLoadingFunds = true;

  // Price Mode: false = Automatic (Current Backend NAV), true = Manual (Custom Purchase Price)
  bool _isManualPrice = false;

  @override
  void initState() {
    super.initState();
    _loadBackendFunds();
  }

  Future<void> _loadBackendFunds() async {
    try {
      final availableFunds = await CalculatorRepository().getSponsoredBackendFunds(
        excludedFundNames: widget.existingFundNames,
      );

      if (mounted) {
        setState(() {
          _backendFunds = availableFunds;
          _filteredFunds = availableFunds;
          _isLoadingFunds = false;
          if (availableFunds.isNotEmpty) {
            _selectedFund = availableFunds.first;
          } else {
            _selectedFund = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingFunds = false);
      }
    }
  }

  @override
  void dispose() {
    _unitsController.dispose();
    _customPriceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  FundCategory _mapCategory(String categoryStr) {
    final cat = categoryStr.toLowerCase();
    if (cat.contains('gold') || cat.contains('ذهب')) return FundCategory.gold;
    if (cat.contains('islamic') || cat.contains('إسلام')) return FundCategory.islamic;
    if (cat.contains('equity') || cat.contains('أسهم')) return FundCategory.equity;
    if (cat.contains('fixed') || cat.contains('سندات') || cat.contains('أذون')) return FundCategory.treasuryBills;
    return FundCategory.moneyMarket;
  }

  void _openFundPickerModal(BuildContext context) {
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
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('selectFundFromList'),
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
                  SizedBox(height: 10.h),

                  // Search Bar Input
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: context.tr('searchBackendFunds'),
                      hintStyle: TextStyle(color: textSecondary, fontSize: 12.sp),
                      prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20.r),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setStateModal(() {
                                  _filteredFunds = _backendFunds;
                                });
                              },
                            )
                          : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (query) {
                      final q = query.toLowerCase().trim();
                      setStateModal(() {
                        _filteredFunds = _backendFunds.where((f) {
                          final nameMatch = f.name.toLowerCase().contains(q);
                          final nameArMatch = (f.nameAr ?? '').toLowerCase().contains(q);
                          final nameEnMatch = (f.nameEn ?? '').toLowerCase().contains(q);
                          final managerMatch = f.managerName.toLowerCase().contains(q);
                          final catMatch = f.category.toLowerCase().contains(q);
                          final abbrMatch = (f.abbreviation ?? '').toLowerCase().contains(q);
                          return nameMatch || nameArMatch || nameEnMatch || managerMatch || catMatch || abbrMatch;
                        }).toList();
                      });
                    },
                  ),
                  SizedBox(height: 12.h),

                  Expanded(
                    child: _filteredFunds.isEmpty
                        ? Center(
                            child: Text(
                              widget.existingFundNames.isNotEmpty && _backendFunds.isEmpty
                                  ? context.tr('allFundsAddedError')
                                  : context.tr('noMatchingFundsFound'),
                              style: TextStyle(color: textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredFunds.length,
                            itemBuilder: (context, index) {
                              final fund = _filteredFunds[index];
                              final isSelected = _selectedFund?.id == fund.id;

                              return Card(
                                margin: EdgeInsets.only(bottom: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : surface,
                                child: ListTile(
                                  title: Text(
                                    fund.name,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${fund.managerName} | ${fund.category}',
                                    style: TextStyle(color: textSecondary, fontSize: 11.sp),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'NAV: ${fund.currentNav} ${fund.currency}',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      Text(
                                        'YTD: +${fund.ytdReturn}%',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedFund = fund;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                ),
                              );
                            },
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

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    final selectedNav = _selectedFund?.currentNav ?? 100.0;

    return Container(
      padding: EdgeInsets.only(
        top: 20.h,
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('addSimTransactionTitle'),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // 1. Fund Selection Selector (Searchable)
              Text(
                context.tr('selectFundLabel'),
                style: TextStyle(color: textSecondary, fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6.h),

              _isLoadingFunds
                  ? const Center(child: CircularProgressIndicator())
                  : GestureDetector(
                      onTap: () => _openFundPickerModal(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.primary, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppColors.primary, size: 20.r),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFund?.name ??
                                        (widget.existingFundNames.isNotEmpty && _backendFunds.isEmpty
                                            ? context.tr('allFundsAddedShort')
                                            : context.tr('selectFundFromListHint')),
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedFund != null) ...[
                                    SizedBox(height: 2.h),
                                    Text(
                                      '${_selectedFund!.managerName} | ${context.tr('currentNavLabel')}: ${_selectedFund!.currentNav} ${_selectedFund!.currency}',
                                      style: TextStyle(color: textSecondary, fontSize: 10.sp),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 24.r),
                          ],
                        ),
                      ),
                    ),
              SizedBox(height: 16.h),

              // 2. Units Input Field (Numbers & Decimals Only Protected)
              TextFormField(
                controller: _unitsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: context.tr('units'),
                  hintText: context.tr('unitsHint'),
                  labelStyle: TextStyle(color: textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (val) {
                  final parsed = double.tryParse(val ?? '');
                  if (parsed == null || parsed <= 0) return context.tr('invalidUnitsError');
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // 3. Purchase Price Mode Switcher (Automatic vs Custom Manual)
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('setPurchasePriceMode'),
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        Switch(
                          value: _isManualPrice,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isManualPrice = val),
                        ),
                      ],
                    ),
                    Text(
                      _isManualPrice
                          ? context.tr('enterCustomPurchasePrice')
                          : '${context.tr('useCurrentNavDefault')} ($selectedNav EGP)',
                      style: TextStyle(
                        color: _isManualPrice ? AppColors.gold : AppColors.success,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // Custom Manual Purchase Price Input (If Manual Enabled)
              if (_isManualPrice) ...[
                TextFormField(
                  controller: _customPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: context.tr('purchasePriceLabel'),
                    hintText: context.tr('purchasePriceHint'),
                    labelStyle: TextStyle(color: textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (val) {
                    if (_isManualPrice) {
                      final parsed = double.tryParse(val ?? '');
                      if (parsed == null || parsed <= 0) return context.tr('invalidPriceError');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
              ],

              // Submit Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedFund == null) {
                      AppSnackBar.showWarning(context, context.tr('selectFundFirstWarning'));
                      return;
                    }

                    if (_formKey.currentState!.validate()) {
                      final units = double.parse(_unitsController.text);
                      final purchasePrice = _isManualPrice
                          ? double.parse(_customPriceController.text)
                          : selectedNav;
                      final fundName = _selectedFund!.name;
                      final category = _mapCategory(_selectedFund!.category);

                      widget.onAdd(
                        fundName: fundName,
                        category: category,
                        units: units,
                        purchasePrice: purchasePrice,
                        currentNav: selectedNav,
                      );

                      Navigator.pop(context);

                      AppSnackBar.showSuccess(
                        context,
                        context.tr('transactionAddedSuccess'),
                      );
                    } else {
                      AppSnackBar.showWarning(
                        context,
                        context.tr('fillFormCorrectlyWarning'),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    context.tr('addTransaction'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
