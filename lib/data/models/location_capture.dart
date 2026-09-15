import 'package:sqlite3/sqlite3.dart';

class LocationCapture {
  const LocationCapture({
    required this.demandaId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  factory LocationCapture.fromRow(Row row) {
    return LocationCapture(
      demandaId: row['demanda_id'] as String,
      latitude: row['latitude'] as double,
      longitude: row['longitude'] as double,
      accuracy: row['accuracy'] as double?,
      capturedAt: DateTime.parse(row['captured_at'] as String),
    );
  }

  final String demandaId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime capturedAt;
}
