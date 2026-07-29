import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/core/utils/safe_call.dart';
import 'package:flutter_expence_tracker/data/models/payback_model.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';

class PaybackProvider extends ChangeNotifier {
  final PaybackRepository _paybackRepository;
  final String uid;

  PaybackProvider({required PaybackRepository paybackRepository, required this.uid})
      : _paybackRepository = paybackRepository {
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _paybackRepository.watchPaybacks(uid).listen(
      (data) {
        _paybacks = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Failed to load paybacks';
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    _subscribe();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  StreamSubscription<List<PaybackModel>>? _sub;

  List<PaybackModel> _paybacks = [];
  List<PaybackModel> get paybacks => _paybacks;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Net effect on this month's available budget: sum of amounts received.
  /// "Given" paybacks are deliberately excluded here — they now create a
  /// real linked expense (see AddPaybackScreen), which already reduces
  /// ExpenseProvider.thisMonthExpenses, so folding them in again here
  /// would subtract the same money twice.
  double get thisMonthNet {
    final now = DateTime.now();
    return _paybacks
        .where((p) => p.date.year == now.year && p.date.month == now.month)
        .fold(0.0, (sum, p) => sum + p.budgetImpact);
  }

  Future<bool> addPayback(PaybackModel payback) async {
    final success = await safeCall(
      () async => (await _paybackRepository.addPayback(uid, payback)).when(
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

  Future<bool> deletePayback(String paybackId) async {
    final success = await safeCall(
      () async => (await _paybackRepository.deletePayback(uid, paybackId)).when(
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
