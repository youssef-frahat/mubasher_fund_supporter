import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/platform_feature.dart';
import '../models/fund_model.dart';

abstract class FundsRepository {
  Future<List<FundModel>> getFunds();
  Future<List<PlatformFeature>> getPlatformFeatures();
  Future<void> addFund(FundModel fund);
  Future<void> updateFund(FundModel fund);
  Future<void> deleteFund(String id);

  // Home Dashboard & Filter Methods
  Future<List<FundModel>> getRecommendedFunds();
  Future<List<FundModel>> getSponsoredFunds();
  Future<FundModel> getTopPerformingFund();
  Future<List<FundModel>> getRankedFunds();
}

class SupabaseFundsRepository implements FundsRepository {
  @override
  Future<List<FundModel>> getFunds() async {
    final client = SupabaseService.client;
    if (client == null) {
      return _getMockFunds();
    }

    try {
      final response = await client
          .from('funds')
          .select()
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 4));
      if (response.isNotEmpty) {
        return response
            .map((item) => FundModel.fromMap(item))
            .toList();
      }
      return _getMockFunds();
    } catch (e) {
      debugPrint('Error fetching funds from Supabase: $e');
      return _getMockFunds();
    }
  }

  @override
  Future<List<PlatformFeature>> getPlatformFeatures() async {
    final funds = await getFunds();
    return funds.map((f) => f.toPlatformFeature()).toList();
  }

  @override
  Future<void> addFund(FundModel fund) async {
    final client = SupabaseService.client;
    if (client == null) throw Exception('Supabase client is not initialized');

    await client.from('funds').insert(fund.toMap());
  }

  @override
  Future<void> updateFund(FundModel fund) async {
    final client = SupabaseService.client;
    if (client == null) throw Exception('Supabase client is not initialized');

    await client.from('funds').update(fund.toMap()).eq('id', fund.id);
  }

  @override
  Future<void> deleteFund(String id) async {
    final client = SupabaseService.client;
    if (client == null) throw Exception('Supabase client is not initialized');

    await client.from('funds').delete().eq('id', id);
  }

  @override
  Future<List<FundModel>> getRecommendedFunds() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final response = await client
            .from('funds')
            .select()
            .or('is_recommended.eq.true,is_sponsored.eq.true')
            .order('name', ascending: true)
            .timeout(const Duration(seconds: 4));
        if (response.isNotEmpty) {
          return response
              .map((item) => FundModel.fromMap(item))
              .toList();
        }
      } catch (e) {
        debugPrint('Error fetching recommended funds from Supabase: $e');
      }
    }
    final all = await getFunds();
    final rec = all.where((f) => f.isRecommended || f.isSponsored).toList();
    return rec.isNotEmpty ? rec : all;
  }

  @override
  Future<List<FundModel>> getSponsoredFunds() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final response = await client
            .from('funds')
            .select()
            .eq('is_sponsored', true)
            .order('name', ascending: true)
            .timeout(const Duration(seconds: 4));
        if (response.isNotEmpty) {
          return response
              .map((item) => FundModel.fromMap(item))
              .toList();
        }
      } catch (e) {
        debugPrint('Error fetching sponsored funds from Supabase: $e');
      }
    }
    final all = await getFunds();
    final sp = all.where((f) => f.isSponsored || f.isRecommended).toList();
    return sp.isNotEmpty ? sp : all;
  }

  @override
  Future<FundModel> getTopPerformingFund() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final response = await client
            .from('funds')
            .select()
            .order('ytd_return', ascending: false)
            .limit(1)
            .maybeSingle()
            .timeout(const Duration(seconds: 4));
        if (response != null && response.containsKey('name')) {
          return FundModel.fromMap(response);
        }
      } catch (e) {
        debugPrint('Error fetching top performing fund: $e');
      }
    }
    final all = await getFunds();
    if (all.isNotEmpty) {
      final sorted = List<FundModel>.from(all)..sort((a, b) => b.ytdReturn.compareTo(a.ytdReturn));
      return sorted.first;
    }
    return _getMockFunds().first;
  }

  @override
  Future<List<FundModel>> getRankedFunds() async {
    final all = await getFunds();
    final sorted = List<FundModel>.from(all)..sort((a, b) => b.ytdReturn.compareTo(a.ytdReturn));
    return sorted;
  }

  List<FundModel> _getMockFunds() {
    return [
      FundModel(
        id: '1',
        name: 'صندوق مباشر للأسهم المصرية (نمو)',
        nameAr: 'صندوق مباشر للأسهم المصرية (نمو)',
        nameEn: 'Mubasher Egyptian Equity Fund (Growth)',
        managerName: 'مباشر كابيتال',
        currentNav: 185.50,
        ytdReturn: 24.80,
        dailyChange: 1.25,
        riskLevel: 'High',
        category: 'Equity',
        isRecommended: true,
        isTopPerforming: true,
      ),
      FundModel(
        id: '2',
        name: 'صندوق أزيموت النقدية اليومية',
        nameAr: 'صندوق أزيموت النقدية اليومية',
        nameEn: 'Azimut Daily Liquidity Fund',
        managerName: 'أزيموت مصر',
        currentNav: 12.34,
        ytdReturn: 18.50,
        dailyChange: 0.05,
        riskLevel: 'Low',
        category: 'MoneyMarket',
        isRecommended: true,
      ),
      FundModel(
        id: '3',
        name: 'صندوق أزيموت الذهب (AZG)',
        nameAr: 'صندوق أزيموت الذهب (AZG)',
        nameEn: 'Azimut Gold Fund (AZG)',
        managerName: 'أزيموت مصر',
        currentNav: 48.75,
        ytdReturn: 32.10,
        dailyChange: -0.40,
        riskLevel: 'Medium',
        category: 'Gold',
        isRecommended: true,
      ),
      FundModel(
        id: '4',
        name: 'صندوق سي آي كابيتال للأسهم (CI Capital Equity)',
        nameAr: 'صندوق سي آي كابيتال للأسهم',
        nameEn: 'CI Capital Equity Fund',
        managerName: 'سي آي كابيتال',
        currentNav: 210.00,
        ytdReturn: 21.40,
        dailyChange: 0.80,
        riskLevel: 'Medium',
        category: 'Equity',
        isSponsored: true,
      ),
      FundModel(
        id: '5',
        name: 'صندوق البنك التجاري الدولي (CIB ثواقب)',
        nameAr: 'صندوق البنك التجاري الدولي (CIB)',
        nameEn: 'CIB Thawaqeb Fund',
        managerName: 'CIB مصر',
        currentNav: 145.20,
        ytdReturn: 19.80,
        dailyChange: 0.35,
        riskLevel: 'Medium',
        category: 'Equity',
      ),
      FundModel(
        id: '6',
        name: 'صندوق فيصل الإسلامي للأسهم',
        nameAr: 'صندوق فيصل الإسلامي للأسهم',
        nameEn: 'Faisal Islamic Equity Fund',
        managerName: 'بنك فيصل',
        currentNav: 98.40,
        ytdReturn: 22.10,
        dailyChange: 0.60,
        riskLevel: 'Medium',
        category: 'Islamic',
        isRecommended: true,
      ),
      FundModel(
        id: '7',
        name: 'صندوق بلتون للادخار بالجنيه (Beltone)',
        nameAr: 'صندوق بلتون للادخار بالجنيه',
        nameEn: 'Beltone EGP Savings Fund',
        managerName: 'بلتون المالية',
        currentNav: 15.80,
        ytdReturn: 17.90,
        dailyChange: 0.02,
        riskLevel: 'Low',
        category: 'MoneyMarket',
      ),
      FundModel(
        id: '8',
        name: 'صندوق هيرميس للنمو والتوزيع (EFG Hermes)',
        nameAr: 'صندوق هيرميس للنمو والتوزيع',
        nameEn: 'EFG Hermes Growth Fund',
        managerName: 'إي إف جي هيرميس',
        currentNav: 310.50,
        ytdReturn: 26.50,
        dailyChange: 1.10,
        riskLevel: 'High',
        category: 'Equity',
        isSponsored: true,
      ),
    ];
  }
}
