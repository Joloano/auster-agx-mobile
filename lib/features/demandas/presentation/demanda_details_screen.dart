import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/roles.dart';
import '../../../data/models/demanda_models.dart';
import '../../../data/models/demanda_status_rules.dart';
import '../../../data/models/location_capture.dart';
import '../../../data/repositorios/demanda_repository.dart';
import '../../../data/sync/sync_providers.dart';
import '../../authentication/presentation/auth_controller.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da demanda')),
      body: detail.when(
        data: (data) {
          if (data == null) {
            return const _CenteredMessage(
              'Demanda nao encontrada no cache local. Sincronize online primeiro.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(detail: data),
              const SizedBox(height: 12),
              _StatusActions(detail: data, canManage: canManage),
              const SizedBox(height: 12),
              _ResumoSection(detail: data),
              const SizedBox(height: 12),
              _ContextoSection(detail: data),
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
        error: (error, _) => _CenteredMessage(error.toString()),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final DemandaDetail detail;

  @override
  Widget build(BuildContext context) {
    final demanda = detail.demanda;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              demanda.codigoDemanda,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(tipoDemandaLabel(demanda.tipo))),
                Chip(label: Text(demanda.status)),
                Chip(label: Text(situacaoDadosLabel(demanda.situacaoDados))),
                Chip(
                  label: Text(
                    situacaoMapeamentoLabel(demanda.situacaoMapeamento),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusActions extends ConsumerWidget {
  const _StatusActions({required this.detail, required this.canManage});

  final DemandaDetail detail;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canManage) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Seu perfil pode consultar a demanda, mas nao pode alterar status.',
          ),
        ),
      );
    }

    return FutureBuilder<DemandaRepository>(
      future: ref.watch(demandaRepositoryProvider.future),
      builder: (context, repositorySnapshot) {
        return FutureBuilder<StatusFluxo?>(
          future: repositorySnapshot.data?.loadStatusFluxo(),
          builder: (context, fluxoSnapshot) {
            final fluxo = fluxoSnapshot.data;
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
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    if (next.isEmpty)
                      const Text('Nenhuma transicao disponivel agora.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final status in next)
                            ActionChip(
                              avatar: const Icon(Icons.swap_horiz),
                              label: Text(statusDemandaLabel(status)),
                              onPressed: repositorySnapshot.hasData
                                  ? () => _updateStatus(context, ref, status)
                                  : null,
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
                                situacaoMapeamento:
                                    detail.demanda.situacaoMapeamento,
                                tipo: detail.demanda.tipo,
                                metodoMapeamento: metodoMapeamento,
                                statusFluxo: fluxo!,
                              ) ?? "regra do backend"}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                    const Divider(height: 24),
                    Text(
                      'Situacao dos dados',
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
                        'Situacao do mapeamento',
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
                              selected:
                                  detail.demanda.situacaoMapeamento == situacao,
                              onSelected:
                                  detail.demanda.situacaoMapeamento == situacao
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
              ),
            );
          },
        );
      },
    );
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
    ref.invalidate(pendingSyncCountProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demanda atualizada ou enfileirada.')),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
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
              label: 'Aplicacao',
              value: demanda.numeroAplicacao?.toString() ?? '-',
            ),
            _InfoRow(
                label: 'Retrabalho', value: demanda.retrabalho ? 'Sim' : 'Nao'),
            _InfoRow(
                label: 'Criada em', value: _formatDateTime(demanda.createdAt)),
            if (indicadores != null)
              _InfoRow(
                label: 'Liberacao',
                value: indicadores.liberadoParaPrescricao
                    ? 'Pronta para prescricao'
                    : 'Aguardando requisitos',
              ),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contexto', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
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
              label: 'Talhoes',
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
              label: 'Area',
              value: demanda.areaDeInteresse ?? '-',
            ),
          ],
        ),
      ),
    );
  }
}

class _SensoriamentoSection extends StatelessWidget {
  const _SensoriamentoSection({required this.detail});

  final DemandaDetail detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sensoriamento',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
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
      ),
    );
  }
}

class _CadeiaSection extends StatelessWidget {
  const _CadeiaSection({required this.detail});

  final DemandaDetail detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cadeia de demandas',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Origem',
              value: detail.demandaOrigem == null
                  ? 'Esta e a demanda raiz.'
                  : '${detail.demandaOrigem!.codigoDemanda} · '
                      '${statusDemandaLabel(detail.demandaOrigem!.status)}',
            ),
            if (detail.derivadas.isEmpty)
              const Text('Nenhuma aplicacao seguinte ou retrabalho.')
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
      ),
    );
  }
}

class _HistoricoSection extends StatelessWidget {
  const _HistoricoSection({required this.history});

  final AsyncValue<List<DemandaStatusHistorico>> history;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historico de status',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            history.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Text('Nenhuma alteracao de status registrada.');
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
              error: (error, _) => Text(error.toString()),
            ),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('GPS', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Captura local academica. Nao sincroniza com backend sem endpoint oficial.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _capture(context, ref),
              icon: const Icon(Icons.my_location),
              label: const Text('Registrar localizacao atual'),
            ),
            const SizedBox(height: 12),
            locations.when(
              data: (items) => items.isEmpty
                  ? const Text('Nenhuma localizacao capturada.')
                  : Column(
                      children: [
                        for (final item in items)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.place_outlined),
                            title: Text('${item.latitude}, ${item.longitude}'),
                            subtitle: Text(
                              'Precisao: ${item.accuracy?.toStringAsFixed(1) ?? '-'} m',
                            ),
                          ),
                      ],
                    ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(error.toString()),
            ),
          ],
        ),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
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
