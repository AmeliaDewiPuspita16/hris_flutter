/// model Department

/// Satu departemen aktif — dipakai untuk mengisi dropdown, misalnya
/// Department pada form pengumuman.
///
/// Server hanya mengirim `id` dan `name` (lihat `GET /api/data/department`).
/// Kolom `company` sengaja tidak disertakan, jadi jangan diasumsikan akan
/// selalu ada kalau suatu saat muncul — anggap bentuk model ini yang jadi
/// kontraknya, bukan apa yang mungkin ikut terkirim.
class Department {
  const Department({required this.id, required this.name});

  final int id;
  final String name;

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => other is Department && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
