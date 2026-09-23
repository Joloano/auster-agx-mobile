import 'page_response.dart';

class Culture {
  const Culture({
    required this.id,
    required this.name,
    required this.precocity,
    required this.group,
    required this.active,
    required this.demandTypes,
    required this.servesAllServices,
    required this.createdAt,
  });

  factory Culture.fromJson(JsonMap json) => Culture(
        id: _int(json['id']) ?? 0,
        name: _string(json['nome']) ?? '',
        precocity: _string(json['precocidade']),
        group: _string(json['grupoCultura']),
        active: _bool(json['ativo'], fallback: true),
        demandTypes: _strings(json['tiposDemanda']),
        servesAllServices: _bool(json['atendeTodosServicos']),
        createdAt: _string(json['createdAt']),
      );

  final int id;
  final String name;
  final String? precocity;
  final String? group;
  final bool active;
  final List<String> demandTypes;
  final bool servesAllServices;
  final String? createdAt;
}

class CultureInput {
  const CultureInput({
    required this.name,
    this.precocity,
    this.group,
    this.demandTypes = const [],
  });

  final String name;
  final String? precocity;
  final String? group;
  final List<String> demandTypes;

  JsonMap toJson() => _withoutNulls({
        'nome': name.trim(),
        'precocidade': _text(precocity),
        'grupoCultura': _text(group),
        'tiposDemanda': demandTypes,
      });
}

class PhenologicalStage {
  const PhenologicalStage({
    required this.id,
    required this.cultureId,
    required this.cultureName,
    required this.name,
    required this.order,
    required this.efa,
    required this.active,
  });

  factory PhenologicalStage.fromJson(JsonMap json) => PhenologicalStage(
        id: _int(json['id']) ?? 0,
        cultureId: _int(json['culturaId']),
        cultureName: _string(json['culturaNome']),
        name: _string(json['nome']) ?? '',
        order: _int(json['ordem']),
        efa: _double(json['efa']),
        active: _bool(json['ativo'], fallback: true),
      );

  final int id;
  final int? cultureId;
  final String? cultureName;
  final String name;
  final int? order;
  final double? efa;
  final bool active;
}

class PhenologicalStageInput {
  const PhenologicalStageInput({
    required this.name,
    this.cultureId,
    this.order,
    this.efa,
  });

  final String name;
  final int? cultureId;
  final int? order;
  final double? efa;

  JsonMap toJson({bool nameOnly = false}) => _withoutNulls({
        'nome': name.trim(),
        if (!nameOnly) 'culturaId': cultureId,
        if (!nameOnly) 'ordem': order,
        if (!nameOnly) 'efa': efa,
      });
}

class Cultivation {
  const Cultivation({
    required this.id,
    required this.fieldId,
    required this.cultureId,
    required this.cultureName,
    required this.sowingDate,
    required this.harvestDate,
    required this.referenceDate,
    required this.purpose,
    required this.averageTemperature,
    required this.targetYield,
    required this.targetYieldUnit,
    required this.averageCropYield,
    required this.averageYieldUnit,
    required this.targetRainfedYield,
    required this.targetIrrigatedYield,
    required this.observedIrrigatedYield,
    required this.observedRainfedYield,
    required this.yieldMapPath,
    required this.boundaryGeoJson,
    required this.active,
  });

  factory Cultivation.fromJson(JsonMap json) => Cultivation(
        id: _string(json['id']) ?? '',
        fieldId: _string(json['talhaoId']) ?? '',
        cultureId: _int(json['culturaId']) ?? 0,
        cultureName: _string(json['culturaNome']) ?? '',
        sowingDate: _string(json['dataSemeadura']),
        harvestDate: _string(json['dataColheita']),
        referenceDate: _string(json['dataReferencia']),
        purpose: _string(json['finalidadeCultivo']),
        averageTemperature: _double(json['temperaturaMedia']),
        targetYield: _double(json['produtividadeDesejada']),
        targetYieldUnit: _string(json['unidadeMedidaProdutividadeDesejada']),
        averageCropYield: _double(json['produtividadeMediaCultura']),
        averageYieldUnit: _string(json['unidadeMedidaProdutividadeMedia']),
        targetRainfedYield: _double(json['produtividadeDesejadaSequeiro']),
        targetIrrigatedYield: _double(json['produtividadeDesejadaIrrigado']),
        observedIrrigatedYield: _double(json['produtividadeObservadaIrrigado']),
        observedRainfedYield: _double(json['produtividadeObservadaSequeiro']),
        yieldMapPath: _string(json['mapaProdutividadePath']),
        boundaryGeoJson: _string(json['contornoGeoJson']),
        active: _bool(json['ativo'], fallback: true),
      );

