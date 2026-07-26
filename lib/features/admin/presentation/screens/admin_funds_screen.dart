import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../home/data/models/fund_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../widgets/add_fund_dialog.dart';
import '../widgets/edit_fund_dialog.dart';

class AdminFundsScreen extends StatefulWidget {
  const AdminFundsScreen({super.key});

  @override
  State<AdminFundsScreen> createState() => _AdminFundsScreenState();
}

class _AdminFundsScreenState extends State<AdminFundsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminCubit>()..loadFunds(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الصناديق ومؤشرات النظام (CRUD Dashboard)'),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                  tooltip: 'إضافة صندوق جديد',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddFundDialog(
                        onAdd: (fund) {
                          context.read<AdminCubit>().addFund(fund);
                        },
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(width: 12.w),
          ],
        ),
        body: BlocBuilder<AdminCubit, AdminState>(
          builder: (context, state) {
            int totalFundsCount = 0;
            List<FundModel> allFunds = [];

            if (state is AdminFundsLoaded) {
              allFunds = state.funds;
              totalFundsCount = allFunds.length;
            }

            return Column(
              children: [
                // Admin Dashboard Metric Statistics Header
                Container(
                  padding: EdgeInsets.all(12.r),
                  margin: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAdminMetricTile(context, 'إجمالي الصناديق', '$totalFundsCount', Colors.green),
                      _buildAdminMetricTile(context, 'تحديث الأسعار', '98.6%', Colors.blue),
                      _buildAdminMetricTile(context, 'حسابات المستشار', '1,248', Colors.amber),
                      _buildAdminMetricTile(context, 'محرك الذكاء', '24/7 نشط', Colors.purple),
                    ],
                  ),
                ),

                // Search Bar Input
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'بحث عن صندوق أو مدير أو فئة...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase().trim();
                      });
                    },
                  ),
                ),

                // Funds List View
                Expanded(
                  child: state is AdminLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state is AdminFundsLoaded
                          ? Builder(
                              builder: (context) {
                                final filteredFunds = allFunds.where((f) {
                                  final nameMatch = f.name.toLowerCase().contains(_searchQuery);
                                  final managerMatch = f.managerName.toLowerCase().contains(_searchQuery);
                                  final categoryMatch = f.category.toLowerCase().contains(_searchQuery);
                                  return nameMatch || managerMatch || categoryMatch;
                                }).toList();

                                if (filteredFunds.isEmpty) {
                                  return const Center(child: Text('لا توجد صناديق مطابقة للبحث'));
                                }

                                return ListView.builder(
                                  itemCount: filteredFunds.length,
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  itemBuilder: (context, index) {
                                    final fund = filteredFunds[index];
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 12.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                          child: Text(
                                            fund.category.isNotEmpty ? fund.category[0].toUpperCase() : 'F',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          fund.name,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                                        ),
                                        subtitle: Padding(
                                          padding: EdgeInsets.only(top: 4.h),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${fund.managerName} | ${fund.category}'),
                                              SizedBox(height: 2.h),
                                              Row(
                                                children: [
                                                  Text(
                                                    'NAV: ${fund.currentNav} ${fund.currency}',
                                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Text(
                                                    'YTD: +${fund.ytdReturn}%',
                                                    style: TextStyle(
                                                      color: Colors.green[700],
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              tooltip: 'تعديل',
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => EditFundDialog(
                                                    fund: fund,
                                                    onSave: (updatedFund) {
                                                      context.read<AdminCubit>().updateFund(updatedFund);
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              tooltip: 'حذف',
                                              onPressed: () {
                                                _confirmDelete(context, fund);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : state is AdminError
                              ? Center(child: Text('خطأ: ${state.message}'))
                              : const Center(child: Text('جاري التحميل...')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdminMetricTile(BuildContext context, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, FundModel fund) {
    final cubit = context.read<AdminCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت تأكد من رغبتك في حذف "${fund.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              cubit.deleteFund(fund.id);
              Navigator.pop(dialogContext);
              AppSnackBar.showSuccess(
                context,
                'تم حذف صندوق "${fund.name}" من الباك إند بنجاح!',
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
