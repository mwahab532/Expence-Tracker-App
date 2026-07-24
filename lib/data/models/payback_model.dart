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

  /// The signed effect on available budget: positive for received,
  /// negative for given.
  double get signedAmount => type == PaybackType.received ? amount : -amount;
}
