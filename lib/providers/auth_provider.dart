import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/core/utils/safe_call.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import '../data/models/app_user_model.dart';


enum AuthStatus { unknown, authenticated, unauthenticated }

/// Providers are the ONLY layer that talks to both repositories and the UI.
/// Screens read state via context.watch/context.read; they never touch
/// repositories directly. This keeps business logic testable and UI dumb.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({required this._authRepository}) {
    _sub = _authRepository.authStateChanges.listen((user) {
      _user = user;
      _status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      notifyListeners();
    });
  }

  late final StreamSubscription<AppUserModel?> _sub;

  AppUserModel? _user;
  AppUserModel? get user => _user;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> signUp(String email, String password, String displayName) async {
    _setLoading(true);
    final result = await _authRepository.signUp(email, password, displayName);
    _setLoading(false);
    return result.when(
      success: (_) => true,
      failure: (f) {
        _errorMessage = f.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    final result = await _authRepository.signIn(email, password);
    _setLoading(false);
    return result.when(
      success: (_) => true,
      failure: (f) {
        _errorMessage = f.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    final result = await _authRepository.sendPasswordReset(email);
    _setLoading(false);
    return result.when(
      success: (_) => true,
      failure: (f) {
        _errorMessage = f.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> signOut() => _authRepository.signOut();

  /// Updates the display name and manually patches the cached [_user] —
  /// authStateChanges (Firebase Auth's stream) does NOT re-emit just
  /// because a profile field changed, only on sign-in/out/token refresh,
  /// so without this the UI would keep showing the old name until the
  /// next app restart.
  Future<bool> updateDisplayName(String newName) async {
    final uid = _user?.uid;
    if (uid == null) {
      _errorMessage = 'No signed-in user';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    final success = await safeCall(
      () async => (await _authRepository.updateDisplayName(uid, newName)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
    if (success) {
      _user = _user?.copyWith(displayName: newName.trim());
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    final success = await safeCall(
      () async => (await _authRepository.changePassword(currentPassword, newPassword)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
    _isLoading = false;
    notifyListeners();
    return success;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
