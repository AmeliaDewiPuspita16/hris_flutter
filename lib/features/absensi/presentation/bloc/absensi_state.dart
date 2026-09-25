import '../../domain/attendance_day.dart';
import '../../domain/attendance_summary.dart';

enum AbsensiStatus { initial, loading, success, failure }

/// Keadaan Log Absensi: bulan yang sedang dipilih, seluruh tanggal di bulan
/// itu (jadwal + realisasi), tanggal yang sedang dilihat detailnya, dan
/// ringkasannya.
class AbsensiState {
  const AbsensiState({
    required this.selectedMonth,
    this.status = AbsensiStatus.initial,
    this.days = const [],
    this.summary,
    this.selectedDate,
    this.errorMessage,
  });

  final AbsensiStatus status;
  final DateTime selectedMonth;
  final List<AttendanceDay> days;
  final AttendanceSummary? summary;

  /// Tanggal yang sedang dipilih di kalender — detailnya ditampilkan di
  /// panel bawah. Null sebelum data pertama kali dimuat.
  final DateTime? selectedDate;

  final String? errorMessage;

  /// Data lengkap untuk [selectedDate], diambil dari [days]. Null bila
  /// belum ada tanggal terpilih.
  AttendanceDay? get selectedDay {
    final date = selectedDate;
    if (date == null) return null;
    for (final day in days) {
      if (day.isSameDay(date)) return day;
    }
    return null;
  }

  AbsensiState copyWith({
    AbsensiStatus? status,
    DateTime? selectedMonth,
    List<AttendanceDay>? days,
    AttendanceSummary? summary,
    DateTime? selectedDate,
    String? errorMessage,
  }) {
    return AbsensiState(
      status: status ?? this.status,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      days: days ?? this.days,
      summary: summary ?? this.summary,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage,
    );
  }
}
