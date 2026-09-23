import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/models/page_response.dart';
import '../../../data/models/rural_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_record_form.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../authentication/providers/account_providers.dart';
import '../../modules/domain/module_access.dart';
import '../providers/rural_providers.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  late Future<PageResponse<Client>> _future;
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

  Future<PageResponse<Client>> _load() {
    return ref.read(ruralApiProvider).listClients(
          page: _page,
          tradeName: _search,
        );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final canCreate = user != null && canCreateClient(user.perfil);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
            children: [
              AusterPageHeader(
                icon: Icons.people_alt_rounded,
                title: 'Clientes',
                subtitle: 'Carteiras e dados cadastrais',
                trailing: canCreate
                    ? IconButton.filled(
                        tooltip: 'Adicionar cliente',
                        onPressed: () => _openForm(user),
                        icon: const Icon(Icons.person_add_rounded),
                      )
                    : null,
              ),
              const SizedBox(height: 18),
              SearchBar(
                controller: _searchController,
                hintText: 'Buscar por nome fantasia',
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        _searchController.clear();
                        _applySearch('');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
                ],
                onSubmitted: _applySearch,
              ),
              const SizedBox(height: 16),
              FutureBuilder<PageResponse<Client>>(
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
              tooltip: 'Adicionar cliente',
              onPressed: () => _openForm(user),
              child: const Icon(Icons.person_add_rounded),
            )
          : null,
    );
  }

  Widget _buildPage(PageResponse<Client> page) {
    if (page.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Nenhum cliente encontrado.')),
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
                    child: Icon(Icons.business_rounded),
                  ),
                  title: Text(page.items[index].tradeName),
                  subtitle: Text(
                    '${page.items[index].documentType} ${page.items[index].documentNumber}'
                    '${page.items[index].city == null ? '' : '\n${page.items[index].city}/${page.items[index].state ?? ''}'}',
                  ),
                  isThreeLine: page.items[index].city != null,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(
                    '/modulos/clientes/${page.items[index].id}',
                  ),
                ),
                if (index < page.items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PaginationBar(
          page: page.page,
          totalPages: page.totalPages,
          totalItems: page.totalItems,
          onPrevious: page.hasPreviousPage ? () => _changePage(-1) : null,
          onNext: page.hasNextPage ? () => _changePage(1) : null,
        ),
      ],
    );
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

  Future<void> _openForm(AuthUser currentUser) async {
    final responsibleUsers = currentUser.perfil == 'SUPER_ADMIN'
        ? await ref
            .read(accountRepositoryProvider)
            .listUsers(includeInactive: false)
        : [currentUser];
    if (!mounted) return;
    final values = await showAusterRecordForm(
      context: context,
      title: 'Adicionar cliente',
      fields: _clientFields(responsibleUsers, includeResponsible: true),
      initialValues: {
        'usuarioId': currentUser.userId,
        'tipoDocumento': 'CPF',
      },
    );
    if (values == null) return;

    try {
      await ref.read(ruralApiProvider).createClient(_clientInput(values));
      if (!mounted) return;
      _showMessage('Cliente criado com sucesso.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$totalItems clientes · página ${page + 1} de ${totalPages == 0 ? 1 : totalPages}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          tooltip: 'Página anterior',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          tooltip: 'Próxima página',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

List<RecordFieldSpec> _clientFields(
  List<AuthUser> users, {
  required bool includeResponsible,
}) {
  return [
    if (includeResponsible)
      RecordFieldSpec(
        key: 'usuarioId',
        label: 'Carteira responsável',
        kind: RecordFieldKind.choice,
        required: true,
        options: users
            .map(
              (user) => RecordFieldOption(
                value: user.userId,
                label: '${user.nome} · ${user.email}',
              ),
            )
            .toList(growable: false),
      ),
    const RecordFieldSpec(
      key: 'tipoDocumento',
      label: 'Tipo de documento',
      kind: RecordFieldKind.choice,
      required: true,
      options: [
        RecordFieldOption(value: 'CPF', label: 'CPF'),
        RecordFieldOption(value: 'CNPJ', label: 'CNPJ'),
      ],
    ),
    const RecordFieldSpec(
      key: 'numeroDocumento',
      label: 'Número do documento',
      required: true,
    ),
    const RecordFieldSpec(
      key: 'nomeFantasia',
      label: 'Nome fantasia',
      required: true,
    ),
    const RecordFieldSpec(key: 'razaoSocial', label: 'Razão social'),
    const RecordFieldSpec(
      key: 'inscricaoEstadual',
      label: 'Inscrição estadual',
    ),
    const RecordFieldSpec(
      key: 'emailFaturamento',
      label: 'E-mail de faturamento',
      kind: RecordFieldKind.email,
      required: true,
    ),
    const RecordFieldSpec(
      key: 'emailContato',
      label: 'E-mail de contato',
      kind: RecordFieldKind.email,
    ),
    const RecordFieldSpec(
      key: 'telefone',
      label: 'Telefone',
      kind: RecordFieldKind.phone,
    ),
    const RecordFieldSpec(key: 'cep', label: 'CEP'),
    const RecordFieldSpec(key: 'logradouro', label: 'Logradouro'),
    const RecordFieldSpec(key: 'numeroEndereco', label: 'Número'),
    const RecordFieldSpec(key: 'complemento', label: 'Complemento'),
    const RecordFieldSpec(key: 'referencia', label: 'Referência'),
    const RecordFieldSpec(key: 'bairro', label: 'Bairro'),
    const RecordFieldSpec(key: 'cidade', label: 'Cidade'),
    const RecordFieldSpec(key: 'uf', label: 'UF', maxLength: 2),
  ];
}

ClientInput _clientInput(Map<String, dynamic> values) {
  return ClientInput(
    userId: values['usuarioId'] as String?,
    documentType: values['tipoDocumento'] as String,
    documentNumber: values['numeroDocumento'] as String,
    tradeName: values['nomeFantasia'] as String,
    companyName: values['razaoSocial'] as String?,
    stateRegistration: values['inscricaoEstadual'] as String?,
    billingEmail: values['emailFaturamento'] as String,
    contactEmail: values['emailContato'] as String?,
    phone: values['telefone'] as String?,
    street: values['logradouro'] as String?,
    addressNumber: values['numeroEndereco'] as String?,
    complement: values['complemento'] as String?,
    reference: values['referencia'] as String?,
    district: values['bairro'] as String?,
    city: values['cidade'] as String?,
    state: values['uf'] as String?,
    postalCode: values['cep'] as String?,
  );
}

Map<String, dynamic> clientFormValues(Client client) {
  return {
    'tipoDocumento': client.documentType,
    'numeroDocumento': client.documentNumber,
    'nomeFantasia': client.tradeName,
    'razaoSocial': client.companyName,
    'inscricaoEstadual': client.stateRegistration,
    'emailFaturamento': client.billingEmail,
    'emailContato': client.contactEmail,
    'telefone': client.phone,
    'logradouro': client.street,
    'numeroEndereco': client.addressNumber,
    'complemento': client.complement,
    'referencia': client.reference,
    'bairro': client.district,
    'cidade': client.city,
    'uf': client.state,
    'cep': client.postalCode,
  };
}

List<RecordFieldSpec> clientEditFields() =>
    _clientFields(const [], includeResponsible: false);

ClientInput clientInputFromForm(Map<String, dynamic> values) =>
    _clientInput(values);

extension on _ClientsScreenState {
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
