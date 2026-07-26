import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_config/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../../home/data/models/fund_model.dart';
import '../../../home/data/repositories/funds_repository.dart';
import '../../../home/presentation/widgets/fund_list_tile.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<FundModel> _allFunds = [];
  List<FundModel> _savedFundsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFunds();
  }

  Future<void> _loadFunds() async {
    try {
      final funds = await SupabaseFundsRepository().getFunds();
      final wishlistService = sl<WishlistService>();

      if (mounted) {
        setState(() {
          _allFunds = funds;
          _syncSavedFunds(wishlistService.orderedFundIds.value);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _syncSavedFunds(List<String> orderedIds) {
    final Map<String, FundModel> fundMap = {for (var f in _allFunds) f.id: f};
    final List<FundModel> result = [];

    for (final id in orderedIds) {
      if (fundMap.containsKey(id)) {
        result.add(fundMap[id]!);
      }
    }

    // Add any remaining saved IDs not in ordered list
    final wishlistService = sl<WishlistService>();
    final savedSet = wishlistService.savedFundIds.value;
    for (final f in _allFunds) {
      if (savedSet.contains(f.id) && !result.contains(f)) {
        result.add(f);
      }
    }

    _savedFundsList = result;
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final wishlistService = sl<WishlistService>();

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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'الصناديق المفضلة ⭐️',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Set<String>>(
              valueListenable: wishlistService.savedFundIds,
              builder: (context, savedIds, _) {
                // Ensure local list matches saved IDs
                final currentSaved = _savedFundsList
                    .where((fund) => savedIds.contains(fund.id))
                    .toList();

                if (currentSaved.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 90.r,
                            height: 90.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                            child: Center(
                              child: FaIcon(
                                FontAwesomeIcons.bookmark,
                                size: 38.r,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'لا توجد صناديق مفضلة حتى الآن',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'اضغط على زر الإشارة المرجعية 🔖 في أي صندوق لإضافته لقائمتك المفضلة والوصول السريع إليه.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13.sp,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            onPressed: () => context.push(Routes.allFunds),
                            icon: const Icon(Icons.search),
                            label: const Text('استكشف جميع الصناديق'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Interactive Drag & Drop Reorder Tip Banner
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, color: AppColors.primary, size: 18.r),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              context.tr('dragReorderTip'),
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Interactive Reorderable List
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                        itemCount: currentSaved.length,
                        onReorderItem: (oldIndex, newIndex) async {
                          setState(() {
                            final item = currentSaved.removeAt(oldIndex);
                            currentSaved.insert(newIndex, item);
                            _savedFundsList = List.from(currentSaved);
                          });
                          final updatedIds = currentSaved.map((f) => f.id).toList();
                          await wishlistService.reorderWishlist(updatedIds);
                        },
                        itemBuilder: (context, index) {
                          final fund = currentSaved[index];
                          return KeyedSubtree(
                            key: ValueKey(fund.id),
                            child: FundListTile(
                              fund: fund,
                              rank: index + 1,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
