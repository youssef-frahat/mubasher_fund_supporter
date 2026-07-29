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
      case InvestmentGoal.highYield:
        return 'highYield';
      case InvestmentGoal.balancedGrowth:
        return 'balancedGrowth';
    }
  }

  RiskAssessmentResult calculateRiskProfile({
    required InvestmentGoal goal,
    required InvestmentDuration duration,
  }) {
    switch (goal) {
      // 1. 🚀 highYield (أقصى نمو وأرباح - أسهم)
      case InvestmentGoal.highYield:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'أقصى نمو وأرباح (أسهم - قصير الأجل)',
            riskCategoryEn: 'Maximum Growth & Equities (Short Term)',
            expectedRoiPercentage: 26.0,
            descriptionAr: 'تحوط وتحقيق أرباح سريعة من صناديق الأسهم عالية الأداء مع جزء للسيولة لتفادي التقلبات.',
            descriptionEn: 'High equity growth with a liquidity cushion to navigate short term volatility.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر للأسهم المصرية',
                categoryNameAr: 'صناديق الأسهم',
                categoryNameEn: 'Equity Funds',
                percentage: 50.0,
                badgeLabelAr: 'نمو مرتفع 🚀',
                badgeLabelEn: 'High Growth',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال للنمو',
                categoryNameAr: 'أسهم واعدة',
                categoryNameEn: 'Growth Stocks',
                percentage: 30.0,
                badgeLabelAr: 'أرباح رأسمالية 📈',
                badgeLabelEn: 'Capital Gains',
                categoryColor: const Color(0xFF3B82F6),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر اليومي للسيولة',
                categoryNameAr: 'أدوات نقدية وحماية',
                categoryNameEn: 'Cash Cushion',
                percentage: 20.0,
                badgeLabelAr: 'أمان وتحوط سريعة',
                badgeLabelEn: 'Safety Cushion',
                categoryColor: const Color(0xFF6366F1),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'أقصى نمو وأرباح (أسهم - متوسط الأجل)',
            riskCategoryEn: 'Maximum Growth & Equities (Medium Term)',
            expectedRoiPercentage: 32.5,
            descriptionAr: 'تركيز على أرباح رأس المال من أفضل صناديق الأسهم مع تحوط جزئي في الذهب.',
            descriptionEn: 'Capital gains focus on high performing equities with partial gold hedging.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر للأسهم المصرية',
                categoryNameAr: 'صناديق الأسهم القيادية',
                categoryNameEn: 'Bluechip Equities',
                percentage: 55.0,
                badgeLabelAr: 'أرباح قياسية 🚀',
                badgeLabelEn: 'Record Yield',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أهلي قطاعات واعدة',
                categoryNameAr: 'صناديق قطاعية',
                categoryNameEn: 'Sector Funds',
                percentage: 30.0,
                badgeLabelAr: 'نمو قطاعي 📊',
                badgeLabelEn: 'Sector Growth',
                categoryColor: const Color(0xFF3B82F6),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب',
                categoryNameAr: 'تحوط ذهبي',
                categoryNameEn: 'Gold Protection',
                percentage: 15.0,
                badgeLabelAr: 'حماية الأرباح',
                badgeLabelEn: 'Yield Guard',
                categoryColor: const Color(0xFFF59E0B),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'أقصى نمو وأرباح (أسهم - طويل الأجل)',
            riskCategoryEn: 'Maximum Growth & Equities (Long Term)',
            expectedRoiPercentage: 38.5,
            descriptionAr: 'أقصى تنمية للثروة ومضاعفة رأس المال عبر الاستثمار الطويل في صناديق الأسهم والنمو المركب.',
            descriptionEn: 'Maximum wealth compounding targeting multi-year stock market outperformance.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر للأسهم المصرية',
                categoryNameAr: 'صناديق النمو التراكمي',
                categoryNameEn: 'Compounding Equities',
                percentage: 70.0,
                badgeLabelAr: 'تضاعف الثروة 🚀',
                badgeLabelEn: 'Wealth Multiplier',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق بلتون للنمو المشتق',
                categoryNameAr: 'أدوات مرابحة وأسهم',
                categoryNameEn: 'Hybrid Equities',
                percentage: 30.0,
                badgeLabelAr: 'أرباح مضاعفة 📈',
                badgeLabelEn: 'Multiplied Gains',
                categoryColor: const Color(0xFF8B5CF6),
              ),
            ],
          );
        }

      // 2. 🛡️ capitalPreservation (أمان مرتفع وحفظ رأس المال)
      case InvestmentGoal.capitalPreservation:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'أمان مرتفع وحفظ رأس المال (قصير الأجل)',
            riskCategoryEn: 'High Safety & Capital Preservation (Short Term)',
            expectedRoiPercentage: 21.5,
            descriptionAr: 'محفظة خالية من المخاطر تركز 100% على أدوات السيولة النقدية اليومية وأذون الخزانة.',
            descriptionEn: 'Zero risk portfolio focused entirely on daily money market yield & gov T-Bills.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق البنك الأهلي الرابع اليومي',
                categoryNameAr: 'سيولة نقدية يومية',
                categoryNameEn: 'Daily Cash Yield',
                percentage: 70.0,
                badgeLabelAr: 'سحب يومي آمن 🟢',
                badgeLabelEn: 'Safe Daily Access',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أذون الخزانة المصرية',
                categoryNameAr: 'أذون خزانة حكومية',
                categoryNameEn: 'Government T-Bills',
                percentage: 30.0,
                badgeLabelAr: 'ضمان دولتي آمن 🏛️',
                badgeLabelEn: 'Gov Backed',
                categoryColor: const Color(0xFF6366F1),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'أمان مرتفع وحفظ رأس المال (متوسط الأجل)',
            riskCategoryEn: 'High Safety & Capital Preservation (Medium Term)',
            expectedRoiPercentage: 24.5,
            descriptionAr: 'مزيج متوازن يوفر عائد آمن مع تحوط جزئي في الذهب ضد التضخم.',
            descriptionEn: 'Balanced mix providing safe returns plus a gold hedge against inflation.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق البنك الأهلي الرابع اليومي',
                categoryNameAr: 'سيولة وتوفير',
                categoryNameEn: 'Cash Liquidity',
                percentage: 45.0,
                badgeLabelAr: 'عائد تراكمي آمن 🟢',
                badgeLabelEn: 'Safe Yield',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أذون الخزانة المصرية',
                categoryNameAr: 'أذون خزانة',
                categoryNameEn: 'Government T-Bills',
                percentage: 35.0,
                badgeLabelAr: 'ضمان خزانة 🏛️',
                badgeLabelEn: 'T-Bills Guaranteed',
                categoryColor: const Color(0xFF6366F1),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ذهبي',
                categoryNameEn: 'Gold Protection',
                percentage: 20.0,
                badgeLabelAr: 'حماية القوة الشرائية 🪙',
                badgeLabelEn: 'Purchasing Power Guard',
                categoryColor: const Color(0xFFF59E0B),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'أمان مرتفع وحفظ رأس المال (طويل الأجل)',
            riskCategoryEn: 'High Safety & Capital Preservation (Long Term)',
            expectedRoiPercentage: 27.0,
            descriptionAr: 'محفظة طويلة الأجل تجمع بين أذون الخزانة، تحوط الذهب، وأسهم التوزيعات النقدية القوية.',
            descriptionEn: 'Long term preservation combining T-Bills, gold protection, & high-dividend stocks.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق أذون الخزانة والدخل الثابت',
                categoryNameAr: 'دخل ثابت وسندات',
                categoryNameEn: 'Fixed Income & Bonds',
                percentage: 35.0,
                badgeLabelAr: 'عائد ثابت مستقر 🏛️',
                badgeLabelEn: 'Stable Income',
                categoryColor: const Color(0xFF6366F1),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ذهبي',
                categoryNameEn: 'Gold Hedge',
                percentage: 35.0,
                badgeLabelAr: 'حفظ ثروة ممتاز 🪙',
                badgeLabelEn: 'Wealth Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال لتوزيعات الأرباح',
                categoryNameAr: 'أسهم توزيعات آمنة',
                categoryNameEn: 'High Dividend Equities',
                percentage: 30.0,
                badgeLabelAr: 'أرباح نقدية دورية 💵',
                badgeLabelEn: 'Cash Dividends',
                categoryColor: const Color(0xFF10B981),
              ),
            ],
          );
        }

      // 3. 🪙 goldHedging (التحوط وحماية الذهب والفضة)
      case InvestmentGoal.goldHedging:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'تحوط وحماية رأس المال - الذهب والفضة (قصير الأجل)',
            riskCategoryEn: 'Gold & Metals Protection (Short Term)',
            expectedRoiPercentage: 24.0,
            descriptionAr: 'محفظة مخصصة 100% للذهب المضمون والسبائك للتحوط السريع ضد تقلبات العملة.',
            descriptionEn: '100% gold & bullion focused portfolio for immediate currency hedging.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت الذهب (Azimut Gold)',
                categoryNameAr: 'صناديق الذهب المباشرة',
                categoryNameEn: 'Physical Gold Funds',
                percentage: 70.0,
                badgeLabelAr: 'ذهب نقي 24 🪙',
                badgeLabelEn: 'Pure 24k Gold',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق إي جولد لسبائك الذهب',
                categoryNameAr: 'معادن ومسبوكات',
                categoryNameEn: 'Bullion & Metals',
                percentage: 30.0,
                badgeLabelAr: 'سبائك مضمونة 🪙',
                badgeLabelEn: 'Certified Bullion',
                categoryColor: const Color(0xFF3B82F6),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'تحوط وحماية رأس المال - الذهب والفضة (متوسط الأجل)',
            riskCategoryEn: 'Gold & Metals Protection (Medium Term)',
            expectedRoiPercentage: 28.0,
            descriptionAr: 'تحوط استثماري متين يعتمد على تنويع الاستثمار في صناديق الذهب والسبائك والمعادن الثمينة.',
            descriptionEn: 'Robust hedging leveraging gold funds, silver, and precious metals.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت الذهب (Azimut Gold)',
                categoryNameAr: 'صناديق الذهب',
                categoryNameEn: 'Gold Funds',
                percentage: 60.0,
                badgeLabelAr: 'الملاذ الآمن الأول 🪙',
                badgeLabelEn: 'Safe Haven #1',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق إي جولد لسبائك الذهب والمعادن',
                categoryNameAr: 'معادن ومسبوكات',
                categoryNameEn: 'Precious Metals',
                percentage: 40.0,
                badgeLabelAr: 'نمو الذهب والفضة 🪙',
                badgeLabelEn: 'Metals Growth',
                categoryColor: const Color(0xFF3B82F6),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'تحوط وحماية رأس المال - الذهب والفضة (طويل الأجل)',
            riskCategoryEn: 'Gold & Metals Protection (Long Term)',
            expectedRoiPercentage: 32.0,
            descriptionAr: 'أقصى درجات حفظ القوة الشرائية وتنمية ثروة المعادن الثمينة والذهب على المدى الطويل.',
            descriptionEn: 'Maximum long term wealth shield and purchasing power growth through metals.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت الذهب (Azimut Gold)',
                categoryNameAr: 'صناديق الذهب الاستثمارية',
                categoryNameEn: 'Investment Gold Funds',
                percentage: 50.0,
                badgeLabelAr: 'حفظ الثروة 🪙',
                badgeLabelEn: 'Wealth Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق إي جولد لسبائك الذهب والفضة',
                categoryNameAr: 'سبائك ومعادن ثمينة',
                categoryNameEn: 'Gold & Silver Bullion',
                percentage: 50.0,
                badgeLabelAr: 'تراكم الأصول 🪙',
                badgeLabelEn: 'Asset Compounding',
                categoryColor: const Color(0xFF8B5CF6),
              ),
            ],
          );
        }

      // 4. 🌙 islamicSharia (استثمار إسلامي)
      case InvestmentGoal.islamicSharia:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'استثمار إسلامي 100% (قصير الأجل)',
            riskCategoryEn: '100% Sharia Investment (Short Term)',
            expectedRoiPercentage: 21.0,
            descriptionAr: 'محفظة إسلامية نقدية تعتمد على المرابحة والسيولة اليومية المتوافقة مع الشريعة.',
            descriptionEn: '100% Sharia cash portfolio focused on daily Murabaha yield.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق البركة الإسلامي اليومي',
                categoryNameAr: 'سيولة مرابحة إسلامية',
                categoryNameEn: 'Murabaha Liquidity',
                percentage: 65.0,
                badgeLabelAr: 'عائد مرابحة آمن 🌙',
                badgeLabelEn: 'Safe Murabaha',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق الذهب أزموت الإسلامي',
                categoryNameAr: 'تحوط ذهبي إسلامي',
                categoryNameEn: 'Islamic Gold',
                percentage: 20.0,
                badgeLabelAr: 'حفظ شرعي 🪙',
                badgeLabelEn: 'Sharia Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق فيصل الإسلامي للأسهم',
                categoryNameAr: 'أسهم إسلامية نقية',
                categoryNameEn: 'Pure Sharia Stocks',
                percentage: 15.0,
                badgeLabelAr: 'نمو حلال 📈',
                badgeLabelEn: 'Halal Growth',
                categoryColor: const Color(0xFF059669),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'استثمار إسلامي 100% (متوسط الأجل)',
            riskCategoryEn: '100% Sharia Investment (Medium Term)',
            expectedRoiPercentage: 25.5,
            descriptionAr: 'توزيع متوازن بين أسهم الشريعة النامية، سيولة المرابحة، والتحوط بالذهب.',
            descriptionEn: 'Balanced mix of Sharia growth stocks, Murabaha liquidity, & gold.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق فيصل الإسلامي للأسهم',
                categoryNameAr: 'أسهم شريعة مطابقة',
                categoryNameEn: 'Sharia Equities',
                percentage: 40.0,
                badgeLabelAr: 'نمو شرعي ممتاز 🌙',
                badgeLabelEn: 'Sharia Growth',
                categoryColor: const Color(0xFF059669),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق البركة الإسلامي اليومي',
                categoryNameAr: 'سيولة مرابحة',
                categoryNameEn: 'Murabaha Liquidity',
                percentage: 35.0,
                badgeLabelAr: 'أمان واستقرار 🟢',
                badgeLabelEn: 'Stable Yield',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق الذهب أزموت الإسلامي',
                categoryNameAr: 'تحوط ذهبي شرعي',
                categoryNameEn: 'Islamic Gold Hedge',
                percentage: 25.0,
                badgeLabelAr: 'حفظ القوة الشرائية 🪙',
                badgeLabelEn: 'Value Preservation',
                categoryColor: const Color(0xFFF59E0B),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'استثمار إسلامي 100% (طويل الأجل)',
            riskCategoryEn: '100% Sharia Investment (Long Term)',
            expectedRoiPercentage: 29.5,
            descriptionAr: 'أقصى تنمية للثروة المتوافقة مع الشريعة عبر التركيز المكثف على أسهم النمو الإسلامية.',
            descriptionEn: 'Maximum long-term wealth growth via heavy allocation in Sharia growth equities.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق فيصل الإسلامي للأسهم',
                categoryNameAr: 'أسهم نمو شريعة',
                categoryNameEn: 'Sharia Growth Equities',
                percentage: 65.0,
                badgeLabelAr: 'أرباح شرعية مضاعفة 🚀',
                badgeLabelEn: 'Compounded Sharia Gains',
                categoryColor: const Color(0xFF059669),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق الذهب أزموت الإسلامي',
                categoryNameAr: 'تحوط ذهبي شرعي',
                categoryNameEn: 'Islamic Gold',
                percentage: 20.0,
                badgeLabelAr: 'استقرار الأصول 🪙',
                badgeLabelEn: 'Asset Guard',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق البركة الإسلامي اليومي',
                categoryNameAr: 'سيولة مرابحة',
                categoryNameEn: 'Murabaha Cash',
                percentage: 15.0,
                badgeLabelAr: 'سيولة مرنة 🟢',
                badgeLabelEn: 'Flexible Liquidity',
                categoryColor: const Color(0xFF10B981),
              ),
            ],
          );
        }

      // 5. ⚖️ balancedGrowth (نمو متوازن - المحفظة النموذجية)
      case InvestmentGoal.balancedGrowth:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'نمو متوازن (قصير الأجل)',
            riskCategoryEn: 'Balanced Growth (Short Term)',
            expectedRoiPercentage: 23.0,
            descriptionAr: 'محفظة متوازنة قصيرة الأجل تضمن سلامة السيولة مع أرباح متوازنة وتحوط الذهب.',
            descriptionEn: 'Short term balanced portfolio combining cash safety, gold, & light stock growth.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر اليومي للسيولة',
                categoryNameAr: 'سيولة وتوفير',
                categoryNameEn: 'Liquidity & Cash',
                percentage: 50.0,
                badgeLabelAr: 'أمان وسحب فوري 🟢',
                badgeLabelEn: 'Instant Withdrawal',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط التضخم',
                categoryNameEn: 'Inflation Hedge',
                percentage: 30.0,
                badgeLabelAr: 'استقرار الأصول 🪙',
                badgeLabelEn: 'Asset Stability',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال للأسهم',
                categoryNameAr: 'أسهم نمو',
                categoryNameEn: 'Growth Stocks',
                percentage: 20.0,
                badgeLabelAr: 'عائد إضافي 📈',
                badgeLabelEn: 'Extra Yield',
                categoryColor: const Color(0xFF3B82F6),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'نمو متوازن (متوسط الأجل)',
            riskCategoryEn: 'Balanced Growth (Medium Term)',
            expectedRoiPercentage: 27.5,
            descriptionAr: 'المحفظة الذكية النموذجية المثالية لزيادة قيمة رأس المال وتفادي التضخم.',
            descriptionEn: 'The ideal model smart portfolio designed for capital growth & inflation protection.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال للأسهم',
                categoryNameAr: 'أسهم ومستقبل',
                categoryNameEn: 'Equities & Future',
                percentage: 40.0,
                badgeLabelAr: 'نمو رأس المال 📈',
                badgeLabelEn: 'Capital Growth',
                categoryColor: const Color(0xFF3B82F6),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ضد التضخم',
                categoryNameEn: 'Gold Hedge',
                percentage: 35.0,
                badgeLabelAr: 'استقرار الأصول 🪙',
                badgeLabelEn: 'Asset Guard',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر اليومي للسيولة',
                categoryNameAr: 'سيولة وتوفير',
                categoryNameEn: 'Liquidity & Savings',
                percentage: 25.0,
                badgeLabelAr: 'أمان وسحب فوري 🟢',
                badgeLabelEn: 'Safe Liquidity',
                categoryColor: const Color(0xFF10B981),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'نمو متوازن (طويل الأجل)',
            riskCategoryEn: 'Balanced Growth (Long Term)',
            expectedRoiPercentage: 32.5,
            descriptionAr: 'محفظة نمو متقدمة تركز على صناديق الأسهم القيادية والذهب لمضاعفة القيمة الاستثمارية.',
            descriptionEn: 'Advanced growth portfolio focusing on leading stock funds & gold to multiply value.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال للأسهم',
                categoryNameAr: 'أسهم نمو قيادية',
                categoryNameEn: 'Leading Equities',
                percentage: 60.0,
                badgeLabelAr: 'تنميات متسارعة 🚀',
                badgeLabelEn: 'Accelerated Gains',
                categoryColor: const Color(0xFF3B82F6),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ذهبي',
                categoryNameEn: 'Gold Protection',
                percentage: 25.0,
                badgeLabelAr: 'درع ثروة 🪙',
                badgeLabelEn: 'Wealth Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أذون الخزانة المصرية',
                categoryNameAr: 'أدوات دخل ثابت',
                categoryNameEn: 'Fixed Income',
                percentage: 15.0,
                badgeLabelAr: 'استقرار أرباح 🏛️',
                badgeLabelEn: 'Income Guard',
                categoryColor: const Color(0xFF6366F1),
              ),
            ],
          );
        }
    }
  }
}
