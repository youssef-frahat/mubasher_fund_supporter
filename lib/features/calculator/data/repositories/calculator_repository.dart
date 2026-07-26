import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/risk_profile_model.dart';
import '../../../home/data/models/fund_model.dart';
import '../../../home/data/repositories/funds_repository.dart';

class CalculatorRepository {
  // ignore: unused_field
  final SupabaseClient? _supabaseClient;

  CalculatorRepository({this._supabaseClient});

  Future<List<FundModel>> getSponsoredBackendFunds() async {
    return await SupabaseFundsRepository().getFunds();
  }

  RiskAssessmentResult calculateRiskProfile({
    required InvestmentGoal goal,
    required InvestmentDuration duration,
  }) {
    if (goal == InvestmentGoal.islamicSharia) {
      return RiskAssessmentResult(
        riskCategory: 'استثمار متوافق مع الشريعة الإسلامية',
        expectedRoiPercentage: 24.0,
        description: 'محفظة نموذجية إسلامية 100% موزعة بين المرابحة النقدية والأسهم النقية.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: 'صندوق فيصل الإسلامي للأسهم',
            categoryNameAr: 'أسهم شريعة',
            percentage: 45.0,
            badgeLabel: 'نمو شرعي',
            categoryColor: const Color(0xFF059669),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق البركة الإسلامي اليومي',
            categoryNameAr: 'سيولة مرابحة',
            percentage: 35.0,
            badgeLabel: 'أمان واستقرار',
            categoryColor: const Color(0xFF10B981),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق الذهب أزموت الإسلامي',
            categoryNameAr: 'تحوط ذهبي',
            percentage: 20.0,
            badgeLabel: 'حفظ القوة الشرائية',
            categoryColor: const Color(0xFFF59E0B),
          ),
        ],
      );
    } else if (goal == InvestmentGoal.goldHedging) {
      return RiskAssessmentResult(
        riskCategory: 'تحوط وحماية رأس المال (الذهب والفضة)',
        expectedRoiPercentage: 27.5,
        description: 'محفظة مخصصة لحماية الأموال من موجات التضخم وانخفاض العملة.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: 'صندوق أزموت الذهب (Azimut Gold)',
            categoryNameAr: 'صناديق الذهب',
            percentage: 50.0,
            badgeLabel: 'الملاذ الآمن الأول',
            categoryColor: const Color(0xFFF59E0B),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق الفضة الاستثماري',
            categoryNameAr: 'صناديق الفضة',
            percentage: 25.0,
            badgeLabel: 'نمو معدني صناعي',
            categoryColor: const Color(0xFF94A3B8),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق مباشر اليومي للسيولة',
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
        expectedRoiPercentage: 35.0,
        description: 'محفظة ديناميكية تركز على الأسهم المصرية الواعدة مع حصة تحوطية.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: 'صندوق هيرميس للأسهم المصرية',
            categoryNameAr: 'أسهم واعدة',
            percentage: 50.0,
            badgeLabel: 'عائد نمو مرتفع',
            categoryColor: const Color(0xFF3B82F6),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق بلتون للنمو الاستثماري',
            categoryNameAr: 'أدوات مركبة ومشتقات',
            percentage: 30.0,
            badgeLabel: 'فرص مضاعفة',
            categoryColor: const Color(0xFF8B5CF6),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق الذهب أزموت',
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
        expectedRoiPercentage: 22.0,
        description: 'محفظة عالية الأمان تركز على العائد اليومي التراكمي وأذون الخزانة.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: 'صندوق البنك الأهلي الرابع اليومي',
            categoryNameAr: 'سيولة نقدية',
            percentage: 60.0,
            badgeLabel: 'عائد يومي آمن',
            categoryColor: const Color(0xFF10B981),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق أذون الخزانة المصرية',
            categoryNameAr: 'أدوات حكومية',
            percentage: 25.0,
            badgeLabel: 'ضمان حكومي',
            categoryColor: const Color(0xFF6366F1),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق الذهب أزموت',
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
        expectedRoiPercentage: 26.5,
        description: 'محفظة متوازنة تجمع بين أمان السيولة، نمو الأسهم، وتحوط الذهب.',
        recommendedPortfolioMix: [
          PortfolioFundAllocation(
            fundName: 'صندوق مباشر اليومي للسيولة',
            categoryNameAr: 'سيولة وتوفير',
            percentage: 40.0,
            badgeLabel: 'أمان وسحب فوري',
            categoryColor: const Color(0xFF10B981),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق أزموت للذهب (Azimut Gold)',
            categoryNameAr: 'تحوط ضد التضخم',
            percentage: 30.0,
            badgeLabel: 'استقرار الأصول',
            categoryColor: const Color(0xFFF59E0B),
          ),
          PortfolioFundAllocation(
            fundName: 'صندوق سي أي كابيتال للأسهم',
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
