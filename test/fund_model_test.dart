import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mubasher_fund_supporter/core/language/language_cubit.dart';
import 'package:mubasher_fund_supporter/features/home/data/models/fund_model.dart';

void main() {
  group('FundModel Financial & Localization Tests', () {
    test('dynamicYtdReturn calculates accurate percentage yield', () {
      final fund = FundModel(
        id: 'test-1',
        name: 'Credit Agricole Egypt Fund I',
        nameAr: 'صندوق استثمار بنك كريدي أجريكول مصر الأول',
        nameEn: 'Credit Agricole Egypt Fund I',
        managerName: 'Hermes',
        currentNav: 120.0,
        initialValue: 100.0,
        ytdReturn: 20.0,
        riskLevel: 'High',
        category: 'Equity',
      );

      // (120 - 100) / 100 * 100 = 20.0%
      expect(fund.dynamicYtdReturn, 20.0);
    });

    test('FundModel parses correctly from database map', () {
      final map = {
        'id': '101',
        'name': 'Banque Misr Fund II',
        'name_ar': 'صندوق بنك مصر الثاني',
        'name_en': 'Banque Misr Fund II',
        'manager_name': 'CI Asset Management',
        'current_nav': 66.67,
        'ytd_return': 24.72,
        'weekly_return': 0.50,
        'four_weeks_return': 2.10,
        'daily_change': 0.15,
        'risk_level': 'High',
        'category': 'Equity',
        'currency': 'EGP',
      };

      final fund = FundModel.fromMap(map);
      expect(fund.id, '101');
      expect(fund.name, 'Banque Misr Fund II');
      expect(fund.nameAr, 'صندوق بنك مصر الثاني');
      expect(fund.currentNav, 66.67);
      expect(fund.ytdReturn, 24.72);
      expect(fund.dailyChange, 0.15);
    });

    testWidgets('localizedName returns Arabic when locale is ar and English when en', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'ar'});
      final prefs = await SharedPreferences.getInstance();
      final languageCubit = LanguageCubit(prefs);

      final fund = FundModel(
        id: 'test-2',
        name: 'ALEXBANK Fund I',
        nameAr: 'صندوق استثمار بنك الإسكندرية الأول',
        nameEn: 'ALEXBANK Fund I',
        managerName: 'Hermes',
        currentNav: 1727.88,
        ytdReturn: 23.09,
        riskLevel: 'High',
        category: 'Equity',
      );

      late String arName;
      late String enName;

      await tester.pumpWidget(
        BlocProvider<LanguageCubit>.value(
          value: languageCubit,
          child: Builder(
            builder: (context) {
              arName = fund.localizedName(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(arName, 'صندوق استثمار بنك الإسكندرية الأول');

      await languageCubit.setLocale(const Locale('en'));
      await tester.pumpWidget(
        BlocProvider<LanguageCubit>.value(
          value: languageCubit,
          child: Builder(
            builder: (context) {
              enName = fund.localizedName(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(enName, 'ALEXBANK Fund I');
    });

    testWidgets('localizedRisk returns Arabic and English correctly', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'ar'});
      final prefs = await SharedPreferences.getInstance();
      final languageCubit = LanguageCubit(prefs);

      final fund = FundModel(
        id: 'test-3',
        name: 'Gold Fund',
        managerName: 'Beltone',
        currentNav: 50.0,
        ytdReturn: 45.0,
        riskLevel: 'High',
        category: 'Gold',
      );

      late String arRisk;
      late String enRisk;

      await tester.pumpWidget(
        BlocProvider<LanguageCubit>.value(
          value: languageCubit,
          child: Builder(
            builder: (context) {
              arRisk = fund.localizedRisk(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(arRisk, 'مرتفع');

      await languageCubit.setLocale(const Locale('en'));
      await tester.pumpWidget(
        BlocProvider<LanguageCubit>.value(
          value: languageCubit,
          child: Builder(
            builder: (context) {
              enRisk = fund.localizedRisk(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(enRisk, 'High');
    });

    testWidgets('isUpdatedToday and localizedPriceStatus return expected freshness label', (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'ar'});
      final prefs = await SharedPreferences.getInstance();
      final languageCubit = LanguageCubit(prefs);

      final today = DateTime.now();
      final updatedTodayFund = FundModel(
        id: 'test-today',
        name: 'Azimut Gold Fund',
        nameAr: 'صندوق أزيموت للذهب',
        managerName: 'Azimut Egypt',
        currentNav: 15.50,
        ytdReturn: 42.0,
        riskLevel: 'Medium',
        category: 'Gold',
        updatedAt: today,
      );

      final pastDate = DateTime(2026, 1, 15);
      final pastFund = FundModel(
        id: 'test-past',
        name: 'Misr Equity Fund',
        nameAr: 'صندوق مصر للأسهم',
        managerName: 'Hermes',
        currentNav: 120.0,
        ytdReturn: 25.0,
        riskLevel: 'High',
        category: 'Equity',
        updatedAt: pastDate,
      );

      expect(updatedTodayFund.isUpdatedToday, true);
      expect(pastFund.isUpdatedToday, false);

      late String arStatusToday;
      late String arStatusPast;

      await tester.pumpWidget(
        BlocProvider<LanguageCubit>.value(
          value: languageCubit,
          child: Builder(
            builder: (context) {
              arStatusToday = updatedTodayFund.localizedPriceStatus(context);
              arStatusPast = pastFund.localizedPriceStatus(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(arStatusToday.contains('سعر اليوم المحدث'), true);
      expect(arStatusPast.contains('آخر سعر معلن'), true);
      expect(arStatusPast.contains('2026-01-15'), true);
    });
  });
}

