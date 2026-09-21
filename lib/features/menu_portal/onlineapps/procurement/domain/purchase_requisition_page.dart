import '../../../../../core/logging/app_logger.dart';
import 'json_value.dart';
import 'pr_status.dart';
import 'purchase_requisition_summary.dart';

/// Satu halaman hasil `GET /api/portal/apps/eprocurement`, lengkap dengan
/// ringkasan jumlah per status dan keterangan paginasinya.
///
/// Ketiganya dibungkus jadi satu karena memang datang bersamaan dalam satu
/// amplop — `summary` dan `meta` berdiri sejajar dengan `data`, bukan di
/// dalamnya.
class PurchaseRequisitionPage {
  const PurchaseRequisitionPage({
    required this.items,
    required this.summary,
    required this.meta,
  });

  final List<PurchaseRequisitionSummary> items;
  final PrStatusCounts summary;
  final PageMeta meta;

  factory PurchaseRequisitionPage.fromEnvelope(Map<String, dynamic> envelope) {
    final rows = envelope['data'] as List<dynamic>? ?? const [];

    final items = <PurchaseRequisitionSummary>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      try {
        items.add(PurchaseRequisitionSummary.fromJson(row));
      } on FormatException catch (e) {
        // Satu baris cacat di server tidak boleh membuat seluruh daftar PR
        // hilang dari layar — lewati saja, tapi catat.
        AppLogger.info('Melewati PR yang tidak bisa dibaca: $e');
      }
    }

    return PurchaseRequisitionPage(
      items: items,
      summary: PrStatusCounts.fromJson(
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

/// Jumlah PR per status, dari `summary`.
///
/// Angkanya menghitung seluruh PR yang cocok dengan pencarian — bukan hanya
/// yang termuat di halaman ini — jadi chip filter bisa menyebut jumlah yang
/// benar tanpa perlu memuat semua halaman.
class PrStatusCounts {
  const PrStatusCounts({required this.all, required this.byCode});

  final int all;
  final Map<String, int> byCode;

  factory PrStatusCounts.fromJson(Map<String, dynamic> json) {
    return PrStatusCounts(
      all: intOr(json['all'], 0),
      byCode: {
        for (final entry in json.entries)
          if (entry.key != 'all' && entry.value is int)
            entry.key: entry.value as int,
      },
    );
  }

  int countFor(String code) => byCode[code] ?? 0;

  /// Status yang benar-benar dilaporkan server, dalam urutan [PrStatusCode].
  ///
  /// Status bernilai nol tetap ikut supaya deret chip tidak berubah-ubah
  /// sewaktu orang mengetik di kolom cari; kode yang tidak dikenal aplikasi
  /// dilewati karena tidak punya label pendek untuk chip.
  List<PrStatusCode> get reportedCodes => PrStatusCode.values
      .where((code) => byCode.containsKey(code.code))
      .toList(growable: false);
}

/// Keterangan paginasi dari `meta`.
class PageMeta {
  const PageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  /// Amplop tanpa `meta` dianggap satu halaman penuh — lebih aman daripada
  /// terus meminta halaman berikutnya yang tidak ada.
  factory PageMeta.fromJson(Map<String, dynamic> json) {
    return PageMeta(
      currentPage: intOr(json['current_page'], 1),
      lastPage: intOr(json['last_page'], 1),
      perPage: intOr(json['per_page'], 20),
      total: intOr(json['total'], 0),
    );
  }
}
