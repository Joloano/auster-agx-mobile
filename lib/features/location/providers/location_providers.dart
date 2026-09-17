import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/models/location_capture.dart';
import '../../../data/services/location_service.dart';
import '../../authentication/providers/current_user_provider.dart';

final locationServiceProvider = FutureProvider<LocationService>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final database = await ref.watch(appDatabaseProvider(userId).future);
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
