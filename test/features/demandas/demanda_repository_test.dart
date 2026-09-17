import 'dart:async';

import 'package:dio/dio.dart';
import 'package:auster_agx_mobile/data/local/app_database.dart';
import 'package:auster_agx_mobile/core/network/network_status.dart';
import 'package:auster_agx_mobile/data/models/demanda_status_rules.dart';
import 'package:auster_agx_mobile/data/repositorios/demanda_repository.dart';
import 'package:auster_agx_mobile/data/services/demandas_api.dart';
import 'package:auster_agx_mobile/data/models/demanda_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late _FakeNetwork network;
  late _FakeDemandasApi api;

  setUp(() {
    database = AppDatabase.inMemory();
    network = _FakeNetwork(online: false);
    api = _FakeDemandasApi();
  });

  tearDown(() {
    database.dispose();
    network.dispose();
  });

  test('loadDetail usa cache quando esta offline', () async {
    final detail = _detail(status: 'LISTADA');
    await database.saveDemandaDetail(detail);
    final repository = DemandaRepository(
      api: api,
      database: database,
      networkStatus: network,
    );

    final loaded = await repository.loadDetail(detail.demanda.id);

    expect(loaded?.demanda.codigoDemanda, 'SMN26001001');
    expect(api.detailCalls, 0);
  });

  test('loadDetail usa cache somente em falha transitoria online', () async {
    network.online = true;
    api.detailError = DioException.connectionError(
      requestOptions: RequestOptions(path: '/demandas/demanda-1/detalhe'),
      reason: 'offline',
    );
    final detail = _detail(status: 'LISTADA');
    await database.saveDemandaDetail(detail);
    final repository = DemandaRepository(
      api: api,
      database: database,
      networkStatus: network,
    );

    final loaded = await repository.loadDetail(detail.demanda.id);

    expect(loaded?.demanda.statusChave, 'LISTADA');
  });

  test('loadDetail propaga erro definitivo em vez de ocultar com cache',
      () async {
    network.online = true;
    final options = RequestOptions(path: '/demandas/demanda-1/detalhe');
    api.detailError = DioException.badResponse(
      requestOptions: options,
      response: Response<void>(requestOptions: options, statusCode: 403),
      statusCode: 403,
    );
    final detail = _detail(status: 'LISTADA');
    await database.saveDemandaDetail(detail);
    final repository = DemandaRepository(
      api: api,
      database: database,
      networkStatus: network,
    );

    await expectLater(
      repository.loadDetail(detail.demanda.id),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'statusCode',
          403,
        ),
      ),
    );
  });

  test('updateStatus offline salva otimista e enfileira sync', () async {
    final detail = _detail(status: 'LISTADA');
    final repository = DemandaRepository(
      api: api,
      database: database,
      networkStatus: network,
    );

    final updated = await repository.updateStatus(
      current: detail,
      status: 'AGENDADA',
    );

    expect(updated.demanda.statusChave, 'AGENDADA');
    expect(await database.countPendingSyncOperations(), 1);
  });

  test('loadHistoricoStatus usa cache quando esta offline', () async {
    await database.saveDemandaStatusHistory('demanda-1', [
      const DemandaStatusHistorico(
        demandaId: 'demanda-1',
        statusAnterior: null,
        statusAnteriorChave: null,
        statusNovo: 'Listada',
        statusNovoChave: 'LISTADA',
        alteradoPorId: 'usuario-1',
        alteradoPorNome: 'Joloano',
        alteradoEm: '2026-09-14T00:00:00',
      ),
    ]);
    final repository = DemandaRepository(
      api: api,
      database: database,
      networkStatus: network,
    );

    final history = await repository.loadHistoricoStatus('demanda-1');

    expect(history, hasLength(1));
    expect(history.single.statusNovoChave, 'LISTADA');
    expect(api.historyCalls, 0);
  });

  test('loadStatusFluxo usa metadados cacheados quando esta offline', () async {
    await database.saveStatusFluxo(
      const StatusFluxo(
        ordem: ['LISTADA', 'AGENDADA'],
        transicoesValidas: {
          'LISTADA': ['AGENDADA'],
        },
        exigeDadosPreenchidos: [],
        exigeMapeamentoConcluido: [],
      ),
    );
    final repository = DemandaRepository(
      api: api,
      database: database,
      networkStatus: network,
    );

    final fluxo = await repository.loadStatusFluxo();

    expect(fluxo?.transicoesValidas['LISTADA'], ['AGENDADA']);
    expect(api.statusFluxoCalls, 0);
  });
}

class _FakeDemandasApi implements DemandasRemoteDataSource {
  Object? detailError;
  int detailCalls = 0;
  int historyCalls = 0;
  int statusFluxoCalls = 0;

  @override
  Future<DemandaDetail> getDetail(String id) async {
    detailCalls++;
    if (detailError != null) throw detailError!;
    return _detail(status: 'LISTADA');
  }

  @override
  Future<List<DemandaStatusHistorico>> getHistoricoStatus(String id) async {
    historyCalls++;
    return const [];
  }

  @override
  Future<StatusFluxo> getStatusFluxo() async {
    statusFluxoCalls++;
    return const StatusFluxo(
      ordem: ['LISTADA', 'AGENDADA'],
      transicoesValidas: {
        'LISTADA': ['AGENDADA'],
      },
      exigeDadosPreenchidos: [],
      exigeMapeamentoConcluido: [],
    );
  }

  @override
  Future<Demanda> update(String id, DemandaUpdateInput input) async {
    return _demanda(status: input.status ?? 'LISTADA');
  }
}

class _FakeNetwork implements ConnectivityStatus {
  _FakeNetwork({required this.online});

  bool online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  @override
  Future<bool> isOnline() async => online;

  void dispose() => _controller.close();
}

DemandaDetail _detail({required String status}) {
  return DemandaDetail(
    demanda: _demanda(status: status),
    pedido: const PedidoResumo(
      id: 'pedido-1',
      codigo: 'PED26001',
    ),
    cliente: const ClienteResumo(
      id: 'cliente-1',
      nomeFantasia: 'Cliente Modelo',
    ),
    fazendas: const [],
    grupos: const [],
    sensoriamentos: const [],
    culturas: const [],
    demandaOrigem: null,
    derivadas: const [],
  );
}

Demanda _demanda({required String status}) {
  return Demanda(
    id: 'demanda-1',
    pedidoId: 'pedido-1',
    pedidoCodigo: 'PED26001',
    clienteNome: 'Cliente Modelo',
    fazendaNomes: const ['Fazenda Modelo'],
    codigoDemanda: 'SMN26001001',
    tipo: 'SMART_N',
    status: statusDemandaLabel(status),
    statusChave: status,
    situacaoDados: 'DADOS_INCOMPLETOS',
    situacaoMapeamento: 'SEM_IMAGENS',
    retrabalho: false,
    demandaOrigemId: null,
    numeroAplicacao: 1,
    representanteId: null,
    representanteNome: null,
    prazo: '2026-10-15',
    areaDeInteresse: 'Talhao 1',
    grupoIds: const [],
    sensoriamentoIds: const [],
    ativo: true,
    createdAt: '2026-09-14T00:00:00',
  );
}
