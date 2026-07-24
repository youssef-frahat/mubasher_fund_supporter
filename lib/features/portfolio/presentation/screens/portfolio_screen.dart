import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/service_locator.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PortfolioCubit>().fetchPortfolio();
  }

  @override
  Widget build(BuildContext context) {
    return const PortfolioView();
  }
}

class PortfolioView extends StatelessWidget {
  const PortfolioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulated Portfolio')),
      body: BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PortfolioError) {
            return Center(child: Text(state.message));
          } else if (state is PortfolioLoaded) {
            final summaries = state.fundSummaries.values.toList();
            if (summaries.isEmpty) {
              return const Center(child: Text('Your portfolio is empty.'));
            }

            double totalPortfolioValue = 0;
            double totalPortfolioCost = 0;
            for (var s in summaries) {
              totalPortfolioValue += s.currentValue;
              totalPortfolioCost += s.totalCost;
            }
            final totalProfit = totalPortfolioValue - totalPortfolioCost;

            return Column(
              children: [
                _buildDashboard(totalPortfolioValue, totalProfit),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: summaries.length,
                    itemBuilder: (context, index) {
                      final summary = summaries[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16.h),
                        child: ListTile(
                          title: Text(summary.fundName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Units: ${summary.totalUnits.toStringAsFixed(2)} | Avg Cost: \$${summary.averageCost.toStringAsFixed(2)}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${summary.currentValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${summary.profitLoss >= 0 ? '+' : ''}${summary.profitLoss.toStringAsFixed(2)}',
                                style: TextStyle(color: summary.profitLoss >= 0 ? Colors.green : Colors.red, fontSize: 12.sp),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open Add Transaction Dialog
          // For now, it will just show a snackbar. We will integrate this from FundDetailsScreen.
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Go to a Fund Details screen to simulate a purchase.'))
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboard(double totalValue, double totalProfit) {
    return Container(
      padding: EdgeInsets.all(24.w),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Column(
        children: [
          const Text('Total Value', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 8.h),
          Text('\$${totalValue.toStringAsFixed(2)}', style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text(
            '${totalProfit >= 0 ? '+' : ''}\$${totalProfit.toStringAsFixed(2)}',
            style: TextStyle(color: totalProfit >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
