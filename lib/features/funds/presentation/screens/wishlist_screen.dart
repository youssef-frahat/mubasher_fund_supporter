import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_config/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../../home/data/models/fund_model.dart';
import '../../../home/presentation/widgets/fund_list_tile.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final wishlistService = sl<WishlistService>();

    // Mock comprehensive funds list to match saved IDs
    final allMockFunds = [
      FundModel.mock('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'صندوق مباشر للأسهم المصرية (نمو)', 24.8, category: 'Equity', riskLevel: 'High'),
      FundModel.mock('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'صندوق أزيموت النقدية اليومية', 18.5, category: 'MoneyMarket', riskLevel: 'Low'),
      FundModel.mock('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'صندوق أزيموت الذهب (AZG)', 32.1, category: 'Gold', riskLevel: 'Medium'),
      FundModel.mock('d4e5f6a7-b89c-0d1e-2f3a-4b5c6d7e8f9a', 'صندوق سي أي كابيتال الشريعة الإسلامية', 21.3, category: 'Islamic', riskLevel: 'Medium'),
      FundModel.mock('e5f6a7b8-9c0d-1e2f-3a4b-5c6d7e8f9a0b', 'صندوق بلتون أذون وسندات الخزانة', 19.8, category: 'TreasuryBills', riskLevel: 'Low'),
      FundModel.mock('1', 'Banque Misr First Fund', 12.5),
      FundModel.mock('2', 'NBE Fund (Fourth)', 8.3, riskLevel: 'Low'),
      FundModel.mock('3', 'CIB Equity Fund', 15.2, riskLevel: 'High'),
      FundModel.mock('4', 'EFG Hermes Growth Fund', 24.8, riskLevel: 'High'),
      FundModel.mock('5', 'Faisal Islamic Fund', 10.1, category: 'Islamic'),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'الصناديق المفضلة ⭐️',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: wishlistService.savedFundIds,
        builder: (context, savedIds, _) {
          final savedFunds = allMockFunds
              .where((fund) => savedIds.contains(fund.id))
              .toList();

          if (savedFunds.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90.r,
                      height: 90.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.bookmark,
                          size: 38.r,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'لا توجد صناديق مفضلة حتى الآن',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'اضغط على زر الإشارة المرجعية 🔖 في أي صندوق لإضافته لقائمتك المفضلة والوصول السريع إليه.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () => context.push(Routes.allFunds),
                      icon: const Icon(Icons.search),
                      label: const Text('استكشف جميع الصناديق'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(20.r),
            itemCount: savedFunds.length,
            itemBuilder: (context, index) {
              final fund = savedFunds[index];
              return FundListTile(
                fund: fund,
                rank: index + 1,
              );
            },
          );
        },
      ),
    );
  }
}
