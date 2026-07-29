import 'package:flutter/foundation.dart';

/// Wraps a provider write operation (already expected to return a plain
/// bool success/failure, per this app's Result<T>/ChangeNotifier pattern)
/// with a timeout and a catch-all, so it can never hang forever or throw
/// an unhandled exception up into the UI — regardless of whether every
/// repository underneath remembered to catch everything itself.
///
/// [onError] receives a human-readable message and should typically set an
/// errorMessage field and notifyListeners().
Future<bool> safeCall(
  Future<bool> Function() action, {
  required void Function(String message) onError,
  Duration timeout = const Duration(seconds: 15),
  String timeoutMessage = 'Request timed out. Please check your connection and try again.',
  String genericErrorMessage = 'Something went wrong. Please try again.',
}) async {
  try {
    return await action().timeout(timeout, onTimeout: () {
      onError(timeoutMessage);
      return false;
    });
  } catch (e, st) {
    debugPrint('safeCall caught: $e');
    debugPrint('$st');
    onError(genericErrorMessage);
    return false;
  }
}
