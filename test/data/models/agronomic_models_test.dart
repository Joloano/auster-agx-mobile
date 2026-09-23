import 'package:auster_agx_mobile/data/models/agronomic_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cultura preserva serviços contratados e classificação', () {
    final culture = Culture.fromJson({
      'id': 7,
      'nome': 'Soja',
      'precocidade': 'PRECOCE',
      'grupoCultura': 'SOJA',
      'ativo': true,
      'tiposDemanda': ['SMART_N', 'SMART_SEEDING'],
      'atendeTodosServicos': false,
      'createdAt': '2026-09-20T10:00:00Z',
    });

    expect(culture.id, 7);
    expect(culture.group, 'SOJA');
    expect(culture.demandTypes, ['SMART_N', 'SMART_SEEDING']);
  });

  test('estádio fenológico preserva EFA decimal', () {
    final stage = PhenologicalStage.fromJson({
      'id': 12,
      'culturaId': 7,
      'culturaNome': 'Soja',
      'nome': 'V3',
      'ordem': 3,
      'efa': 0.375,
      'ativo': true,
    });

    expect(stage.efa, 0.375);
    expect(
      const PhenologicalStageInput(name: 'V3', efa: 0.375).toJson()['efa'],
      0.375,
    );
  });

  test('atualização de cultivo mantém todos os campos existentes', () {
    final cultivation = Cultivation.fromJson({
      'id': 'cultivo-1',
      'talhaoId': 'talhao-1',
      'culturaId': 3,
      'culturaNome': 'Milho',
      'dataSemeadura': '2026-09-01',
      'dataColheita': '2027-01-15',
      'finalidadeCultivo': 'Grãos',
      'temperaturaMedia': 24.5,
      'produtividadeDesejada': 100,
      'unidadeMedidaProdutividadeDesejada': 'SC_HA',
      'produtividadeMediaCultura': 90,
      'unidadeMedidaProdutividadeMedia': 'SC_HA',
      'produtividadeDesejadaSequeiro': 85,
      'produtividadeDesejadaIrrigado': 110,
      'produtividadeObservadaIrrigado': 105,
      'produtividadeObservadaSequeiro': 80,
      'mapaProdutividadePath': '/mapas/produtividade.geojson',
      'contornoGeoJson': '{"type":"Polygon"}',
      'ativo': true,
    });

    final payload = cultivation.toUpdateInput().toJson(
          includeRelations: false,
        );

    expect(payload['dataSemeadura'], '2026-09-01');
    expect(payload['produtividadeDesejadaIrrigado'], 110);
    expect(payload['mapaProdutividadePath'], '/mapas/produtividade.geojson');
    expect(payload, isNot(contains('talhaoId')));
    expect(payload, isNot(contains('culturaId')));
  });

  test('manejo de nitrogênio separa criação e atualização', () {
    const input = NitrogenManagementInput(
      demandId: 'demanda-1',
      averageRateRestrictionActive: true,
      averageMinIrrigated: 20,
      averageMaxIrrigated: 40,
      pointRateRestrictionActive: false,
      controlActive: true,
      controlRateIrrigated: 25,
    );

    expect(input.toJson(includeDemand: true)['demandaId'], 'demanda-1');
    expect(input.toJson(includeDemand: false), isNot(contains('demandaId')));
    expect(
      input.toJson(includeDemand: false)['restricaoTaxaMediaAtiva'],
      isTrue,
    );
  });

  test('prescrição smart seeding envia matriz de taxas e equipamento', () {
    const input = SmartSeedingPrescriptionInput(
      demandId: 'demanda-2',
      rowSpacing: 0.45,
      thousandSeedWeight: 182,
      restrictionType: 'MEDIA',
      minimumRainfedRate: 250000,
      maximumIrrigatedRate: 360000,
      controlActive: false,
      totalSeedsAvailable: 1200000,
      seederId: 4,
    );

    final payload = input.toJson(includeDemand: true);
    expect(payload['distanciaEntreLinhas'], 0.45);
    expect(payload['taxaMinimaSequeiro'], 250000);
    expect(payload['modeloSemeadoraId'], 4);
  });
}