  CultivationInput toUpdateInput() => CultivationInput(
        sowingDate: sowingDate,
        harvestDate: harvestDate,
        purpose: purpose,
        averageTemperature: averageTemperature,
        targetYield: targetYield,
        targetYieldUnit: targetYieldUnit,
        averageCropYield: averageCropYield,
        averageYieldUnit: averageYieldUnit,
        targetRainfedYield: targetRainfedYield,
        targetIrrigatedYield: targetIrrigatedYield,
        observedIrrigatedYield: observedIrrigatedYield,
        observedRainfedYield: observedRainfedYield,
        yieldMapPath: yieldMapPath,
        boundaryGeoJson: boundaryGeoJson,
      );

  final String id;
  final String fieldId;
  final int cultureId;
  final String cultureName;
  final String? sowingDate;
  final String? harvestDate;
  final String? referenceDate;
  final String? purpose;
  final double? averageTemperature;
  final double? targetYield;
  final String? targetYieldUnit;
  final double? averageCropYield;
  final String? averageYieldUnit;
  final double? targetRainfedYield;
  final double? targetIrrigatedYield;
  final double? observedIrrigatedYield;
  final double? observedRainfedYield;
  final String? yieldMapPath;
  final String? boundaryGeoJson;
  final bool active;
}

class CultivationInput {
  const CultivationInput({
    this.fieldId,
    this.cultureId,
    this.sowingDate,
    this.harvestDate,
    this.purpose,
    this.averageTemperature,
    this.targetYield,
    this.targetYieldUnit,
    this.averageCropYield,
    this.averageYieldUnit,
    this.targetRainfedYield,
    this.targetIrrigatedYield,
    this.observedIrrigatedYield,
    this.observedRainfedYield,
    this.yieldMapPath,
    this.boundaryGeoJson,
  });

  final String? fieldId;
  final int? cultureId;
  final String? sowingDate;
  final String? harvestDate;
  final String? purpose;
  final double? averageTemperature;
  final double? targetYield;
  final String? targetYieldUnit;
  final double? averageCropYield;
  final String? averageYieldUnit;
  final double? targetRainfedYield;
  final double? targetIrrigatedYield;
  final double? observedIrrigatedYield;
  final double? observedRainfedYield;
  final String? yieldMapPath;
  final String? boundaryGeoJson;

  JsonMap toJson({required bool includeRelations}) => _withoutNulls({
        if (includeRelations) 'talhaoId': fieldId,
        if (includeRelations) 'culturaId': cultureId,
        'dataSemeadura': _text(sowingDate),
        'dataColheita': _text(harvestDate),
        'finalidadeCultivo': _text(purpose),
        'temperaturaMedia': averageTemperature,
        'produtividadeDesejada': targetYield,
        'unidadeMedidaProdutividadeDesejada': _text(targetYieldUnit),
        'produtividadeMediaCultura': averageCropYield,
        'unidadeMedidaProdutividadeMedia': _text(averageYieldUnit),
        'produtividadeDesejadaSequeiro': targetRainfedYield,
        'produtividadeDesejadaIrrigado': targetIrrigatedYield,
        'produtividadeObservadaIrrigado': observedIrrigatedYield,
        'produtividadeObservadaSequeiro': observedRainfedYield,
        'mapaProdutividadePath': _text(yieldMapPath),
        'contornoGeoJson': _text(boundaryGeoJson),
      });
}

