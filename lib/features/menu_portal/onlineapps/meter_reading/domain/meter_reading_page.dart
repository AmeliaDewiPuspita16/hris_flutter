import '../../../../../core/network/page_meta.dart';
import 'meter_period.dart';
import 'meter_reading_summary.dart';

/// Satu halaman daftar Meter Reading: baris, jumlah untuk chip, paginasi,
/// periode aktif, dan hak tulis user.
///
/// Semuanya datang sejajar dalam satu amplop `GET /records`:
/// `data`, `summary`, `categories`, `meta`, `active_period`, `can_write`
class MeterReadingPage {
  const MeterReadingPage({
    required this.items,
    required this.counts,
    required this.meta,
    this.categories = const [],
    this.activePeriod,
    this.canWrite = false,
  });

  final List<MeterReadingSummary> items;
  final MeterReadingCounts counts;
  final PageMeta meta;

  /// Pilihan filter kategori dari server (`categories` di respons), ex:
  /// ["Amenity", "Dormitory"]. Kosong bila server tidak mengirimnya.
  final List<String> categories;

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
