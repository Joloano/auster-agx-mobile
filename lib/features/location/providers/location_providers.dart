import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/models/location_capture.dart';
import '../../../data/services/location_service.dart';

final locationServiceProvider = FutureProvider<LocationService>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return LocationService(database);
});

final locationCapturesProvider =
    FutureProvider.family<List<LocationCapture>, String>((
  ref,
  demandaId,
) async {
  final service = await ref.watch(locationServiceProvider.future);
  return service.listCaptures(demandaId);
});
