import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/commercial_models.dart';
import '../../../data/models/page_response.dart';
import '../../../data/models/rural_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_record_form.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../modules/domain/module_access.dart';
import '../../rural/providers/rural_providers.dart';
import '../providers/commercial_providers.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  late Future<PageResponse<Order>> _future;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PageResponse<Order>> _load() {
    return ref.read(commercialApiProvider).listOrders(page: _page);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).valueOrNull?.perfil ?? '';
    final canCreate = canCreateOrder(profile);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
            children: [
              AusterPageHeader(
                icon: Icons.receipt_long_rounded,
                title: 'Pedidos',
                subtitle: 'Contratos e demandas relacionadas',
                trailing: canCreate
                    ? IconButton.filled(
                        tooltip: 'Adicionar pedido',
                        onPressed: _create,
                        icon: const Icon(Icons.add_rounded),
                      )
                    : null,
              ),
              const SizedBox(height: 18),
              FutureBuilder<PageResponse<Order>>(
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
              tooltip: 'Adicionar pedido',
              onPressed: _create,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _buildPage(PageResponse<Order> page) {
    if (page.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Nenhum pedido encontrado.')),
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
                    child: Icon(Icons.receipt_long_rounded),
                  ),
                  title: Text(page.items[index].code),
                  subtitle: Text(
                    [page.items[index].clientName, page.items[index].nickname]
                        .whereType<String>()
                        .where((value) => value.isNotEmpty)
                        .join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(
                    '/modulos/pedidos/${page.items[index].id}',
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
                '${page.totalItems} pedidos · página ${page.page + 1} de ${page.totalPages == 0 ? 1 : page.totalPages}',
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

  void _changePage(int delta) {
    setState(() {
      _page += delta;
      _future = _load();
    });
  }

  Future<void> _create() async {
    try {
      final clients =
          (await ref.read(ruralApiProvider).listClients(pageSize: 200)).items;
      if (!mounted) return;
      final values = await showAusterRecordForm(
        context: context,
        title: 'Adicionar pedido',
        fields: orderFormFields(clients, includeClient: true),
      );
      if (values == null) return;
      await ref
          .read(commercialApiProvider)
          .createOrder(orderInputFromForm(values));
      if (!mounted) return;
      _showMessage('Pedido criado com sucesso.');
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

List<RecordFieldSpec> orderFormFields(
  List<Client> clients, {
  required bool includeClient,
}) {
  return [
    if (includeClient)
      RecordFieldSpec(
        key: 'clienteId',
        label: 'Cliente',
        kind: RecordFieldKind.choice,
        required: true,
        options: clients
            .map(
              (client) => RecordFieldOption(
                value: client.id,
                label: client.tradeName,
              ),
            )
            .toList(growable: false),
      ),
    const RecordFieldSpec(key: 'apelido', label: 'Apelido'),
    const RecordFieldSpec(
      key: 'observacoes',
      label: 'Observações',
      kind: RecordFieldKind.multiline,
    ),
  ];
}

OrderInput orderInputFromForm(
  Map<String, dynamic> values, {
  String fallbackClientId = '',
}) {
  return OrderInput(
    clientId: values['clienteId'] as String? ?? fallbackClientId,
    nickname: values['apelido'] as String?,
    notes: values['observacoes'] as String?,
  );
}
