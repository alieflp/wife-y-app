import 'package:flutter/foundation.dart';
import '../models/payment_method_model.dart';
import '../repositories/payment_method_repository.dart';

/// Provider untuk manage payment methods
/// State management: list payment methods, loading, error
class PaymentMethodProvider extends ChangeNotifier {
  final PaymentMethodRepository _repo = PaymentMethodRepository();

  // State
  List<PaymentMethod> _methods = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PaymentMethod> get methods => _methods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all payment methods
  Future<void> loadMethods() async {
    _isLoading = true;
    _error = null;
    _methods = []; // Clear dulu untuk mencegah data lama tersisa
    notifyListeners();

    try {
      _methods = await _repo.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create payment method baru
  Future<void> createMethod(String name) async {
    try {
      final method = PaymentMethod(name: name);
      final created = await _repo.create(method);
      _methods.add(created);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update payment method
  Future<void> updateMethod(PaymentMethod method) async {
    try {
      await _repo.update(method);
      
      // Update di list
      final index = _methods.indexWhere((m) => m.id == method.id);
      if (index != -1) {
        _methods[index] = method;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete payment method
  Future<void> deleteMethod(int id) async {
    try {
      await _repo.delete(id);
      _methods.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get method by id
  PaymentMethod? getMethodById(int id) {
    try {
      return _methods.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
}
