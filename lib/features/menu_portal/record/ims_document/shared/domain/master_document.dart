/// Satu baris dokumen pada tab Manual/SOP/WI/Form/ANNEX/Form Template di
/// halaman Document File.
class MasterDocument {
  const MasterDocument({
    this.id,
    required this.docNo,
    required this.title,
    required this.hierarchy,
    required this.downloadUrl,
    this.obsoleteUrl,
    this.viewUrl,
    this.isPdf = true,
  });

  /// Id dari server; null untuk data demo (Master Edited File).
  final int? id;

  final String docNo;
  final String title;

  /// Kode departemen pemilik dokumen, mis. "IMS", "HSE", "EST" — ditampilkan
  /// sebagai badge kolom "HIERARCHY DOC".
  final String hierarchy;

  final String downloadUrl;

  /// Null berarti dokumen ini tidak punya versi obsolete — tombol
  /// "Obsolete" tidak ditampilkan (lihat tab Manual di web, semua barisnya
  /// begini; tab lain seperti SOP punya keduanya).
  final String? obsoleteUrl;

  /// Alamat PDF untuk dibaca di aplikasi (lihat `DocumentViewerScreen`) —
  /// terpisah dari [downloadUrl] karena unduhan resmi tetap lewat website.
  /// Null selama data masih demo; viewer lalu menampilkan PDF contoh.
  final String? viewUrl;

  /// False untuk Form Template (berkas Word/Excel) — server membalas 422
  /// kalau PDF-nya diminta, jadi tombol "Lihat Dokumen" disembunyikan.
  final bool isPdf;
}
