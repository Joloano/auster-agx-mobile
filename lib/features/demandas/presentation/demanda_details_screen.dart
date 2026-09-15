import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../location/domain/location_capture.dart';
import '../../location/providers/location_providers.dart';
import '../data/demanda_repository.dart';
import '../data/demandas_api.dart';
import '../domain/demanda_models.dart';
import '../providers/demandas_providers.dart';

class DemandaDetailsScreen extends ConsumerWidget {
  const DemandaDetailsScreen({required this.demandaId, super.key});

  final String demandaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(demandaDetailProvider(demandaId));
    final locations = ref.watch(locationCapturesProvider(demandaId));

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
              _StatusActions(detail: data),
              const SizedBox(height: 12),
              _InfoSection(detail: data),
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
                Chip(label: Text(demanda.tipo)),
                Chip(label: Text(demanda.status)),
                Chip(label: Text(demanda.situacaoDados)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusActions extends ConsumerWidget {
  const _StatusActions({required this.detail});

  final DemandaDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<DemandaRepository>(
      future: ref.watch(demandaRepositoryProvider.future),
      builder: (context, repositorySnapshot) {
        return FutureBuilder<StatusFluxo?>(
          future: repositorySnapshot.data?.loadStatusFluxo(),
          builder: (context, fluxoSnapshot) {
            final next = fluxoSnapshot
                    .data?.transicoesValidas[detail.demanda.statusChave] ??
                const <String>[];
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
                              label: Text(statusLabels[status] ?? status),
                              onPressed: repositorySnapshot.hasData
                                  ? () => _updateStatus(context, ref, status)
                                  : null,
                            ),
                        ],
                      ),
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
    final repository = await ref.read(demandaRepositoryProvider.future);
    await repository.updateStatus(current: detail, status: status);
    ref.invalidate(demandaDetailProvider(detail.demanda.id));
    ref.invalidate(dashboardDemandasProvider);
    ref.invalidate(pendingSyncCountProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status atualizado ou enfileirado.')),
      );
    }
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.detail});

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
            Text('Contexto', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _InfoRow(label: 'Pedido', value: demanda.pedidoCodigo),
            _InfoRow(label: 'Cliente', value: demanda.clienteNome ?? '-'),
            _InfoRow(label: 'Fazendas', value: demanda.fazendaNomes.join(', ')),
            _InfoRow(label: 'Prazo', value: demanda.prazo ?? '-'),
            _InfoRow(
              label: 'Responsavel',
              value: demanda.representanteNome ?? '-',
            ),
            _InfoRow(
              label: 'Area de interesse',
              value: demanda.areaDeInteresse ?? '-',
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
