import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase/supabase_service.dart';

class WishlistService {
  static const String _wishlistKey = 'saved_wishlist_fund_ids_v1';
  final ValueNotifier<Set<String>> savedFundIds = ValueNotifier<Set<String>>({});

  WishlistService() {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localList = prefs.getStringList(_wishlistKey) ?? [];
      savedFundIds.value = localList.toSet();

      // Sync with Supabase if logged in
      final client = SupabaseService.client;
      final userId = client?.auth.currentUser?.id;
      if (userId != null) {
        final response = await client!
            .from('wishlist')
            .select('fund_id')
            .eq('user_id', userId);

        final remoteSet = (response as List<dynamic>)
            .map((row) => row['fund_id'] as String)
            .toSet();

        final merged = {...savedFundIds.value, ...remoteSet};
        savedFundIds.value = merged;
        await prefs.setStringList(_wishlistKey, merged.toList());
      }
    } catch (e) {
      debugPrint('Wishlist load error: $e');
    }
  }

  bool isSaved(String fundId) {
    return savedFundIds.value.contains(fundId);
  }

  Future<bool> toggleWishlist(String fundId) async {
    final updated = Set<String>.from(savedFundIds.value);
    final isAdding = !updated.contains(fundId);

    if (isAdding) {
      updated.add(fundId);
    } else {
      updated.remove(fundId);
    }

    savedFundIds.value = updated;

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_wishlistKey, updated.toList());

    // Sync to Supabase in background if authenticated
    try {
      final client = SupabaseService.client;
      final userId = client?.auth.currentUser?.id;
      if (userId != null) {
        if (isAdding) {
          await client!.from('wishlist').upsert({
            'user_id': userId,
            'fund_id': fundId,
          });
        } else {
          await client!
              .from('wishlist')
              .delete()
              .eq('user_id', userId)
              .eq('fund_id', fundId);
        }
      }
    } catch (e) {
      debugPrint('Wishlist Supabase sync error: $e');
    }

    return isAdding;
  }
}
