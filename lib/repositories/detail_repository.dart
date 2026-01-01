import '../database/database_helper.dart';
import '../models/detail_model.dart';

/// Repository untuk Detail
/// Layer mapping antara database dan model
class DetailRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Create detail baru
  Future<Detail> create(Detail detail) async {
    final id = await _db.insertDetail(detail.toMap());
    return Detail(id: id, name: detail.name, categoryId: detail.categoryId);
  }

  /// Get all details
  Future<List<Detail>> getAll() async {
    final results = await _db.queryAllDetails();
    return results.map((json) => Detail.fromMap(json)).toList();
  }

  /// Get details by category
  Future<List<Detail>> getByCategory(int categoryId) async {
    final results = await _db.queryDetailsByCategory(categoryId);
    return results.map((json) => Detail.fromMap(json)).toList();
  }

  /// Update detail
  Future<void> update(Detail detail) async {
    await _db.updateDetail(detail.id!, detail.toMap());
  }

  /// Delete detail
  Future<void> delete(int id) async {
    await _db.deleteDetail(id);
  }
}
