import 'package:cloud_firestore/cloud_firestore.dart';

/// [received] = someone paid you back (increases what you have available).
/// [given] = you paid someone back (decreases what you have available) —
/// has the same effect on remaining budget as a small expense would.
enum PaybackType { received, given }

class PaybackModel {
  final String id;
  final String personName;
  final double amount;
  final PaybackType type;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  const PaybackModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.type,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory PaybackModel.fromMap(String id, Map<String, dynamic> map) {
    return PaybackModel(
      id: id,
      personName: map['personName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: (map['type'] as String?) == 'given' ? PaybackType.given : PaybackType.received,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PaybackModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PaybackModel.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'personName': personName,
      'amount': amount,
      'type': type == PaybackType.given ? 'given' : 'received',
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// The signed effect on available budget IF paybacks were the only
  /// thing tracking money movement. Kept for historical/ledger display
  /// (e.g. the +/- shown in PaybackListScreen) — NOT used for the actual
  /// budget calculation anymore, since a "given" payback now also creates
  /// a real ExpenseModel (see AddPaybackScreen), which already reduces
  /// budget via ExpenseProvider.thisMonthExpenses. Using both would
  /// double-count the same money leaving your pocket.
  double get signedAmount => type == PaybackType.received ? amount : -amount;

  /// What actually feeds into BudgetProvider.remainingWithPaybacks: only
  /// "received" affects it here, because "given" is already reflected via
  /// its linked expense instead. See the comment on [signedAmount] above.
  double get budgetImpact => type == PaybackType.received ? amount : 0;
}
