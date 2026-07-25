import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricsState();
  }

  Future<void> _loadBiometricsState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      // Trigger native biometric prompt to verify
      final isAuthenticated = await BiometricService.authenticateUser(context);
      if (isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometrics_enabled', true);
        setState(() => _biometricsEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تفعيل البصمة لتأمين التطبيق بنجاح! 🔒'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل تأكيد البصمة، لم يتم تفعيل الخاصية.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometrics_enabled', false);
      setState(() => _biometricsEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الإعدادات والحساب',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<LanguageCubit>().toggleLanguage();
              if (context.mounted) {
                final code = context.read<LanguageCubit>().state.languageCode;
                await context.setLocale(Locale(code));
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Text(
                context.watch<LanguageCubit>().isArabic ? 'ENG' : 'AR',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Account Profile Card
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                String userName = 'المستثمر المحترف';
                String userEmail = 'user@watheqa.eg';

                if (state is Authenticated) {
                  userName = state.user.userMetadata?['full_name'] ?? state.user.email?.split('@').first ?? 'المستثمر المحترف';
                  userEmail = state.user.email ?? 'user@watheqa.eg';
                }

                return Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: surface,
                    gradient: AppColors.getCardGradient(context),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28.r,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: FaIcon(
                          FontAwesomeIcons.userCheck,
                          color: AppColors.primary,
                          size: 24.r,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              userEmail,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.penToSquare, color: AppColors.primary, size: 18),
                        onPressed: () => context.push(Routes.profile),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 24.h),

            // Category Title: Theme & Language Setting
            _buildSectionHeader(context, '🎨 مظهر التطبيق واللغة'),
            SizedBox(height: 10.h),
            Material(
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Theme Tile
                  BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, themeMode) {
                      String subtitleText = 'تلقائي (حسب نظام الجهاز)';
                      dynamic themeIcon = FontAwesomeIcons.sliders;

                      if (themeMode == ThemeMode.dark) {
                        subtitleText = 'المظهر الداكن (Dark Mode)';
                        themeIcon = FontAwesomeIcons.moon;
                      } else if (themeMode == ThemeMode.light) {
                        subtitleText = 'المظهر الفاتح (Light Mode)';
                        themeIcon = FontAwesomeIcons.sun;
                      }

                      return ListTile(
                        tileColor: Colors.transparent,
                        leading: FaIcon(themeIcon, color: AppColors.primary, size: 18.r),
                        title: Text(
                          'مظهر التطبيق (Theme)',
                          style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          subtitleText,
                          style: TextStyle(color: textSecondary, fontSize: 11.sp),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => _showThemeSelectorSheet(context, themeMode),
                      );
                    },
                  ),
                  Divider(height: 1, color: border),

                  // Language Tile
                  ListTile(
                    tileColor: Colors.transparent,
                    leading: FaIcon(FontAwesomeIcons.language, color: AppColors.primary, size: 18.r),
                    title: Text(
                      'لغة التطبيق (Language)',
                      style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      context.watch<LanguageCubit>().isArabic ? 'العربية (Arabic)' : 'English',
                      style: TextStyle(color: textSecondary, fontSize: 11.sp),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        context.watch<LanguageCubit>().isArabic ? 'تغيير إلى English' : 'تغيير إلى العربية',
                        style: TextStyle(color: AppColors.primary, fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () async {
                      await context.read<LanguageCubit>().toggleLanguage();
                      if (context.mounted) {
                        final code = context.read<LanguageCubit>().state.languageCode;
                        await context.setLocale(Locale(code));
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Category Title: Notifications & Alerts
            _buildSectionHeader(context, '🔔 التنبيهات وإشعارات المحفظة'),
            SizedBox(height: 10.h),
            Material(
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                secondary: const FaIcon(FontAwesomeIcons.bell, color: AppColors.primary, size: 18),
                title: Text(
                  'تنبيهات أداء المحفظة اليومية',
                  style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'إشعارات ملخص جلسة التداول والأرباح آخر اليوم',
                  style: TextStyle(color: textSecondary, fontSize: 11.sp),
                ),
                activeThumbColor: AppColors.primary,
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
            ),
            SizedBox(height: 24.h),

            // Category Title: Security & Biometrics
            _buildSectionHeader(context, '🔒 الأمان والحماية'),
            SizedBox(height: 10.h),
            Material(
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                secondary: const FaIcon(FontAwesomeIcons.fingerprint, color: AppColors.primary, size: 18),
                title: Text(
                  'التأمين ببصمة الاصبع / الوجه',
                  style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'طلب البصمة قبل فتح المحفظة والحساب',
                  style: TextStyle(color: textSecondary, fontSize: 11.sp),
                ),
                activeThumbColor: AppColors.primary,
                value: _biometricsEnabled,
                onChanged: _toggleBiometrics,
              ),
            ),
            SizedBox(height: 24.h),

            // Category Title: Support
            _buildSectionHeader(context, '💬 الدعم الفني والمساعدة'),
            SizedBox(height: 10.h),
            Material(
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.circleQuestion, color: AppColors.primary, size: 18),
                    title: Text(
                      'الأسئلة الشائعة (FAQ)',
                      style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'إجابات حول الصناديق والمحفظة والمستشار الذكي',
                      style: TextStyle(color: textSecondary, fontSize: 11.sp),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => context.push(Routes.faq),
                  ),
                  Divider(height: 1, color: border, indent: 48.w),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.fileContract, color: AppColors.primary, size: 18),
                    title: Text(
                      'الشروط والأحكام وسياسة الخصوصية',
                      style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'اتفاقية الاستخدام وحماية البيانات لحفظ حقوقك',
                      style: TextStyle(color: textSecondary, fontSize: 11.sp),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => context.push(Routes.termsConditions),
                  ),
                  Divider(height: 1, color: border, indent: 48.w),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.headset, color: AppColors.primary, size: 18),
                    title: Text(
                      'الدعم الفني والخدمة المباشرة',
                      style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'تواصل مع مستشاري وثيقة عبر واتساب',
                      style: TextStyle(color: textSecondary, fontSize: 11.sp),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('جاري فتح محادثة الدعم المباشر... 💬')),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmSignOut(context),
                icon: const FaIcon(FontAwesomeIcons.rightFromBracket, color: Colors.white, size: 16),
                label: const Text(
                  'تسجيل الخروج من الحساب',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.getTextPrimary(context),
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _showThemeSelectorSheet(BuildContext context, ThemeMode currentMode) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final border = AppColors.getBorder(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر مظهر التطبيق (Theme)',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              _buildThemeOptionTile(
                context,
                title: 'تلقائي (حسب نظام الجهاز)',
                icon: FontAwesomeIcons.sliders,
                isSelected: currentMode == ThemeMode.system,
                onTap: () {
                  context.read<ThemeCubit>().setTheme(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              Divider(color: border),
              _buildThemeOptionTile(
                context,
                title: 'المظهر الداكن (Dark Mode)',
                icon: FontAwesomeIcons.moon,
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  context.read<ThemeCubit>().setTheme(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              Divider(color: border),
              _buildThemeOptionTile(
                context,
                title: 'المظهر الفاتح (Light Mode)',
                icon: FontAwesomeIcons.sun,
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  context.read<ThemeCubit>().setTheme(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile(
    BuildContext context, {
    required String title,
    required dynamic icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final textPrimary = AppColors.getTextPrimary(context);

    return ListTile(
      leading: FaIcon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 18.r),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14.sp,
        ),
      ),
      trailing: isSelected ? const FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.primary, size: 18) : null,
      onTap: onTap,
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        title: Text(
          'تأكيد تسجيل الخروج',
          style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت تأكد من أنك تريد تسجيل الخروج من حسابك؟',
          style: TextStyle(color: AppColors.getTextSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
