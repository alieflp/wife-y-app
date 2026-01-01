import 'package:flutter/foundation.dart';
import '../models/category_model.dart' as model;
import '../repositories/category_repository.dart';

/// Provider untuk manage categories
/// State management: list categories, loading, error
class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repo = CategoryRepository();

  // State
  List<model.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<model.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all categories
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    _categories = []; // Clear dulu untuk mencegah data lama tersisa
    notifyListeners();

    try {
      _categories = await _repo.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create category baru
  Future<void> createCategory(String name, {int? parentId}) async {
    try {
      final category = model.Category(
        name: name,
        parentId: parentId,
      );
      
      final created = await _repo.create(category);
      _categories.add(created);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update category
  Future<void> updateCategory(model.Category category) async {
    try {
      await _repo.update(category);
      
      // Update di list
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(int id) async {
    try {
      await _repo.delete(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get category by id
  model.Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
