import 'package:auster_agx_mobile/data/models/dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DashboardDemandItem mapeia JSON do endpoint /dashboard/demandas', () {
    final item = DashboardDemandItem.fromJson({
      'id': '01900000-0000-7000-8000-000000000010',
      'tipo': 'SMART_N',
      'codigo': 'SMN26001001',
      'aplicacao': '1a',
      'fazenda': 'Fazenda Modelo',
      'talhoes': ['Talhao 1'],
      'areaHa': 42.5,
      'cultura': 'Milho',
      'dataPrevista': '2026-10-15',
      'representanteId': null,
      'responsavelNome': 'Ana',
      'status': 'AGENDADA',
      'situacaoDados': 'DADOS_INCOMPLETOS',
      'situacaoMapeamento': 'SEM_IMAGENS',
      'metodoMapeamento': 'DRONE',
      'arquivada': false,
      'areaDeInteresse': 'Talhao 1',
      'retrabalho': false,
    });

    expect(item.codigo, 'SMN26001001');
    expect(item.talhoes, ['Talhao 1']);
    expect(item.status, 'AGENDADA');
    expect(item.toJson()['tipo'], 'SMART_N');
  });

  test('PageResponse usa campos reais da paginacao do backend', () {
    final page = PageResponse.fromJson({
      'conteudo': [
        {
          'id': '1',
          'tipo': 'SMART_N',
          'codigo': 'SMN26001001',
          'aplicacao': null,
          'fazenda': null,
          'talhoes': [],
          'areaHa': null,
          'cultura': null,
          'dataPrevista': null,
          'representanteId': null,
          'responsavelNome': null,
          'status': 'LISTADA',
          'situacaoDados': 'DADOS_INCOMPLETOS',
          'situacaoMapeamento': 'SEM_IMAGENS',
          'metodoMapeamento': null,
          'arquivada': false,
          'areaDeInteresse': null,
          'retrabalho': false,
        },
      ],
      'totalElementos': 1,
      'totalPaginas': 1,
      'pagina': 0,
      'tamanho': 20,
    }, DashboardDemandItem.fromJson);

    expect(page.conteudo, hasLength(1));
    expect(page.totalElementos, 1);
    expect(page.pagina, 0);
  });
}
