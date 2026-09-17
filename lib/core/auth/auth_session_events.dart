import 'dart:async';

class AuthSessionEvents {
  final StreamController<void> _expiredController =
      StreamController<void>.broadcast(sync: true);

  Stream<void> get sessionExpired => _expiredController.stream;

  void notifySessionExpired() {
    if (!_expiredController.isClosed) {
      _expiredController.add(null);
    }
  }

  Future<void> dispose() {
    return _expiredController.close();
  }
}
