import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/page_meta.dart';
import 'it_request_item.dart';
import 'it_request_summary.dart';

/// Satu halaman hasil `GET /api/portal/apps/it_request`, lengkap dengan
/// ringkasan "menunggu rating" dan keterangan paginasinya.
///
/// Ketiganya dibungkus jadi satu karena memang datang bersamaan dalam satu
/// amplop — `summary` dan `meta` berdiri sejajar dengan `data`, bukan di
/// dalamnya. Pola sama dengan `PurchaseRequisitionPage` di EProcurement.
class ItRequestPage {
  const ItRequestPage({
    required this.items,
    required this.summary,
    required this.meta,
  });

  final List<ItRequestItem> items;
  final ItRequestSummary summary;
  final PageMeta meta;

  /// Baris "cangkang kosong": tanpa kategori DAN tanpa deskripsi. Request
  /// yang sah selalu punya keduanya (keduanya wajib di form Add Request),
  /// jadi baris seperti ini hanya sisa data rusak/tes di server yang ikut
  /// terkirim oleh API tapi sudah disaring di web. Aturannya sengaja sempit
  /// supaya request asli tidak ikut terbuang.
  static bool _isEmptyShell(Map<String, dynamic> row) =>
      row['category'] == null && '${row['description'] ?? ''}'.trim().isEmpty;

  factory ItRequestPage.fromEnvelope(Map<String, dynamic> envelope) {
    final rows = envelope['data'] as List<dynamic>? ?? const [];

    final items = <ItRequestItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      if (_isEmptyShell(row)) {
        AppLogger.info('Melewati IT Request kosong (id ${row['id']})');
        continue;
      }

      try {
        items.add(ItRequestItem.fromJson(row));
      } on FormatException catch (e) {
        // Satu baris cacat di server tidak boleh membuat seluruh riwayat
        // hilang dari layar — lewati saja, tapi catat.
        AppLogger.info('Melewati IT Request yang tidak bisa dibaca: $e');
      }
    }

    return ItRequestPage(
      items: items,
      summary: ItRequestSummary.fromJson(
        envelope['summary'] is Map<String, dynamic>
            ? envelope['summary'] as Map<String, dynamic>
            : const {},
      ),
      meta: PageMeta.fromJson(
        envelope['meta'] is Map<String, dynamic>
            ? envelope['meta'] as Map<String, dynamic>
            : const {},
      ),
    );
  }
}
