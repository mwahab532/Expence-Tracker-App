import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';



class CategoryRepositoryImpl implements CategoryRepository {
  final FirestoreService _firestoreService;
  CategoryRepositoryImpl({required this._firestoreService});

  @override
  Stream<List<CategoryModel>> watchCategories(String uid) {
    return _firestoreService
        .categoriesRef(uid)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(CategoryModel.fromDoc).toList());
  }

  @override
  Future<Result<void>> addCustomCategory(String uid, String name, String iconKey) async {
    if (name.trim().isEmpty) {
      return Result.failure(const ValidationFailure('Category name cannot be empty'));
    }
    try {
      final category = CategoryModel(
        id: '',
        name: name.trim(),
        isDefault: false,
        iconKey: iconKey,
        createdAt: DateTime.now(),
      );
      await _firestoreService.categoriesRef(uid).add(category.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to add category'));
    }
  }

  @override
  Future<Result<void>> renameCategory(String uid, String categoryId, String newName) async {
    if (newName.trim().isEmpty) {
      return Result.failure(const ValidationFailure('Category name cannot be empty'));
    }
    try {
      await _firestoreService.categoriesRef(uid).doc(categoryId).update({'name': newName.trim()});
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to rename category'));
    }
  }

  @override
  Future<Result<void>> deleteCategory(String uid, String categoryId) async {
    try {
      final doc = await _firestoreService.categoriesRef(uid).doc(categoryId).get();
      if (doc.data()?['isDefault'] == true) {
        return Result.failure(const ValidationFailure('Default categories cannot be deleted'));
      }
      await _firestoreService.categoriesRef(uid).doc(categoryId).delete();
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to delete category'));
    }
  }

  @override
  Future<void> seedDefaultCategories(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final name in DefaultCategories.names) {
      final ref = _firestoreService.categoriesRef(uid).doc();
      batch.set(ref, CategoryModel(
        id: ref.id,
        name: name,
        isDefault: true,
        iconKey: name.toLowerCase(),
        createdAt: DateTime.now(),
      ).toMap());
    }
    await batch.commit();
  }
}
