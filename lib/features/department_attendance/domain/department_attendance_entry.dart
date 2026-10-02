import 'department_attendance_status.dart';

/// Satu karyawan pada satu tanggal di Department Attendance Log.
class DepartmentAttendanceEntry {
  const DepartmentAttendanceEntry({
    required this.id,
    required this.name,
    required this.position,
    required this.status,
    this.shiftCode,
    this.shiftTimeRange,
    this.clockIn,
    this.lateMinutes,
    this.leaveLabel,
  });

  final String id;
  final String name;
  final String position;
  final DepartmentAttendanceStatus status;

  /// Kode shift terjadwal, mis. "A".
  final String? shiftCode;

  /// Rentang jam shift, mis. "07:00–16:00".
  final String? shiftTimeRange;

  /// Jam masuk hasil realisasi, mis. "06:55". Null kalau belum/tidak ada.
  final String? clockIn;

  /// Menit keterlambatan, hanya untuk status terlambat.
  final int? lateMinutes;

  /// Jenis cuti/izin, mis. "Annual leave". Hanya untuk status cuti.
  final String? leaveLabel;

  /// Dua huruf awal nama untuk avatar, mis. "Ari Putra" → "AP".
  String get initials {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final first = words.first[0];
    final second = words.length > 1 ? words[1][0] : '';
    return (first + second).toUpperCase();
  }

  /// Baris kedua di daftar: jabatan + shift (atau jenis cuti).
  String get subtitle {
    if (status == DepartmentAttendanceStatus.cuti) {
      return '$position · ${leaveLabel ?? 'Leave'}';
    }
    if (shiftCode != null && shiftTimeRange != null) {
      return '$position · $shiftCode $shiftTimeRange';
    }
    return position;
  }

  /// Teks badge di sisi kanan baris, mis. "Late 14m".
  String badgeText({required bool isToday}) => switch (status) {
        DepartmentAttendanceStatus.hadir => 'On time',
        DepartmentAttendanceStatus.terlambat =>
          lateMinutes == null ? 'Late' : 'Late ${lateMinutes}m',
        _ => status.label(isToday: isToday),
      };
}
