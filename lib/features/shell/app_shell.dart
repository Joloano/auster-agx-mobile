import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../widgets/auster_logo.dart';
import '../../widgets/sync_status_bar.dart';
import '../authentication/presentation/auth_controller.dart';

const _branchPaths = ['/dashboard', '/demandas', '/modulos'];

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const AusterLogo(height: 34, width: 148),
        actions: [
          if (user != null)
            PopupMenuButton<String>(
              tooltip: 'Conta',
              onSelected: (value) async {
                if (value == 'profile') {
                  context.go('/modulos/perfil');
                  return;
                }
                if (value != 'logout') return;
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nome,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.account_circle_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Meu perfil'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Sair'),
                    ],
                  ),
                ),
              ],
              icon: CircleAvatar(
                radius: 17,
                backgroundColor: AusterColors.primary500,
                foregroundColor: Colors.white,
                child: Text(
                  _initials(user.nome),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SyncStatusBar(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Demandas',
              ),
              NavigationDestination(
                icon: Icon(Icons.apps_outlined),
                selectedIcon: Icon(Icons.apps_rounded),
                label: 'Módulos',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

int branchIndexForLocation(String location) {
  final index = _branchPaths.indexWhere(location.startsWith);
  return index < 0 ? 0 : index;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'AU';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
