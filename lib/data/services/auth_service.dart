import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth. Contains NO business logic and NO
/// error-translation — that happens in AuthRepository. This is what makes
/// it swappable/mockable in tests.
class AuthService {
  final FirebaseAuth _auth;
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> reauthenticate(String email, String password) async {
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await _auth.currentUser?.reauthenticateWithCredential(cred);
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<void> signOut() => _auth.signOut();
}
