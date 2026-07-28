import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/routing/routes.dart';
import '../../../home/data/models/fund_model.dart';
import '../../../home/data/repositories/funds_repository.dart';

class Top10LeagueScreen extends StatefulWidget {
  const Top10LeagueScreen({super.key});

  @override
  State<Top10LeagueScreen> createState() => _Top10LeagueScreenState();
}

class _Top10LeagueScreenState extends State<Top10LeagueScreen> {
  List<FundModel> _top10Funds = [];
  List<FundModel> _bottom10Funds = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Top 10 Leaders, 1: Bottom 10 Relegation

  @override
  void initState() {
    super.initState();
    _loadLeagueData();
  }

  Future<void> _loadLeagueData() async {
    try {
      final backendFunds = await SupabaseFundsRepository().getFunds();
      final sortedDesc = List<FundModel>.from(backendFunds)
        ..sort((a, b) => b.ytdReturn.compareTo(a.ytdReturn));

      final sortedAsc = List<FundModel>.from(backendFunds)
        ..sort((a, b) => a.ytdReturn.compareTo(b.ytdReturn));

      if (mounted) {
        setState(() {
          _top10Funds = sortedDesc.take(10).toList();
          _bottom10Funds = sortedAsc.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final isAr = context.isArabic;

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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr('fundSupporterLeague'),
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
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
                  // Top Banner Title & Info with Standardized Clean Trend Icons
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedTab == 0
                            ? [const Color(0xFF0F3822), const Color(0xFF062013)]
                            : [const Color(0xFF450A0A), const Color(0xFF1F0404)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: _selectedTab == 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : AppColors.error.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_selectedTab == 0 ? const Color(0xFF10B981) : AppColors.error).withValues(alpha: 0.12),
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
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: (_selectedTab == 0 ? const Color(0xFF10B981) : AppColors.error).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                _selectedTab == 0 ? Icons.trending_up : Icons.trending_down,
                                color: _selectedTab == 0 ? const Color(0xFF10B981) : AppColors.error,
                                size: 20.r,
                              ),
                            ),
                            SizedBox(width: 10.w),
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
                        SizedBox(height: 8.h),
                        Text(
                          context.tr('fundSupporterLeagueSub'),
                          style: TextStyle(
                            color: _selectedTab == 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
                            fontSize: 11.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Segmented Tab Selector (Top 10 Leaders vs Bottom 10 Relegation)
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  context.tr('top10Leaders'),
                                  style: TextStyle(
                                    color: _selectedTab == 0 ? Colors.black : textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? AppColors.error : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  context.tr('bottom10Relegation'),
                                  style: TextStyle(
                                    color: _selectedTab == 1 ? Colors.white : textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // TOP 10 LEADERS TAB CONTENT
                  if (_selectedTab == 0) ...[
                    if (_top10Funds.length >= 3) _buildPodium(context),
                    SizedBox(height: 24.h),

                    Text(
                      context.tr('fullLeaguePoints'),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.h),

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

                        return _buildLeagueRow(context, fund, rank, movement, isTop: true);
                      },
                    ),
                  ],

                  // BOTTOM 10 RELEGATION TAB CONTENT
                  if (_selectedTab == 1) ...[
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'تضم هذه القائمة الصناديق الأكثر تراجعاً في السوق، وتعتبر فرصة ممتازة لمتابعة القيعان وإعادة التجميع'
                                  : 'This list highlights the most dipped funds, presenting potential buy-the-dip and rebalancing opportunities.',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 11.sp,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    Text(
                      context.tr('fullRelegationPoints'),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.h),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _bottom10Funds.length,
                      itemBuilder: (context, index) {
                        final fund = _bottom10Funds[index];
                        final rank = index + 1;

                        return _buildLeagueRow(context, fund, rank, -1, isTop: false);
                      },
                    ),
                  ],

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
        Expanded(child: _buildPodiumItem(context, second, 2, '🥈', const Color(0xFF94A3B8), 140.h)),
        SizedBox(width: 8.w),
        // 1st Place (Gold Leader)
        Expanded(child: _buildPodiumItem(context, first, 1, '🥇', const Color(0xFFF59E0B), 165.h)),
        SizedBox(width: 8.w),
        // 3rd Place (Bronze)
        Expanded(child: _buildPodiumItem(context, third, 3, '🥉', const Color(0xFFD97706), 125.h)),
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
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
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
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    nameText,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (abbrText != null) ...[
              SizedBox(height: 1.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '($abbrText)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            SizedBox(height: 4.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueRow(BuildContext context, FundModel fund, int rank, int movement, {required bool isTop}) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    final nameText = fund.displayNameOnly;
    final abbrText = fund.abbreviation;
    final ytdFormatted = fund.ytdReturn >= 0 ? '+${fund.ytdReturn}%' : '${fund.ytdReturn}%';
    final badgeBg = isTop
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : AppColors.error.withValues(alpha: 0.15);
    final badgeTextColor = isTop ? const Color(0xFF10B981) : AppColors.error;

    Widget movementBadge;
    if (isTop && movement > 0) {
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
    } else if (!isTop || movement < 0) {
      movementBadge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_drop_down, color: AppColors.error, size: 18.r),
          Text(
            '-1',
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
              color: isTop
                  ? (rank == 1
                      ? const Color(0xFFF59E0B)
                      : rank == 2
                          ? const Color(0xFF94A3B8)
                          : rank == 3
                              ? const Color(0xFFD97706)
                              : AppColors.primary.withValues(alpha: 0.15))
                  : AppColors.error.withValues(alpha: 0.15),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: isTop ? (rank <= 3 ? Colors.black : AppColors.primary) : AppColors.error,
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        nameText,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              ytdFormatted,
              style: TextStyle(
                color: badgeTextColor,
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
