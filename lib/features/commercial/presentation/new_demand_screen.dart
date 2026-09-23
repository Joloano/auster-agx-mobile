import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/commercial_models.dart';
import '../../../data/models/demanda_models.dart';
import '../../../data/models/rural_models.dart';
import '../../../widgets/auster_page_header.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../modules/domain/module_access.dart';
import '../../rural/providers/rural_providers.dart';
import '../providers/commercial_providers.dart';

class NewDemandScreen extends ConsumerStatefulWidget {
  const NewDemandScreen({this.initialOrderId, super.key});

  final String? initialOrderId;

  @override
  ConsumerState<NewDemandScreen> createState() => _NewDemandScreenState();
}

class _NewDemandScreenState extends ConsumerState<NewDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deadlineController = TextEditingController();
  final _areaController = TextEditingController();
  final _applicationController = TextEditingController();
  late Future<_DemandFormOptions> _optionsFuture;

  String? _orderId;
  String _type = 'SMART_N';
  String? _representativeId;
  String? _originDemandId;
  String? _source = 'DRONE';
  String? _pilotId;
  String? _satellite;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _orderId = widget.initialOrderId;
    _optionsFuture = _loadOptions();
  }

  @override
  void dispose() {
    _deadlineController.dispose();
    _areaController.dispose();
    _applicationController.dispose();
    super.dispose();
  }

  Future<_DemandFormOptions> _loadOptions() async {
    final commercial = ref.read(commercialApiProvider);
    final rural = ref.read(ruralApiProvider);
    final ordersFuture = commercial.listOrders(pageSize: 200);
    final demandsFuture = commercial.listDemands(pageSize: 200);
    final collaboratorsFuture = rural.listCollaborators();
    return _DemandFormOptions(
      orders: (await ordersFuture).items,
      demands: (await demandsFuture).items,
      collaborators: await collaboratorsFuture,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null || !canCreateDemanda(user.perfil)) {
      return const Center(child: Text('Seu perfil não pode criar demandas.'));
    }
    return FutureBuilder<_DemandFormOptions>(
      future: _optionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: () {
                setState(() => _optionsFuture = _loadOptions());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(userFacingErrorMessage(snapshot.error!)),
            ),
          );
        }
        return _buildForm(snapshot.data!);
      },
    );
  }

  Widget _buildForm(_DemandFormOptions options) {
    final inheritsMapping = _originDemandId != null;
    final requiresRemoteSensing = !inheritsMapping && _type != 'SMART_SEEDING';
    final selectedOrderExists =
        options.orders.any((order) => order.id == _orderId);
    if (!selectedOrderExists) _orderId = null;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
          children: [
            AusterPageHeader(
              icon: Icons.add_task_rounded,
              title: 'Nova demanda',
              subtitle: 'Criação conectada ao fluxo operacional oficial',
              leading: IconButton(
                tooltip: 'Voltar',
                onPressed: () => context.go('/demandas'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _orderId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pedido',
                prefixIcon: Icon(Icons.receipt_long_rounded),
              ),
              items: options.orders
                  .map(
                    (order) => DropdownMenuItem(
                      value: order.id,
                      child: Text('${order.code} · ${order.clientName}'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() => _orderId = value),
              validator: (value) => value == null ? 'Selecione o pedido' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo de demanda',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'SMART_N', child: Text('Smart-N')),
                DropdownMenuItem(
                  value: 'SMART_BRAKE',
                  child: Text('Smart-Brake'),
                ),
                DropdownMenuItem(
                  value: 'SMART_SEEDING',
                  child: Text('Smart-Seeding'),
                ),
              ],
              onChanged: (value) => setState(() {
                _type = value!;
                if (_type == 'SMART_SEEDING') {
                  _source = null;
                  _pilotId = null;
                  _satellite = null;
                }
              }),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _representativeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Representante',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              items: options.collaborators
                  .map(
                    (person) => DropdownMenuItem(
                      value: person.id,
                      child: Text(person.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() => _representativeId = value),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _deadlineController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Prazo',
                prefixIcon: Icon(Icons.event_rounded),
              ),
              onTap: () => _selectDate(_deadlineController),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _areaController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Área de interesse',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.map_rounded),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _originDemandId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Demanda de origem',
                helperText: 'Use apenas para aplicação seguinte ou retrabalho.',
                prefixIcon: Icon(Icons.account_tree_rounded),
              ),
              items: options.demands
                  .map(
                    (demand) => DropdownMenuItem(
                      value: demand.id,
                      child: Text(demand.codigoDemanda),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() {
                _originDemandId = value;
                if (value != null) {
                  _source = null;
                  _pilotId = null;
                  _satellite = null;
                }
              }),
            ),
            if (_type == 'SMART_N') ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _applicationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número da aplicação',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return int.tryParse(value) == null
                      ? 'Informe um número inteiro'
                      : null;
                },
              ),
            ],
            if (requiresRemoteSensing) ...[
              const SizedBox(height: 20),
              Text(
                'Sensoriamento inicial',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'DRONE',
                    label: Text('Drone'),
                    icon: Icon(Icons.flight_rounded),
                  ),
                  ButtonSegment(
                    value: 'SATELITE',
                    label: Text('Satélite'),
                    icon: Icon(Icons.satellite_alt_rounded),
                  ),
                ],
                selected: {_source ?? 'DRONE'},
                onSelectionChanged: (selection) {
                  setState(() {
                    _source = selection.first;
                    _pilotId = null;
                    _satellite = null;
                  });
                },
              ),
              const SizedBox(height: 14),
              if (_source == 'DRONE')
                DropdownButtonFormField<String>(
                  initialValue: _pilotId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Piloto',
                    prefixIcon: Icon(Icons.flight_takeoff_rounded),
                  ),
                  items: options.collaborators
                      .map(
                        (person) => DropdownMenuItem(
                          value: person.id,
                          child: Text(person.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _pilotId = value),
                  validator: (value) => _source == 'DRONE' && value == null
                      ? 'Selecione o piloto'
                      : null,
                ),
              if (_source == 'SATELITE')
                DropdownButtonFormField<String>(
                  initialValue: _satellite,
                  decoration: const InputDecoration(
                    labelText: 'Satélite',
                    prefixIcon: Icon(Icons.satellite_alt_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'LANDSAT_9',
                      child: Text('Landsat 9'),
                    ),
                    DropdownMenuItem(
                      value: 'SENTINEL_2',
                      child: Text('Sentinel 2'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _satellite = value),
                  validator: (value) => _source == 'SATELITE' && value == null
                      ? 'Selecione o satélite'
                      : null,
                ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_task_rounded),
              label: Text(_submitting ? 'Criando...' : 'Criar demanda'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) {
      controller.text = selected.toIso8601String().split('T').first;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final inheritsMapping = _originDemandId != null;
      final useRemoteSensing = !inheritsMapping && _type != 'SMART_SEEDING';
      final demand = await ref.read(commercialApiProvider).createDemand(
            DemandCreateInput(
              orderId: _orderId!,
              type: _type,
              representativeId: _representativeId,
              deadline: _deadlineController.text.trim(),
              areaOfInterest: _areaController.text.trim(),
              originDemandId: _originDemandId,
              applicationNumber:
                  int.tryParse(_applicationController.text.trim()),
              source: useRemoteSensing ? _source : null,
              pilotId: useRemoteSensing && _source == 'DRONE' ? _pilotId : null,
              satellite:
                  useRemoteSensing && _source == 'SATELITE' ? _satellite : null,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demanda criada com sucesso.')),
      );
      context.go('/demandas/${demand.id}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _DemandFormOptions {
  const _DemandFormOptions({
    required this.orders,
    required this.demands,
    required this.collaborators,
  });

  final List<Order> orders;
  final List<Demanda> demands;
  final List<Collaborator> collaborators;
}
