import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../data/models/platform_metric.dart';
import '../../data/repositories/funds_repository.dart';
import '../../data/models/fund_model.dart';

class HomeCubit extends Cubit<HomeState> {
  final FundsRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> loadData() async {
    try {
      final features = await repository.getPlatformFeatures();
      
      // Fetch dashboard data in parallel with timeout
      final results = await Future.wait([
        repository.getFunds(),
        repository.getRecommendedFunds(),
        repository.getTopPerformingFund(),
        repository.getRankedFunds(),
      ]).timeout(const Duration(seconds: 6));

      final allFunds = results[0] as List<FundModel>;
      final recommendedFunds = results[1] as List<FundModel>;
      final topPerformingFund = results[2] as FundModel;
      final rankedFunds = results[3] as List<FundModel>;

      final activeCount = allFunds.isNotEmpty ? allFunds.length.toString() : '3';

      final metrics = [
        PlatformMetric(label: 'Active Funds', value: activeCount),
        const PlatformMetric(label: 'Daily NAV Updates', value: '98.6%'),
        const PlatformMetric(label: 'Advisor Accounts', value: '1,248'),
        const PlatformMetric(label: 'AI Insights', value: '24/7'),
      ];

      emit(HomeLoaded(
        features: features, 
        metrics: metrics,
        recommendedFunds: recommendedFunds,
        topPerformingFund: topPerformingFund,
        rankedFunds: rankedFunds,
        aiInsight: "أسواق الأسهم والصناديق تشهد نشاطاً كبيراً اليوم. نوصي بمراجعة صناديق الأسهم والنقدية المنوعة.",
      ));
    } catch (e, stack) {
      debugPrint('⚠️ Error loading home data: $e\n$stack');
      final fallbackFunds = [
        FundModel(
          id: '1',
          name: 'صندوق مباشر للأسهم المصرية (نمو)',
          managerName: 'مباشر كابيتال',
          currentNav: 185.50,
          ytdReturn: 24.80,
          dailyChange: 1.25,
          riskLevel: 'High',
          category: 'Equity',
          isRecommended: true,
          isTopPerforming: true,
        ),
        FundModel(
          id: '2',
          name: 'صندوق أزيموت النقدية اليومية',
          managerName: 'أزيموت مصر',
          currentNav: 12.34,
          ytdReturn: 18.50,
          dailyChange: 0.05,
          riskLevel: 'Low',
          category: 'MoneyMarket',
          isRecommended: true,
        ),
        FundModel(
          id: '3',
          name: 'صندوق أزيموت الذهب (AZG)',
          managerName: 'أزيموت مصر',
          currentNav: 48.75,
          ytdReturn: 32.10,
          dailyChange: -0.40,
          riskLevel: 'Medium',
          category: 'Gold',
          isRecommended: true,
        ),
      ];

      emit(HomeLoaded(
        features: fallbackFunds.map((f) => f.toPlatformFeature()).toList(),
        metrics: [
          PlatformMetric(label: 'Active Funds', value: fallbackFunds.length.toString()),
          const PlatformMetric(label: 'Daily NAV Updates', value: '98.6%'),
          const PlatformMetric(label: 'Advisor Accounts', value: '1,248'),
          const PlatformMetric(label: 'AI Insights', value: '24/7'),
        ],
        recommendedFunds: fallbackFunds,
        topPerformingFund: fallbackFunds.first,
        rankedFunds: fallbackFunds,
        aiInsight: "أسواق الأسهم والصناديق تشهد نشاطاً كبيراً اليوم. نوصي بمراجعة صناديق الأسهم والنقدية المنوعة.",
      ));
    }
  }
}
