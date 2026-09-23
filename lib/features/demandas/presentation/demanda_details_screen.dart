import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../core/auth/roles.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/demanda_models.dart';
import '../../../data/models/demanda_status_rules.dart';
import '../../../data/models/location_capture.dart';
import '../../../data/sync/sync_providers.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_section_card.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../agronomic/presentation/demand_agronomic_sections.dart';
import '../../commercial/presentation/demand_management_section.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../location/providers/location_providers.dart';
import '../providers/demandas_providers.dart';

class DemandaDetailsScreen extends ConsumerWidget {
  const DemandaDetailsScreen({required this.demandaId, super.key});

  final String demandaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(demandaDetailProvider(demandaId));
    final locations = ref.watch(locationCapturesProvider(demandaId));
    final history = ref.watch(demandaHistoricoStatusProvider(demandaId));
    final user = ref.watch(authControllerProvider).valueOrNull;
    final canManage =
        user == null ? false : isAdministrativeProfile(user.perfil);

    return detail.when(
      data: (data) {
        if (data == null) {
          return _errorPage(
            context,
            'Demanda não encontrada no cache local. Sincronize online primeiro.',
            () => _refreshDetails(ref),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AusterPageHeader(
              leading: IconButton(
                tooltip: 'Voltar para demandas',
                onPressed: () => context.go('/demandas'),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: AusterColors.primary700,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AusterColors.neutral300),
                ),
              ),
              icon: Icons.assignment_rounded,
              title: 'DETALHE DA DEMANDA',
              subtitle: 'Informações operacionais e registros de campo.',
            ),
            const SizedBox(height: 22),
            _Header(detail: data),
            const SizedBox(height: 12),
            _StatusActions(detail: data, canManage: canManage),
            if (canManage) ...[
              const SizedBox(height: 12),
              DemandManagementSection(
                detail: data,
                onChanged: () => _refreshDetails(ref),
              ),
            ],
            const SizedBox(height: 12),
            _ResumoSection(detail: data),
            const SizedBox(height: 12),
            _ContextoSection(detail: data),
            const SizedBox(height: 12),
            DemandAgronomicSections(
              demandId: data.demanda.id,
              demandType: data.demanda.tipo,
              canManage: canManage,
            ),
            const SizedBox(height: 12),
            _SensoriamentoSection(detail: data),
            const SizedBox(height: 12),
            _CadeiaSection(detail: data),
            const SizedBox(height: 12),
            _HistoricoSection(history: history),
            const SizedBox(height: 12),
            _LocationSection(demandaId: demandaId, locations: locations),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _errorPage(
        context,
        userFacingErrorMessage(error),
        () => _refreshDetails(ref),
      ),
    );
  }

