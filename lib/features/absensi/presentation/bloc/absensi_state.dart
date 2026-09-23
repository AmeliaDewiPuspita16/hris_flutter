import '../../domain/attendance_entry.dart';
import '../../domain/attendance_summary.dart';

enum AbsensiStatus { initial, loading, success, failure }

/// Keadaan Log Absensi: bulan yang sedang dipilih beserta entri &
/// ringkasannya.
class AbsensiState {
  const AbsensiState({
    required this.selectedMonth,
    this.status = AbsensiStatus.initial,
    this.entries = const [],
    this.summary,
    this.errorMessage,
  });

  final AbsensiStatus status;
  final DateTime selectedMonth;
  final List<AttendanceEntry> entries;
  final AttendanceSummary? summary;
  final String? errorMessage;

  AbsensiState copyWith({
    AbsensiStatus? status,
    DateTime? selectedMonth,
    List<AttendanceEntry>? entries,
    AttendanceSummary? summary,
    String? errorMessage,
  }) {
    return AbsensiState(
      status: status ?? this.status,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      entries: entries ?? this.entries,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
    );
  }
}
