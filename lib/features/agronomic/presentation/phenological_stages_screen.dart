import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/agronomic_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_record_form.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../modules/domain/module_access.dart';
import '../providers/agronomic_providers.dart';

class PhenologicalStagesScreen extends ConsumerStatefulWidget {
  const PhenologicalStagesScreen({super.key});

  @override
  ConsumerState<PhenologicalStagesScreen> createState() =>
      _PhenologicalStagesScreenState();
}

class _PhenologicalStagesScreenState
    extends ConsumerState<PhenologicalStagesScreen> {
  late Future<_StagePageData> _future;
  int? _cultureId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StagePageData> _load() async {
    final api = ref.read(agronomicApiProvider);
    final culturesFuture = api.listCultures();
    final stagesFuture = api.listPhenologicalStages(cultureId: _cultureId);
    return _StagePageData(
      cultures: await culturesFuture,
      stages: (await stagesFuture).items,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).valueOrNull?.perfil ?? '';
    final canManage = canManageAgronomicData(profile);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            AusterPageHeader(
              icon: Icons.timeline_rounded,
              title: 'Estádios fenológicos',
              subtitle: 'Catálogo agronômico por cultura',
              leading: IconButton(
                tooltip: 'Voltar',
                onPressed: () => context.go('/modulos'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              trailing: canManage
                  ? IconButton.filled(
                      tooltip: 'Adicionar estádio',
                      onPressed: _create,
                      icon: const Icon(Icons.add_rounded),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            FutureBuilder<_StagePageData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return AusterErrorState(
                    message: userFacingErrorMessage(snapshot.error!),
                    onRetry: _refresh,
                  );
                }
                return _buildContent(snapshot.data!, canManage);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(_StagePageData data, bool canManage) {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          initialValue: _cultureId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Cultura',
            helperText: 'Sem seleção, a API retorna os estádios genéricos.',
            prefixIcon: Icon(Icons.filter_alt_rounded),
          ),
          items: data.cultures
              .map(
                (culture) => DropdownMenuItem(
                  value: culture.id,
                  child: Text(culture.name),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            setState(() {
              _cultureId = value;
              _future = _load();
            });
          },
        ),
        if (_cultureId != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _cultureId = null;
                  _future = _load();
                });
              },
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Mostrar genéricos'),
            ),
          ),
        const SizedBox(height: 12),
        if (data.stages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Text('Nenhum estádio encontrado para este filtro.'),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: AusterColors.neutral200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (var index = 0; index < data.stages.length; index++) ...[
                  ListTile(
                    minTileHeight: 76,
                    leading: CircleAvatar(
                      child: Text(
                        data.stages[index].order?.toString() ?? '-',
                      ),
                    ),
                    title: Text(data.stages[index].name),
                    subtitle: Text(
                      [
                        data.stages[index].cultureName ?? 'Genérico',
                        if (data.stages[index].efa != null)
                          'EFA ${data.stages[index].efa}',
                      ].join(' · '),
                    ),
                    trailing: canManage
                        ? PopupMenuButton<String>(
                            tooltip: 'Ações do estádio',
                            onSelected: (action) {
                              if (action == 'edit') {
                                _edit(data.stages[index]);
                              }
                              if (action == 'deactivate') {
                                _deactivate(data.stages[index]);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar nome'),
                              ),
                              if (data.stages[index].active)
                                const PopupMenuItem(
                                  value: 'deactivate',
                                  child: Text('Desativar'),
                                ),
                            ],
                          )
                        : null,
                  ),
                  if (index < data.stages.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _create() async {
    try {
      final cultures = await ref.read(agronomicApiProvider).listCultures();
      if (!mounted) return;
      final values = await showAusterRecordForm(
        context: context,
        title: 'Novo estádio fenológico',
        fields: [
          const RecordFieldSpec(
            key: 'nome',
            label: 'Nome',
            required: true,
          ),
          RecordFieldSpec(
            key: 'culturaId',
            label: 'Cultura',
            kind: RecordFieldKind.choice,
            helperText: 'Opcional para estádios genéricos.',
            options: cultures
                .map(
                  (culture) => RecordFieldOption(
                    value: culture.id.toString(),
                    label: culture.name,
                  ),
                )
                .toList(growable: false),
          ),
          const RecordFieldSpec(
            key: 'ordem',
            label: 'Ordem',
            kind: RecordFieldKind.integer,
          ),
          const RecordFieldSpec(
            key: 'efa',
            label: 'EFA',
            kind: RecordFieldKind.decimal,
          ),
        ],
      );
      if (values == null) return;
      await ref.read(agronomicApiProvider).createPhenologicalStage(
            PhenologicalStageInput(
              name: values['nome'] as String,
              cultureId: int.tryParse(values['culturaId'] as String? ?? ''),
              order: values['ordem'] as int?,
              efa: values['efa'] as double?,
            ),
          );
      if (!mounted) return;
      _showMessage('Estádio criado com sucesso.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _edit(PhenologicalStage stage) async {
    final values = await showAusterRecordForm(
      context: context,
      title: 'Editar estádio fenológico',
      fields: const [
        RecordFieldSpec(key: 'nome', label: 'Nome', required: true),
      ],
      initialValues: {'nome': stage.name},
    );
    if (values == null) return;
    try {
      await ref
          .read(agronomicApiProvider)
          .updatePhenologicalStage(stage.id, values['nome'] as String);
      if (!mounted) return;
      _showMessage('Estádio atualizado.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _deactivate(PhenologicalStage stage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar estádio'),
        content: Text('Deseja desativar ${stage.name}?'),
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
          .read(agronomicApiProvider)
          .deactivatePhenologicalStage(stage.id);
      if (!mounted) return;
      _showMessage('Estádio desativado.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StagePageData {
  const _StagePageData({required this.cultures, required this.stages});

  final List<Culture> cultures;
  final List<PhenologicalStage> stages;
}
