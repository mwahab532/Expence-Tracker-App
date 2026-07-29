import 'package:cloud_firestore/cloud_firestore.dart';

/// [equal] = amount is divided evenly among all contributorUids.
/// [custom] = each contributor owes exactly what's specified in
/// customAmounts, which must sum to the total amount.
enum SplitType { equal, custom }

class GroupExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final String categoryName;
  final List<String> contributorUids;
  final SplitType splitType;

  /// Only meaningful when [splitType] is custom — maps each contributor's
  /// uid to their exact share. Empty for equal-split expenses.
  final Map<String, double> customAmounts;

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
    this.splitType = SplitType.equal,
    this.customAmounts = const {},
    required this.date,
    this.notes,
    required this.createdAt,
  });

  /// What a specific contributor owes for this expense — branches on
  /// [splitType] so callers never need to know which mode an expense was
  /// saved in. Returns 0 for a uid that isn't actually a contributor.
  double amountOwedBy(String uid) {
    if (!contributorUids.contains(uid)) return 0;
    if (splitType == SplitType.custom) {
      return customAmounts[uid] ?? 0;
    }
    return contributorUids.isEmpty ? 0 : amount / contributorUids.length;
  }

  /// Equal-split convenience getter — kept for equal-split call sites
  /// that only need "the" per-person amount. Not meaningful for a custom
  /// split (where each person can owe a different amount); use
  /// [amountOwedBy] instead when [splitType] might be custom.
  double get perPersonAmount => contributorUids.isEmpty ? 0 : amount / contributorUids.length;

  factory GroupExpenseModel.fromMap(String id, Map<String, dynamic> map) {
    final rawCustom = map['customAmounts'] as Map<String, dynamic>? ?? {};
    return GroupExpenseModel(
      id: id,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? 'Uncategorized',
      contributorUids: List<String>.from(map['contributorUids'] as List? ?? []),
      splitType: (map['splitType'] as String?) == 'custom' ? SplitType.custom : SplitType.equal,
      customAmounts: rawCustom.map((k, v) => MapEntry(k, (v as num).toDouble())),
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
      'splitType': splitType == SplitType.custom ? 'custom' : 'equal',
      'customAmounts': customAmounts,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
