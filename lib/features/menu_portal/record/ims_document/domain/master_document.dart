/// Satu baris dokumen pada tab Manual/SOP/WI/Form/ANNEX/Form Template di
/// halaman Document File.
class MasterDocument {
  const MasterDocument({
    required this.docNo,
    required this.title,
    required this.hierarchy,
    required this.downloadUrl,
    this.obsoleteUrl,
  });

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
}
