import 'package:auster_agx_mobile/data/models/dashboard_models.dart';
import 'package:auster_agx_mobile/data/models/demanda_status_rules.dart';
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

  test(
      'DashboardOverview mapeia metricas completas do endpoint /dashboard/resumo',
      () {
    final overview = DashboardOverview.fromJson({
      'escopo': 'GLOBAL',
      'totalClientes': 12,
      'totalFazendas': 5,
      'totalTalhoes': 41,
      'totalVinculosAtivos': 9,
      'areaTotalFazendasHa': 1234.5,
      'areaTotalTalhoesHa': 900.25,
      'areaMediaPorFazendaHa': 246.9,
      'mediaTalhoesPorFazenda': 8.2,
      'coberturaAreaTalhoesPercentual': 72.9,
      'fazendasComAreaInformada': 4,
      'talhoesComAreaInformada': 38,
      'fazendasSemAreaInformada': 1,
      'fazendasSemTalhoes': 0,
      'maioresFazendas': [
        {
          'fazendaId': 'fazenda-1',
          'nome': 'Fazenda Modelo',
          'areaHa': 640.5,
          'totalTalhoes': 12,
          'totalVinculosAtivos': 2,
        }
      ],
    });

    expect(overview.escopo, 'GLOBAL');
    expect(overview.areaMediaPorFazendaHa, 246.9);
    expect(overview.maioresFazendas.single.nome, 'Fazenda Modelo');
  });

  test('regras do painel seguem agrupamento operacional oficial', () {
    expect(
      grupoDaDemanda(status: 'AGENDADA', situacaoMapeamento: 'SEM_IMAGENS'),
      'A_SEGUIR',
    );
    expect(
      grupoDaDemanda(status: 'AGENDADA', situacaoMapeamento: 'EM_ANDAMENTO'),
      'COLETA_DE_DADOS',
    );
    expect(
      grupoDaDemanda(
        status: 'PRESCRICAO_EM_ANDAMENTO',
        situacaoMapeamento: 'IMAGENS_DISPONIVEIS',
      ),
      'ANDAMENTO',
    );
  });
}
