import 'package:flutter/material.dart';
import '../../../home/data/models/platform_feature.dart';

class FundModel {
  final String id;
  final String name;
  final String managerName;
  final double currentNav;
  final double ytdReturn;
  final double dailyChange;
  final String riskLevel; // e.g. "Low", "Medium", "High"
  final String category; // e.g. "Equity", "Fixed Income"
  final String? logoUrl;

  FundModel({
    required this.id,
    required this.name,
    required this.managerName,
    required this.currentNav,
    required this.ytdReturn,
    required this.dailyChange,
    required this.riskLevel,
    required this.category,
    this.logoUrl,
  });

  /// Convert to PlatformFeature for navigation to FundDetailsScreen
  PlatformFeature toPlatformFeature() {
    return PlatformFeature(
      id: id,
      title: name,
      subtitle: '$managerName | $category',
      icon: Icons.account_balance,
      accentColor: _categoryColor,
    );
  }

  Color get _categoryColor {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // Basic mock factory for now
  factory FundModel.mock(String id, String name, double ytd, {String category = "Equity", String riskLevel = "Medium"}) {
    return FundModel(
      id: id,
      name: name,
      managerName: "Mock Manager",
      currentNav: 150.25,
      ytdReturn: ytd,
      dailyChange: ytd / 10, // Mocked daily change
      riskLevel: riskLevel,
      category: category,
    );
  }
}

