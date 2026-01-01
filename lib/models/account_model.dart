/// Model untuk Account (Modul)
/// Mewakili: Tabungan, Kas Besar, Kas Kecil
/// Model ini PASIF - hanya data structure
class Account {
  final int? id;
  final String name;
  final int initialBalance; // dalam Rupiah (int, bukan double)

  Account({
    this.id,
    required this.name,
    required this.initialBalance,
  });

  /// Convert dari database Map ke Object
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      initialBalance: map['initial_balance'] as int,
    );
  }

  /// Convert dari Object ke Map untuk save ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initial_balance': initialBalance,
    };
  }
}
