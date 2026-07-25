enum InvestmentGoal {
  capitalPreservation, // حفظ رأس المال ضد التضخم
  balancedGrowth,      // نمو متوازن بعائد معقول
  highYield,           // أقصى ربح ممكن (أسهم / مخاطرة)
  islamicSharia,       // استثمار شريعة إسلامية 100%
  goldHedging,         // التحوط بالذهب
}

enum InvestmentDuration {
  shortTerm, // أقل من سنة
  mediumTerm,// 1 - 3 سنوات
  longTerm,  // أكثر من 3 سنوات
}

class RiskAssessmentResult {
  final String riskCategory;        // منخفض المخاطرة، متوازن، نمو مرتفع، شريعة
  final double expectedRoiPercentage; // نسبة العائد المتوقع (مثلاً 24.5%)
  final String recommendedCategory;  // 'money_market', 'balanced', 'equity', 'islamic', 'gold'
  final String description;

  RiskAssessmentResult({
    required this.riskCategory,
    required this.expectedRoiPercentage,
    required this.recommendedCategory,
    required this.description,
  });
}
