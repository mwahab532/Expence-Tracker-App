import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  ConnectivityService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  /// Never throws — if the plugin itself errors, this defaults to
  /// "online" rather than breaking provider construction at app startup.
  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged
      .map(_hasConnection)
      .handleError((e) => debugPrint('ConnectivityService stream error: $e'));

  Future<bool> get currentStatus async {
    try {
      return _hasConnection(await _connectivity.checkConnectivity());
    } catch (e) {
      debugPrint('ConnectivityService.currentStatus failed: $e');
      return true;
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
