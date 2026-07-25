import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/risk_profile_model.dart';
import '../models/sponsored_fund_model.dart';

class CalculatorRepository {
  final SupabaseClient? _supabaseClient;

  CalculatorRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient;

  RiskAssessmentResult calculateRiskProfile({
    required InvestmentGoal goal,
    required InvestmentDuration duration,
  }) {
    if (goal == InvestmentGoal.islamicSharia) {
      return RiskAssessmentResult(
        riskCategory: 'استثمار متوافق مع الشريعة',
        expectedRoiPercentage: 22.5,
        recommendedCategory: 'islamic',
        description: 'صناديق استثمار إسلامية تعتمد على المرابحة والأسهم النقية بدون شبهات.',
      );
    } else if (goal == InvestmentGoal.goldHedging) {
      return RiskAssessmentResult(
        riskCategory: 'التحوط والاستقرار (الذهب)',
        expectedRoiPercentage: 28.0,
        recommendedCategory: 'gold',
        description: 'صناديق الذهب لحماية القوة الشرائية لأموالك من موجات التضخم.',
      );
    } else if (goal == InvestmentGoal.highYield && duration == InvestmentDuration.longTerm) {
      return RiskAssessmentResult(
        riskCategory: 'عائد نمو مرتفع (أسهم)',
        expectedRoiPercentage: 34.0,
        recommendedCategory: 'equity',
        description: 'استثمار ديناميكي في أفضل أسهم الشركات المصرية ذات النمو المتسارع.',
      );
    } else if (goal == InvestmentGoal.capitalPreservation) {
      return RiskAssessmentResult(
        riskCategory: 'آمن جداً (سيولة نقدية)',
        expectedRoiPercentage: 21.0,
        recommendedCategory: 'money_market',
        description: 'صناديق أدوات الدين والسيولة اليومية ذات الأمان العالي.',
      );
    } else {
      return RiskAssessmentResult(
        riskCategory: 'نمو متوازن (محفظة مختلطة)',
        expectedRoiPercentage: 25.5,
        recommendedCategory: 'balanced',
        description: 'توزيع متوازن بين الأسهم وأدوات الدين لتقليل المخاطر وتعظيم الربح.',
      );
    }
  }

  Future<SponsoredFundModel?> getSponsoredPlacement(String categoryType) async {
    try {
      final client = _supabaseClient;
      if (client != null) {
        final response = await client
            .from('sponsored_fund_placements')
            .select()
            .eq('category_type', categoryType)
            .eq('is_active', true)
            .maybeSingle();

        if (response != null) {
          return SponsoredFundModel.fromJson(response);
        }
      }
    } catch (_) {
      // Fallback below if Supabase is offline or table is empty
    }

    // Default Fallbacks
    final fallbacks = {
      'gold': SponsoredFundModel(
        id: 'gold-1',
        categoryType: 'gold',
        sponsorName: 'صندوق أزموت للذهب (Azimut Gold)',
        badgeLabel: 'شريك مميز • صندوق الذهب الأول',
        isActive: true,
      ),
      'islamic': SponsoredFundModel(
        id: 'islamic-1',
        categoryType: 'islamic',
        sponsorName: 'صندوق فيصل الإسلامي النموذجي',
        badgeLabel: 'أفضل صندوق شريعة 2026',
        isActive: true,
      ),
      'equity': SponsoredFundModel(
        id: 'equity-1',
        categoryType: 'equity',
        sponsorName: 'صندوق هيرميس للأسهم المصرية',
        badgeLabel: 'الأعلى نمواً 35% سنويًا',
        isActive: true,
      ),
      'money_market': SponsoredFundModel(
        id: 'money_market-1',
        categoryType: 'money_market',
        sponsorName: 'صندوق مباشر النخبة اليومي',
        badgeLabel: 'سيولة يومية • عائد 22%',
        isActive: true,
      ),
    };

    return fallbacks[categoryType] ??
        SponsoredFundModel(
          id: 'gen-1',
          categoryType: categoryType,
          sponsorName: 'صندوق مباشر المالي الموصى به',
          badgeLabel: 'موصى به',
          isActive: true,
        );
  }
}
