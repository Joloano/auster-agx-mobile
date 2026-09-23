import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/agronomic_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../modules/domain/module_access.dart';
import '../domain/agronomic_labels.dart';
import '../providers/agronomic_providers.dart';

class CulturesScreen extends ConsumerStatefulWidget {
  const CulturesScreen({super.key});

  @override
  ConsumerState<CulturesScreen> createState() => _CulturesScreenState();
}

class _CulturesScreenState extends ConsumerState<CulturesScreen> {
  late Future<List<Culture>> _future;
  String? _group;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Culture>> _load() {
    return ref.read(agronomicApiProvider).listCultures(group: _group);
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
              icon: Icons.nature_rounded,
              title: 'Culturas',
              subtitle: 'Cultivares e serviços agrícolas atendidos',
              leading: IconButton(
                tooltip: 'Voltar',
                onPressed: () => context.go('/modulos'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              trailing: canManage
                  ? IconButton.filled(
                      tooltip: 'Adicionar cultura',
                      onPressed: () => _save(),
                      icon: const Icon(Icons.add_rounded),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _group,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar por grupo',
                prefixIcon: Icon(Icons.filter_alt_rounded),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todos')),
                for (final value in cultureGroupValues)
                  DropdownMenuItem(
                    value: value,
                    child: Text(labelFor(cultureGroupLabels, value)),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _group = value == null || value.isEmpty ? null : value;
                  _future = _load();
                });
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Culture>>(
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
                return _buildList(snapshot.data!, canManage);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Culture> cultures, bool canManage) {
    if (cultures.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Nenhuma cultura encontrada.')),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AusterColors.neutral200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var index = 0; index < cultures.length; index++) ...[
            ListTile(
              minTileHeight: 84,
              leading: CircleAvatar(
                child: Icon(
                  cultures[index].active
                      ? Icons.eco_rounded
                      : Icons.block_rounded,
                ),
              ),
              title: Text(cultures[index].name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      labelFor(cultureGroupLabels, cultures[index].group),
                      labelFor(precocityLabels, cultures[index].precocity),
                    ].join(' · '),
                  ),
                  if (cultures[index].demandTypes.isNotEmpty)
                    Text(
                      cultures[index]
                          .demandTypes
                          .map((value) => labelFor(demandTypeLabels, value))
                          .join(', '),
                    ),
                ],
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações da cultura',
                      onSelected: (action) {
                        if (action == 'edit') _save(cultures[index]);
                        if (action == 'deactivate') {
                          _deactivate(cultures[index]);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        if (cultures[index].active)
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Desativar'),
                          ),
                      ],
                    )
                  : null,
            ),
            if (index < cultures.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Future<void> _save([Culture? culture]) async {
    final input = await showDialog<CultureInput>(
      context: context,
      builder: (context) => _CultureDialog(culture: culture),
    );
    if (input == null) return;
    try {
      final api = ref.read(agronomicApiProvider);
      if (culture == null) {
        await api.createCulture(input);
      } else {
        await api.updateCulture(culture.id, input);
      }
      if (!mounted) return;
      _showMessage(
        culture == null ? 'Cultura criada com sucesso.' : 'Cultura atualizada.',
      );
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _deactivate(Culture culture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar cultura'),
        content: Text('Deseja desativar ${culture.name}?'),
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
      await ref.read(agronomicApiProvider).deactivateCulture(culture.id);
      if (!mounted) return;
      _showMessage('Cultura desativada.');
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

class _CultureDialog extends StatefulWidget {
  const _CultureDialog({this.culture});

  final Culture? culture;

  @override
  State<_CultureDialog> createState() => _CultureDialogState();
}

class _CultureDialogState extends State<_CultureDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _group;
  String? _precocity;
  late final Set<String> _demandTypes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.culture?.name ?? '');
    _group = widget.culture?.group;
    _precocity = widget.culture?.precocity;
    _demandTypes = {...?widget.culture?.demandTypes};
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.culture == null ? 'Nova cultura' : 'Editar cultura'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  autofocus: true,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _group,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Grupo'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Sem grupo'),
                    ),
                    for (final value in cultureGroupValues)
                      DropdownMenuItem(
                        value: value,
                        child: Text(labelFor(cultureGroupLabels, value)),
                      ),
                  ],
                  onChanged: (value) =>
                      _group = value == null || value.isEmpty ? null : value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _precocity,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Precocidade'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Sem precocidade'),
                    ),
                    for (final value in precocityValues)
                      DropdownMenuItem(
                        value: value,
                        child: Text(labelFor(precocityLabels, value)),
                      ),
                  ],
                  onChanged: (value) => _precocity =
                      value == null || value.isEmpty ? null : value,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Serviços atendidos',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final value in demandTypeValues)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _demandTypes.contains(value),
                    title: Text(labelFor(demandTypeLabels, value)),
                    onChanged: (selected) {
                      setState(() {
                        if (selected ?? false) {
                          _demandTypes.add(value);
                        } else {
                          _demandTypes.remove(value);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Salvar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CultureInput(
        name: _nameController.text,
        group: _group,
        precocity: _precocity,
        demandTypes: _demandTypes.toList(growable: false),
      ),
    );
  }
}
