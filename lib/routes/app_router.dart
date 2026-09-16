import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/auth_controller.dart';
import '../features/authentication/presentation/change_password_screen.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/demandas/presentation/demanda_details_screen.dart';
import '../features/demandas/presentation/demandas_screen.dart';
import '../features/shell/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerRefresh = _RouterRefreshNotifier();
  ref
    ..listen(authControllerProvider, (_, __) => routerRefresh.notify())
    ..onDispose(routerRefresh.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: routerRefresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final currentLocation = state.matchedLocation;
      final isLogin = currentLocation == '/login';
      final isChangePassword = currentLocation == '/change-password';

      if (auth.isLoading) return null;
      final user = auth.valueOrNull;
      final authenticated = user != null;
      if (!authenticated && !isLogin) return '/login';
      if (!authenticated) return null;

      if (user.deveAlterarSenha && !isChangePassword) {
        return '/change-password';
      }
      if (!user.deveAlterarSenha && (isLogin || isChangePassword)) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/demandas',
                builder: (context, state) => const DemandasScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return DemandaDetailsScreen(demandaId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
