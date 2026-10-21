import 'package:intl/intl.dart';

/// Pemformat tanggal.
///
/// Bagian pertama (`fullDate`, `shortDate`, dst) memakai daftar nama
/// hari/bulan manual peninggalan sebelum project pakai `intl`.
/// Bagian yang berakhiran `ID` (`shortDateID`, `monthYearID`, `shortDayID`,
/// `dateTimeID`) memakai `DateFormat` dari package `intl` dengan locale
/// `en_US` — pastikan `initializeDateFormatting('en_US')` sudah dipanggil di
/// `main()`. Akhiran `ID` adalah sisa nama dari saat locale-nya masih
/// Indonesia; namanya dipertahankan supaya pemanggil tidak ikut berubah.
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

  /// Contoh: "12 Oct 2026". Dipakai AppDateField & AppDateRangeField.
  static String shortDateID(DateTime date) {
    return DateFormat('d MMM yyyy', 'en_US').format(date);
  }

  /// Contoh: "October 2026". Dipakai untuk judul header kalender.
  static String monthYearID(DateTime date) {
    return DateFormat('MMMM yyyy', 'en_US').format(date);
  }

  /// Contoh: "Mon". Dipakai untuk label hari di header kalender.
  static String shortDayID(DateTime date) {
    return DateFormat('EEE', 'en_US').format(date);
  }

  /// Contoh: "16 Sep 2026, 10:30". Dipakai layar detail, di mana waktu pasti
  /// lebih berguna daripada waktu relatif seperti "2h ago".
  static String dateTimeID(DateTime date) {
    return DateFormat("d MMM yyyy, HH:mm", 'en_US').format(date);
  }

  /// Mengubah tanggal ISO dari API ("1991-11-21") menjadi format yang
  /// dipakai layar detail ("21-11-1991").
  ///
  /// Mengembalikan null bila [iso] kosong atau tidak bisa diurai, supaya
  /// pemanggil bisa jatuh ke nilai lain.
  static String? dayMonthYearFromIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;

    final date = DateTime.tryParse(iso);
    if (date == null) return null;

    // DateTime menormalkan tanggal mustahil — "0000-00-00" yang biasa dikirim
    // MySQL untuk tanggal kosong berubah jadi 30-11-0000, bukan gagal urai.
    // Round-trip memastikan hasilnya benar-benar tanggal yang dimaksud.
    if (DateFormat('yyyy-MM-dd').format(date) != iso.split('T').first) {
      return null;
    }

    return DateFormat('dd-MM-yyyy').format(date);
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
