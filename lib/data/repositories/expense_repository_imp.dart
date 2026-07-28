import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

enum SortBy { dateDesc, dateAsc, amountDesc, amountAsc }

class ExpenseFilter {
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final SortBy sortBy;

  const ExpenseFilter({
    this.categoryId,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.sortBy = SortBy.dateDesc,
  });
}


class ExpenseRepositoryImpl implements ExpenseRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  ExpenseRepositoryImpl({
    required this._firestoreService,
    required StorageService storageService,
  })  : _storageService = storageService;

  @override
  Stream<List<ExpenseModel>> watchExpenses(String uid, {ExpenseFilter filter = const ExpenseFilter()}) {
    // Firestore-side filtering keeps queries efficient (only what's needed
    // travels over the wire). Full-text "search by title" is done client
    // side on the already-filtered, already-small result set below, since
    // Firestore has no native substring search.
    Query<Map<String, dynamic>> query = _firestoreService.expensesRef(uid);

    if (filter.categoryId != null) {
      query = query.where('categoryId', isEqualTo: filter.categoryId);
    }
    if (filter.startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
    }
    if (filter.endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
    }

    switch (filter.sortBy) {
      case SortBy.dateDesc:
        query = query.orderBy('date', descending: true);
        break;
      case SortBy.dateAsc:
        query = query.orderBy('date');
        break;
      case SortBy.amountDesc:
        query = query.orderBy('amount', descending: true);
        break;
      case SortBy.amountAsc:
        query = query.orderBy('amount');
        break;
    }

    return query.snapshots().map((snap) {
      var expenses = snap.docs.map(ExpenseModel.fromDoc).toList();
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final q = filter.searchQuery!.trim().toLowerCase();
        expenses = expenses.where((e) => e.title.toLowerCase().contains(q)).toList();
      }
      return expenses;
    });
  }

  @override
  Future<Result<void>> addExpense(String uid, ExpenseModel expense, {File? receiptImage}) async {
    final validation = _validate(expense);
    if (validation != null) return Result.failure(validation);

    try {
      String? imageUrl;
      if (receiptImage != null) {
        imageUrl = await _storageService.uploadFile(
          file: receiptImage,
          folder: StorageFolders.receipts,
          uid: uid,
        );
      }
      final toSave = expense.copyWith(receiptImageUrl: imageUrl);
      await _firestoreService.expensesRef(uid).add(toSave.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to add expense'));
    } catch (_) {
      return Result.failure(const StorageFailure('Failed to upload receipt image'));
    }
  }

  @override
  Future<Result<void>> updateExpense(String uid, ExpenseModel expense, {File? newReceiptImage}) async {
    final validation = _validate(expense);
    if (validation != null) return Result.failure(validation);

    try {
      String? imageUrl = expense.receiptImageUrl;
      if (newReceiptImage != null) {
        if (expense.receiptImageUrl != null) {
          await _storageService.deleteFileByUrl(expense.receiptImageUrl!);
        }
        imageUrl = await _storageService.uploadFile(
          file: newReceiptImage,
          folder: StorageFolders.receipts,
          uid: uid,
        );
      }
      final toSave = expense.copyWith(receiptImageUrl: imageUrl, updatedAt: DateTime.now());
      await _firestoreService.expensesRef(uid).doc(expense.id).update(toSave.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to update expense'));
    } catch (_) {
      return Result.failure(const StorageFailure('Failed to upload receipt image'));
    }
  }

  @override
  Future<Result<void>> deleteExpense(String uid, String expenseId, {String? receiptImageUrl}) async {
    try {
      await _firestoreService.expensesRef(uid).doc(expenseId).delete();
      if (receiptImageUrl != null) {
        await _storageService.deleteFileByUrl(receiptImageUrl);
      }
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to delete expense'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to delete expense'));
    }
  }

  Failure? _validate(ExpenseModel expense) {
    if (expense.title.trim().isEmpty) return const ValidationFailure('Title is required');
    if (expense.amount <= 0) return const ValidationFailure('Amount must be greater than 0');
    if (expense.categoryId.isEmpty) return const ValidationFailure('Please select a category');
    return null;
  }
}
