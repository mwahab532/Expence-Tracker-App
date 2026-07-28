class AppUserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  const AppUserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  factory AppUserModel.fromMap(String uid, Map<String, dynamic> map) {
    return AppUserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  AppUserModel copyWith({String? displayName, String? photoUrl}) {
    return AppUserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
