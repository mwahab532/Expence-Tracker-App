import 'package:flutter/foundation.dart';
import '../../data/models/category_model.dart';
import '../../data/models/expense_model.dart';
import '../../providers/expense_provider.dart';

/// Owns all form state and save logic for adding/editing an expense.
/// The widget only reads this controller's state and calls [submit] —
/// it never builds an ExpenseModel or talks to ExpenseProvider directly.
class AddEditExpenseController extends ChangeNotifier {
  final ExpenseProvider _expenseProvider;
  final ExpenseModel? existing;

  AddEditExpenseController({
    required ExpenseProvider expenseProvider,
    this.existing,
  }) : _expenseProvider = expenseProvider {
    date = existing?.date ?? DateTime.now();
  }

  bool get isEditing => existing != null;

  late DateTime date;
  CategoryModel? selectedCategory;

  bool _saving = false;
  bool get isSaving => _saving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setDate(DateTime value) {
    date = value;
    notifyListeners();
  }

  void setCategory(CategoryModel? category) {
    selectedCategory = category;
    notifyListeners();
  }

  /// Resolves the initially-selected category once the category list has
  /// loaded, for the edit case. No-op once a category has been picked.
  void resolveInitialCategory(List<CategoryModel> categories) {
    if (selectedCategory != null || existing == null) return;
    for (final c in categories) {
      if (c.id == existing!.categoryId) {
        selectedCategory = c;
        break;
      }
    }
  }

  /// Attempts to save the expense described by the given form field text.
  /// Returns true on success. Never throws — ExpenseProvider already
  /// routes every write through the app's shared safeCall helper
  /// (timeout + catch-all), so this just reacts to its bool result.
  Future<bool> submit({
    required String title,
    required String amountText,
    required String notes,
  }) async {
    if (selectedCategory == null) {
      _errorMessage = 'Please select a category';
      notifyListeners();
      return false;
    }

    final amount = double.tryParse(amountText) ?? 0;
    final now = DateTime.now();
    final expense = ExpenseModel(
      id: existing?.id ?? '',
      title: title.trim(),
      amount: amount,
      categoryId: selectedCategory!.id,
      categoryName: selectedCategory!.name,
      date: date,
      notes: notes.trim().isEmpty ? null : notes.trim(),
      receiptImageUrl: existing?.receiptImageUrl,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    _saving = true;
    _errorMessage = null;
    notifyListeners();

    final success = isEditing
        ? await _expenseProvider.updateExpense(expense)
        : await _expenseProvider.addExpense(expense);

    if (!success) {
      _errorMessage = _expenseProvider.errorMessage ?? 'Failed to save expense';
    }
    _saving = false;
    notifyListeners();
    return success;
  }
}
