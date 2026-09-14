import 'package:auster_agx_mobile/core/database/app_database.dart';
import 'package:auster_agx_mobile/features/dashboard/domain/dashboard_models.dart';
import 'package:auster_agx_mobile/features/location/domain/location_capture.dart';
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
