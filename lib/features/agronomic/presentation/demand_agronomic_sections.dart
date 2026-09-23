import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/agronomic_models.dart';
import '../../../data/models/rural_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_key_value_list.dart';
import '../../../widgets/auster_record_form.dart';
import '../../../widgets/auster_section_card.dart';
import '../../rural/providers/rural_providers.dart';
import '../domain/agronomic_labels.dart';
import '../providers/agronomic_providers.dart';

class DemandAgronomicSections extends ConsumerStatefulWidget {
  const DemandAgronomicSections({
    required this.demandId,
    required this.demandType,
    required this.canManage,
    super.key,
  });

  final String demandId;
  final String demandType;
  final bool canManage;

  @override
  ConsumerState<DemandAgronomicSections> createState() =>
      _DemandAgronomicSectionsState();
}

class _DemandAgronomicSectionsState
    extends ConsumerState<DemandAgronomicSections> {
  late Future<_DemandAgronomicData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DemandAgronomicData> _load() async {
    final api = ref.read(agronomicApiProvider);
    final rural = ref.read(ruralApiProvider);
    final stagesFuture = api.listPhenologicalStages();
    final equipmentFuture = rural.listEquipment();

    if (widget.demandType == 'SMART_N') {
      final fertilizationsFuture = api.listFertilizations(widget.demandId);
      final nitrogenFuture = api.getNitrogenManagement(widget.demandId);
      return _DemandAgronomicData(
        stages: (await stagesFuture).items,
        equipment: await equipmentFuture,
        fertilizations: await fertilizationsFuture,
        nitrogen: await nitrogenFuture,
      );
    }
    if (widget.demandType == 'SMART_BRAKE') {
      final brakeFuture = api.getSmartBrakePrescription(widget.demandId);
      return _DemandAgronomicData(
        stages: (await stagesFuture).items,
        equipment: await equipmentFuture,
        smartBrake: await brakeFuture,
      );
    }
    final seedingFuture = api.getSmartSeedingPrescription(widget.demandId);
    return _DemandAgronomicData(
      stages: (await stagesFuture).items,
      equipment: await equipmentFuture,
      smartSeeding: await seedingFuture,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DemandAgronomicData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AusterSectionCard(
            title: 'DADOS AGRONÔMICOS',
            icon: Icons.grass_rounded,
            child: LinearProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return AusterSectionCard(
            title: 'DADOS AGRONÔMICOS',
            icon: Icons.grass_rounded,
            child: AusterErrorState(
              message: userFacingErrorMessage(snapshot.error!),
              compact: true,
              onRetry: _refresh,
            ),
          );
        }
        return _buildSections(snapshot.data!);
      },
    );
  }

  Widget _buildSections(_DemandAgronomicData data) {
    if (widget.demandType == 'SMART_N') {
      return Column(
        children: [
          _fertilizationsSection(data),
          const SizedBox(height: 12),
          _nitrogenSection(data),
        ],
      );
    }
    if (widget.demandType == 'SMART_BRAKE') {
      return _smartBrakeSection(data);
    }
    return _smartSeedingSection(data);
  }

  Widget _fertilizationsSection(_DemandAgronomicData data) {
    return AusterSectionCard(
      title: 'ADUBAÇÕES EM TAXA FIXA',
      icon: Icons.spa_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.canManage)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => _saveFertilization(data),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar'),
              ),
            ),
          if (data.fertilizations.isEmpty)
            const Text('Nenhuma adubação cadastrada.')
          else
            for (final item in data.fertilizations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.spa_rounded),
                title: Text(
                  '${labelFor(fertilizationTypeLabels, item.type)} · '
                  '${item.fertilizerName ?? "Sem fertilizante"}',
                ),
                subtitle: Text(
                  [
                    item.stageName,
                    'Irrigado ${item.irrigatedRate ?? '-'}',
                    'Sequeiro ${item.rainfedRate ?? '-'}',
                    item.estimatedApplicationDate,
                  ].whereType<String>().join(' · '),
                ),
                trailing: widget.canManage
                    ? _actionMenu(
                        onEdit: () => _saveFertilization(data, item),
                        onDeactivate: () => _deactivate(
                          title: 'Desativar adubação',
                          message: 'Deseja desativar esta adubação?',
                          action: () => ref
                              .read(agronomicApiProvider)
                              .deactivateFertilization(item.id),
                        ),
                      )
                    : null,
              ),
        ],
      ),
    );
  }

  Widget _nitrogenSection(_DemandAgronomicData data) {
    final item = data.nitrogen;
    return AusterSectionCard(
      title: 'APLICAÇÃO COM SMART-N',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.canManage)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _saveNitrogen(data, item),
                    icon: Icon(item == null ? Icons.add_rounded : Icons.edit),
                    label: Text(item == null ? 'Cadastrar' : 'Editar'),
                  ),
                  if (item != null)
                    IconButton(
                      tooltip: 'Desativar manejo',
                      onPressed: () => _deactivate(
                        title: 'Desativar manejo',
                        message: 'Deseja desativar o manejo de nitrogênio?',
                        action: () => ref
                            .read(agronomicApiProvider)
                            .deactivateNitrogenManagement(item.id),
                      ),
                      icon: const Icon(Icons.block_rounded),
                    ),
                ],
              ),
            ),
          if (item == null)
            const Text('Nenhum manejo de nitrogênio cadastrado.')
          else
            AusterKeyValueList(
              values: {
                'Restrição média': item.averageRateRestrictionActive
                    ? 'Irrigado ${_range(item.averageMinIrrigated, item.averageMaxIrrigated)}; '
                        'sequeiro ${_range(item.averageMinRainfed, item.averageMaxRainfed)}'
                    : 'Inativa',
                'Restrição pontual': item.pointRateRestrictionActive
                    ? 'Irrigado ${_range(item.pointMinIrrigated, item.pointMaxIrrigated)}; '
                        'sequeiro ${_range(item.pointMinRainfed, item.pointMaxRainfed)}'
                    : 'Inativa',
                'Testemunha': item.controlActive
                    ? 'Irrigado ${item.controlRateIrrigated ?? '-'}; '
                        'sequeiro ${item.controlRateRainfed ?? '-'}'
                    : 'Inativa',
                'Equipamento': item.equipmentName,
                'Insumo disponível': item.totalInputAvailable,
              },
            ),
        ],
      ),
    );
  }

  Widget _smartBrakeSection(_DemandAgronomicData data) {
    final item = data.smartBrake;
    return AusterSectionCard(
      title: 'MANEJO SMART-BRAKE',
      icon: Icons.speed_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.canManage)
            _singleRecordActions(
              item == null,
              onSave: () => _saveSmartBrake(data, item),
              onDeactivate: item == null
                  ? null
                  : () => _deactivate(
                        title: 'Desativar manejo Smart-Brake',
                        message: 'Deseja desativar esta prescrição?',
                        action: () => ref
                            .read(agronomicApiProvider)
                            .deactivateSmartBrakePrescription(item.id),
                      ),
            ),
          if (item == null)
            const Text('Nenhum manejo Smart-Brake cadastrado.')
          else
            AusterKeyValueList(
              values: {
                'Restrição': item.restrictionType,
                'Produto': item.product,
                'Estádio': item.stageName,
                'Taxa mínima': _rates(
                  item.minimumIrrigatedRate,
                  item.minimumRainfedRate,
                ),
                'Taxa média': _rates(
                  item.averageIrrigatedRate,
                  item.averageRainfedRate,
                ),
                'Taxa máxima': _rates(
                  item.maximumIrrigatedRate,
                  item.maximumRainfedRate,
                ),
                'Taxa zero': item.zeroRate ? 'Sim' : 'Não',
                'Testemunha': item.controlActive
                    ? _rates(
                        item.controlRateIrrigated,
                        item.controlRateRainfed,
                      )
                    : 'Inativa',
                'Equipamento': item.equipmentName,
                'Observações': item.notes,
              },
            ),
        ],
      ),
    );
  }

  Widget _smartSeedingSection(_DemandAgronomicData data) {
    final item = data.smartSeeding;
    return AusterSectionCard(
      title: 'MANEJO SMART-SEEDING',
      icon: Icons.agriculture_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.canManage)
            _singleRecordActions(
              item == null,
              onSave: () => _saveSmartSeeding(data, item),
              onDeactivate: item == null
                  ? null
                  : () => _deactivate(
                        title: 'Desativar manejo Smart-Seeding',
                        message: 'Deseja desativar esta prescrição?',
                        action: () => ref
                            .read(agronomicApiProvider)
                            .deactivateSmartSeedingPrescription(item.id),
                      ),
            ),
          if (item == null)
            const Text('Nenhum manejo Smart-Seeding cadastrado.')
          else
            AusterKeyValueList(
              values: {
                'Entrelinhas': item.rowSpacing,
                'Peso de mil sementes': item.thousandSeedWeight,
                'Restrição': item.restrictionType,
                'Taxa mínima': _rates(
                  item.minimumIrrigatedRate,
                  item.minimumRainfedRate,
                ),
                'Taxa média': _rates(
                  item.averageIrrigatedRate,
                  item.averageRainfedRate,
                ),
                'Taxa máxima': _rates(
                  item.maximumIrrigatedRate,
                  item.maximumRainfedRate,
                ),
                'Testemunha': item.controlActive
                    ? _rates(
                        item.controlRateIrrigated,
                        item.controlRateRainfed,
                      )
                    : 'Inativa',
                'Sementes disponíveis': item.totalSeedsAvailable,
                'Semeadora': item.seederName,
                'Observações': item.notes,
              },
            ),
        ],
      ),
    );
  }

  Widget _singleRecordActions(
    bool creating, {
    required VoidCallback onSave,
    VoidCallback? onDeactivate,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: onSave,
            icon: Icon(creating ? Icons.add_rounded : Icons.edit_rounded),
            label: Text(creating ? 'Cadastrar' : 'Editar'),
          ),
          if (onDeactivate != null)
            IconButton(
              tooltip: 'Desativar',
              onPressed: onDeactivate,
              icon: const Icon(Icons.block_rounded),
            ),
        ],
      ),
    );
  }

  Widget _actionMenu({
    required VoidCallback onEdit,
    required VoidCallback onDeactivate,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Ações',
      onSelected: (action) {
        if (action == 'edit') onEdit();
        if (action == 'deactivate') onDeactivate();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'deactivate', child: Text('Desativar')),
      ],
    );
  }

  Future<void> _saveFertilization(
    _DemandAgronomicData data, [
    Fertilization? item,
  ]) async {
    final values = await showAusterRecordForm(
      context: context,
      title: item == null ? 'Nova adubação' : 'Editar adubação',
      fields: [
        const RecordFieldSpec(
          key: 'tipo',
          label: 'Tipo',
          kind: RecordFieldKind.choice,
          required: true,
          options: [
            RecordFieldOption(value: 'SEMEADURA', label: 'Semeadura'),
            RecordFieldOption(value: 'INCORPORADA', label: 'Incorporada'),
            RecordFieldOption(value: 'COBERTURA', label: 'Cobertura'),
          ],
        ),
        const RecordFieldSpec(key: 'fertilizante', label: 'Fertilizante'),
        _stageField(data.stages),
        _decimal('taxaIrrigado', 'Taxa irrigado'),
        _decimal('taxaSequeiro', 'Taxa sequeiro'),
        const RecordFieldSpec(
          key: 'dataAplicacao',
          label: 'Data estimada de aplicação',
          kind: RecordFieldKind.date,
        ),
      ],
      initialValues: item == null
          ? {'tipo': 'SEMEADURA'}
          : {
              'tipo': item.type,
              'fertilizante': item.fertilizerName,
              'estadioId': item.stageId?.toString(),
              'taxaIrrigado': item.irrigatedRate,
              'taxaSequeiro': item.rainfedRate,
              'dataAplicacao': item.estimatedApplicationDate,
            },
    );
    if (values == null) return;
    final input = FertilizationInput(
      demandId: widget.demandId,
      type: values['tipo'] as String,
      fertilizerName: _value(values, 'fertilizante', item?.fertilizerName),
      stageId: _choiceInt(values, 'estadioId', item?.stageId),
      irrigatedRate: _value(values, 'taxaIrrigado', item?.irrigatedRate),
      rainfedRate: _value(values, 'taxaSequeiro', item?.rainfedRate),
      estimatedApplicationDate:
          _value(values, 'dataAplicacao', item?.estimatedApplicationDate),
    );
    await _run(
      () => item == null
          ? ref.read(agronomicApiProvider).createFertilization(input)
          : ref.read(agronomicApiProvider).updateFertilization(item.id, input),
      item == null ? 'Adubação criada.' : 'Adubação atualizada.',
    );
  }

  Future<void> _saveNitrogen(
    _DemandAgronomicData data,
    NitrogenManagement? item,
  ) async {
    final values = await showAusterRecordForm(
      context: context,
      title:
          item == null ? 'Cadastrar manejo Smart-N' : 'Editar manejo Smart-N',
      fields: [
        _boolean('mediaAtiva', 'Restrição de taxa média'),
        _decimal('mediaMinIrrigado', 'Mínimo médio irrigado'),
        _decimal('mediaMaxIrrigado', 'Máximo médio irrigado'),
        _decimal('mediaMinSequeiro', 'Mínimo médio sequeiro'),
        _decimal('mediaMaxSequeiro', 'Máximo médio sequeiro'),
        _boolean('pontualAtiva', 'Restrição de taxa pontual'),
        _decimal('pontualMinIrrigado', 'Mínimo pontual irrigado'),
        _decimal('pontualMaxIrrigado', 'Máximo pontual irrigado'),
        _decimal('pontualMinSequeiro', 'Mínimo pontual sequeiro'),
        _decimal('pontualMaxSequeiro', 'Máximo pontual sequeiro'),
        _boolean('testemunhaAtiva', 'Testemunha'),
        _decimal('testemunhaIrrigado', 'Testemunha irrigado'),
        _decimal('testemunhaSequeiro', 'Testemunha sequeiro'),
        _equipmentField(data.equipment, key: 'equipamentoId'),
        _decimal('totalInsumo', 'Total de insumo disponível'),
      ],
      initialValues: {
        'mediaAtiva': item?.averageRateRestrictionActive ?? false,
        'mediaMinIrrigado': item?.averageMinIrrigated,
        'mediaMaxIrrigado': item?.averageMaxIrrigated,
        'mediaMinSequeiro': item?.averageMinRainfed,
        'mediaMaxSequeiro': item?.averageMaxRainfed,
        'pontualAtiva': item?.pointRateRestrictionActive ?? false,
        'pontualMinIrrigado': item?.pointMinIrrigated,
        'pontualMaxIrrigado': item?.pointMaxIrrigated,
        'pontualMinSequeiro': item?.pointMinRainfed,
        'pontualMaxSequeiro': item?.pointMaxRainfed,
        'testemunhaAtiva': item?.controlActive ?? false,
        'testemunhaIrrigado': item?.controlRateIrrigated,
        'testemunhaSequeiro': item?.controlRateRainfed,
        'equipamentoId': item?.equipmentId?.toString(),
        'totalInsumo': item?.totalInputAvailable,
      },
    );
    if (values == null) return;
    final input = NitrogenManagementInput(
      demandId: widget.demandId,
      averageRateRestrictionActive: values['mediaAtiva'] as bool? ?? false,
      averageMinIrrigated:
          _value(values, 'mediaMinIrrigado', item?.averageMinIrrigated),
      averageMaxIrrigated:
          _value(values, 'mediaMaxIrrigado', item?.averageMaxIrrigated),
      averageMinRainfed:
          _value(values, 'mediaMinSequeiro', item?.averageMinRainfed),
      averageMaxRainfed:
          _value(values, 'mediaMaxSequeiro', item?.averageMaxRainfed),
      pointRateRestrictionActive: values['pontualAtiva'] as bool? ?? false,
      pointMinIrrigated:
          _value(values, 'pontualMinIrrigado', item?.pointMinIrrigated),
      pointMaxIrrigated:
          _value(values, 'pontualMaxIrrigado', item?.pointMaxIrrigated),
      pointMinRainfed:
          _value(values, 'pontualMinSequeiro', item?.pointMinRainfed),
      pointMaxRainfed:
          _value(values, 'pontualMaxSequeiro', item?.pointMaxRainfed),
      controlActive: values['testemunhaAtiva'] as bool? ?? false,
      controlRateIrrigated:
          _value(values, 'testemunhaIrrigado', item?.controlRateIrrigated),
      controlRateRainfed:
          _value(values, 'testemunhaSequeiro', item?.controlRateRainfed),
      equipmentId: _choiceInt(values, 'equipamentoId', item?.equipmentId),
      totalInputAvailable:
          _value(values, 'totalInsumo', item?.totalInputAvailable),
    );
    await _run(
      () => item == null
          ? ref.read(agronomicApiProvider).createNitrogenManagement(input)
          : ref
              .read(agronomicApiProvider)
              .updateNitrogenManagement(item.id, input),
      item == null ? 'Manejo Smart-N criado.' : 'Manejo Smart-N atualizado.',
    );
  }

  Future<void> _saveSmartBrake(
    _DemandAgronomicData data,
    SmartBrakePrescription? item,
  ) async {
    final values = await showAusterRecordForm(
      context: context,
      title: item == null
          ? 'Cadastrar manejo Smart-Brake'
          : 'Editar manejo Smart-Brake',
      fields: [
        _restrictionField(),
        const RecordFieldSpec(key: 'produto', label: 'Produto utilizado'),
        _stageField(data.stages),
        ..._rateMatrixFields(),
        _boolean('taxaZero', 'Taxa zero'),
        _boolean('testemunhaAtiva', 'Testemunha'),
        _decimal('testemunhaIrrigado', 'Testemunha irrigado'),
        _decimal('testemunhaSequeiro', 'Testemunha sequeiro'),
        _equipmentField(data.equipment, key: 'equipamentoId'),
        const RecordFieldSpec(
          key: 'observacoes',
          label: 'Observações',
          kind: RecordFieldKind.multiline,
        ),
      ],
      initialValues: {
        'restricao': item?.restrictionType,
        'produto': item?.product,
        'estadioId': item?.stageId?.toString(),
        ..._rateMatrixValues(
          minimumIrrigated: item?.minimumIrrigatedRate,
          minimumRainfed: item?.minimumRainfedRate,
          averageIrrigated: item?.averageIrrigatedRate,
          averageRainfed: item?.averageRainfedRate,
          maximumIrrigated: item?.maximumIrrigatedRate,
          maximumRainfed: item?.maximumRainfedRate,
        ),
        'taxaZero': item?.zeroRate ?? false,
        'testemunhaAtiva': item?.controlActive ?? false,
        'testemunhaIrrigado': item?.controlRateIrrigated,
        'testemunhaSequeiro': item?.controlRateRainfed,
        'equipamentoId': item?.equipmentId?.toString(),
        'observacoes': item?.notes,
      },
    );
    if (values == null) return;
    final input = SmartBrakePrescriptionInput(
      demandId: widget.demandId,
      restrictionType: _value(values, 'restricao', item?.restrictionType),
      product: _value(values, 'produto', item?.product),
      stageId: _choiceInt(values, 'estadioId', item?.stageId),
      minimumIrrigatedRate:
          _value(values, 'minIrrigado', item?.minimumIrrigatedRate),
      minimumRainfedRate:
          _value(values, 'minSequeiro', item?.minimumRainfedRate),
      averageIrrigatedRate:
          _value(values, 'mediaIrrigado', item?.averageIrrigatedRate),
      averageRainfedRate:
          _value(values, 'mediaSequeiro', item?.averageRainfedRate),
      maximumIrrigatedRate:
          _value(values, 'maxIrrigado', item?.maximumIrrigatedRate),
      maximumRainfedRate:
          _value(values, 'maxSequeiro', item?.maximumRainfedRate),
      zeroRate: values['taxaZero'] as bool? ?? false,
      controlActive: values['testemunhaAtiva'] as bool? ?? false,
      controlRateIrrigated:
          _value(values, 'testemunhaIrrigado', item?.controlRateIrrigated),
      controlRateRainfed:
          _value(values, 'testemunhaSequeiro', item?.controlRateRainfed),
      equipmentId: _choiceInt(values, 'equipamentoId', item?.equipmentId),
      notes: _value(values, 'observacoes', item?.notes),
    );
    await _run(
      () => item == null
          ? ref.read(agronomicApiProvider).createSmartBrakePrescription(input)
          : ref
              .read(agronomicApiProvider)
              .updateSmartBrakePrescription(item.id, input),
      item == null
          ? 'Manejo Smart-Brake criado.'
          : 'Manejo Smart-Brake atualizado.',
    );
  }

  Future<void> _saveSmartSeeding(
    _DemandAgronomicData data,
    SmartSeedingPrescription? item,
  ) async {
    final values = await showAusterRecordForm(
      context: context,
      title: item == null
          ? 'Cadastrar manejo Smart-Seeding'
          : 'Editar manejo Smart-Seeding',
      fields: [
        _decimal('entrelinhas', 'Distância entre linhas'),
        _decimal('pesoMil', 'Peso de mil sementes'),
        _restrictionField(),
        ..._rateMatrixFields(),
        _boolean('testemunhaAtiva', 'Testemunha'),
        _decimal('testemunhaIrrigado', 'Testemunha irrigado'),
        _decimal('testemunhaSequeiro', 'Testemunha sequeiro'),
        _decimal('totalSementes', 'Total de sementes disponível'),
        _equipmentField(
          data.equipment,
          key: 'semeadoraId',
          label: 'Modelo de semeadora',
        ),
        const RecordFieldSpec(
          key: 'observacoes',
          label: 'Observações',
          kind: RecordFieldKind.multiline,
        ),
      ],
      initialValues: {
        'entrelinhas': item?.rowSpacing,
        'pesoMil': item?.thousandSeedWeight,
        'restricao': item?.restrictionType,
        ..._rateMatrixValues(
          minimumIrrigated: item?.minimumIrrigatedRate,
          minimumRainfed: item?.minimumRainfedRate,
          averageIrrigated: item?.averageIrrigatedRate,
          averageRainfed: item?.averageRainfedRate,
          maximumIrrigated: item?.maximumIrrigatedRate,
          maximumRainfed: item?.maximumRainfedRate,
        ),
        'testemunhaAtiva': item?.controlActive ?? false,
        'testemunhaIrrigado': item?.controlRateIrrigated,
        'testemunhaSequeiro': item?.controlRateRainfed,
        'totalSementes': item?.totalSeedsAvailable,
        'semeadoraId': item?.seederId?.toString(),
        'observacoes': item?.notes,
      },
    );
    if (values == null) return;
    final input = SmartSeedingPrescriptionInput(
      demandId: widget.demandId,
      rowSpacing: _value(values, 'entrelinhas', item?.rowSpacing),
      thousandSeedWeight: _value(values, 'pesoMil', item?.thousandSeedWeight),
      restrictionType: _value(values, 'restricao', item?.restrictionType),
      minimumIrrigatedRate:
          _value(values, 'minIrrigado', item?.minimumIrrigatedRate),
      minimumRainfedRate:
          _value(values, 'minSequeiro', item?.minimumRainfedRate),
      averageIrrigatedRate:
          _value(values, 'mediaIrrigado', item?.averageIrrigatedRate),
      averageRainfedRate:
          _value(values, 'mediaSequeiro', item?.averageRainfedRate),
      maximumIrrigatedRate:
          _value(values, 'maxIrrigado', item?.maximumIrrigatedRate),
      maximumRainfedRate:
          _value(values, 'maxSequeiro', item?.maximumRainfedRate),
      controlActive: values['testemunhaAtiva'] as bool? ?? false,
      controlRateIrrigated:
          _value(values, 'testemunhaIrrigado', item?.controlRateIrrigated),
      controlRateRainfed:
          _value(values, 'testemunhaSequeiro', item?.controlRateRainfed),
      totalSeedsAvailable:
          _value(values, 'totalSementes', item?.totalSeedsAvailable),
      seederId: _choiceInt(values, 'semeadoraId', item?.seederId),
      notes: _value(values, 'observacoes', item?.notes),
    );
    await _run(
      () => item == null
          ? ref.read(agronomicApiProvider).createSmartSeedingPrescription(input)
          : ref
              .read(agronomicApiProvider)
              .updateSmartSeedingPrescription(item.id, input),
      item == null
          ? 'Manejo Smart-Seeding criado.'
          : 'Manejo Smart-Seeding atualizado.',
    );
  }

  Future<void> _deactivate({
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
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
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _run(action, 'Registro desativado.');
  }

  Future<void> _run(
    Future<Object?> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }
}

