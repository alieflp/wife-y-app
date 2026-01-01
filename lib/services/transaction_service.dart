import '../repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import 'balance_service.dart';

/// Service untuk Transaction Business Logic
/// Tanggung jawab: Orchestrate transaction operations dengan balance updates
class TransactionService {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final BalanceService _balanceService = BalanceService();

  /// Create transaction dan auto-update monthly balance
  /// Ini adalah orchestration - koordinasi antar services
  Future<Transaction> createTransaction(Transaction transaction) async {
    // 1. Simpan transaksi
    final savedTransaction = await _transactionRepo.create(transaction);
    
    // 2. Auto-update monthly balance
    await _balanceService.updateMonthlyBalance(
      transaction.accountId,
      transaction.date.month,
      transaction.date.year,
    );

    return savedTransaction;
  }

  /// Get transactions by account
  Future<List<Transaction>> getTransactionsByAccount(int accountId) async {
    return await _transactionRepo.getByAccount(accountId);
  }

  /// Get transactions by month
  Future<List<Transaction>> getTransactionsByMonth(
    int accountId,
    int month,
    int year,
  ) async {
    return await _transactionRepo.getByMonth(accountId, month, year);
  }

  /// Update transaction dan re-calculate balance
  Future<void> updateTransaction(Transaction transaction) async {
    // 1. Update transaksi
    await _transactionRepo.update(transaction);
    
    // 2. Update monthly balance untuk bulan transaksi
    await _balanceService.updateMonthlyBalance(
      transaction.accountId,
      transaction.date.month,
      transaction.date.year,
    );
  }

  /// Delete transaction dan re-calculate balance
  Future<void> deleteTransaction(Transaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Transaction id cannot be null');
    }

    // 1. Delete transaksi
    await _transactionRepo.delete(transaction.id!);
    
    // 2. Update monthly balance untuk bulan transaksi
    await _balanceService.updateMonthlyBalance(
      transaction.accountId,
      transaction.date.month,
      transaction.date.year,
    );
  }
}
