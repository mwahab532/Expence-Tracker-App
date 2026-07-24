import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/core/utils/safe_call.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import '../data/models/category_model.dart';


class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository;
  final String uid;

  CategoryProvider({required this._categoryRepository, required this.uid}) {
    _sub = _categoryRepository.watchCategories(uid).listen((data) {
      _categories = data;
      notifyListeners();
    });
  }
   void _subscribe() {
    _sub?.cancel();
    _sub = _categoryRepository.watchCategories(uid).listen((data) {
      _categories = data;
      notifyListeners();
    });
  }
  Future<void> refresh() async {
    _subscribe();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  StreamSubscription<List<CategoryModel>>? _sub;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> addCategory(String name, {String iconKey = 'category'}) async {
    final success = await safeCall(
      () async => (await _categoryRepository.addCustomCategory(uid, name, iconKey)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
    notifyListeners();
    return success;
  }

  Future<bool> renameCategory(String categoryId, String newName) async {
    final success = await safeCall(
      () async => (await _categoryRepository.renameCategory(uid, categoryId, newName)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
    notifyListeners();
    return success;
  }

  Future<bool> deleteCategory(String categoryId) async {
    final success = await safeCall(
      () async => (await _categoryRepository.deleteCategory(uid, categoryId)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
    notifyListeners();
    return success;
  }
  

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
