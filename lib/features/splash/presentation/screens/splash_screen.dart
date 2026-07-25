import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/routing/routes.dart';
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
    await Future.delayed(const Duration(milliseconds: 2600));

    if (!mounted) return;
    final session = SupabaseService.client?.auth.currentSession;
    if (session != null) {
      context.go(Routes.home);
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              AppColors.midnightNavy,
              const Color(0xFF090D16),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Glowing Animated App Vault Emblem
              Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.slateCard,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    width: 2.r,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.vault,
                    size: 64.r,
                    color: AppColors.primary,
                  ),
                ),
              )
              .animate()
              .scale(duration: 800.ms, curve: Curves.easeOutBack, begin: const Offset(0.4, 0.4))
              .fadeIn(duration: 600.ms)
              .shimmer(delay: 800.ms, duration: 1200.ms, color: Colors.white70),

              SizedBox(height: 28.h),

              // Brand Title
              Text(
                'وثيقة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.w,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

              SizedBox(height: 6.h),

              Text(
                'Watheqa Financial Platform',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2.w,
                ),
              ).animate().fadeIn(delay: 450.ms),

              SizedBox(height: 12.h),

              // Subtitle Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'المستشار الذكي ومحاكي محفظة الصناديق 📈',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).scale(),

              const Spacer(flex: 2),

              // Custom Futuristic Loading Indicator
              const AppLoadingIndicator(message: 'جاري تهيئة البيانات المالية...'),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
