import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/routing/routes.dart';
import '../../data/models/fund_model.dart';

class TopPerformingCard extends StatelessWidget {
  final FundModel fund;

  const TopPerformingCard({super.key, required this.fund});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(Routes.fundDetails, extra: fund.toPlatformFeature()),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0D1B2A)]
                : const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glow accent top-right
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00E676).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: #1 Badge + Crown + Category
                  Row(
                    children: [
                      Container(
                        width: 44.r,
                        height: 44.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFF59E0B), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.crown, size: 12.r, color: const Color(0xFF1A1A2E)),
                              Text(
                                '#1',
                                style: TextStyle(
                                  color: const Color(0xFF1A1A2E),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.sp,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('topPerforming'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFFFFD700),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.sp,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              fund.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10.sp,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 34.r,
                        height: 34.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 13.r,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Fund Name
                  Text(
                    fund.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.visible,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    fund.managerName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                  SizedBox(height: 14.h),

                  // Divider line
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Bottom stats row
                  Row(
                    children: [
                      _buildStat(
                        context: context,
                        label: context.tr('annualReturn'),
                        value: '+${fund.ytdReturn}%',
                        valueColor: AppColors.primary,
                        icon: FontAwesomeIcons.arrowTrendUp,
                      ),
                      SizedBox(width: 12.w),
                      _buildStat(
                        context: context,
                        label: context.tr('navPrice'),
                        value: '${fund.currentNav} ${fund.currency}',
                        valueColor: Colors.white,
                        icon: FontAwesomeIcons.coins,
                      ),
                      SizedBox(width: 12.w),
                      _buildStat(
                        context: context,
                        label: context.tr('risk'),
                        value: fund.riskLevel,
                        valueColor: fund.riskLevel == 'Low'
                            ? AppColors.primary
                            : fund.riskLevel == 'Medium'
                                ? AppColors.gold
                                : AppColors.error,
                        icon: FontAwesomeIcons.shieldHalved,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required BuildContext context,
    required String label,
    required String value,
    required Color valueColor,
    required dynamic icon,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon is IconData
                  ? Icon(icon, size: 10.r, color: Colors.white.withValues(alpha: 0.35))
                  : FaIcon(icon, size: 10.r, color: Colors.white.withValues(alpha: 0.35)),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 9.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
