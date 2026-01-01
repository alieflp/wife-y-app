import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

/// Provider untuk manage transactions
/// State management: list transactions, loading, error
/// AUTO-UPDATE balance saat add/edit/delete transaksi
class TransactionProvider extends ChangeNotifier {
  final TransactionService _service = TransactionService();

  // State
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  // Filter state
  int? _selectedAccountId;
  int? _selectedMonth;
  int? _selectedYear;

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedAccountId => _selectedAccountId;
  int? get selectedMonth => _selectedMonth;
  int? get selectedYear => _selectedYear;

  /// Load transactions by account
  Future<void> loadTransactionsByAccount(int accountId) async {
    _isLoading = true;
    _error = null;
    _transactions = []; // Clear dulu untuk mencegah data lama tersisa
    _selectedAccountId = accountId;
    _selectedMonth = null;
    _selectedYear = null;
    notifyListeners();

    try {
      _transactions = await _service.getTransactionsByAccount(accountId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load transactions by month
  Future<void> loadTransactionsByMonth(
    int accountId,
    int month,
    int year,
  ) async {
    _isLoading = true;
    _error = null;
    _transactions = []; // Clear dulu untuk mencegah data lama tersisa
    _selectedAccountId = accountId;
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();

    try {
      _transactions = await _service.getTransactionsByMonth(
        accountId,
        month,
        year,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add transaction baru (AUTO-UPDATE BALANCE!)
  Future<void> addTransaction(Transaction transaction) async {
    try {
      // Service akan auto-update balance
      final created = await _service.createTransaction(transaction);
      
      // Validasi: jika ada filter aktif, cek apakah transaksi match
      if (_selectedAccountId != null) {
        if (_isTransactionMatchFilter(created)) {
          _transactions.insert(0, created); // Add di awal (newest first)
        }
        // Jika tidak match filter, tidak perlu tambah ke list
        // User bisa refresh manual jika ingin lihat transaksi baru
      } else {
        // Tidak ada filter, langsung tambahkan
        _transactions.insert(0, created);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update transaction (AUTO-UPDATE BALANCE!)
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      // Service akan auto-recalculate balance
      await _service.updateTransaction(transaction);
      
      // Update di list
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        // Jika ada filter aktif, cek apakah transaksi masih match
        if (_selectedAccountId != null) {
          if (_isTransactionMatchFilter(transaction)) {
            // Masih match, update
            _transactions[index] = transaction;
          } else {
            // Tidak match lagi (misal tanggal diubah), remove dari list
            _transactions.removeAt(index);
          }
        } else {
          // Tidak ada filter, langsung update
          _transactions[index] = transaction;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete transaction (AUTO-UPDATE BALANCE!)
  Future<void> deleteTransaction(Transaction transaction) async {
    try {
      // Service akan auto-adjust balance
      await _service.deleteTransaction(transaction);
      _transactions.removeWhere((t) => t.id == transaction.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh current filter
  Future<void> refresh() async {
    if (_selectedAccountId != null) {
      if (_selectedMonth != null && _selectedYear != null) {
        await loadTransactionsByMonth(
          _selectedAccountId!,
          _selectedMonth!,
          _selectedYear!,
        );
      } else {
        await loadTransactionsByAccount(_selectedAccountId!);
      }
    }
  }

  /// Get total debit untuk list saat ini
  int get totalDebit {
    return _transactions
        .where((t) => t.direction == 'debit')
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Get total kredit untuk list saat ini
  int get totalCredit {
    return _transactions
        .where((t) => t.direction == 'kredit')
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Get net (debit - kredit)
  int get netAmount => totalDebit - totalCredit;

  /// Helper: check if transaction matches current filter
  bool _isTransactionMatchFilter(Transaction transaction) {
    // Jika tidak ada filter bulan, hanya cek accountId
    if (_selectedMonth == null || _selectedYear == null) {
      return transaction.accountId == _selectedAccountId;
    }
    
    // Jika ada filter bulan, cek accountId + bulan + tahun
    return transaction.accountId == _selectedAccountId &&
           transaction.date.month == _selectedMonth &&
           transaction.date.year == _selectedYear;
  }

  /// Clear filter
  void clearFilter() {
    _selectedAccountId = null;
    _selectedMonth = null;
    _selectedYear = null;
    _transactions = [];
    notifyListeners();
  }
}
