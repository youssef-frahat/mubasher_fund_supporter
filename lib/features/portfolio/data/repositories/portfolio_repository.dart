import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../calculator/data/models/risk_profile_model.dart';
import '../../../home/data/repositories/funds_repository.dart';
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

  /// Get all portfolios for the user.
  /// Uses Supabase DB as the primary source of truth for logged-in users,
  /// with local SharedPreferences fallback for offline or guest mode.
  Future<List<PortfolioModel>> getAllPortfolios() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;

    if (client != null && user != null && user.id.isNotEmpty) {
      try {
        // Fetch portfolios with joined portfolio_items directly from Supabase DB
        final response = await client
            .from('portfolios')
            .select('*, portfolio_items(*)')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .timeout(const Duration(seconds: 5));

        if (response is List && response.isNotEmpty) {
          final List<PortfolioModel> dbPortfolios = response
              .map((e) => PortfolioModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();

            // Cache to local SharedPreferences
            await _savePortfoliosToLocal(dbPortfolios);
            return dbPortfolios;
          } else {
            // First time user in Supabase DB: Create default portfolio in DB
            final defaultPortfolio = await _createDefaultPortfolioInSupabase(user.id);
            if (defaultPortfolio != null) {
              final list = [defaultPortfolio];
              await _savePortfoliosToLocal(list);
              return list;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Supabase fetch portfolios notice (falling back to local): $e');
      }
    }

    // Guest or Offline Fallback
    return _getLocalPortfolios();
  }

  Future<PortfolioModel?> _createDefaultPortfolioInSupabase(String userId) async {
    final client = SupabaseService.client;
    if (client == null) return null;

    try {
      final newPortfolio = PortfolioModel(
        id: 'portfolio-${DateTime.now().millisecondsSinceEpoch}',
        name: 'المحفظة الرئيسية',
        items: [],
        createdAt: DateTime.now(),
      );

      await client.from('portfolios').insert(newPortfolio.toSupabaseJson(userId));
      debugPrint('✅ Default portfolio created in Supabase for user $userId');
      return newPortfolio;
    } catch (e) {
      debugPrint('⚠️ Failed to create default portfolio in Supabase: $e');
      return null;
    }
  }

  Future<List<PortfolioModel>> _getLocalPortfolios() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserPortfoliosKey();
    final jsonString = prefs.getString(key);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => PortfolioModel.fromJson(e)).toList();
      } catch (_) {
        return _getDefaultPortfolios();
      }
    }

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

    final newPortfolio = PortfolioModel(
      id: 'portfolio-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      items: [],
      createdAt: DateTime.now(),
    );

    if (client != null && user != null) {
      try {
        await client.from('portfolios').insert(newPortfolio.toSupabaseJson(user.id));
        debugPrint('✅ Created portfolio "${name}" in Supabase DB');
      } catch (e) {
        debugPrint('⚠️ Supabase createPortfolio notice: $e');
      }
    }

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
    final user = client?.auth.currentUser;

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

    if (client != null && user != null) {
      try {
        // 1. Insert Portfolio into Supabase DB
        await client.from('portfolios').insert(newPortfolio.toSupabaseJson(user.id));

        // 2. Batch insert Portfolio Items into Supabase DB
        if (items.isNotEmpty) {
          final itemsJson = items.map((i) => i.toSupabaseJson(newPortfolioId)).toList();
          await client.from('portfolio_items').insert(itemsJson);
        }

        debugPrint('✅ Created Robo-Advisor portfolio & items in Supabase DB');
      } catch (e) {
        debugPrint('⚠️ Supabase createPortfolioFromRecommendedMix notice: $e');
      }
    }

    final portfolios = await getAllPortfolios();
    portfolios.add(newPortfolio);
    await _savePortfoliosToLocal(portfolios);
    await setActivePortfolioId(newPortfolio.id);

    return newPortfolio;
  }

  /// Delete a portfolio from Supabase DB and local storage
  Future<void> deletePortfolio(String portfolioId) async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;

    if (client != null && user != null) {
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
    final activeId = await getActivePortfolioId();
    final client = SupabaseService.client;

    if (client != null) {
      try {
        await client.from('portfolio_items').insert(newItem.toSupabaseJson(activeId));
        debugPrint('✅ Added portfolio item ${newItem.fundName} to Supabase DB');
      } catch (e) {
        debugPrint('⚠️ Supabase addTransactionToActive notice: $e');
      }
    }

    final portfolios = await getAllPortfolios();
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

    if (client != null) {
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

    if (client != null) {
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

    Map<FundCategory, double> categoryPercentages = {};
    categoryTotals.forEach((category, value) {
      categoryPercentages[category] = totalValue > 0 ? (value / totalValue) * 100 : 0;
    });

    double totalProfitLoss = totalValue - totalCost;
    double totalProfitLossPercentage = totalCost > 0 ? (totalProfitLoss / totalCost) * 100 : 0;

    int categoriesCount = categoryPercentages.keys.length;
    int score = 40;

    if (categoriesCount >= 2) score += 20;
    if (categoriesCount >= 4) score += 20;

    bool isOverConcentrated = categoryPercentages.values.any((pct) => pct > 75.0);
    if (isOverConcentrated) {
      score -= 25;
    } else {
      score += 15;
    }

    score = score.clamp(0, 100);

    Color scoreColor;
    String ratingTextAr;
    String ratingTextEn;

    if (score < 50) {
      scoreColor = const Color(0xFFEF4444);
      ratingTextAr = 'محفظة غير متوازنة (مخاطرة عالية)';
      ratingTextEn = 'Unbalanced Portfolio (High Risk)';
    } else if (score <= 85) {
      scoreColor = const Color(0xFFF59E0B);
      ratingTextAr = 'توزيع متوسط (توازن مقبول)';
      ratingTextEn = 'Moderate Distribution (Acceptable Balance)';
    } else {
      scoreColor = const Color(0xFF10B981);
      ratingTextAr = 'توزيع استثماري مثالي وسليم';
      ratingTextEn = 'Optimal Balanced Portfolio';
    }

    return PortfolioHealthSummary(
      score: score,
      scoreColor: scoreColor,
      ratingTextAr: ratingTextAr,
      ratingTextEn: ratingTextEn,
      categoryPercentages: categoryPercentages,
      totalPortfolioValue: totalValue,
      totalProfitLoss: totalProfitLoss,
      totalProfitLossPercentage: totalProfitLossPercentage,
    );
  }

  /// Refresh the currentNav of every portfolio item from live Supabase data.
  Future<void> refreshPortfolioNavs() async {
    try {
      final liveFunds = await SupabaseFundsRepository().getFunds().timeout(const Duration(seconds: 4));
      if (liveFunds.isEmpty) return;

      final navMap = <String, double>{};
      for (final f in liveFunds) {
        navMap[f.name.trim().toLowerCase()] = f.currentNav;
        if (f.nameAr != null && f.nameAr!.isNotEmpty) {
          navMap[f.nameAr!.trim().toLowerCase()] = f.currentNav;
        }
        if (f.nameEn != null && f.nameEn!.isNotEmpty) {
          navMap[f.nameEn!.trim().toLowerCase()] = f.currentNav;
        }
      }

      final portfolios = await getAllPortfolios();
      bool anyUpdated = false;

      final updatedPortfolios = portfolios.map((portfolio) {
        final updatedItems = portfolio.items.map((item) {
          final key = item.fundName.trim().toLowerCase();
          final liveNav = navMap[key];
          if (liveNav != null && liveNav != item.currentNav) {
            anyUpdated = true;
            return PortfolioItem(
              id: item.id,
              fundId: item.fundId,
              fundName: item.fundName,
              category: item.category,
              units: item.units,
              purchasePrice: item.purchasePrice,
              currentNav: liveNav,
              purchaseDate: item.purchaseDate,
            );
          }
          return item;
        }).toList();

        return PortfolioModel(
          id: portfolio.id,
          name: portfolio.name,
          items: updatedItems,
          createdAt: portfolio.createdAt,
        );
      }).toList();

      if (anyUpdated) {
        await _savePortfoliosToLocal(updatedPortfolios);
        debugPrint('✅ Portfolio NAVs refreshed from Supabase');
      }
    } catch (e) {
      debugPrint('⚠️ refreshPortfolioNavs error: $e');
    }
  }

  List<PortfolioModel> _getDefaultPortfolios() {
    return [
      PortfolioModel(
        id: 'portfolio-default-1',
        name: 'المحفظة الرئيسية',
        createdAt: DateTime.now(),
        items: [],
      ),
    ];
  }
}
