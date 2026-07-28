import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../home/data/models/fund_model.dart';
import '../../../home/data/repositories/funds_repository.dart';
import '../../../home/presentation/widgets/fund_list_tile.dart';

class AllFundsScreen extends StatefulWidget {
  const AllFundsScreen({super.key});

  @override
  State<AllFundsScreen> createState() => _AllFundsScreenState();
}

class _AllFundsScreenState extends State<AllFundsScreen> {
  static const String _searchHistoryKey = 'watheqa_search_history';

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryKey = 'catAll';
  String _searchQuery = '';
  List<FundModel> _funds = [];
  List<String> _searchHistory = [];
  bool _isLoading = true;

  final List<String> _categoryKeys = [
    'catAll',
    'catSponsored',
    'catLiquidity',
    'catPreciousMetals',
    'catEquities',
    'catIslamic',
    'catTreasury',
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _fetchRealFunds();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_searchHistoryKey) ?? [];
      if (mounted) {
        setState(() => _searchHistory = history);
      }
    } catch (_) {}
  }

  Future<void> _saveSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];
      history.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
      history.insert(0, trimmed);
      if (history.length > 10) history = history.sublist(0, 10);
      await prefs.setStringList(_searchHistoryKey, history);
      if (mounted) setState(() => _searchHistory = history);
    } catch (_) {}
  }

  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      if (mounted) setState(() => _searchHistory = []);
    } catch (_) {}
  }

  Future<void> _fetchRealFunds() async {
    try {
      final backendFunds = await SupabaseFundsRepository().getFunds();
      if (mounted) {
        setState(() {
          _funds = backendFunds;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    setState(() => _searchQuery = trimmed);
    if (trimmed.isNotEmpty) {
      _saveSearchQuery(trimmed);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    final hasActiveQuery = _searchQuery.trim().isNotEmpty;
    final hasCategoryFilter = _selectedCategoryKey != 'catAll';
    final bool showResults = hasActiveQuery || hasCategoryFilter;

    final filteredFunds = _funds.where((fund) {
      final nameLower = fund.name.toLowerCase();
      final mgrLower = fund.managerName.toLowerCase();
      final catLower = fund.category.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();

      final matchesSearch = queryLower.isEmpty ||
          nameLower.contains(queryLower) ||
          mgrLower.contains(queryLower) ||
          catLower.contains(queryLower);

      if (!matchesSearch) return false;

      if (_selectedCategoryKey == 'catAll') return true;

      if (_selectedCategoryKey == 'catSponsored') {
        return fund.isSponsored || fund.isRecommended || nameLower.contains('رعائي') || nameLower.contains('دعائي');
      }
      if (_selectedCategoryKey == 'catLiquidity') {
        return catLower.contains('money') || catLower.contains('liquidity') || catLower.contains('cash') || nameLower.contains('نقدي') || nameLower.contains('يومي') || nameLower.contains('سيولة') || nameLower.contains('جذور');
      }
      if (_selectedCategoryKey == 'catPreciousMetals') {
        return catLower.contains('gold') || catLower.contains('silver') || catLower.contains('metal') || nameLower.contains('ذهب') || nameLower.contains('فضة') || nameLower.contains('معادن') || nameLower.contains('سبائك');
      }
      if (_selectedCategoryKey == 'catEquities') {
        return catLower.contains('equity') || catLower.contains('growth') || nameLower.contains('أسهم') || nameLower.contains('نمو') || nameLower.contains('مباشر أسهم');
      }
      if (_selectedCategoryKey == 'catIslamic') {
        return catLower.contains('islamic') || catLower.contains('sharia') || nameLower.contains('إسلامي') || nameLower.contains('شريعة') || nameLower.contains('وفاق');
      }
      if (_selectedCategoryKey == 'catTreasury') {
        return catLower.contains('fixed') || catLower.contains('treasury') || catLower.contains('bill') || catLower.contains('bond') || nameLower.contains('أذون') || nameLower.contains('سندات') || nameLower.contains('خزانة') || nameLower.contains('دخل ثابت') || nameLower.contains('مرابحة');
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('exploreFunds'),
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar (with clear & submit)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: context.tr('searchPlaceholder'),
                hintStyle: TextStyle(color: textSecondary, fontSize: 13.sp),
                prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 22.r),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textSecondary, size: 20.r),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: surface,
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Horizontal Category Filter Chips
          SizedBox(
            height: 38.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _categoryKeys.length,
              itemBuilder: (context, index) {
                final catKey = _categoryKeys[index];
                final catLabel = context.tr(catKey);
                final isSelected = catKey == _selectedCategoryKey;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedCategoryKey == catKey && catKey != 'catAll') {
                        _selectedCategoryKey = 'catAll';
                      } else {
                        _selectedCategoryKey = catKey;
                      }
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : surface,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : border,
                      ),
                    ),
                    child: Text(
                      catLabel,
                      style: TextStyle(
                        color: isSelected ? Colors.black : textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 14.h),

          // Main Search Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : showResults
                    // ---------------- RESULTS STATE (Active Query / Category Filter) ----------------
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${context.tr('filterResults')} (${filteredFunds.length})',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  context.tr('lastNavUpdate'),
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),

                          Expanded(
                            child: filteredFunds.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24.r),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.search_off, size: 48.r, color: textSecondary.withValues(alpha: 0.5)),
                                          SizedBox(height: 12.h),
                                          Text(
                                            context.tr('noFundsMatchSearch'),
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.sp,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    itemCount: filteredFunds.length,
                                    itemBuilder: (context, index) {
                                      final fund = filteredFunds[index];
                                      return GestureDetector(
                                        onTap: () {
                                          if (_searchQuery.isNotEmpty) {
                                            _saveSearchQuery(_searchQuery);
                                          }
                                        },
                                        child: FundListTile(
                                          fund: fund,
                                          rank: index + 1,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      )
                    // ---------------- SEARCH HISTORY & POPULAR PROMPT STATE ----------------
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Recent Search History (If available)
                            if (_searchHistory.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.tr('recentSearchHistory'),
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _clearSearchHistory,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      context.tr('clearSearchHistory'),
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: _searchHistory.map((item) {
                                  return ActionChip(
                                    avatar: Icon(Icons.history, size: 14.r, color: AppColors.primary),
                                    label: Text(
                                      item,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: surface,
                                    side: BorderSide(color: border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                    onPressed: () {
                                      _searchController.text = item;
                                      _onSearchSubmitted(item);
                                    },
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 12.h),
                            ],

                            // 2. Elegant Search Placeholder Illustration & Prompt
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(20.r),
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(color: border),
                                ),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 28.r,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                      child: FaIcon(
                                        FontAwesomeIcons.magnifyingGlassChart,
                                        color: AppColors.primary,
                                        size: 24.r,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      context.tr('searchStartPrompt'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      context.tr('searchStartSub'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11.sp,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
