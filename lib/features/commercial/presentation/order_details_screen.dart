import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/commercial_models.dart';
import '../../../data/models/demanda_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_key_value_list.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_record_form.dart';
import '../../../widgets/auster_section_card.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../modules/domain/module_access.dart';
import '../providers/commercial_providers.dart';
import 'orders_screen.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  late Future<OrderDetails> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<OrderDetails> _load() async {
    final api = ref.read(commercialApiProvider);
    final orderFuture = api.getOrder(widget.orderId);
    final demandsFuture = api.listDemands(orderId: widget.orderId);
    return OrderDetails(
      order: await orderFuture,
      demands: (await demandsFuture).items,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderDetails>(
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

  Widget _buildContent(OrderDetails details) {
    final profile = ref.watch(authControllerProvider).valueOrNull?.perfil ?? '';
    final canEdit = canUpdateOrder(profile);
    final canCreateDemand = canCreateDemanda(profile);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            AusterPageHeader(
              icon: Icons.receipt_long_rounded,
              title: details.order.code,
              subtitle: details.order.clientName,
              leading: IconButton(
                tooltip: 'Voltar',
                onPressed: () => context.go('/modulos/pedidos'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              trailing: canEdit
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações do pedido',
                      onSelected: (action) {
                        if (action == 'edit') _edit(details.order);
                        if (action == 'deactivate') {
                          _deactivate(details.order);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Editar')),
                        if (canManageRuralData(profile))
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Desativar'),
                          ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            AusterSectionCard(
              title: 'Resumo',
              icon: Icons.description_rounded,
              child: AusterKeyValueList(
                values: {
                  'Cliente': details.order.clientName,
                  'Apelido': details.order.nickname,
                  'Observações': details.order.notes,
                  'Criado em': details.order.createdAt,
                },
              ),
            ),
            const SizedBox(height: 12),
            AusterSectionCard(
              title: 'Demandas',
              icon: Icons.assignment_rounded,
              child: Column(
                children: [
                  if (details.demands.isEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nenhuma demanda criada para este pedido.'),
                    ),
                  for (final demand in details.demands)
                    _DemandTile(demand: demand),
                  if (canCreateDemand) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go(
                          '/demandas/nova?pedidoId=${details.order.id}',
                        ),
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Nova demanda'),
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

  Future<void> _edit(Order order) async {
    final values = await showAusterRecordForm(
      context: context,
      title: 'Editar pedido',
      fields: orderFormFields(const [], includeClient: false),
      initialValues: {
        'apelido': order.nickname,
        'observacoes': order.notes,
      },
    );
    if (values == null) return;
    try {
      await ref.read(commercialApiProvider).updateOrder(
            order.id,
            orderInputFromForm(values, fallbackClientId: order.clientId),
          );
      if (!mounted) return;
      _showMessage('Pedido atualizado com sucesso.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _deactivate(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar pedido'),
        content: Text('Deseja desativar ${order.code}?'),
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
      await ref.read(commercialApiProvider).deactivateOrder(order.id);
      if (!mounted) return;
      _showMessage('Pedido desativado.');
      context.go('/modulos/pedidos');
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DemandTile extends StatelessWidget {
  const _DemandTile({required this.demand});

  final Demanda demand;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(demand.codigoDemanda),
      subtitle: Text('${demand.tipo} · ${demand.status}'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.go('/demandas/${demand.id}'),
    );
  }
}
