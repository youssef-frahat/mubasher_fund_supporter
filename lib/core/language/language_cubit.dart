import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageCubit extends Cubit<Locale> {
  final SharedPreferences prefs;

  LanguageCubit(this.prefs) : super(_getInitialLocale(prefs));

  static Locale _getInitialLocale(SharedPreferences prefs) {
    final lang = prefs.getString('app_language') ?? 'ar';
    return Locale(lang);
  }

  bool get isArabic => state.languageCode == 'ar';

  Future<void> toggleLanguage([BuildContext? context]) async {
    final nextLocale = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    await prefs.setString('app_language', nextLocale.languageCode);
    if (context != null && context.mounted) {
      try {
        await context.setLocale(nextLocale);
      } catch (_) {}
    }
    emit(nextLocale);
  }

  Future<void> setLocale(Locale locale, [BuildContext? context]) async {
    await prefs.setString('app_language', locale.languageCode);
    if (context != null && context.mounted) {
      try {
        await context.setLocale(locale);
      } catch (_) {}
    }
    emit(locale);
  }
}

class AppTranslation {
  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'appName': 'وثيقة (Watheqa)',
      'appSubtitle': 'منصة ومحاكي صناديق الاستثمار في مصر 📈',
      'home': 'الرئيسية',
      'roboAdvisor': 'المستشار الذكي',
      'portfolio': 'محفظتي',
      'settings': 'الإعدادات',
      'theme': 'مظهر التطبيق',
      'language': 'لغة التطبيق',
      'arabic': 'العربية (Arabic)',
      'english': 'English',
      'switchToEn': 'ENG',
      'switchToAr': 'AR',
      'exploreFunds': 'مستكشف كل الصناديق',
      'allFunds': 'دليل كل الصناديق',
      'searchPlaceholder': 'ابحث باسم الصندوق، المدير، أو الفئة...',
      'topPerforming': 'الصندوق الأعلى أداءً',
      'seeAll': 'عرض الكل ➔',
      'securityEncryption': 'تشفير بنكي آمن 256-bit',
      'privacyPolicy': 'الشروط والأحكام وسياسة الخصوصية',
      'faq': 'الأسئلة الشائعة',
      'profileEdit': 'تعديل البروفايل',
      'activePortfolio': 'المحفظة النشطة',
      'addPortfolio': 'إضافة محفظة محاكاة جديدة ➕',
      'addTransaction': '+ إضافة صفقة',
      'healthScore': 'مؤشر توازن المحفظة',
      'totalValue': 'إجمالي قيمة الاستثمارات',
      'profitLoss': 'إجمالي الربح / الخسارة',
      'notifications': 'التنبيهات وإشعارات المحفظة',
      'security': 'الأمان والحماية',
      'biometrics': 'التأمين ببصمة الاصبع / الوجه',
      'support': 'الدعم الفني والمساعدة',
      'editUnits': 'تعديل عدد الوثائق ✏️',
      'save': 'حفظ التغييرات',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'units': 'عدد الوثائق',
      'welcomeBack': 'أهلاً بك في وثيقة 👋',
      'smartAdvisorInsight': 'تحليل المستشار الذكي 💡',
      'aiRecommendation': 'توصيات التوزيع الاستثماري بناءً على أداء السوق اليوم',
      'categories': 'فئات الصناديق الاستثمارية',
      'moneyMarket': 'نقدية وسيولة',
      'gold': 'صناديق الذهب',
      'equity': 'أسهم ومحافظ',
      'islamic': 'شريعة إسلامية',
      'treasuryBills': 'أذون خزانة',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب جديد',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'fullName': 'الاسم بالكامل',
      'phone': 'رقم الهاتف',
      'rememberMe': 'تذكرني',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'optionalPhoto': 'إضافة صورة شخصية (اختياري 📸)',
      'lastNavUpdate': 'آخر تحديث للوثيقة: اليوم 25 يوليو 📅',
      'buyNowBroker': 'تداول واستثمر عبر المدير الرسمي 🔗',
      'simulatedReturn': 'العائد التقديري المتوقع',
    },
    'en': {
      'appName': 'Watheqa',
      'appSubtitle': 'Egyptian Mutual Funds Simulator & Platform 📈',
      'home': 'Home',
      'roboAdvisor': 'Robo-Advisor',
      'portfolio': 'My Portfolio',
      'settings': 'Settings',
      'theme': 'App Theme',
      'language': 'App Language',
      'arabic': 'العربية (Arabic)',
      'english': 'English',
      'switchToEn': 'ENG',
      'switchToAr': 'AR',
      'exploreFunds': 'Explore All Funds',
      'allFunds': 'All Funds Directory',
      'searchPlaceholder': 'Search fund name, manager, or category...',
      'topPerforming': 'Top Performing Fund',
      'seeAll': 'See All ➔',
      'securityEncryption': '256-bit Bank Grade Security',
      'privacyPolicy': 'Terms & Privacy Policy',
      'faq': 'FAQ',
      'profileEdit': 'Edit Profile',
      'activePortfolio': 'Active Portfolio',
      'addPortfolio': 'Add New Portfolio ➕',
      'addTransaction': '+ Add Transaction',
      'healthScore': 'Portfolio Balance Score',
      'totalValue': 'Total Portfolio Value',
      'profitLoss': 'Total Profit / Loss',
      'notifications': 'Portfolio Notifications',
      'security': 'Security & Protection',
      'biometrics': 'Biometric Authentication (Face/Touch ID)',
      'support': 'Support & Help',
      'editUnits': 'Edit Units Count ✏️',
      'save': 'Save Changes',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'units': 'Units Count',
      'welcomeBack': 'Welcome to Watheqa 👋',
      'smartAdvisorInsight': 'Smart Advisor Insights 💡',
      'aiRecommendation': 'Portfolio allocation recommendations based on today market performance',
      'categories': 'Fund Categories',
      'moneyMarket': 'Money Market & Liquidity',
      'gold': 'Gold Funds',
      'equity': 'Equities & Stocks',
      'islamic': 'Sharia Compliant',
      'treasuryBills': 'Treasury Bills',
      'login': 'Sign In',
      'register': 'Create Account',
      'email': 'Email Address',
      'password': 'Password',
      'fullName': 'Full Name',
      'phone': 'Phone Number',
      'rememberMe': 'Remember Me',
      'forgotPassword': 'Forgot Password?',
      'optionalPhoto': 'Add Profile Photo (Optional 📸)',
      'lastNavUpdate': 'Last Unit Value Update: Today 25 July 📅',
      'buyNowBroker': 'Trade via Official Manager 🔗',
      'simulatedReturn': 'Estimated Expected Return',
    },
  };

  static String translate(String key, String langCode) {
    return _localizedValues[langCode]?[key] ?? _localizedValues['ar']?[key] ?? key;
  }
}

extension TranslationExtension on BuildContext {
  String tr(String key) {
    final locale = watch<LanguageCubit>().state;
    return AppTranslation.translate(key, locale.languageCode);
  }

  bool get isArabic => watch<LanguageCubit>().state.languageCode == 'ar';
}