class PreviousCrop {
  const PreviousCrop({
    required this.id,
    required this.fieldId,
    required this.cultureId,
    required this.cultureName,
    required this.averageYield,
    required this.cycle,
    required this.notes,
    required this.season,
    required this.referenceDate,
    required this.active,
  });

  factory PreviousCrop.fromJson(JsonMap json) => PreviousCrop(
        id: _string(json['id']) ?? '',
        fieldId: _string(json['talhaoId']) ?? '',
        cultureId: _int(json['culturaId']) ?? 0,
        cultureName: _string(json['culturaNome']) ?? '',
        averageYield: _double(json['produtividadeMedia']),
        cycle: _int(json['ciclo']),
        notes: _string(json['observacao']),
        season: _string(json['safra']),
        referenceDate: _string(json['dataReferencia']),
        active: _bool(json['ativo'], fallback: true),
      );

  final String id;
  final String fieldId;
  final int cultureId;
  final String cultureName;
  final double? averageYield;
  final int? cycle;
  final String? notes;
  final String? season;
  final String? referenceDate;
  final bool active;
}

class PreviousCropInput {
  const PreviousCropInput({
    this.fieldId,
    this.cultureId,
    this.averageYield,
    this.cycle,
    this.notes,
    this.season,
  });

  final String? fieldId;
  final int? cultureId;
  final double? averageYield;
  final int? cycle;
  final String? notes;
  final String? season;

  JsonMap toJson({required bool includeRelations}) => _withoutNulls({
        if (includeRelations) 'talhaoId': fieldId,
        if (includeRelations) 'culturaId': cultureId,
        'produtividadeMedia': averageYield,
        'ciclo': cycle,
        'observacao': _text(notes),
        'safra': _text(season),
      });
}

class SoilData {
  const SoilData({
    required this.id,
    required this.fieldId,
    required this.registrationDate,
    required this.averageOrganicMatter,
    required this.averageClay,
    required this.active,
  });

  factory SoilData.fromJson(JsonMap json) => SoilData(
        id: _string(json['id']) ?? '',
        fieldId: _string(json['talhaoId']) ?? '',
        registrationDate: _string(json['dataCadastro']) ?? '',
        averageOrganicMatter: _double(json['mediaMos']),
        averageClay: _double(json['mediaArgila']),
        active: _bool(json['ativo'], fallback: true),
      );

  final String id;
  final String fieldId;
  final String registrationDate;
  final double? averageOrganicMatter;
  final double? averageClay;
  final bool active;
}

class SoilDataInput {
  const SoilDataInput({
    required this.registrationDate,
    this.fieldId,
    this.averageOrganicMatter,
    this.averageClay,
  });

  final String? fieldId;
  final String registrationDate;
  final double? averageOrganicMatter;
  final double? averageClay;

  JsonMap toJson({required bool includeField}) => _withoutNulls({
        if (includeField) 'talhaoId': fieldId,
        'dataCadastro': registrationDate,
        'mediaMos': averageOrganicMatter,
        'mediaArgila': averageClay,
      });
}

class Fertilization {
  const Fertilization({
    required this.id,
    required this.demandId,
    required this.type,
    required this.fertilizerName,
    required this.stageId,
    required this.stageName,
    required this.irrigatedRate,
    required this.rainfedRate,
    required this.estimatedApplicationDate,
    required this.active,
  });

  factory Fertilization.fromJson(JsonMap json) => Fertilization(
        id: _string(json['id']) ?? '',
        demandId: _string(json['demandaId']) ?? '',
        type: _string(json['tipoAdubacao']) ?? '',
        fertilizerName: _string(json['nomeFertilizante']),
        stageId: _int(json['estadioFenologicoId']),
        stageName: _string(json['estadioFenologicoNome']),
        irrigatedRate: _double(json['taxaAplicacaoIrrigado']),
        rainfedRate: _double(json['taxaAplicacaoSequeiro']),
        estimatedApplicationDate: _string(json['dataEstimadaAplicacao']),
        active: _bool(json['ativo'], fallback: true),
      );

