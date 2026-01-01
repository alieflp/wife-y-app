import '../database/database_helper.dart';
import '../models/transaction_model.dart';

/// Repository untuk Transaction
/// Tanggung jawab: Data mapping antara database dan model
class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Create transaction (tanpa business logic)
  Future<Transaction> create(Transaction transaction) async {
    final id = await _db.insertTransaction(transaction.toMap());
    return Transaction(
      id: id,
      accountId: transaction.accountId,
      categoryId: transaction.categoryId,
      paymentMethodId: transaction.paymentMethodId,
      date: transaction.date,
      amount: transaction.amount,
      direction: transaction.direction,
      note: transaction.note,
    );
  }

  /// Get transactions by account
  Future<List<Transaction>> getByAccount(int accountId) async {
    final data = await _db.queryTransactionsByAccount(accountId);
    return data.map((json) => Transaction.fromMap(json)).toList();
  }

  /// Get transactions by account and month
  Future<List<Transaction>> getByMonth(
    int accountId,
    int month,
    int year,
  ) async {
    final data = await _db.queryTransactionsByMonth(accountId, month, year);
    return data.map((json) => Transaction.fromMap(json)).toList();
  }

  /// Update transaction
  Future<int> update(Transaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Transaction id cannot be null');
    }
    return await _db.updateTransaction(transaction.id!, transaction.toMap());
  }

  /// Delete transaction
  Future<int> delete(int id) async {
    return await _db.deleteTransaction(id);
  }
}
