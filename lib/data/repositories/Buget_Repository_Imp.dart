import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_expence_tracker/data/models/buget_model.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../services/firestore_service.dart';



class BudgetRepositoryImpl implements BudgetRepository {
  final FirestoreService _firestoreService;
  BudgetRepositoryImpl({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  @override
  Stream<BudgetModel> watchBudget(String uid) {
    return _firestoreService.userDoc(uid).snapshots().map(
          (doc) => BudgetModel.fromMap(doc.data() ?? {}),
        );
  }

  @override
  Future<Result<void>> setMonthlyBudget(String uid, double amount) async {
    if (amount < 0) {
      return Result.failure(const ValidationFailure('Budget cannot be negative'));
    }
    try {
      // merge: true so this never overwrites the rest of the user doc
      // (email, displayName, photoUrl) — it only touches this one field.
      await _firestoreService.userDoc(uid).set(
        BudgetModel(monthlyBudget: amount).toMap(),
        SetOptions(merge: true),
      );
      return  Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to update budget'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to update budget'));
    }
  }
  
  @override
 Future<Result<void>> clearBudget(String uid) async {
    try {
      await _firestoreService.userDoc(uid).set(
        const BudgetModel(monthlyBudget: 0).toMap(),
        SetOptions(merge: true),
      );
      return  Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to clear budget'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to clear budget'));
    }
  }
}