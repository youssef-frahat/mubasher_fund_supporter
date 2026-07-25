import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../data/models/fund_model.dart';

class TopPerformingCard extends StatelessWidget {
  final FundModel fund;

  const TopPerformingCard({super.key, required this.fund});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 28.sp),
              SizedBox(width: 8.w),
              Text(
                "Top Performing Fund",
                style: FontStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            fund.name,
            style: FontStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "YTD Return",
                    style: FontStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "+${fund.ytdReturn}%",
                    style: FontStyles.headlineMedium.copyWith(
                      color: Colors.greenAccent[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text("Invest"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
