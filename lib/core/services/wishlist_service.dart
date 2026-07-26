import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase/supabase_service.dart';

class WishlistService {
  static const String _wishlistKey = 'saved_wishlist_fund_ids_v1';
  final ValueNotifier<Set<String>> savedFundIds = ValueNotifier<Set<String>>({});
  final ValueNotifier<List<String>> orderedFundIds = ValueNotifier<List<String>>([]);

  WishlistService() {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localList = prefs.getStringList(_wishlistKey) ?? [];
      savedFundIds.value = localList.toSet();
      orderedFundIds.value = localList;

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
        orderedFundIds.value = merged.toList();
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
    final updatedSet = Set<String>.from(savedFundIds.value);
    final updatedList = List<String>.from(orderedFundIds.value);
    final isAdding = !updatedSet.contains(fundId);

    if (isAdding) {
      updatedSet.add(fundId);
      if (!updatedList.contains(fundId)) {
        updatedList.add(fundId);
      }
    } else {
      updatedSet.remove(fundId);
      updatedList.remove(fundId);
    }

    savedFundIds.value = updatedSet;
    orderedFundIds.value = updatedList;

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_wishlistKey, updatedList);

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

  Future<void> reorderWishlist(List<String> newOrderedIds) async {
    savedFundIds.value = newOrderedIds.toSet();
    orderedFundIds.value = newOrderedIds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_wishlistKey, newOrderedIds);
  }
}
