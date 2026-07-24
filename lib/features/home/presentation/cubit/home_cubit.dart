import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../data/models/platform_feature.dart';
import '../../data/models/platform_metric.dart';
import '../../data/repositories/funds_repository.dart';

class HomeCubit extends Cubit<HomeState> {
  final FundsRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> loadData() async {
    // Show loading later if needed
    // emit(HomeLoading());

    final features = await repository.getFunds();

    final metrics = const [
      PlatformMetric(label: 'Active Funds', value: '142'),
      PlatformMetric(label: 'Daily NAV Updates', value: '98.6%'),
      PlatformMetric(label: 'Advisor Accounts', value: '1,248'),
      PlatformMetric(label: 'AI Insights', value: '24/7'),
    ];

    emit(HomeLoaded(features: features, metrics: metrics));
  }
}
