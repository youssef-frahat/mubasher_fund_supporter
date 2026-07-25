import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/platform_feature.dart';
import '../models/fund_model.dart';

abstract class FundsRepository {
  Future<List<PlatformFeature>> getFunds();
  Future<void> addFund(PlatformFeature fund);
  Future<void> deleteFund(String id);

  // New Home Dashboard Methods
  Future<List<FundModel>> getRecommendedFunds();
  Future<FundModel> getTopPerformingFund();
  Future<List<FundModel>> getRankedFunds();
}

class SupabaseFundsRepository implements FundsRepository {
  @override
  Future<List<PlatformFeature>> getFunds() async {
    final client = SupabaseService.client;
    if (client == null) {
      throw Exception('Supabase client is not initialized');
    }

    try {
      final response = await client.from('funds').select();
      
      return (response as List<dynamic>).map((fund) {
        return PlatformFeature(
          id: fund['id'] as String,
          title: fund['name_en'] as String,
          subtitle: fund['description_en'] as String,
          icon: Icons.account_balance, // Default icon for now
          accentColor: const Color(0xFF1E5CFF), // Default color for now
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching funds: $e');
      return []; 
    }
  }

  @override
  Future<void> addFund(PlatformFeature fund) async {
    final client = SupabaseService.client;
    if (client == null) throw Exception('Supabase client is not initialized');

    await client.from('funds').insert({
      'name_ar': fund.title,
      'name_en': fund.title,
      'description_ar': fund.subtitle,
      'description_en': fund.subtitle,
      'fund_type': 'Equity', // Default for now
      'manager': 'Admin', // Default for now
    });
  }

  @override
  Future<void> deleteFund(String id) async {
    final client = SupabaseService.client;
    if (client == null) throw Exception('Supabase client is not initialized');

    await client.from('funds').delete().eq('id', id);
  }

  @override
  Future<List<FundModel>> getRecommendedFunds() async {
    // Mocking API call
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      FundModel.mock('1', 'Banque Misr First Fund', 12.5),
      FundModel.mock('2', 'NBE Fund (Fourth)', 8.3, riskLevel: 'Low'),
      FundModel.mock('3', 'CIB Equity Fund', 15.2, riskLevel: 'High'),
    ];
  }

  @override
  Future<FundModel> getTopPerformingFund() async {
    // Mocking API call
    await Future.delayed(const Duration(milliseconds: 500));
    return FundModel.mock('4', 'EFG Hermes Growth Fund', 24.8, riskLevel: 'High');
  }

  @override
  Future<List<FundModel>> getRankedFunds() async {
    // Mocking API call
    await Future.delayed(const Duration(milliseconds: 500));
    final funds = [
      FundModel.mock('4', 'EFG Hermes Growth Fund', 24.8, riskLevel: 'High'),
      FundModel.mock('3', 'CIB Equity Fund', 15.2, riskLevel: 'High'),
      FundModel.mock('1', 'Banque Misr First Fund', 12.5),
      FundModel.mock('5', 'Faisal Islamic Fund', 10.1, category: 'Islamic'),
      FundModel.mock('2', 'NBE Fund (Fourth)', 8.3, riskLevel: 'Low'),
    ];
    // Sort by yield descending (already sorted in this mock, but just to be sure)
    funds.sort((a, b) => b.ytdReturn.compareTo(a.ytdReturn));
    return funds;
  }
}
