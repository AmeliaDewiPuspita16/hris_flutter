import '../../../../../core/network/page_meta.dart';
import 'meter_reading_summary.dart';

/// Satu halaman daftar Meter Reading, lengkap dengan jumlah per status
/// pencatatan dan keterangan paginasinya.
///
/// Pola sama dengan `PurchaseRequisitionPage`: `counts` dan `meta` datang
/// sejajar dengan daftarnya dalam satu amplop.
class MeterReadingPage {
  const MeterReadingPage({
    required this.items,
    required this.counts,
    required this.meta,
  });

  final List<MeterReadingSummary> items;
  final MeterReadingCounts counts;
  final PageMeta meta;
}

/// Jumlah meter per status pencatatan, untuk chip filter.
///
/// Menghitung SELURUH data yang cocok dengan kategori dan pencarian aktif —
/// bukan hanya halaman yang termuat — dan tidak terpengaruh filter status
/// itu sendiri, supaya angka di chip tidak ikut berubah saat dipilih.
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
