import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/page_response.dart';
import '../../../data/models/rural_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_record_form.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../modules/domain/module_access.dart';
import '../providers/rural_providers.dart';

class FarmsScreen extends ConsumerStatefulWidget {
  const FarmsScreen({super.key});

  @override
  ConsumerState<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends ConsumerState<FarmsScreen> {
  final _searchController = TextEditingController();
  late Future<PageResponse<Farm>> _future;
  int _page = 0;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<PageResponse<Farm>> _load() {
    return ref.read(ruralApiProvider).listFarms(
          page: _page,
          name: _search,
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
    final canCreate = canCreateFarmOrField(profile);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
            children: [
              AusterPageHeader(
                icon: Icons.agriculture_rounded,
                title: 'Fazendas',
                subtitle: 'Propriedades, áreas e estrutura de campo',
                trailing: canCreate
                    ? IconButton.filled(
                        tooltip: 'Adicionar fazenda',
                        onPressed: _openForm,
                        icon: const Icon(Icons.add_business_rounded),
                      )
                    : null,
              ),
              const SizedBox(height: 18),
              SearchBar(
                controller: _searchController,
                hintText: 'Buscar fazenda',
                leading: const Icon(Icons.search_rounded),
                onSubmitted: _applySearch,
              ),
              const SizedBox(height: 16),
              FutureBuilder<PageResponse<Farm>>(
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
                  return _buildPage(snapshot.data!);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              tooltip: 'Adicionar fazenda',
              onPressed: _openForm,
              child: const Icon(Icons.add_business_rounded),
            )
          : null,
    );
  }

  Widget _buildPage(PageResponse<Farm> page) {
    if (page.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Nenhuma fazenda encontrada.')),
      );
    }
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AusterColors.neutral200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (var index = 0; index < page.items.length; index++) ...[
                ListTile(
                  minTileHeight: 76,
                  leading: const CircleAvatar(
                    child: Icon(Icons.landscape_rounded),
                  ),
                  title: Text(page.items[index].name),
                  subtitle: Text(_farmSubtitle(page.items[index])),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(
                    '/modulos/fazendas/${page.items[index].id}',
                  ),
                ),
                if (index < page.items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${page.totalItems} fazendas · página ${page.page + 1} de ${page.totalPages == 0 ? 1 : page.totalPages}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: 'Página anterior',
              onPressed: page.hasPreviousPage ? () => _changePage(-1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Próxima página',
              onPressed: page.hasNextPage ? () => _changePage(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }

  String _farmSubtitle(Farm farm) {
    final location = [farm.city, farm.state].whereType<String>().join('/');
    final area = farm.areaHa == null ? null : '${farm.areaHa} ha';
    return [farm.ownerClientName, location, area]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' · ');
  }

  void _applySearch(String value) {
    setState(() {
      _search = value.trim();
      _page = 0;
      _future = _load();
    });
  }

  void _changePage(int delta) {
    setState(() {
      _page += delta;
      _future = _load();
    });
  }

  Future<void> _openForm() async {
    try {
      final clients =
          (await ref.read(ruralApiProvider).listClients(pageSize: 200)).items;
      if (!mounted) return;
      final values = await showAusterRecordForm(
        context: context,
        title: 'Adicionar fazenda',
        fields: farmFormFields(clients),
      );
      if (values == null) return;
      await ref.read(ruralApiProvider).createFarm(farmInputFromForm(values));
      if (!mounted) return;
      _showMessage('Fazenda criada com sucesso.');
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

List<RecordFieldSpec> farmFormFields(List<Client> clients) {
  return [
    const RecordFieldSpec(key: 'nome', label: 'Nome', required: true),
    const RecordFieldSpec(key: 'responsavel', label: 'Responsável'),
    RecordFieldSpec(
      key: 'clienteProprietarioId',
      label: 'Cliente proprietário',
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
    const RecordFieldSpec(
      key: 'areaHa',
      label: 'Área total (ha)',
      kind: RecordFieldKind.decimal,
    ),
    const RecordFieldSpec(
      key: 'areaCultivavel',
      label: 'Área cultivável (ha)',
      kind: RecordFieldKind.decimal,
    ),
    const RecordFieldSpec(
      key: 'latitude',
      label: 'Latitude',
      kind: RecordFieldKind.decimal,
    ),
    const RecordFieldSpec(
      key: 'longitude',
      label: 'Longitude',
      kind: RecordFieldKind.decimal,
    ),
    const RecordFieldSpec(
      key: 'contornoGeoJson',
      label: 'Contorno GeoJSON',
      kind: RecordFieldKind.multiline,
    ),
    const RecordFieldSpec(key: 'croquiPath', label: 'Chave do croqui'),
    const RecordFieldSpec(
      key: 'telefone',
      label: 'Telefone',
      kind: RecordFieldKind.phone,
    ),
    const RecordFieldSpec(key: 'localizacao', label: 'Localização'),
    const RecordFieldSpec(key: 'cep', label: 'CEP'),
    const RecordFieldSpec(key: 'logradouro', label: 'Logradouro'),
    const RecordFieldSpec(key: 'numeroEndereco', label: 'Número'),
    const RecordFieldSpec(key: 'complemento', label: 'Complemento'),
    const RecordFieldSpec(key: 'bairro', label: 'Bairro'),
    const RecordFieldSpec(key: 'cidade', label: 'Cidade'),
    const RecordFieldSpec(key: 'uf', label: 'UF', maxLength: 2),
  ];
}

FarmInput farmInputFromForm(Map<String, dynamic> values) {
  return FarmInput(
    name: values['nome'] as String,
    manager: values['responsavel'] as String?,
    ownerClientId: values['clienteProprietarioId'] as String?,
    areaHa: values['areaHa'] as double?,
    cultivableArea: values['areaCultivavel'] as double?,
    latitude: values['latitude'] as double?,
    longitude: values['longitude'] as double?,
    boundaryGeoJson: values['contornoGeoJson'] as String?,
    sketchPath: values['croquiPath'] as String?,
    phone: values['telefone'] as String?,
    location: values['localizacao'] as String?,
    street: values['logradouro'] as String?,
    addressNumber: values['numeroEndereco'] as String?,
    complement: values['complemento'] as String?,
    district: values['bairro'] as String?,
    city: values['cidade'] as String?,
    state: values['uf'] as String?,
    postalCode: values['cep'] as String?,
  );
}

Map<String, dynamic> farmFormValues(Farm farm) {
  return {
    'nome': farm.name,
    'responsavel': farm.manager,
    'clienteProprietarioId': farm.ownerClientId,
    'areaHa': farm.areaHa,
    'areaCultivavel': farm.cultivableArea,
    'latitude': farm.latitude,
    'longitude': farm.longitude,
    'contornoGeoJson': farm.boundaryGeoJson,
    'croquiPath': farm.sketchPath,
    'telefone': farm.phone,
    'localizacao': farm.location,
    'logradouro': farm.street,
    'numeroEndereco': farm.addressNumber,
    'complemento': farm.complement,
    'bairro': farm.district,
    'cidade': farm.city,
    'uf': farm.state,
    'cep': farm.postalCode,
  };
}
