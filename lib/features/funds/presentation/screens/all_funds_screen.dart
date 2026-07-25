import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../home/data/models/platform_feature.dart';

class AllFundsScreen extends StatefulWidget {
  const AllFundsScreen({super.key});

  @override
  State<AllFundsScreen> createState() => _AllFundsScreenState();
}

class _AllFundsScreenState extends State<AllFundsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryFilter = 'الكل';
  String _searchQuery = '';

  final List<String> _categories = [
    'الكل',
    'سيولة ونقدي',
    'تحوط ذهب',
    'أسهم ونمو',
    'شريعة إسلامية',
    'أذون وسندات',
  ];

  final List<PlatformFeature> _allFunds = const [
    PlatformFeature(
      title: 'صندوق مباشر اليومي للسيولة',
      subtitle: 'صندوق استثمار نقدي يومي تراكمي - عائد آمن وسحب فوري',
      icon: FontAwesomeIcons.moneyBillWave,
      accentColor: Color(0xFF10B981),
    ),
    PlatformFeature(
      title: 'صندوق أزموت للذهب (Azimut Gold)',
      subtitle: 'أول صندوق استثمار مصري متخصص في سبائك الذهب النقية 999.9',
      icon: FontAwesomeIcons.coins,
      accentColor: Color(0xFFF59E0B),
    ),
    PlatformFeature(
      title: 'صندوق فيصل الإسلامي للأسهم',
      subtitle: 'استثمار متوافق 100% مع الشريعة الإسلامية في أسهم واعدة',
      icon: FontAwesomeIcons.kaaba,
      accentColor: Color(0xFF059669),
    ),
    PlatformFeature(
      title: 'صندوق هيرميس للنمو والتنمية',
      subtitle: 'صندوق أسهم للنمو المرتفع في البورصة المصرية',
      icon: FontAwesomeIcons.chartLine,
      accentColor: Color(0xFF3B82F6),
    ),
    PlatformFeature(
      title: 'صندوق البنك الأهلي الرابع',
      subtitle: 'عائد يومي آمن ومستقر مع إمكانية الشراء اليومي',
      icon: FontAwesomeIcons.landmark,
      accentColor: Color(0xFF10B981),
    ),
    PlatformFeature(
      title: 'صندوق أذون الخزانة المصرية',
      subtitle: 'صندوق سندات ودخل ثابت بضمان حكومي وعائد ممتاز',
      icon: FontAwesomeIcons.shieldHalved,
      accentColor: Color(0xFF6366F1),
    ),
  ];

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

    final filteredFunds = _allFunds.where((fund) {
      final matchesSearch = fund.title.contains(_searchQuery) || fund.subtitle.contains(_searchQuery);
      if (_selectedCategoryFilter == 'الكل') return matchesSearch;
      if (_selectedCategoryFilter == 'سيولة ونقدي') return matchesSearch && (fund.subtitle.contains('نقدي') || fund.subtitle.contains('يومي'));
      if (_selectedCategoryFilter == 'تحوط ذهب') return matchesSearch && fund.title.contains('ذهب');
      if (_selectedCategoryFilter == 'أسهم ونمو') return matchesSearch && (fund.title.contains('أسهم') || fund.subtitle.contains('أسهم'));
      if (_selectedCategoryFilter == 'شريعة إسلامية') return matchesSearch && (fund.title.contains('إسلامي') || fund.subtitle.contains('الشريعة'));
      if (_selectedCategoryFilter == 'أذون وسندات') return matchesSearch && (fund.title.contains('سندات') || fund.subtitle.contains('خزانة'));
      return matchesSearch;
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
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategoryFilter;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryFilter = cat),
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
                      cat,
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
                  'آخر تحديث: اليوم',
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
            child: filteredFunds.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد صناديق تطابق الكلمة المبحوث عنها.',
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
