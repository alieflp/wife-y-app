/// Model untuk Category (Kategori)
/// Mewakili: Pendapatan, Pendidikan, Makan, Transport, dll
/// Mendukung hierarki dengan parentId (opsional)
/// Model ini PASIF - hanya data structure
class Category {
  final int? id;
  final String name;
  final int? parentId; // untuk kategori hierarki (opsional)

  Category({
    this.id,
    required this.name,
    this.parentId,
  });

  /// Convert dari database Map ke Object
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
    );
  }

  /// Convert dari Object ke Map untuk save ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
    };
  }
}
