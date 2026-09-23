import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/services/operations_api.dart';

final operationsApiProvider = Provider<OperationsApi>((ref) {
  return OperationsApi(ref.watch(apiClientProvider));
});
