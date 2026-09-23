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
import 'clients_screen.dart';

class ClientDetailsScreen extends ConsumerStatefulWidget {
  const ClientDetailsScreen({required this.clientId, super.key});

  final String clientId;

  @override
  ConsumerState<ClientDetailsScreen> createState() =>
      _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends ConsumerState<ClientDetailsScreen> {
  late Future<_ClientDetailsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClientDetailsData> _load() async {
    final api = ref.read(ruralApiProvider);
    final clientFuture = api.getClient(widget.clientId);
    final linksFuture = api.listActiveLinks();
    final farmsFuture = api.listFarms(pageSize: 200);
    final client = await clientFuture;
    final links = await linksFuture;
    final farms = await farmsFuture;
    return _ClientDetailsData(
      client: client,
      links: links
          .where((link) => link.clientId == widget.clientId)
          .toList(growable: false),
      farms: farms.items,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ClientDetailsData>(
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

  Widget _buildContent(_ClientDetailsData data) {
    final profile = ref.watch(authControllerProvider).valueOrNull?.perfil ?? '';
    final canEdit = canUpdateClient(profile);
    final canManageLinks = canManageRuralData(profile);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            AusterPageHeader(
              icon: Icons.business_rounded,
              title: data.client.tradeName,
              subtitle:
                  '${data.client.documentType} ${data.client.documentNumber}',
              leading: IconButton(
                tooltip: 'Voltar',
                onPressed: () => context.go('/modulos/clientes'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              trailing: canEdit
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações do cliente',
                      onSelected: (action) {
                        if (action == 'edit') _edit(data.client);
                        if (action == 'deactivate') _deactivate(data.client);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar cliente'),
                        ),
                        if (canManageRuralData(profile))
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Desativar cliente'),
                          ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            AusterSectionCard(
              title: 'Contato e faturamento',
              icon: Icons.contact_mail_rounded,
              child: AusterKeyValueList(
                values: {
                  'Razão social': data.client.companyName,
                  'E-mail de faturamento': data.client.billingEmail,
                  'E-mail de contato': data.client.contactEmail,
                  'Telefone': data.client.phone,
                  'Inscrição estadual': data.client.stateRegistration,
                },
              ),
            ),
            const SizedBox(height: 12),
            AusterSectionCard(
              title: 'Endereço',
              icon: Icons.location_on_rounded,
              child: AusterKeyValueList(
                values: {
                  'Logradouro': data.client.street,
                  'Número': data.client.addressNumber,
                  'Complemento': data.client.complement,
                  'Bairro': data.client.district,
                  'Cidade/UF': [data.client.city, data.client.state]
                      .whereType<String>()
                      .join('/'),
                  'CEP': data.client.postalCode,
                  'Referência': data.client.reference,
                },
              ),
            ),
            const SizedBox(height: 12),
            AusterSectionCard(
              title: 'Fazendas vinculadas',
              icon: Icons.agriculture_rounded,
              child: Column(
                children: [
                  if (data.links.isEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nenhuma fazenda vinculada.'),
                    ),
                  for (final link in data.links)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(link.farmName),
                      subtitle: Text('Desde ${link.startDate}'),
                      onTap: () =>
                          context.go('/modulos/fazendas/${link.farmId}'),
                      trailing: canManageLinks
                          ? IconButton(
                              tooltip: 'Encerrar vínculo',
                              onPressed: () => _closeLink(link),
                              icon: const Icon(Icons.link_off_rounded),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                    ),
                  if (canManageLinks) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _addLink(data),
                        icon: const Icon(Icons.add_link_rounded),
                        label: const Text('Vincular fazenda'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(Client client) async {
    final values = await showAusterRecordForm(
      context: context,
      title: 'Editar cliente',
      fields: clientEditFields(),
      initialValues: clientFormValues(client),
    );
    if (values == null) return;
    try {
      await ref
          .read(ruralApiProvider)
          .updateClient(client.id, clientInputFromForm(values));
      if (!mounted) return;
      _showMessage('Cliente atualizado com sucesso.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _deactivate(Client client) async {
    final confirmed = await _confirm(
      'Desativar cliente',
      'Deseja desativar ${client.tradeName}?',
    );
    if (!confirmed) return;
    try {
      await ref.read(ruralApiProvider).deactivateClient(client.id);
      if (!mounted) return;
      _showMessage('Cliente desativado.');
      context.go('/modulos/clientes');
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _addLink(_ClientDetailsData data) async {
    final linkedIds = data.links.map((link) => link.farmId).toSet();
    final available = data.farms
        .where((farm) => !linkedIds.contains(farm.id))
        .toList(growable: false);
    if (available.isEmpty) {
      _showMessage('Não há fazendas disponíveis para vincular.');
      return;
    }
    final values = await showAusterRecordForm(
      context: context,
      title: 'Vincular fazenda',
      fields: [
        RecordFieldSpec(
          key: 'fazendaId',
          label: 'Fazenda',
          kind: RecordFieldKind.choice,
          required: true,
          options: available
              .map(
                (farm) => RecordFieldOption(value: farm.id, label: farm.name),
              )
              .toList(growable: false),
        ),
        const RecordFieldSpec(
          key: 'dataInicio',
          label: 'Data de início',
          kind: RecordFieldKind.date,
          required: true,
        ),
      ],
      initialValues: {
        'dataInicio': DateTime.now().toIso8601String().split('T').first,
      },
    );
    if (values == null) return;
    try {
      await ref.read(ruralApiProvider).linkClientToFarm(
            clientId: data.client.id,
            farmId: values['fazendaId'] as String,
            startDate: values['dataInicio'] as String,
          );
      if (!mounted) return;
      _showMessage('Fazenda vinculada com sucesso.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _closeLink(ClientFarmLink link) async {
    final confirmed = await _confirm(
      'Encerrar vínculo',
      'Deseja encerrar o vínculo com ${link.farmName}?',
    );
    if (!confirmed) return;
    try {
      await ref.read(ruralApiProvider).closeClientFarmLink(
            link.id,
            DateTime.now().toIso8601String().split('T').first,
          );
      if (!mounted) return;
      _showMessage('Vínculo encerrado.');
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

class _ClientDetailsData {
  const _ClientDetailsData({
    required this.client,
    required this.links,
    required this.farms,
  });

  final Client client;
  final List<ClientFarmLink> links;
  final List<Farm> farms;
}
