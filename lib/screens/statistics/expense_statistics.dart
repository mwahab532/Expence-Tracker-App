import '../../data/models/expense_model.dart';

/// Derived statistics computed from a list of expenses. This is pure Dart
/// with no Flutter dependency, so it can be unit tested directly and
/// reused anywhere (e.g. an export feature, a widget test, a future
/// backend job) without touching UI code.
class ExpenseStatistics {
  final Map<String, double> totalsByCategory;
  final ExpenseModel highest;
  final ExpenseModel lowest;
  final double averageDailySpending;
  final double monthlyTotal;

  const ExpenseStatistics({
    required this.totalsByCategory,
    required this.highest,
    required this.lowest,
    required this.averageDailySpending,
    required this.monthlyTotal,
  });

  /// Returns null when [expenses] is empty — there's no meaningful
  /// "highest"/"lowest"/etc. to compute, so the UI layer decides what to
  /// show for an empty state instead of this class faking a zero value.
  static ExpenseStatistics? fromExpenses(List<ExpenseModel> expenses, {DateTime? now}) {
    if (expenses.isEmpty) return null;
    final referenceNow = now ?? DateTime.now();

    final totalsByCategory = <String, double>{};
    for (final e in expenses) {
      totalsByCategory[e.categoryName] = (totalsByCategory[e.categoryName] ?? 0) + e.amount;
    }

    final highest = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
    final lowest = expenses.reduce((a, b) => a.amount < b.amount ? a : b);

    final distinctDays = expenses.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final averageDailySpending = distinctDays.isEmpty ? 0.0 : total / distinctDays.length;

    final monthlyTotal = expenses
        .where((e) => e.date.year == referenceNow.year && e.date.month == referenceNow.month)
        .fold(0.0, (sum, e) => sum + e.amount);

    return ExpenseStatistics(
      totalsByCategory: totalsByCategory,
      highest: highest,
      lowest: lowest,
      averageDailySpending: averageDailySpending,
      monthlyTotal: monthlyTotal,
    );
  }
}