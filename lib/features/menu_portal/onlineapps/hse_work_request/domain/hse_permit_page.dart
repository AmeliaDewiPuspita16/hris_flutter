import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/page_meta.dart';
import 'hse_work_request.dart';

/// Satu halaman daftar permit (`GET /hse_permit` atau
/// `GET /hse_permit/approvals`) beserta paginasinya.
class HsePermitPage {
  const HsePermitPage({
    required this.items,
    required this.meta,
    this.summary = const {},
  });

  final List<HseWorkRequest> items;
  final PageMeta meta;

  /// Hanya dari antrean approval: jumlah antrean per stage, mis.
  /// `{"hod": 2, "hse": 1}`. Key-nya sekaligus stage yang dimiliki user.
  final Map<String, int> summary;

  int get summaryTotal => summary.values.fold(0, (sum, n) => sum + n);

  static const emptyMeta =
      PageMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0);

  factory HsePermitPage.fromEnvelope(Map<String, dynamic> envelope) {
    final rows = envelope['data'] is List ? envelope['data'] as List : const [];

    final items = <HseWorkRequest>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(HseWorkRequest.fromJson(row));
      } on FormatException catch (e) {
        // Satu baris cacat dilewati, sisanya tetap tampil.
        AppLogger.info('Melewati permit HSE yang tidak bisa dibaca: $e');
      }
    }

    final summary = envelope['summary'];

    return HsePermitPage(
      items: items,
      meta: envelope['meta'] is Map<String, dynamic>
          ? PageMeta.fromJson(envelope['meta'] as Map<String, dynamic>)
          : emptyMeta,
      summary: {
        if (summary is Map)
          for (final entry in summary.entries)
            if (entry.value is num)
              '${entry.key}': (entry.value as num).toInt(),
      },
    );
  }
}
