import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { isConnected, isDisconnected, initializing }

class ConnectivityService extends StateNotifier<ConnectivityStatus> {
  ConnectivityService() : super(ConnectivityStatus.initializing) {
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      // connectivity_plus 6.x returns a List<ConnectivityResult>
      _updateStatus(results);
    });
  }

  void _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      state = ConnectivityStatus.isDisconnected;
    } else {
      state = ConnectivityStatus.isConnected;
    }
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityService, ConnectivityStatus>((ref) {
  return ConnectivityService();
});
