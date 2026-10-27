import '../../../../../../core/network/page_meta.dart';
import 'master_document.dart';

/// Satu halaman daftar dokumen untuk satu tab, beserta paginasinya.
class MasterDocumentPage {
  const MasterDocumentPage({required this.items, required this.meta});

  final List<MasterDocument> items;
  final PageMeta meta;

  /// Seluruh [documents] sebagai satu halaman, disaring lokal oleh [search]
  /// (nomor dokumen, judul, atau departemen) — untuk sumber yang datanya
  /// sudah termuat semua, mis. data demo Master Edited File.
  factory MasterDocumentPage.local(List<MasterDocument> documents, String search) {
    final keyword = search.trim().toLowerCase();
    final items = keyword.isEmpty
        ? documents
        : documents
            .where((doc) =>
                doc.docNo.toLowerCase().contains(keyword) ||
                doc.title.toLowerCase().contains(keyword) ||
                doc.hierarchy.toLowerCase().contains(keyword))
            .toList(growable: false);

    return MasterDocumentPage(
      items: items,
      meta: PageMeta(currentPage: 1, lastPage: 1, perPage: items.length, total: items.length),
    );
  }
}

/// Pengambil satu halaman dokumen sebuah tab. [search] kosong berarti tanpa
/// penyaringan.
typedef MasterDocumentFetcher = Future<MasterDocumentPage> Function({
  required int page,
  required String search,
});
