import 'package:flutter/material.dart';
import '../../data/models/platform_feature.dart';
import '../../data/models/platform_metric.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoaded extends HomeState {
  final List<PlatformFeature> features;
  final List<PlatformMetric> metrics;

  HomeLoaded({required this.features, required this.metrics});
}
