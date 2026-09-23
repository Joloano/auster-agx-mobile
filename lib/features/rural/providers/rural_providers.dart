import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/services/rural_api.dart';

final ruralApiProvider = Provider<RuralApi>((ref) {
  return RuralApi(ref.watch(apiClientProvider));
});
