import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../models/app_user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';


/// Contract the rest of the app depends on. Screens/providers only ever
/// see this interface, never AuthService or FirebaseAuth directly.


class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final CategoryRepository _categoryRepository;

  AuthRepositoryImpl({
    required this._authService,
    required FirestoreService firestoreService,
    required this._categoryRepository,
  })  : _firestoreService = firestoreService;

  AppUserModel? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
    );
  }

  @override
  Stream<AppUserModel?> get authStateChanges =>
      _authService.authStateChanges().map(_mapFirebaseUser);

  @override
  AppUserModel? get currentUser => _mapFirebaseUser(_authService.currentUser);

  @override
  Future<Result<AppUserModel>> signUp(String email, String password, String displayName) async {
    try {
      final cred = await _authService.signUp(email.trim(), password);
      await _authService.updateDisplayName(displayName.trim());

      final uid = cred.user!.uid;
      final appUser = AppUserModel(uid: uid, email: email.trim(), displayName: displayName.trim());

      // If anything below fails (network drop, misconfigured rules, etc.),
      // the Firebase Auth account still exists — signIn() calls
      // _ensureUserProfile again on every future login, so the profile
      // doc / default categories get created then instead of being lost
      // forever with no way to recover through the UI.
      await _ensureUserProfile(uid: uid, email: appUser.email, displayName: appUser.displayName);

      return Result.success(appUser);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      return Result.failure(const UnknownFailure());
    }
  }

  @override
  Future<Result<AppUserModel>> signIn(String email, String password) async {
    try {
      final cred = await _authService.signIn(email.trim(), password);
      final user = _mapFirebaseUser(cred.user)!;

      // Repair-on-login: cheap no-op for a healthy account, but recovers
      // automatically if a prior signUp partially failed after the Auth
      // account was already created.
      await _ensureUserProfile(uid: user.uid, email: user.email, displayName: user.displayName);

      return Result.success(user);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      return Result.failure(const UnknownFailure());
    }
  }

  /// Ensures a Firestore user profile doc and default categories exist for
  /// [uid]. Idempotent and safe to call on every signUp/signIn: never
  /// overwrites an existing profile doc, and only seeds categories if none
  /// exist yet. Best-effort — a failure here must never fail the sign-up/
  /// sign-in itself; worst case it just retries on the next login.
  Future<void> _ensureUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      final userDocSnapshot = await _firestoreService.userDoc(uid).get();
      if (!userDocSnapshot.exists) {
        await _firestoreService.userDoc(uid).set(
          AppUserModel(uid: uid, email: email, displayName: displayName).toMap(),
        );
      }

      final hasCategories = await _categoryRepository.watchCategories(uid).first
          .timeout(const Duration(seconds: 5), onTimeout: () => []);
      if (hasCategories.isEmpty) {
        await _categoryRepository.seedDefaultCategories(uid);
      }
    } catch (_) {
      // best-effort — swallow and retry on next login
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email.trim());
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      return Result.failure(const UnknownFailure());
    }
  }

  @override
  Future<Result<void>> changePassword(String currentPassword, String newPassword) async {
    try {
      final email = _authService.currentUser?.email;
      if (email == null) return Result.failure(const AuthFailure('No signed-in user'));
      await _authService.reauthenticate(email, currentPassword);
      await _authService.updatePassword(newPassword);
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      return Result.failure(const UnknownFailure());
    }
  }
    @override
  Future<Result<void>> updateDisplayName(String uid, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return Result.failure(const ValidationFailure('Display name cannot be empty'));
    }
    try {
      // Update both: FirebaseAuth's own profile field (used e.g. by
      // FirebaseUser.displayName) and the Firestore user doc (the source
      // of truth AuthProvider actually reads from via authStateChanges).
      await _authService.updateDisplayName(trimmed);
      await _firestoreService.userDoc(uid).set(
        {'displayName': trimmed},
        SetOptions(merge: true),
      );
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(_mapAuthError(e)));
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to update display name'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to update display name'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _authService.signOut();
      return Result.success(null);
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to sign out'));
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please re-enter your current password and try again.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
