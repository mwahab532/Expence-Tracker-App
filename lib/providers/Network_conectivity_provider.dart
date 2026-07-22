import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/data/services/contectivity_servics.dart';


class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService;

  ConnectivityProvider({required ConnectivityService connectivityService})
      : _connectivityService = connectivityService {
    _connectivityService.currentStatus.then((online) {
      _isOnline = online;
      notifyListeners();
    });
    _sub = _connectivityService.onStatusChange.listen((online) {
      _isOnline = online;
      notifyListeners();
    });
  }

  StreamSubscription<bool>? _sub;

  // Optimistic default: assume online until the first check resolves, so
  // the offline banner doesn't flash briefly on every cold start.
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}