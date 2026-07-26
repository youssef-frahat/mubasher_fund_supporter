import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/widgets/app_loading_indicator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _startAnimationAndRedirect();
  }

  void _startAnimationAndRedirect() async {
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;
    final session = SupabaseService.client?.auth.currentSession;
    if (session != null) {
      final prefs = await SharedPreferences.getInstance();
      final biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
      final isBiometricsAvailable = await BiometricService.isBiometricAvailable();

      if (!mounted) return;
      if (biometricsEnabled && isBiometricsAvailable) {
        context.go(Routes.biometricLock);
      } else {
        context.go(Routes.home);
      }
    } else {
      if (!mounted) return;
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: Stack(
        children: [
          // Background Radial Ambient Light Glows
          Positioned(
            top: -100.h,
            left: -100.w,
            child: Container(
              width: 300.r,
              height: 300.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(duration: 2500.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
          ),
          Positioned(
            bottom: -80.h,
            right: -80.w,
            child: Container(
              width: 260.r,
              height: 260.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.1),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(duration: 3000.ms, begin: const Offset(1.1, 1.1), end: const Offset(0.8, 0.8)),
          ),

          // Main Center Splash Content
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40.h),

                // Master Glowing Vault Logo Emblem
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glowing Backdrop Aura
                      Container(
                        width: 150.r,
                        height: 150.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      // Outer Glassmorphism Ring
                      Container(
                        width: 120.r,
                        height: 120.r,
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.gold.withValues(alpha: 0.8),
                              AppColors.primary.withValues(alpha: 0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0F172A),
                          ),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60.r),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 90.r,
                                height: 90.r,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => FaIcon(
                                  FontAwesomeIcons.vault,
                                  size: 52.r,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .scale(duration: 900.ms, curve: Curves.easeOutBack, begin: const Offset(0.3, 0.3))
                .fadeIn(duration: 600.ms)
                .shimmer(delay: 900.ms, duration: 1500.ms, color: Colors.white60),

                SizedBox(height: 32.h),

                // Main Brand Typography
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'وثيقة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5.w,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scale(duration: 800.ms, begin: const Offset(0.5, 0.5), end: const Offset(1.4, 1.4)),
                  ],
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

                SizedBox(height: 6.h),

                Text(
                  'W A T H E Q A',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.w,
                  ),
                ).animate().fadeIn(delay: 500.ms),

                SizedBox(height: 16.h),

                // Glassmorphic Subtitle Tag
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'منصة ومحاكي صناديق الاستثمار في مصر 📈',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(delay: 650.ms).scale(),

                SizedBox(height: 30.h),

                // Custom Loading Indicator
                const AppLoadingIndicator(message: 'جاري الاتصال الآمن بالسوق المصري...'),

                SizedBox(height: 16.h),

                // Security & Regulatory Compliance Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.shieldHalved, color: Colors.white38, size: 11.r),
                    SizedBox(width: 6.w),
                    Text(
                      'تشفير بنكي آمن 256-bit | بيانات محاكاة دقيقة',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),
              ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
