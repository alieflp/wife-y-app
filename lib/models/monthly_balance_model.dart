/// Model untuk saldo bulanan per account
/// Mewakili buku kas per bulan
/// Model ini PASIF - hanya data structure, tidak ada business logic
class MonthlyBalance {
  final int? id;
  final int accountId;
  final int month; // 1-12
  final int year;
  final int openingBalance; // dalam Rupiah (int, bukan double)
  final int totalDebit;
  final int totalCredit;
  final int closingBalance;

  MonthlyBalance({
    this.id,
    required this.accountId,
    required this.month,
    required this.year,
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
  });

  /// Convert dari database Map ke Object
  factory MonthlyBalance.fromMap(Map<String, dynamic> map) {
    return MonthlyBalance(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      month: map['month'] as int,
      year: map['year'] as int,
      openingBalance: map['opening_balance'] as int,
      totalDebit: map['total_debit'] as int,
      totalCredit: map['total_credit'] as int,
      closingBalance: map['closing_balance'] as int,
    );
  }

  /// Convert dari Object ke Map untuk save ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'month': month,
      'year': year,
      'opening_balance': openingBalance,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'closing_balance': closingBalance,
    };
  }
}
