import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/demanda_models.dart';
import '../../../data/models/rural_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_record_form.dart';
import '../../../widgets/auster_section_card.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../demandas/providers/demandas_providers.dart';
import '../../rural/providers/rural_providers.dart';
import '../providers/commercial_providers.dart';

class DemandManagementSection extends ConsumerStatefulWidget {
  const DemandManagementSection({
    required this.detail,
    required this.onChanged,
    super.key,
  });

  final DemandaDetail detail;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<DemandManagementSection> createState() =>
      _DemandManagementSectionState();
}

class _DemandManagementSectionState
    extends ConsumerState<DemandManagementSection> {
  late Future<_DemandManagementOptions> _optionsFuture;
  String? _busyGroupId;

  @override
  void initState() {
    super.initState();
    _optionsFuture = _loadOptions();
  }

  Future<_DemandManagementOptions> _loadOptions() async {
    final api = ref.read(ruralApiProvider);
    final collaboratorsFuture = api.listCollaborators();
    final groupsFuture = api.listGroups();
    return _DemandManagementOptions(
      collaborators: await collaboratorsFuture,
      groups: await groupsFuture,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AusterSectionCard(
      title: 'GESTÃO DA DEMANDA',
      icon: Icons.edit_note_rounded,
      child: FutureBuilder<_DemandManagementOptions>(
        future: _optionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            return AusterErrorState(
              message: userFacingErrorMessage(snapshot.error!),
              compact: true,
              onRetry: () async {
                final next = _loadOptions();
                setState(() => _optionsFuture = next);
                await next;
              },
            );
          }
          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(_DemandManagementOptions options) {
    final linkedGroups = widget.detail.demanda.grupoIds.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _edit(options.collaborators),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Editar resumo'),
            ),
            OutlinedButton.icon(
              onPressed: _deactivate,
              icon: const Icon(Icons.block_rounded),
              label: const Text('Desativar'),
            ),
          ],
        ),
        const Divider(height: 28),
        Text('Grupos vinculados',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (options.groups.isEmpty)
          const Text('Nenhum grupo disponível.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final group in options.groups)
                FilterChip(
                  label: Text(group.name),
                  selected: linkedGroups.contains(group.id),
                  onSelected: _busyGroupId == null
                      ? (selected) => _setGroup(group, selected)
                      : null,
                  avatar: _busyGroupId == group.id
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _edit(List<Collaborator> collaborators) async {
    final demand = widget.detail.demanda;
    final values = await showAusterRecordForm(
      context: context,
      title: 'Editar demanda',
      fields: [
        const RecordFieldSpec(
          key: 'tipo',
          label: 'Tipo',
          kind: RecordFieldKind.choice,
          required: true,
          options: [
            RecordFieldOption(value: 'SMART_N', label: 'Smart-N'),
            RecordFieldOption(value: 'SMART_BRAKE', label: 'Smart-Brake'),
            RecordFieldOption(value: 'SMART_SEEDING', label: 'Smart-Seeding'),
          ],
        ),
        RecordFieldSpec(
          key: 'representanteId',
          label: 'Representante',
          kind: RecordFieldKind.choice,
          options: collaborators
              .map(
                (person) => RecordFieldOption(
                  value: person.id,
                  label: person.name,
                ),
              )
              .toList(growable: false),
        ),
        const RecordFieldSpec(
          key: 'prazo',
          label: 'Prazo',
          kind: RecordFieldKind.date,
        ),
        const RecordFieldSpec(
          key: 'areaDeInteresse',
          label: 'Área de interesse',
          kind: RecordFieldKind.multiline,
        ),
        const RecordFieldSpec(
          key: 'retrabalho',
          label: 'Retrabalho',
          kind: RecordFieldKind.boolean,
        ),
      ],
      initialValues: {
        'tipo': demand.tipo,
        'representanteId': demand.representanteId,
        'prazo': demand.prazo,
        'areaDeInteresse': demand.areaDeInteresse,
        'retrabalho': demand.retrabalho,
      },
    );
    if (values == null) return;
    try {
      await ref.read(commercialApiProvider).updateDemand(
            demand.id,
            DemandaUpdateInput(
              tipo: values['tipo'] as String,
              representanteId: values['representanteId'] as String?,
              prazo: values['prazo'] as String?,
              areaDeInteresse: values['areaDeInteresse'] as String?,
              situacaoDados: demand.situacaoDados,
              situacaoMapeamento: demand.situacaoMapeamento,
              retrabalho: values['retrabalho'] as bool? ?? false,
            ),
          );
      await _reload('Demanda atualizada com sucesso.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _setGroup(FieldGroup group, bool associated) async {
    setState(() => _busyGroupId = group.id);
    try {
      await ref.read(commercialApiProvider).setDemandGroup(
            widget.detail.demanda.id,
            group.id,
            associated: associated,
          );
      await _reload(
        associated ? 'Grupo vinculado.' : 'Grupo desvinculado.',
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyGroupId = null);
    }
  }

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar demanda'),
        content: Text(
          'Deseja desativar ${widget.detail.demanda.codigoDemanda}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(commercialApiProvider)
          .deactivateDemand(widget.detail.demanda.id);
      ref.invalidate(dashboardDemandasProvider);
      if (!mounted) return;
      _showMessage('Demanda desativada.');
      context.go('/demandas');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _reload(String message) async {
    ref.invalidate(demandaDetailProvider(widget.detail.demanda.id));
    ref.invalidate(dashboardDemandasProvider);
    await widget.onChanged();
    if (mounted) _showMessage(message);
  }

  void _showError(Object error) {
    if (mounted) _showMessage(userFacingErrorMessage(error));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DemandManagementOptions {
  const _DemandManagementOptions({
    required this.collaborators,
    required this.groups,
  });

  final List<Collaborator> collaborators;
  final List<FieldGroup> groups;
}
