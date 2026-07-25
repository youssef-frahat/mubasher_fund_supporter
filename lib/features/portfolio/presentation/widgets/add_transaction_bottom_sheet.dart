import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../data/models/portfolio_item_model.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final Function({
    required String fundName,
    required FundCategory category,
    required double units,
    required double purchasePrice,
    required double currentNav,
  }) onAdd;

  const AddTransactionBottomSheet({super.key, required this.onAdd});

  @override
  State<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitsController = TextEditingController(text: '10');
  final _priceController = TextEditingController(text: '100');

  FundCategory _selectedCategory = FundCategory.moneyMarket;

  @override
  void dispose() {
    _nameController.dispose();
    _unitsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

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
                    '➕ إضافة صفقة محاكاة جديدة',
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
              SizedBox(height: 16.h),

              // Fund Name
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'اسم الصندوق / الأداة المالية',
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
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم الصندوق' : null,
              ),
              SizedBox(height: 14.h),

              // Category Selector Dropdown
              DropdownButtonFormField<FundCategory>(
                initialValue: _selectedCategory,
                dropdownColor: surface,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'الفئة المالية (Asset Category)',
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
                items: FundCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.color, size: 18.r),
                        SizedBox(width: 8.w),
                        Text(cat.displayNameAr),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              SizedBox(height: 14.h),

              // Units & Price Inputs Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        labelText: 'عدد الوثائق',
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
                      validator: (val) => (double.tryParse(val ?? '') ?? 0) <= 0 ? 'مطلوب' : null,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        labelText: 'سعر الوثيقة (ج.م)',
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
                      validator: (val) => (double.tryParse(val ?? '') ?? 0) <= 0 ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final units = double.parse(_unitsController.text);
                      final price = double.parse(_priceController.text);

                      widget.onAdd(
                        fundName: _nameController.text,
                        category: _selectedCategory,
                        units: units,
                        purchasePrice: price,
                        currentNav: price * 1.08,
                      );

                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: const Text(
                    'حفظ الصفقة في المحفظة',
                    style: TextStyle(
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
