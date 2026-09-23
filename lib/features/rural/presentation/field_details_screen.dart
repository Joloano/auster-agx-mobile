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
import '../providers/rural_providers.dart';
import 'farm_details_screen.dart';

class FieldDetailsScreen extends ConsumerStatefulWidget {
  const FieldDetailsScreen({required this.fieldId, super.key});

  final String fieldId;

  @override
  ConsumerState<FieldDetailsScreen> createState() => _FieldDetailsScreenState();
}

class _FieldDetailsScreenState extends ConsumerState<FieldDetailsScreen> {
  late Future<_FieldDetailsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FieldDetailsData> _load() async {
    final api = ref.read(ruralApiProvider);
    final fieldFuture = api.getField(widget.fieldId);
    final groupsFuture = api.listGroups();
    final field = await fieldFuture;
    final groups = (await groupsFuture)
        .where(
          (group) => group.fields.any(
            (item) => item['id']?.toString() == widget.fieldId,
          ),
        )
        .toList(growable: false);
    return _FieldDetailsData(field: field, groups: groups);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FieldDetailsData>(
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

  Widget _buildContent(_FieldDetailsData data) {
    final profile = ref.watch(authControllerProvider).valueOrNull?.perfil ?? '';
    final canManage = canManageRuralData(profile);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            AusterPageHeader(
              icon: Icons.grid_view_rounded,
              title: data.field.name,
              subtitle: data.field.lptCode ?? 'Talhão',
              leading: IconButton(
                tooltip: 'Voltar para a fazenda',
                onPressed: () => context.go(
                  '/modulos/fazendas/${data.field.farmId}',
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações do talhão',
                      onSelected: (action) {
                        if (action == 'edit') _edit(data.field);
                        if (action == 'deactivate') _deactivate(data.field);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: 'edit', child: Text('Editar talhão')),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Desativar talhão'),
                        ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            AusterSectionCard(
              title: 'Características',
              icon: Icons.straighten_rounded,
              child: AusterKeyValueList(
                values: {
                  'Número': data.field.number,
                  'Área total': data.field.areaHa == null
                      ? null
                      : '${data.field.areaHa} ha',
                  'Área cultivável': data.field.cultivableArea == null
                      ? null
                      : '${data.field.cultivableArea} ha',
                  'Manejo hídrico':
                      data.field.irrigated ? 'Irrigado' : 'Sequeiro',
                  'Latitude': data.field.latitude,
                  'Longitude': data.field.longitude,
                },
              ),
            ),
            const SizedBox(height: 12),
            AusterSectionCard(
              title: 'Grupos',
              icon: Icons.account_tree_rounded,
              child: data.groups.isEmpty
                  ? const Text('Este talhão não pertence a nenhum grupo.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.groups
                          .map((group) => Chip(label: Text(group.name)))
                          .toList(growable: false),
                    ),
            ),
            if (data.field.boundaryGeoJson != null) ...[
              const SizedBox(height: 12),
              AusterSectionCard(
                title: 'Contorno GeoJSON',
                icon: Icons.map_rounded,
                child: SelectableText(data.field.boundaryGeoJson!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _edit(FieldPlot field) async {
    final values = await showAusterRecordForm(
      context: context,
      title: 'Editar talhão',
      fields: fieldFormFields(),
      initialValues: fieldFormValues(field),
    );
    if (values == null) return;
    try {
      await ref
          .read(ruralApiProvider)
          .updateField(field.id, fieldInputFromForm(values));
      if (!mounted) return;
      _showMessage('Talhão atualizado com sucesso.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _deactivate(FieldPlot field) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar talhão'),
        content: Text('Deseja desativar ${field.name}?'),
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
      await ref.read(ruralApiProvider).deactivateField(field.id);
      if (!mounted) return;
      _showMessage('Talhão desativado.');
      context.go('/modulos/fazendas/${field.farmId}');
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FieldDetailsData {
  const _FieldDetailsData({required this.field, required this.groups});

  final FieldPlot field;
  final List<FieldGroup> groups;
}
