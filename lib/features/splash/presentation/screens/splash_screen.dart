import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/supabase/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Remove the native splash screen as soon as this Flutter screen loads
    // so we can seamlessly begin our custom Flutter animation!
    FlutterNativeSplash.remove();
    _startAnimationAndRedirect();
  }

  void _startAnimationAndRedirect() async {
    // Wait for the gorgeous animations to finish (e.g., 2.5 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // Check Auth State
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The glowing App Icon
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9D00FF).withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 140.w,
                  height: 140.w,
                  fit: BoxFit.cover,
                ),
              ),
            )
            .animate()
            .scale(duration: 800.ms, curve: Curves.easeOutBack, begin: const Offset(0.5, 0.5))
            .fadeIn(duration: 600.ms)
            .shimmer(delay: 800.ms, duration: 1200.ms, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
