import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../data/models/demanda_status_rules.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../modules/domain/module_access.dart';

class DemandasScreen extends ConsumerWidget {
  const DemandasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandas = ref.watch(dashboardDemandasProvider);
    final profile = ref.watch(authControllerProvider).valueOrNull?.perfil ?? '';
    final header = AusterPageHeader(
      icon: Icons.assignment_rounded,
      title: 'DEMANDAS',
      subtitle: 'Acompanhamento operacional por etapa e status.',
      trailing: canCreateDemanda(profile)
          ? IconButton.filled(
              tooltip: 'Criar demanda',
              onPressed: () => context.go('/demandas/nova'),
              icon: const Icon(Icons.add_task_rounded),
            )
          : null,
    );

    return RefreshIndicator(
      onRefresh: () => _refreshDemandas(ref),
      child: demandas.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                header,
                const SizedBox(height: 48),
                const _CenteredMessage('Nenhuma demanda sincronizada.'),
              ],
            );
          }
          final grouped = _groupByGrupoOperacional(items);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              header,
              const SizedBox(height: 22),
              for (final grupo in [
                ...grupoOperacionalOrder,
                ...grouped.keys.where(
                  (grupo) => !grupoOperacionalOrder.contains(grupo),
                ),
              ])
                if (grouped.containsKey(grupo)) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AusterColors.neutral100,
                      border: Border.all(color: AusterColors.neutral300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            grupoOperacionalLabel(grupo),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AusterColors.neutral900,
                                ),
                          ),
                        ),
                        Chip(
                          label: Text(grouped[grupo]!.length.toString()),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AusterColors.primary100,
                          side: const BorderSide(
                            color: AusterColors.primary300,
                          ),
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
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            header,
            const SizedBox(height: 48),
            AusterErrorState(
              message: userFacingErrorMessage(error),
              onRetry: () => _refreshDemandas(ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshDemandas(WidgetRef ref) async {
    final request = ref.refresh(dashboardDemandasProvider.future);
    try {
      await request;
    } catch (_) {
      // O provider mantém o erro para a própria tela apresentar.
    }
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
    final tone = _statusTone(item.status);
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
                Container(width: 5, color: tone.foreground),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: tone.background,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                size: 20,
                                color: tone.foreground,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.codigo,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AusterColors.primary700,
                                    ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AusterColors.primary700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            item.fazenda,
                            item.talhoes.isEmpty
                                ? null
                                : item.talhoes.join(', '),
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
                              backgroundColor: tone.background,
                              side: BorderSide(color: tone.border),
                              labelStyle: TextStyle(
                                color: tone.foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Chip(
                              label:
                                  Text(situacaoDadosLabel(item.situacaoDados)),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(
                                situacaoMapeamentoLabel(
                                    item.situacaoMapeamento),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            if (indicadores != null)
                              Chip(
                                label: Text(
                                  indicadores.liberadoParaPrescricao
                                      ? 'Pronto para prescrição'
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

({Color background, Color foreground, Color border}) _statusTone(
  String status,
) {
  final normalized = status.toUpperCase();
  if (normalized.contains('CONCLUID')) {
    return (
      background: AusterColors.successBackground,
      foreground: const Color(0xFF006B3A),
      border: const Color(0xFF9BD9BE),
    );
  }
  if (normalized.contains('CANCEL')) {
    return (
      background: AusterColors.errorBackground,
      foreground: const Color(0xFF8F231D),
      border: const Color(0xFFE8A39E),
    );
  }
  if (normalized.contains('AGEND') || normalized.contains('ANDAMENTO')) {
    return (
      background: AusterColors.infoBackground,
      foreground: AusterColors.primary700,
      border: const Color(0xFF9BC8EF),
    );
  }
  return (
    background: AusterColors.warningBackground,
    foreground: const Color(0xFF7A5200),
    border: const Color(0xFFF0CF7A),
  );
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
