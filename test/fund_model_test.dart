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

    test('effectiveInitialNav and inceptionReturn calculate accurately for El Wefaq and low par funds', () {
      // El Wefaq Islamic Fund launched at par 10.0 EGP, currently 47.4784 EGP
      final elWefaq = FundModel(
        id: 'eg_fund_062',
        name: 'صندوق الوفاق الإسلامي',
        managerName: 'CI Capital',
        currentNav: 47.4784,
        initialNav: 10.0,
        ytdReturn: 41.59,
        riskLevel: 'High',
        category: 'Equity',
        subscriptionSchedule: 'أسبوعياً - تنفيذ يوم الأحد بسعر وثيقة الإقفال',
        subscriptionScheduleEn: 'Weekly - executed on Sunday at closing NAV',
        redemptionSchedule: 'أسبوعياً - طلبات حتى الخميس والتنفيذ الأحد (تسوية T+2)',
        redemptionScheduleEn: 'Weekly - orders by Thursday, executed Sunday (T+2)',
        executionCutoffTime: 'الخميس الساعة 1:00 ظهراً',
        executionCutoffTimeEn: 'Thursday at 1:00 PM',
      );

      // Verify par value is 10.0 EGP
      expect(elWefaq.effectiveInitialNav, 10.0);
      // ((47.4784 - 10.0) / 10.0) * 100 = 374.784% gain! (Never negative -52%)
      expect(elWefaq.inceptionReturn, closeTo(374.78, 0.01));

      // Test intelligent fallback when initialNav is null
      final unconfiguredFund = FundModel(
        id: 'test-heuristic',
        name: 'Heuristic Fund',
        managerName: 'Manager',
        currentNav: 45.0,
        ytdReturn: 20.0,
        riskLevel: 'Medium',
        category: 'Equity',
      );
      // NAV between 5 and 90 -> fallback is 10.0
      expect(unconfiguredFund.effectiveInitialNav, 10.0);
      expect(unconfiguredFund.inceptionReturn, closeTo(350.0, 0.01));
    });

    test('FundModel serializes and deserializes prospectus schedules correctly', () {
      final map = {
        'id': 'eg_fund_001',
        'name': 'Sahmy 70',
        'name_ar': 'صندوق سهمي 70',
        'name_en': 'Sahmy 70',
        'manager_name': 'NI Capital',
        'current_nav': 21.9448,
        'initial_nav': 10.0,
        'ytd_return': 94.10,
        'risk_level': 'High',
        'category': 'Equity',
        'subscription_schedule': 'أسبوعياً - الأحد',
        'subscription_schedule_en': 'Weekly - Sunday',
        'redemption_schedule': 'أسبوعياً - الأحد',
        'redemption_schedule_en': 'Weekly - Sunday',
        'execution_cutoff_time': 'الخميس 1:00 ظهراً',
        'execution_cutoff_time_en': 'Thursday 1:00 PM',
      };

      final fund = FundModel.fromMap(map);
      expect(fund.initialNav, 10.0);
      expect(fund.subscriptionSchedule, 'أسبوعياً - الأحد');
      expect(fund.subscriptionScheduleEn, 'Weekly - Sunday');
      expect(fund.redemptionSchedule, 'أسبوعياً - الأحد');
      expect(fund.redemptionScheduleEn, 'Weekly - Sunday');
      expect(fund.executionCutoffTime, 'الخميس 1:00 ظهراً');
      expect(fund.executionCutoffTimeEn, 'Thursday 1:00 PM');

      final serialized = fund.toMap();
      expect(serialized['initial_nav'], 10.0);
      expect(serialized['subscription_schedule'], 'أسبوعياً - الأحد');
      expect(serialized['execution_cutoff_time_en'], 'Thursday 1:00 PM');
    });
  });
}

