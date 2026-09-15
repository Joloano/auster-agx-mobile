import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/sync_status_bar.dart';

const _branchPaths = ['/dashboard', '/demandas'];

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: navigationShell),
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