  Widget _errorPage(
    BuildContext context,
    String message,
    Future<void> Function() onRetry,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        AusterPageHeader(
          leading: IconButton(
            tooltip: 'Voltar para demandas',
            onPressed: () => context.go('/demandas'),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              foregroundColor: AusterColors.primary700,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AusterColors.neutral300),
            ),
          ),
          icon: Icons.assignment_rounded,
          title: 'DETALHE DA DEMANDA',
          subtitle: 'Informações operacionais e registros de campo.',
        ),
        const SizedBox(height: 48),
        AusterErrorState(message: message, onRetry: onRetry),
      ],
    );
  }

  Future<void> _refreshDetails(WidgetRef ref) async {
    final detail = ref.refresh(demandaDetailProvider(demandaId).future);
    final history =
        ref.refresh(demandaHistoricoStatusProvider(demandaId).future);
    final statusFlow = ref.refresh(demandaStatusFluxoProvider.future);
    try {
      await Future.wait<Object?>([detail, history, statusFlow]);
    } catch (_) {
      // Os providers mantêm os erros para a própria tela apresentar.
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final DemandaDetail detail;

  @override
  Widget build(BuildContext context) {
    final demanda = detail.demanda;
    final tone = _statusTone(demanda.statusChave);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: tone.foreground),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demanda.codigoDemanda,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AusterColors.primary900,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demanda.clienteNome ?? 'Demanda operacional AUSTER',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AusterColors.neutral700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(tipoDemandaLabel(demanda.tipo))),
                        Chip(
                          label: Text(statusDemandaLabel(demanda.statusChave)),
                          backgroundColor: tone.background,
                          side: BorderSide(color: tone.border),
                          labelStyle: TextStyle(
                            color: tone.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Chip(
                          label: Text(
                            situacaoDadosLabel(demanda.situacaoDados),
                          ),
                        ),
                        Chip(
                          label: Text(
                            situacaoMapeamentoLabel(
                              demanda.situacaoMapeamento,
                            ),
                          ),
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

class _StatusActions extends ConsumerWidget {
  const _StatusActions({required this.detail, required this.canManage});

  final DemandaDetail detail;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canManage) {
      return const AusterSectionCard(
        title: 'GESTÃO DE STATUS',
        icon: Icons.rule_rounded,
        child: Text(
          'Seu perfil pode consultar a demanda, mas não pode alterar o status.',
        ),
      );
    }

    final fluxoState = ref.watch(demandaStatusFluxoProvider);
    return fluxoState.when(
      data: (fluxo) => _buildStatusCard(context, ref, fluxo),
      loading: () => const AusterSectionCard(
        title: 'GESTÃO DE STATUS',
        icon: Icons.rule_rounded,
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => AusterSectionCard(
        title: 'GESTÃO DE STATUS',
        icon: Icons.rule_rounded,
        child: AusterErrorState(
          message: userFacingErrorMessage(error),
          compact: true,
          onRetry: () => _refreshStatusFlow(ref),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    StatusFluxo? fluxo,
  ) {
    final metodoMapeamento = _metodoMapeamento(detail);
    final next = fluxo == null
        ? const <String>[]
        : proximosStatusValidos(
            status: detail.demanda.statusChave,
            situacaoDados: detail.demanda.situacaoDados,
            situacaoMapeamento: detail.demanda.situacaoMapeamento,
            tipo: detail.demanda.tipo,
            metodoMapeamento: metodoMapeamento,
            statusFluxo: fluxo,
          );
    final blocked = fluxo == null
        ? const <String>[]
        : (fluxo.transicoesValidas[detail.demanda.statusChave] ??
                const <String>[])
            .where((status) => !next.contains(status))
            .toList();

    return AusterSectionCard(
      title: 'GESTÃO DE STATUS',
      icon: Icons.rule_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Próximo status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (next.isEmpty)
            const Text('Nenhuma transição disponível agora.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in next)
                  ActionChip(
                    avatar: const Icon(Icons.swap_horiz),
                    label: Text(statusDemandaLabel(status)),
                    onPressed: () => _updateStatus(context, ref, status),
                  ),
              ],
            ),
          if (blocked.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final status in blocked)
              Text(
                '${statusDemandaLabel(status)} bloqueado: '
                '${bloqueioParaStatus(
                      proximoStatus: status,
                      situacaoDados: detail.demanda.situacaoDados,
                      situacaoMapeamento: detail.demanda.situacaoMapeamento,
                      tipo: detail.demanda.tipo,
                      metodoMapeamento: metodoMapeamento,
                      statusFluxo: fluxo!,
                    ) ?? "regra do backend"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
          const Divider(height: 24),
          Text(
            'Situação dos dados',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final situacao in situacaoDadosValues)
                ChoiceChip(
                  label: Text(situacaoDadosLabel(situacao)),
                  selected: detail.demanda.situacaoDados == situacao,
                  onSelected: detail.demanda.situacaoDados == situacao
                      ? null
                      : (_) => _updateFields(
                            context,
                            ref,
                            situacaoDados: situacao,
                          ),
                ),
            ],
          ),
          if (!demandaSemMapeamento(
            tipo: detail.demanda.tipo,
            metodoMapeamento: metodoMapeamento,
          )) ...[
            const SizedBox(height: 16),
            Text(
              'Situação do mapeamento',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final situacao in situacaoMapeamentoValues)
                  ChoiceChip(
                    label: Text(situacaoMapeamentoLabel(situacao)),
                    selected: detail.demanda.situacaoMapeamento == situacao,
                    onSelected: detail.demanda.situacaoMapeamento == situacao
                        ? null
                        : (_) => _updateFields(
                              context,
                              ref,
                              situacaoMapeamento: situacao,
                            ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshStatusFlow(WidgetRef ref) async {
    final request = ref.refresh(demandaStatusFluxoProvider.future);
    try {
      await request;
    } catch (_) {
      // O provider mantém o erro para a própria seção apresentar.
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    await _updateFields(context, ref, status: status);
  }

  Future<void> _updateFields(
    BuildContext context,
    WidgetRef ref, {
    String? status,
    String? situacaoDados,
    String? situacaoMapeamento,
  }) async {
    try {
      final repository = await ref.read(demandaRepositoryProvider.future);
      await repository.updateFields(
        current: detail,
        status: status,
        situacaoDados: situacaoDados,
        situacaoMapeamento: situacaoMapeamento,
      );
      ref.invalidate(demandaDetailProvider(detail.demanda.id));
      ref.invalidate(demandaHistoricoStatusProvider(detail.demanda.id));
      ref.invalidate(dashboardDemandasProvider);
      ref.invalidate(syncQueueSummaryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demanda atualizada ou enfileirada.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }
}

class _ResumoSection extends StatelessWidget {
  const _ResumoSection({required this.detail});

  final DemandaDetail detail;

  @override
  Widget build(BuildContext context) {
    final demanda = detail.demanda;
    final indicadores = derivarIndicadores(
      status: demanda.statusChave,
      situacaoDados: demanda.situacaoDados,
      situacaoMapeamento: demanda.situacaoMapeamento,
      tipo: demanda.tipo,
      metodoMapeamento: detail.sensoriamentos.firstOrNull?.fonte,
    );
    return AusterSectionCard(
      title: 'RESUMO',
      icon: Icons.summarize_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'Dados',
            value: situacaoDadosLabel(demanda.situacaoDados),
          ),
          _InfoRow(
            label: 'Mapeamento',
            value: situacaoMapeamentoLabel(demanda.situacaoMapeamento),
          ),
          _InfoRow(label: 'Prazo', value: demanda.prazo ?? '-'),
          _InfoRow(
            label: 'Responsavel',
            value: demanda.representanteNome ?? '-',
          ),
          _InfoRow(
            label: 'Aplicação',
            value: demanda.numeroAplicacao?.toString() ?? '-',
          ),
          _InfoRow(
            label: 'Retrabalho',
            value: demanda.retrabalho ? 'Sim' : 'Não',
          ),
          _InfoRow(
            label: 'Criada em',
            value: _formatDateTime(demanda.createdAt),
          ),
          if (indicadores != null)
            _InfoRow(
              label: 'Liberacao',
              value: indicadores.liberadoParaPrescricao
                  ? 'Pronta para prescrição'
                  : 'Aguardando requisitos',
            ),
        ],
      ),
    );
  }
}

class _ContextoSection extends StatelessWidget {
  const _ContextoSection({required this.detail});

  final DemandaDetail detail;

  @override
  Widget build(BuildContext context) {
    final demanda = detail.demanda;
    final talhoes = detail.grupos.expand((grupo) => grupo.talhoes).toList();
    return AusterSectionCard(
      title: 'CONTEXTO',
      icon: Icons.account_tree_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'Pedido',
            value: [
              detail.pedido.codigo,
              detail.pedido.apelido,
            ].whereType<String>().join(' · '),
          ),
          _InfoRow(
            label: 'Cliente',
            value: detail.cliente?.nomeFantasia ?? demanda.clienteNome ?? '-',
          ),
          _InfoRow(
            label: 'Fazendas',
            value: detail.fazendas.isEmpty
                ? demanda.fazendaNomes.join(', ')
                : detail.fazendas.map((fazenda) => fazenda.nome).join(', '),
          ),
          _InfoRow(
            label: 'Grupos',
            value: detail.grupos.isEmpty
                ? '-'
                : detail.grupos.map((grupo) => grupo.nome).join(', '),
          ),
          _InfoRow(
            label: 'Talhões',
            value: talhoes.isEmpty
                ? '-'
                : talhoes.map((talhao) => talhao.nome).join(', '),
          ),
          _InfoRow(
            label: 'Culturas',
            value: detail.culturas.isEmpty
                ? '-'
                : detail.culturas.map((cultura) => cultura.nome).join(', '),
          ),
          _InfoRow(
            label: 'Área',
            value: demanda.areaDeInteresse ?? '-',
          ),
        ],
      ),
    );
  }
}

class _SensoriamentoSection extends StatelessWidget {
  const _SensoriamentoSection({required this.detail});

  final DemandaDetail detail;

  @override
  Widget build(BuildContext context) {
    return AusterSectionCard(
      title: 'SENSORIAMENTO',
      icon: Icons.satellite_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.sensoriamentos.isEmpty)
            const Text('Sem sensoriamento vinculado.')
          else
            for (final sensoriamento in detail.sensoriamentos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.satellite_alt_outlined),
                title: Text(sensoriamento.codigoMapeamento),
                subtitle: Text(
                  [
                    sensoriamento.fonte,
                    sensoriamento.satelite,
                    sensoriamento.pilotoNome,
                    sensoriamento.status.replaceAll('_', ' '),
                  ].whereType<String>().join(' · '),
                ),
              ),
        ],
      ),
    );
  }
}

class _CadeiaSection extends StatelessWidget {
  const _CadeiaSection({required this.detail});

  final DemandaDetail detail;

  @override
  Widget build(BuildContext context) {
    return AusterSectionCard(
      title: 'CADEIA DE DEMANDAS',
      icon: Icons.link_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'Origem',
            value: detail.demandaOrigem == null
                ? 'Esta é a demanda raiz.'
                : '${detail.demandaOrigem!.codigoDemanda} · '
                    '${statusDemandaLabel(detail.demandaOrigem!.status)}',
          ),
          if (detail.derivadas.isEmpty)
            const Text('Nenhuma aplicação seguinte ou retrabalho.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final derivada in detail.derivadas)
                  Chip(
                    label: Text(
                      '${derivada.codigoDemanda} · '
                      '${statusDemandaLabel(derivada.status)}',
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HistoricoSection extends StatelessWidget {
  const _HistoricoSection({required this.history});

  final AsyncValue<List<DemandaStatusHistorico>> history;

  @override
  Widget build(BuildContext context) {
    return AusterSectionCard(
      title: 'HISTÓRICO DE STATUS',
      icon: Icons.history_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          history.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('Nenhuma alteração de status registrada.');
              }
              return Column(
                children: [
                  for (final item in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: Text(
                        [
                          item.statusAnteriorChave == null
                              ? null
                              : statusDemandaLabel(item.statusAnteriorChave!),
                          statusDemandaLabel(item.statusNovoChave),
                        ].whereType<String>().join(' -> '),
                      ),
                      subtitle: Text(
                        '${item.alteradoPorNome} · '
                        '${_formatDateTime(item.alteradoEm)}',
                      ),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(userFacingErrorMessage(error)),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends ConsumerWidget {
  const _LocationSection({required this.demandaId, required this.locations});

  final String demandaId;
  final AsyncValue<List<LocationCapture>> locations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AusterSectionCard(
      title: 'LOCALIZAÇÃO DE CAMPO',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Captura local para apoio em campo. Os registros permanecem no dispositivo.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _capture(context, ref),
            icon: const Icon(Icons.my_location),
            label: const Text('Registrar localização atual'),
          ),
          const SizedBox(height: 12),
          locations.when(
            data: (items) => items.isEmpty
                ? const Text('Nenhuma localização capturada.')
                : Column(
                    children: [
                      for (final item in items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.place_outlined),
                          title: Text('${item.latitude}, ${item.longitude}'),
                          subtitle: Text(
                            'Precisão: ${item.accuracy?.toStringAsFixed(1) ?? '-'} m',
                          ),
                        ),
                    ],
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(userFacingErrorMessage(error)),
          ),
        ],
      ),
    );
  }

  Future<void> _capture(BuildContext context, WidgetRef ref) async {
    try {
      final service = await ref.read(locationServiceProvider.future);
      await service.captureCurrentLocation(demandaId);
      ref.invalidate(locationCapturesProvider(demandaId));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }
}

String? _metodoMapeamento(DemandaDetail detail) {
  if (detail.sensoriamentos.isNotEmpty) {
    return detail.sensoriamentos.first.fonte;
  }
  return detail.demanda.sensoriamentoIds.isEmpty ? null : 'DRONE';
}

String _formatDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final date = parsed.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
