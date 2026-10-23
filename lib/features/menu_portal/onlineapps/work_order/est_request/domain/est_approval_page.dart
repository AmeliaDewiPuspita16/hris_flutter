import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/utils/json_value.dart';
import 'est_approval_item.dart';

/// Hasil `GET /api/portal/apps/est_work_order/approvals`: satu halaman
/// antrean HOD beserta info paginasinya.
///
/// [pending] dari `summary.pending` — dihitung server atas SELURUH
/// antrean, bukan cuma halaman yang termuat — jadi itu yang dipakai untuk
/// badge tab, bukan `items.length`.
class EstApprovalPage {
  const EstApprovalPage({
    required this.items,
    required this.pending,
    required this.currentPage,
    required this.lastPage,
  });

  final List<EstApprovalItem> items;
  final int pending;

  /// Dari `meta`. Belum dipakai UI (belum ada infinite scroll), tapi sudah
  /// tersedia: masih ada halaman berikutnya kalau `currentPage < lastPage`.
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  factory EstApprovalPage.fromEnvelope(Map<String, dynamic> envelope) {
    final rows = envelope['data'] as List<dynamic>? ?? const [];

    final items = <EstApprovalItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(EstApprovalItem.fromJson(row));
      } on FormatException catch (e) {
        // Satu baris cacat dilewati saja, sisanya tetap tampil.
        AppLogger.info('Melewati approval EST yang tidak bisa dibaca: $e');
      }
    }

    final summary = envelope['summary'] is Map<String, dynamic>
        ? envelope['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final meta = envelope['meta'] is Map<String, dynamic>
        ? envelope['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return EstApprovalPage(
      items: items,
      pending: intOr(summary['pending'], items.length),
      currentPage: intOr(meta['current_page'], 1),
      lastPage: intOr(meta['last_page'], 1),
    );
  }
}
