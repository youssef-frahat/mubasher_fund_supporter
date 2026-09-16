import 'package:flutter/material.dart';
import '../../../../core/language/language_cubit.dart';
import 'admin_funds_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const AdminFundsScreen(),
      Center(child: Text('${context.tr('usersManagement')} (${context.tr('comingSoon')})')),
      Center(child: Text('${context.tr('settings')} (${context.tr('comingSoon')})')),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: const Icon(Icons.account_balance_wallet),
                label: Text(context.tr('funds')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: Text(context.tr('users')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(context.tr('settings')),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
