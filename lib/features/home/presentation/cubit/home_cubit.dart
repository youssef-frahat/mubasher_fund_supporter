import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../data/models/platform_metric.dart';
import '../../data/repositories/funds_repository.dart';
import '../../data/models/fund_model.dart';

class HomeCubit extends Cubit<HomeState> {
  final FundsRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> loadData() async {
    final features = await repository.getPlatformFeatures();
    
    // Fetch dashboard data in parallel
    final results = await Future.wait([
      repository.getFunds(),
      repository.getRecommendedFunds(),
      repository.getTopPerformingFund(),
      repository.getRankedFunds(),
    ]);

    final allFunds = results[0] as List<FundModel>;
    final recommendedFunds = results[1] as List<FundModel>;
    final topPerformingFund = results[2] as FundModel;
    final rankedFunds = results[3] as List<FundModel>;

    // Dynamic count of active funds from Supabase database
    final activeCount = allFunds.length.toString();

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
  }
}
