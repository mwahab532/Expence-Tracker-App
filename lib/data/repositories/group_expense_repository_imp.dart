import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_expence_tracker/core/errors/failures.dart';
import 'package:flutter_expence_tracker/core/utils/result.dart';
import 'package:flutter_expence_tracker/data/models/group_expense_model.dart';
import 'package:flutter_expence_tracker/data/services/firestore_service.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';

class GroupExpenseRepositoryImp implements GroupExpenseRepository {
  final FirestoreService _firestoreService;
  GroupExpenseRepositoryImp({required FirestoreService firestoreService}) : _firestoreService = firestoreService;

  @override
  Stream<List<GroupExpenseModel>> watchGroupExpenses(String ownerUid, String groupId) {
    return _firestoreService
        .groupExpensesRef(ownerUid, groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(GroupExpenseModel.fromDoc).toList());
  }

  Failure? _validate(GroupExpenseModel expense) {
    if (expense.title.trim().isEmpty) return const ValidationFailure('Title is required');
    if (expense.amount <= 0) return const ValidationFailure('Amount must be greater than 0');
    if (expense.categoryId.isEmpty) return const ValidationFailure('Please select a category');
    if (expense.contributorUids.isEmpty) {
      return const ValidationFailure('Select at least one contributor');
    }
    return null;
  }

  @override
  Future<Result<void>> addGroupExpense(String ownerUid, String groupId, GroupExpenseModel expense) async {
    final validation = _validate(expense);
    if (validation != null) return Result.failure(validation);
    try {
      await _firestoreService.groupExpensesRef(ownerUid, groupId).add(expense.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to add group expense'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to add group expense'));
    }
  }

  @override
  Future<Result<void>> updateGroupExpense(String ownerUid, String groupId, GroupExpenseModel expense) async {
    final validation = _validate(expense);
    if (validation != null) return Result.failure(validation);
    try {
      await _firestoreService.groupExpensesRef(ownerUid, groupId).doc(expense.id).update(expense.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to update group expense'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to update group expense'));
    }
  }

  @override
  Future<Result<void>> deleteGroupExpense(String ownerUid, String groupId, String expenseId) async {
    try {
      await _firestoreService.groupExpensesRef(ownerUid, groupId).doc(expenseId).delete();
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to delete group expense'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to delete group expense'));
    }
  }
}
