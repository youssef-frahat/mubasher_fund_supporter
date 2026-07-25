import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_item_model.dart';

class PortfolioRepository {
  static const String _storageKey = 'simulated_portfolio_items_v1';
  final SupabaseClient? _supabaseClient;

  PortfolioRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<List<PortfolioItem>> getPortfolioItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    List<PortfolioItem> items = [];

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        items = decoded.map((e) => PortfolioItem.fromJson(e)).toList();
      } catch (_) {
        items = _getInitialDefaultItems();
      }
    } else {
      items = _getInitialDefaultItems();
      await savePortfolioItems(items);
    }

    // Background sync attempt with Supabase if online
    _syncToSupabase(items);

    return items;
  }

  Future<void> savePortfolioItems(List<PortfolioItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> addTransaction(PortfolioItem newItem) async {
    final items = await getPortfolioItems();
    items.add(newItem);
    await savePortfolioItems(items);
  }

  Future<void> removeTransaction(String itemId) async {
    final items = await getPortfolioItems();
    items.removeWhere((e) => e.id == itemId);
    await savePortfolioItems(items);
  }

  PortfolioHealthSummary calculatePortfolioHealth(List<PortfolioItem> items) {
    if (items.isEmpty) {
      return PortfolioHealthSummary(
        score: 0,
        scoreColor: const Color(0xFFEF4444),
        ratingText: 'لا توجد أصول في المحفظة حالياً',
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

    // Calculate Risk Diversification Score (0 to 100)
    int categoriesCount = categoryPercentages.keys.length;
    int score = 40; // Base score

    if (categoriesCount >= 2) score += 20;
    if (categoriesCount >= 4) score += 20;

    // Penalize if one category dominates > 75%
    bool isOverConcentrated = categoryPercentages.values.any((pct) => pct > 75.0);
    if (isOverConcentrated) {
      score -= 25;
    } else {
      score += 15;
    }

    // Clamp score 0 to 100
    score = score.clamp(0, 100);

    Color scoreColor;
    String ratingText;

    if (score < 50) {
      scoreColor = const Color(0xFFEF4444); // Red
      ratingText = 'محفظة غير متوازنة (مخاطرة عالية)';
    } else if (score <= 85) {
      scoreColor = const Color(0xFFF59E0B); // Yellow
      ratingText = 'توزيع متوسط (توازن مقبول)';
    } else {
      scoreColor = const Color(0xFF10B981); // Green
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

  void _syncToSupabase(List<PortfolioItem> items) async {
    try {
      final client = _supabaseClient;
      if (client != null && client.auth.currentUser != null) {
        // Sync logic to Supabase if authenticated
      }
    } catch (_) {}
  }

  List<PortfolioItem> _getInitialDefaultItems() {
    return [
      PortfolioItem(
        id: '1',
        fundId: 'fund-nbe-4',
        fundName: 'صندوق البنك الأهلي الرابع اليومي',
        category: FundCategory.moneyMarket,
        units: 100,
        purchasePrice: 240.0,
        currentNav: 268.5,
        purchaseDate: DateTime.now().subtract(const Duration(days: 90)),
      ),
      PortfolioItem(
        id: '2',
        fundId: 'fund-azimut-gold',
        fundName: 'صندوق أزموت الذهب (Azimut Gold)',
        category: FundCategory.gold,
        units: 50,
        purchasePrice: 180.0,
        currentNav: 215.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 60)),
      ),
      PortfolioItem(
        id: '3',
        fundId: 'fund-beltone-equity',
        fundName: 'صندوق بلتون للأسهم المصرية',
        category: FundCategory.equity,
        units: 30,
        purchasePrice: 310.0,
        currentNav: 345.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }
}
