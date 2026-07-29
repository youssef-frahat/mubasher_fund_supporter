import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../calculator/data/models/risk_profile_model.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/portfolio_item_model.dart';
import '../models/portfolio_model.dart';

class PortfolioRepository {
  String _getUserPortfoliosKey() {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (user != null && user.id.isNotEmpty) {
      return 'multi_portfolios_${user.id}';
    }
    return 'multi_portfolios_guest_v3';
  }

  String _getUserActiveIdKey() {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (user != null && user.id.isNotEmpty) {
      return 'active_portfolio_id_${user.id}';
    }
    return 'active_portfolio_id_guest_v3';
  }

  static bool _isValidUuid(String str) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(str);
  }

  /// Get all portfolios for the user.
  /// Supabase PostgreSQL DB is the SINGLE SOURCE OF TRUTH for logged-in users.
  /// Auto-syncs any local SharedPreferences items (e.g. 7223 EGP) into Supabase DB.
  Future<List<PortfolioModel>> getAllPortfolios() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;

    if (client != null && user != null && user.id.isNotEmpty) {
      try {
        // 1. Fetch DB portfolios from Supabase
        var dbPortfolios = await _getSupabasePortfoliosDirectly(user.id);

        // 2. Auto-sync any local SharedPreferences items into Supabase DB
        await _syncLocalItemsToSupabase(user.id, dbPortfolios);

        // 3. Re-fetch clean updated DB portfolios from Supabase
        dbPortfolios = await _getSupabasePortfoliosDirectly(user.id);

        if (dbPortfolios.isNotEmpty) {
          await _savePortfoliosToLocal(dbPortfolios);
          return dbPortfolios;
        } else {
          // If no portfolio exists in DB, create default portfolio in DB
          final defaultP = await _createDefaultPortfolioInSupabase(user.id);
          if (defaultP != null) {
            final list = [defaultP];
            await _savePortfoliosToLocal(list);
            return list;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Supabase fetch portfolios notice (falling back to local): $e');
      }
    }

    return _getLocalPortfolios();
  }

  Future<List<PortfolioModel>> _getSupabasePortfoliosDirectly(String userId) async {
    final client = SupabaseService.client;
    if (client == null) return [];
    try {
      final response = await client
          .from('portfolios')
          .select('*, portfolio_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 6));

      if ((response as List).isNotEmpty) {
        return response
            .map((e) => PortfolioModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ _getSupabasePortfoliosDirectly notice: $e');
    }
    return [];
  }

  /// Auto-sync local items (like the 7223 EGP portfolio) into Supabase PostgreSQL DB
  Future<void> _syncLocalItemsToSupabase(String userId, List<PortfolioModel> dbPortfolios) async {
    final client = SupabaseService.client;
    if (client == null) return;

    try {
      final localPortfolios = await _getLocalPortfoliosWithoutFallback();
      if (localPortfolios.isEmpty) return;

      PortfolioModel? targetDbPortfolio;
      if (dbPortfolios.isNotEmpty) {
        targetDbPortfolio = dbPortfolios.first;
      } else {
        targetDbPortfolio = await _createDefaultPortfolioInSupabase(userId);
      }

      if (targetDbPortfolio == null) return;

      final existingDbFundNames = targetDbPortfolio.items.map((i) => i.fundName.trim()).toSet();
      final List<Map<String, dynamic>> itemsToInsert = [];

      for (var localP in localPortfolios) {
        for (var localItem in localP.items) {
          if (localItem.fundName.isNotEmpty && !existingDbFundNames.contains(localItem.fundName.trim())) {
            itemsToInsert.add(localItem.toSupabaseJson(targetDbPortfolio.id));
            existingDbFundNames.add(localItem.fundName.trim());
          }
        }
      }

      if (itemsToInsert.isNotEmpty) {
        await client.from('portfolio_items').insert(itemsToInsert);
        debugPrint('✅ Auto-synced ${itemsToInsert.length} local items to Supabase DB portfolio ${targetDbPortfolio.id}');
      }
    } catch (e) {
      debugPrint('⚠️ _syncLocalItemsToSupabase notice: $e');
    }
  }

  Future<List<PortfolioModel>> refreshPortfolioNavs([List<PortfolioModel>? portfolios]) async {
    return getAllPortfolios();
  }

  Future<PortfolioModel?> _createDefaultPortfolioInSupabase(String userId) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    try {
      final res = await client
          .from('portfolios')
          .insert({'user_id': userId, 'name': 'المحفظة الرئيسية'})
          .select('*, portfolio_items(*)')
          .single();

      final created = PortfolioModel.fromJson(Map<String, dynamic>.from(res as Map));
      debugPrint('✅ Default portfolio created in Supabase with UUID ${created.id}');
      return created;
    } catch (e) {
      debugPrint('⚠️ Failed to create default portfolio in Supabase: $e');
      return null;
    }
  }

  Future<List<PortfolioModel>> _getLocalPortfoliosWithoutFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserPortfoliosKey();
    final jsonString = prefs.getString(key);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => PortfolioModel.fromJson(e)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<List<PortfolioModel>> _getLocalPortfolios() async {
    final list = await _getLocalPortfoliosWithoutFallback();
    if (list.isNotEmpty) return list;

    final defaultList = _getDefaultPortfolios();
    await _savePortfoliosToLocal(defaultList);
    return defaultList;
  }

  Future<void> _savePortfoliosToLocal(List<PortfolioModel> portfolios) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserPortfoliosKey();
    final jsonList = portfolios.map((e) => e.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  Future<String> getActivePortfolioId() async {
    final prefs = await SharedPreferences.getInstance();
    final activeKey = _getUserActiveIdKey();
    final id = prefs.getString(activeKey);
    final all = await getAllPortfolios();

    if (id != null && all.any((p) => p.id == id)) {
      return id;
    }
    final firstId = all.first.id;
    await setActivePortfolioId(firstId);
    return firstId;
  }

  Future<void> setActivePortfolioId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final activeKey = _getUserActiveIdKey();
    await prefs.setString(activeKey, id);
  }

  /// Create a new portfolio in Supabase DB and local storage
  Future<PortfolioModel> createPortfolio(String name) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;

    if (client != null && user != null) {
      try {
        final res = await client
            .from('portfolios')
            .insert({'user_id': user.id, 'name': name})
            .select('*, portfolio_items(*)')
            .single();

        final created = PortfolioModel.fromJson(Map<String, dynamic>.from(res as Map));
        await setActivePortfolioId(created.id);
        debugPrint('✅ Created portfolio "${created.name}" in Supabase DB with ID ${created.id}');
        return created;
      } catch (e) {
        debugPrint('⚠️ Supabase createPortfolio notice: $e');
      }
    }

    final newPortfolio = PortfolioModel(
      id: 'portfolio-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      items: [],
      createdAt: DateTime.now(),
    );
    final portfolios = await getAllPortfolios();
    portfolios.add(newPortfolio);
    await _savePortfoliosToLocal(portfolios);
    await setActivePortfolioId(newPortfolio.id);

    return newPortfolio;
  }

  /// Create a simulated portfolio directly from Robo-Advisor recommendations in Supabase DB
  Future<PortfolioModel> createPortfolioFromRecommendedMix({
    required String name,
    required RiskAssessmentResult riskResult,
    required double totalAmount,
  }) async {
    final client = SupabaseService.client;
    var user = client?.auth.currentUser;

    // If user is guest, attempt anonymous sign in so portfolio is persisted in Supabase DB for Dashboard visibility
    if (client != null && user == null) {
      try {
        final anonRes = await client.auth.signInAnonymously();
        user = anonRes.user ?? client.auth.currentUser;
      } catch (e) {
        debugPrint('⚠️ Anonymous sign-in notice: $e');
      }
    }

    if (client != null && user != null) {
      try {
        final res = await client
            .from('portfolios')
            .insert({'user_id': user.id, 'name': name})
            .select()
            .single();

        final dbPortfolioId = res['id'].toString();
        final List<Map<String, dynamic>> itemsJson = [];

        for (var alloc in riskResult.recommendedPortfolioMix) {
          final allocatedEgp = alloc.getAllocatedAmount(totalAmount);
          double mockNav = 100.0;
          if (alloc.categoryNameAr.contains('ذهب')) mockNav = 48.5;
          if (alloc.categoryNameAr.contains('أسهم')) mockNav = 185.0;
          if (alloc.categoryNameAr.contains('سيولة')) mockNav = 12.5;

          final units = allocatedEgp / mockNav;
          final cat = alloc.categoryNameAr.contains('ذهب')
              ? FundCategory.gold
              : alloc.categoryNameAr.contains('أسهم')
                  ? FundCategory.equity
                  : alloc.categoryNameAr.contains('شريعة')
                      ? FundCategory.islamic
                      : FundCategory.moneyMarket;

          itemsJson.add({
            'portfolio_id': dbPortfolioId,
            'fund_name': alloc.fundName,
            'category': cat.name,
            'units': units,
            'purchase_price': mockNav,
            'current_nav': mockNav * (1 + (riskResult.expectedRoiPercentage / 100)),
            'purchase_date': DateTime.now().toIso8601String(),
          });
        }

        if (itemsJson.isNotEmpty) {
          await client.from('portfolio_items').insert(itemsJson);
        }

        final fullRes = await client
            .from('portfolios')
            .select('*, portfolio_items(*)')
            .eq('id', dbPortfolioId)
            .single();

        final createdPortfolio = PortfolioModel.fromJson(Map<String, dynamic>.from(fullRes as Map));
        await setActivePortfolioId(createdPortfolio.id);

        // Keep local cache in sync so Flutter local state matches DB instantly
        final localList = await _getLocalPortfoliosWithoutFallback();
        if (!localList.any((p) => p.id == createdPortfolio.id)) {
          localList.add(createdPortfolio);
          await _savePortfoliosToLocal(localList);
        }

        debugPrint('✅ Created Robo-Advisor portfolio & items in Supabase DB (${createdPortfolio.id})');
        return createdPortfolio;
      } catch (e) {
        debugPrint('⚠️ Supabase createPortfolioFromRecommendedMix notice: $e');
      }
    }

    final newPortfolioId = 'portfolio-${DateTime.now().millisecondsSinceEpoch}';
    final List<PortfolioItem> items = [];

    for (var alloc in riskResult.recommendedPortfolioMix) {
      final allocatedEgp = alloc.getAllocatedAmount(totalAmount);
      double mockNav = 100.0;
      if (alloc.categoryNameAr.contains('ذهب')) mockNav = 48.5;
      if (alloc.categoryNameAr.contains('أسهم')) mockNav = 185.0;
      if (alloc.categoryNameAr.contains('سيولة')) mockNav = 12.5;

      final units = allocatedEgp / mockNav;

      items.add(
        PortfolioItem(
          id: 'item-${DateTime.now().millisecondsSinceEpoch}-${items.length}',
          fundId: 'fund-${items.length}',
          fundName: alloc.fundName,
          category: alloc.categoryNameAr.contains('ذهب')
              ? FundCategory.gold
              : alloc.categoryNameAr.contains('أسهم')
                  ? FundCategory.equity
                  : alloc.categoryNameAr.contains('شريعة')
                      ? FundCategory.islamic
                      : FundCategory.moneyMarket,
          units: units,
          purchasePrice: mockNav,
          currentNav: mockNav * (1 + (riskResult.expectedRoiPercentage / 100)),
          purchaseDate: DateTime.now(),
        ),
      );
    }

    final newPortfolio = PortfolioModel(
      id: newPortfolioId,
      name: name,
      items: items,
      createdAt: DateTime.now(),
    );

    final portfolios = await _getLocalPortfoliosWithoutFallback();
    portfolios.add(newPortfolio);
    await _savePortfoliosToLocal(portfolios);
    await setActivePortfolioId(newPortfolio.id);

    return newPortfolio;
  }

  /// Delete a portfolio from Supabase DB and local storage
  Future<void> deletePortfolio(String portfolioId) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;

    if (client != null && user != null && _isValidUuid(portfolioId)) {
      try {
        await client.from('portfolios').delete().eq('id', portfolioId).eq('user_id', user.id);
        debugPrint('✅ Deleted portfolio $portfolioId from Supabase DB');
      } catch (e) {
        debugPrint('⚠️ Supabase deletePortfolio notice: $e');
      }
    }

    final portfolios = await getAllPortfolios();
    if (portfolios.length <= 1) return;

    portfolios.removeWhere((p) => p.id == portfolioId);
    await _savePortfoliosToLocal(portfolios);

    final activeId = await getActivePortfolioId();
    if (activeId == portfolioId) {
      await setActivePortfolioId(portfolios.first.id);
    }
  }

  /// Add a transaction/item to active portfolio in Supabase DB and local storage
  Future<void> addTransactionToActive(PortfolioItem newItem) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;

    if (client != null && user != null) {
      try {
        var dbPortfolios = await _getSupabasePortfoliosDirectly(user.id);
        if (dbPortfolios.isEmpty) {
          final defaultP = await _createDefaultPortfolioInSupabase(user.id);
          if (defaultP != null) dbPortfolios = [defaultP];
        }

        if (dbPortfolios.isNotEmpty) {
          final targetP = dbPortfolios.first;
          await client.from('portfolio_items').insert(newItem.toSupabaseJson(targetP.id));
          debugPrint('✅ Added portfolio item ${newItem.fundName} to Supabase DB for portfolio ${targetP.id}');
        }
      } catch (e) {
        debugPrint('⚠️ Supabase addTransactionToActive notice: $e');
      }
    }

    final portfolios = await getAllPortfolios();
    final activeId = await getActivePortfolioId();
    final index = portfolios.indexWhere((p) => p.id == activeId);

    if (index != -1) {
      final current = portfolios[index];
      final updatedItems = List<PortfolioItem>.from(current.items)..add(newItem);
      portfolios[index] = PortfolioModel(
        id: current.id,
        name: current.name,
        items: updatedItems,
        createdAt: current.createdAt,
      );
      await _savePortfoliosToLocal(portfolios);
    }
  }

  /// Update units of an item in active portfolio in Supabase DB and local storage
  Future<void> updateTransactionUnitsInActive(String itemId, double newUnits) async {
    final activeId = await getActivePortfolioId();
    final client = SupabaseService.client;

    if (client != null && _isValidUuid(itemId)) {
      try {
        if (newUnits <= 0) {
          await client.from('portfolio_items').delete().eq('id', itemId);
        } else {
          await client.from('portfolio_items').update({'units': newUnits}).eq('id', itemId);
        }
        debugPrint('✅ Updated item $itemId units in Supabase DB');
      } catch (e) {
        debugPrint('⚠️ Supabase updateTransactionUnitsInActive notice: $e');
      }
    }

    final portfolios = await getAllPortfolios();
    final index = portfolios.indexWhere((p) => p.id == activeId);

    if (index != -1) {
      final current = portfolios[index];
      final updatedItems = List<PortfolioItem>.from(current.items);
      final itemIndex = updatedItems.indexWhere((i) => i.id == itemId);

      if (itemIndex != -1) {
        if (newUnits <= 0) {
          updatedItems.removeAt(itemIndex);
        } else {
          final existing = updatedItems[itemIndex];
          updatedItems[itemIndex] = PortfolioItem(
            id: existing.id,
            fundId: existing.fundId,
            fundName: existing.fundName,
            category: existing.category,
            units: newUnits,
            purchasePrice: existing.purchasePrice,
            currentNav: existing.currentNav,
            purchaseDate: existing.purchaseDate,
          );
        }

        portfolios[index] = PortfolioModel(
          id: current.id,
          name: current.name,
          items: updatedItems,
          createdAt: current.createdAt,
        );
        await _savePortfoliosToLocal(portfolios);
      }
    }
  }

  /// Remove an item from active portfolio in Supabase DB and local storage
  Future<void> removeTransactionFromActive(String itemId) async {
    final client = SupabaseService.client;

    if (client != null && _isValidUuid(itemId)) {
      try {
        await client.from('portfolio_items').delete().eq('id', itemId);
        debugPrint('✅ Removed portfolio item $itemId from Supabase DB');
      } catch (e) {
        debugPrint('⚠️ Supabase removeTransactionFromActive notice: $e');
      }
    }

    final portfolios = await getAllPortfolios();
    final activeId = await getActivePortfolioId();
    final index = portfolios.indexWhere((p) => p.id == activeId);

    if (index != -1) {
      final current = portfolios[index];
      final updatedItems = List<PortfolioItem>.from(current.items)
        ..removeWhere((i) => i.id == itemId);

      portfolios[index] = PortfolioModel(
        id: current.id,
        name: current.name,
        items: updatedItems,
        createdAt: current.createdAt,
      );
      await _savePortfoliosToLocal(portfolios);
    }
  }

  PortfolioHealthSummary calculatePortfolioHealth(List<PortfolioItem> items) {
    if (items.isEmpty) {
      return PortfolioHealthSummary(
        score: 0,
        scoreColor: const Color(0xFFEF4444),
        ratingTextAr: 'لا توجد أصول في هذه المحفظة حالياً',
        ratingTextEn: 'No assets in this portfolio currently',
        categoryPercentages: {},
        totalPortfolioValue: 0,
        totalProfitLoss: 0,
        totalProfitLossPercentage: 0,
      );
    }

    double totalValue = 0;
    double totalCost = 0;
    Map<FundCategory, double> categoryTotals = {};

    for (var item in items) {
      totalValue += item.currentValue;
      totalCost += item.totalCost;
      categoryTotals[item.category] = (categoryTotals[item.category] ?? 0) + item.currentValue;
    }

    double totalProfit = totalValue - totalCost;
    double totalProfitPct = totalCost > 0 ? (totalProfit / totalCost) * 100 : 0;

    Map<FundCategory, double> categoryPcts = {};
    if (totalValue > 0) {
      categoryTotals.forEach((cat, val) {
        categoryPcts[cat] = (val / totalValue) * 100;
      });
    }

    int score = 0;
    final numCategories = categoryPcts.length;
    if (numCategories >= 3) {
      score += 40;
    } else if (numCategories == 2) {
      score += 25;
    } else {
      score += 10;
    }

    double maxCategoryPct = 0;
    categoryPcts.forEach((_, pct) {
      if (pct > maxCategoryPct) maxCategoryPct = pct;
    });

    if (maxCategoryPct <= 45) {
      score += 40;
    } else if (maxCategoryPct <= 70) {
      score += 25;
    } else {
      score += 10;
    }

    if (totalProfitPct >= 15) {
      score += 20;
    } else if (totalProfitPct >= 0) {
      score += 10;
    } else {
      score += 5;
    }

    score = score.clamp(0, 100);

    Color scoreColor;
    String ratingAr;
    String ratingEn;

    if (score >= 80) {
      scoreColor = const Color(0xFF10B981);
      ratingAr = 'محفظة متوازنة وممتازة (تنويع عالي 🟢)';
      ratingEn = 'Excellent Balanced Portfolio (High Diversification 🟢)';
    } else if (score >= 50) {
      scoreColor = const Color(0xFFF59E0B);
      ratingAr = 'محفظة متوسطة المخاطر والتنويع 🟡';
      ratingEn = 'Moderate Risk & Diversification 🟡';
    } else {
      scoreColor = const Color(0xFFEF4444);
      ratingAr = 'محفظة غير متوازنة (مخاطرة عالية 🔴)';
      ratingEn = 'Unbalanced High Risk Portfolio 🔴';
    }

    return PortfolioHealthSummary(
      score: score,
      scoreColor: scoreColor,
      ratingTextAr: ratingAr,
      ratingTextEn: ratingEn,
      categoryPercentages: categoryPcts,
      totalPortfolioValue: totalValue,
      totalProfitLoss: totalProfit,
      totalProfitLossPercentage: totalProfitPct,
    );
  }

  List<PortfolioModel> _getDefaultPortfolios() {
    return [
      PortfolioModel(
        id: 'portfolio-default-1',
        name: 'المحفظة الرئيسية',
        items: [
          PortfolioItem(
            id: 'item-default-1',
            fundId: 'f1',
            fundName: 'صندوق الأهلي الرابع اليومي',
            category: FundCategory.moneyMarket,
            units: 100,
            purchasePrice: 288.50,
            currentNav: 312.40,
            purchaseDate: DateTime.now().subtract(const Duration(days: 90)),
          ),
          PortfolioItem(
            id: 'item-default-2',
            fundId: 'f2',
            fundName: 'صندوق أزيموت الذهب (AZG)',
            category: FundCategory.gold,
            units: 50,
            purchasePrice: 42.00,
            currentNav: 48.60,
            purchaseDate: DateTime.now().subtract(const Duration(days: 45)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
    ];
  }
}
