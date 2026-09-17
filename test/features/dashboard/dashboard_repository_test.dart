import 'dart:async';

import 'package:auster_agx_mobile/core/network/network_status.dart';
import 'package:auster_agx_mobile/data/local/app_database.dart';
import 'package:auster_agx_mobile/data/models/dashboard_models.dart';
import 'package:auster_agx_mobile/data/repositorios/dashboard_repository.dart';
import 'package:auster_agx_mobile/data/services/dashboard_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late _FakeNetwork network;
  late _FakeDashboardApi api;
  late DashboardRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    network = _FakeNetwork();
    api = _FakeDashboardApi();
    repository = DashboardRepository(
      api: api,
      database: database,
      networkStatus: network,
    );
  });

  tearDown(() {
    database.dispose();
    network.dispose();
  });

  test('usa resumo em cache quando API falha temporariamente', () async {
    await database.saveDashboardOverview(_overview(totalClientes: 12));
    api.error = DioException.connectionError(
      requestOptions: RequestOptions(path: '/dashboard/resumo'),
      reason: 'offline',
    );

    final result = await repository.loadOverview();

    expect(result?.totalClientes, 12);
  });

  test('propaga 403 em vez de apresentar cache como resposta atual', () async {
    await database.saveDashboardOverview(_overview(totalClientes: 12));
    final options = RequestOptions(path: '/dashboard/resumo');
    api.error = DioException.badResponse(
      requestOptions: options,
      response: Response<void>(requestOptions: options, statusCode: 403),
      statusCode: 403,
    );

    await expectLater(
      repository.loadOverview(),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'statusCode',
          403,
        ),
      ),
    );
  });
}

class _FakeDashboardApi implements DashboardRemoteDataSource {
  Object? error;

  @override
  Future<DashboardOverview> getOverview() async {
    if (error != null) throw error!;
    return _overview(totalClientes: 20);
  }

  @override
  Future<PageResponse<DashboardDemandItem>> listDemandasPainel({
    bool arquivada = false,
    int pagina = 0,
    int tamanho = 100,
  }) async {
    if (error != null) throw error!;
    return const PageResponse(
      conteudo: [],
      totalElementos: 0,
      totalPaginas: 0,
      pagina: 0,
      tamanho: 100,
    );
  }
}

class _FakeNetwork implements ConnectivityStatus {
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  void dispose() => _controller.close();
}

DashboardOverview _overview({required int totalClientes}) {
  return DashboardOverview(
    escopo: 'GLOBAL',
    totalClientes: totalClientes,
    totalFazendas: 0,
    totalTalhoes: 0,
    totalVinculosAtivos: 0,
    areaTotalFazendasHa: 0,
    areaTotalTalhoesHa: 0,
    areaMediaPorFazendaHa: 0,
    mediaTalhoesPorFazenda: 0,
    coberturaAreaTalhoesPercentual: 0,
    fazendasComAreaInformada: 0,
    talhoesComAreaInformada: 0,
    fazendasSemAreaInformada: 0,
    fazendasSemTalhoes: 0,
    maioresFazendas: const [],
  );
}
