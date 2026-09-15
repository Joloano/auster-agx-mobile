import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/dashboard_models.dart';
import '../../../data/models/demanda_status_rules.dart';
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
          final grouped = _groupByGrupoOperacional(items);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Demandas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              for (final grupo in [
                ...grupoOperacionalOrder,
                ...grouped.keys.where(
                  (grupo) => !grupoOperacionalOrder.contains(grupo),
                ),
              ])
                if (grouped.containsKey(grupo)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            grupoOperacionalLabel(grupo),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Chip(
                          label: Text(grouped[grupo]!.length.toString()),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  for (final item in grouped[grupo]!) _DemandaCard(item: item),
                ]
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _CenteredMessage(error.toString()),
      ),
    );
  }

  Map<String, List<DashboardDemandItem>> _groupByGrupoOperacional(
    List<DashboardDemandItem> items,
  ) {
    final result = <String, List<DashboardDemandItem>>{};
    for (final item in items) {
      final grupo = grupoDaDemanda(
        status: item.status,
        situacaoMapeamento: item.situacaoMapeamento,
      );
      result.putIfAbsent(grupo, () => []).add(item);
    }
    return result;
  }
}

class _DemandaCard extends StatelessWidget {
  const _DemandaCard({required this.item});

  final DashboardDemandItem item;

  @override
  Widget build(BuildContext context) {
    final indicadores = derivarIndicadores(
      status: item.status,
      situacaoDados: item.situacaoDados,
      situacaoMapeamento: item.situacaoMapeamento,
      tipo: item.tipo,
      metodoMapeamento: item.metodoMapeamento,
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/demandas/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: Text(tipoDemandaLabel(item.tipo).substring(0, 1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.codigo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  item.fazenda,
                  item.talhoes.isEmpty ? null : item.talhoes.join(', '),
                  item.dataPrevista,
                ].whereType<String>().join(' · '),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    label: Text(statusDemandaLabel(item.status)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(situacaoDadosLabel(item.situacaoDados)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(
                      situacaoMapeamentoLabel(item.situacaoMapeamento),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (indicadores != null)
                    Chip(
                      label: Text(
                        indicadores.liberadoParaPrescricao
                            ? 'Pronto para prescricao'
                            : 'Aguardando requisitos',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
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
