/// Satu driver di dropdown Assign Vehicle (`GET /api/indent/admin/list_driver`).
///
/// `id` dikirim balik saat assign (`id_driver`), `name` yang ditampilkan.
/// Field `nik` dan `roles` dari server tidak dipakai di UI.
class IndentDriver {
  const IndentDriver({required this.id, required this.name});

  final int id;
  final String name;

  factory IndentDriver.fromJson(Map<String, dynamic> json) {
    return IndentDriver(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
