import 'observation_category.dart';

/// Tiga filter di tabel "All Observations" web: Month, Relevant Dept.,
/// Category. Null = "All ...". Dikirim ke server sebagai `month`, `id_dept`,
/// dan `category`; penyaringan dilakukan di server.
class ObservationFilter {
  const ObservationFilter({this.month, this.idDept, this.category});

  /// Hanya tahun & bulan yang dipakai (tanggal diabaikan).
  final DateTime? month;

  /// Id departemen tujuan (dari `/options`).
  final int? idDept;
  final ObservationCategory? category;

  static const none = ObservationFilter();

  bool get isActive => month != null || idDept != null || category != null;
}
