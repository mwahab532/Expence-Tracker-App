import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String? notes;
  final String? receiptImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.notes,
    this.receiptImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromMap(String id, Map<String, dynamic> map) {
    return ExpenseModel(
      id: id,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? 'Uncategorized',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] as String?,
      receiptImageUrl: map['receiptImageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ExpenseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ExpenseModel.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'receiptImageUrl': receiptImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ExpenseModel copyWith({
    String? title,
    double? amount,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    String? notes,
    String? receiptImageUrl,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
