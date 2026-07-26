import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../calculator/data/models/risk_profile_model.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/portfolio_item_model.dart';
import '../models/portfolio_model.dart';

class PortfolioRepository {
  static const String _portfoliosKey = 'multi_portfolios_v2';
  static const String _activeIdKey = 'active_portfolio_id_v2';

  Future<List<PortfolioModel>> getAllPortfolios() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_portfoliosKey);

    List<PortfolioModel> portfolios = [];

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        portfolios = decoded.map((e) => PortfolioModel.fromJson(e)).toList();
      } catch (_) {
        portfolios = _getDefaultPortfolios();
      }
    } else {
      portfolios = _getDefaultPortfolios();
      await savePortfolios(portfolios);
    }

    return portfolios;
  }

  Future<String> getActivePortfolioId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_activeIdKey);
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
    await prefs.setString(_activeIdKey, id);
  }

  Future<void> savePortfolios(List<PortfolioModel> portfolios) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = portfolios.map((e) => e.toJson()).toList();
    await prefs.setString(_portfoliosKey, jsonEncode(jsonList));

    // Supabase sync for logged in user
    final client = SupabaseService.client;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        for (var p in portfolios) {
          final isUuid = p.id.length == 36 && p.id.contains('-');
          await client.from('portfolios').upsert({
            if (isUuid) 'id': p.id,
            'user_id': userId,
            'name': p.name,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Supabase portfolio sync notice: $e');
      }
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
        ratingText: 'لا توجد أصول في هذه المحفظة حالياً',
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
    String ratingText;

    if (score < 50) {
      scoreColor = const Color(0xFFEF4444);
      ratingText = 'محفظة غير متوازنة (مخاطرة عالية)';
    } else if (score <= 85) {
      scoreColor = const Color(0xFFF59E0B);
      ratingText = 'توزيع متوسط (توازن مقبول)';
    } else {
      scoreColor = const Color(0xFF10B981);
      ratingText = 'توزيع استثماري مثالي وسليم';
    }

    return PortfolioHealthSummary(
      score: score,
      scoreColor: scoreColor,
      ratingText: ratingText,
      categoryPercentages: categoryPercentages,
      totalPortfolioValue: totalValue,
      totalProfitLoss: totalProfitLoss,
      totalProfitLossPercentage: totalProfitLossPercentage,
    );
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
