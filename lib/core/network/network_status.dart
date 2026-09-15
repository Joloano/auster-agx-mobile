import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityStatus {
  Stream<bool> get onlineChanges;

  Future<bool> isOnline();
}

class NetworkStatus implements ConnectivityStatus {
  NetworkStatus(this._connectivity);

  final Connectivity _connectivity;

  @override
  Stream<bool> get onlineChanges {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  @override
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
