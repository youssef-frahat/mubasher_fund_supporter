import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/biometric_service.dart';

class MainLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final prefs = await SharedPreferences.getInstance();
      final biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
      final isBiometricAvailable = await BiometricService.isBiometricAvailable();

      if (biometricsEnabled && isBiometricAvailable && mounted) {
        context.go(Routes.biometricLock);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurface(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.15),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: const Color(0xFF10B981), size: 19.r);
            }
            return IconThemeData(
              color: textSecondary.withValues(alpha: 0.7),
              size: 18.r,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
              );
            }
            return TextStyle(
              color: textSecondary,
              fontSize: 11.sp,
            );
          }),
          elevation: 2,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: (int index) {
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
            destinations: [
              NavigationDestination(
                icon: const FaIcon(FontAwesomeIcons.house),
                selectedIcon: const FaIcon(FontAwesomeIcons.house),
                label: context.tr('home'),
              ),
              NavigationDestination(
                icon: const FaIcon(FontAwesomeIcons.robot),
                selectedIcon: const FaIcon(FontAwesomeIcons.robot),
                label: context.tr('roboAdvisor'),
              ),
              NavigationDestination(
                icon: const FaIcon(FontAwesomeIcons.wallet),
                selectedIcon: const FaIcon(FontAwesomeIcons.wallet),
                label: context.tr('portfolio'),
              ),
              NavigationDestination(
                icon: const FaIcon(FontAwesomeIcons.gear),
                selectedIcon: const FaIcon(FontAwesomeIcons.gear),
                label: context.tr('settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
