import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/app_config/font_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Profile Card Entry
          InkWell(
            onTap: () => context.push(Routes.profile),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 30.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Profile', style: FontStyles.titleMedium),
                        SizedBox(height: 4.h),
                        Text('View and edit your personal info', style: FontStyles.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          
          Text('Preferences', style: FontStyles.headlineSmall),
          SizedBox(height: 12.h),

          // Theme Selector
          Material(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return Column(
                  children: [
                    _buildThemeRadio(
                      context,
                      title: 'System Default',
                      icon: Icons.brightness_auto,
                      value: ThemeMode.system,
                      groupValue: themeMode,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildThemeRadio(
                      context,
                      title: 'Light Mode',
                      icon: Icons.light_mode,
                      value: ThemeMode.light,
                      groupValue: themeMode,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildThemeRadio(
                      context,
                      title: 'Dark Mode',
                      icon: Icons.dark_mode,
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeRadio(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
  }) {
    return RadioListTile<ThemeMode>(
      title: Text(title, style: FontStyles.bodyLarge),
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      value: value,
      groupValue: groupValue,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (ThemeMode? newValue) {
        if (newValue != null) {
          context.read<ThemeCubit>().setTheme(newValue);
        }
      },
    );
  }
}
