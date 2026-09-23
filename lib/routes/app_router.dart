import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/auth_controller.dart';
import '../features/authentication/presentation/auth_loading_screen.dart';
import '../features/authentication/presentation/change_password_screen.dart';
import '../features/authentication/presentation/forgot_password_screen.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/profile_screen.dart';
import '../features/authentication/presentation/reset_password_screen.dart';
import '../features/authentication/presentation/users_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/demandas/presentation/demanda_details_screen.dart';
import '../features/demandas/presentation/demandas_screen.dart';
import '../features/modules/presentation/modules_screen.dart';
import '../features/shell/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerRefresh = _RouterRefreshNotifier();
  ref
    ..listen(authControllerProvider, (_, __) => routerRefresh.notify())
    ..onDispose(routerRefresh.dispose);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: routerRefresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final currentLocation = state.matchedLocation;
      final isLoading = currentLocation == '/loading';
      final isLogin = currentLocation == '/login';
      final isForgotPassword = currentLocation == '/esqueci-senha';
      final isResetPassword = currentLocation == '/redefinir-senha';
      final isChangePassword = currentLocation == '/change-password';
      final isPublicAuth = isLogin || isForgotPassword || isResetPassword;

      if (auth.isLoading) {
        if (isLoading) return null;
        return Uri(
          path: '/loading',
          queryParameters: {'redirect': state.uri.toString()},
        ).toString();
      }
      final user = auth.valueOrNull;
      final authenticated = user != null;
      if (!authenticated && !isPublicAuth) return '/login';
      if (!authenticated) return null;

      if (user.deveAlterarSenha && !isChangePassword) {
        return '/change-password';
      }
      if (!user.deveAlterarSenha && isLoading) {
        return _safeRedirectTarget(state) ?? '/dashboard';
      }
      if (!user.deveAlterarSenha && (isPublicAuth || isChangePassword)) {
        return '/dashboard';
      }
      if (currentLocation.startsWith('/modulos/usuarios') &&
          user.perfil != 'SUPER_ADMIN') {
        return '/modulos';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/esqueci-senha',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/redefinir-senha',
        builder: (context, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/modulos',
                builder: (context, state) => const ModulesScreen(),
                routes: [
                  GoRoute(
                    path: 'usuarios',
                    builder: (context, state) => const UsersScreen(),
                  ),
                  GoRoute(
                    path: 'perfil',
                    builder: (context, state) => const ProfileScreen(),
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

String? _safeRedirectTarget(GoRouterState state) {
  final target = state.uri.queryParameters['redirect'];
  if (target == null || target.isEmpty || target.startsWith('//')) return null;

  final uri = Uri.tryParse(target);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/')) {
    return null;
  }
  if (uri.path == '/loading') return null;
  return uri.toString();
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
