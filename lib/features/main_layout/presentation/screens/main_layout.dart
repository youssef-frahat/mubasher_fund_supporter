import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/language/language_cubit.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
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
