import 'package:flutter/material.dart';

enum FundCategory {
  moneyMarket,   // نقدية وسيولة يومية
  equity,        // أسهم (مثل بلتون وسي أي كابيتال)
  islamic,       // إسلامية شريعة
  gold,          // ذهب
  silver,        // فضة
  usd,           // عملات أجنبية ودولار
  treasuryBills, // أذون وسندات خزانة
  derivatives,   // مشتقات مالية وأدوات مركبة
}

extension FundCategoryExtension on FundCategory {
  String get displayNameAr {
    switch (this) {
      case FundCategory.moneyMarket:
        return 'نقدية وسيولة يومية';
      case FundCategory.equity:
        return 'أسهم ومحفظة استثمارية';
      case FundCategory.islamic:
        return 'استثمار إسلامي (شريعة)';
      case FundCategory.gold:
        return 'صناديق الذهب';
      case FundCategory.silver:
        return 'صناديق الفضة';
      case FundCategory.usd:
        return 'صناديق الدولار والعملات';
      case FundCategory.treasuryBills:
        return 'أذون وسندات خزانة';
      case FundCategory.derivatives:
        return 'مشتقات وأدوات مركبة';
    }
  }

  String get displayNameEn {
    switch (this) {
      case FundCategory.moneyMarket:
        return 'Money Market & Daily Liquidity';
      case FundCategory.equity:
        return 'Equities & Stocks';
      case FundCategory.islamic:
        return 'Sharia Compliant (Islamic)';
      case FundCategory.gold:
        return 'Gold Funds';
      case FundCategory.silver:
        return 'Silver Funds';
      case FundCategory.usd:
        return 'USD & Foreign Currency';
      case FundCategory.treasuryBills:
        return 'Treasury Bills & Bonds';
      case FundCategory.derivatives:
        return 'Derivatives & Hybrid Instruments';
    }
  }

  String getDisplayName(bool isAr) => isAr ? displayNameAr : displayNameEn;

  Color get color {
    switch (this) {
      case FundCategory.moneyMarket:
        return const Color(0xFF10B981); // Emerald Green
      case FundCategory.equity:
        return const Color(0xFF3B82F6); // Blue
      case FundCategory.islamic:
        return const Color(0xFF059669); // Dark Green
      case FundCategory.gold:
        return const Color(0xFFF59E0B); // Gold
      case FundCategory.silver:
        return const Color(0xFF94A3B8); // Silver Slate
      case FundCategory.usd:
        return const Color(0xFF10B981); // USD Green
      case FundCategory.treasuryBills:
        return const Color(0xFF6366F1); // Indigo
      case FundCategory.derivatives:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  IconData get icon {
    switch (this) {
      case FundCategory.moneyMarket:
        return Icons.attach_money;
      case FundCategory.equity:
        return Icons.show_chart;
      case FundCategory.islamic:
        return Icons.brightness_3;
      case FundCategory.gold:
        return Icons.monetization_on;
      case FundCategory.silver:
        return Icons.shield;
      case FundCategory.usd:
        return Icons.currency_exchange;
      case FundCategory.treasuryBills:
        return Icons.account_balance;
      case FundCategory.derivatives:
        return Icons.bolt;
    }
  }
}

class PortfolioItem {
  final String id;
  final String fundId;
  final String fundName;
  final FundCategory category;
  final double units;
  final double purchasePrice;
  final double currentNav;
  final DateTime purchaseDate;

  PortfolioItem({
    required this.id,
    required this.fundId,
    required this.fundName,
    required this.category,
    required this.units,
    required this.purchasePrice,
    required this.currentNav,
    required this.purchaseDate,
  });

  double get totalCost => units * purchasePrice;
  double get currentValue => units * currentNav;
  double get profitLoss => currentValue - totalCost;
  double get profitLossPercentage => totalCost > 0 ? (profitLoss / totalCost) * 100 : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fundId': fundId,
      'fundName': fundName,
      'category': category.name,
      'units': units,
      'purchasePrice': purchasePrice,
      'currentNav': currentNav,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'],
      fundId: json['fundId'],
      fundName: json['fundName'],
      category: FundCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => FundCategory.moneyMarket,
      ),
      units: (json['units'] as num).toDouble(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      currentNav: (json['currentNav'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
    );
  }
}

class PortfolioHealthSummary {
  final int score; // 0 - 100
  final Color scoreColor; // Red (<50), Yellow (50-85), Green (>85)
  final String ratingTextAr;
  final String ratingTextEn;
  final Map<FundCategory, double> categoryPercentages;
  final double totalPortfolioValue;
  final double totalProfitLoss;
  final double totalProfitLossPercentage;

  String getRatingText(bool isAr) => isAr ? ratingTextAr : ratingTextEn;
  String get ratingText => ratingTextAr;

  PortfolioHealthSummary({
    required this.score,
    required this.scoreColor,
    required this.ratingTextAr,
    required this.ratingTextEn,
    required this.categoryPercentages,
    required this.totalPortfolioValue,
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
  });
}
