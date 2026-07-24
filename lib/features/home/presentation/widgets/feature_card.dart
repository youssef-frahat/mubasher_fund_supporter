import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../../../core/routing/routes.dart';
import '../../data/models/platform_feature.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({super.key, required this.feature});

  final PlatformFeature feature;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(Routes.fundDetails, extra: feature);
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: feature.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(feature.icon, color: feature.accentColor, size: 24.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                feature.title,
                style: FontStyles.titleMedium,
              ),
              SizedBox(height: 8.h),
              Text(
                feature.subtitle,
                style: FontStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
