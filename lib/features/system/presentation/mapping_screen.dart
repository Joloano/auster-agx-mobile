import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/agronomic_models.dart';
import '../../../data/models/commercial_models.dart';
import '../../../data/models/demanda_models.dart';
import '../../../data/models/rural_models.dart';
import '../../../data/models/system_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_record_form.dart';
import '../../agronomic/providers/agronomic_providers.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../commercial/providers/commercial_providers.dart';
import '../../modules/domain/module_access.dart';
import '../../rural/providers/rural_providers.dart';
import '../providers/system_providers.dart';

class MappingScreen extends ConsumerStatefulWidget {
  const MappingScreen({super.key, this.initialRemoteSensingId});

  final String? initialRemoteSensingId;

  @override
  ConsumerState<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends ConsumerState<MappingScreen> {
  static const _pageSize = 20;

  late Future<_MappingData> _future;
  String? _source;
  bool _pendingOnly = false;
  int _page = 0;
  bool _openedInitialItem = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MappingData> _load() async {
    final system = ref.read(systemApiProvider);
    final commercial = ref.read(commercialApiProvider);
    var items = await system.listRemoteSensing(
      source: _pendingOnly ? null : _source,
      pendingOnly: _pendingOnly,
    );
    if (_pendingOnly && _source != null) {
      items = items.where((item) => item.source == _source).toList();
    }

    List<Demanda> demands = const [];
    try {
      demands = (await commercial.listDemands(pageSize: 200)).items;
    } catch (_) {
      // O vínculo é contexto complementar; a listagem principal segue disponível.
    }
    return _MappingData(items: items, demands: demands);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).valueOrNull?.perfil ?? '';
    final canManage = canManageMappingData(profile);
    final canOperate = canOperateMapping(profile);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
            children: [
              AusterPageHeader(
                icon: Icons.satellite_alt_rounded,
                title: 'Mapeamentos',
                subtitle: 'Sensoriamento remoto, voos e imagens processadas',
                trailing: canManage
                    ? IconButton.filled(
                        tooltip: 'Adicionar mapeamento',
                        onPressed: _create,
                        icon: const Icon(Icons.add_rounded),
                      )
                    : null,
              ),
              const SizedBox(height: 18),
              _filters(),
              const SizedBox(height: 14),
              FutureBuilder<_MappingData>(
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
                  final data = snapshot.data!;
                  _openInitialItem(data);
                  return _content(data, canManage, canOperate);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              tooltip: 'Adicionar mapeamento',
              onPressed: _create,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _filters() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AusterColors.neutral200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fonte', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _source == null,
                  onSelected: (_) => _setFilters(source: null),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.flight_rounded, size: 18),
                  label: const Text('Drone'),
                  selected: _source == 'DRONE',
                  onSelected: (_) => _setFilters(source: 'DRONE'),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.satellite_alt_rounded, size: 18),
                  label: const Text('Satélite'),
                  selected: _source == 'SATELITE',
                  onSelected: (_) => _setFilters(source: 'SATELITE'),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Somente pendentes'),
              subtitle: const Text('Aguardando voo ou imagem processada'),
              value: _pendingOnly,
              onChanged: (value) {
                setState(() {
                  _pendingOnly = value;
                  _page = 0;
                  _future = _load();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setFilters({required String? source}) {
    setState(() {
      _source = source;
      _page = 0;
      _future = _load();
    });
  }

  Widget _content(_MappingData data, bool canManage, bool canOperate) {
    if (data.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Nenhum mapeamento encontrado.')),
      );
    }

    final totalPages = (data.items.length / _pageSize).ceil();
    final safePage = _page.clamp(0, totalPages - 1);
    final start = safePage * _pageSize;
    final pageItems = data.items.skip(start).take(_pageSize).toList();

    return Column(
      children: [
        for (var index = 0; index < pageItems.length; index++) ...[
          _mappingCard(pageItems[index], data, canManage, canOperate),
          if (index < pageItems.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${data.items.length} mapeamentos · página ${safePage + 1} de $totalPages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: 'Página anterior',
              onPressed: safePage > 0 ? () => _changePage(-1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Próxima página',
              onPressed:
                  safePage + 1 < totalPages ? () => _changePage(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mappingCard(
    RemoteSensing item,
    _MappingData data,
    bool canManage,
    bool canOperate,
  ) {
    final linkedDemands = data.demands
        .where((demand) => demand.sensoriamentoIds.contains(item.id))
        .toList();
    final pending = item.status == 'MAPEAMENTO_PENDENTE';
    final subtitle = [
      _sourceLabel(item.source),
      item.source == 'DRONE' ? item.pilotName : _satelliteLabel(item.satellite),
      item.imageDate == null ? 'Data a definir' : _date(item.imageDate!),
      if (linkedDemands.isNotEmpty)
        linkedDemands.map((demand) => demand.codigoDemanda).join(', '),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AusterColors.neutral200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDetails(item, linkedDemands),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: item.source == 'DRONE'
                    ? AusterColors.primary100
                    : AusterColors.secondary100,
                foregroundColor: item.source == 'DRONE'
                    ? AusterColors.primary700
                    : AusterColors.secondary900,
                child: Icon(
                  item.source == 'DRONE'
                      ? Icons.flight_rounded
                      : Icons.satellite_alt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.mappingCode,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(subtitle),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: Icon(
                            pending
                                ? Icons.pending_actions_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 16,
                          ),
                          label: Text(pending ? 'Pendente' : 'Concluído'),
                          backgroundColor: pending
                              ? AusterColors.warningBackground
                              : AusterColors.successBackground,
                        ),
                        if (item.quality != null)
                          Chip(label: Text(_qualityLabel(item.quality!))),
                        if (item.mappingNumber != null)
                          Chip(label: Text('Mapa ${item.mappingNumber}')),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_MappingAction>(
                tooltip: 'Ações do mapeamento',
                onSelected: (action) => _handleAction(action, item),
                itemBuilder: (context) => [
                  if (canOperate && pending && item.source == 'DRONE')
                    const PopupMenuItem(
                      value: _MappingAction.startFlight,
                      child: _MenuAction(
                        icon: Icons.flight_takeoff_rounded,
                        label: 'Iniciar voo',
                      ),
                    ),
                  if (canOperate && pending)
                    const PopupMenuItem(
                      value: _MappingAction.complete,
                      child: _MenuAction(
                        icon: Icons.task_alt_rounded,
                        label: 'Concluir',
                      ),
                    ),
                  if (item.mappingImagePath != null)
                    const PopupMenuItem(
                      value: _MappingAction.download,
                      child: _MenuAction(
                        icon: Icons.download_rounded,
                        label: 'Baixar imagem',
                      ),
                    ),
                  if (canManage)
                    const PopupMenuItem(
                      value: _MappingAction.edit,
                      child: _MenuAction(
                        icon: Icons.edit_rounded,
                        label: 'Editar',
                      ),
                    ),
                  if (canManage)
                    const PopupMenuItem(
                      value: _MappingAction.deactivate,
                      child: _MenuAction(
                        icon: Icons.block_rounded,
                        label: 'Desativar',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changePage(int delta) {
    setState(() => _page += delta);
  }

  void _openInitialItem(_MappingData data) {
    if (_openedInitialItem || widget.initialRemoteSensingId == null) return;
    _openedInitialItem = true;
    RemoteSensing? selected;
    for (final item in data.items) {
      if (item.id == widget.initialRemoteSensingId) selected = item;
    }
    if (selected == null) return;
    final linked = data.demands
        .where((demand) => demand.sensoriamentoIds.contains(selected!.id))
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showDetails(selected!, linked);
    });
  }

  Future<_MappingFormOptions> _loadFormOptions() async {
    final demandsRequest =
        ref.read(commercialApiProvider).listDemands(pageSize: 200);
    final collaboratorsRequest = ref.read(ruralApiProvider).listCollaborators();
    final stagesRequest =
        ref.read(agronomicApiProvider).listPhenologicalStages();
    final mappingsRequest = ref.read(systemApiProvider).listRemoteSensing();

    final demands = (await demandsRequest).items;
    final collaborators = await collaboratorsRequest;
    final stages = (await stagesRequest).items;
    final mappings = await mappingsRequest;
    return _MappingFormOptions(
      demands: demands,
      collaborators: collaborators,
      stages: stages,
      mappings: mappings,
    );
  }

  Future<void> _create() async {
    try {
      final options = await _loadFormOptions();
      if (!mounted) return;
      final values = await showAusterRecordForm(
        context: context,
        title: 'Adicionar mapeamento',
        fields: _mappingFields(options, includeOrigin: true),
      );
      if (values == null) return;
      final validation = _validateMappingValues(values, includeOrigin: true);
      if (validation != null) {
        _showMessage(validation);
        return;
      }
      await ref.read(commercialApiProvider).createRemoteSensing(
            values['demandaId'] as String,
            RemoteSensingCreateInput(
              source: values['fonte'] as String,
              pilotId: _forSource(values, 'DRONE', 'pilotoId'),
              satellite: _forSource(values, 'SATELITE', 'satelite'),
              originMappingId: values['mapeamentoOrigemId'] as String?,
              mappingNumber: values['numeroMapeamento'] as int?,
              quality: values['qualidade'] as String?,
              imageDate: values['dataImagem'] as String?,
              phenologicalStage: values['estadioFenologico'] as String?,
              notes: values['observacoes'] as String?,
            ),
          );
      if (!mounted) return;
      _showMessage('Mapeamento criado e vinculado à demanda.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _edit(RemoteSensing item) async {
    try {
      final options = await _loadFormOptions();
      if (!mounted) return;
      final values = await showAusterRecordForm(
        context: context,
        title: 'Editar ${item.mappingCode}',
        fields: _mappingFields(options, includeOrigin: false),
        initialValues: {
          'fonte': item.source,
          'pilotoId': item.pilotId,
          'satelite': item.satellite,
          'qualidade': item.quality,
          'dataImagem': item.imageDate,
          'estadioFenologico': item.phenologicalStage,
          'observacoes': item.notes,
        },
      );
      if (values == null) return;
      final validation = _validateMappingValues(values, includeOrigin: false);
      if (validation != null) {
        _showMessage(validation);
        return;
      }
      await ref.read(systemApiProvider).updateRemoteSensing(
            item.id,
            RemoteSensingUpdateInput(
              source: values['fonte'] as String,
              pilotId: _forSource(values, 'DRONE', 'pilotoId'),
              satellite: _forSource(values, 'SATELITE', 'satelite'),
              quality: values['qualidade'] as String?,
              imageDate: values['dataImagem'] as String?,
              phenologicalStage: values['estadioFenologico'] as String?,
              notes: values['observacoes'] as String?,
              mappingImagePath: item.mappingImagePath,
            ),
          );
      if (!mounted) return;
      _showMessage('Mapeamento atualizado.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  List<RecordFieldSpec> _mappingFields(
    _MappingFormOptions options, {
    required bool includeOrigin,
  }) {
    final stageNames = options.stages
        .where((stage) => stage.active && stage.name.isNotEmpty)
        .map((stage) => stage.name)
        .toSet()
        .toList()
      ..sort();
    final roots = options.mappings
        .where(
          (item) =>
              item.originMappingId == null &&
              item.status == 'MAPEAMENTO_CONCLUIDO',
        )
        .toList();
    return [
      if (includeOrigin)
        RecordFieldSpec(
          key: 'demandaId',
          label: 'Demanda',
          kind: RecordFieldKind.choice,
          required: true,
          options: options.demands
              .map(
                (item) => RecordFieldOption(
                  value: item.id,
                  label: '${item.codigoDemanda} · ${item.tipo}',
                ),
              )
              .toList(),
        ),
      const RecordFieldSpec(
        key: 'fonte',
        label: 'Fonte',
        kind: RecordFieldKind.choice,
        required: true,
        options: [
          RecordFieldOption(value: 'DRONE', label: 'Drone'),
          RecordFieldOption(value: 'SATELITE', label: 'Satélite'),
        ],
      ),
      RecordFieldSpec(
        key: 'pilotoId',
        label: 'Piloto (para drone)',
        kind: RecordFieldKind.choice,
        options: options.collaborators
            .where((item) => item.active)
            .map(
              (item) => RecordFieldOption(value: item.id, label: item.name),
            )
            .toList(),
      ),
      const RecordFieldSpec(
        key: 'satelite',
        label: 'Satélite (para imagem orbital)',
        kind: RecordFieldKind.choice,
        options: [
          RecordFieldOption(value: 'LANDSAT_9', label: 'Landsat 9'),
          RecordFieldOption(value: 'SENTINEL_2', label: 'Sentinel 2'),
        ],
      ),
      const RecordFieldSpec(
        key: 'qualidade',
        label: 'Qualidade',
        kind: RecordFieldKind.choice,
        options: [
          RecordFieldOption(value: 'RUIM', label: 'Ruim'),
          RecordFieldOption(value: 'VIAVEL', label: 'Viável'),
          RecordFieldOption(value: 'BOA', label: 'Boa'),
        ],
      ),
      const RecordFieldSpec(
        key: 'dataImagem',
        label: 'Data da imagem',
        kind: RecordFieldKind.date,
        helperText: 'Opcional para mapeamentos agendados.',
      ),
      RecordFieldSpec(
        key: 'estadioFenologico',
        label: 'Estádio fenológico',
        kind: RecordFieldKind.choice,
        options: stageNames
            .map((name) => RecordFieldOption(value: name, label: name))
            .toList(),
      ),
      if (includeOrigin)
        RecordFieldSpec(
          key: 'mapeamentoOrigemId',
          label: 'Mapeamento original (remapeamento)',
          kind: RecordFieldKind.choice,
          options: roots
              .map(
                (item) => RecordFieldOption(
                  value: item.id,
                  label: item.mappingCode,
                ),
              )
              .toList(),
        ),
      if (includeOrigin)
        const RecordFieldSpec(
          key: 'numeroMapeamento',
          label: 'Número do remapeamento',
          kind: RecordFieldKind.integer,
        ),
      const RecordFieldSpec(
        key: 'observacoes',
        label: 'Observações',
        kind: RecordFieldKind.multiline,
      ),
    ];
  }

  String? _validateMappingValues(
    Map<String, dynamic> values, {
    required bool includeOrigin,
  }) {
    final source = values['fonte'];
    if (source == 'DRONE' && values['pilotoId'] == null) {
      return 'Selecione o piloto para um mapeamento por drone.';
    }
    if (source == 'SATELITE' && values['satelite'] == null) {
      return 'Selecione o satélite usado no mapeamento.';
    }
    if (includeOrigin) {
      final hasOrigin = values['mapeamentoOrigemId'] != null;
      final number = values['numeroMapeamento'] as int?;
      if (hasOrigin != (number != null)) {
        return 'Informe o mapa original e o número do remapeamento juntos.';
      }
      if (number != null && number < 2) {
        return 'O número do remapeamento deve ser maior que 1.';
      }
    }
    return null;
  }

  String? _forSource(
    Map<String, dynamic> values,
    String source,
    String key,
  ) {
    return values['fonte'] == source ? values[key] as String? : null;
  }

  Future<void> _startFlight(RemoteSensing item) async {
    final confirmed = await _confirm(
      title: 'Iniciar voo',
      message: 'Registrar o início do voo de ${item.mappingCode}?',
      confirmLabel: 'Iniciar',
    );
    if (!confirmed) return;
    try {
      await ref.read(systemApiProvider).startFlight(item.id);
      if (!mounted) return;
      _showMessage('Voo iniciado. As demandas vinculadas foram atualizadas.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _complete(RemoteSensing item) async {
    try {
      String? fileKey = item.mappingImagePath;
      if (fileKey != null) {
        final useExisting = await _confirm(
          title: 'Concluir mapeamento',
          message:
              'Usar a imagem já anexada para concluir ${item.mappingCode}?',
          confirmLabel: 'Usar imagem',
          cancelLabel: 'Trocar arquivo',
        );
        if (!mounted) return;
        if (!useExisting) fileKey = await _pickAndUpload('mapeamento');
      } else {
        fileKey = await _pickAndUpload('mapeamento');
      }
      if (fileKey == null) return;
      await ref.read(systemApiProvider).updateMappingStatus(
            item.id,
            'MAPEAMENTO_CONCLUIDO',
            mappingImagePath: fileKey,
          );
      if (!mounted) return;
      _showMessage('Mapeamento concluído com a imagem processada.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<String?> _pickAndUpload(String type) async {
    final api = ref.read(systemApiProvider);
    try {
      final connected = await api.getGoogleDriveStatus();
      if (!connected && mounted) {
        final connect = await _confirm(
          title: 'Google Drive desconectado',
          message: 'Conecte o Google Drive para enviar a imagem processada.',
          confirmLabel: 'Conectar',
        );
        if (connect) {
          final launched =
              await ref.read(googleDriveAuthorizationProvider).launch();
          if (!launched && mounted) {
            _showMessage('Não foi possível abrir a autorização do Google.');
          }
        }
        return null;
      }
    } catch (_) {
      // Se o status não estiver disponível, o upload ainda fornece o erro real.
    }

    final allowed = (await api.getAllowedFileTypes())[type] ?? const [];
    final result = await FilePicker.pickFiles(
      type: allowed.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: allowed.isEmpty ? null : allowed,
      withData: true,
      allowMultiple: false,
    );
    if (result == null) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('O Android não forneceu o conteúdo do arquivo.');
    }
    final uploaded = await api.uploadFile(
      type: type,
      fileName: file.name,
      bytes: bytes,
    );
    return uploaded.key;
  }

  Future<void> _download(RemoteSensing item) async {
    final key = item.mappingImagePath;
    if (key == null) return;
    try {
      final file = await ref.read(systemApiProvider).downloadFile(key);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Salvar imagem de mapeamento',
        fileName: file.fileName,
        bytes: file.bytes,
      );
      if (!mounted) return;
      _showMessage(
        path == null ? 'Download concluído.' : 'Arquivo salvo em $path',
      );
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _deactivate(RemoteSensing item) async {
    final confirmed = await _confirm(
      title: 'Desativar mapeamento',
      message: 'Desativar ${item.mappingCode}? Esta ação preserva o histórico.',
      confirmLabel: 'Desativar',
    );
    if (!confirmed) return;
    try {
      await ref.read(systemApiProvider).deactivateRemoteSensing(item.id);
      if (!mounted) return;
      _showMessage('Mapeamento desativado.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  void _handleAction(_MappingAction action, RemoteSensing item) {
    switch (action) {
      case _MappingAction.startFlight:
        _startFlight(item);
      case _MappingAction.complete:
        _complete(item);
      case _MappingAction.download:
        _download(item);
      case _MappingAction.edit:
        _edit(item);
      case _MappingAction.deactivate:
        _deactivate(item);
    }
  }

  Future<void> _showDetails(
    RemoteSensing item,
    List<Demanda> linkedDemands,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.mappingCode,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _DetailRow(label: 'Fonte', value: _sourceLabel(item.source)),
              _DetailRow(
                label: item.source == 'DRONE' ? 'Piloto' : 'Satélite',
                value: item.source == 'DRONE'
                    ? item.pilotName ?? '-'
                    : _satelliteLabel(item.satellite) ?? '-',
              ),
              _DetailRow(
                label: 'Status',
                value: item.status == 'MAPEAMENTO_CONCLUIDO'
                    ? 'Concluído'
                    : 'Pendente',
              ),
              _DetailRow(
                label: 'Data da imagem',
                value: item.imageDate == null ? '-' : _date(item.imageDate!),
              ),
              _DetailRow(
                label: 'Qualidade',
                value:
                    item.quality == null ? '-' : _qualityLabel(item.quality!),
              ),
              _DetailRow(
                label: 'Estádio fenológico',
                value: item.phenologicalStage ?? '-',
              ),
              _DetailRow(
                label: 'Remapeamento',
                value: item.mappingNumber?.toString() ?? 'Original',
              ),
              _DetailRow(
                label: 'Demandas',
                value: linkedDemands.isEmpty
                    ? '-'
                    : linkedDemands
                        .map((demand) => demand.codigoDemanda)
                        .join(', '),
              ),
              _DetailRow(label: 'Observações', value: item.notes ?? '-'),
              if (item.mappingImagePath != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _download(item);
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Baixar imagem processada'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancelar',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MappingData {
  const _MappingData({required this.items, required this.demands});

  final List<RemoteSensing> items;
  final List<Demanda> demands;
}

class _MappingFormOptions {
  const _MappingFormOptions({
    required this.demands,
    required this.collaborators,
    required this.stages,
    required this.mappings,
  });

  final List<Demanda> demands;
  final List<Collaborator> collaborators;
  final List<PhenologicalStage> stages;
  final List<RemoteSensing> mappings;
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

enum _MappingAction { startFlight, complete, download, edit, deactivate }

String _sourceLabel(String source) {
  return source == 'SATELITE' ? 'Satélite' : 'Drone';
}

String? _satelliteLabel(String? satellite) {
  return switch (satellite) {
    'LANDSAT_9' => 'Landsat 9',
    'SENTINEL_2' => 'Sentinel 2',
    null => null,
    _ => satellite.replaceAll('_', ' '),
  };
}

String _qualityLabel(String quality) {
  return switch (quality) {
    'RUIM' => 'Ruim',
    'VIAVEL' => 'Viável',
    'BOA' => 'Boa',
    _ => quality,
  };
}

String _date(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
