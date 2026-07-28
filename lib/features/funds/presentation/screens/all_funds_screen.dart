import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryKey = 'catAll';
  String _searchQuery = '';
  List<FundModel> _funds = [];
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
    _fetchRealFunds();
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
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: context.tr('searchPlaceholder'),
                hintStyle: TextStyle(color: textSecondary, fontSize: 13.sp),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.primary),
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

          // Filtered Count Header
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

          // Fund List using standardized FundListTile
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFunds.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد صناديق تطابق الفئة أو البحث.',
                          style: TextStyle(color: textSecondary, fontSize: 13.sp),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _fetchRealFunds,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          itemCount: filteredFunds.length,
                          itemBuilder: (context, index) {
                            final fund = filteredFunds[index];
                            return FundListTile(
                              fund: fund,
                              rank: index + 1,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
