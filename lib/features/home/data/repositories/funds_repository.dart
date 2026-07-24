import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/platform_feature.dart';

abstract class FundsRepository {
  Future<List<PlatformFeature>> getFunds();
  Future<void> addFund(PlatformFeature fund);
  Future<void> deleteFund(String id);
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
}
