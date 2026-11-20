import '../../../../../core/network/page_meta.dart';
import 'meter_period.dart';
import 'meter_reading_summary.dart';

/// Satu halaman daftar Meter Reading: baris, jumlah untuk chip, paginasi,
/// periode aktif, dan hak tulis user.
///
/// Semuanya datang sejajar dalam satu amplop `GET /records`:
/// `data`, `summary`, `meta`, `active_period`, `can_write`
class MeterReadingPage {
  const MeterReadingPage({
    required this.items,
    required this.counts,
    required this.meta,
    this.activePeriod,
    this.canWrite = false,
  });

  final List<MeterReadingSummary> items;
  final MeterReadingCounts counts;
  final PageMeta meta;

  // Periode aktif saat ini. Null = tidak ada periode aktif (tidak ada yang
  /// bisa dicatat).
  final MeterPeriod? activePeriod;

  /// Hak tulis user. False = tampilan hanya-baca.
  final bool canWrite;
}

/// Jumlah meter per status pencatatan, untuk chip filter dan progress bar.
///
/// Dari `summary` server (`total`, `recorded`, `not_recorded`).
class MeterReadingCounts {
  const MeterReadingCounts({
    required this.all,
    required this.recorded,
    required this.pending,
  });

  final int all;
  final int recorded;
  final int pending;
}
