import 'package:flutter_test/flutter_test.dart';
import 'package:mubasher_fund_supporter/features/portfolio/data/models/portfolio_item_model.dart';
import 'package:mubasher_fund_supporter/features/portfolio/data/models/portfolio_model.dart';

void main() {
  group('Portfolio Financial Accounting Tests', () {
    test('Calculates total current value, total cost, and profit accurately', () {
      final now = DateTime.now();
      final item1 = PortfolioItem(
        id: 'item-1',
        fundId: 'f1',
        fundName: 'صندوق أسهم',
        category: FundCategory.equity,
        units: 100.0,
        purchasePrice: 10.0, // Cost: 1000 EGP
        currentNav: 15.0,     // Current: 1500 EGP (+500 EGP)
        purchaseDate: now,
      );

      final item2 = PortfolioItem(
        id: 'item-2',
        fundId: 'f2',
        fundName: 'صندوق ذهب',
        category: FundCategory.gold,
        units: 50.0,
        purchasePrice: 20.0, // Cost: 1000 EGP
        currentNav: 18.0,    // Current: 900 EGP (-100 EGP)
        purchaseDate: now,
      );

      final portfolio = PortfolioModel(
        id: 'p-1',
        name: 'محفظة الاختبار',
        items: [item1, item2],
        createdAt: now,
      );

      // Total Cost = 1000 + 1000 = 2000 EGP
      expect(portfolio.totalCost, 2000.0);

      // Total Value = 1500 + 900 = 2400 EGP
      expect(portfolio.totalCurrentValue, 2400.0);

      // Total Profit = 2400 - 2000 = 400 EGP
      expect(portfolio.totalProfitLoss, 400.0);

      // Profit % = (400 / 2000) * 100 = 20.0%
      expect(portfolio.totalProfitLossPercentage, 20.0);
    });

    test('Handles empty portfolio gracefully without division by zero', () {
      final emptyPortfolio = PortfolioModel(
        id: 'p-empty',
        name: 'محفظة فارغة',
        items: [],
        createdAt: DateTime.now(),
      );

      expect(emptyPortfolio.totalCost, 0.0);
      expect(emptyPortfolio.totalCurrentValue, 0.0);
      expect(emptyPortfolio.totalProfitLoss, 0.0);
      expect(emptyPortfolio.totalProfitLossPercentage, 0.0);
    });

    test('PortfolioItem preserves fund_id during toSupabaseJson and fromJson cycles', () {
      final item = PortfolioItem(
        id: '25a7538d-ec82-4f3f-981f-ebcfa3b59325',
        fundId: 'eg_fund_001',
        fundName: 'صندوق سهمي 70',
        category: FundCategory.equity,
        units: 50.0,
        purchasePrice: 100.0,
        currentNav: 120.0,
        purchaseDate: DateTime(2026, 1, 1),
      );

      final supabaseJson = item.toSupabaseJson('portfolio-uuid-123');
      expect(supabaseJson['fund_id'], 'eg_fund_001');
      expect(supabaseJson['portfolio_id'], 'portfolio-uuid-123');
      expect(supabaseJson['fund_name'], 'صندوق سهمي 70');

      final reconstructed = PortfolioItem.fromJson(supabaseJson);
      expect(reconstructed.fundId, 'eg_fund_001');
      expect(reconstructed.fundName, 'صندوق سهمي 70');
    });
  });
}
