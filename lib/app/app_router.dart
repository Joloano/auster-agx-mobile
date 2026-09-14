import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/auth_controller.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/demandas/presentation/demanda_details_screen.dart';
import '../features/demandas/presentation/demandas_screen.dart';
import 'shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final isLogin = state.matchedLocation == '/login';

      if (auth.isLoading) return null;
      final authenticated = auth.valueOrNull != null;
      if (!authenticated && !isLogin) return '/login';
      if (authenticated && isLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/demandas',
            builder: (context, state) => const DemandasScreen(),
          ),
          GoRoute(
            path: '/demandas/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DemandaDetailsScreen(demandaId: id);
            },
          ),
        ],
      ),
    ],
  );
});
