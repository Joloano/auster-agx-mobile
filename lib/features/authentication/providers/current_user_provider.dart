import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/auth_controller.dart';

final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) {
    throw StateError('Authenticated user is required for local data access.');
  }
  return user.userId;
});
