import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../app_config/app_colors.dart';
import '../routing/routes.dart';
import 'watheqa_animated_title.dart';

class WatheqaTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;

  const WatheqaTopAppBar({
    super.key,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final textPrimary = AppColors.getTextPrimary(context);

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textPrimary),
              onPressed: () => context.pop(),
            )
          : null,
      title: const WatheqaAnimatedTitle(),
      actions: [
        // All Funds Directory Explorer Icon
        IconButton(
          tooltip: 'مستكشف كل الصناديق',
          icon: FaIcon(
            FontAwesomeIcons.layerGroup,
            color: AppColors.primary,
            size: 18.r,
          ),
          onPressed: () => context.push(Routes.allFunds),
        ),

        // Language Switcher Action (AR / ENG)
        TextButton(
          onPressed: () {
            final currentLocale = Localizations.localeOf(context).languageCode;
            final newLocale = currentLocale == 'ar' ? 'en' : 'ar';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  newLocale == 'en' ? 'Switched to English 🌐' : 'تم التحويل إلى اللغة العربية 🌐',
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            child: Text(
              Localizations.localeOf(context).languageCode.toUpperCase() == 'AR' ? 'ENG' : 'AR',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }
}
