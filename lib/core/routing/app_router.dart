import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/admin/presentation/screens/admin_layout.dart';
import '../../features/main_layout/presentation/screens/main_layout.dart';
import '../../features/funds/presentation/screens/fund_details_screen.dart';
import '../../features/home/data/models/platform_feature.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.compare,
                builder: (context, state) => const Scaffold(body: Center(child: Text('Compare Screen'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.portfolio,
                builder: (context, state) => const Scaffold(body: Center(child: Text('Portfolio Screen'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.fundDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final fund = state.extra as PlatformFeature;
          return FundDetailsScreen(fund: fund);
        },
      ),
      GoRoute(
        path: Routes.admin,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminLayout(),
      ),
    ],
  );
}
