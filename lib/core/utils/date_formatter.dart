/// Pemformat tanggal seadanya.
///
/// Project ini belum memakai package `intl`, jadi nama hari dan bulan ditulis
/// manual. Begitu aplikasi perlu lebih dari satu bahasa, ganti kelas ini
/// dengan `DateFormat` dari `intl`.
class DateFormatter {
  DateFormatter._();

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Contoh: "Monday, 8 September 2026".
  static String fullDate(DateTime date) {
    final day = _days[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$day, ${date.day} $month ${date.year}';
  }
}
