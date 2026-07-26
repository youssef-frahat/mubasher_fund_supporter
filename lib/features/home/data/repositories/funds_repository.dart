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

  // Home Dashboard Methods
  Future<List<FundModel>> getRecommendedFunds();
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
      final response = await client.from('funds').select().order('name', ascending: true);
      final data = response as List<dynamic>;
      if (data.isEmpty) return _getMockFunds();
      return data.map((item) => FundModel.fromMap(item as Map<String, dynamic>)).toList();
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
            .eq('is_recommended', true)
            .limit(10);
        final data = response as List<dynamic>;
        if (data.isNotEmpty) {
          return data.map((item) => FundModel.fromMap(item as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('Error fetching recommended funds: $e');
      }
    }
    final all = await getFunds();
    return all.where((f) => f.isRecommended).take(5).toList();
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
            .maybeSingle();
        if (response != null) {
          return FundModel.fromMap(response);
        }
      } catch (e) {
        debugPrint('Error fetching top performing fund: $e');
      }
    }
    final all = await getFunds();
    return all.first;
  }

  @override
  Future<List<FundModel>> getRankedFunds() async {
    final all = await getFunds();
    all.sort((a, b) => b.ytdReturn.compareTo(a.ytdReturn));
    return all;
  }

  List<FundModel> _getMockFunds() {
    return [
      FundModel(
        id: '1',
        name: 'صندوق مباشر للأسهم المصرية (نمو)',
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
        managerName: 'أزيموت مصر',
        currentNav: 48.75,
        ytdReturn: 32.10,
        dailyChange: -0.40,
        riskLevel: 'Medium',
        category: 'Gold',
        isRecommended: true,
      ),
    ];
  }
}
