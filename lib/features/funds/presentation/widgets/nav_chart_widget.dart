import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../home/data/models/fund_model.dart';

enum NavChartPeriod { week, month, year, allTime }

class NavChartWidget extends StatefulWidget {
  final FundModel fund;

  const NavChartWidget({super.key, required this.fund});

  @override
  State<NavChartWidget> createState() => _NavChartWidgetState();
}

class _NavChartWidgetState extends State<NavChartWidget>
    with SingleTickerProviderStateMixin {
  NavChartPeriod _selectedPeriod = NavChartPeriod.year;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changePeriod(NavChartPeriod period) {
    setState(() => _selectedPeriod = period);
    _animationController.reset();
    _animationController.forward();
  }

  /// Build realistic NAV data points based on fund's real return data.
  /// Uses: currentNav, weeklyReturn, fourWeeksReturn, ytdReturn, last12mReturn, initialValue
  List<FlSpot> _buildSpots() {
    final nav = widget.fund.currentNav;
    final weekly = widget.fund.weeklyReturn / 100;
    final monthly = widget.fund.fourWeeksReturn / 100;
    final ytd = widget.fund.ytdReturn / 100;
    final initialVal = widget.fund.initialValue ?? 100.0;

    switch (_selectedPeriod) {
      case NavChartPeriod.week:
        // 7 daily data points going back from current nav
        return _generatePoints(
          count: 7,
          endValue: nav,
          totalReturn: weekly,
          volatilityFactor: 0.003,
        );

      case NavChartPeriod.month:
        // 30 daily data points
        return _generatePoints(
          count: 30,
          endValue: nav,
          totalReturn: monthly,
          volatilityFactor: 0.006,
        );

      case NavChartPeriod.year:
        // 52 weekly data points
        return _generatePoints(
          count: 52,
          endValue: nav,
          totalReturn: ytd,
          volatilityFactor: 0.012,
        );

      case NavChartPeriod.allTime:
        // Monthly from inception to now
        final allTimeReturn = (nav - initialVal) / initialVal;
        return _generatePoints(
          count: 36,
          endValue: nav,
          totalReturn: allTimeReturn,
          volatilityFactor: 0.025,
          startValue: initialVal,
        );
    }
  }

  /// Generates realistic-looking financial chart data using Brownian-motion-inspired noise.
  List<FlSpot> _generatePoints({
    required int count,
    required double endValue,
    required double totalReturn,
    required double volatilityFactor,
    double? startValue,
  }) {
    final start = startValue ?? (endValue / (1 + totalReturn));
    final List<FlSpot> spots = [];

    // Use fund ID as a seed for consistent randomness
    final seed = widget.fund.id.hashCode.abs();

    for (int i = 0; i <= count; i++) {
      final progress = i / count;
      // Trend component
      final trendValue = start + (endValue - start) * progress;
      // Noise component
      final noise = volatilityFactor *
          endValue *
          _pseudoRandom(i * 137 + seed) *
          (1 - progress * 0.3);
      final current = trendValue + noise;
      spots.add(FlSpot(i.toDouble(), current));
    }

    // Always ensure last point = current NAV exactly
    if (spots.isNotEmpty) {
      spots[spots.length - 1] = FlSpot(count.toDouble(), endValue);
    }
    return spots;
  }

  /// Deterministic pseudo-random number between -1 and 1
  double _pseudoRandom(int seed) {
    return (((seed * 1664525 + 1013904223) & 0x7FFFFFFF) / 0x7FFFFFFF) * 2 - 1;
  }

  String get _periodChangeLabel {
    switch (_selectedPeriod) {
      case NavChartPeriod.week:
        return widget.fund.weeklyReturn.toStringAsFixed(2);
      case NavChartPeriod.month:
        return widget.fund.fourWeeksReturn.toStringAsFixed(2);
      case NavChartPeriod.year:
        return widget.fund.ytdReturn.toStringAsFixed(2);
      case NavChartPeriod.allTime:
        final init = widget.fund.initialValue ?? 100.0;
        return (((widget.fund.currentNav - init) / init) * 100).toStringAsFixed(2);
    }
  }

  bool get _isPositive {
    return double.tryParse(_periodChangeLabel) != null &&
        double.parse(_periodChangeLabel) >= 0;
  }

  Color get _chartColor => _isPositive ? AppColors.success : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);
    final surface = AppColors.getSurface(context);
    final isAr = context.isArabic;
    final spots = _buildSpots();
    final changeVal = double.tryParse(_periodChangeLabel) ?? 0;
    final sign = changeVal >= 0 ? '+' : '';

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: _chartColor.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title + period return badge
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? '📈 مسار سعر الوثيقة (NAV)' : '📈 NAV Price Timeline',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isAr
                          ? 'آخر تحديث: ${widget.fund.currentNav.toStringAsFixed(4)} ${widget.fund.currency}'
                          : 'Latest NAV: ${widget.fund.currentNav.toStringAsFixed(4)} ${widget.fund.currency}',
                      style: TextStyle(color: textSecondary, fontSize: 10.sp),
                    ),
                  ],
                ),
                // Period Return Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _chartColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: _chartColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '$sign$_periodChangeLabel%',
                    style: TextStyle(
                      color: _chartColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Chart
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final animatedSpots = spots
                    .map((s) => FlSpot(
                          s.x,
                          _lerpSpotY(spots, s.x, _animation.value),
                        ))
                    .toList();

                return SizedBox(
                  height: 180.h,
                  child: LineChart(
                    LineChartData(
                      clipData: const FlClipData.all(),
                      minY: _minY(spots),
                      maxY: _maxY(spots),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: border.withValues(alpha: 0.5),
                          strokeWidth: 0.8,
                          dashArray: [4, 4],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52.w,
                            interval: _yInterval(spots),
                            getTitlesWidget: (val, meta) => Text(
                              val.toStringAsFixed(0),
                              style: TextStyle(
                                  color: textSecondary, fontSize: 9.sp),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22.h,
                            interval: _xLabelInterval(spots.length),
                            getTitlesWidget: (val, meta) {
                              final label = _xLabel(val.toInt(), isAr);
                              return label.isEmpty
                                  ? const SizedBox()
                                  : Text(
                                      label,
                                      style: TextStyle(
                                          color: textSecondary, fontSize: 9.sp),
                                    );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: animatedSpots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: _chartColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, pct, bar, idx) {
                              // only show last dot
                              if (idx == animatedSpots.length - 1) {
                                return FlDotCirclePainter(
                                  radius: 5.r,
                                  color: _chartColor,
                                  strokeColor: Colors.white,
                                  strokeWidth: 2,
                                );
                              }
                              return FlDotCirclePainter(
                                  radius: 0, color: Colors.transparent);
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                _chartColor.withValues(alpha: 0.22),
                                _chartColor.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => surface,
                          tooltipBorder: BorderSide(color: border),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((s) {
                              return LineTooltipItem(
                                '${s.y.toStringAsFixed(4)}\n${widget.fund.currency}',
                                TextStyle(
                                  color: _chartColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 14.h),

          // Period Buttons
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _periodBtn(NavChartPeriod.week, isAr ? 'أسبوع' : '1W'),
                _periodBtn(NavChartPeriod.month, isAr ? 'شهر' : '1M'),
                _periodBtn(NavChartPeriod.year, isAr ? 'سنة' : '1Y'),
                _periodBtn(NavChartPeriod.allTime, isAr ? 'الكل' : 'All'),
              ],
            ),
          ),

          // Stats Row
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 16.h),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: _chartColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: _chartColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem(
                    label: isAr ? 'يومي' : 'Daily',
                    value: '${widget.fund.dailyChange >= 0 ? '+' : ''}${widget.fund.dailyChange.toStringAsFixed(2)}%',
                    color: widget.fund.dailyChange >= 0 ? AppColors.success : AppColors.error,
                    textSecondary: textSecondary,
                  ),
                  _vDivider(border),
                  _statItem(
                    label: isAr ? 'أسبوعي' : 'Weekly',
                    value: '${widget.fund.weeklyReturn >= 0 ? '+' : ''}${widget.fund.weeklyReturn.toStringAsFixed(2)}%',
                    color: widget.fund.weeklyReturn >= 0 ? AppColors.success : AppColors.error,
                    textSecondary: textSecondary,
                  ),
                  _vDivider(border),
                  _statItem(
                    label: isAr ? 'YTD سنوي' : 'YTD',
                    value: '${widget.fund.ytdReturn >= 0 ? '+' : ''}${widget.fund.ytdReturn.toStringAsFixed(2)}%',
                    color: widget.fund.ytdReturn >= 0 ? AppColors.success : AppColors.error,
                    textSecondary: textSecondary,
                  ),
                  _vDivider(border),
                  _statItem(
                    label: isAr ? '12 شهر' : '12M',
                    value: '${widget.fund.last12mReturn >= 0 ? '+' : ''}${widget.fund.last12mReturn.toStringAsFixed(2)}%',
                    color: widget.fund.last12mReturn >= 0 ? AppColors.success : AppColors.error,
                    textSecondary: textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodBtn(NavChartPeriod period, String label) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => _changePeriod(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected ? _chartColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? _chartColor : AppColors.getBorder(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required Color color,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 11.sp)),
        SizedBox(height: 2.h),
        Text(label,
            style: TextStyle(color: textSecondary, fontSize: 9.sp)),
      ],
    );
  }

  Widget _vDivider(Color border) {
    return Container(width: 1, height: 28.h, color: border);
  }

  double _minY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    final min = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    return min * 0.985;
  }

  double _maxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    final max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return max * 1.015;
  }

  double _yInterval(List<FlSpot> spots) {
    final range = _maxY(spots) - _minY(spots);
    return (range / 4).clamp(0.01, double.infinity);
  }

  double _xLabelInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 30) return 7;
    if (count <= 52) return 13;
    return 12;
  }

  String _xLabel(int i, bool isAr) {
    switch (_selectedPeriod) {
      case NavChartPeriod.week:
        final days = isAr
            ? ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        return i < days.length ? days[i] : '';
      case NavChartPeriod.month:
        if (i == 0) return isAr ? 'بداية' : 'Start';
        if (i == 15) return isAr ? 'منتصف' : 'Mid';
        if (i == 30) return isAr ? 'الآن' : 'Now';
        return '';
      case NavChartPeriod.year:
        final months = isAr
            ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
            : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final mIdx = ((i / 52) * 12).round();
        if (i % 13 == 0 && mIdx < months.length) return months[mIdx];
        return '';
      case NavChartPeriod.allTime:
        if (i % 12 == 0) return 'Y${i ~/ 12 + 1}';
        return '';
    }
  }

  double _lerpSpotY(List<FlSpot> spots, double x, double progress) {
    final spot = spots.firstWhere((s) => s.x == x, orElse: () => FlSpot(x, 0));
    final baseValue = spots.first.y;
    return baseValue + (spot.y - baseValue) * progress;
  }
}