class _DemandAgronomicData {
  const _DemandAgronomicData({
    required this.stages,
    required this.equipment,
    this.fertilizations = const [],
    this.nitrogen,
    this.smartBrake,
    this.smartSeeding,
  });

  final List<PhenologicalStage> stages;
  final List<Equipment> equipment;
  final List<Fertilization> fertilizations;
  final NitrogenManagement? nitrogen;
  final SmartBrakePrescription? smartBrake;
  final SmartSeedingPrescription? smartSeeding;
}

RecordFieldSpec _decimal(String key, String label) {
  return RecordFieldSpec(
    key: key,
    label: label,
    kind: RecordFieldKind.decimal,
  );
}

RecordFieldSpec _boolean(String key, String label) {
  return RecordFieldSpec(
    key: key,
    label: label,
    kind: RecordFieldKind.boolean,
  );
}

RecordFieldSpec _stageField(List<PhenologicalStage> stages) {
  return RecordFieldSpec(
    key: 'estadioId',
    label: 'Estádio fenológico',
    kind: RecordFieldKind.choice,
    options: stages
        .map(
          (stage) => RecordFieldOption(
            value: stage.id.toString(),
            label: stage.name,
          ),
        )
        .toList(growable: false),
  );
}

RecordFieldSpec _equipmentField(
  List<Equipment> equipment, {
  required String key,
  String label = 'Equipamento de aplicação',
}) {
  return RecordFieldSpec(
    key: key,
    label: label,
    kind: RecordFieldKind.choice,
    options: equipment
        .map(
          (item) => RecordFieldOption(
            value: item.id.toString(),
            label: item.name,
          ),
        )
        .toList(growable: false),
  );
}

