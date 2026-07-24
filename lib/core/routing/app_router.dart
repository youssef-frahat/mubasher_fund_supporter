import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/admin/presentation/screens/admin_layout.dart';
import 'routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.admin,
        builder: (context, state) => const AdminLayout(),
      ),
    ],
  );
}
