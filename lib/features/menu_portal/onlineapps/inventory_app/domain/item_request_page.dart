import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/page_meta.dart';
import '../../../../../core/utils/json_value.dart';
import 'item_request_entry.dart';

/// Jumlah request per status untuk SELURUH data (dihitung server), bukan hanya
/// halaman yang termuat. Nilai null = server tidak mengirimnya, jadi UI
/// menampilkan "–" alih-alih angka tebakan.
///
/// ```json
/// "summary": {"pending": 9, "approved": 15, "rejected": 3}
/// ```
class ItemRequestStatusCounts {
  const ItemRequestStatusCounts({this.pending, this.approved, this.rejected});

  final int? pending;
  final int? approved;
  final int? rejected;

  static const unknown = ItemRequestStatusCounts();

  factory ItemRequestStatusCounts.fromSummary(Map<String, dynamic> summary) {
    int? read(String key) {
      final v = summary[key];
      return v is num ? v.toInt() : null;
    }

    return ItemRequestStatusCounts(
      pending: read('pending'),
      approved: read('approved'),
      rejected: read('rejected'),
    );
  }
}

/// Satu halaman hasil `GET /item-request` (atau
/// `.../verifications`), bentuknya sama dengan `EstRequestPage`:
///
/// ```json
/// { "data": [...], "summary": {"pending": 27},
///   "meta": {"current_page": 1, "last_page": 3, "per_page": 10, "total": 27} }
/// ```
class ItemRequestPage {
  const ItemRequestPage({
    required this.items,
    required this.pending,
    required this.meta,
    this.counts = ItemRequestStatusCounts.unknown,
  });

  final List<ItemRequestEntry> items;

  /// Jumlah per status dari `summary` (seluruh data). Dipakai kotak ringkasan
  /// di atas daftar Request.
  final ItemRequestStatusCounts counts;

  /// `summary.pending`: jumlah request yang menunggu verifikasi (dihitung
  /// server atas seluruh data, bukan hanya halaman ini). Dipakai badge tab.
  final int pending;

  final PageMeta meta;

  factory ItemRequestPage.fromEnvelope(Map<String, dynamic> envelope) {
    final rows = envelope['data'] as List<dynamic>? ?? const [];

    final items = <ItemRequestEntry>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(ItemRequestEntry.fromJson(row));
      } on FormatException catch (e) {
        // Satu baris cacat dilewati saja, sisanya tetap tampil.
        AppLogger.info('Melewati item request yang tidak terbaca: $e');
      }
    }

    final summary = envelope['summary'] is Map<String, dynamic>
        ? envelope['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final meta = envelope['meta'] is Map<String, dynamic>
        ? PageMeta.fromJson(envelope['meta'] as Map<String, dynamic>)
        : PageMeta(
            currentPage: 1,
            lastPage: 1,
            perPage: items.length,
            total: items.length,
          );

    return ItemRequestPage(
      items: items,
      pending: intOr(summary['pending'], items.length),
      meta: meta,
      counts: ItemRequestStatusCounts.fromSummary(summary),
    );
  }
}
