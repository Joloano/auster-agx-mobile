import 'package:auster_agx_mobile/data/local/app_database.dart';
import 'package:auster_agx_mobile/data/models/dashboard_models.dart';
import 'package:auster_agx_mobile/data/models/demanda_models.dart';
import 'package:auster_agx_mobile/data/models/location_capture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.inMemory();
  });

  tearDown(() {
    database.dispose();
  });

  test('salva e le demandas do dashboard no SQLite local', () async {
    await database.saveDashboardItems([_dashboardItem()]);

    final items = await database.readDashboardItems();

    expect(items, hasLength(1));
    expect(items.single.codigo, 'SMN26001001');
  });

  test('fila de sincronizacao registra operacoes pendentes', () async {
    await database.enqueueSyncOperation(
      operationType: 'update_demanda',
      entity: 'demanda',
      entityId: 'demanda-1',
      payload: {'tipo': 'SMART_N', 'status': 'AGENDADA'},
    );

    expect(await database.countPendingSyncOperations(), 1);
    final operations = await database.readPendingSyncOperations();
    expect(operations.single.payload['status'], 'AGENDADA');
  });

  test('capturas GPS ficam vinculadas a demanda', () async {
    await database.saveLocationCapture(
      LocationCapture(
        demandaId: 'demanda-1',
        latitude: -20.1,
        longitude: -48.5,
        accuracy: 8,
        capturedAt: DateTime.utc(2026, 9, 14),
      ),
    );

    final captures = await database.readLocationCaptures('demanda-1');

    expect(captures, hasLength(1));
    expect(captures.single.latitude, -20.1);
  });

  test('atualiza cache do dashboard ao alterar demanda offline', () async {
    await database.saveDashboardItems([_dashboardItem()]);

    await database.updateCachedDashboardDemand(
      _demanda(status: 'ENTREGUE', situacaoDados: 'DADOS_PREENCHIDOS'),
    );

    final items = await database.readDashboardItems();

    expect(items.single.status, 'ENTREGUE');
    expect(items.single.situacaoDados, 'DADOS_PREENCHIDOS');
    expect(items.single.arquivada, isTrue);
  });
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

Demanda _demanda({
  required String status,
  required String situacaoDados,
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
    statusChave: status,
    situacaoDados: situacaoDados,
    situacaoMapeamento: 'IMAGENS_DISPONIVEIS',
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
