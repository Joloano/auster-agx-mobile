import 'dart:async';

import 'package:auster_agx_mobile/core/database/app_database.dart';
import 'package:auster_agx_mobile/core/network/network_status.dart';
import 'package:auster_agx_mobile/core/sync/sync_service.dart';
import 'package:auster_agx_mobile/features/demandas/data/demandas_api.dart';
import 'package:auster_agx_mobile/features/demandas/domain/demanda_models.dart';
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
}

class _FakeDemandasApi implements DemandasRemoteDataSource {
  final updatedIds = <String>[];

  @override
  Future<DemandaDetail> getDetail(String id) {
    throw UnimplementedError();
  }

  @override
  Future<StatusFluxo> getStatusFluxo() {
    throw UnimplementedError();
  }

  @override
  Future<Demanda> update(String id, DemandaUpdateInput input) async {
    updatedIds.add(id);
    return Demanda(
      id: id,
      pedidoId: 'pedido-1',
      pedidoCodigo: 'PED26001',
      clienteNome: 'Cliente Modelo',
      fazendaNomes: const [],
      codigoDemanda: 'SMN26001001',
      tipo: input.tipo,
      status: input.status ?? 'LISTADA',
      statusChave: input.status ?? 'LISTADA',
      situacaoDados: input.situacaoDados ?? 'DADOS_INCOMPLETOS',
      situacaoMapeamento: input.situacaoMapeamento ?? 'SEM_IMAGENS',
      retrabalho: input.retrabalho ?? false,
      demandaOrigemId: null,
      numeroAplicacao: null,
      representanteId: null,
      representanteNome: null,
      prazo: null,
      areaDeInteresse: null,
      grupoIds: const [],
      sensoriamentoIds: const [],
      ativo: true,
      createdAt: '2026-09-14T00:00:00',
    );
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
