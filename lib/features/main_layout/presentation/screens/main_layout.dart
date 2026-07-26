import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
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
    );
  }
}
