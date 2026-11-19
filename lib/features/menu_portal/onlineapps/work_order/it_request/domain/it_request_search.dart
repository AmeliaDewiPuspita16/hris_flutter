import '../../../../../../core/utils/date_formatter.dart';
import 'it_request_item.dart';

/// Pencarian request IT/Media disisi klien.
extension ItRequestSearch on ItRequestItem {
  /// True bila request ini cocok dengan [query]
  ///
  /// Query dipecah per kata dan SETIAP kata harus ketemu (tanpa pedduli
  /// urutan & huruf besar/kecil), jaddi "laptop andi" menemukan request
  /// laptop milik Andi walau kata itu ada di kolom yang berbeda.
  ///
  /// Yang dicari adalah teks yang memang tampil di kartu - jenis, kategori,
  /// deskripsi, requester, department, status, dan tanggal - supaya apa yang
  /// user ketik selalu bisa ditemukan di layar. Tanggal memakai format yang
  /// sama dengan yang ditampilkan ([DateFormatter.shortDate])
  bool matchesSearch(String query) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    if (terms.isEmpty) return true;

    final haystack = [
      type.label,
      category.label,
      description,
      status.label,
      requester?.name ?? '',
      requester?.department ?? '',
      DateFormatter.shortDate(createdAt),
    ].join(' ').toLowerCase();

    return terms.every(haystack.contains);
  }
}
