import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/risk_profile_model.dart';
import '../../../home/data/models/fund_model.dart';
import '../../../home/data/repositories/funds_repository.dart';

class CalculatorRepository {
  // ignore: unused_field
  final SupabaseClient? _supabaseClient;

  CalculatorRepository({this._supabaseClient});

  Future<List<FundModel>> getSponsoredBackendFunds({
    List<String> excludedFundNames = const [],
  }) async {
    final list = await SupabaseFundsRepository().getFunds();

    if (excludedFundNames.isEmpty) return list;

    final lowerExcluded = excludedFundNames.map((e) => e.trim().toLowerCase()).toSet();
    final filtered = list.where((f) => !lowerExcluded.contains(f.name.trim().toLowerCase())).toList();
    return filtered.isNotEmpty ? filtered : list;
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
