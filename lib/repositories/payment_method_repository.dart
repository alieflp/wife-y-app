import '../database/database_helper.dart';
import '../models/payment_method_model.dart';

/// Repository untuk Payment Method
/// Tanggung jawab: Data mapping antara database dan model
class PaymentMethodRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Create payment method
  Future<PaymentMethod> create(PaymentMethod method) async {
    final id = await _db.insertPaymentMethod(method.toMap());
    return PaymentMethod(id: id, name: method.name);
  }

  /// Get all payment methods
  Future<List<PaymentMethod>> getAll() async {
    final data = await _db.queryAllPaymentMethods();
    return data.map((json) => PaymentMethod.fromMap(json)).toList();
  }

  /// Update payment method
  Future<int> update(PaymentMethod method) async {
    if (method.id == null) {
      throw Exception('Payment method id cannot be null');
    }
    return await _db.updatePaymentMethod(method.id!, method.toMap());
  }

  /// Delete payment method
  Future<int> delete(int id) async {
    return await _db.deletePaymentMethod(id);
  }
}