  final String id;
  final String demandId;
  final String type;
  final String? fertilizerName;
  final int? stageId;
  final String? stageName;
  final double? irrigatedRate;
  final double? rainfedRate;
  final String? estimatedApplicationDate;
  final bool active;
}

class FertilizationInput {
  const FertilizationInput({
    required this.type,
    this.demandId,
    this.fertilizerName,
    this.stageId,
    this.irrigatedRate,
    this.rainfedRate,
    this.estimatedApplicationDate,
  });

  final String? demandId;
  final String type;
  final String? fertilizerName;
  final int? stageId;
  final double? irrigatedRate;
  final double? rainfedRate;
  final String? estimatedApplicationDate;

  JsonMap toJson({required bool includeDemand}) => _withoutNulls({
        if (includeDemand) 'demandaId': demandId,
        'tipoAdubacao': type,
        'nomeFertilizante': _text(fertilizerName),
        'estadioFenologicoId': stageId,
        'taxaAplicacaoIrrigado': irrigatedRate,
        'taxaAplicacaoSequeiro': rainfedRate,
        'dataEstimadaAplicacao': _text(estimatedApplicationDate),
      });
}

class NitrogenManagement {
  const NitrogenManagement({
    required this.id,
    required this.demandId,
    required this.averageRateRestrictionActive,
    required this.averageMinIrrigated,
    required this.averageMaxIrrigated,
    required this.averageMinRainfed,
    required this.averageMaxRainfed,
    required this.pointRateRestrictionActive,
    required this.pointMinIrrigated,
    required this.pointMaxIrrigated,
    required this.pointMinRainfed,
    required this.pointMaxRainfed,
    required this.controlActive,
    required this.controlRateIrrigated,
    required this.controlRateRainfed,
    required this.equipmentId,
    required this.equipmentName,
    required this.totalInputAvailable,
    required this.active,
  });

  factory NitrogenManagement.fromJson(JsonMap json) => NitrogenManagement(
        id: _string(json['id']) ?? '',
        demandId: _string(json['demandaId']) ?? '',
        averageRateRestrictionActive: _bool(json['restricaoTaxaMediaAtiva']),
        averageMinIrrigated: _double(json['restricaoTaxaMediaMinIrrigado']),
        averageMaxIrrigated: _double(json['restricaoTaxaMediaMaxIrrigado']),
        averageMinRainfed: _double(json['restricaoTaxaMediaMinSequeiro']),
        averageMaxRainfed: _double(json['restricaoTaxaMediaMaxSequeiro']),
        pointRateRestrictionActive: _bool(json['restricaoTaxaPontualAtiva']),
        pointMinIrrigated: _double(json['restricaoTaxaPontualMinIrrigado']),
        pointMaxIrrigated: _double(json['restricaoTaxaPontualMaxIrrigado']),
        pointMinRainfed: _double(json['restricaoTaxaPontualMinSequeiro']),
        pointMaxRainfed: _double(json['restricaoTaxaPontualMaxSequeiro']),
        controlActive: _bool(json['testemunhaAtiva']),
        controlRateIrrigated: _double(json['testemunhaTaxaIrrigado']),
        controlRateRainfed: _double(json['testemunhaTaxaSequeiro']),
        equipmentId: _int(json['equipamentoAplicacaoId']),
        equipmentName: _string(json['equipamentoAplicacaoNome']),
        totalInputAvailable: _double(json['totalInsumoDisponivel']),
        active: _bool(json['ativo'], fallback: true),
      );

  final String id;
  final String demandId;
  final bool averageRateRestrictionActive;
  final double? averageMinIrrigated;
  final double? averageMaxIrrigated;
  final double? averageMinRainfed;
  final double? averageMaxRainfed;
  final bool pointRateRestrictionActive;
  final double? pointMinIrrigated;
  final double? pointMaxIrrigated;
  final double? pointMinRainfed;
  final double? pointMaxRainfed;
  final bool controlActive;
  final double? controlRateIrrigated;
  final double? controlRateRainfed;
  final int? equipmentId;
  final String? equipmentName;
  final double? totalInputAvailable;
  final bool active;
}

