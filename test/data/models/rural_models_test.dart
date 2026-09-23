import 'package:auster_agx_mobile/data/models/rural_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fazenda converte agregados e números retornados pela API', () {
    final farm = Farm.fromJson({
      'id': 'fazenda-1',
      'nome': 'Fazenda Horizonte',
      'areaHa': 120,
      'areaCultivavel': '110.5',
      'ativo': true,
      'culturas': [
        {'id': 1, 'nome': 'Soja'},
      ],
      'equipamentos': [
        {'id': 4, 'nome': 'Pulverizador'},
      ],
    });

    expect(farm.areaHa, 120.0);
    expect(farm.cultivableArea, 110.5);
    expect(farm.cultures.single['nome'], 'Soja');
    expect(farm.equipment.single['id'], 4);
  });

  test('payload de cliente remove opcionais vazios e preserva obrigatórios',
      () {
    const input = ClientInput(
      userId: 'usuario-1',
      documentType: 'CPF',
      documentNumber: '12345678900',
      tradeName: 'Cliente Teste',
      billingEmail: 'financeiro@teste.com',
      phone: '',
    );

    final createPayload = input.toJson(includeUser: true);
    final updatePayload = input.toJson(includeUser: false);

    expect(createPayload['usuarioId'], 'usuario-1');
    expect(createPayload.containsKey('telefone'), isFalse);
    expect(updatePayload.containsKey('usuarioId'), isFalse);
  });

  test('payload de talhão não envia fazenda durante atualização', () {
    const input = FieldInput(
      farmId: 'fazenda-1',
      name: 'Talhão A',
      irrigated: true,
    );

    expect(input.toJson(includeFarm: true)['fazendaId'], 'fazenda-1');
    expect(input.toJson(includeFarm: false).containsKey('fazendaId'), isFalse);
  });
}
