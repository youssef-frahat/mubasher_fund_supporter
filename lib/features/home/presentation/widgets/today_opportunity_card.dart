import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/routing/routes.dart';
import '../../../calculator/data/repositories/calculator_repository.dart';
import '../../data/models/fund_model.dart';

class TodayOpportunityCard extends StatelessWidget {
  final FundModel? recommendedFund;

  const TodayOpportunityCard({super.key, this.recommendedFund});

  void _openAiMarketSignalsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AiMarketSignalsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LanguageCubit>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0F2D1F), Color(0xFF0B1F15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE8F7EE), Color(0xFFF3FAF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final borderColor = isDark ? const Color(0xFF1B4D35) : const Color(0xFFC2EBCD);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B331E);
    final textSecondary = isDark ? const Color(0xFFA3CDB5) : const Color(0xFF386B52);
    final fundNameText = recommendedFund?.displayNameOnly ?? 'صندوق مباشر اليومي للسيولة النقدية';

    return GestureDetector(
      onTap: () => _openAiMarketSignalsSheet(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Pill Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF163E2B) : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isDark ? const Color(0xFF235C40) : const Color(0xFFA6E0B8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 11)),
                        SizedBox(width: 4.w),
                        Text(
                          isAr ? 'إشارات الذكاء الاصطناعي اليومية' : "AI Daily Signals",
                          style: TextStyle(
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF047857),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Main Title
                  Text(
                    isAr ? 'تحليل السوق وإشارات الدخول والخروج' : "AI Market Analysis & Daily Signals",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Subtitle
                  Text(
                    isAr ? 'ترشيحات الدخول لقصوى الصعود والخروج لقصوى الهبوط' : 'Top gainers buy signals & top dips exit/hedge recommendations',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11.sp,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Recommended Fund Badge
                  Row(
                    children: [
                      const Text('⭐️', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 4.w),
                      Text(
                        isAr ? 'الصندوق الموصى به' : 'Recommended Fund',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Fund Name
                  Text(
                    fundNameText,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12.h),

                  // Button
                  ElevatedButton(
                    onPressed: () => _openAiMarketSignalsSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF044E2B),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAr ? 'استكشف إشارات AI الآن 🤖' : 'Explore AI Signals 🤖',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          isAr ? Icons.arrow_back : Icons.arrow_forward,
                          size: 14.r,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),

            // Right Graphic Illustration (3D Financial Chart Graphic)
            SizedBox(
              width: 90.w,
              height: 120.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    ),
                  ),
                  CustomPaint(
                    size: Size(80.w, 100.h),
                    painter: _ChartGraphicPainter(isDark: isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiMarketSignalsSheet extends StatefulWidget {
  const _AiMarketSignalsSheet();

  @override
  State<_AiMarketSignalsSheet> createState() => _AiMarketSignalsSheetState();
}

class _AiMarketSignalsSheetState extends State<_AiMarketSignalsSheet> {
  List<FundModel> _funds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final backendFunds = await CalculatorRepository().getSponsoredBackendFunds();
      if (mounted) {
        setState(() {
          _funds = backendFunds;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    // Calculate Top Gainer (Buy Signal) & Top Dip (Exit Signal)
    FundModel? topGainer;
    FundModel? topDip;
    FundModel? topGoldLiquidity;

    if (_funds.isNotEmpty) {
      final sortedByReturn = List<FundModel>.from(_funds)
        ..sort((a, b) => b.ytdReturn.compareTo(a.ytdReturn));

      topGainer = sortedByReturn.first;
      topDip = sortedByReturn.last;

      topGoldLiquidity = _funds.firstWhere(
        (f) => f.category.toLowerCase().contains('gold') || f.category.toLowerCase().contains('money'),
        orElse: () => _funds.first,
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Overflow Fix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: const FaIcon(FontAwesomeIcons.robot, color: AppColors.primary, size: 18),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        context.tr('aiMarketSignalsTitle'),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            context.tr('aiMarketSignalsSubtitle'),
            style: TextStyle(color: textSecondary, fontSize: 11.sp),
          ),
          SizedBox(height: 16.h),

          // Main Signal Body Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. BUY SIGNAL CARD (Top Gainer)
                        if (topGainer != null)
                          _buildSignalCard(
                            context: context,
                            title: context.tr('buySignalHeader'),
                            badgeColor: const Color(0xFF10B981),
                            fund: topGainer,
                            reason: context.tr('buyReason'),
                            actionLabel: 'ترشيح الشراء والدخول 🚀',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.fundDetails, extra: topGainer!.toPlatformFeature());
                            },
                          ),
                        SizedBox(height: 14.h),

                        // 2. EXIT / CAUTION SIGNAL CARD (Top Dip / Falling)
                        if (topDip != null)
                          _buildSignalCard(
                            context: context,
                            title: context.tr('sellSignalHeader'),
                            badgeColor: AppColors.error,
                            fund: topDip,
                            reason: context.tr('sellReason'),
                            actionLabel: 'تأمين الأرباح والتخرج ⚠️',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.fundDetails, extra: topDip!.toPlatformFeature());
                            },
                          ),
                        SizedBox(height: 14.h),

                        // 3. HEDGE / LIQUIDITY REBALANCING CARD
                        if (topGoldLiquidity != null)
                          _buildSignalCard(
                            context: context,
                            title: '🛡️ ترشيح التحوط والسيولة (HEDGE & LIQUIDITY)',
                            badgeColor: AppColors.gold,
                            fund: topGoldLiquidity,
                            reason: 'أفضل اختيار لحفظ القوة الشرائية وامتصاص تقلبات البورصة اليومية',
                            actionLabel: 'استكشاف صندوق التحوط ⚡',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(Routes.fundDetails, extra: topGoldLiquidity!.toPlatformFeature());
                            },
                          ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCard({
    required BuildContext context,
    required String title,
    required Color badgeColor,
    required FundModel fund,
    required String reason,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    final ytdFormatted = fund.ytdReturn >= 0 ? '+${fund.ytdReturn}%' : '${fund.ytdReturn}%';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
              ),
            ),
          ),
          SizedBox(height: 10.h),

          Text(
            fund.displayNameOnly,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          if (fund.abbreviation != null) ...[
            SizedBox(height: 1.h),
            Text(
              '🏷️ ${fund.abbreviation}',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: 2.h),

          Text(
            '${fund.managerName} | YTD: $ytdFormatted | NAV: ${fund.currentNav} ${fund.currency}',
            style: TextStyle(
              color: textSecondary,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 8.h),

          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: border),
            ),
            child: Text(
              '💡 السبب: $reason',
              style: TextStyle(
                color: textPrimary,
                fontSize: 11.sp,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: badgeColor,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartGraphicPainter extends CustomPainter {
  final bool isDark;

  _ChartGraphicPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bar1Paint = Paint()
      ..color = const Color(0xFFA7F3D0)
      ..style = PaintingStyle.fill;

    final bar2Paint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.fill;

    final bar3Paint = Paint()
      ..color = const Color(0xFF059669)
      ..style = PaintingStyle.fill;

    final arrowPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowHeadPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    double barWidth = 14.w;
    double bottomY = size.height - 10.h;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10.w, bottomY - 30.h, barWidth, 30.h),
        Radius.circular(4.r),
      ),
      bar1Paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30.w, bottomY - 50.h, barWidth, 50.h),
        Radius.circular(4.r),
      ),
      bar2Paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(50.w, bottomY - 75.h, barWidth, 75.h),
        Radius.circular(4.r),
      ),
      bar3Paint,
    );

    Path arrowPath = Path();
    arrowPath.moveTo(8.w, bottomY - 15.h);
    arrowPath.quadraticBezierTo(25.w, bottomY - 55.h, 68.w, bottomY - 85.h);
    canvas.drawPath(arrowPath, arrowPaint);

    Path headPath = Path();
    headPath.moveTo(68.w, bottomY - 85.h);
    headPath.lineTo(58.w, bottomY - 82.h);
    headPath.lineTo(65.w, bottomY - 72.h);
    headPath.close();
    canvas.drawPath(headPath, arrowHeadPaint);

    final piePaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromLTWH(15.w, 5.h, 40.w, 40.w),
      -0.5,
      4.5,
      true,
      piePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
