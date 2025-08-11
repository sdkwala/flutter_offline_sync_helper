import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityWatcher {
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityResult> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  Future<ConnectivityResult> checkConnectivity() {
    return _connectivity.checkConnectivity();
  }
} 