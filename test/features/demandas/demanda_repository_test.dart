import 'dart:async';

import 'package:auster_agx_mobile/data/local/app_database.dart';
import 'package:auster_agx_mobile/core/network/network_status.dart';
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
}

class _FakeDemandasApi implements DemandasRemoteDataSource {
  int detailCalls = 0;

  @override
  Future<DemandaDetail> getDetail(String id) async {
    detailCalls++;
    return _detail(status: 'LISTADA');
  }

  @override
  Future<StatusFluxo> getStatusFluxo() async {
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
    pedido: const {'id': 'pedido-1', 'codigo': 'PED26001', 'apelido': null},
    cliente: const {'id': 'cliente-1', 'nomeFantasia': 'Cliente Modelo'},
    fazendas: const [],
    grupos: const [],
    culturas: const [],
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
    status: statusLabels[status] ?? status,
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
