import '../database/database_helper.dart';
import '../models/category_model.dart';

/// Repository untuk Category
/// Tanggung jawab: Data mapping antara database dan model
class CategoryRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Create category
  Future<Category> create(Category category) async {
    final id = await _db.insertCategory(category.toMap());
    return Category(
      id: id,
      name: category.name,
      parentId: category.parentId,
    );
  }

  /// Get all categories
  Future<List<Category>> getAll() async {
    final data = await _db.queryAllCategories();
    return data.map((json) => Category.fromMap(json)).toList();
  }

  /// Update category
  Future<int> update(Category category) async {
    if (category.id == null) {
      throw Exception('Category id cannot be null');
    }
    return await _db.updateCategory(category.id!, category.toMap());
  }

  /// Delete category
  Future<int> delete(int id) async {
    return await _db.deleteCategory(id);
  }
}
