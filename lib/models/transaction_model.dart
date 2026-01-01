/// Model untuk transaksi
/// Setiap transaksi terikat pada satu account (modul)
/// Model ini PASIF - hanya data structure
class Transaction {
  final int? id;
  final int accountId;
  final int categoryId;
  final int paymentMethodId;
  final int? detailId; // Optional detail
  final DateTime date;
  final int amount; // dalam Rupiah (int, bukan double)
  final String direction; // 'debit' atau 'kredit'
  final String? note;

  Transaction({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.paymentMethodId,
    this.detailId,
    required this.date,
    required this.amount,
    required this.direction,
    this.note,
  });

  /// Convert dari database Map ke Object
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      categoryId: map['category_id'] as int,
      paymentMethodId: map['payment_method_id'] as int,
      detailId: map['detail_id'] as int?,
      date: DateTime.parse(map['date'] as String),
      amount: map['amount'] as int,
      direction: map['direction'] as String,
      note: map['note'] as String?,
    );
  }

  /// Convert dari Object ke Map untuk save ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'payment_method_id': paymentMethodId,
      'detail_id': detailId,
      'date': date.toIso8601String(),
      'amount': amount,
      'direction': direction,
      'note': note,
    };
  }
}
