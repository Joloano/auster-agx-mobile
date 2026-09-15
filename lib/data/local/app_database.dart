import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/dashboard_models.dart';
import '../models/demanda_models.dart';
import '../models/location_capture.dart';

class AppDatabase {
  AppDatabase(this._db) {
    _createSchema();
  }

  factory AppDatabase.inMemory() => AppDatabase(sqlite3.openInMemory());

  static Future<AppDatabase> openDefault() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'auster_agx_mobile.sqlite');
    return AppDatabase(sqlite3.open(path));
  }

  final Database _db;

  void dispose() => _db.dispose();

  void _createSchema() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS dashboard_items (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS dashboard_overview (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS demanda_details (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending'
      );

      CREATE TABLE IF NOT EXISTS location_captures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        demanda_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        captured_at TEXT NOT NULL
      );
    ''');
  }

  Future<void> saveDashboardItems(List<DashboardDemandItem> items) async {
    final statement = _db.prepare('''
      INSERT INTO dashboard_items (id, payload, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        payload = excluded.payload,
        updated_at = excluded.updated_at
    ''');
    final now = DateTime.now().toIso8601String();
    try {
      for (final item in items) {
        statement.execute([item.id, jsonEncode(item.toJson()), now]);
      }
    } finally {
      statement.dispose();
    }
  }

  Future<List<DashboardDemandItem>> readDashboardItems() async {
    final result = _db.select(
      'SELECT payload FROM dashboard_items ORDER BY updated_at DESC',
    );
    return result
        .map((row) => DashboardDemandItem.fromJson(_decode(row['payload'])))
        .toList();
  }

  Future<void> saveDashboardOverview(DashboardOverview overview) async {
    _db.execute(
      '''
      INSERT INTO dashboard_overview (id, payload, updated_at)
      VALUES (1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        payload = excluded.payload,
        updated_at = excluded.updated_at
      ''',
      [jsonEncode(overview.toJson()), DateTime.now().toIso8601String()],
    );
  }

  Future<DashboardOverview?> readDashboardOverview() async {
    final result = _db.select(
      'SELECT payload FROM dashboard_overview WHERE id = 1',
    );
    if (result.isEmpty) return null;
    return DashboardOverview.fromJson(_decode(result.first['payload']));
  }

  Future<void> saveDemandaDetail(DemandaDetail detail) async {
    _db.execute(
      '''
      INSERT INTO demanda_details (id, payload, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        payload = excluded.payload,
        updated_at = excluded.updated_at
      ''',
      [
        detail.demanda.id,
        jsonEncode(detail.toJson()),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Future<DemandaDetail?> readDemandaDetail(String id) async {
    final result = _db.select(
      'SELECT payload FROM demanda_details WHERE id = ?',
      [id],
    );
    if (result.isEmpty) return null;
    return DemandaDetail.fromJson(_decode(result.first['payload']));
  }

  Future<int> enqueueSyncOperation({
    required String operationType,
    required String entity,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final result = _db.select(
      '''
      INSERT INTO sync_queue
        (operation_type, entity, entity_id, payload, created_at, attempts, status)
      VALUES (?, ?, ?, ?, ?, 0, 'pending')
      RETURNING id
      ''',
      [
        operationType,
        entity,
        entityId,
        jsonEncode(payload),
        DateTime.now().toIso8601String(),
      ],
    );
    return result.first['id'] as int;
  }

  Future<List<SyncQueueItem>> readPendingSyncOperations() async {
    final result = _db.select('''
      SELECT id, operation_type, entity, entity_id, payload, created_at, attempts, status
      FROM sync_queue
      WHERE status = 'pending'
      ORDER BY created_at ASC
      ''');
    return result.map(SyncQueueItem.fromRow).toList();
  }

  Future<int> countPendingSyncOperations() async {
    final result = _db.select(
      "SELECT COUNT(*) AS total FROM sync_queue WHERE status = 'pending'",
    );
    return result.first['total'] as int;
  }

  Future<void> markSyncDone(int id) async {
    _db.execute("UPDATE sync_queue SET status = 'done' WHERE id = ?", [id]);
  }

  Future<void> markSyncFailed(int id) async {
    _db.execute('UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?', [
      id,
    ]);
  }

  Future<void> saveLocationCapture(LocationCapture capture) async {
    _db.execute(
      '''
      INSERT INTO location_captures
        (demanda_id, latitude, longitude, accuracy, captured_at)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        capture.demandaId,
        capture.latitude,
        capture.longitude,
        capture.accuracy,
        capture.capturedAt.toIso8601String(),
      ],
    );
  }

  Future<List<LocationCapture>> readLocationCaptures(String demandaId) async {
    final result = _db.select(
      '''
      SELECT demanda_id, latitude, longitude, accuracy, captured_at
      FROM location_captures
      WHERE demanda_id = ?
      ORDER BY captured_at DESC
      ''',
      [demandaId],
    );
    return result.map(LocationCapture.fromRow).toList();
  }

  Map<String, dynamic> _decode(Object? value) {
    return jsonDecode(value! as String) as Map<String, dynamic>;
  }
}

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.operationType,
    required this.entity,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    required this.attempts,
  });

  factory SyncQueueItem.fromRow(Row row) {
    return SyncQueueItem(
      id: row['id'] as int,
      operationType: row['operation_type'] as String,
      entity: row['entity'] as String,
      entityId: row['entity_id'] as String,
      payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(row['created_at'] as String),
      attempts: row['attempts'] as int,
    );
  }

  final int id;
  final String operationType;
  final String entity;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
}
