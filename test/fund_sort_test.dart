import 'package:flutter_test/flutter_test.dart';
import 'package:mubasher_fund_supporter/features/funds/domain/models/fund_sort_option.dart';
import 'package:mubasher_fund_supporter/features/home/data/models/fund_model.dart';

void main() {
  group('FundSortOption Tests', () {
    final fundA = FundModel(
      id: '1',
      name: 'صندوق أ - ألفا',
      nameAr: 'صندوق أ - ألفا',
      nameEn: 'Alpha Fund',
      managerName: 'مدير أ',
      currentNav: 150.0,
      ytdReturn: 45.0,
      dailyChange: 2.5,
      riskLevel: 'High',
      category: 'Equity',
    );

    final fundB = FundModel(
      id: '2',
      name: 'صندوق ب - بيتا',
      nameAr: 'صندوق ب - بيتا',
      nameEn: 'Beta Fund',
      managerName: 'مدير ب',
      currentNav: 80.0,
      ytdReturn: 15.0,
      dailyChange: -0.5,
      riskLevel: 'Low',
      category: 'MoneyMarket',
    );

    final fundC = FundModel(
      id: '3',
      name: 'صندوق ج - جاما',
      nameAr: 'صندوق ج - جاما',
      nameEn: 'Gamma Fund',
      managerName: 'مدير ج',
      currentNav: 300.0,
      ytdReturn: 28.0,
      dailyChange: 0.8,
      riskLevel: 'Medium',
      category: 'Balanced',
    );

    final funds = [fundA, fundB, fundC];

    test('Sort by highestReturn orders funds descending by YTD', () {
      final sorted = FundSortOption.highestReturn.sort(funds);
      expect(sorted.map((f) => f.id).toList(), ['1', '3', '2']);
    });

    test('Sort by lowestReturn orders funds ascending by YTD', () {
      final sorted = FundSortOption.lowestReturn.sort(funds);
      expect(sorted.map((f) => f.id).toList(), ['2', '3', '1']);
    });

    test('Sort by highestPrice orders funds descending by currentNav', () {
      final sorted = FundSortOption.highestPrice.sort(funds);
      expect(sorted.map((f) => f.id).toList(), ['3', '1', '2']);
    });

    test('Sort by lowestPrice orders funds ascending by currentNav', () {
      final sorted = FundSortOption.lowestPrice.sort(funds);
      expect(sorted.map((f) => f.id).toList(), ['2', '1', '3']);
    });

    test('Sort by dailyGainers orders funds descending by dailyChange', () {
      final sorted = FundSortOption.dailyGainers.sort(funds);
      expect(sorted.map((f) => f.id).toList(), ['1', '3', '2']);
    });

    test('Sort by lowestRisk orders Low -> Medium -> High', () {
      final sorted = FundSortOption.lowestRisk.sort(funds);
      expect(sorted.map((f) => f.riskLevel).toList(), ['Low', 'Medium', 'High']);
    });

    test('Sort by highestRisk orders High -> Medium -> Low', () {
      final sorted = FundSortOption.highestRisk.sort(funds);
      expect(sorted.map((f) => f.riskLevel).toList(), ['High', 'Medium', 'Low']);
    });

    test('Sort by nameAsc in English orders Alpha, Beta, Gamma', () {
      final sorted = FundSortOption.nameAsc.sort(funds, isArabic: false);
      expect(sorted.map((f) => f.nameEn).toList(), ['Alpha Fund', 'Beta Fund', 'Gamma Fund']);
    });
  });
}
