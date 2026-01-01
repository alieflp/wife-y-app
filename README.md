# 💰 Halo Flutter - Cash Management App

Aplikasi manajemen kas modular menggunakan Flutter dengan Clean Architecture.

## 📱 Fitur

- **Multi-Account Management**: Kelola multiple akun kas dengan saldo terpisah
- **Category & Detail Management**: Kategori dan detail transaksi yang bisa dikelola dengan relasi parent-child
- **Transaction Tracking**: Input transaksi Debit/Kredit dengan detail lengkap
- **Monthly Reports**: Laporan bulanan per akun
- **Inline Creation**: Tambah kategori dan detail langsung dari form transaksi (seperti Google Form)

## 🏗️ Arsitektur

Project ini dibangun menggunakan **Clean Architecture** dengan layer:

```
lib/
├── models/          # Data models (Account, Category, Detail, Transaction, etc)
├── database/        # Database helper & raw SQL operations
├── repositories/    # Data mapping layer
├── services/        # Business logic
├── providers/       # State management (Provider pattern)
└── screens/         # UI screens
```

## 🚀 Fase Implementasi

### ✅ FASE 1: Setup Dependencies & Database
- [x] Dependencies (sqflite, provider, intl, path_provider)
- [x] Struktur folder

### ✅ FASE 2: Models & Database
- [x] Account, Category, PaymentMethod, Transaction, MonthlyBalance models
- [x] Detail model dengan relasi ke Category
- [x] Database Helper dengan migration system (v1 → v2 → v3)
- [x] CRUD operations untuk semua tabel

### ✅ FASE 3: Business Logic
- [x] AccountProvider
- [x] CategoryProvider
- [x] PaymentMethodProvider
- [x] TransactionProvider
- [x] DetailProvider dengan filtering by category
- [x] Auto-update monthly balance pada transaksi

### ✅ FASE 4: User Interface
- [x] HomeScreen - Dashboard & pilih modul
- [x] AccountListScreen - CRUD accounts
- [x] CategoryListScreen - CRUD categories
- [x] DetailListScreen - CRUD details dengan filter kategori
- [x] TransactionListScreen - List transaksi per account
- [x] AddTransactionScreen - Form input dengan inline creation
- [x] ReportScreen - Laporan bulanan

## 🎯 Fitur Unggulan

### 1. Relasi Kategori-Detail
Detail berfungsi sebagai sub-kategori dari Kategori:
- **Kategori "Pendapatan"** → Detail: Gaji, Bonus, Investasi
- **Kategori "Pendidikan"** → Detail: SPP Anak, Alat Tulis, Seragam

Ketika memilih kategori di form transaksi, dropdown detail otomatis terfilter.

### 2. Inline Creation (Google Form Style)
Tidak perlu keluar ke halaman terpisah untuk menambah kategori/detail:
- Klik "Tambah ... Baru..." di dropdown
- Dialog popup muncul
- Input nama → klik "Tambah"
- Opsi baru langsung tersimpan dan terpilih

### 3. Database Migration
Automatic migration system:
- **v1**: Initial tables (accounts, categories, payment_methods, transactions, monthly_balance)
- **v2**: Tambah tabel details & kolom detail_id di transactions
- **v3**: Tambah kolom category_id di details untuk relasi parent-child

## 🛠️ Tech Stack

- **Flutter**: ^3.10.4
- **sqflite**: ^2.3.3 - Local database
- **provider**: ^6.1.2 - State management
- **intl**: ^0.19.0 - Internationalization & formatting
- **path_provider**: ^2.1.3 - Path utilities

## 📦 Instalasi

```bash
# Clone repository
git clone <repository-url>
cd halo_flutter

# Install dependencies
flutter pub get

# Run app
flutter run
```

## 💾 Database Schema

### Accounts
```sql
CREATE TABLE accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  initial_balance INTEGER NOT NULL
)
```

### Categories
```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  parent_id INTEGER
)
```

### Details (Sub-kategori)
```sql
CREATE TABLE details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category_id INTEGER NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id)
)
```

### Transactions
```sql
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  payment_method_id INTEGER NOT NULL,
  detail_id INTEGER,
  date TEXT NOT NULL,
  amount INTEGER NOT NULL,
  direction TEXT NOT NULL, -- 'debit' or 'kredit'
  note TEXT,
  FOREIGN KEY (account_id) REFERENCES accounts (id),
  FOREIGN KEY (category_id) REFERENCES categories (id),
  FOREIGN KEY (detail_id) REFERENCES details (id)
)
```

### Monthly Balance
```sql
CREATE TABLE monthly_balance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  opening_balance INTEGER NOT NULL,
  closing_balance INTEGER NOT NULL,
  total_debit INTEGER NOT NULL,
  total_kredit INTEGER NOT NULL,
  FOREIGN KEY (account_id) REFERENCES accounts (id)
)
```

## 👨‍💻 Author

**Alief**

## 📄 License

MIT License
