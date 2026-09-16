import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/platform_feature.dart';
import '../models/fund_model.dart';
import '../sources/official_egyptian_funds_data.dart';

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
    final officialFunds = OfficialEgyptianFundsData.allFunds;
    if (client == null) {
      return officialFunds;
    }

    try {
      final response = await client
          .from('funds')
          .select()
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 4));

      if (response.isNotEmpty) {
        // Map official funds by ID and normalized names to retain full 36 institutional metadata fields
        final Map<String, FundModel> fundsMap = {
          for (var fund in officialFunds) fund.id: fund,
        };
        final Map<String, FundModel> nameMap = {
          for (var fund in officialFunds) fund.name.trim().toLowerCase(): fund,
        };

        for (final item in response) {
          try {
            final remoteFund = FundModel.fromMap(item);
            final key = remoteFund.id;
            final normName = remoteFund.name.trim().toLowerCase();

            // Match by ID or name
            FundModel? baseFund = fundsMap[key] ?? nameMap[normName];

            if (baseFund != null) {
              // Overlay live price, YTD return, updated_at timestamp, and admin flags
              final merged = baseFund.copyWith(
                currentNav: remoteFund.currentNav,
                ytdReturn: remoteFund.ytdReturn,
                dailyChange: remoteFund.dailyChange != 0 ? remoteFund.dailyChange : baseFund.dailyChange,
                updatedAt: remoteFund.updatedAt ?? DateTime.now(),
                isSponsored: remoteFund.isSponsored,
                isRecommended: remoteFund.isRecommended,
                isTopPerforming: remoteFund.isTopPerforming,
              );
              fundsMap[baseFund.id] = merged;
            } else {
              // Newly added custom fund from Supabase admin
              fundsMap[key] = remoteFund;
            }
          } catch (e) {
            debugPrint('Error parsing remote fund item: $e');
          }
        }

        return fundsMap.values.toList();
      }
      return officialFunds;
    } catch (e) {
      debugPrint('Error fetching funds from Supabase: $e');
      return officialFunds;
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
    return OfficialEgyptianFundsData.allFunds;
  }
}
