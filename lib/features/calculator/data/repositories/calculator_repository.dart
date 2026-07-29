import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/risk_profile_model.dart';
import '../../../home/data/models/fund_model.dart';
import '../../../home/data/repositories/funds_repository.dart';

class CalculatorRepository {

  Future<List<FundModel>> getSponsoredBackendFunds({
    List<String> excludedFundNames = const [],
  }) async {
    final list = await SupabaseFundsRepository().getFunds();

    if (excludedFundNames.isEmpty) return list;

    final lowerExcluded = excludedFundNames.map((e) => e.trim().toLowerCase()).toSet();
    final filtered = list.where((f) => !lowerExcluded.contains(f.name.trim().toLowerCase())).toList();
    return filtered.isNotEmpty ? filtered : list;
  }

  /// Get Risk Assessment Profile directly from Supabase DB `funds` & `robo_advisor_configs` tables configured by Admin
  Future<RiskAssessmentResult> getDynamicRiskProfile({
    required InvestmentGoal goal,
    required InvestmentDuration duration,
  }) async {
    final defaultResult = calculateRiskProfile(goal: goal, duration: duration);
    final client = SupabaseService.client;
    if (client == null) return defaultResult;

    final goalKey = _getGoalKey(goal);
    try {
      // 1. First check if Admin has designated specific funds for this goalKey in funds table
      final recFunds = await client
          .from('funds')
          .select('*')
          .eq('is_recommended', true)
          .eq('recommended_goal_key', goalKey)
          .limit(3);

      if ((recFunds as List).isNotEmpty) {
        final List<PortfolioFundAllocation> mix = [];
        final double perFundPct = (100.0 / recFunds.length).roundToDouble();

        for (int i = 0; i < recFunds.length; i++) {
          final f = recFunds[i] as Map;
          final fundName = (f['name_ar'] ?? f['name'] ?? '').toString();
          final category = (f['category'] ?? 'عام').toString();

          Color color = const Color(0xFF10B981);
          if (i == 0) color = const Color(0xFFF59E0B);
          if (i == 1) color = const Color(0xFF3B82F6);
          if (i == 2) color = const Color(0xFF8B5CF6);

          mix.add(PortfolioFundAllocation(
            fundName: fundName,
            categoryNameAr: category,
            categoryNameEn: category,
            percentage: i == 0 ? (100.0 - (perFundPct * (recFunds.length - 1))) : perFundPct,
            badgeLabelAr: i == 0 ? 'موصى به إدارياً ⭐' : 'توصية المستشار 💡',
            badgeLabelEn: 'Admin Recommended',
            categoryColor: color,
          ));
        }

        if (mix.isNotEmpty) {
          return RiskAssessmentResult(
            riskCategoryAr: defaultResult.riskCategoryAr,
            riskCategoryEn: defaultResult.riskCategoryEn,
            expectedRoiPercentage: defaultResult.expectedRoiPercentage,
            descriptionAr: defaultResult.descriptionAr,
            descriptionEn: defaultResult.descriptionEn,
            recommendedPortfolioMix: mix,
          );
        }
      }

      // 2. Fallback to robo_advisor_configs table if no direct funds assigned
      final response = await client
          .from('robo_advisor_configs')
          .select('*')
          .eq('goal_key', goalKey)
          .maybeSingle();

      if (response != null) {
        final Map<String, dynamic> data = response;
        final String titleAr = data['goal_title_ar'] ?? defaultResult.riskCategoryAr;
        final double roi = (data['expected_roi'] as num?)?.toDouble() ?? defaultResult.expectedRoiPercentage;
        final String descAr = data['description_ar'] ?? defaultResult.descriptionAr;

        final fund1Name = data['fund1_name']?.toString() ?? '';
        final fund2Name = data['fund2_name']?.toString() ?? '';
        final fund3Name = data['fund3_name']?.toString() ?? '';

        final List<PortfolioFundAllocation> mix = [];

        if (fund1Name.isNotEmpty) {
          mix.add(PortfolioFundAllocation(
            fundName: fund1Name,
            categoryNameAr: data['fund1_category_ar']?.toString() ?? 'صناديق الذهب',
            categoryNameEn: 'Gold Funds',
            percentage: (data['fund1_percentage'] as num?)?.toDouble() ?? 50.0,
            badgeLabelAr: data['fund1_badge_ar']?.toString() ?? 'الملاذ الأول',
            badgeLabelEn: 'Primary Haven',
            categoryColor: const Color(0xFFF59E0B),
          ));
        }

        if (fund2Name.isNotEmpty) {
          mix.add(PortfolioFundAllocation(
            fundName: fund2Name,
            categoryNameAr: data['fund2_category_ar']?.toString() ?? 'معادن ومسبوكات',
            categoryNameEn: 'Metals',
            percentage: (data['fund2_percentage'] as num?)?.toDouble() ?? 30.0,
            badgeLabelAr: data['fund2_badge_ar']?.toString() ?? 'نمو مرتفع',
            badgeLabelEn: 'High Yield',
            categoryColor: const Color(0xFF3B82F6),
          ));
        }

        if (fund3Name.isNotEmpty) {
          mix.add(PortfolioFundAllocation(
            fundName: fund3Name,
            categoryNameAr: data['fund3_category_ar']?.toString() ?? 'أدوات مركبة',
            categoryNameEn: 'Derivatives',
            percentage: (data['fund3_percentage'] as num?)?.toDouble() ?? 20.0,
            badgeLabelAr: data['fund3_badge_ar']?.toString() ?? 'فرص مضاعفة',
            badgeLabelEn: 'Multiplied Growth',
            categoryColor: const Color(0xFF8B5CF6),
          ));
        }

        if (mix.isNotEmpty) {
          return RiskAssessmentResult(
            riskCategoryAr: titleAr,
            riskCategoryEn: defaultResult.riskCategoryEn,
            expectedRoiPercentage: roi,
            descriptionAr: descAr,
            descriptionEn: defaultResult.descriptionEn,
            recommendedPortfolioMix: mix,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Dynamic Robo-Advisor config notice: $e');
    }

    return defaultResult;
  }

  String _getGoalKey(InvestmentGoal goal) {
    switch (goal) {
      case InvestmentGoal.goldHedging:
        return 'goldHedging';
      case InvestmentGoal.islamicSharia:
        return 'islamicSharia';
      case InvestmentGoal.capitalPreservation:
        return 'capitalPreservation';
      case InvestmentGoal.balancedGrowth:
      case InvestmentGoal.highYield:
        return 'balancedGrowth';
    }
  }

  RiskAssessmentResult calculateRiskProfile({
    required InvestmentGoal goal,
    required InvestmentDuration duration,
  }) {
    if (goal == InvestmentGoal.islamicSharia) {
      return RiskAssessmentResult(
        riskCategoryAr: 'استثمار متوافق مع الشريعة الإسلامية',
        riskCategoryEn: 'Sharia Compliant Investment',
        expectedRoiPercentage: 24.0,
        descriptionAr: 'محفظة نموذجية إسلامية 100% موزعة بين المرابحة النقدية والأسهم النقية.',
        descriptionEn: '100% Sharia compliant portfolio split between Murabaha liquidity & pure stocks.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: 'صندوق فيصل الإسلامي للأسهم',
            categoryNameAr: 'أسهم شريعة',
            categoryNameEn: 'Sharia Equities',
            percentage: 45.0,
            badgeLabelAr: 'نمو شرعي',
            badgeLabelEn: 'Sharia Growth',
            categoryColor: const Color(0xFF059669),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق البركة الإسلامي اليومي',
            categoryNameAr: 'سيولة مرابحة',
            categoryNameEn: 'Murabaha Liquidity',
            percentage: 35.0,
            badgeLabelAr: 'أمان واستقرار',
            badgeLabelEn: 'Stable & Safe',
            categoryColor: const Color(0xFF10B981),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق الذهب أزموت الإسلامي',
            categoryNameAr: 'تحوط ذهبي',
            categoryNameEn: 'Gold Hedge',
            percentage: 20.0,
            badgeLabelAr: 'حفظ القوة الشرائية',
            badgeLabelEn: 'Wealth Preservation',
            categoryColor: const Color(0xFFF59E0B),
          ),
        ],
      );
    } else if (goal == InvestmentGoal.goldHedging) {
      return RiskAssessmentResult(
        riskCategoryAr: 'تحوط وحماية رأس المال (الذهب والفضة)',
        riskCategoryEn: 'Capital Hedging & Gold Protection',
        expectedRoiPercentage: 27.5,
        descriptionAr: 'محفظة مخصصة لحماية الأموال من موجات التضخم وانخفاض العملة.',
        descriptionEn: 'Specialized portfolio to protect wealth against inflation & currency drops.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: 'صندوق أزموت الذهب (Azimut Gold)',
            categoryNameAr: 'صناديق الذهب',
            categoryNameEn: 'Gold Funds',
            percentage: 50.0,
            badgeLabelAr: 'الملاذ الآمن الأول',
            badgeLabelEn: 'Safe Haven #1',
            categoryColor: const Color(0xFFF59E0B),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق إي جولد لسبائك الذهب',
            categoryNameAr: 'معادن ومسبوكات',
            categoryNameEn: 'Precious Metals',
            percentage: 30.0,
            badgeLabelAr: 'نمو مرتفع',
            badgeLabelEn: 'High Yield',
            categoryColor: const Color(0xFF3B82F6),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق بلتون للنمو الاستثماري',
            categoryNameAr: 'أدوات مركبة ومشتقات',
            categoryNameEn: 'Hybrid & Derivatives',
            percentage: 20.0,
            badgeLabelAr: 'فرص مضاعفة',
            badgeLabelEn: 'Multiplied Growth',
            categoryColor: const Color(0xFF8B5CF6),
          ),
        ],
      );
    } else if (goal == InvestmentGoal.capitalPreservation) {
      return RiskAssessmentResult(
        riskCategoryAr: 'أمان مرتفع وحفظ رأس المال',
        riskCategoryEn: 'High Safety & Capital Preservation',
        expectedRoiPercentage: 22.0,
        descriptionAr: 'محفظة عالية الأمان تركز على العائد اليومي التراكمي وأذون الخزانة.',
        descriptionEn: 'High safety portfolio focused on daily cumulative yield & T-Bills.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: 'صندوق البنك الأهلي الرابع اليومي',
            categoryNameAr: 'سيولة نقدية',
            categoryNameEn: 'Cash Liquidity',
            percentage: 60.0,
            badgeLabelAr: 'عائد يومي آمن',
            badgeLabelEn: 'Safe Daily Yield',
            categoryColor: const Color(0xFF10B981),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق أذون الخزانة المصرية',
            categoryNameAr: 'أدوات حكومية',
            categoryNameEn: 'Government T-Bills',
            percentage: 25.0,
            badgeLabelAr: 'ضمان حكومي',
            badgeLabelEn: 'Gov Guaranteed',
            categoryColor: const Color(0xFF6366F1),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق الذهب أزموت',
            categoryNameAr: 'تحوط ذهبي',
            categoryNameEn: 'Gold Hedge',
            percentage: 15.0,
            badgeLabelAr: 'حفظ القيمة',
            badgeLabelEn: 'Value Preservation',
            categoryColor: const Color(0xFFF59E0B),
          ),
        ],
      );
    } else {
      return RiskAssessmentResult(
        riskCategoryAr: 'نمو متوازن (المحفظة الذكية النموذجية)',
        riskCategoryEn: 'Balanced Growth (Model Smart Portfolio)',
        expectedRoiPercentage: 26.5,
        descriptionAr: 'محفظة متوازنة تجمع بين أمان السيولة، نمو الأسهم، وتحوط الذهب.',
        descriptionEn: 'Balanced portfolio combining liquidity safety, stock growth, & gold hedging.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: 'صندوق مباشر اليومي للسيولة',
            categoryNameAr: 'سيولة وتوفير',
            categoryNameEn: 'Liquidity & Savings',
            percentage: 40.0,
            badgeLabelAr: 'أمان وسحب فوري',
            badgeLabelEn: 'Instant Withdrawal',
            categoryColor: const Color(0xFF10B981),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق أزموت للذهب (Azimut Gold)',
            categoryNameAr: 'تحوط ضد التضخم',
            categoryNameEn: 'Inflation Hedge',
            percentage: 30.0,
            badgeLabelAr: 'استقرار الأصول',
            badgeLabelEn: 'Asset Stability',
            categoryColor: const Color(0xFFF59E0B),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق سي أي كابيتال للأسهم',
            categoryNameAr: 'أسهم ومستقبل',
            categoryNameEn: 'Equities & Future',
            percentage: 30.0,
            badgeLabelAr: 'نمو رأس المال',
            badgeLabelEn: 'Capital Growth',
            categoryColor: const Color(0xFF3B82F6),
          ),
        ],
      );
    }
  }
}
