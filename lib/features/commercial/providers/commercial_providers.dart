import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/services/commercial_api.dart';

final commercialApiProvider = Provider<CommercialApi>((ref) {
  return CommercialApi(ref.watch(apiClientProvider));
});
