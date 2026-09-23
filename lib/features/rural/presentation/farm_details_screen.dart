import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/rural_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_key_value_list.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_record_form.dart';
import '../../../widgets/auster_section_card.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../modules/domain/module_access.dart';
import '../../modules/providers/operations_providers.dart';
import '../providers/rural_providers.dart';
import 'farms_screen.dart';

class FarmDetailsScreen extends ConsumerStatefulWidget {
  const FarmDetailsScreen({required this.farmId, super.key});

  final String farmId;

  @override
  ConsumerState<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends ConsumerState<FarmDetailsScreen> {
  late Future<_FarmDetailsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FarmDetailsData> _load() async {
    final api = ref.read(ruralApiProvider);
    final operations = ref.read(operationsApiProvider);
    final farmFuture = api.getFarm(widget.farmId);
    final fieldsFuture = api.listFields(farmId: widget.farmId);
    final linksFuture = api.listActiveLinks();
    final collaboratorsFuture = api.listCollaborators(farmId: widget.farmId);
    final equipmentFuture = api.listEquipment();
    final groupsFuture = api.listGroups();
    final culturesFuture = operations.getList('/culturas');

    final farm = await farmFuture;
    final fields = (await fieldsFuture).items;
    final fieldIds = fields.map((field) => field.id).toSet();
    return _FarmDetailsData(
      farm: farm,
      fields: fields,
      links: (await linksFuture)
          .where((link) => link.farmId == widget.farmId)
          .toList(growable: false),
      collaborators: await collaboratorsFuture,
      equipment: await equipmentFuture,
      groups: (await groupsFuture)
          .where(
            (group) => group.fields.any(
              (field) => fieldIds.contains(field['id']?.toString()),
            ),
          )
          .toList(growable: false),
      cultures: await culturesFuture,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FarmDetailsData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: AusterErrorState(
              message: userFacingErrorMessage(snapshot.error!),
              onRetry: _refresh,
            ),
          );
        }
        return _buildContent(snapshot.data!);
      },
    );
  }

  Widget _buildContent(_FarmDetailsData data) {
    final profile = ref.watch(authControllerProvider).valueOrNull?.perfil ?? '';
    final canManage = canManageRuralData(profile);
    final canCreateField = canCreateFarmOrField(profile);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            AusterPageHeader(
              icon: Icons.agriculture_rounded,
              title: data.farm.name,
              subtitle:
                  data.farm.ownerClientName ?? 'Sem proprietário informado',
              leading: IconButton(
                tooltip: 'Voltar',
                onPressed: () => context.go('/modulos/fazendas'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações da fazenda',
                      onSelected: (action) {
                        if (action == 'edit') _editFarm(data);
                        if (action == 'deactivate') _deactivateFarm(data.farm);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: 'edit', child: Text('Editar fazenda')),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Desativar fazenda'),
                        ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            AusterSectionCard(
              title: 'Propriedade',
              icon: Icons.info_rounded,
              child: AusterKeyValueList(
                values: {
                  'Responsável': data.farm.manager,
                  'Área total': data.farm.areaHa == null
                      ? null
                      : '${data.farm.areaHa} ha',
                  'Área cultivável': data.farm.cultivableArea == null
                      ? null
                      : '${data.farm.cultivableArea} ha',
                  'Telefone': data.farm.phone,
                  'Localização': data.farm.location,
                  'Cidade/UF': [data.farm.city, data.farm.state]
                      .whereType<String>()
                      .join('/'),
                  'Coordenadas': data.farm.latitude == null
                      ? null
                      : '${data.farm.latitude}, ${data.farm.longitude}',
                  'Croqui': data.farm.sketchPath,
                },
              ),
            ),
            const SizedBox(height: 12),
            _fieldsSection(data, canCreateField, canManage),
            const SizedBox(height: 12),
            _teamSection(data, canManage),
            const SizedBox(height: 12),
            _groupsSection(data, canManage),
            const SizedBox(height: 12),
            _associationsSection(data, canManage),
            const SizedBox(height: 12),
            _linksSection(data),
          ],
        ),
      ),
    );
  }

  Widget _fieldsSection(
    _FarmDetailsData data,
    bool canCreate,
    bool canManage,
  ) {
    return AusterSectionCard(
      title: 'Talhões',
      icon: Icons.grid_view_rounded,
      child: Column(
        children: [
          if (data.fields.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Nenhum talhão cadastrado.'),
            ),
          for (final field in data.fields)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(field.name),
              subtitle: Text(
                [
                  field.lptCode,
                  field.areaHa == null ? null : '${field.areaHa} ha',
                  field.irrigated ? 'Irrigado' : 'Sequeiro',
                ].whereType<String>().join(' · '),
              ),
              onTap: () => context.go('/modulos/talhoes/${field.id}'),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações do talhão',
                      onSelected: (action) {
                        if (action == 'edit') _editField(field);
                        if (action == 'deactivate') _deactivateField(field);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Desativar'),
                        ),
                      ],
                    )
                  : const Icon(Icons.chevron_right_rounded),
            ),
          if (canCreate) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addField,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar talhão'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamSection(_FarmDetailsData data, bool canManage) {
    return AusterSectionCard(
      title: 'Equipe',
      icon: Icons.groups_rounded,
      child: Column(
        children: [
          if (data.collaborators.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Nenhum colaborador vinculado.'),
            ),
          for (final collaborator in data.collaborators)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
              title: Text(collaborator.name),
              subtitle: Text(
                [collaborator.role, collaborator.phone, collaborator.email]
                    .whereType<String>()
                    .join(' · '),
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações do colaborador',
                      onSelected: (action) {
                        if (action == 'edit') _editCollaborator(collaborator);
                        if (action == 'unlink') {
                          _unlinkCollaborator(collaborator);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'unlink',
                          child: Text('Remover da fazenda'),
                        ),
                      ],
                    )
                  : null,
            ),
          if (canManage) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addCollaborator(data),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Adicionar colaborador'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _groupsSection(_FarmDetailsData data, bool canManage) {
    return AusterSectionCard(
      title: 'Grupos de talhões',
      icon: Icons.account_tree_rounded,
      child: Column(
        children: [
          if (data.groups.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Nenhum grupo vinculado aos talhões desta fazenda.'),
            ),
          for (final group in data.groups)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(group.name),
              subtitle: Text(
                group.fields
                    .map((field) => field['nome']?.toString())
                    .whereType<String>()
                    .join(', '),
              ),
              trailing: canManage
                  ? IconButton(
                      tooltip: 'Gerenciar talhões',
                      onPressed: () => _manageGroupFields(group, data.fields),
                      icon: const Icon(Icons.tune_rounded),
                    )
                  : null,
            ),
          if (canManage) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _createGroup(data.fields),
                icon: const Icon(Icons.create_new_folder_rounded),
                label: const Text('Criar grupo'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _associationsSection(_FarmDetailsData data, bool canManage) {
    return AusterSectionCard(
      title: 'Culturas e equipamentos',
      icon: Icons.eco_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Culturas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.farm.cultures.isEmpty
                ? [const Text('Nenhuma cultura associada.')]
                : data.farm.cultures
                    .map(
                      (culture) => Chip(
                        label: Text(culture['nome']?.toString() ?? 'Cultura'),
                      ),
                    )
                    .toList(growable: false),
          ),
          if (canManage)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _manageCultures(data),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Gerenciar culturas'),
              ),
            ),
          const Divider(height: 24),
          Text('Equipamentos', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.farm.equipment.isEmpty
                ? [const Text('Nenhum equipamento associado.')]
                : data.farm.equipment
                    .map(
                      (equipment) => Chip(
                        label: Text(
                          equipment['nome']?.toString() ?? 'Equipamento',
                        ),
                      ),
                    )
                    .toList(growable: false),
          ),
          if (canManage)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _manageEquipment(data),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Gerenciar equipamentos'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _linksSection(_FarmDetailsData data) {
    return AusterSectionCard(
      title: 'Clientes vinculados',
      icon: Icons.link_rounded,
      child: data.links.isEmpty
          ? const Text('Nenhum vínculo ativo.')
          : Column(
              children: [
                for (final link in data.links)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(link.clientName),
                    subtitle: Text('Desde ${link.startDate}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        context.go('/modulos/clientes/${link.clientId}'),
                  ),
              ],
            ),
    );
  }

  Future<void> _editFarm(_FarmDetailsData data) async {
    final clients =
        (await ref.read(ruralApiProvider).listClients(pageSize: 200)).items;
    if (!mounted) return;
    final values = await showAusterRecordForm(
      context: context,
      title: 'Editar fazenda',
      fields: farmFormFields(clients),
      initialValues: farmFormValues(data.farm),
    );
    if (values == null) return;
    await _runMutation(
      () => ref
          .read(ruralApiProvider)
          .updateFarm(data.farm.id, farmInputFromForm(values)),
      'Fazenda atualizada com sucesso.',
    );
  }

  Future<void> _deactivateFarm(Farm farm) async {
    if (!await _confirm(
        'Desativar fazenda', 'Deseja desativar ${farm.name}?')) {
      return;
    }
    try {
      await ref.read(ruralApiProvider).deactivateFarm(farm.id);
      if (!mounted) return;
      _showMessage('Fazenda desativada.');
      context.go('/modulos/fazendas');
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _addField() async {
    final values = await showAusterRecordForm(
      context: context,
      title: 'Adicionar talhão',
      fields: fieldFormFields(),
      initialValues: const {'irrigacao': false},
    );
    if (values == null) return;
    final input = fieldInputFromForm(values, farmId: widget.farmId);
    await _runMutation(
      () => ref.read(ruralApiProvider).createField(input),
      'Talhão criado com sucesso.',
    );
  }

  Future<void> _editField(FieldPlot field) async {
    final values = await showAusterRecordForm(
      context: context,
      title: 'Editar talhão',
      fields: fieldFormFields(),
      initialValues: fieldFormValues(field),
    );
    if (values == null) return;
    await _runMutation(
      () => ref
          .read(ruralApiProvider)
          .updateField(field.id, fieldInputFromForm(values)),
      'Talhão atualizado com sucesso.',
    );
  }

  Future<void> _deactivateField(FieldPlot field) async {
    if (!await _confirm(
        'Desativar talhão', 'Deseja desativar ${field.name}?')) {
      return;
    }
    await _runMutation(
      () => ref.read(ruralApiProvider).deactivateField(field.id),
      'Talhão desativado.',
    );
  }

  Future<void> _addCollaborator(_FarmDetailsData data) async {
    final clients =
        (await ref.read(ruralApiProvider).listClients(pageSize: 200)).items;
    if (!mounted) return;
    final values = await showAusterRecordForm(
      context: context,
      title: 'Adicionar colaborador',
      fields: collaboratorFormFields(clients),
    );
    if (values == null) return;
    try {
      final collaborator = await ref
          .read(ruralApiProvider)
          .createCollaborator(collaboratorInputFromForm(values));
      await ref.read(ruralApiProvider).setCollaboratorFarm(
            collaborator.id,
            data.farm.id,
            associated: true,
          );
      if (!mounted) return;
      _showMessage('Colaborador adicionado com sucesso.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _editCollaborator(Collaborator collaborator) async {
    final clients =
        (await ref.read(ruralApiProvider).listClients(pageSize: 200)).items;
    if (!mounted) return;
    final values = await showAusterRecordForm(
      context: context,
      title: 'Editar colaborador',
      fields: collaboratorFormFields(clients),
      initialValues: collaboratorFormValues(collaborator),
    );
    if (values == null) return;
    await _runMutation(
      () => ref.read(ruralApiProvider).updateCollaborator(
            collaborator.id,
            collaboratorInputFromForm(values),
          ),
      'Colaborador atualizado com sucesso.',
    );
  }

  Future<void> _unlinkCollaborator(Collaborator collaborator) async {
    if (!await _confirm(
      'Remover colaborador',
      'Deseja remover ${collaborator.name} desta fazenda?',
    )) {
      return;
    }
    await _runMutation(
      () => ref.read(ruralApiProvider).setCollaboratorFarm(
            collaborator.id,
            widget.farmId,
            associated: false,
          ),
      'Colaborador removido da fazenda.',
    );
  }

  Future<void> _createGroup(List<FieldPlot> fields) async {
    final values = await showAusterRecordForm(
      context: context,
      title: 'Criar grupo',
      fields: [
        const RecordFieldSpec(key: 'nome', label: 'Nome', required: true),
        if (fields.isNotEmpty)
          RecordFieldSpec(
            key: 'talhaoId',
            label: 'Talhão inicial',
            kind: RecordFieldKind.choice,
            options: fields
                .map(
                  (field) =>
                      RecordFieldOption(value: field.id, label: field.name),
                )
                .toList(growable: false),
          ),
      ],
    );
    if (values == null) return;
    try {
      final group = await ref
          .read(ruralApiProvider)
          .createGroup(values['nome'] as String);
      final fieldId = values['talhaoId'] as String?;
      if (fieldId != null) {
        await ref
            .read(ruralApiProvider)
            .setGroupField(group.id, fieldId, associated: true);
      }
      if (!mounted) return;
      _showMessage('Grupo criado com sucesso.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _manageGroupFields(
    FieldGroup group,
    List<FieldPlot> fields,
  ) async {
    final selected = group.fields
        .map((field) => field['id']?.toString())
        .whereType<String>()
        .toSet();
    final next = await _showMultiSelect<FieldPlot>(
      title: group.name,
      items: fields,
      selectedIds: selected,
      idOf: (field) => field.id,
      labelOf: (field) => field.name,
    );
    if (next == null) return;
    await _syncAssociations(
      previous: selected,
      next: next,
      update: (id, associated) => ref
          .read(ruralApiProvider)
          .setGroupField(group.id, id, associated: associated),
      successMessage: 'Talhões do grupo atualizados.',
    );
  }

  Future<void> _manageCultures(_FarmDetailsData data) async {
    final selected = data.farm.cultures
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .toSet();
    final next = await _showMultiSelect<Map<String, dynamic>>(
      title: 'Culturas da fazenda',
      items: data.cultures,
      selectedIds: selected,
      idOf: (item) => item['id'].toString(),
      labelOf: (item) => item['nome']?.toString() ?? 'Cultura',
    );
    if (next == null) return;
    await _syncAssociations(
      previous: selected,
      next: next,
      update: (id, associated) => ref.read(ruralApiProvider).setFarmCulture(
            data.farm.id,
            int.parse(id),
            associated: associated,
          ),
      successMessage: 'Culturas atualizadas.',
    );
  }

  Future<void> _manageEquipment(_FarmDetailsData data) async {
    final selected = data.farm.equipment
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .toSet();
    final next = await _showMultiSelect<Equipment>(
      title: 'Equipamentos da fazenda',
      items: data.equipment,
      selectedIds: selected,
      idOf: (item) => item.id.toString(),
      labelOf: (item) => item.name,
    );
    if (next == null) return;
    await _syncAssociations(
      previous: selected,
      next: next,
      update: (id, associated) => ref.read(ruralApiProvider).setFarmEquipment(
            data.farm.id,
            int.parse(id),
            associated: associated,
          ),
      successMessage: 'Equipamentos atualizados.',
    );
  }

  Future<Set<String>?> _showMultiSelect<T>({
    required String title,
    required List<T> items,
    required Set<String> selectedIds,
    required String Function(T item) idOf,
    required String Function(T item) labelOf,
  }) {
    final draft = {...selectedIds};
    return showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 460,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in items)
                  CheckboxListTile(
                    value: draft.contains(idOf(item)),
                    title: Text(labelOf(item)),
                    onChanged: (selected) {
                      setDialogState(() {
                        if (selected ?? false) {
                          draft.add(idOf(item));
                        } else {
                          draft.remove(idOf(item));
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, draft),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncAssociations({
    required Set<String> previous,
    required Set<String> next,
    required Future<Object?> Function(String id, bool associated) update,
    required String successMessage,
  }) async {
    try {
      for (final id in next.difference(previous)) {
        await update(id, true);
      }
      for (final id in previous.difference(next)) {
        await update(id, false);
      }
      if (!mounted) return;
      _showMessage(successMessage);
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _runMutation(
    Future<Object?> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      _showMessage(successMessage);
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
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

class _FarmDetailsData {
  const _FarmDetailsData({
    required this.farm,
    required this.fields,
    required this.links,
    required this.collaborators,
    required this.equipment,
    required this.groups,
    required this.cultures,
  });

  final Farm farm;
  final List<FieldPlot> fields;
  final List<ClientFarmLink> links;
  final List<Collaborator> collaborators;
  final List<Equipment> equipment;
  final List<FieldGroup> groups;
  final List<Map<String, dynamic>> cultures;
}

List<RecordFieldSpec> fieldFormFields() => const [
      RecordFieldSpec(key: 'nome', label: 'Nome', required: true),
      RecordFieldSpec(key: 'codigoLpt', label: 'Código LPT'),
      RecordFieldSpec(
        key: 'numeroTalhao',
        label: 'Número do talhão',
        kind: RecordFieldKind.integer,
      ),
      RecordFieldSpec(
        key: 'areaHa',
        label: 'Área total (ha)',
        kind: RecordFieldKind.decimal,
      ),
      RecordFieldSpec(
        key: 'areaCultivavel',
        label: 'Área cultivável (ha)',
        kind: RecordFieldKind.decimal,
      ),
      RecordFieldSpec(
        key: 'latitude',
        label: 'Latitude',
        kind: RecordFieldKind.decimal,
      ),
      RecordFieldSpec(
        key: 'longitude',
        label: 'Longitude',
        kind: RecordFieldKind.decimal,
      ),
      RecordFieldSpec(
        key: 'contornoGeoJson',
        label: 'Contorno GeoJSON',
        kind: RecordFieldKind.multiline,
      ),
      RecordFieldSpec(
        key: 'irrigacao',
        label: 'Talhão irrigado',
        kind: RecordFieldKind.boolean,
      ),
    ];

FieldInput fieldInputFromForm(
  Map<String, dynamic> values, {
  String? farmId,
}) {
  return FieldInput(
    farmId: farmId,
    name: values['nome'] as String,
    lptCode: values['codigoLpt'] as String?,
    number: values['numeroTalhao'] as int?,
    areaHa: values['areaHa'] as double?,
    cultivableArea: values['areaCultivavel'] as double?,
    latitude: values['latitude'] as double?,
    longitude: values['longitude'] as double?,
    boundaryGeoJson: values['contornoGeoJson'] as String?,
    irrigated: (values['irrigacao'] as bool?) ?? false,
  );
}

Map<String, dynamic> fieldFormValues(FieldPlot field) => {
      'nome': field.name,
      'codigoLpt': field.lptCode,
      'numeroTalhao': field.number,
      'areaHa': field.areaHa,
      'areaCultivavel': field.cultivableArea,
      'latitude': field.latitude,
      'longitude': field.longitude,
      'contornoGeoJson': field.boundaryGeoJson,
      'irrigacao': field.irrigated,
    };

List<RecordFieldSpec> collaboratorFormFields(List<Client> clients) => [
      const RecordFieldSpec(key: 'nome', label: 'Nome', required: true),
      const RecordFieldSpec(key: 'cargo', label: 'Cargo'),
      const RecordFieldSpec(
        key: 'telefone',
        label: 'Telefone',
        kind: RecordFieldKind.phone,
      ),
      const RecordFieldSpec(
        key: 'email',
        label: 'E-mail',
        kind: RecordFieldKind.email,
      ),
      RecordFieldSpec(
        key: 'clienteId',
        label: 'Cliente relacionado',
        kind: RecordFieldKind.choice,
        options: clients
            .map(
              (client) => RecordFieldOption(
                value: client.id,
                label: client.tradeName,
              ),
            )
            .toList(growable: false),
      ),
    ];

CollaboratorInput collaboratorInputFromForm(Map<String, dynamic> values) {
  return CollaboratorInput(
    name: values['nome'] as String,
    role: values['cargo'] as String?,
    phone: values['telefone'] as String?,
    email: values['email'] as String?,
    clientId: values['clienteId'] as String?,
  );
}

Map<String, dynamic> collaboratorFormValues(Collaborator collaborator) => {
      'nome': collaborator.name,
      'cargo': collaborator.role,
      'telefone': collaborator.phone,
      'email': collaborator.email,
      'clienteId': collaborator.clientId,
    };
