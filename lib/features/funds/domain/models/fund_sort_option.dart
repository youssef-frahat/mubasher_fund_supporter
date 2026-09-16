import 'package:flutter/material.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../home/data/models/fund_model.dart';

enum FundSortOption {
  highestReturn,
  lowestReturn,
  highestPrice,
  lowestPrice,
  nameAsc,
  nameDesc,
  dailyGainers,
  lowestRisk,
  highestRisk;

  String getLabel(BuildContext context) {
    switch (this) {
      case FundSortOption.highestReturn:
        return context.tr('sortHighestReturn');
      case FundSortOption.lowestReturn:
        return context.tr('sortLowestReturn');
      case FundSortOption.highestPrice:
        return context.tr('sortHighestPrice');
      case FundSortOption.lowestPrice:
        return context.tr('sortLowestPrice');
      case FundSortOption.nameAsc:
        return context.tr('sortNameAsc');
      case FundSortOption.nameDesc:
        return context.tr('sortNameDesc');
      case FundSortOption.dailyGainers:
        return context.tr('sortDailyGainers');
      case FundSortOption.lowestRisk:
        return context.tr('sortLowestRisk');
      case FundSortOption.highestRisk:
        return context.tr('sortHighestRisk');
    }
  }

  IconData get icon {
    switch (this) {
      case FundSortOption.highestReturn:
        return Icons.trending_up_rounded;
      case FundSortOption.lowestReturn:
        return Icons.trending_down_rounded;
      case FundSortOption.highestPrice:
        return Icons.arrow_upward_rounded;
      case FundSortOption.lowestPrice:
        return Icons.arrow_downward_rounded;
      case FundSortOption.nameAsc:
        return Icons.sort_by_alpha_rounded;
      case FundSortOption.nameDesc:
        return Icons.sort_by_alpha_rounded;
      case FundSortOption.dailyGainers:
        return Icons.electric_bolt_rounded;
      case FundSortOption.lowestRisk:
        return Icons.verified_user_outlined;
      case FundSortOption.highestRisk:
        return Icons.warning_amber_rounded;
    }
  }

  List<FundModel> sort(List<FundModel> funds, {bool isArabic = true}) {
    final list = List<FundModel>.from(funds);
    switch (this) {
      case FundSortOption.highestReturn:
        list.sort((a, b) => b.ytdReturn.compareTo(a.ytdReturn));
        break;
      case FundSortOption.lowestReturn:
        list.sort((a, b) => a.ytdReturn.compareTo(b.ytdReturn));
        break;
      case FundSortOption.highestPrice:
        list.sort((a, b) => b.currentNav.compareTo(a.currentNav));
        break;
      case FundSortOption.lowestPrice:
        list.sort((a, b) => a.currentNav.compareTo(b.currentNav));
        break;
      case FundSortOption.nameAsc:
        list.sort((a, b) {
          final nameA = isArabic ? (a.nameAr ?? a.name) : (a.nameEn ?? a.name);
          final nameB = isArabic ? (b.nameAr ?? b.name) : (b.nameEn ?? b.name);
          return nameA.compareTo(nameB);
        });
        break;
      case FundSortOption.nameDesc:
        list.sort((a, b) {
          final nameA = isArabic ? (a.nameAr ?? a.name) : (a.nameEn ?? a.name);
          final nameB = isArabic ? (b.nameAr ?? b.name) : (b.nameEn ?? b.name);
          return nameB.compareTo(nameA);
        });
        break;
      case FundSortOption.dailyGainers:
        list.sort((a, b) => b.dailyChange.compareTo(a.dailyChange));
        break;
      case FundSortOption.lowestRisk:
        list.sort((a, b) => _riskRank(a.riskLevel).compareTo(_riskRank(b.riskLevel)));
        break;
      case FundSortOption.highestRisk:
        list.sort((a, b) => _riskRank(b.riskLevel).compareTo(_riskRank(a.riskLevel)));
        break;
    }
    return list;
  }

  static int _riskRank(String risk) {
    final r = risk.toLowerCase().trim();
    if (r.contains('low') || r.contains('منخفض')) return 1;
    if (r.contains('medium') || r.contains('متوسط')) return 2;
    if (r.contains('high') || r.contains('عالي') || r.contains('مرتفع')) return 3;
    return 2;
  }
}
