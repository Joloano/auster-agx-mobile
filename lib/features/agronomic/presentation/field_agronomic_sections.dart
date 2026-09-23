import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/agronomic_models.dart';
import '../../../widgets/auster_record_form.dart';
import '../../../widgets/auster_section_card.dart';
import '../providers/agronomic_providers.dart';

class FieldAgronomicSections extends ConsumerWidget {
  const FieldAgronomicSections({
    required this.fieldId,
    required this.cultures,
    required this.cultivations,
    required this.previousCrops,
    required this.soilData,
    required this.canManage,
    required this.onChanged,
    super.key,
  });

  final String fieldId;
  final List<Culture> cultures;
  final List<Cultivation> cultivations;
  final List<PreviousCrop> previousCrops;
  final List<SoilData> soilData;
  final bool canManage;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AusterSectionCard(
          title: 'Cultivos',
          icon: Icons.grass_rounded,
          child: _buildCultivations(context, ref),
        ),
        const SizedBox(height: 12),
        AusterSectionCard(
          title: 'Culturas antecessoras',
          icon: Icons.history_rounded,
          child: _buildPreviousCrops(context, ref),
        ),
        const SizedBox(height: 12),
        AusterSectionCard(
          title: 'Dados de solo',
          icon: Icons.science_rounded,
          child: _buildSoilData(context, ref),
        ),
      ],
    );
  }

  Widget _buildCultivations(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canManage)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _saveCultivation(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar'),
            ),
          ),
        if (cultivations.isEmpty)
          const Text('Nenhum cultivo cadastrado.')
        else
          for (final cultivation in cultivations)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.grass_rounded),
              title: Text(cultivation.cultureName),
              subtitle: Text(
                [
                  cultivation.purpose,
                  cultivation.sowingDate == null
                      ? null
                      : 'Semeadura ${cultivation.sowingDate}',
                  cultivation.targetYield == null
                      ? null
                      : 'Meta ${cultivation.targetYield} ${cultivation.targetYieldUnit ?? ''}',
                ].whereType<String>().join(' · '),
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações do cultivo',
                      onSelected: (action) {
                        if (action == 'edit') {
                          _saveCultivation(context, ref, cultivation);
                        }
                        if (action == 'deactivate') {
                          _deactivate(
                            context,
                            ref,
                            title: 'Desativar cultivo',
                            message:
                                'Deseja desativar o cultivo de ${cultivation.cultureName}?',
                            action: () => ref
                                .read(agronomicApiProvider)
                                .deactivateCultivation(cultivation.id),
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Desativar'),
                        ),
                      ],
                    )
                  : null,
            ),
      ],
    );
  }

  Widget _buildPreviousCrops(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canManage)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _savePreviousCrop(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar'),
            ),
          ),
        if (previousCrops.isEmpty)
          const Text('Nenhuma cultura antecessora cadastrada.')
        else
          for (final crop in previousCrops)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded),
              title: Text(crop.cultureName),
              subtitle: Text(
                [
                  crop.season,
                  crop.averageYield == null
                      ? null
                      : 'Produtividade ${crop.averageYield}',
                  crop.cycle == null ? null : 'Ciclo ${crop.cycle} dias',
                ].whereType<String>().join(' · '),
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações da cultura antecessora',
                      onSelected: (action) {
                        if (action == 'edit') {
                          _savePreviousCrop(context, ref, crop);
                        }
                        if (action == 'deactivate') {
                          _deactivate(
                            context,
                            ref,
                            title: 'Desativar cultura antecessora',
                            message: 'Deseja desativar ${crop.cultureName}?',
                            action: () => ref
                                .read(agronomicApiProvider)
                                .deactivatePreviousCrop(crop.id),
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Desativar'),
                        ),
                      ],
                    )
                  : null,
            ),
      ],
    );
  }

  Widget _buildSoilData(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canManage)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => _saveSoilData(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar'),
            ),
          ),
        if (soilData.isEmpty)
          const Text('Nenhuma análise de solo cadastrada.')
        else
          for (final soil in soilData)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.science_rounded),
              title: Text(soil.registrationDate),
              subtitle: Text(
                'MOS ${soil.averageOrganicMatter ?? '-'} · '
                'Argila ${soil.averageClay ?? '-'}',
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      tooltip: 'Ações dos dados de solo',
                      onSelected: (action) {
                        if (action == 'edit') {
                          _saveSoilData(context, ref, soil);
                        }
                        if (action == 'deactivate') {
                          _deactivate(
                            context,
                            ref,
                            title: 'Desativar dados de solo',
                            message:
                                'Deseja desativar a análise de ${soil.registrationDate}?',
                            action: () => ref
                                .read(agronomicApiProvider)
                                .deactivateSoilData(soil.id),
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Desativar'),
                        ),
                      ],
                    )
                  : null,
            ),
      ],
    );
  }

  Future<void> _saveCultivation(
    BuildContext context,
    WidgetRef ref, [
    Cultivation? cultivation,
  ]) async {
    final values = await showAusterRecordForm(
      context: context,
      title: cultivation == null ? 'Novo cultivo' : 'Editar cultivo',
      fields: [
        if (cultivation == null)
          RecordFieldSpec(
            key: 'culturaId',
            label: 'Cultura',
            kind: RecordFieldKind.choice,
            required: true,
            options: cultures
                .map(
                  (culture) => RecordFieldOption(
                    value: culture.id.toString(),
                    label: culture.name,
                  ),
                )
                .toList(growable: false),
          ),
        const RecordFieldSpec(
          key: 'dataSemeadura',
          label: 'Data de semeadura',
          kind: RecordFieldKind.date,
        ),
        const RecordFieldSpec(
          key: 'dataColheita',
          label: 'Data de colheita',
          kind: RecordFieldKind.date,
        ),
        const RecordFieldSpec(
          key: 'finalidadeCultivo',
          label: 'Finalidade do cultivo',
        ),
        const RecordFieldSpec(
          key: 'temperaturaMedia',
          label: 'Temperatura média',
          kind: RecordFieldKind.decimal,
        ),
        const RecordFieldSpec(
          key: 'produtividadeDesejada',
          label: 'Produtividade desejada',
          kind: RecordFieldKind.decimal,
        ),
        const RecordFieldSpec(
          key: 'unidadeDesejada',
          label: 'Unidade da produtividade desejada',
        ),
        const RecordFieldSpec(
          key: 'produtividadeMedia',
          label: 'Produtividade média da cultura',
          kind: RecordFieldKind.decimal,
        ),
        const RecordFieldSpec(
          key: 'unidadeMedia',
          label: 'Unidade da produtividade média',
        ),
        const RecordFieldSpec(
          key: 'desejadaSequeiro',
          label: 'Produtividade desejada sequeiro',
          kind: RecordFieldKind.decimal,
        ),
        const RecordFieldSpec(
          key: 'desejadaIrrigado',
          label: 'Produtividade desejada irrigado',
          kind: RecordFieldKind.decimal,
        ),
        const RecordFieldSpec(
          key: 'observadaSequeiro',
          label: 'Produtividade observada sequeiro',
          kind: RecordFieldKind.decimal,
        ),
        const RecordFieldSpec(
          key: 'observadaIrrigado',
          label: 'Produtividade observada irrigado',
          kind: RecordFieldKind.decimal,
        ),
        const RecordFieldSpec(
          key: 'mapaProdutividadePath',
          label: 'Caminho do mapa de produtividade',
        ),
        const RecordFieldSpec(
          key: 'contornoGeoJson',
          label: 'Contorno GeoJSON',
          kind: RecordFieldKind.multiline,
        ),
      ],
      initialValues: cultivation == null
          ? const {}
          : {
              'dataSemeadura': cultivation.sowingDate,
              'dataColheita': cultivation.harvestDate,
              'finalidadeCultivo': cultivation.purpose,
              'temperaturaMedia': cultivation.averageTemperature,
              'produtividadeDesejada': cultivation.targetYield,
              'unidadeDesejada': cultivation.targetYieldUnit,
              'produtividadeMedia': cultivation.averageCropYield,
              'unidadeMedia': cultivation.averageYieldUnit,
              'desejadaSequeiro': cultivation.targetRainfedYield,
              'desejadaIrrigado': cultivation.targetIrrigatedYield,
              'observadaSequeiro': cultivation.observedRainfedYield,
              'observadaIrrigado': cultivation.observedIrrigatedYield,
              'mapaProdutividadePath': cultivation.yieldMapPath,
              'contornoGeoJson': cultivation.boundaryGeoJson,
            },
    );
    if (values == null) return;
    if (!context.mounted) return;
    final input = _cultivationInput(values, cultivation);
    await _run(
      context,
      () => cultivation == null
          ? ref.read(agronomicApiProvider).createCultivation(input)
          : ref
              .read(agronomicApiProvider)
              .updateCultivation(cultivation.id, input),
      cultivation == null ? 'Cultivo criado.' : 'Cultivo atualizado.',
    );
  }

  CultivationInput _cultivationInput(
    Map<String, dynamic> values,
    Cultivation? fallback,
  ) {
    T? value<T>(String key, T? current) => values[key] as T? ?? current;
    return CultivationInput(
      fieldId: fieldId,
      cultureId: fallback?.cultureId ??
          int.tryParse(values['culturaId'] as String? ?? ''),
      sowingDate: value('dataSemeadura', fallback?.sowingDate),
      harvestDate: value('dataColheita', fallback?.harvestDate),
      purpose: value('finalidadeCultivo', fallback?.purpose),
      averageTemperature:
          value('temperaturaMedia', fallback?.averageTemperature),
      targetYield: value('produtividadeDesejada', fallback?.targetYield),
      targetYieldUnit: value('unidadeDesejada', fallback?.targetYieldUnit),
      averageCropYield: value('produtividadeMedia', fallback?.averageCropYield),
      averageYieldUnit: value('unidadeMedia', fallback?.averageYieldUnit),
      targetRainfedYield:
          value('desejadaSequeiro', fallback?.targetRainfedYield),
      targetIrrigatedYield:
          value('desejadaIrrigado', fallback?.targetIrrigatedYield),
      observedRainfedYield:
          value('observadaSequeiro', fallback?.observedRainfedYield),
      observedIrrigatedYield:
          value('observadaIrrigado', fallback?.observedIrrigatedYield),
      yieldMapPath: value('mapaProdutividadePath', fallback?.yieldMapPath),
      boundaryGeoJson: value('contornoGeoJson', fallback?.boundaryGeoJson),
    );
  }

  Future<void> _savePreviousCrop(
    BuildContext context,
    WidgetRef ref, [
    PreviousCrop? crop,
  ]) async {
    final values = await showAusterRecordForm(
      context: context,
      title: crop == null
          ? 'Nova cultura antecessora'
          : 'Editar cultura antecessora',
      fields: [
        if (crop == null)
          RecordFieldSpec(
            key: 'culturaId',
            label: 'Cultura',
            kind: RecordFieldKind.choice,
            required: true,
            options: cultures
                .map(
                  (culture) => RecordFieldOption(
                    value: culture.id.toString(),
                    label: culture.name,
                  ),
                )
                .toList(growable: false),
          ),
        const RecordFieldSpec(
          key: 'produtividadeMedia',
          label: 'Produtividade média',
          kind: RecordFieldKind.decimal,
        ),
        const RecordFieldSpec(
          key: 'ciclo',
          label: 'Ciclo em dias',
          kind: RecordFieldKind.integer,
        ),
        const RecordFieldSpec(key: 'safra', label: 'Safra'),
        const RecordFieldSpec(
          key: 'observacao',
          label: 'Observação',
          kind: RecordFieldKind.multiline,
        ),
      ],
      initialValues: crop == null
          ? const {}
          : {
              'produtividadeMedia': crop.averageYield,
              'ciclo': crop.cycle,
              'safra': crop.season,
              'observacao': crop.notes,
            },
    );
    if (values == null) return;
    if (!context.mounted) return;
    final input = PreviousCropInput(
      fieldId: fieldId,
      cultureId: crop?.cultureId ?? int.parse(values['culturaId'] as String),
      averageYield:
          values['produtividadeMedia'] as double? ?? crop?.averageYield,
      cycle: values['ciclo'] as int? ?? crop?.cycle,
      season: values['safra'] as String? ?? crop?.season,
      notes: values['observacao'] as String? ?? crop?.notes,
    );
    await _run(
      context,
      () => crop == null
          ? ref.read(agronomicApiProvider).createPreviousCrop(input)
          : ref.read(agronomicApiProvider).updatePreviousCrop(crop.id, input),
      crop == null
          ? 'Cultura antecessora criada.'
          : 'Cultura antecessora atualizada.',
    );
  }

  Future<void> _saveSoilData(
    BuildContext context,
    WidgetRef ref, [
    SoilData? soil,
  ]) async {
    final values = await showAusterRecordForm(
      context: context,
      title: soil == null ? 'Novos dados de solo' : 'Editar dados de solo',
      fields: const [
        RecordFieldSpec(
          key: 'dataCadastro',
          label: 'Data de cadastro',
          kind: RecordFieldKind.date,
          required: true,
        ),
        RecordFieldSpec(
          key: 'mediaMos',
          label: 'Média MOS',
          kind: RecordFieldKind.decimal,
        ),
        RecordFieldSpec(
          key: 'mediaArgila',
          label: 'Média de argila',
          kind: RecordFieldKind.decimal,
        ),
      ],
      initialValues: soil == null
          ? const {}
          : {
              'dataCadastro': soil.registrationDate,
              'mediaMos': soil.averageOrganicMatter,
              'mediaArgila': soil.averageClay,
            },
    );
    if (values == null) return;
    if (!context.mounted) return;
    final input = SoilDataInput(
      fieldId: fieldId,
      registrationDate: values['dataCadastro'] as String,
      averageOrganicMatter:
          values['mediaMos'] as double? ?? soil?.averageOrganicMatter,
      averageClay: values['mediaArgila'] as double? ?? soil?.averageClay,
    );
    await _run(
      context,
      () => soil == null
          ? ref.read(agronomicApiProvider).createSoilData(input)
          : ref.read(agronomicApiProvider).updateSoilData(soil.id, input),
      soil == null ? 'Dados de solo criados.' : 'Dados de solo atualizados.',
    );
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref, {
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
    if (confirmed != true) return;
    if (!context.mounted) return;
    await _run(context, action, 'Registro desativado.');
  }

  Future<void> _run(
    BuildContext context,
    Future<Object?> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      await onChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }
}
