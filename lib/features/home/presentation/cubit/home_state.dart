import 'package:flutter/material.dart';
import '../../data/models/platform_feature.dart';
import '../../data/models/platform_metric.dart';

import '../../data/models/fund_model.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoaded extends HomeState {
  final List<PlatformFeature> features;
  final List<PlatformMetric> metrics;
  
  // New State variables
  final List<FundModel> recommendedFunds;
  final FundModel topPerformingFund;
  final List<FundModel> rankedFunds;
  final String aiInsight;

  HomeLoaded({
    required this.features, 
    required this.metrics,
    required this.recommendedFunds,
    required this.topPerformingFund,
    required this.rankedFunds,
    required this.aiInsight,
  });
}
