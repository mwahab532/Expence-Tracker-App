import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_expence_tracker/core/errors/failures.dart';
import 'package:flutter_expence_tracker/core/utils/result.dart';
import 'package:flutter_expence_tracker/data/models/app_user_model.dart';
import 'package:flutter_expence_tracker/data/services/firestore_service.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';

class UserDirectoryRepositoryImp implements UserDirectoryRepository {
  final FirestoreService _firestoreService;
  UserDirectoryRepositoryImp({required FirestoreService firestoreService}) : _firestoreService = firestoreService;

  @override
  Future<Result<AppUserModel?>> findUserByEmail(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return Result.failure(const ValidationFailure('Enter an email to search'));
    }
    try {
      final snap = await _firestoreService
          .usersCollection()
          .where('email', isEqualTo: trimmed)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        return  Result.success(null);
      }
      return Result.success(AppUserModel.fromMap(snap.docs.first.id, snap.docs.first.data()));
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Search failed'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Search failed'));
    }
  }
}
