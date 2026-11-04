import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/page_meta.dart';
import '../../../../../core/utils/json_value.dart';
import 'stationery_request_item.dart';

/// Satu halaman hasil `GET .../inventory/stationery/requests` (atau
/// `.../verifications`), bentuknya sama dengan `EstRequestPage`:
///
/// ```json
/// { "data": [...], "summary": {"pending": 27},
///   "meta": {"current_page": 1, "last_page": 3, "per_page": 10, "total": 27} }
/// ```
class StationeryRequestPage {
  const StationeryRequestPage({
    required this.items,
    required this.pending,
    required this.meta,
  });

  final List<StationeryRequestItem> items;

  /// `summary.pending`: jumlah request yang menunggu verifikasi (dihitung
  /// server atas seluruh data, bukan hanya halaman ini). Dipakai badge tab.
  final int pending;

  final PageMeta meta;

  factory StationeryRequestPage.fromEnvelope(Map<String, dynamic> envelope) {
    final rows = envelope['data'] as List<dynamic>? ?? const [];

    final items = <StationeryRequestItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(StationeryRequestItem.fromJson(row));
      } on FormatException catch (e) {
        // Satu baris cacat dilewati saja, sisanya tetap tampil.
        AppLogger.info('Melewati request stationery yang tidak terbaca: $e');
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

    return StationeryRequestPage(
      items: items,
      pending: intOr(summary['pending'], items.length),
      meta: meta,
    );
  }
}
