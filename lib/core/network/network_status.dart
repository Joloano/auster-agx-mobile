import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatus {
  NetworkStatus(this._connectivity);

  final Connectivity _connectivity;

  Stream<bool> get onlineChanges {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
