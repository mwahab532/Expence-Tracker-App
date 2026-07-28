import 'package:cloud_firestore/cloud_firestore.dart';

class GroupExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final String categoryName;
  final List<String> contributorUids;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  const GroupExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.contributorUids,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  /// Equal split — each contributor owes the same share. Guards against
  /// division by zero if somehow saved with no contributors.
  double get perPersonAmount => contributorUids.isEmpty ? 0 : amount / contributorUids.length;

  factory GroupExpenseModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupExpenseModel(
      id: id,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? 'Uncategorized',
      contributorUids: List<String>.from(map['contributorUids'] as List? ?? []),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory GroupExpenseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return GroupExpenseModel.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'contributorUids': contributorUids,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
