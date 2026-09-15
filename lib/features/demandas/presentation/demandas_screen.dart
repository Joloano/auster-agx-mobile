import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/dashboard_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class DemandasScreen extends ConsumerWidget {
  const DemandasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandas = ref.watch(dashboardDemandasProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardDemandasProvider),
      child: demandas.when(
        data: (items) {
          if (items.isEmpty) {
            return const _CenteredMessage('Nenhuma demanda sincronizada.');
          }
          final grouped = _groupByStatus(items);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Demandas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final item in entry.value) _DemandaCard(item: item),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _CenteredMessage(error.toString()),
      ),
    );
  }

  Map<String, List<DashboardDemandItem>> _groupByStatus(
    List<DashboardDemandItem> items,
  ) {
    final result = <String, List<DashboardDemandItem>>{};
    for (final item in items) {
      result.putIfAbsent(item.status, () => []).add(item);
    }
    return result;
  }
}

class _DemandaCard extends StatelessWidget {
  const _DemandaCard({required this.item});

  final DashboardDemandItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.go('/demandas/${item.id}'),
        leading: CircleAvatar(
          child: Text(item.tipo.replaceAll('SMART_', '').substring(0, 1)),
        ),
        title: Text(item.codigo),
        subtitle: Text(
          [
            item.fazenda,
            item.talhoes.isEmpty ? null : item.talhoes.join(', '),
            item.dataPrevista,
          ].whereType<String>().join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
