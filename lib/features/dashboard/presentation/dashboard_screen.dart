import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/app_theme.dart';
import '../../../core/auth/roles.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../data/models/demanda_status_rules.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dashboardOverviewProvider);
    final demandas = ref.watch(dashboardDemandasProvider);
    final auth = ref.watch(authControllerProvider).valueOrNull;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardOverviewProvider);
        ref.invalidate(dashboardDemandasProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            auth == null
                ? 'PAINEL OPERACIONAL'
                : 'BEM-VINDO, ${auth.nome.toUpperCase()}!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 3),
          Text(
            auth == null
                ? 'Visão geral do AusterAgX.'
                : perfilLabel(auth.perfil),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AusterColors.neutral700,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            'VISÃO GERAL',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AusterColors.primary700,
                ),
          ),
          const SizedBox(height: 10),
          overview.when(
            data: (data) => data == null
                ? const _EmptyState(text: 'Nenhum resumo salvo ainda.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OverviewGrid(overview: data),
                      const SizedBox(height: 12),
                      _AreaSummary(overview: data),
                      if (data.maioresFazendas.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _TopFazendas(fazendas: data.maioresFazendas),
                      ],
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                _EmptyState(text: userFacingErrorMessage(error)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'DEMANDAS RECENTES',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
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
            error: (error, _) =>
                _EmptyState(text: userFacingErrorMessage(error)),
          ),
        ],
      ),
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
      ('Talhões', overview.totalTalhoes.toString(), Icons.grid_view),
      ('Vínculos', overview.totalVinculosAtivos.toString(), Icons.link),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
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
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AusterColors.primary100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    metric.$3,
                    size: 18,
                    color: AusterColors.primary700,
                  ),
                ),
                const Spacer(),
                Text(
                  metric.$2,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AusterColors.primary900,
                      ),
                ),
                Text(
                  metric.$1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AreaSummary extends StatelessWidget {
  const _AreaSummary({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    final areaFazendas = _formatArea(overview.areaTotalFazendasHa);
    final areaTalhoes = _formatArea(overview.areaTotalTalhoesHa);
    final cobertura = overview.coberturaAreaTalhoesPercentual == null
        ? '-'
        : '${overview.coberturaAreaTalhoesPercentual!.toStringAsFixed(1)}%';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Text(
              'ÁREAS E COBERTURA',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _MetricLine(
                    label: 'Área total das fazendas', value: areaFazendas),
                _MetricLine(
                    label: 'Área total dos talhões', value: areaTalhoes),
                _MetricLine(label: 'Cobertura por talhões', value: cobertura),
                _MetricLine(
                  label: 'Fazendas sem área',
                  value: overview.fazendasSemAreaInformada.toString(),
                ),
                _MetricLine(
                  label: 'Fazendas sem talhões',
                  value: overview.fazendasSemTalhoes.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopFazendas extends StatelessWidget {
  const _TopFazendas({required this.fazendas});

  final List<DashboardTopFazenda> fazendas;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Text(
              'MAIORES FAZENDAS',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(
              children: [
                for (final fazenda in fazendas.take(3))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.landscape_outlined),
                    title: Text(fazenda.nome),
                    subtitle: Text(
                      '${_formatArea(fazenda.areaHa)} · ${fazenda.totalTalhoes} talhões',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandPreviewCard extends StatelessWidget {
  const _DemandPreviewCard(this.item);

  final DashboardDemandItem item;

  @override
  Widget build(BuildContext context) {
    final grupo = grupoDaDemanda(
      status: item.status,
      situacaoMapeamento: item.situacaoMapeamento,
    );
    final indicadores = derivarIndicadores(
      status: item.status,
      situacaoDados: item.situacaoDados,
      situacaoMapeamento: item.situacaoMapeamento,
      tipo: item.tipo,
      metodoMapeamento: item.metodoMapeamento,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/demandas/${item.id}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: AusterColors.primary500),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.codigo,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AusterColors.primary700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            item.fazenda,
                            item.responsavelNome,
                            statusDemandaLabel(item.status),
                          ].whereType<String>().join(' · '),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Chip(
                              label: Text(tipoDemandaLabel(item.tipo)),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(grupoOperacionalLabel(grupo)),
                              visualDensity: VisualDensity.compact,
                            ),
                            if (indicadores != null)
                              Chip(
                                label: Text(
                                  indicadores.liberadoParaPrescricao
                                      ? 'Liberado'
                                      : 'Pendente',
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
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

String _formatArea(double? value) {
  if (value == null) return '-';
  return '${NumberFormat.decimalPattern('pt_BR').format(value)} ha';
}
