import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/core/utils/safe_call.dart';
import 'package:flutter_expence_tracker/data/models/group_expense_model.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';

class GroupExpenseProvider extends ChangeNotifier {
  final GroupExpenseRepository _groupExpenseRepository;
  final String ownerUid;
  final String groupId;

  GroupExpenseProvider({
    required GroupExpenseRepository groupExpenseRepository,
    required this.ownerUid,
    required this.groupId,
  }) : _groupExpenseRepository = groupExpenseRepository {
    _sub = _groupExpenseRepository.watchGroupExpenses(ownerUid, groupId).listen(
      (data) {
        _expenses = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Failed to load group expenses';
        notifyListeners();
      },
    );
  }

  StreamSubscription<List<GroupExpenseModel>>? _sub;

  List<GroupExpenseModel> _expenses = [];
  List<GroupExpenseModel> get expenses => _expenses;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _saving = false;
  bool get isSaving => _saving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  double get totalGroupSpending => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// How much each member (by uid) owes in total across all group
  /// expenses — the sum of their per-person share of every expense they
  /// were a contributor on.
  Map<String, double> get totalsByMember {
    final totals = <String, double>{};
    for (final e in _expenses) {
      for (final uid in e.contributorUids) {
        totals[uid] = (totals[uid] ?? 0) + e.amountOwedBy(uid);
      }
    }
    return totals;
  }

  Future<bool> addExpense(GroupExpenseModel expense) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    final success = await safeCall(
      () async => (await _groupExpenseRepository.addGroupExpense(ownerUid, groupId, expense)).when(
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

  Future<bool> updateExpense(GroupExpenseModel expense) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    final success = await safeCall(
      () async => (await _groupExpenseRepository.updateGroupExpense(ownerUid, groupId, expense)).when(
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

  Future<bool> deleteExpense(String expenseId) async {
    final success = await safeCall(
      () async => (await _groupExpenseRepository.deleteGroupExpense(ownerUid, groupId, expenseId)).when(
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
