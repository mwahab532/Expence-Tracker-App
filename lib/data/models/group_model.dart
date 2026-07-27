import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory GroupModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupModel(
      id: id,
      name: map['name'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory GroupModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return GroupModel.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
