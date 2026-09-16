import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../home/data/models/fund_model.dart';

class EditFundDialog extends StatefulWidget {
  final FundModel fund;
  final Function(FundModel) onSave;

  const EditFundDialog({super.key, required this.fund, required this.onSave});

  @override
  State<EditFundDialog> createState() => _EditFundDialogState();
}

class _EditFundDialogState extends State<EditFundDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _managerController;
  late TextEditingController _navController;
  late TextEditingController _ytdController;
  
  late String _riskLevel;
  late String _category;
  late String _currency;
  late bool _isRecommended;
  late bool _isSponsored;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fund.name);
    _managerController = TextEditingController(text: widget.fund.managerName);
    _navController = TextEditingController(text: widget.fund.currentNav.toString());
    _ytdController = TextEditingController(text: widget.fund.ytdReturn.toString());
    _riskLevel = _riskLevels.contains(widget.fund.riskLevel) ? widget.fund.riskLevel : 'Medium';
    _category = _categories.contains(widget.fund.category) ? widget.fund.category : 'Equity';
    _currency = _currencies.contains(widget.fund.currency) ? widget.fund.currency : 'EGP';
    _isRecommended = widget.fund.isRecommended;
    _isSponsored = widget.fund.isSponsored;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return AlertDialog(
      title: Text(context.tr('editFund')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: context.tr('fundNameLabel')),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return context.tr('fundNameRequired');
                  if (val.trim().length < 3) return context.tr('nameTooShort');
                  return null;
                },
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _managerController,
                decoration: InputDecoration(labelText: context.tr('managerLabel')),
                validator: (val) => val == null || val.trim().isEmpty ? context.tr('managerNameRequired') : null,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _navController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: context.tr('navPriceLabel')),
                      validator: (val) {
                        final d = double.tryParse(val ?? '');
                        if (d == null || d <= 0) return context.tr('invalidPriceOrNav');
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextFormField(
                      controller: _ytdController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: context.tr('ytdReturnLabel')),
                      validator: (val) {
                        final d = double.tryParse(val ?? '');
                        if (d == null) return context.tr('invalidReturnRate');
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(labelText: context.tr('category')),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _riskLevel,
                      decoration: InputDecoration(labelText: context.tr('risk')),
                      items: _riskLevels.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => _riskLevel = val!),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: InputDecoration(labelText: context.tr('currencyLabel')),
                      items: _currencies.map((curr) => DropdownMenuItem(value: curr, child: Text(curr))).toList(),
                      onChanged: (val) => setState(() => _currency = val!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('sponsoredFundTag')),
                subtitle: Text(context.tr('sponsoredFundSub')),
                value: _isSponsored,
                onChanged: (val) => setState(() => _isSponsored = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('recommendedFundTag')),
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
          child: Text(context.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedFund = FundModel(
                id: widget.fund.id,
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
              widget.onSave(updatedFund);
              Navigator.pop(context);

              AppSnackBar.showSuccess(
                context,
                isAr
                    ? 'تمت تحديث بيانات صندوق "${updatedFund.name}" بنجاح!'
                    : 'Fund "${updatedFund.name}" updated successfully!',
              );
            } else {
              AppSnackBar.showWarning(
                context,
                context.tr('fillAllDataWarning'),
              );
            }
          },
          child: Text(context.tr('saveChanges')),
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
