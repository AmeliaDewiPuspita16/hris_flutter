import 'package:intl/intl.dart';

/// Pemformat tanggal.
///
/// Bagian Inggris (`fullDate`, `shortDate`, dst) masih pakai daftar
/// nama hari/bulan manual peninggalan sebelum project pakai `intl`.
/// Bagian ID (`shortDateID`, `monthYearID`, `shortDayID`) sudah pakai
/// `DateFormat` dari package `intl` dengan locale `id_ID` — pastikan
/// `initializeDateFormatting('id_ID')` sudah dipanggil di `main()`.
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

  /// Contoh: "Just now", "25m ago", "5h ago", "Yesterday", "3 days ago".
  ///
  /// [now] bisa diisi supaya hasilnya bisa diuji tanpa bergantung jam sistem.
  static String relative(DateTime time, {DateTime? now}) {
    final elapsed = (now ?? DateTime.now()).difference(time);

    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    if (elapsed.inDays == 1) return 'Yesterday';
    if (elapsed.inDays < 7) return '${elapsed.inDays} days ago';
    return shortDate(time);
  }

  /// Contoh: "8 Sep 2026".
  static String shortDate(DateTime date) {
    final month = _months[date.month - 1].substring(0, 3);
    return '${date.day} $month ${date.year}';
  }

  /// Contoh: "12 Okt 2026". Dipakai AppDateField & AppDateRangeField.
  static String shortDateID(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  /// Contoh: "Oktober 2026". Dipakai untuk judul header kalender.
  static String monthYearID(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  /// Contoh: "Sen". Dipakai untuk label hari di header kalender.
  static String shortDayID(DateTime date) {
    return DateFormat('EEE', 'id_ID').format(date);
  }

  /// Label pengelompokan daftar: "Today", "Yesterday", atau "Earlier".
  ///
  /// Dihitung per tanggal kalender, bukan selisih jam — notifikasi pukul
  /// 23.50 tidak boleh ikut masuk "Today" saat dilihat pukul 00.10 besoknya.
  static String dayGroup(DateTime time, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final thatDay = DateTime(time.year, time.month, time.day);
    final today = DateTime(reference.year, reference.month, reference.day);
    final days = today.difference(thatDay).inDays;

    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return 'Earlier';
  }
}