class NitrogenManagementInput {
  const NitrogenManagementInput({
    required this.averageRateRestrictionActive,
    required this.pointRateRestrictionActive,
    required this.controlActive,
    this.demandId,
    this.averageMinIrrigated,
    this.averageMaxIrrigated,
    this.averageMinRainfed,
    this.averageMaxRainfed,
    this.pointMinIrrigated,
    this.pointMaxIrrigated,
    this.pointMinRainfed,
    this.pointMaxRainfed,
    this.controlRateIrrigated,
    this.controlRateRainfed,
    this.equipmentId,
    this.totalInputAvailable,
  });

  final String? demandId;
  final bool averageRateRestrictionActive;
  final double? averageMinIrrigated;
  final double? averageMaxIrrigated;
  final double? averageMinRainfed;
  final double? averageMaxRainfed;
  final bool pointRateRestrictionActive;
  final double? pointMinIrrigated;
  final double? pointMaxIrrigated;
  final double? pointMinRainfed;
  final double? pointMaxRainfed;
  final bool controlActive;
  final double? controlRateIrrigated;
  final double? controlRateRainfed;
  final int? equipmentId;
  final double? totalInputAvailable;

  JsonMap toJson({required bool includeDemand}) => _withoutNulls({
        if (includeDemand) 'demandaId': demandId,
        'restricaoTaxaMediaAtiva': averageRateRestrictionActive,
        'restricaoTaxaMediaMinIrrigado': averageMinIrrigated,
        'restricaoTaxaMediaMaxIrrigado': averageMaxIrrigated,
        'restricaoTaxaMediaMinSequeiro': averageMinRainfed,
        'restricaoTaxaMediaMaxSequeiro': averageMaxRainfed,
        'restricaoTaxaPontualAtiva': pointRateRestrictionActive,
        'restricaoTaxaPontualMinIrrigado': pointMinIrrigated,
        'restricaoTaxaPontualMaxIrrigado': pointMaxIrrigated,
        'restricaoTaxaPontualMinSequeiro': pointMinRainfed,
        'restricaoTaxaPontualMaxSequeiro': pointMaxRainfed,
        'testemunhaAtiva': controlActive,
        'testemunhaTaxaIrrigado': controlRateIrrigated,
        'testemunhaTaxaSequeiro': controlRateRainfed,
        'equipamentoAplicacaoId': equipmentId,
        'totalInsumoDisponivel': totalInputAvailable,
      });
}

class SmartBrakePrescription {
  const SmartBrakePrescription({
    required this.id,
    required this.demandId,
    required this.restrictionType,
    required this.product,
    required this.stageId,
    required this.stageName,
    required this.minimumIrrigatedRate,
    required this.minimumRainfedRate,
    required this.averageIrrigatedRate,
    required this.averageRainfedRate,
    required this.maximumIrrigatedRate,
    required this.maximumRainfedRate,
    required this.zeroRate,
    required this.controlActive,
    required this.controlRateIrrigated,
    required this.controlRateRainfed,
    required this.equipmentId,
    required this.equipmentName,
    required this.notes,
    required this.active,
  });

  factory SmartBrakePrescription.fromJson(JsonMap json) =>
      SmartBrakePrescription(
        id: _string(json['id']) ?? '',
        demandId: _string(json['demandaId']) ?? '',
        restrictionType: _string(json['tipoRestricaoTaxa']),
        product: _string(json['produtoUtilizado']),
        stageId: _int(json['estadioFenologicoId']),
        stageName: _string(json['estadioFenologicoNome']),
        minimumIrrigatedRate: _double(json['taxaMinimaIrrigado']),
        minimumRainfedRate: _double(json['taxaMinimaSequeiro']),
        averageIrrigatedRate: _double(json['taxaMediaIrrigado']),
        averageRainfedRate: _double(json['taxaMediaSequeiro']),
        maximumIrrigatedRate: _double(json['taxaMaximaIrrigado']),
        maximumRainfedRate: _double(json['taxaMaximaSequeiro']),
        zeroRate: _bool(json['taxaZero']),
        controlActive: _bool(json['testemunhaAtiva']),
        controlRateIrrigated: _double(json['testemunhaTaxaIrrigado']),
        controlRateRainfed: _double(json['testemunhaTaxaSequeiro']),
        equipmentId: _int(json['equipamentoAplicacaoId']),
        equipmentName: _string(json['equipamentoAplicacaoNome']),
        notes: _string(json['observacoes']),
        active: _bool(json['ativo'], fallback: true),
      );

