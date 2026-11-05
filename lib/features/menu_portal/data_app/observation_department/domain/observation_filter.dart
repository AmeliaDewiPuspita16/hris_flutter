import 'observation_category.dart';
import 'observation_item.dart';

/// Tiga filter di tabel "All Observations" web: Month, Relevant Dept.,
/// Category. Null = "All ...".
class ObservationFilter {
  const ObservationFilter({this.month, this.relevantDept, this.category});

  /// Hanya tahun & bulan yang dipakai (tanggal diabaikan).
  final DateTime? month;
  final String? relevantDept;
  final ObservationCategory? category;

  static const none = ObservationFilter();

  bool get isActive =>
      month != null || relevantDept != null || category != null;

  bool matches(ObservationItem item) {
    if (month != null &&
        (item.createdDate.year != month!.year ||
            item.createdDate.month != month!.month)) {
      return false;
    }
    if (relevantDept != null && item.relevantDept != relevantDept) {
      return false;
    }
    if (category != null && item.category != category) return false;
    return true;
  }
}
