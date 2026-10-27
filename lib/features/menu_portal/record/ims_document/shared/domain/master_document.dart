/// Satu baris dokumen pada tab Manual/SOP/WI/Form/ANNEX/Form Template di
/// halaman Document File.
class MasterDocument {
  const MasterDocument({
    this.id,
    required this.docNo,
    required this.title,
    required this.hierarchy,
    this.viewUrl,
    this.isPdf = true,
    this.updatedAt,
  });

  /// Id dari server; null untuk data demo (Master Edited File).
  final int? id;

  final String docNo;
  final String title;

  /// Kode departemen pemilik dokumen, mis. "IMS", "HSE", "EST" — ditampilkan
  /// sebagai badge.
  final String hierarchy;

  /// Alamat PDF untuk dibaca di aplikasi (lihat `DocumentViewerScreen`).
  /// Null selama data masih demo; viewer lalu menampilkan PDF contoh.
  final String? viewUrl;

  /// False untuk Form Template (berkas Word/Excel) — server membalas 422
  /// kalau PDF-nya diminta, jadi dokumennya tidak bisa dibuka.
  final bool isPdf;

  /// Kapan revisi terkini diperbarui; null untuk data demo.
  final DateTime? updatedAt;
}