  final String id;
  final String demandId;
  final String? restrictionType;
  final String? product;
  final int? stageId;
  final String? stageName;
  final double? minimumIrrigatedRate;
  final double? minimumRainfedRate;
  final double? averageIrrigatedRate;
  final double? averageRainfedRate;
  final double? maximumIrrigatedRate;
  final double? maximumRainfedRate;
  final bool zeroRate;
  final bool controlActive;
  final double? controlRateIrrigated;
  final double? controlRateRainfed;
  final int? equipmentId;
  final String? equipmentName;
  final String? notes;
  final bool active;
}

class SmartBrakePrescriptionInput {
  const SmartBrakePrescriptionInput({
    required this.zeroRate,
    required this.controlActive,
    this.demandId,
    this.restrictionType,
    this.product,
    this.stageId,
    this.minimumIrrigatedRate,
    this.minimumRainfedRate,
    this.averageIrrigatedRate,
    this.averageRainfedRate,
    this.maximumIrrigatedRate,
    this.maximumRainfedRate,
    this.controlRateIrrigated,
    this.controlRateRainfed,
    this.equipmentId,
    this.notes,
  });

  final String? demandId;
  final String? restrictionType;
  final String? product;
  final int? stageId;
  final double? minimumIrrigatedRate;
  final double? minimumRainfedRate;
  final double? averageIrrigatedRate;
  final double? averageRainfedRate;
  final double? maximumIrrigatedRate;
  final double? maximumRainfedRate;
  final bool zeroRate;
  final bool controlActive;
  final double? controlRateIrrigated;
  final double? controlRateRainfed;
  final int? equipmentId;
  final String? notes;

  JsonMap toJson({required bool includeDemand}) => _withoutNulls({
        if (includeDemand) 'demandaId': demandId,
        'tipoRestricaoTaxa': _text(restrictionType),
        'produtoUtilizado': _text(product),
        'estadioFenologicoId': stageId,
        'taxaMinimaIrrigado': minimumIrrigatedRate,
        'taxaMinimaSequeiro': minimumRainfedRate,
        'taxaMediaIrrigado': averageIrrigatedRate,
        'taxaMediaSequeiro': averageRainfedRate,
        'taxaMaximaIrrigado': maximumIrrigatedRate,
        'taxaMaximaSequeiro': maximumRainfedRate,
        'taxaZero': zeroRate,
        'testemunhaAtiva': controlActive,
        'testemunhaTaxaIrrigado': controlRateIrrigated,
        'testemunhaTaxaSequeiro': controlRateRainfed,
        'equipamentoAplicacaoId': equipmentId,
        'observacoes': _text(notes),
      });
}

class SmartSeedingPrescription {
  const SmartSeedingPrescription({
    required this.id,
    required this.demandId,
    required this.rowSpacing,
    required this.thousandSeedWeight,
    required this.restrictionType,
    required this.minimumIrrigatedRate,
    required this.minimumRainfedRate,
    required this.averageIrrigatedRate,
    required this.averageRainfedRate,
    required this.maximumIrrigatedRate,
    required this.maximumRainfedRate,
    required this.controlActive,
    required this.controlRateIrrigated,
    required this.controlRateRainfed,
    required this.totalSeedsAvailable,
    required this.seederId,
    required this.seederName,
    required this.notes,
    required this.active,
  });

