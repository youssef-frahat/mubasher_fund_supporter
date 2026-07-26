import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../calculator/data/repositories/calculator_repository.dart';
import '../../../home/data/models/platform_feature.dart';

class AllFundsScreen extends StatefulWidget {
  const AllFundsScreen({super.key});

  @override
  State<AllFundsScreen> createState() => _AllFundsScreenState();
}

class _AllFundsScreenState extends State<AllFundsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryKey = 'catAll';
  String _searchQuery = '';
  List<PlatformFeature> _funds = [];
  bool _isLoading = true;

  final List<String> _categoryKeys = [
    'catAll',
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
      final backendFunds = await CalculatorRepository().getSponsoredBackendFunds();
      final mapped = backendFunds.map((f) {
        Color color = const Color(0xFF10B981);
        dynamic icon = FontAwesomeIcons.chartLine;
        final cat = f.category.toLowerCase();
        final name = f.name.toLowerCase();

        if (cat.contains('gold') || cat.contains('silver') || cat.contains('metal') || name.contains('ذهب') || name.contains('فضة') || name.contains('معادن')) {
          color = const Color(0xFFF59E0B);
          icon = FontAwesomeIcons.coins;
        } else if (cat.contains('islamic') || cat.contains('sharia') || name.contains('إسلام') || name.contains('شريعة') || name.contains('وفاق')) {
          color = const Color(0xFF059669);
          icon = FontAwesomeIcons.kaaba;
        } else if (cat.contains('money') || cat.contains('cash') || name.contains('سيولة') || name.contains('نقدي') || name.contains('يومي')) {
          color = const Color(0xFF10B981);
          icon = FontAwesomeIcons.moneyBillWave;
        } else if (cat.contains('fixed') || cat.contains('treasury') || cat.contains('bill') || name.contains('سند') || name.contains('أذون') || name.contains('خزانة')) {
          color = const Color(0xFF6366F1);
          icon = FontAwesomeIcons.shieldHalved;
        }

        return PlatformFeature(
          id: f.id,
          title: f.name,
          subtitle: '${f.managerName} | ${f.category} | NAV: ${f.currentNav} ${f.currency}',
          icon: icon,
          accentColor: color,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _funds = mapped;
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
      final titleLower = fund.title.toLowerCase();
      final subLower = fund.subtitle.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();

      final matchesSearch = queryLower.isEmpty || titleLower.contains(queryLower) || subLower.contains(queryLower);

      if (!matchesSearch) return false;

      if (_selectedCategoryKey == 'catAll') return true;

      if (_selectedCategoryKey == 'catLiquidity') {
        return subLower.contains('moneymarket') || subLower.contains('liquidity') || subLower.contains('cash') || titleLower.contains('نقدي') || titleLower.contains('يومي') || titleLower.contains('سيولة') || titleLower.contains('جذور');
      }
      if (_selectedCategoryKey == 'catPreciousMetals') {
        return subLower.contains('gold') || subLower.contains('silver') || subLower.contains('metal') || titleLower.contains('ذهب') || titleLower.contains('فضة') || titleLower.contains('معادن') || titleLower.contains('سبائك');
      }
      if (_selectedCategoryKey == 'catEquities') {
        return subLower.contains('equity') || subLower.contains('growth') || titleLower.contains('أسهم') || titleLower.contains('نمو') || titleLower.contains('مباشر أسهم');
      }
      if (_selectedCategoryKey == 'catIslamic') {
        return subLower.contains('islamic') || subLower.contains('sharia') || titleLower.contains('إسلامي') || titleLower.contains('شريعة') || titleLower.contains('وفاق');
      }
      if (_selectedCategoryKey == 'catTreasury') {
        return subLower.contains('fixed') || subLower.contains('treasury') || subLower.contains('bill') || subLower.contains('bond') || titleLower.contains('أذون') || titleLower.contains('سندات') || titleLower.contains('خزانة') || titleLower.contains('دخل ثابت') || titleLower.contains('مرابحة');
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
                  onTap: () => setState(() => _selectedCategoryKey = catKey),
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
                  'نتائج التصفية (${filteredFunds.length})',
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

          // Fund List
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
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        itemCount: filteredFunds.length,
                        itemBuilder: (context, index) {
                          final fund = filteredFunds[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Material(
                              color: surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                side: BorderSide(color: border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                tileColor: Colors.transparent,
                                leading: CircleAvatar(
                                  radius: 22.r,
                                  backgroundColor: fund.accentColor.withValues(alpha: 0.15),
                                  child: FaIcon(fund.icon, color: fund.accentColor, size: 18.r),
                                ),
                                title: Text(
                                  fund.title,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  fund.subtitle,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () => context.push(Routes.fundDetails, extra: fund),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
