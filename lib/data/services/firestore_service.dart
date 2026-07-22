import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Thin wrapper exposing the exact Firestore paths/queries the app needs.
/// Repositories call this; nothing above the repository layer imports
/// cloud_firestore directly.
class FirestoreService {
  final FirebaseFirestore _db;
  FirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> expensesRef(String uid) =>
      _db.collection(FirestoreCollections.users).doc(uid).collection(FirestoreCollections.expenses);

  CollectionReference<Map<String, dynamic>> categoriesRef(String uid) =>
      _db.collection(FirestoreCollections.users).doc(uid).collection(FirestoreCollections.categories);

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection(FirestoreCollections.users).doc(uid);

      

  /// Enables offline persistence (bonus feature: works without connectivity,
  /// syncs automatically when back online).
  void enableOfflinePersistence() {
    try {
      _db.settings = const Settings(persistenceEnabled: true);
    } catch (e) {
      // Already configured (e.g. from a previous hot reload) — safe to ignore.
      // ignore: avoid_print
      print('Firestore settings already applied, skipping: $e');
    }
  }
}
