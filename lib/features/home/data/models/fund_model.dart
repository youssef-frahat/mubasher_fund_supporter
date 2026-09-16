import 'package:flutter/material.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../home/data/models/platform_feature.dart';

class FundModel {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String managerName;
  final double currentNav;
  final double ytdReturn;
  final double weeklyReturn;
  final double fourWeeksReturn;
  final double last12mReturn;
  final double dailyChange;
  final String riskLevel; // e.g. "Low", "Medium", "High"
  final String category; // e.g. "Equity", "MoneyMarket", "Gold", "Islamic"
  final String? subCategory;
  final String currency; // EGP, USD, EUR
  final String? inceptionDate;
  final double? initialValue;
  final String? logoUrl;
  final bool isRecommended;
  final bool isSponsored;
  final bool isTopPerforming;
  final int? rank;
  final DateTime? updatedAt;

  // Deep Fund Metadata Attributes
  final bool isShariahCompliant;
  final String? shariahBoard;
  final String? issuingEntity;
  final String? issuingEntityAr;
  final String? issuingEntityEn;
  final int? inceptionYear;
  final String? custodian;
  final String? custodianAr;
  final String? custodianEn;
  final String? fundAdministrator;
  final String? auditor;
  final String? managerLogo;
  final String? dividendPolicy;

  FundModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.managerName,
    required this.currentNav,
    required this.ytdReturn,
    this.weeklyReturn = 0.0,
    this.fourWeeksReturn = 0.0,
    this.last12mReturn = 0.0,
    this.dailyChange = 0.0,
    required this.riskLevel,
    required this.category,
    this.subCategory,
    this.currency = 'EGP',
    this.inceptionDate,
    this.initialValue,
    this.logoUrl,
    this.isRecommended = false,
    this.isSponsored = false,
    this.isTopPerforming = false,
    this.rank,
    this.updatedAt,
    this.isShariahCompliant = false,
    this.shariahBoard,
    this.issuingEntity,
    this.issuingEntityAr,
    this.issuingEntityEn,
    this.inceptionYear,
    this.custodian,
    this.custodianAr,
    this.custodianEn,
    this.fundAdministrator,
    this.auditor,
    this.managerLogo,
    this.dividendPolicy,
  });

  /// Returns main name without parentheses e.g. "AAIB" from "AAIB (Gozoor)"
  String get displayNameOnly {
    if (name.contains('(') && name.contains(')')) {
      final index = name.indexOf('(');
      final mainPart = name.substring(0, index).trim();
      if (mainPart.isNotEmpty) return mainPart;
    }
    return name;
  }

  /// Dynamically computed YTD return based on price change
  double get dynamicYtdReturn {
    final basePrice = (initialValue != null && initialValue! > 0) ? initialValue! : 100.0;
    if (basePrice <= 0) return ytdReturn;
    final calc = ((currentNav - basePrice) / basePrice) * 100;
    return double.parse(calc.toStringAsFixed(2));
  }

  bool _checkIsArabic(BuildContext context) {
    try {
      return context.isArabic;
    } catch (_) {
      try {
        return Localizations.localeOf(context).languageCode == 'ar';
      } catch (_) {
        return true;
      }
    }
  }

  /// Returns localized name based on active app Locale
  String localizedName(BuildContext context) {
    final isAr = _checkIsArabic(context);
    if (isAr) {
      if (nameAr != null && nameAr!.trim().isNotEmpty) return nameAr!;
      return name;
    } else {
      if (nameEn != null && nameEn!.trim().isNotEmpty) return nameEn!;
      return name;
    }
  }

  /// Returns localized category name based on active app Locale
  String localizedCategory(BuildContext context) {
    final isAr = _checkIsArabic(context);
    final catLower = category.toLowerCase();
    if (catLower.contains('equity') || catLower.contains('أسهم')) {
      return isAr ? 'أسهم ونمو' : 'Equity & Growth';
    } else if (catLower.contains('gold') || catLower.contains('ذهب') || catLower.contains('معادن')) {
      return isAr ? 'معادن وذهب' : 'Precious Metals & Gold';
    } else if (catLower.contains('islamic') || catLower.contains('شريعة') || catLower.contains('إسلام')) {
      return isAr ? 'شريعة إسلامية' : 'Islamic Shariah';
    } else if (catLower.contains('moneymarket') || catLower.contains('نقد') || catLower.contains('سيول')) {
      return isAr ? 'نقدية وسيولة' : 'Money Market';
    } else if (catLower.contains('fixed') || catLower.contains('سند') || catLower.contains('أذون')) {
      return isAr ? 'أذون وسندات' : 'Fixed Income & Bonds';
    } else if (catLower.contains('balanced') || catLower.contains('متوازن')) {
      return isAr ? 'متوازن ومختلط' : 'Balanced';
    }
    return isAr ? (nameAr ?? category) : category;
  }

  /// Returns localized risk level
  String localizedRisk(BuildContext context) {
    final isAr = _checkIsArabic(context);
    final rLower = riskLevel.toLowerCase();
    if (rLower.contains('high') || rLower.contains('عالي') || rLower.contains('مرتفع')) {
      return isAr ? 'مرتفع' : 'High';
    } else if (rLower.contains('low') || rLower.contains('منخفض')) {
      return isAr ? 'منخفض' : 'Low';
    }
    return isAr ? 'متوسط' : 'Medium';
  }

  /// Returns abbreviation/code inside parentheses e.g. "Gozoor" from "AAIB (Gozoor)"
  String? get abbreviation {
    if (name.contains('(') && name.contains(')')) {
      final start = name.indexOf('(') + 1;
      final end = name.lastIndexOf(')');
      if (start < end) {
        final code = name.substring(start, end).trim();
        if (code.isNotEmpty) return code;
      }
    }
    return null;
  }

  /// Returns localized issuing entity / founding bank
  String localizedIssuingEntity(BuildContext context) {
    final isAr = _checkIsArabic(context);
    if (isAr) {
      if (issuingEntityAr != null && issuingEntityAr!.trim().isNotEmpty) return issuingEntityAr!;
      return issuingEntity ?? (isAr ? 'البنك المؤسس' : 'Issuing Bank');
    } else {
      if (issuingEntityEn != null && issuingEntityEn!.trim().isNotEmpty) return issuingEntityEn!;
      return issuingEntity ?? 'Issuing Bank';
    }
  }

  /// Returns localized custodian bank
  String localizedCustodian(BuildContext context) {
    final isAr = _checkIsArabic(context);
    if (isAr) {
      if (custodianAr != null && custodianAr!.trim().isNotEmpty) return custodianAr!;
      return custodian ?? 'البنك التجاري الدولي (CIB)';
    } else {
      if (custodianEn != null && custodianEn!.trim().isNotEmpty) return custodianEn!;
      return custodian ?? 'Commercial International Bank (CIB)';
    }
  }

  /// Returns localized Shariah status badge text
  String localizedShariahStatus(BuildContext context) {
    final isAr = _checkIsArabic(context);
    if (isShariahCompliant) {
      return isAr ? 'مطابق للشريعة الإسلامية 🌙' : 'Shariah Compliant 🌙';
    } else {
      return isAr ? 'صندوق استثماري تقليدي 🏛️' : 'Conventional Mutual Fund 🏛️';
    }
  }

  factory FundModel.fromMap(Map<String, dynamic> map) {
    final cat = (map['category'] ?? 'Equity').toString().toLowerCase();
    final nameStr = (map['name'] ?? '').toString().toLowerCase();
    final bool shariah = map['is_shariah_compliant'] == true ||
        cat.contains('islamic') ||
        cat.contains('sharia') ||
        nameStr.contains('إسلامي') ||
        nameStr.contains('شريعة') ||
        nameStr.contains('وفاق') ||
        nameStr.contains('سنابل') ||
        nameStr.contains('أمان') ||
        nameStr.contains('هلال') ||
        nameStr.contains('بشائر');

    return FundModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? map['name_ar'] ?? map['name_en'] ?? '',
      nameAr: map['name_ar'],
      nameEn: map['name_en'],
      managerName: map['manager_name'] ?? map['manager'] ?? 'مباشر كابيتال',
      currentNav: (map['current_nav'] as num?)?.toDouble() ?? 100.0,
      ytdReturn: (map['ytd_return'] as num?)?.toDouble() ?? 0.0,
      weeklyReturn: (map['weekly_return'] as num?)?.toDouble() ?? 0.0,
      fourWeeksReturn: (map['four_weeks_return'] as num?)?.toDouble() ?? 0.0,
      last12mReturn: (map['last_12m_return'] as num?)?.toDouble() ?? 0.0,
      dailyChange: (map['daily_change'] as num?)?.toDouble() ?? 0.0,
      riskLevel: map['risk_level'] ?? 'Medium',
      category: map['category'] ?? 'Equity',
      subCategory: map['sub_category'],
      currency: map['currency'] ?? 'EGP',
      inceptionDate: map['inception_date'],
      initialValue: (map['initial_value'] as num?)?.toDouble(),
      logoUrl: map['logo_url'],
      isRecommended: map['is_recommended'] ?? false,
      isSponsored: map['is_sponsored'] ?? false,
      isTopPerforming: map['is_top_performing'] ?? false,
      rank: map['rank'] as int?,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
      isShariahCompliant: shariah,
      shariahBoard: map['shariah_board'] ?? (shariah ? 'الهيئة الشرعية الموحدة والرقابة المالية' : null),
      issuingEntity: map['issuing_entity'] ?? map['issuing_entity_ar'],
      issuingEntityAr: map['issuing_entity_ar'] ?? map['issuing_entity'],
      issuingEntityEn: map['issuing_entity_en'],
      inceptionYear: (map['inception_year'] as num?)?.toInt(),
      custodian: map['custodian'],
      custodianAr: map['custodian_ar'] ?? map['custodian'],
      custodianEn: map['custodian_en'],
      fundAdministrator: map['fund_administrator'] ?? 'الفروع الرسمية والمنصات المرخصة',
      auditor: map['auditor'] ?? 'حازم حسن (KPMG) ومراقبون مستقلون',
      managerLogo: map['manager_logo'] ?? map['logo_url'],
      dividendPolicy: map['dividend_policy'] ?? 'إعادة استثمار العوائد تلقائياً (Reinvestment / Growth)',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'name_ar': nameAr ?? name,
      'name_en': nameEn,
      'manager_name': managerName,
      'manager': managerName,
      'current_nav': currentNav,
      'ytd_return': ytdReturn,
      'weekly_return': weeklyReturn,
      'four_weeks_return': fourWeeksReturn,
      'last_12m_return': last12mReturn,
      'daily_change': dailyChange,
      'risk_level': riskLevel,
      'category': category,
      'sub_category': subCategory,
      'currency': currency,
      'inception_date': inceptionDate,
      'initial_value': initialValue,
      'logo_url': logoUrl,
      'is_recommended': isRecommended,
      'is_sponsored': isSponsored,
      'is_top_performing': isTopPerforming,
      'rank': rank,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'is_shariah_compliant': isShariahCompliant,
      if (shariahBoard != null) 'shariah_board': shariahBoard,
      if (issuingEntity != null) 'issuing_entity': issuingEntity,
      if (issuingEntityAr != null) 'issuing_entity_ar': issuingEntityAr,
      if (issuingEntityEn != null) 'issuing_entity_en': issuingEntityEn,
      if (inceptionYear != null) 'inception_year': inceptionYear,
      if (custodian != null) 'custodian': custodian,
      if (custodianAr != null) 'custodian_ar': custodianAr,
      if (custodianEn != null) 'custodian_en': custodianEn,
      if (fundAdministrator != null) 'fund_administrator': fundAdministrator,
      if (auditor != null) 'auditor': auditor,
      if (managerLogo != null) 'manager_logo': managerLogo,
      if (dividendPolicy != null) 'dividend_policy': dividendPolicy,
    };
  }

  /// Convert to PlatformFeature for navigation to FundDetailsScreen
  PlatformFeature toPlatformFeature() {
    return PlatformFeature(
      id: id,
      title: name,
      subtitle: '$managerName | $category',
      icon: Icons.account_balance,
      accentColor: _categoryColor,
    );
  }

  Color get _categoryColor {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  factory FundModel.mock(String id, String name, double ytd, {String category = "Equity", String riskLevel = "Medium"}) {
    return FundModel(
      id: id,
      name: name,
      managerName: "مباشر كابيتال",
      currentNav: 150.25,
      ytdReturn: ytd,
      dailyChange: ytd / 10,
      riskLevel: riskLevel,
      category: category,
    );
  }
}
