import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../data/models/platform_feature.dart';
import '../../data/models/platform_metric.dart';
import '../../data/repositories/funds_repository.dart';
import '../../data/models/fund_model.dart';

class HomeCubit extends Cubit<HomeState> {
  final FundsRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> loadData() async {
    // Show loading later if needed
    // emit(HomeLoading());

    final features = await repository.getFunds();
    
    // Fetch new dashboard data in parallel
    final results = await Future.wait([
      repository.getRecommendedFunds(),
      repository.getTopPerformingFund(),
      repository.getRankedFunds(),
    ]);

    final recommendedFunds = results[0] as List<FundModel>;
    final topPerformingFund = results[1] as FundModel;
    final rankedFunds = results[2] as List<FundModel>;

    final metrics = const [
      PlatformMetric(label: 'Active Funds', value: '142'),
      PlatformMetric(label: 'Daily NAV Updates', value: '98.6%'),
      PlatformMetric(label: 'Advisor Accounts', value: '1,248'),
      PlatformMetric(label: 'AI Insights', value: '24/7'),
    ];

    emit(HomeLoaded(
      features: features, 
      metrics: metrics,
      recommendedFunds: recommendedFunds,
      topPerformingFund: topPerformingFund,
      rankedFunds: rankedFunds,
      aiInsight: "The Egyptian stock market is highly active today. Consider looking at Equity funds which are up 2.4% on average.",
    ));
  }
}
