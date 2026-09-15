import 'package:auster_agx_mobile/data/models/demanda_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DemandaDetail mapeia payload agregado real do backend', () {
    final detail = DemandaDetail.fromJson({
      'demanda': {
        'id': 'demanda-1',
        'pedidoId': 'pedido-1',
        'pedidoCodigo': 'PED26001',
        'clienteNome': 'Cliente Modelo',
        'fazendaNomes': ['Fazenda Modelo'],
        'codigoDemanda': 'SMN26001001',
        'tipo': 'SMART_N',
        'status': 'Listada',
        'statusChave': 'LISTADA',
        'situacaoDados': 'DADOS_PREENCHIDOS',
        'situacaoMapeamento': 'IMAGENS_DISPONIVEIS',
        'retrabalho': false,
        'demandaOrigemId': null,
        'numeroAplicacao': 1,
        'representanteId': 'rep-1',
        'representanteNome': 'Ana',
        'prazo': '2026-10-15',
        'areaDeInteresse': 'Talhao 1',
        'grupoIds': ['grupo-1'],
        'sensoriamentoIds': ['sens-1'],
        'ativo': true,
        'createdAt': '2026-09-14T00:00:00',
      },
      'pedido': {'id': 'pedido-1', 'codigo': 'PED26001', 'apelido': 'Safra'},
      'cliente': {'id': 'cliente-1', 'nomeFantasia': 'Cliente Modelo'},
      'fazendas': [
        {'id': 'fazenda-1', 'nome': 'Fazenda Modelo'}
      ],
      'grupos': [
        {
          'id': 'grupo-1',
          'nome': 'Grupo 1',
          'talhoes': [
            {
              'id': 'talhao-1',
              'nome': 'Talhao 1',
              'fazendaId': 'fazenda-1',
              'fazendaNome': 'Fazenda Modelo',
            }
          ],
        }
      ],
      'sensoriamentos': [
        {
          'id': 'sens-1',
          'codigoMapeamento': 'MAP26001001',
          'fonte': 'DRONE',
          'pilotoId': 'piloto-1',
          'pilotoNome': 'Piloto',
          'satelite': null,
          'mapeamentoOrigemId': null,
          'numeroMapeamento': 1,
          'status': 'MAPEAMENTO_CONCLUIDO',
        }
      ],
      'culturas': [
        {'id': 1, 'nome': 'Milho'}
      ],
      'demandaOrigem': null,
      'derivadas': [
        {
          'id': 'demanda-2',
          'codigoDemanda': 'SMN26001002',
          'tipo': 'SMART_N',
          'status': 'AGENDADA',
          'numeroAplicacao': 2,
          'retrabalho': false,
        }
      ],
    });

    expect(detail.pedido.apelido, 'Safra');
    expect(detail.grupos.single.talhoes.single.nome, 'Talhao 1');
    expect(detail.sensoriamentos.single.codigoMapeamento, 'MAP26001001');
    expect(detail.culturas.single.nome, 'Milho');
    expect(detail.derivadas.single.codigoDemanda, 'SMN26001002');
  });
}
