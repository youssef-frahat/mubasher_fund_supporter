import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

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
        destinations: const [
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.house),
            selectedIcon: FaIcon(FontAwesomeIcons.house),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.robot),
            selectedIcon: FaIcon(FontAwesomeIcons.robot),
            label: 'المستشار الذكي',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.wallet),
            selectedIcon: FaIcon(FontAwesomeIcons.wallet),
            label: 'محفظتي',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.gear),
            selectedIcon: FaIcon(FontAwesomeIcons.gear),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
