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
import '../features/agronomic/presentation/cultures_screen.dart';
import '../features/agronomic/presentation/phenological_stages_screen.dart';
import '../features/commercial/presentation/new_demand_screen.dart';
import '../features/commercial/presentation/order_details_screen.dart';
import '../features/commercial/presentation/orders_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/demandas/presentation/demanda_details_screen.dart';
import '../features/demandas/presentation/demandas_screen.dart';
import '../features/modules/presentation/modules_screen.dart';
import '../features/modules/domain/module_access.dart';
import '../features/rural/presentation/client_details_screen.dart';
import '../features/rural/presentation/clients_screen.dart';
import '../features/rural/presentation/farm_details_screen.dart';
import '../features/rural/presentation/farms_screen.dart';
import '../features/rural/presentation/field_details_screen.dart';
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
      if (currentLocation == '/demandas/nova' &&
          !canCreateDemanda(user.perfil)) {
        return '/modulos';
      }
      if (currentLocation.startsWith('/demandas') &&
          currentLocation != '/demandas/nova' &&
          !canAccessModule(user.perfil, AppModuleId.demandas)) {
        return '/modulos';
      }
      if (currentLocation.startsWith('/modulos/pedidos') &&
          !canAccessModule(user.perfil, AppModuleId.pedidos)) {
        return '/modulos';
      }
      if (currentLocation.startsWith('/modulos/culturas') &&
          !canAccessModule(user.perfil, AppModuleId.culturas)) {
        return '/modulos';
      }
      if (currentLocation.startsWith('/modulos/estadios-fenologicos') &&
          !canAccessModule(user.perfil, AppModuleId.estadiosFenologicos)) {
        return '/modulos';
      }
      final ruralLocation = currentLocation.startsWith('/modulos/fazendas') ||
          currentLocation.startsWith('/modulos/talhoes');
      if (ruralLocation &&
          !canAccessModule(user.perfil, AppModuleId.fazendas)) {
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
                    path: 'nova',
                    builder: (context, state) => NewDemandScreen(
                      initialOrderId: state.uri.queryParameters['pedidoId'],
                    ),
                  ),
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
                  GoRoute(
                    path: 'clientes',
                    builder: (context, state) => const ClientsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => ClientDetailsScreen(
                          clientId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'fazendas',
                    builder: (context, state) => const FarmsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => FarmDetailsScreen(
                          farmId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'pedidos',
                    builder: (context, state) => const OrdersScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => OrderDetailsScreen(
                          orderId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'culturas',
                    builder: (context, state) => const CulturesScreen(),
                  ),
                  GoRoute(
                    path: 'estadios-fenologicos',
                    builder: (context, state) =>
                        const PhenologicalStagesScreen(),
                  ),
                  GoRoute(
                    path: 'talhoes/:id',
                    builder: (context, state) => FieldDetailsScreen(
                      fieldId: state.pathParameters['id']!,
                    ),
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
