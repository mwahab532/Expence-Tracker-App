import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final bool isDefault;
  final String iconKey; // maps to an IconData lookup in the UI layer
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.iconKey,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      isDefault: map['isDefault'] as bool? ?? false,
      iconKey: map['iconKey'] as String? ?? 'category',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory CategoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return CategoryModel.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isDefault': isDefault,
      'iconKey': iconKey,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CategoryModel copyWith({String? name, String? iconKey}) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      isDefault: isDefault,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt,
    );
  }
}
