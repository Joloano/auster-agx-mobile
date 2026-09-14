import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dashboardOverviewProvider);
    final demandas = ref.watch(dashboardDemandasProvider);
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final pending = ref.watch(pendingSyncCountProvider);
    ref.watch(syncServiceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardOverviewProvider);
        ref.invalidate(dashboardDemandasProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (auth != null) Text('${auth.nome} · ${auth.perfil}'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sair',
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ConnectivityBanner(),
          pending.when(
            data: (count) => count > 0
                ? _InfoBanner(
                    icon: Icons.sync_problem,
                    text: '$count alteracao(es) aguardando sincronizacao.',
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          overview.when(
            data: (data) => data == null
                ? const _EmptyState(text: 'Nenhum resumo salvo ainda.')
                : _OverviewGrid(overview: data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _EmptyState(text: error.toString()),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Demandas recentes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/demandas'),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          demandas.when(
            data: (items) => Column(
              children: items.take(5).map(_DemandPreviewCard.new).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _EmptyState(text: error.toString()),
          ),
        ],
      ),
    );
  }
}

class _ConnectivityBanner extends ConsumerWidget {
  const _ConnectivityBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineStatusProvider).valueOrNull ?? true;
    if (online) return const SizedBox.shrink();
    return const _InfoBanner(
      icon: Icons.wifi_off,
      text: 'Voce esta offline. Exibindo dados salvos no dispositivo.',
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(leading: Icon(icon), title: Text(text)),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Clientes', overview.totalClientes.toString(), Icons.people_outline),
      ('Fazendas', overview.totalFazendas.toString(), Icons.grass_outlined),
      ('Talhoes', overview.totalTalhoes.toString(), Icons.grid_view),
      ('Vinculos', overview.totalVinculosAtivos.toString(), Icons.link),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(metric.$3),
                const SizedBox(height: 8),
                Text(
                  metric.$2,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(metric.$1),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DemandPreviewCard extends StatelessWidget {
  const _DemandPreviewCard(this.item);

  final DashboardDemandItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.go('/demandas/${item.id}'),
        leading: const Icon(Icons.assignment_outlined),
        title: Text(item.codigo),
        subtitle: Text(
          [
            item.fazenda,
            item.responsavelNome,
            item.status,
          ].whereType<String>().join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(text)),
      ),
    );
  }
}
