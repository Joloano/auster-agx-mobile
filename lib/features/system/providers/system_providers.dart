import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/services/google_drive_authorization.dart';
import '../../../data/services/system_api.dart';

final systemApiProvider = Provider<SystemApi>((ref) {
  return SystemApi(ref.watch(apiClientProvider));
});

final googleDriveAuthorizationProvider = Provider<GoogleDriveAuthorization>((
  ref,
) {
  return GoogleDriveAuthorization(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
