import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/admin/presentation/screens/admin_layout.dart';
import '../../features/main_layout/presentation/screens/main_layout.dart';
import '../../features/funds/presentation/screens/fund_details_screen.dart';
import '../../features/home/data/models/platform_feature.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/portfolio/presentation/screens/portfolio_screen.dart';
import '../../features/calculator/presentation/screens/investment_calculator_screen.dart';
import 'routes.dart';
import '../supabase/supabase_service.dart';
import 'go_router_refresh_stream.dart';
import '../../features/funds/presentation/screens/all_funds_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/terms_conditions_screen.dart';
import '../../features/settings/presentation/screens/faq_screen.dart';

import '../../features/auth/presentation/screens/register_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorSettingsKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(SupabaseService.client!.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = SupabaseService.client?.auth.currentSession;
      final isAuthenticated = session != null;
      
      final isGoingToSplash = state.matchedLocation == Routes.splash;
      final isGoingToLogin = state.matchedLocation == Routes.login;
      final isGoingToRegister = state.matchedLocation == Routes.register;
      final isGoingToOtp = state.matchedLocation == Routes.otp;
      final isAuthRoute = isGoingToLogin || isGoingToRegister || isGoingToOtp;

      // Allow splash screen to show regardless of auth state
      if (isGoingToSplash) return null;

      // If user is not authenticated and not heading to an auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return Routes.login;
      }

      // If user is authenticated and heading to an auth route, redirect to home
      if (isAuthenticated && isAuthRoute) {
        return Routes.home;
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
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
                builder: (context, state) => const InvestmentCalculatorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.portfolio,
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.profile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
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
        path: Routes.otp,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final email = state.extra as String;
          return OtpScreen(email: email);
        },
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
        path: Routes.allFunds,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AllFundsScreen(),
      ),

      GoRoute(
        path: Routes.termsConditions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      GoRoute(
        path: Routes.faq,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: Routes.admin,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminLayout(),
      ),
    ],
  );
}
