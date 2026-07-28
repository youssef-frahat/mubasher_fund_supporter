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
  final String categoryNameEn;
  final double percentage; // e.g. 40.0 for 40%
  final String badgeLabelAr;
  final String badgeLabelEn;
  final Color categoryColor;

  PortfolioFundAllocation({
    required this.fundName,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.percentage,
    required this.badgeLabelAr,
    required this.badgeLabelEn,
    required this.categoryColor,
  });

  String getCategoryName(bool isAr) => isAr ? categoryNameAr : categoryNameEn;
  String getBadgeLabel(bool isAr) => isAr ? badgeLabelAr : badgeLabelEn;

  double getAllocatedAmount(double totalInvestmentAmount) {
    return (totalInvestmentAmount * percentage) / 100.0;
  }
}

class RiskAssessmentResult {
  final String riskCategoryAr;
  final String riskCategoryEn;
  final double expectedRoiPercentage;
  final String descriptionAr;
  final String descriptionEn;
  final List<PortfolioFundAllocation> recommendedPortfolioMix;

  RiskAssessmentResult({
    required this.riskCategoryAr,
    required this.riskCategoryEn,
    required this.expectedRoiPercentage,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.recommendedPortfolioMix,
  });

  String getRiskCategory(bool isAr) => isAr ? riskCategoryAr : riskCategoryEn;
  String getDescription(bool isAr) => isAr ? descriptionAr : descriptionEn;

  String get riskCategory => riskCategoryAr;
  String get description => descriptionAr;
}
