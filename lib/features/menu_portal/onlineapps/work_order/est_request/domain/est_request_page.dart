import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/page_meta.dart';
import '../../../../../../core/utils/json_value.dart';
import 'est_request_item.dart';

/// Hasil `GET /api/portal/apps/est_work_order`: satu halaman daftar request
/// beserta info paginasinya.
///
/// ```json
/// { "data": [...], "summary": {"awaiting_verification": 1},
///   "meta": {"current_page": 1, "last_page": 56, "per_page": 20, "total": 1103} }
/// ```
class EstRequestPage {
  const EstRequestPage({
    required this.items,
    required this.awaitingVerification,
    required this.meta,
  });

  final List<EstRequestItem> items;

  /// Dari `summary.awaiting_verification`: jumlah request MILIK user yang
  /// sudah selesai dikerjakan tapi belum diverifikasi. Dihitung server atas
  /// seluruh data, bukan hanya halaman ini.
  final int awaitingVerification;

  final PageMeta meta;

  factory EstRequestPage.fromEnvelope(Map<String, dynamic> envelope) {
    final rows = envelope['data'] as List<dynamic>? ?? const [];

    final items = <EstRequestItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(EstRequestItem.fromJson(row));
      } on FormatException catch (e) {
        // Satu baris cacat dilewati saja, sisanya tetap tampil.
        AppLogger.info('Melewati request EST yang tidak bisa dibaca: $e');
      }
    }

    final summary = envelope['summary'] is Map<String, dynamic>
        ? envelope['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final meta = envelope['meta'] is Map<String, dynamic>
        ? PageMeta.fromJson(envelope['meta'] as Map<String, dynamic>)
        : const PageMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0);

    return EstRequestPage(
      items: items,
      awaitingVerification: intOr(summary['awaiting_verification'], 0),
      meta: meta,
    );
  }
}
