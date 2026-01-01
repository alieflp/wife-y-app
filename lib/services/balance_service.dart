import '../repositories/balance_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/monthly_balance_model.dart';

/// Service untuk Balance Business Logic
/// Tanggung jawab: Hitung saldo, update monthly_balance
class BalanceService {
  final BalanceRepository _balanceRepo = BalanceRepository();
  final AccountRepository _accountRepo = AccountRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  /// Calculate closing balance
  /// Rumus: opening + debit - credit = closing
  int calculateClosingBalance(int opening, int debit, int credit) {
    return opening + debit - credit;
  }

  /// Update monthly balance untuk account dan bulan tertentu
  /// Ini adalah CORE business logic dari sistem kas
  Future<void> updateMonthlyBalance(
    int accountId,
    int month,
    int year,
  ) async {
    // 1. Hitung opening balance dari bulan sebelumnya
    final openingBalance = await _getOpeningBalance(accountId, month, year);

    // 2. Hitung total debit dan kredit dari transaksi bulan ini
    final transactions = await _transactionRepo.getByMonth(accountId, month, year);
    
    int totalDebit = 0;
    int totalCredit = 0;
    
    for (var trans in transactions) {
      if (trans.direction == 'debit') {
        totalDebit = totalDebit + trans.amount;
      } else if (trans.direction == 'kredit') {
        totalCredit = totalCredit + trans.amount;
      }
    }

    // 3. Hitung closing balance dengan rumus
    final closingBalance = calculateClosingBalance(
      openingBalance,
      totalDebit,
      totalCredit,
    );

    // 4. Insert or update monthly_balance
    final existingBalance = await _balanceRepo.get(accountId, month, year);
    
    final data = {
      'account_id': accountId,
      'month': month,
      'year': year,
      'opening_balance': openingBalance,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'closing_balance': closingBalance,
    };

    if (existingBalance == null) {
      // Insert new
      await _balanceRepo.create(MonthlyBalance(
        accountId: accountId,
        month: month,
        year: year,
        openingBalance: openingBalance,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        closingBalance: closingBalance,
      ));
    } else {
      // Update existing
      await _balanceRepo.update(accountId, month, year, data);
    }

    // 5. Cascade update bulan berikutnya - hanya jika ada transaksi
    await _cascadeUpdateNextMonth(accountId, month, year);
  }

  /// Get opening balance dari bulan sebelumnya
  Future<int> _getOpeningBalance(int accountId, int month, int year) async {
    if (month == 1) {
      // Januari: ambil dari initial_balance account
      final account = await _accountRepo.getById(accountId);
      return account?.initialBalance ?? 0;
    } else {
      // Bulan lain: ambil dari closing_balance bulan sebelumnya
      final prevMonth = month - 1;
      final prevBalance = await _balanceRepo.get(accountId, prevMonth, year);
      return prevBalance?.closingBalance ?? 0;
    }
  }

  /// Cascade update bulan berikutnya - hanya jika ada transaksi
  Future<void> _cascadeUpdateNextMonth(
    int accountId,
    int month,
    int year,
  ) async {
    if (month < 12) {
      final nextMonth = month + 1;
      
      // Cek apakah bulan berikutnya punya transaksi
      final nextTransactions = await _transactionRepo.getByMonth(
        accountId,
        nextMonth,
        year,
      );
      
      // Hanya update jika ada transaksi di bulan berikutnya
      if (nextTransactions.isNotEmpty) {
        await updateMonthlyBalance(accountId, nextMonth, year);
      }
    }
  }

  /// Get current balance untuk account
  Future<int> getCurrentBalance(int accountId) async {
    final now = DateTime.now();
    final balance = await _balanceRepo.get(accountId, now.month, now.year);
    
    if (balance != null) {
      return balance.closingBalance;
    }
    
    // Jika belum ada transaksi bulan ini, ambil dari account initial_balance
    final account = await _accountRepo.getById(accountId);
    return account?.initialBalance ?? 0;
  }

  /// Get balances untuk multiple accounts sekaligus
  /// Untuk load balances di provider tanpa loop manual
  Future<Map<int, int>> getBalancesForAccounts(List<int> accountIds) async {
    final balances = <int, int>{};
    
    for (var accountId in accountIds) {
      balances[accountId] = await getCurrentBalance(accountId);
    }
    
    return balances;
  }

  /// Get balance untuk bulan tertentu
  Future<MonthlyBalance?> getMonthlyBalance(
    int accountId,
    int month,
    int year,
  ) async {
    return await _balanceRepo.get(accountId, month, year);
  }

  /// Get all monthly balances untuk account
  Future<List<MonthlyBalance>> getAllBalancesByAccount(int accountId) async {
    return await _balanceRepo.getByAccount(accountId);
  }
}