RecordFieldSpec _restrictionField() {
  return const RecordFieldSpec(
    key: 'restricao',
    label: 'Tipo de restrição de taxa',
    kind: RecordFieldKind.choice,
    options: [
      RecordFieldOption(value: 'MEDIA', label: 'Média'),
      RecordFieldOption(value: 'PONTUAL', label: 'Pontual'),
    ],
  );
}

List<RecordFieldSpec> _rateMatrixFields() => [
      _decimal('minIrrigado', 'Taxa mínima irrigado'),
      _decimal('minSequeiro', 'Taxa mínima sequeiro'),
      _decimal('mediaIrrigado', 'Taxa média irrigado'),
      _decimal('mediaSequeiro', 'Taxa média sequeiro'),
      _decimal('maxIrrigado', 'Taxa máxima irrigado'),
      _decimal('maxSequeiro', 'Taxa máxima sequeiro'),
    ];

Map<String, Object?> _rateMatrixValues({
  required double? minimumIrrigated,
  required double? minimumRainfed,
  required double? averageIrrigated,
  required double? averageRainfed,
  required double? maximumIrrigated,
  required double? maximumRainfed,
}) =>
    {
      'minIrrigado': minimumIrrigated,
      'minSequeiro': minimumRainfed,
      'mediaIrrigado': averageIrrigated,
      'mediaSequeiro': averageRainfed,
      'maxIrrigado': maximumIrrigated,
      'maxSequeiro': maximumRainfed,
    };

T? _value<T>(Map<String, dynamic> values, String key, T? fallback) {
  return values[key] as T? ?? fallback;
}

int? _choiceInt(
  Map<String, dynamic> values,
  String key,
  int? fallback,
) {
  return int.tryParse(values[key] as String? ?? '') ?? fallback;
}

String _range(double? minimum, double? maximum) {
  return '${minimum ?? '-'} a ${maximum ?? '-'}';
}

String _rates(double? irrigated, double? rainfed) {
  return 'Irrigado ${irrigated ?? '-'}; sequeiro ${rainfed ?? '-'}';
}
