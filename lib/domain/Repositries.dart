import 'dart:io';
import 'package:flutter_expence_tracker/core/utils/result.dart';
import 'package:flutter_expence_tracker/data/models/app_user_model.dart';
import 'package:flutter_expence_tracker/data/models/buget_model.dart';
import 'package:flutter_expence_tracker/data/models/category_model.dart';
import 'package:flutter_expence_tracker/data/models/expense_model.dart';
import 'package:flutter_expence_tracker/data/repositories/expense_repository_imp.dart';

abstract class AuthRepository {
  Stream<AppUserModel?> get authStateChanges;
  AppUserModel? get currentUser;
  Future<Result<AppUserModel>> signUp(String email, String password, String displayName);
  Future<Result<AppUserModel>> signIn(String email, String password);
  Future<Result<void>> sendPasswordReset(String email);
   Future<Result<void>> updateDisplayName(String uid, String newName);
  Future<Result<void>> changePassword(String currentPassword, String newPassword);
  Future<Result<void>> signOut();
}


//Budget repository

abstract class BudgetRepository {
  /// Emits the current monthly budget every time it changes (or 0 if
  /// never set), by listening to the user's own document.
  Stream<BudgetModel> watchBudget(String uid);
  Future<Result<void>> setMonthlyBudget(String uid, double amount);
   Future<Result<void>> clearBudget(String uid);
}

// categories repository

abstract class CategoryRepository {
  Stream<List<CategoryModel>> watchCategories(String uid);
  Future<Result<void>> addCustomCategory(String uid, String name, String iconKey);
  Future<Result<void>> renameCategory(String uid, String categoryId, String newName);
  Future<Result<void>> deleteCategory(String uid, String categoryId);
  Future<void> seedDefaultCategories(String uid);
}

// Expence repository 

abstract class ExpenseRepository {
  Stream<List<ExpenseModel>> watchExpenses(String uid, {ExpenseFilter filter = const ExpenseFilter()});
  Future<Result<void>> addExpense(String uid, ExpenseModel expense, {File? receiptImage});
  Future<Result<void>> updateExpense(String uid, ExpenseModel expense, {File? newReceiptImage});
  Future<Result<void>> deleteExpense(String uid, String expenseId, {String? receiptImageUrl});
}