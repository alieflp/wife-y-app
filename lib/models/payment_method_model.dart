/// Model untuk Payment Method (Metode Pembayaran)
/// Mewakili: Tunai, Transfer Bank, E-wallet, dll
/// Model ini PASIF - hanya data structure
class PaymentMethod {
  final int? id;
  final String name;

  PaymentMethod({
    this.id,
    required this.name,
  });

  /// Convert dari database Map ke Object
  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  /// Convert dari Object ke Map untuk save ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
