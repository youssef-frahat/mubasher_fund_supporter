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

  Future<List<PortfolioModel>> getAllPortfolios() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserPortfoliosKey();
    final jsonString = prefs.getString(key);

    List<PortfolioModel> portfolios = [];

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        portfolios = decoded.map((e) => PortfolioModel.fromJson(e)).toList();
      } catch (_) {
        portfolios = _getDefaultPortfolios();
      }
    } else {
      // Brand new user gets a clean empty portfolio
      portfolios = _getDefaultPortfolios();
      await savePortfolios(portfolios);
    }

    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client != null && user != null && portfolios.isNotEmpty) {
      _syncUserAndPortfoliosToSupabase(user, portfolios);
    }

    return portfolios;
  }

  Future<void> _syncUserAndPortfoliosToSupabase(dynamic user, List<PortfolioModel> portfolios) async {
    final client = SupabaseService.client;
    if (client == null || user == null) return;

    try {
      final name = user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@').first ??
          'مستثمر وثيقة';
      final phone = user.userMetadata?['phone'] ?? user.phone ?? user.email;
      final avatarUrl = user.userMetadata?['avatar_url'];
      final isVerified = user.emailConfirmedAt != null || user.appMetadata['provider'] == 'google';

      // 1. Sync User Profile to Supabase DB
      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'is_verified': isVerified,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Sync User Portfolios to Supabase DB
      for (var p in portfolios) {
        await client.from('portfolios').upsert({
          'user_id': user.id,
          'name': p.name,
          'created_at': p.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      debugPrint('✅ Portfolios & Profile synced to Supabase for user ${user.id}');
    } catch (e) {
      debugPrint('⚠️ Supabase user/portfolio sync notice: $e');
    }
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

  Future<void> savePortfolios(List<PortfolioModel> portfolios) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserPortfoliosKey();
    final jsonList = portfolios.map((e) => e.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));

    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      await _syncUserAndPortfoliosToSupabase(user, portfolios);
    }
  }

  Future<PortfolioModel> createPortfolio(String name) async {
    final portfolios = await getAllPortfolios();
    final newPortfolio = PortfolioModel(
      id: 'portfolio-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      items: [],
      createdAt: DateTime.now(),
    );
    portfolios.add(newPortfolio);
    await savePortfolios(portfolios);
    await setActivePortfolioId(newPortfolio.id);
    return newPortfolio;
  }

  /// Create a simulated portfolio directly from Robo-Advisor recommendations
  Future<PortfolioModel> createPortfolioFromRecommendedMix({
    required String name,
    required RiskAssessmentResult riskResult,
    required double totalAmount,
  }) async {
    final portfolios = await getAllPortfolios();

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
      id: 'portfolio-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      items: items,
      createdAt: DateTime.now(),
    );

    portfolios.add(newPortfolio);
    await savePortfolios(portfolios);
    await setActivePortfolioId(newPortfolio.id);

    // Save transactions to Supabase DB if user is logged in
    final client = SupabaseService.client;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        for (var item in items) {
          await client.from('transactions').insert({
            'user_id': userId,
            'fund_name': item.fundName,
            'category': item.category.name,
            'units': item.units,
            'purchase_price': item.purchasePrice,
            'current_nav': item.currentNav,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Supabase recommended mix transactions insert notice: $e');
      }
    }

    return newPortfolio;
  }

  Future<void> deletePortfolio(String portfolioId) async {
    final portfolios = await getAllPortfolios();
    if (portfolios.length <= 1) return;

    portfolios.removeWhere((p) => p.id == portfolioId);
    await savePortfolios(portfolios);

    final activeId = await getActivePortfolioId();
    if (activeId == portfolioId) {
      await setActivePortfolioId(portfolios.first.id);
    }
  }

  Future<void> addTransactionToActive(PortfolioItem newItem) async {
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
      await savePortfolios(portfolios);
    }

    // Sync transaction insertion to Supabase DB
    final client = SupabaseService.client;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        await client.from('transactions').insert({
          'user_id': userId,
          'fund_name': newItem.fundName,
          'category': newItem.category.name,
          'units': newItem.units,
          'purchase_price': newItem.purchasePrice,
          'current_nav': newItem.currentNav,
          'created_at': newItem.purchaseDate.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Supabase transaction insert notice: $e');
      }
    }
  }

  Future<void> updateTransactionUnitsInActive(String itemId, double newUnits) async {
    final portfolios = await getAllPortfolios();
    final activeId = await getActivePortfolioId();

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
        await savePortfolios(portfolios);
      }
    }
  }

  Future<void> removeTransactionFromActive(String itemId) async {
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
      await savePortfolios(portfolios);
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
  /// Called automatically on each portfolio load so P&L always reflects
  /// the latest NAV the admin has set.
  Future<void> refreshPortfolioNavs() async {
    try {
      final liveFunds = await SupabaseFundsRepository().getFunds().timeout(const Duration(seconds: 4));
      if (liveFunds.isEmpty) return;

      // Build a lookup map: fund name (lower-case trimmed) → currentNav
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
        await savePortfolios(updatedPortfolios);
        debugPrint('✅ Portfolio NAVs refreshed from Supabase');
      }
    } catch (e) {
      debugPrint('⚠️ refreshPortfolioNavs error (non-critical): $e');
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
