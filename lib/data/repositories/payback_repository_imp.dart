import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_expence_tracker/core/errors/failures.dart';
import 'package:flutter_expence_tracker/core/utils/result.dart';
import 'package:flutter_expence_tracker/data/models/payback_model.dart';
import 'package:flutter_expence_tracker/data/services/firestore_service.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';

class PaybackRepositoryImp implements PaybackRepository {
  final FirestoreService _firestoreService;
  PaybackRepositoryImp({required FirestoreService firestoreService}) : _firestoreService = firestoreService;

  @override
  Stream<List<PaybackModel>> watchPaybacks(String uid) {
    return _firestoreService
        .paybacksRef(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PaybackModel.fromDoc).toList());
  }

  @override
  Future<Result<void>> addPayback(String uid, PaybackModel payback) async {
    if (payback.personName.trim().isEmpty) {
      return Result.failure(const ValidationFailure('Person name is required'));
    }
    if (payback.amount <= 0) {
      return Result.failure(const ValidationFailure('Amount must be greater than 0'));
    }
    try {
      await _firestoreService.paybacksRef(uid).add(payback.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to add payback'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to add payback'));
    }
  }

  @override
  Future<Result<void>> deletePayback(String uid, String paybackId) async {
    try {
      await _firestoreService.paybacksRef(uid).doc(paybackId).delete();
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to delete payback'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to delete payback'));
    }
  }
}
