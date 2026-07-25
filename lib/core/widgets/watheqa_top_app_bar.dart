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
      centerTitle: true,
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
        SizedBox(width: 4.w),
      ],
    );
  }
}
