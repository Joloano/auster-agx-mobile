import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../../../core/errors/app_exception.dart';
import '../local/app_database.dart';
import '../models/location_capture.dart';

class LocationService {
  LocationService(this._database);

  final AppDatabase _database;

  Future<LocationCapture> captureCurrentLocation(String demandaId) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const AppException(
        'GPS desligado. Ative a localizacao do aparelho.',
      );
    }

    final permission = await permissions.Permission.locationWhenInUse.request();
    if (permission.isPermanentlyDenied) {
      throw const AppException(
        'Permissao de localizacao negada permanentemente.',
      );
    }
    if (!permission.isGranted) {
      throw const AppException('Permissao de localizacao negada.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    final capture = LocationCapture(
      demandaId: demandaId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      capturedAt: DateTime.now(),
    );
    await _database.saveLocationCapture(capture);
    return capture;
  }

  Future<List<LocationCapture>> listCaptures(String demandaId) {
    return _database.readLocationCaptures(demandaId);
  }
}
