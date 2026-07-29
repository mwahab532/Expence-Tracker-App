import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/providers/auth_provider.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';


/// Orchestrates the login submit flow. AuthProvider already holds the
/// actual auth business logic (talking to AuthRepository, tracking
/// isLoading/errorMessage) — this controller's only job is to be the
/// single point the UI talks to, so LoginScreen never reaches into
/// AuthProvider directly.
class LoginController extends ChangeNotifier {
  final RoundedLoadingButtonController loginController = RoundedLoadingButtonController();
  final AuthProvider _authProvider;
  LoginController({required AuthProvider authProvider}) : _authProvider = authProvider;

  bool get isLoading => _authProvider.isLoading;
  String? get errorMessage => _authProvider.errorMessage;

  Future<bool> submit({required String email, required String password}) {
    return _authProvider.signIn(email, password);
  }
}