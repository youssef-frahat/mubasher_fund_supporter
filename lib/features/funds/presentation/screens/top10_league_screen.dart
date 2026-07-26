import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/routing/routes.dart';
import '../../../calculator/data/repositories/calculator_repository.dart';
import '../../../home/data/models/fund_model.dart';

class Top10LeagueScreen extends StatefulWidget {
  const Top10LeagueScreen({super.key});

  @override
  State<Top10LeagueScreen> createState() => _Top10LeagueScreenState();
}

class _Top10LeagueScreenState extends State<Top10LeagueScreen> {
  List<FundModel> _top10Funds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTop10Data();
  }

  Future<void> _loadTop10Data() async {
    try {
      final backendFunds = await CalculatorRepository().getSponsoredBackendFunds();
      final sorted = List<FundModel>.from(backendFunds)
        ..sort((a, b) => b.ytdReturn.compareTo(a.ytdReturn));

      final top10 = sorted.take(10).toList();

      if (mounted) {
        setState(() {
          _top10Funds = top10;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LanguageCubit>().isArabic;
    final bg = AppColors.getBackground(context);
    final textPrimary = AppColors.getTextPrimary(context);

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
          context.tr('fundSupporterLeague'),
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Banner Title & Info
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F3822), Color(0xFF062013)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('⚽️ 🏆', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                context.tr('fundSupporterLeague'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          context.tr('fundSupporterLeagueSub'),
                          style: TextStyle(
                            color: const Color(0xFFA7F3D0),
                            fontSize: 11.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Top 3 Podium (منصة التتويج)
                  if (_top10Funds.length >= 3) _buildPodium(context),
                  SizedBox(height: 24.h),

                  // Standings Header
                  Text(
                    isAr ? '📋 جدول نقاط الترتيب الكامل (Top 10):' : '📋 Full League Standings Table (Top 10):',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Table Rows List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _top10Funds.length,
                    itemBuilder: (context, index) {
                      final fund = _top10Funds[index];
                      final rank = index + 1;
                      final movement = (index == 0)
                          ? 2
                          : (index == 1)
                              ? 1
                              : (index == 3)
                                  ? -1
                                  : 0;

                      return _buildLeagueRow(context, fund, rank, movement);
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
    );
  }

  Widget _buildPodium(BuildContext context) {
    final first = _top10Funds[0];
    final second = _top10Funds[1];
    final third = _top10Funds[2];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place (Silver)
        Expanded(child: _buildPodiumItem(context, second, 2, '🥈', const Color(0xFF94A3B8), 135.h)),
        SizedBox(width: 8.w),
        // 1st Place (Gold Leader)
        Expanded(child: _buildPodiumItem(context, first, 1, '🥇', const Color(0xFFF59E0B), 160.h)),
        SizedBox(width: 8.w),
        // 3rd Place (Bronze)
        Expanded(child: _buildPodiumItem(context, third, 3, '🥉', const Color(0xFFD97706), 120.h)),
      ],
    );
  }

  Widget _buildPodiumItem(BuildContext context, FundModel fund, int rank, String medal, Color badgeColor, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;

    final nameText = fund.displayNameOnly;
    final abbrText = fund.abbreviation;

    return GestureDetector(
      onTap: () {
        context.push(Routes.fundDetails, extra: fund.toPlatformFeature());
      },
      child: Container(
        height: height,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: badgeColor.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(medal, style: TextStyle(fontSize: rank == 1 ? 24.sp : 20.sp)),
            SizedBox(height: 2.h),
            Text(
              nameText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (abbrText != null) ...[
              SizedBox(height: 1.h),
              Text(
                '($abbrText)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '+${fund.ytdReturn}% YTD',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueRow(BuildContext context, FundModel fund, int rank, int movement) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    final nameText = fund.displayNameOnly;
    final abbrText = fund.abbreviation;

    Widget movementBadge;
    if (movement > 0) {
      movementBadge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_drop_up, color: const Color(0xFF10B981), size: 18.r),
          Text(
            '+$movement',
            style: TextStyle(color: const Color(0xFF10B981), fontSize: 10.sp, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else if (movement < 0) {
      movementBadge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_drop_down, color: AppColors.error, size: 18.r),
          Text(
            '$movement',
            style: TextStyle(color: AppColors.error, fontSize: 10.sp, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      movementBadge = Text(
        '➖ 0',
        style: TextStyle(color: textSecondary, fontSize: 10.sp),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          leading: Container(
            width: 34.w,
            height: 34.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rank == 1
                  ? const Color(0xFFF59E0B)
                  : rank == 2
                      ? const Color(0xFF94A3B8)
                      : rank == 3
                          ? const Color(0xFFD97706)
                          : AppColors.primary.withValues(alpha: 0.15),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank <= 3 ? Colors.black : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nameText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  movementBadge,
                ],
              ),
              if (abbrText != null) ...[
                SizedBox(height: 1.h),
                Text(
                  '🏷️ $abbrText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              '${fund.managerName} | NAV: ${fund.currentNav} ${fund.currency}',
              style: TextStyle(color: textSecondary, fontSize: 11.sp),
            ),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '+${fund.ytdReturn}%',
              style: TextStyle(
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
          onTap: () {
            context.push(Routes.fundDetails, extra: fund.toPlatformFeature());
          },
        ),
      ),
    );
  }
}
