import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/services/agronomic_api.dart';

final agronomicApiProvider = Provider<AgronomicApi>((ref) {
  return AgronomicApi(ref.watch(apiClientProvider));
});
