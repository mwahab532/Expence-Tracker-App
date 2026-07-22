import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/core/utils/safe_call.dart';
import 'package:flutter_expence_tracker/data/models/buget_model.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';


class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  final String uid;

  BudgetProvider({required BudgetRepository budgetRepository, required this.uid})
      : _budgetRepository = budgetRepository {
    _sub = _budgetRepository.watchBudget(uid).listen((budget) {
      _monthlyBudget = budget.monthlyBudget;
      notifyListeners();
    });
  }
    void _subscribe() {
    _sub?.cancel();
    _sub = _budgetRepository.watchBudget(uid).listen((budget) {
      _monthlyBudget = budget.monthlyBudget;
      notifyListeners();
    });
  }
    Future<void> refresh() async {
    _subscribe();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  StreamSubscription<BudgetModel>? _sub;

  double _monthlyBudget = 0;
  double get monthlyBudget => _monthlyBudget;

  bool get isSet => _monthlyBudget > 0;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _saving = false;
  bool get isSaving => _saving;

  /// Remaining budget for the month, given the current month's spending
  /// (passed in by the caller — usually ExpenseProvider.thisMonthExpenses).
  /// Deliberately NOT stored/decremented manually: deriving it fresh from
  /// the live expense total means adding, editing, or deleting an expense
  /// all automatically keep this correct with zero extra bookkeeping.
  double remaining(double spentThisMonth) => _monthlyBudget - spentThisMonth;

  bool isOverBudget(double spentThisMonth) => remaining(spentThisMonth) < 0;

  Future<bool> setMonthlyBudget(double amount) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    final success = await safeCall(
      () async => (await _budgetRepository.setMonthlyBudget(uid, amount)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );

    _saving = false;
    notifyListeners();
    return success;
  }
  Future<bool> clearBudget() async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();
 
    final success = await safeCall(
      () async => (await _budgetRepository.clearBudget(uid)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
 
    _saving = false;
    notifyListeners();
    return success;
  }
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}