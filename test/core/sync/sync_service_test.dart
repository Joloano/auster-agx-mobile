import 'dart:async';

import 'package:auster_agx_mobile/data/local/app_database.dart';
import 'package:auster_agx_mobile/core/network/network_status.dart';
import 'package:auster_agx_mobile/data/models/dashboard_models.dart';
import 'package:auster_agx_mobile/data/sync/sync_service.dart';
import 'package:auster_agx_mobile/data/services/demandas_api.dart';
import 'package:auster_agx_mobile/data/models/demanda_models.dart';
import 'package:auster_agx_mobile/data/models/demanda_status_rules.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SyncService processa update_demanda pendente', () async {
    final database = AppDatabase.inMemory();
    final api = _FakeDemandasApi();
    final network = _FakeNetwork(online: true);
    final service = SyncService(
      database: database,
      demandasApi: api,
      networkStatus: network,
    );

    await database.enqueueSyncOperation(
      operationType: 'update_demanda',
      entity: 'demanda',
      entityId: 'demanda-1',
      payload: {
        'tipo': 'SMART_N',
        'status': 'AGENDADA',
        'situacaoDados': 'DADOS_INCOMPLETOS',
        'situacaoMapeamento': 'SEM_IMAGENS',
        'retrabalho': false,
      },
    );

    await service.processPending();

    expect(api.updatedIds, ['demanda-1']);
    expect(await database.countPendingSyncOperations(), 0);

    database.dispose();
    network.dispose();
  });

  test('SyncService reconcilia caches com resposta oficial da API', () async {
    final database = AppDatabase.inMemory();
    final authoritative = _demanda(
      status: 'Em andamento',
      statusChave: 'EM_ANDAMENTO',
      situacaoDados: 'DADOS_PREENCHIDOS',
      situacaoMapeamento: 'MAPEAMENTO_CONCLUIDO',
    );
    final api = _FakeDemandasApi(updateResult: authoritative);
    final network = _FakeNetwork(online: true);
    final service = SyncService(
      database: database,
      demandasApi: api,
      networkStatus: network,
    );
    await database.saveDemandaDetail(
      _detail(
        _demanda(
          status: 'Agendada',
          statusChave: 'AGENDADA',
          situacaoDados: 'DADOS_INCOMPLETOS',
          situacaoMapeamento: 'SEM_IMAGENS',
        ),
      ),
    );
    await database.saveDashboardItems([_dashboardItem()]);
    await database.enqueueSyncOperation(
      operationType: 'update_demanda',
      entity: 'demanda',
      entityId: 'demanda-1',
      payload: {
        'tipo': 'SMART_N',
        'status': 'AGENDADA',
        'situacaoDados': 'DADOS_INCOMPLETOS',
        'situacaoMapeamento': 'SEM_IMAGENS',
        'retrabalho': false,
      },
    );

    await service.processPending();

    final detail = await database.readDemandaDetail('demanda-1');
    final dashboard = await database.readDashboardItems();
    expect(detail?.demanda.statusChave, 'EM_ANDAMENTO');
    expect(detail?.demanda.situacaoDados, 'DADOS_PREENCHIDOS');
    expect(detail?.demanda.situacaoMapeamento, 'MAPEAMENTO_CONCLUIDO');
    expect(dashboard.single.status, 'EM_ANDAMENTO');
    expect(dashboard.single.situacaoDados, 'DADOS_PREENCHIDOS');
    expect(dashboard.single.situacaoMapeamento, 'MAPEAMENTO_CONCLUIDO');
    expect(await database.countPendingSyncOperations(), 0);

    database.dispose();
    network.dispose();
  });

  test('SyncService mantem falha transitoria pendente para nova tentativa',
      () async {
    final database = AppDatabase.inMemory();
    final api = _FakeDemandasApi(
      updateError: DioException.connectionError(
        requestOptions: RequestOptions(path: '/demandas/demanda-1'),
        reason: 'offline',
      ),
    );
    final network = _FakeNetwork(online: true);
    final service = SyncService(
      database: database,
      demandasApi: api,
      networkStatus: network,
    );
    await _enqueueUpdate(database);

    await service.processPending();

    final operations = await database.readPendingSyncOperations();
    expect(operations.single.attempts, 1);
    expect(await database.countFailedSyncOperations(), 0);

    database.dispose();
    network.dispose();
  });

  test('SyncService bloqueia rejeicao permanente para evitar loop', () async {
    final database = AppDatabase.inMemory();
    final options = RequestOptions(path: '/demandas/demanda-1');
    final api = _FakeDemandasApi(
      updateError: DioException.badResponse(
        requestOptions: options,
        response: Response<void>(requestOptions: options, statusCode: 422),
        statusCode: 422,
      ),
    );
    final network = _FakeNetwork(online: true);
    final service = SyncService(
      database: database,
      demandasApi: api,
      networkStatus: network,
    );
    await _enqueueUpdate(database);

    await service.processPending();

    final summary = await service.queueSummary();
    expect(summary.pending, 0);
    expect(summary.failed, 1);

    database.dispose();
    network.dispose();
  });
}

