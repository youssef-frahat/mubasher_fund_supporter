import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseRepository {
  final SupabaseClient _client;

  DatabaseRepository(this._client);

  // --- Wishlist (Favorite Funds) ---

  Future<void> addToWishlist(String fundId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('wishlists').insert({
      'user_id': userId,
      'fund_id': fundId,
    });
  }

  Future<void> removeFromWishlist(String fundId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('wishlists')
        .delete()
        .eq('user_id', userId)
        .eq('fund_id', fundId);
  }

  Future<List<String>> getWishlist() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _client.from('wishlists')
        .select('fund_id')
        .eq('user_id', userId);

    return (response as List<dynamic>)
        .map((row) => row['fund_id'] as String)
        .toList();
  }

  Future<bool> isFundInWishlist(String fundId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client.from('wishlists')
        .select('id')
        .eq('user_id', userId)
        .eq('fund_id', fundId)
        .maybeSingle();

    return response != null;
  }
}
