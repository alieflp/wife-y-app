import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database Helper untuk raw SQL operations only
/// Singleton pattern - hanya ada satu instance database
/// TIDAK ADA business logic di sini - hanya CRUD
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('halo_kas.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Update version untuk migration detail-category relation
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Upgrade database untuk versi baru
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tambah tabel details
      await db.execute('''
        CREATE TABLE details (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');

      // Update tabel transactions - tambah detail_id
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN detail_id INTEGER
      ''');

      // Insert default details
      await db.insert('details', {'name': 'Lainnya'});
    }
    
    if (oldVersion < 3) {
      // Tambah kolom category_id ke tabel details
      await db.execute('''
        ALTER TABLE details ADD COLUMN category_id INTEGER
      ''');
      
      // Update existing details untuk punya category_id default (kategori pertama)
      final categories = await db.query('categories', limit: 1);
      if (categories.isNotEmpty) {
        final firstCategoryId = categories.first['id'];
        await db.execute('''
          UPDATE details SET category_id = ? WHERE category_id IS NULL
        ''', [firstCategoryId]);
      }
    }
  }

  /// Configure database - enable foreign keys
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create tables
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const integerType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    // Table accounts
    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        name $textType,
        initial_balance $integerType
      )
    ''');

    // Table categories
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        parent_id INTEGER
      )
    ''');

    // Table payment_methods
    await db.execute('''
      CREATE TABLE payment_methods (
        id $idType,
        name $textType
      )
    ''');

    // Table details
    await db.execute('''
      CREATE TABLE details (
        id $idType,
        name $textType,
        category_id $integerType,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Table transactions
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        account_id $integerType,
        category_id $integerType,
        payment_method_id $integerType,
        detail_id INTEGER,
        date $textType,
        amount $integerType,
        direction $textType,
        note $textTypeNullable,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id),
        FOREIGN KEY (detail_id) REFERENCES details (id)
      )
    ''');

    // Table monthly_balance
    await db.execute('''
      CREATE TABLE monthly_balance (
        id $idType,
        account_id $integerType,
        month $integerType,
        year $integerType,
        opening_balance $integerType,
        total_debit $integerType,
        total_credit $integerType,
        closing_balance $integerType,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        UNIQUE(account_id, month, year)
      )
    ''');

    // Insert default data
    await _insertDefaultData(db);
  }

  /// Insert data default untuk testing
  Future _insertDefaultData(Database db) async {
    // Default accounts
    await db.insert('accounts', {'name': 'Kas Kecil', 'initial_balance': 0});
    await db.insert('accounts', {'name': 'Kas Besar', 'initial_balance': 0});
    await db.insert('accounts', {'name': 'Tabungan', 'initial_balance': 0});

    // Default categories
    // Default details
    await db.insert('details', {'name': 'Lainnya'});    await db.insert('categories', {'name': 'Pendapatan', 'parent_id': null});
    await db.insert('categories', {'name': 'Pendidikan', 'parent_id': null});
    await db.insert('categories', {'name': 'Makan & Minum', 'parent_id': null});
    await db.insert('categories', {'name': 'Transport', 'parent_id': null});
    await db.insert('categories', {'name': 'Belanja', 'parent_id': null});

    // Default payment methods
    await db.insert('payment_methods', {'name': 'Tunai'});
    await db.insert('payment_methods', {'name': 'Transfer Bank'});
    await db.insert('payment_methods', {'name': 'E-wallet'});
  }

  // ==================== CRUD ACCOUNTS ====================

  /// Insert account
  Future<int> insertAccount(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('accounts', data);
  }

  /// Query all accounts
  Future<List<Map<String, dynamic>>> queryAllAccounts() async {
    final db = await database;
    return await db.query('accounts', orderBy: 'name ASC');
  }

  /// Query single account
  Future<Map<String, dynamic>?> queryAccount(int id) async {
    final db = await database;
    final result = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Update account
  Future<int> updateAccount(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'accounts',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete account
  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CRUD CATEGORIES ====================

  /// Insert category
  Future<int> insertCategory(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('categories', data);
  }

  /// Query all categories
  Future<List<Map<String, dynamic>>> queryAllCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  /// Update category
  Future<int> updateCategory(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'categories',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete category
  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CRUD PAYMENT METHODS ====================

  /// Insert payment method
  Future<int> insertPaymentMethod(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('payment_methods', data);
  }

  /// Query all payment methods
  Future<List<Map<String, dynamic>>> queryAllPaymentMethods() async {
    final db = await database;
    return await db.query('payment_methods', orderBy: 'name ASC');
  }

  /// Update payment method
  Future<int> updatePaymentMethod(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'payment_methods',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete payment method
  Future<int> deletePaymentMethod(int id) async {
    final db = await database;
    return await db.delete(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CRUD DETAILS ====================

  /// Insert detail
  Future<int> insertDetail(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('details', data);
  }

  /// Query all details
  Future<List<Map<String, dynamic>>> queryAllDetails() async {
    final db = await database;
    return await db.query('details', orderBy: 'name ASC');
  }

  /// Query details by category
  Future<List<Map<String, dynamic>>> queryDetailsByCategory(int categoryId) async {
    final db = await database;
    return await db.query(
      'details',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
  }

  /// Update detail
  Future<int> updateDetail(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'details',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete detail
  Future<int> deleteDetail(int id) async {
    final db = await database;
    return await db.delete(
      'details',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CRUD TRANSACTIONS ====================

  /// Insert transaction
  Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('transactions', data);
  }

  /// Query transactions by account
  Future<List<Map<String, dynamic>>> queryTransactionsByAccount(
    int accountId,
  ) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
  }

  /// Query transactions by account and month
  Future<List<Map<String, dynamic>>> queryTransactionsByMonth(
    int accountId,
    int month,
    int year,
  ) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'account_id = ? AND strftime("%m", date) = ? AND strftime("%Y", date) = ?',
      whereArgs: [accountId, month.toString().padLeft(2, '0'), year.toString()],
      orderBy: 'date DESC',
    );
  }

  /// Update transaction
  Future<int> updateTransaction(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete transaction
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CRUD MONTHLY BALANCE ====================

  /// Insert monthly balance
  Future<int> insertMonthlyBalance(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('monthly_balance', data);
  }

  /// Query monthly balance
  Future<Map<String, dynamic>?> queryMonthlyBalance(
    int accountId,
    int month,
    int year,
  ) async {
    final db = await database;
    final result = await db.query(
      'monthly_balance',
      where: 'account_id = ? AND month = ? AND year = ?',
      whereArgs: [accountId, month, year],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Query all monthly balances by account
  Future<List<Map<String, dynamic>>> queryMonthlyBalancesByAccount(
    int accountId,
  ) async {
    final db = await database;
    return await db.query(
      'monthly_balance',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'year DESC, month DESC',
    );
  }

  /// Update monthly balance
  Future<int> updateMonthlyBalance(
    int accountId,
    int month,
    int year,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return await db.update(
      'monthly_balance',
      data,
      where: 'account_id = ? AND month = ? AND year = ?',
      whereArgs: [accountId, month, year],
    );
  }

  /// Delete monthly balance
  Future<int> deleteMonthlyBalance(int id) async {
    final db = await database;
    return await db.delete(
      'monthly_balance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== UTILITY ====================

  /// Close database
  Future close() async {
    final db = await database;
    db.close();
  }

  /// Delete database (untuk testing)
  Future deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'halo_kas.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
