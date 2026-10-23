import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/utils/json_value.dart';
import 'approve_request_item.dart';

/// Hasil `GET /api/portal/apps/it_request/approvals`: antrean HOD beserta
/// jumlah totalnya.
///
/// [pending] diambil dari `summary.pending` — dihitung server atas SELURUH
/// antrean, bukan cuma halaman yang termuat — jadi itu yang dipakai untuk
/// badge tab, bukan `items.length`.
class ApproveRequestPage {
  const ApproveRequestPage({required this.items, required this.pending});

  final List<ApproveRequestItem> items;
  final int pending;

  factory ApproveRequestPage.fromEnvelope(Map<String, dynamic> envelope) {
    final rows = envelope['data'] as List<dynamic>? ?? const [];

    final items = <ApproveRequestItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(ApproveRequestItem.fromJson(row));
      } on FormatException catch (e) {
        // Pola sama dengan ItRequestPage: satu baris cacat dilewati saja.
        AppLogger.info(
            'Melewati approval IT Request yang tidak bisa dibaca: $e');
      }
    }

    final summary = envelope['summary'] is Map<String, dynamic>
        ? envelope['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ApproveRequestPage(
      items: items,
      pending: intOr(summary['pending'], items.length),
    );
  }
}
