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

  /// Get Risk Assessment Profile from Supabase `robo_advisor_configs` table
  /// queried by BOTH goal_key AND duration_key (15 combinations).
  /// Falls back to local calculateRiskProfile only if Supabase fails.
  Future<RiskAssessmentResult> getDynamicRiskProfile({
    required InvestmentGoal goal,
    required InvestmentDuration duration,
  }) async {
    final defaultResult = calculateRiskProfile(goal: goal, duration: duration);
    final client = SupabaseService.client;
    if (client == null) return defaultResult;

    final goalKey = _getGoalKey(goal);
    final durationKey = _getDurationKey(duration);

    // Color palette for fund slots
    const List<Color> slotColors = [
      Color(0xFFF59E0B), // Gold/primary
      Color(0xFF3B82F6), // Blue
      Color(0xFF10B981), // Green
      Color(0xFF8B5CF6), // Purple
    ];

    try {
      // ─── PRIMARY: Query robo_advisor_configs by goal_key + duration_key ───
      final response = await client
          .from('robo_advisor_configs')
          .select('*')
          .eq('goal_key', goalKey)
          .eq('duration_key', durationKey)
          .maybeSingle();

      if (response != null) {
        final Map<String, dynamic> data = response;
        final String titleAr = data['goal_title_ar']?.toString() ?? defaultResult.riskCategoryAr;
        final String titleEn = data['goal_title_en']?.toString() ?? defaultResult.riskCategoryEn;
        final double roi = (data['expected_roi'] as num?)?.toDouble() ?? defaultResult.expectedRoiPercentage;
        final String descAr = data['description_ar']?.toString() ?? defaultResult.descriptionAr;
        final String descEn = data['description_en']?.toString() ?? defaultResult.descriptionEn;

        final List<PortfolioFundAllocation> mix = [];

        // Parse up to 4 fund slots
        for (int i = 1; i <= 4; i++) {
          final name = data['fund${i}_name']?.toString() ?? '';
          if (name.isEmpty) continue;

          mix.add(PortfolioFundAllocation(
            fundName: name,
            categoryNameAr: data['fund${i}_category_ar']?.toString() ?? 'عام',
            categoryNameEn: data['fund${i}_category_ar']?.toString() ?? 'General',
            percentage: (data['fund${i}_percentage'] as num?)?.toDouble() ?? 25.0,
            badgeLabelAr: data['fund${i}_badge_ar']?.toString() ?? 'صندوق موصى به',
            badgeLabelEn: 'Recommended Fund',
            categoryColor: slotColors[i - 1],
          ));
        }

        if (mix.isNotEmpty) {
          return RiskAssessmentResult(
            riskCategoryAr: titleAr,
            riskCategoryEn: titleEn,
            expectedRoiPercentage: roi,
            descriptionAr: descAr,
            descriptionEn: descEn,
            recommendedPortfolioMix: mix,
          );
        }
      }

      // ─── FALLBACK: Check if Admin assigned specific funds directly ───
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

          mix.add(PortfolioFundAllocation(
            fundName: fundName,
            categoryNameAr: category,
            categoryNameEn: category,
            percentage: i == 0 ? (100.0 - (perFundPct * (recFunds.length - 1))) : perFundPct,
            badgeLabelAr: i == 0 ? 'موصى به إدارياً ⭐' : 'توصية المستشار 💡',
            badgeLabelEn: 'Admin Recommended',
            categoryColor: slotColors[i % slotColors.length],
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

  String _getDurationKey(InvestmentDuration duration) {
    switch (duration) {
      case InvestmentDuration.shortTerm:
        return 'shortTerm';
      case InvestmentDuration.mediumTerm:
        return 'mediumTerm';
      case InvestmentDuration.longTerm:
        return 'longTerm';
    }
  }

  /// ─── DURATION-AWARE PORTFOLIO ANALYSIS ENGINE ───
  /// 
  /// Financial Analysis Logic:
  /// ┌────────────────┬──────────────────────────────────────────────────────┐
  /// │ Short (<1yr)   │ Favor LIQUIDITY: cash, T-Bills, gold hedge          │
  /// │ Medium (1-3yr) │ BALANCE: equity + gold + bonds = sweet spot         │
  /// │ Long (>3yr)    │ MAXIMIZE equity compounding, gold as wealth shield  │
  /// └────────────────┴──────────────────────────────────────────────────────┘
  /// 
  /// Gold & Silver → pure gold/metals (NO other assets)
  /// Capital Preservation → treasury bills + gold + money market (NOT just gold)
  /// High Yield → heavy equity, duration-adjusted risk buffer
  /// Islamic Sharia → halal equivalents mirroring conventional risk/return
  /// Balanced Growth → classic 3-way diversification
  ///
  RiskAssessmentResult calculateRiskProfile({
    required InvestmentGoal goal,
    required InvestmentDuration duration,
  }) {
    switch (goal) {

      // ═══════════════════════════════════════════════════════════════════
      // 1. 🪙 goldHedging → ذهب فقط 100% (بدون أي خلط)
      //    User rule: "الدهب والفضة ده دهب بس"
      //    All durations = pure gold & metals funds only.
      // ═══════════════════════════════════════════════════════════════════
      case InvestmentGoal.goldHedging:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'تحوط بالذهب والمعادن الثمينة (قصير الأجل)',
            riskCategoryEn: 'Gold & Precious Metals Hedge (Short Term)',
            expectedRoiPercentage: 22.0,
            descriptionAr: 'محفظة مخصصة 100% لصناديق الذهب والسبائك المضمونة — حماية فورية ضد تقلبات العملة والتضخم.',
            descriptionEn: '100% gold & bullion portfolio for immediate currency and inflation hedging.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت الذهب (Azimut Gold)',
                categoryNameAr: 'صناديق الذهب المباشرة',
                categoryNameEn: 'Physical Gold Funds',
                percentage: 70.0,
                badgeLabelAr: 'ذهب نقي 24 قيراط 🪙',
                badgeLabelEn: 'Pure 24k Gold',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق إي جولد لسبائك الذهب',
                categoryNameAr: 'سبائك ومعادن ثمينة',
                categoryNameEn: 'Gold Bullion & Metals',
                percentage: 30.0,
                badgeLabelAr: 'سبائك مضمونة 🪙',
                badgeLabelEn: 'Certified Bullion',
                categoryColor: const Color(0xFF3B82F6),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'تحوط بالذهب والمعادن الثمينة (متوسط الأجل)',
            riskCategoryEn: 'Gold & Precious Metals Hedge (Medium Term)',
            expectedRoiPercentage: 26.0,
            descriptionAr: 'استثمار متين في صناديق الذهب والمعادن الثمينة — تنويع بين صناديق الذهب المباشرة وسبائك المعادن.',
            descriptionEn: 'Robust gold & precious metals investment diversified across gold funds and bullion.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت الذهب (Azimut Gold)',
                categoryNameAr: 'صناديق الذهب',
                categoryNameEn: 'Gold Funds',
                percentage: 60.0,
                badgeLabelAr: 'الملاذ الآمن الأول 🪙',
                badgeLabelEn: 'Primary Safe Haven',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق إي جولد لسبائك الذهب والمعادن',
                categoryNameAr: 'معادن ومسبوكات',
                categoryNameEn: 'Precious Metals & Bullion',
                percentage: 40.0,
                badgeLabelAr: 'نمو المعادن الثمينة 🪙',
                badgeLabelEn: 'Metals Growth',
                categoryColor: const Color(0xFF3B82F6),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'تحوط بالذهب والمعادن الثمينة (طويل الأجل)',
            riskCategoryEn: 'Gold & Precious Metals Hedge (Long Term)',
            expectedRoiPercentage: 30.0,
            descriptionAr: 'أقصى درجات حفظ القوة الشرائية وتنمية ثروة المعادن الثمينة — تراكم ذهبي طويل المدى.',
            descriptionEn: 'Maximum long-term purchasing power preservation through gold wealth compounding.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت الذهب (Azimut Gold)',
                categoryNameAr: 'صناديق الذهب الاستثمارية',
                categoryNameEn: 'Investment Gold Funds',
                percentage: 50.0,
                badgeLabelAr: 'حفظ الثروة الطويل 🪙',
                badgeLabelEn: 'Long-Term Wealth Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق إي جولد لسبائك الذهب والفضة',
                categoryNameAr: 'سبائك الذهب والفضة',
                categoryNameEn: 'Gold & Silver Bullion',
                percentage: 50.0,
                badgeLabelAr: 'تراكم الأصول الثمينة 🪙',
                badgeLabelEn: 'Precious Asset Compounding',
                categoryColor: const Color(0xFF8B5CF6),
              ),
            ],
          );
        }

      // ═══════════════════════════════════════════════════════════════════
      // 2. 🛡️ capitalPreservation → أذون خزانة + ذهب + سيولة نقدية
      //    User rule: "مش لازم عشان حفظ مال يبقى دهب، ممكن دهب وأذون خزانة"
      //    Short = high treasury + cash | Long = add gold + dividends
      // ═══════════════════════════════════════════════════════════════════
      case InvestmentGoal.capitalPreservation:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'أمان مرتفع وحفظ رأس المال (قصير الأجل)',
            riskCategoryEn: 'High Safety & Capital Preservation (Short Term)',
            expectedRoiPercentage: 20.5,
            descriptionAr: 'محفظة آمنة 100% تجمع بين أذون الخزانة الحكومية والسيولة النقدية اليومية — صفر مخاطر وسحب فوري.',
            descriptionEn: 'Zero-risk portfolio combining government T-Bills and daily money market for instant access.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق أذون الخزانة المصرية',
                categoryNameAr: 'أذون خزانة حكومية',
                categoryNameEn: 'Government Treasury Bills',
                percentage: 60.0,
                badgeLabelAr: 'ضمان حكومي 100% 🏛️',
                badgeLabelEn: 'Gov Guaranteed',
                categoryColor: const Color(0xFF6366F1),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق البنك الأهلي الرابع اليومي',
                categoryNameAr: 'سيولة نقدية يومية',
                categoryNameEn: 'Daily Money Market',
                percentage: 40.0,
                badgeLabelAr: 'سحب يومي فوري 🟢',
                badgeLabelEn: 'Instant Daily Access',
                categoryColor: const Color(0xFF10B981),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'أمان مرتفع وحفظ رأس المال (متوسط الأجل)',
            riskCategoryEn: 'High Safety & Capital Preservation (Medium Term)',
            expectedRoiPercentage: 24.0,
            descriptionAr: 'مزيج متوازن يجمع بين أذون الخزانة المضمونة، التحوط بالذهب ضد التضخم، والسيولة النقدية — الأمان مع العائد.',
            descriptionEn: 'Balanced mix of T-Bills, gold inflation hedge, and money market for safety with yield.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق أذون الخزانة المصرية',
                categoryNameAr: 'أذون خزانة حكومية',
                categoryNameEn: 'Government Treasury Bills',
                percentage: 40.0,
                badgeLabelAr: 'ضمان خزانة دولتي 🏛️',
                badgeLabelEn: 'Gov T-Bills',
                categoryColor: const Color(0xFF6366F1),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ذهبي ضد التضخم',
                categoryNameEn: 'Gold Inflation Hedge',
                percentage: 30.0,
                badgeLabelAr: 'حماية القوة الشرائية 🪙',
                badgeLabelEn: 'Purchasing Power Guard',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر اليومي للسيولة',
                categoryNameAr: 'سيولة نقدية يومية',
                categoryNameEn: 'Daily Cash Liquidity',
                percentage: 30.0,
                badgeLabelAr: 'أمان وسحب فوري 🟢',
                badgeLabelEn: 'Safe Instant Access',
                categoryColor: const Color(0xFF10B981),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'أمان مرتفع وحفظ رأس المال (طويل الأجل)',
            riskCategoryEn: 'High Safety & Capital Preservation (Long Term)',
            expectedRoiPercentage: 27.5,
            descriptionAr: 'محفظة طويلة الأجل تجمع بين الدخل الثابت والسندات، التحوط بالذهب، أسهم التوزيعات النقدية، وأذون الخزانة — حماية شاملة مع نمو.',
            descriptionEn: 'Long-term preservation combining fixed income, gold hedge, high-dividend equities, and T-Bills.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق الدخل الثابت والسندات',
                categoryNameAr: 'دخل ثابت وسندات حكومية',
                categoryNameEn: 'Fixed Income & Gov Bonds',
                percentage: 35.0,
                badgeLabelAr: 'عائد ثابت مستقر 🏛️',
                badgeLabelEn: 'Stable Fixed Return',
                categoryColor: const Color(0xFF6366F1),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ذهبي طويل',
                categoryNameEn: 'Long-Term Gold Hedge',
                percentage: 30.0,
                badgeLabelAr: 'درع الثروة الذهبي 🪙',
                badgeLabelEn: 'Golden Wealth Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال لتوزيعات الأرباح',
                categoryNameAr: 'أسهم توزيعات نقدية',
                categoryNameEn: 'High Dividend Equities',
                percentage: 20.0,
                badgeLabelAr: 'أرباح نقدية دورية 💵',
                badgeLabelEn: 'Periodic Cash Dividends',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أذون الخزانة المصرية',
                categoryNameAr: 'أذون خزانة قصيرة',
                categoryNameEn: 'Short-Term T-Bills',
                percentage: 15.0,
                badgeLabelAr: 'سيولة آمنة مضمونة 🏛️',
                badgeLabelEn: 'Safe Guaranteed Liquidity',
                categoryColor: const Color(0xFF3B82F6),
              ),
            ],
          );
        }

      // ═══════════════════════════════════════════════════════════════════
      // 3. 🚀 highYield → أسهم مكثفة + وسادة سيولة/ذهب حسب المدة
      //    Analysis: Equity compounding needs TIME.
      //    Short = 55% equity + buffer | Long = 75% pure equity growth
      // ═══════════════════════════════════════════════════════════════════
      case InvestmentGoal.highYield:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'أقصى نمو وأرباح - أسهم (قصير الأجل)',
            riskCategoryEn: 'Maximum Growth & Equities (Short Term)',
            expectedRoiPercentage: 24.0,
            descriptionAr: 'تركيز على صناديق الأسهم عالية الأداء مع وسادة سيولة نقدية وتحوط ذهبي — أرباح سريعة مع حماية من التقلبات.',
            descriptionEn: 'High-performance equity focus with cash cushion and gold hedge for volatility protection.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر للأسهم المصرية',
                categoryNameAr: 'صناديق الأسهم',
                categoryNameEn: 'Equity Funds',
                percentage: 55.0,
                badgeLabelAr: 'نمو سريع 🚀',
                badgeLabelEn: 'Rapid Growth',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر اليومي للسيولة',
                categoryNameAr: 'سيولة نقدية وحماية',
                categoryNameEn: 'Cash Liquidity Cushion',
                percentage: 25.0,
                badgeLabelAr: 'أمان وتحوط سريع 🟢',
                badgeLabelEn: 'Safety Buffer',
                categoryColor: const Color(0xFF6366F1),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ضد التقلبات',
                categoryNameEn: 'Volatility Hedge',
                percentage: 20.0,
                badgeLabelAr: 'حماية الأرباح 🪙',
                badgeLabelEn: 'Profit Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'أقصى نمو وأرباح - أسهم (متوسط الأجل)',
            riskCategoryEn: 'Maximum Growth & Equities (Medium Term)',
            expectedRoiPercentage: 30.0,
            descriptionAr: 'تركيز مكثف على أرباح رأس المال من أفضل صناديق الأسهم القيادية والقطاعية مع تحوط ذهبي جزئي.',
            descriptionEn: 'Intensive capital gains focus across leading and sector equity funds with partial gold hedging.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر للأسهم المصرية',
                categoryNameAr: 'صناديق الأسهم القيادية',
                categoryNameEn: 'Bluechip Equities',
                percentage: 60.0,
                badgeLabelAr: 'أرباح رأسمالية قياسية 🚀',
                badgeLabelEn: 'Record Capital Gains',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال للنمو',
                categoryNameAr: 'صناديق قطاعية ونمو',
                categoryNameEn: 'Sector & Growth Funds',
                percentage: 25.0,
                badgeLabelAr: 'نمو قطاعي متسارع 📊',
                badgeLabelEn: 'Accelerated Sector Growth',
                categoryColor: const Color(0xFF3B82F6),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ذهبي',
                categoryNameEn: 'Gold Protection',
                percentage: 15.0,
                badgeLabelAr: 'حماية الأرباح المتراكمة 🪙',
                badgeLabelEn: 'Accumulated Yield Guard',
                categoryColor: const Color(0xFFF59E0B),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'أقصى نمو وأرباح - أسهم (طويل الأجل)',
            riskCategoryEn: 'Maximum Growth & Equities (Long Term)',
            expectedRoiPercentage: 36.0,
            descriptionAr: 'أقصى تنمية للثروة عبر النمو المركب طويل الأجل — تركيز كامل على صناديق الأسهم لمضاعفة رأس المال.',
            descriptionEn: 'Maximum wealth compounding via long-term full equity allocation for capital multiplication.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر للأسهم المصرية',
                categoryNameAr: 'صناديق النمو التراكمي',
                categoryNameEn: 'Compounding Equities',
                percentage: 75.0,
                badgeLabelAr: 'تضاعف الثروة المركب 🚀',
                badgeLabelEn: 'Compound Wealth Multiplier',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق بلتون للنمو المشتق',
                categoryNameAr: 'أدوات نمو هجينة',
                categoryNameEn: 'Hybrid Growth Instruments',
                percentage: 25.0,
                badgeLabelAr: 'أرباح مضاعفة متسارعة 📈',
                badgeLabelEn: 'Accelerated Multiplied Gains',
                categoryColor: const Color(0xFF8B5CF6),
              ),
            ],
          );
        }

      // ═══════════════════════════════════════════════════════════════════
      // 4. 🌙 islamicSharia → بدائل حلال متوافقة مع الشريعة
      //    Analysis: Mirror conventional risk/return with halal alternatives
      //    Short = Murabaha liquidity heavy | Long = Sharia equity heavy
      // ═══════════════════════════════════════════════════════════════════
      case InvestmentGoal.islamicSharia:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'استثمار إسلامي 100% (قصير الأجل)',
            riskCategoryEn: '100% Sharia-Compliant Investment (Short Term)',
            expectedRoiPercentage: 19.5,
            descriptionAr: 'محفظة إسلامية آمنة تركز على سيولة المرابحة اليومية مع تحوط ذهبي شرعي ونمو حلال خفيف.',
            descriptionEn: 'Safe Islamic portfolio focused on daily Murabaha liquidity with Sharia gold hedge and light halal growth.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق البركة الإسلامي اليومي',
                categoryNameAr: 'سيولة مرابحة إسلامية',
                categoryNameEn: 'Islamic Murabaha Liquidity',
                percentage: 50.0,
                badgeLabelAr: 'عائد مرابحة آمن 🌙',
                badgeLabelEn: 'Safe Murabaha Yield',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق الذهب أزموت الإسلامي',
                categoryNameAr: 'تحوط ذهبي إسلامي',
                categoryNameEn: 'Islamic Gold Hedge',
                percentage: 30.0,
                badgeLabelAr: 'حماية شرعية 🪙',
                badgeLabelEn: 'Sharia Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق فيصل الإسلامي للأسهم',
                categoryNameAr: 'أسهم إسلامية نقية',
                categoryNameEn: 'Pure Sharia Stocks',
                percentage: 20.0,
                badgeLabelAr: 'نمو حلال خفيف 📈',
                badgeLabelEn: 'Light Halal Growth',
                categoryColor: const Color(0xFF059669),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'استثمار إسلامي 100% (متوسط الأجل)',
            riskCategoryEn: '100% Sharia-Compliant Investment (Medium Term)',
            expectedRoiPercentage: 25.0,
            descriptionAr: 'توزيع متوازن بين أسهم النمو الشرعية، سيولة المرابحة، والتحوط بالذهب الإسلامي — عائد ونمو حلال.',
            descriptionEn: 'Balanced mix of Sharia growth equities, Murabaha liquidity, and Islamic gold hedging.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق فيصل الإسلامي للأسهم',
                categoryNameAr: 'أسهم شريعة نامية',
                categoryNameEn: 'Sharia Growth Equities',
                percentage: 45.0,
                badgeLabelAr: 'نمو شرعي ممتاز 🌙',
                badgeLabelEn: 'Excellent Sharia Growth',
                categoryColor: const Color(0xFF059669),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق البركة الإسلامي اليومي',
                categoryNameAr: 'سيولة مرابحة',
                categoryNameEn: 'Murabaha Liquidity',
                percentage: 30.0,
                badgeLabelAr: 'أمان واستقرار حلال 🟢',
                badgeLabelEn: 'Halal Stability',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق الذهب أزموت الإسلامي',
                categoryNameAr: 'تحوط ذهبي شرعي',
                categoryNameEn: 'Islamic Gold Hedge',
                percentage: 25.0,
                badgeLabelAr: 'حفظ القوة الشرائية 🪙',
                badgeLabelEn: 'Purchasing Power Guard',
                categoryColor: const Color(0xFFF59E0B),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'استثمار إسلامي 100% (طويل الأجل)',
            riskCategoryEn: '100% Sharia-Compliant Investment (Long Term)',
            expectedRoiPercentage: 29.0,
            descriptionAr: 'أقصى تنمية للثروة المتوافقة مع الشريعة — تركيز مكثف على أسهم النمو الإسلامية مع تحوط ذهبي وسيولة مرنة.',
            descriptionEn: 'Maximum Sharia-compliant wealth growth via heavy Islamic equity allocation with gold shield and flexible liquidity.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق فيصل الإسلامي للأسهم',
                categoryNameAr: 'أسهم نمو شريعة مركبة',
                categoryNameEn: 'Compounding Sharia Equities',
                percentage: 60.0,
                badgeLabelAr: 'أرباح شرعية مضاعفة 🚀',
                badgeLabelEn: 'Compounded Sharia Returns',
                categoryColor: const Color(0xFF059669),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق الذهب أزموت الإسلامي',
                categoryNameAr: 'تحوط ذهبي شرعي',
                categoryNameEn: 'Islamic Gold Shield',
                percentage: 25.0,
                badgeLabelAr: 'استقرار الأصول الإسلامية 🪙',
                badgeLabelEn: 'Islamic Asset Guard',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق البركة الإسلامي اليومي',
                categoryNameAr: 'سيولة مرابحة مرنة',
                categoryNameEn: 'Flexible Murabaha Cash',
                percentage: 15.0,
                badgeLabelAr: 'سيولة مرنة حلال 🟢',
                badgeLabelEn: 'Flexible Halal Liquidity',
                categoryColor: const Color(0xFF10B981),
              ),
            ],
          );
        }

      // ═══════════════════════════════════════════════════════════════════
      // 5. ⚖️ balancedGrowth → تنويع كلاسيكي 3-way
      //    Analysis: Classic diversified portfolio adapted by duration
      //    Short = cash-heavy | Medium = equal 3-way | Long = equity-heavy
      // ═══════════════════════════════════════════════════════════════════
      case InvestmentGoal.balancedGrowth:
        if (duration == InvestmentDuration.shortTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'نمو متوازن ومتنوع (قصير الأجل)',
            riskCategoryEn: 'Balanced Diversified Growth (Short Term)',
            expectedRoiPercentage: 21.5,
            descriptionAr: 'محفظة متوازنة قصيرة الأجل — سيولة نقدية عالية مع تحوط ذهبي ونمو أسهم خفيف.',
            descriptionEn: 'Short-term balanced portfolio with high cash safety, gold hedge, and light equity growth.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق مباشر اليومي للسيولة',
                categoryNameAr: 'سيولة نقدية وتوفير',
                categoryNameEn: 'Cash & Savings',
                percentage: 40.0,
                badgeLabelAr: 'أمان وسحب فوري 🟢',
                badgeLabelEn: 'Instant Safe Access',
                categoryColor: const Color(0xFF10B981),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ذهبي ضد التضخم',
                categoryNameEn: 'Gold Inflation Hedge',
                percentage: 35.0,
                badgeLabelAr: 'استقرار الأصول 🪙',
                badgeLabelEn: 'Asset Stability',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال للأسهم',
                categoryNameAr: 'أسهم نمو خفيفة',
                categoryNameEn: 'Light Growth Stocks',
                percentage: 25.0,
                badgeLabelAr: 'عائد إضافي متوازن 📈',
                badgeLabelEn: 'Balanced Extra Yield',
                categoryColor: const Color(0xFF3B82F6),
              ),
            ],
          );
        } else if (duration == InvestmentDuration.mediumTerm) {
          return RiskAssessmentResult(
            riskCategoryAr: 'نمو متوازن ومتنوع (متوسط الأجل)',
            riskCategoryEn: 'Balanced Diversified Growth (Medium Term)',
            expectedRoiPercentage: 26.5,
            descriptionAr: 'المحفظة الذكية النموذجية — تنويع مثالي بين الأسهم والذهب والدخل الثابت لزيادة القيمة وتفادي التضخم.',
            descriptionEn: 'The ideal smart portfolio — perfect diversification across equities, gold, and fixed income.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال للأسهم',
                categoryNameAr: 'أسهم ونمو',
                categoryNameEn: 'Equities & Growth',
                percentage: 40.0,
                badgeLabelAr: 'نمو رأس المال 📈',
                badgeLabelEn: 'Capital Growth',
                categoryColor: const Color(0xFF3B82F6),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ذهبي ضد التضخم',
                categoryNameEn: 'Gold Inflation Hedge',
                percentage: 30.0,
                badgeLabelAr: 'درع الأصول 🪙',
                badgeLabelEn: 'Asset Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أذون الخزانة المصرية',
                categoryNameAr: 'دخل ثابت وأذون خزانة',
                categoryNameEn: 'Fixed Income & T-Bills',
                percentage: 30.0,
                badgeLabelAr: 'استقرار وعائد مضمون 🏛️',
                badgeLabelEn: 'Stable Guaranteed Yield',
                categoryColor: const Color(0xFF6366F1),
              ),
            ],
          );
        } else {
          return RiskAssessmentResult(
            riskCategoryAr: 'نمو متوازن ومتنوع (طويل الأجل)',
            riskCategoryEn: 'Balanced Diversified Growth (Long Term)',
            expectedRoiPercentage: 31.0,
            descriptionAr: 'محفظة نمو متقدمة طويلة الأجل — تركيز على الأسهم القيادية مع تحوط ذهبي ودخل ثابت لمضاعفة القيمة.',
            descriptionEn: 'Advanced long-term growth portfolio — leading equities with gold shield and fixed income for value multiplication.',
            recommendedPortfolioMix: [
              PortfolioFundAllocation(
                fundName: 'صندوق سي أي كابيتال للأسهم',
                categoryNameAr: 'أسهم نمو قيادية',
                categoryNameEn: 'Leading Growth Equities',
                percentage: 55.0,
                badgeLabelAr: 'تنمية متسارعة 🚀',
                badgeLabelEn: 'Accelerated Growth',
                categoryColor: const Color(0xFF3B82F6),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق أزموت للذهب (Azimut Gold)',
                categoryNameAr: 'تحوط ذهبي',
                categoryNameEn: 'Gold Protection',
                percentage: 25.0,
                badgeLabelAr: 'درع ثروة طويل 🪙',
                badgeLabelEn: 'Long-Term Wealth Shield',
                categoryColor: const Color(0xFFF59E0B),
              ),
              PortfolioFundAllocation(
                fundName: 'صندوق الدخل الثابت والسندات',
                categoryNameAr: 'دخل ثابت وسندات',
                categoryNameEn: 'Fixed Income & Bonds',
                percentage: 20.0,
                badgeLabelAr: 'استقرار أرباح مضمون 🏛️',
                badgeLabelEn: 'Guaranteed Income Stability',
                categoryColor: const Color(0xFF6366F1),
              ),
            ],
          );
        }
    }
  }
}

