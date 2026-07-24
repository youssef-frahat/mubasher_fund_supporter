import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/models/platform_feature.dart';
import '../../../portfolio/presentation/cubit/portfolio_cubit.dart';

class FundDetailsScreen extends StatelessWidget {
  final PlatformFeature fund;

  const FundDetailsScreen({super.key, required this.fund});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fund.title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: fund.accentColor.withValues(alpha: 0.2),
                  radius: 30.r,
                  child: Icon(fund.icon, color: fund.accentColor, size: 30.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fund.title,
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        fund.subtitle,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Text(
              'NAV History (Mock Data)',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 250.h,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 10),
                        FlSpot(1, 12),
                        FlSpot(2, 11),
                        FlSpot(3, 14),
                        FlSpot(4, 15),
                        FlSpot(5, 14.5),
                        FlSpot(6, 17),
                      ],
                      isCurved: true,
                      color: fund.accentColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: fund.accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: fund.accentColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                onPressed: () => _showAddTransactionDialog(context, fund),
                child: const Text('Simulate Purchase', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, PlatformFeature fund) {
    final unitsController = TextEditingController();
    final priceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16.w, right: 16.w, top: 16.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Simulate Purchase for ${fund.title}', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              TextField(
                controller: unitsController,
                decoration: const InputDecoration(labelText: 'Number of Units'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Purchase Price (per unit)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final units = double.tryParse(unitsController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    if (units > 0 && price > 0) {
                      context.read<PortfolioCubit>().addTransaction(fund.id ?? '', units, price);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction Added!')));
                    }
                  },
                  child: const Text('Add Transaction'),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }
}
