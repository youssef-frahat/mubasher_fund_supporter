import 'package:flutter/material.dart';
import '../../../home/data/models/platform_feature.dart';

class FundModel {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String managerName;
  final double currentNav;
  final double ytdReturn;
  final double weeklyReturn;
  final double fourWeeksReturn;
  final double last12mReturn;
  final double dailyChange;
  final String riskLevel; // e.g. "Low", "Medium", "High"
  final String category; // e.g. "Equity", "MoneyMarket", "Gold", "Islamic"
  final String? subCategory;
  final String currency; // EGP, USD, EUR
  final String? inceptionDate;
  final double? initialValue;
  final String? logoUrl;
  final bool isRecommended;
  final bool isSponsored;
  final bool isTopPerforming;
  final int? rank;

  FundModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.managerName,
    required this.currentNav,
    required this.ytdReturn,
    this.weeklyReturn = 0.0,
    this.fourWeeksReturn = 0.0,
    this.last12mReturn = 0.0,
    this.dailyChange = 0.0,
    required this.riskLevel,
    required this.category,
    this.subCategory,
    this.currency = 'EGP',
    this.inceptionDate,
    this.initialValue,
    this.logoUrl,
    this.isRecommended = false,
    this.isSponsored = false,
    this.isTopPerforming = false,
    this.rank,
  });

  factory FundModel.fromMap(Map<String, dynamic> map) {
    return FundModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? map['name_ar'] ?? map['name_en'] ?? '',
      nameAr: map['name_ar'],
      nameEn: map['name_en'],
      managerName: map['manager_name'] ?? map['manager'] ?? 'مباشر كابيتال',
      currentNav: (map['current_nav'] as num?)?.toDouble() ?? 100.0,
      ytdReturn: (map['ytd_return'] as num?)?.toDouble() ?? 0.0,
      weeklyReturn: (map['weekly_return'] as num?)?.toDouble() ?? 0.0,
      fourWeeksReturn: (map['four_weeks_return'] as num?)?.toDouble() ?? 0.0,
      last12mReturn: (map['last_12m_return'] as num?)?.toDouble() ?? 0.0,
      dailyChange: (map['daily_change'] as num?)?.toDouble() ?? 0.0,
      riskLevel: map['risk_level'] ?? 'Medium',
      category: map['category'] ?? 'Equity',
      subCategory: map['sub_category'],
      currency: map['currency'] ?? 'EGP',
      inceptionDate: map['inception_date'],
      initialValue: (map['initial_value'] as num?)?.toDouble(),
      logoUrl: map['logo_url'],
      isRecommended: map['is_recommended'] ?? false,
      isSponsored: map['is_sponsored'] ?? false,
      isTopPerforming: map['is_top_performing'] ?? false,
      rank: map['rank'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'name_ar': nameAr ?? name,
      'name_en': nameEn,
      'manager_name': managerName,
      'manager': managerName,
      'current_nav': currentNav,
      'ytd_return': ytdReturn,
      'weekly_return': weeklyReturn,
      'four_weeks_return': fourWeeksReturn,
      'last_12m_return': last12mReturn,
      'daily_change': dailyChange,
      'risk_level': riskLevel,
      'category': category,
      'sub_category': subCategory,
      'currency': currency,
      'inception_date': inceptionDate,
      'initial_value': initialValue,
      'logo_url': logoUrl,
      'is_recommended': isRecommended,
      'is_sponsored': isSponsored,
      'is_top_performing': isTopPerforming,
      'rank': rank,
    };
  }

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

  factory FundModel.mock(String id, String name, double ytd, {String category = "Equity", String riskLevel = "Medium"}) {
    return FundModel(
      id: id,
      name: name,
      managerName: "مباشر كابيتال",
      currentNav: 150.25,
      ytdReturn: ytd,
      dailyChange: ytd / 10,
      riskLevel: riskLevel,
      category: category,
    );
  }
}
