import 'package:flutter/foundation.dart';
import '../models/detail_model.dart';
import '../repositories/detail_repository.dart';

/// Provider untuk manage details
/// State management: list details, loading, error
class DetailProvider extends ChangeNotifier {
  final DetailRepository _repo = DetailRepository();

  // State
  List<Detail> _details = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Detail> get details => _details;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all details
  Future<void> loadDetails() async {
    _isLoading = true;
    _error = null;
    _details = []; // Clear dulu untuk mencegah data lama tersisa
    notifyListeners();

    try {
      _details = await _repo.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load details by category
  Future<void> loadDetailsByCategory(int categoryId) async {
    _isLoading = true;
    _error = null;
    _details = []; // Clear dulu
    notifyListeners();

    try {
      _details = await _repo.getByCategory(categoryId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create detail baru dengan categoryId
  Future<void> createDetail(String name, int categoryId) async {
    try {
      final detail = Detail(name: name, categoryId: categoryId);
      final created = await _repo.create(detail);
      _details.add(created);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update detail
  Future<void> updateDetail(Detail detail) async {
    try {
      await _repo.update(detail);
      
      // Update di list
      final index = _details.indexWhere((d) => d.id == detail.id);
      if (index != -1) {
        _details[index] = detail;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete detail
  Future<void> deleteDetail(int id) async {
    try {
      await _repo.delete(id);
      _details.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
