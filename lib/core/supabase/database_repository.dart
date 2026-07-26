import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/data/models/fund_model.dart';

class DatabaseRepository {
  final SupabaseClient _client;

  DatabaseRepository(this._client);

  // --- Funds CRUD Operations ---

  /// Fetch all investment funds from Supabase
  Future<List<FundModel>> getFunds() async {
    final response = await _client
        .from('funds')
        .select()
        .order('name', ascending: true);

    final data = response as List<dynamic>;
    return data.map((item) => FundModel.fromMap(item as Map<String, dynamic>)).toList();
  }

  /// Fetch single fund by ID
  Future<FundModel?> getFundById(String id) async {
    final response = await _client
        .from('funds')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return FundModel.fromMap(response);
  }

  /// Create a new fund in Supabase
  Future<FundModel> createFund(FundModel fund) async {
    final response = await _client
        .from('funds')
        .insert(fund.toMap())
        .select()
        .single();

    return FundModel.fromMap(response);
  }

  /// Update existing fund in Supabase
  Future<FundModel> updateFund(FundModel fund) async {
    final response = await _client
        .from('funds')
        .update(fund.toMap())
        .eq('id', fund.id)
        .select()
        .single();

    return FundModel.fromMap(response);
  }

  /// Delete a fund by ID
  Future<void> deleteFund(String id) async {
    await _client.from('funds').delete().eq('id', id);
  }

  // --- Wishlist (Favorite Funds) ---

  Future<void> addToWishlist(String fundId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('wishlist').insert({
      'user_id': userId,
      'fund_id': fundId,
    });
  }

  Future<void> removeFromWishlist(String fundId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('wishlist')
        .delete()
        .eq('user_id', userId)
        .eq('fund_id', fundId);
  }

  Future<List<String>> getWishlist() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client.from('wishlist')
        .select('fund_id')
        .eq('user_id', userId);

    return (response as List<dynamic>)
        .map((row) => row['fund_id'] as String)
        .toList();
  }

  Future<bool> isFundInWishlist(String fundId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client.from('wishlist')
        .select('id')
        .eq('user_id', userId)
        .eq('fund_id', fundId)
        .maybeSingle();

    return response != null;
  }
}