  factory SmartSeedingPrescription.fromJson(JsonMap json) =>
      SmartSeedingPrescription(
        id: _string(json['id']) ?? '',
        demandId: _string(json['demandaId']) ?? '',
        rowSpacing: _double(json['distanciaEntreLinhas']),
        thousandSeedWeight: _double(json['pesoMilSementes']),
        restrictionType: _string(json['tipoRestricaoTaxa']),
        minimumIrrigatedRate: _double(json['taxaMinimaIrrigado']),
        minimumRainfedRate: _double(json['taxaMinimaSequeiro']),
        averageIrrigatedRate: _double(json['taxaMediaIrrigado']),
        averageRainfedRate: _double(json['taxaMediaSequeiro']),
        maximumIrrigatedRate: _double(json['taxaMaximaIrrigado']),
        maximumRainfedRate: _double(json['taxaMaximaSequeiro']),
        controlActive: _bool(json['testemunhaAtiva']),
        controlRateIrrigated: _double(json['testemunhaTaxaIrrigado']),
        controlRateRainfed: _double(json['testemunhaTaxaSequeiro']),
        totalSeedsAvailable: _double(json['totalSementesDisponivel']),
        seederId: _int(json['modeloSemeadoraId']),
        seederName: _string(json['modeloSemeadoraNome']),
        notes: _string(json['observacoes']),
        active: _bool(json['ativo'], fallback: true),
      );

  final String id;
  final String demandId;
  final double? rowSpacing;
  final double? thousandSeedWeight;
  final String? restrictionType;
  final double? minimumIrrigatedRate;
  final double? minimumRainfedRate;
  final double? averageIrrigatedRate;
  final double? averageRainfedRate;
  final double? maximumIrrigatedRate;
  final double? maximumRainfedRate;
  final bool controlActive;
  final double? controlRateIrrigated;
  final double? controlRateRainfed;
  final double? totalSeedsAvailable;
  final int? seederId;
  final String? seederName;
  final String? notes;
  final bool active;
}

class SmartSeedingPrescriptionInput {
  const SmartSeedingPrescriptionInput({
    required this.controlActive,
    this.demandId,
    this.rowSpacing,
    this.thousandSeedWeight,
    this.restrictionType,
    this.minimumIrrigatedRate,
    this.minimumRainfedRate,
    this.averageIrrigatedRate,
    this.averageRainfedRate,
    this.maximumIrrigatedRate,
    this.maximumRainfedRate,
    this.controlRateIrrigated,
    this.controlRateRainfed,
    this.totalSeedsAvailable,
    this.seederId,
    this.notes,
  });

  final String? demandId;
  final double? rowSpacing;
  final double? thousandSeedWeight;
  final String? restrictionType;
  final double? minimumIrrigatedRate;
  final double? minimumRainfedRate;
  final double? averageIrrigatedRate;
  final double? averageRainfedRate;
  final double? maximumIrrigatedRate;
  final double? maximumRainfedRate;
  final bool controlActive;
  final double? controlRateIrrigated;
  final double? controlRateRainfed;
  final double? totalSeedsAvailable;
  final int? seederId;
  final String? notes;

  JsonMap toJson({required bool includeDemand}) => _withoutNulls({
        if (includeDemand) 'demandaId': demandId,
        'distanciaEntreLinhas': rowSpacing,
        'pesoMilSementes': thousandSeedWeight,
        'tipoRestricaoTaxa': _text(restrictionType),
        'taxaMinimaIrrigado': minimumIrrigatedRate,
        'taxaMinimaSequeiro': minimumRainfedRate,
        'taxaMediaIrrigado': averageIrrigatedRate,
        'taxaMediaSequeiro': averageRainfedRate,
        'taxaMaximaIrrigado': maximumIrrigatedRate,
        'taxaMaximaSequeiro': maximumRainfedRate,
        'testemunhaAtiva': controlActive,
        'testemunhaTaxaIrrigado': controlRateIrrigated,
        'testemunhaTaxaSequeiro': controlRateRainfed,
        'totalSementesDisponivel': totalSeedsAvailable,
        'modeloSemeadoraId': seederId,
        'observacoes': _text(notes),
      });
}

String? _string(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

String? _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool _bool(Object? value, {bool fallback = false}) {
  return value is bool ? value : fallback;
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}

JsonMap _withoutNulls(JsonMap values) {
  return Map<String, dynamic>.fromEntries(
    values.entries.where((entry) => entry.value != null),
  );
}
