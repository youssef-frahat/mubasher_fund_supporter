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
  static String _normalizeKey(String input) {
    if (input.isEmpty) return '';
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp(r'\bviii\b'), '8')
         .replaceAll(RegExp(r'\bvii\b'), '7')
         .replaceAll(RegExp(r'\bvi\b'), '6')
         .replaceAll(RegExp(r'\biv\b'), '4')
         .replaceAll(RegExp(r'\bv\b'), '5')
         .replaceAll(RegExp(r'\biii\b'), '3')
         .replaceAll(RegExp(r'\bii\b'), '2')
         .replaceAll(RegExp(r'\bi\b'), '1');
    s = s.replaceAll(RegExp(r'\bfirst\b'), '1')
         .replaceAll(RegExp(r'\bsecond\b'), '2')
         .replaceAll(RegExp(r'\bthird\b'), '3')
         .replaceAll(RegExp(r'\bfourth\b'), '4')
         .replaceAll(RegExp(r'\bfifth\b'), '5')
         .replaceAll('الأول', '1')
         .replaceAll('الاول', '1')
         .replaceAll('الثاني', '2')
         .replaceAll('الثانى', '2')
         .replaceAll('الثالث', '3')
         .replaceAll('الرابع', '4')
         .replaceAll('الخامس', '5');
    s = s.replaceAll(RegExp(r'\b(fund|mutual|portfolio|asset|management|bank|egypt|egyptian|holding|capital|investment|no)\b'), ' ')
         .replaceAll(RegExp(r'(صندوق|استثمار|بنك|مصر|المصري|المصرية|القابضة|كابيتال|لإدارة|الأصول)'), ' ')
         .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]'), ' ')
         .replaceAll(RegExp(r'\s+'), ' ')
         .trim();
    return s;
  }

  static FundModel? _findMatchingOfficialFund(
    FundModel remoteFund,
    List<FundModel> officialFunds,
    Map<String, FundModel> idMap,
  ) {
    // 1. Direct canonical ID match
    if (idMap.containsKey(remoteFund.id)) {
      return idMap[remoteFund.id];
    }

    final rName = remoteFund.name.trim().toLowerCase();
    final rNameAr = (remoteFund.nameAr ?? '').trim().toLowerCase();
    final rNameEn = (remoteFund.nameEn ?? '').trim().toLowerCase();

    // 2. Direct exact or substring name matching
    for (final off in officialFunds) {
      final oName = off.name.trim().toLowerCase();
      final oNameAr = (off.nameAr ?? '').trim().toLowerCase();
      final oNameEn = (off.nameEn ?? '').trim().toLowerCase();

      if ((rName.isNotEmpty && (rName == oName || (oNameAr.isNotEmpty && rName == oNameAr) || (oNameEn.isNotEmpty && rName == oNameEn))) ||
          (rNameAr.isNotEmpty && (rNameAr == oName || (oNameAr.isNotEmpty && rNameAr == oNameAr) || (oNameEn.isNotEmpty && rNameAr == oNameEn))) ||
          (rNameEn.isNotEmpty && (rNameEn == oName || (oNameAr.isNotEmpty && rNameEn == oNameAr) || (oNameEn.isNotEmpty && rNameEn == oNameEn)))) {
        return off;
      }
    }

    // 3. Normalized cross-lingual token overlap
    final normRName = _normalizeKey(remoteFund.name);
    final normREn = _normalizeKey(remoteFund.nameEn ?? '');
    final rTokens = <String>{
      ...normRName.split(' '),
      ...normREn.split(' '),
    }.where((t) => t.length >= 2).toSet();

    if (rTokens.isNotEmpty) {
      FundModel? bestMatch;
      int bestScore = 0;

      for (final off in officialFunds) {
        final offTarget = '${_normalizeKey(off.name)} ${_normalizeKey(off.nameAr ?? '')} ${_normalizeKey(off.nameEn ?? '')}';
        int score = 0;
        for (final t in rTokens) {
          if (offTarget.contains(t)) score++;
        }
        if (score > bestScore && (score / rTokens.length) >= 0.40) {
          bestScore = score;
          bestMatch = off;
        }
      }
      if (bestMatch != null) return bestMatch;
    }

    return null;
  }

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
        // Map official funds by ID to retain full 36 institutional metadata fields
        final Map<String, FundModel> fundsMap = {
          for (var fund in officialFunds) fund.id: fund,
        };

        for (final item in response) {
          try {
            final remoteFund = FundModel.fromMap(item);
            final baseFund = _findMatchingOfficialFund(remoteFund, officialFunds, fundsMap);

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
              // Deduplicate: avoid adding old English seed duplicates of Egyptian funds
              final isDuplicate = fundsMap.values.any((f) =>
                  f.name.toLowerCase() == remoteFund.name.toLowerCase() ||
                  (f.nameAr != null && f.nameAr!.toLowerCase() == remoteFund.name.toLowerCase()) ||
                  (f.nameEn != null && f.nameEn!.toLowerCase() == remoteFund.name.toLowerCase()) ||
                  _normalizeKey(f.name) == _normalizeKey(remoteFund.name));

              if (!isDuplicate && remoteFund.name.trim().isNotEmpty) {
                // Legitimate custom fund created via admin dashboard
                fundsMap[remoteFund.id] = remoteFund;
              }
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
