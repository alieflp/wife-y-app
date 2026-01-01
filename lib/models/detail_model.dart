/// Model untuk detail transaksi
/// Detail adalah sub-kategori yang terhubung dengan Kategori
/// Contoh: Kategori Pendapatan -> Detail: Gaji, Bonus
///         Kategori Pendidikan -> Detail: SPP Anak, Alat Tulis
class Detail {
  final int? id;
  final String name;
  final int categoryId; // Foreign key ke kategori

  Detail({
    this.id,
    required this.name,
    required this.categoryId,
  });

  /// Convert dari database Map ke Object
  factory Detail.fromMap(Map<String, dynamic> map) {
    return Detail(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int,
    );
  }

  /// Convert dari Object ke database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
    };
  }
}
