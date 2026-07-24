import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMemberModel {
  final String uid;
  final String displayName;
  final String email;
  final DateTime addedAt;

  const GroupMemberModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.addedAt,
  });

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory GroupMemberModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return GroupMemberModel.fromMap(doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
