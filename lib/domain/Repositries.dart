import 'dart:io';
import 'package:flutter_expence_tracker/core/utils/result.dart';
import 'package:flutter_expence_tracker/data/models/app_user_model.dart';
import 'package:flutter_expence_tracker/data/models/buget_model.dart';
import 'package:flutter_expence_tracker/data/models/category_model.dart';
import 'package:flutter_expence_tracker/data/models/expense_model.dart';
import 'package:flutter_expence_tracker/data/models/payback_model.dart';
import 'package:flutter_expence_tracker/data/models/group_model.dart';
import 'package:flutter_expence_tracker/data/models/group_member_model.dart';
import 'package:flutter_expence_tracker/data/models/group_expense_model.dart';
import 'package:flutter_expence_tracker/data/repositories/expense_repository_imp.dart';

abstract class AuthRepository {
  Stream<AppUserModel?> get authStateChanges;
  AppUserModel? get currentUser;
  Future<Result<AppUserModel>> signUp(String email, String password, String displayName);
  Future<Result<AppUserModel>> signIn(String email, String password);
  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> changePassword(String currentPassword, String newPassword);
  Future<Result<void>> updateDisplayName(String uid, String newName);
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

// Payback repository — individual money-back tracking (received from / given to someone)

abstract class PaybackRepository {
  Stream<List<PaybackModel>> watchPaybacks(String uid);
  Future<Result<void>> addPayback(String uid, PaybackModel payback);
  Future<Result<void>> deletePayback(String uid, String paybackId);
}

// Group repository — simple named groups (e.g. for grouping multiple people)

abstract class GroupRepository {
  Stream<List<GroupModel>> watchGroups(String uid);
  Future<Result<void>> addGroup(String uid, String name);
  Future<Result<void>> deleteGroup(String uid, String groupId);
}

// Group members — people (real Firebase-registered users) added to a group

abstract class GroupMemberRepository {
  Stream<List<GroupMemberModel>> watchMembers(String ownerUid, String groupId);
  Future<Result<void>> addMember(String ownerUid, String groupId, GroupMemberModel member);
  Future<Result<void>> removeMember(String ownerUid, String groupId, String memberUid);
}

// Group expenses — an expense split equally among chosen contributors

abstract class GroupExpenseRepository {
  Stream<List<GroupExpenseModel>> watchGroupExpenses(String ownerUid, String groupId);
  Future<Result<void>> addGroupExpense(String ownerUid, String groupId, GroupExpenseModel expense);
  Future<Result<void>> updateGroupExpense(String ownerUid, String groupId, GroupExpenseModel expense);
  Future<Result<void>> deleteGroupExpense(String ownerUid, String groupId, String expenseId);
}

// User directory — looks up another registered user's basic profile by
// email, so they can be added to a group. Read-only, never exposes more
// than uid/email/displayName/photoUrl.

abstract class UserDirectoryRepository {
  Future<Result<AppUserModel?>> findUserByEmail(String email);
}