import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/core/utils/safe_call.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository_imp.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _expenseRepository;
  final String uid;

  ExpenseProvider({required this._expenseRepository, required this.uid}) {
    _listen();
  }

  StreamSubscription<List<ExpenseModel>>? _sub;
  ExpenseFilter _filter = const ExpenseFilter();
  ExpenseFilter get filter => _filter;

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _listen() {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _expenseRepository.watchExpenses(uid, filter: _filter).listen(
      (data) {
        _expenses = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load expenses';
        notifyListeners();
      },
    );
  }

  void updateFilter(ExpenseFilter newFilter) {
    _filter = newFilter;
    _listen();
  }
    Future<void> refresh() async {
    _listen();
    // Wait for the first snapshot (or error) so RefreshIndicator's spinner
    // stays visible until there's something to show, instead of vanishing
    // instantly before _listen()'s async stream callback has fired.
    while (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // ---- Dashboard-derived stats (computed client-side from the current
  // stream snapshot; cheap since a personal expense list is small) ----

  double get totalExpenses => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get todayExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get thisMonthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  int get totalTransactions => _expenses.length;

  Future<bool> addExpense(ExpenseModel expense, {File? receiptImage}) async {
    final success = await safeCall(
      () async => (await _expenseRepository.addExpense(uid, expense, receiptImage: receiptImage)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
    notifyListeners();
    return success;
  }

  Future<bool> updateExpense(ExpenseModel expense, {File? newReceiptImage}) async {
    final success = await safeCall(
      () async => (await _expenseRepository.updateExpense(uid, expense, newReceiptImage: newReceiptImage)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
    notifyListeners();
    return success;
  }

  Future<bool> deleteExpense(String expenseId, {String? receiptImageUrl}) async {
    final success = await safeCall(
      () async => (await _expenseRepository.deleteExpense(uid, expenseId, receiptImageUrl: receiptImageUrl)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
    notifyListeners();
    return success;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
