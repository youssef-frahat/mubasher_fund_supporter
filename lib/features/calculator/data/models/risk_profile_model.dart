import 'package:flutter/material.dart';

enum InvestmentGoal {
  capitalPreservation, // حفظ رأس المال ضد التضخم
  balancedGrowth,      // نمو متوازن بعائد ممتاز
  highYield,           // أقصى ربح وتنمية (أسهم)
  islamicSharia,       // استثمار إسلامي 100%
  goldHedging,         // التحوط بالذهب والفضة
}

enum InvestmentDuration {
  shortTerm, // أقل من سنة
  mediumTerm,// 1 - 3 سنوات
  longTerm,  // أكثر من 3 سنوات
}

class PortfolioFundAllocation {
  final String fundName;
  final String categoryNameAr;
  final double percentage; // e.g. 40.0 for 40%
  final String badgeLabel;
  final Color categoryColor;

  PortfolioFundAllocation({
    required this.fundName,
    required this.categoryNameAr,
    required this.percentage,
    required this.badgeLabel,
    required this.categoryColor,
  });

  double getAllocatedAmount(double totalInvestmentAmount) {
    return (totalInvestmentAmount * percentage) / 100.0;
  }
}

class RiskAssessmentResult {
  final String riskCategory;          // منخفض المخاطرة، متوازن، نمو مرتفع، شريعة
  final double expectedRoiPercentage;   // متوسط العائد السنوي المتوقع للمحفظة المقترحة
  final String description;
  final List<PortfolioFundAllocation> recommendedPortfolioMix;

  RiskAssessmentResult({
    required this.riskCategory,
    required this.expectedRoiPercentage,
    required this.description,
    required this.recommendedPortfolioMix,
  });
}