class _FakeDemandasApi implements DemandasRemoteDataSource {
  _FakeDemandasApi({this.updateResult, this.updateError});

  final Demanda? updateResult;
  final Object? updateError;
  final updatedIds = <String>[];

  @override
  Future<DemandaDetail> getDetail(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<DemandaStatusHistorico>> getHistoricoStatus(String id) {
    throw UnimplementedError();
  }

  @override
  Future<StatusFluxo> getStatusFluxo() {
    throw UnimplementedError();
  }

  @override
  Future<Demanda> update(String id, DemandaUpdateInput input) async {
    updatedIds.add(id);
    if (updateError != null) throw updateError!;
    return updateResult ??
        _demanda(
          status: input.status ?? 'Listada',
          statusChave: input.status ?? 'LISTADA',
          situacaoDados: input.situacaoDados ?? 'DADOS_INCOMPLETOS',
          situacaoMapeamento: input.situacaoMapeamento ?? 'SEM_IMAGENS',
        );
  }
}

Future<void> _enqueueUpdate(AppDatabase database) {
  return database.enqueueSyncOperation(
    operationType: 'update_demanda',
    entity: 'demanda',
    entityId: 'demanda-1',
    payload: {
      'tipo': 'SMART_N',
      'status': 'AGENDADA',
      'situacaoDados': 'DADOS_INCOMPLETOS',
      'situacaoMapeamento': 'SEM_IMAGENS',
      'retrabalho': false,
    },
  );
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

Demanda _demanda({
  required String status,
  required String statusChave,
  required String situacaoDados,
  required String situacaoMapeamento,
}) {
  return Demanda(
    id: 'demanda-1',
    pedidoId: 'pedido-1',
    pedidoCodigo: 'PED26001',
    clienteNome: 'Cliente Modelo',
    fazendaNomes: const ['Fazenda Modelo'],
    codigoDemanda: 'SMN26001001',
    tipo: 'SMART_N',
    status: status,
    statusChave: statusChave,
    situacaoDados: situacaoDados,
    situacaoMapeamento: situacaoMapeamento,
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

DemandaDetail _detail(Demanda demanda) {
  return DemandaDetail(
    demanda: demanda,
    pedido: const PedidoResumo(id: 'pedido-1', codigo: 'PED26001'),
    cliente: null,
    fazendas: const [],
    grupos: const [],
    sensoriamentos: const [],
    culturas: const [],
    demandaOrigem: null,
    derivadas: const [],
  );
}

DashboardDemandItem _dashboardItem() {
  return const DashboardDemandItem(
    id: 'demanda-1',
    tipo: 'SMART_N',
    codigo: 'SMN26001001',
    aplicacao: '1a',
    fazenda: 'Fazenda Modelo',
    talhoes: ['Talhao 1'],
    areaHa: 42.5,
    cultura: 'Milho',
    dataPrevista: '2026-10-15',
    representanteId: null,
    responsavelNome: 'Ana',
    status: 'AGENDADA',
    situacaoDados: 'DADOS_INCOMPLETOS',
    situacaoMapeamento: 'SEM_IMAGENS',
    metodoMapeamento: 'DRONE',
    arquivada: false,
    areaDeInteresse: 'Talhao 1',
    retrabalho: false,
  );
}
