import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../../core/routing/routes.dart' show Routes;

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
      final isAuthenticated = await BiometricService.authenticateUser(context);
      if (isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometrics_enabled', true);
        setState(() => _biometricsEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('biometricActivated')),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('biometricFailed')),
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
          context.tr('settingsAndAccount'),
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<LanguageCubit>().toggleLanguage(context),
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
                String userName = context.tr('proInvestor');
                String userEmail = 'user@watheqa.eg';

                String? avatarUrl;
                if (state is Authenticated) {
                  userName = state.user.userMetadata?['full_name'] ?? state.user.email?.split('@').first ?? context.tr('proInvestor');
                  avatarUrl = state.user.userMetadata?['avatar_url'];
                  final email = state.user.email ?? 'user@watheqa.eg';
                  if (email.contains('@')) {
                    final domain = email.split('@').last.split('.').first;
                    final companyName = domain.isNotEmpty ? domain[0].toUpperCase() + domain.substring(1) : '';
                    userEmail = companyName.isNotEmpty ? '${context.tr('account')}: $companyName' : email;
                  } else {
                    userEmail = email;
                  }
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
                        backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                            ? NetworkImage(avatarUrl.toString())
                            : null,
                        child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                            ? FaIcon(
                                FontAwesomeIcons.userCheck,
                                color: AppColors.primary,
                                size: 24.r,
                              )
                            : null,
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
            _buildSectionHeader(context, context.tr('appThemeAndLang')),
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
                      String subtitleText = context.tr('themeSubtitleSystem');
                      dynamic themeIcon = FontAwesomeIcons.sliders;

                      if (themeMode == ThemeMode.dark) {
                        subtitleText = context.tr('themeSubtitleDark');
                        themeIcon = FontAwesomeIcons.moon;
                      } else if (themeMode == ThemeMode.light) {
                        subtitleText = context.tr('themeSubtitleLight');
                        themeIcon = FontAwesomeIcons.sun;
                      }

                      return ListTile(
                        tileColor: Colors.transparent,
                        leading: FaIcon(themeIcon, color: AppColors.primary, size: 18.r),
                        title: Text(
                          context.tr('theme'),
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
                      context.tr('language'),
                      style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      context.watch<LanguageCubit>().isArabic ? context.tr('arabic') : context.tr('english'),
                      style: TextStyle(color: textSecondary, fontSize: 11.sp),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        context.watch<LanguageCubit>().isArabic ? context.tr('changeToEnglish') : context.tr('changeToArabic'),
                        style: TextStyle(color: AppColors.primary, fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () => context.read<LanguageCubit>().toggleLanguage(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Category Title: Notifications & Alerts
            _buildSectionHeader(context, '🔔 ${context.tr('notifications')}'),
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
                  context.tr('dailyPortfolioAlerts'),
                  style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  context.tr('dailyPortfolioAlertsSub'),
                  style: TextStyle(color: textSecondary, fontSize: 11.sp),
                ),
                activeThumbColor: AppColors.primary,
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
            ),
            SizedBox(height: 24.h),

            // Category Title: Security & Biometrics
            _buildSectionHeader(context, '🔒 ${context.tr('security')}'),
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
                  context.tr('biometricAuthTitle'),
                  style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  context.tr('biometricAuthSub'),
                  style: TextStyle(color: textSecondary, fontSize: 11.sp),
                ),
                activeThumbColor: AppColors.primary,
                value: _biometricsEnabled,
                onChanged: _toggleBiometrics,
              ),
            ),
            SizedBox(height: 24.h),

            // Category Title: Support
            _buildSectionHeader(context, '💬 ${context.tr('support')}'),
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
                      context.tr('faq'),
                      style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      context.tr('faqSub'),
                      style: TextStyle(color: textSecondary, fontSize: 11.sp),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => context.push(Routes.faq),
                  ),
                  Divider(height: 1, color: border, indent: 48.w),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.fileContract, color: AppColors.primary, size: 18),
                    title: Text(
                      context.tr('privacyPolicy'),
                      style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      context.tr('termsSub'),
                      style: TextStyle(color: textSecondary, fontSize: 11.sp),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => context.push(Routes.termsConditions),
                  ),
                  Divider(height: 1, color: border, indent: 48.w),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.headset, color: AppColors.primary, size: 18),
                    title: Text(
                      context.tr('liveSupportTitle'),
                      style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      context.tr('liveSupportSub'),
                      style: TextStyle(color: textSecondary, fontSize: 11.sp),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _showLiveSupportSheet(context),
                  ),
                  Divider(height: 1, color: border, indent: 48.w),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.circleInfo, color: AppColors.primary, size: 18),
                    title: Text(
                      context.isArabic ? '🤝 من نحن' : '🤝 About Us',
                      style: TextStyle(color: textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      context.isArabic
                          ? 'تعرف على وثيقة وفريق التطوير ورؤيتنا'
                          : 'Learn about Watheqa, our team & vision',
                      style: TextStyle(color: textSecondary, fontSize: 11.sp),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => context.push(Routes.aboutUs),
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
                label: Text(
                  context.tr('signOut'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                context.tr('theme'),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              _buildThemeOptionTile(
                context,
                title: context.tr('themeSubtitleSystem'),
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
                title: context.tr('themeSubtitleDark'),
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
                title: context.tr('themeSubtitleLight'),
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
          context.tr('confirmSignOut'),
          style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.tr('confirmSignOutMsg'),
          style: TextStyle(color: AppColors.getTextSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.tr('signOut'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchContactUrl(BuildContext context, String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          AppSnackBar.showError(context, context.tr('launchError'));
        }
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.showError(context, context.tr('launchError'));
      }
    }
  }

  void _showLiveSupportSheet(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);
    final isAr = context.isArabic;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                context.tr('liveSupportTitle'),
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                context.tr('liveSupportSub'),
                style: TextStyle(color: textSecondary, fontSize: 11.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),

              // 1. Direct Phone Call Option (1111)
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const FaIcon(FontAwesomeIcons.phone, color: Color(0xFF10B981), size: 18),
                ),
                title: Text(
                  context.tr('callSupportBtn'),
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
                subtitle: Text(
                  context.tr('callSupportSub'),
                  style: TextStyle(color: textSecondary, fontSize: 11.sp),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchContactUrl(context, 'tel:1111');
                },
              ),
              Divider(color: border),

              // 2. Email Support Option (Watheqa@support.com)
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const FaIcon(FontAwesomeIcons.envelope, color: AppColors.primary, size: 18),
                ),
                title: Text(
                  context.tr('emailSupportBtn'),
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
                subtitle: Text(
                  context.tr('emailSupportSub'),
                  style: TextStyle(color: textSecondary, fontSize: 11.sp),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  final subject = Uri.encodeComponent(isAr ? 'طلب دعم واستفسار - منصة وثيقة' : 'Support Request - Watheqa Platform');
                  _launchContactUrl(context, 'mailto:Watheqa@support.com?subject=$subject');
                },
              ),
              Divider(color: border),

              // 3. WhatsApp Fast Chat Option
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 18),
                ),
                title: Text(
                  context.tr('whatsappSupportBtn'),
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
                subtitle: Text(
                  context.tr('whatsappSupportSub'),
                  style: TextStyle(color: textSecondary, fontSize: 11.sp),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchContactUrl(context, 'https://wa.me/201111111111');
                },
              ),
              Divider(color: border),

              // 4. Developer Portfolio
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const FaIcon(FontAwesomeIcons.laptopCode, color: AppColors.gold, size: 18),
                ),
                title: Text(
                  isAr ? 'بورتفوليو مبرمج التطبيق 👨‍💻' : 'Developer Portfolio 👨‍💻',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
                subtitle: const Text('https://v0-youssef-farahat.vercel.app/', style: TextStyle(color: AppColors.gold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchContactUrl(context, 'https://v0-youssef-farahat.vercel.app/');
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }
}
