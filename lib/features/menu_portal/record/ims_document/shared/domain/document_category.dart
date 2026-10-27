/// Satu tab kategori dokumen IMS dari `GET /api/record/ims/documents/categories`.
class DocumentCategory {
  const DocumentCategory({required this.key, required this.label, this.count});

  /// Nilai untuk query `?category=`, mis. "manual".
  final String key;

  /// Nama tampilan, mis. "Manual".
  final String label;

  /// Jumlah dokumen di kategori ini; null kalau server tidak mengirimnya.
  final int? count;
}
