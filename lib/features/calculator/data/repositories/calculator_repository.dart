import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../home/data/models/fund_model.dart';
import '../models/risk_profile_model.dart';

class CalculatorRepository {
  final SupabaseClient? _supabaseClient;

  CalculatorRepository([SupabaseClient? supabaseClient])
      : _supabaseClient = supabaseClient ?? SupabaseService.client;

  /// Fetch sponsored/featured funds per category directly from Supabase backend
  Future<List<FundModel>> getSponsoredBackendFunds() async {
    final client = _supabaseClient ?? SupabaseService.client;
    if (client == null) return [];

    try {
      final response = await client
          .from('funds')
          .select()
          .order('is_recommended', ascending: false)
          .order('ytd_return', ascending: false);

      final data = response as List<dynamic>;
      return data.map((e) => FundModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching backend sponsored funds: $e');
      return [];
    }
  }

  Future<RiskAssessmentResult> calculateRiskProfileAsync({
    required InvestmentGoal goal,
    required InvestmentDuration duration,
  }) async {
    final backendFunds = await getSponsoredBackendFunds();
    return calculateRiskProfile(goal: goal, duration: duration, backendFunds: backendFunds);
  }

  RiskAssessmentResult calculateRiskProfile({
    required InvestmentGoal goal,
    required InvestmentDuration duration,
    List<FundModel>? backendFunds,
  }) {
    // Helper to find best sponsored fund by category from backend
    String getFundName(String categoryKey, String defaultName) {
      if (backendFunds != null && backendFunds.isNotEmpty) {
        final match = backendFunds.where((f) =>
            f.category.toLowerCase().contains(categoryKey.toLowerCase()) ||
            f.riskLevel.toLowerCase().contains(categoryKey.toLowerCase()) ||
            f.name.contains(categoryKey)).firstOrNull;
        if (match != null) return match.name;
      }
      return defaultName;
    }

    if (goal == InvestmentGoal.islamicSharia) {
      return RiskAssessmentResult(
        riskCategory: 'استثمار متوافق مع الشريعة الإسلامية',
        expectedRoiPercentage: 24.8,
        description: 'محفظة نموذجية إسلامية 100% موزعة بين المرابحة النقدية والأسهم النقية والذهب معتمدة من الباك إند.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: getFundName('Islamic', 'صندوق بنك فيصل الإسلامي المصري الأول'),
            categoryNameAr: 'أسهم شريعة',
            percentage: 45.0,
            badgeLabel: 'نمو شرعي',
            categoryColor: const Color(0xFF059669),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('Money', 'صندوق بنك البركة مصر (إسلامي)'),
            categoryNameAr: 'سيولة مرابحة',
            percentage: 35.0,
            badgeLabel: 'أمان واستقرار',
            categoryColor: const Color(0xFF10B981),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('Gold', 'صندوق أزيموت الذهب (AZG)'),
            categoryNameAr: 'تحوط ذهبي',
            percentage: 20.0,
            badgeLabel: 'حفظ القوة الشرائية',
            categoryColor: const Color(0xFFF59E0B),
          ),
        ],
      );
    } else if (goal == InvestmentGoal.goldHedging) {
      return RiskAssessmentResult(
        riskCategory: 'تحوط وحماية رأس المال (الذهب والسيولة)',
        expectedRoiPercentage: 27.5,
        description: 'محفظة مخصصة لحماية الأموال من موجات التضخم وانخفاض العملة معتمدة من الباك إند.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: getFundName('Gold', 'صندوق أزيموت الذهب (AZG)'),
            categoryNameAr: 'صناديق الذهب',
            percentage: 50.0,
            badgeLabel: 'الملاذ الآمن الأول',
            categoryColor: const Color(0xFFF59E0B),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('Sabayek', 'صندوق سبائك الذهب'),
            categoryNameAr: 'معادن نادرة',
            percentage: 25.0,
            badgeLabel: 'تحوط معدني',
            categoryColor: const Color(0xFF94A3B8),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('Money', 'صندوق كريدي أجريكول مصر الثالث'),
            categoryNameAr: 'سيولة نقدية',
            percentage: 25.0,
            badgeLabel: 'سيولة وسحب فوري',
            categoryColor: const Color(0xFF10B981),
          ),
        ],
      );
    } else if (goal == InvestmentGoal.highYield && duration == InvestmentDuration.longTerm) {
      return RiskAssessmentResult(
        riskCategory: 'عائد نمو متسارع (أسهم ومكاسب عالي)',
        expectedRoiPercentage: 32.5,
        description: 'محفظة ديناميكية تركز على الأسهم المصرية الواعدة مع حصة تحوطية معتمدة من الباك إند.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: getFundName('Equity', 'صندوق كريدي أجريكول مصر الأول'),
            categoryNameAr: 'أسهم واعدة',
            percentage: 50.0,
            badgeLabel: 'عائد نمو مرتفع',
            categoryColor: const Color(0xFF3B82F6),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('Istithmar', 'صندوق CIB الثاني (استثمار)'),
            categoryNameAr: 'نمو أسهم',
            percentage: 30.0,
            badgeLabel: 'فرص مضاعفة',
            categoryColor: const Color(0xFF8B5CF6),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('Gold', 'صندوق أزيموت الذهب (AZG)'),
            categoryNameAr: 'تحوط ذهبي',
            percentage: 20.0,
            badgeLabel: 'توازن المحفظة',
            categoryColor: const Color(0xFFF59E0B),
          ),
        ],
      );
    } else if (goal == InvestmentGoal.capitalPreservation) {
      return RiskAssessmentResult(
        riskCategory: 'أمان مرتفع وحفظ رأس المال',
        expectedRoiPercentage: 21.5,
        description: 'محفظة عالية الأمان تركز على العائد اليومي التراكمي والنقدية آمنة العائد من الباك إند.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: getFundName('National', 'صندوق البنك الأهلي المصري الرابع'),
            categoryNameAr: 'سيولة نقدية',
            percentage: 60.0,
            badgeLabel: 'عائد يومي آمن',
            categoryColor: const Color(0xFF10B981),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('QNB', 'صندوق QNB الأهلي (ثمار)'),
            categoryNameAr: 'أدوات نقدية',
            percentage: 25.0,
            badgeLabel: 'استقرار مالي',
            categoryColor: const Color(0xFF6366F1),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('Gold', 'صندوق أزيموت الذهب (AZG)'),
            categoryNameAr: 'تحوط ذهبي',
            percentage: 15.0,
            badgeLabel: 'حفظ القيمة',
            categoryColor: const Color(0xFFF59E0B),
          ),
        ],
      );
    } else {
      return RiskAssessmentResult(
        riskCategory: 'نمو متوازن (المحفظة الذكية النموذجية)',
        expectedRoiPercentage: 25.8,
        description: 'محفظة متوازنة تجمع بين أمان السيولة، نمو الأسهم، وتحوط الذهب من الباك إند.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: getFundName('Credit', 'صندوق كريدي أجريكول مصر الثالث'),
            categoryNameAr: 'سيولة وتوفير',
            percentage: 40.0,
            badgeLabel: 'أمان وسحب فوري',
            categoryColor: const Color(0xFF10B981),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('Gold', 'صندوق أزيموت الذهب (AZG)'),
            categoryNameAr: 'تحوط ضد التضخم',
            percentage: 30.0,
            badgeLabel: 'استقرار الأصول',
            categoryColor: const Color(0xFFF59E0B),
          ),
          PortfolioFundAllocation(
            fundName: getFundName('Mubasher', 'صندوق مباشر للأسهم المصرية (نمو)'),
            categoryNameAr: 'أسهم ومستقبل',
            percentage: 30.0,
            badgeLabel: 'نمو رأس المال',
            categoryColor: const Color(0xFF3B82F6),
          ),
        ],
      );
    }
  }
}
