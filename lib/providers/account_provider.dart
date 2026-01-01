import 'package:flutter/foundation.dart';
import '../models/account_model.dart';
import '../repositories/account_repository.dart';
import '../services/balance_service.dart';

/// Provider untuk manage accounts dan saldo
/// State management: list accounts, loading, error
class AccountProvider extends ChangeNotifier {
  final AccountRepository _repo = AccountRepository();
  final BalanceService _balanceService = BalanceService();

  // State
  List<Account> _accounts = [];
  bool _isLoading = false;
  String? _error;
  final Map<int, int> _balances = {}; // accountId -> current balance

  // Getters
  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Get balance untuk account tertentu
  int getBalance(int accountId) => _balances[accountId] ?? 0;

  /// Load all accounts
  Future<void> loadAccounts() async {
    _isLoading = true;
    _error = null;
    _accounts = []; // Clear dulu untuk mencegah data lama tersisa
    _balances.clear();
    notifyListeners();

    try {
      // 1. Load accounts dari repository
      _accounts = await _repo.getAll();
      
      // 2. Load balances - LOGIC DI SERVICE!
      final accountIds = _accounts
          .where((a) => a.id != null)
          .map((a) => a.id!)
          .toList();
      
      final balances = await _balanceService.getBalancesForAccounts(accountIds);
      _balances.addAll(balances);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create account baru
  Future<void> createAccount(String name, int initialBalance) async {
    try {
      final account = Account(
        name: name,
        initialBalance: initialBalance,
      );
      
      final created = await _repo.create(account);
      _accounts.add(created);
      
      // Set balance
      if (created.id != null) {
        _balances[created.id!] = initialBalance;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update account
  Future<void> updateAccount(Account account) async {
    try {
      await _repo.update(account);
      
      // Update di list
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount(int id) async {
    try {
      await _repo.delete(id);
      _accounts.removeWhere((a) => a.id == id);
      _balances.remove(id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh balance untuk account tertentu
  Future<void> refreshBalance(int accountId) async {
    try {
      // Service handle logic, provider hanya simpan hasil
      final balance = await _balanceService.getCurrentBalance(accountId);
      _balances[accountId] = balance;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh semua balances
  Future<void> refreshAllBalances() async {
    try {
      final accountIds = _accounts
          .where((a) => a.id != null)
          .map((a) => a.id!)
          .toList();
      
      // Service handle bulk refresh
      final balances = await _balanceService.getBalancesForAccounts(accountIds);
      _balances.addAll(balances);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
