import '../database/database_helper.dart';
import '../models/account_model.dart';

/// Repository untuk Account
/// Tanggung jawab: Data mapping antara database dan model
class AccountRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Create account
  Future<Account> create(Account account) async {
    final id = await _db.insertAccount(account.toMap());
    return Account(
      id: id,
      name: account.name,
      initialBalance: account.initialBalance,
    );
  }

  /// Get all accounts
  Future<List<Account>> getAll() async {
    final data = await _db.queryAllAccounts();
    return data.map((json) => Account.fromMap(json)).toList();
  }

  /// Get single account by id
  Future<Account?> getById(int id) async {
    final data = await _db.queryAccount(id);
    if (data != null) {
      return Account.fromMap(data);
    }
    return null;
  }

  /// Update account
  Future<int> update(Account account) async {
    if (account.id == null) {
      throw Exception('Account id cannot be null');
    }
    return await _db.updateAccount(account.id!, account.toMap());
  }

  /// Delete account
  Future<int> delete(int id) async {
    return await _db.deleteAccount(id);
  }
}
