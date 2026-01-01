import '../database/database_helper.dart';
import '../models/monthly_balance_model.dart';

/// Repository untuk Monthly Balance
/// Tanggung jawab: Data mapping antara database dan model
class BalanceRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Create monthly balance
  Future<int> create(MonthlyBalance balance) async {
    return await _db.insertMonthlyBalance(balance.toMap());
  }

  /// Get monthly balance
  Future<MonthlyBalance?> get(int accountId, int month, int year) async {
    final data = await _db.queryMonthlyBalance(accountId, month, year);
    if (data != null) {
      return MonthlyBalance.fromMap(data);
    }
    return null;
  }

  /// Get all monthly balances by account
  Future<List<MonthlyBalance>> getByAccount(int accountId) async {
    final data = await _db.queryMonthlyBalancesByAccount(accountId);
    return data.map((json) => MonthlyBalance.fromMap(json)).toList();
  }

  /// Update monthly balance
  Future<int> update(
    int accountId,
    int month,
    int year,
    Map<String, dynamic> data,
  ) async {
    return await _db.updateMonthlyBalance(accountId, month, year, data);
  }

  /// Delete monthly balance
  Future<int> delete(int id) async {
    return await _db.deleteMonthlyBalance(id);
  }
}
