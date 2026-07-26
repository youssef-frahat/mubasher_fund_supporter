import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../home/data/models/fund_model.dart';

class AddFundDialog extends StatefulWidget {
  final Function(FundModel) onAdd;

  const AddFundDialog({super.key, required this.onAdd});

  @override
  State<AddFundDialog> createState() => _AddFundDialogState();
}

class _AddFundDialogState extends State<AddFundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _managerController = TextEditingController(text: 'مباشر كابيتال');
  final _navController = TextEditingController(text: '100.0');
  final _ytdController = TextEditingController(text: '0.0');
  
  String _riskLevel = 'Medium';
  String _category = 'Equity';
  String _currency = 'EGP';
  bool _isRecommended = false;
  bool _isSponsored = false;

  final List<String> _categories = [
    'Equity',
    'MoneyMarket',
    'Islamic',
    'Gold',
    'Balanced',
    'Fixed Income',
    'ForeignCurrency'
  ];

  final List<String> _riskLevels = ['Low', 'Medium', 'High'];
  final List<String> _currencies = ['EGP', 'USD', 'EUR'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة صندوق استثماري جديد'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم الصندوق'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'يرجى إدخال اسم الصندوق';
                  if (val.trim().length < 3) return 'الاسم قصير جداً (3 حروف على الأقل)';
                  return null;
                },
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _managerController,
                decoration: const InputDecoration(labelText: 'الشركة المديرة'),
                validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال اسم المدير' : null,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _navController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'سعر الوثيقة (NAV)'),
                      validator: (val) {
                        final d = double.tryParse(val ?? '');
                        if (d == null || d <= 0) return 'سعر غير صالح';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextFormField(
                      controller: _ytdController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'العائد % (YTD)'),
                      validator: (val) {
                        final d = double.tryParse(val ?? '');
                        if (d == null) return 'نسبة غير صالحة';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'الفئة (Category)'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _riskLevel,
                      decoration: const InputDecoration(labelText: 'المخاطرة'),
                      items: _riskLevels.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => _riskLevel = val!),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'العملة'),
                      items: _currencies.map((curr) => DropdownMenuItem(value: curr, child: Text(curr))).toList(),
                      onChanged: (val) => setState(() => _currency = val!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('صندوق ترشيحي / سبونسر (Sponsored ⭐️)'),
                subtitle: const Text('يظهر في التوصيات الرسمية والمستشار الذكي'),
                value: _isSponsored,
                onChanged: (val) => setState(() => _isSponsored = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('صندوق موصى به (Recommended)'),
                value: _isRecommended,
                onChanged: (val) => setState(() => _isRecommended = val ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newFund = FundModel(
                id: '',
                name: _nameController.text.trim(),
                managerName: _managerController.text.trim(),
                currentNav: double.parse(_navController.text.trim()),
                ytdReturn: double.parse(_ytdController.text.trim()),
                riskLevel: _riskLevel,
                category: _category,
                currency: _currency,
                isRecommended: _isRecommended,
                isSponsored: _isSponsored,
              );
              widget.onAdd(newFund);
              Navigator.pop(context);

              AppSnackBar.showSuccess(
                context,
                'تمت إضافة صندوق "${newFund.name}" إلى الباك إند بنجاح!',
              );
            } else {
              AppSnackBar.showWarning(
                context,
                'يرجى التأكد من استكمال كافة بيانات الصندوق بشكل صحيح',
              );
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _managerController.dispose();
    _navController.dispose();
    _ytdController.dispose();
    super.dispose();
  }
}
