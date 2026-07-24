import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/service_locator.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../widgets/add_fund_dialog.dart';

class AdminFundsScreen extends StatelessWidget {
  const AdminFundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminCubit>()..loadFunds(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Funds'),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.add),
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
              }
            ),
            SizedBox(width: 16.w),
          ],
        ),
        body: BlocBuilder<AdminCubit, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AdminFundsLoaded) {
              return ListView.builder(
                itemCount: state.funds.length,
                itemBuilder: (context, index) {
                  final fund = state.funds[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: fund.accentColor.withValues(alpha: 0.2),
                      child: Icon(fund.icon, color: fund.accentColor),
                    ),
                    title: Text(fund.title),
                    subtitle: Text(fund.subtitle),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (fund.id != null) {
                          context.read<AdminCubit>().deleteFund(fund.id!);
                        }
                      },
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('Error loading funds'));
          },
        ),
      ),
    );
  }
}
