import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../pengajuan/domain/leave_type.dart';

/// Warna teks status "terlambat". Sengaja lebih gelap dari [AppColors.orange]
/// supaya terbaca di atas [AppColors.orangeBg].
const _lateText = Color(0xFFB45309);

/// Status seorang karyawan pada satu tanggal di Department Attendance Log.
///
/// Urutan nilai enum = urutan tampil di daftar: yang butuh perhatian HOD
/// (belum check-in, terlambat) naik ke atas, yang normal di bawah.
enum DepartmentAttendanceStatus { belumCheckIn, terlambat, hadir, cuti }

extension DepartmentAttendanceStatusX on DepartmentAttendanceStatus {
  /// Label untuk kartu penghitung dan badge. Di hari yang sudah lewat, orang
  /// yang tidak punya jam masuk bukan lagi "belum check-in" — dia tidak hadir.
  String label({required bool isToday}) => switch (this) {
        DepartmentAttendanceStatus.belumCheckIn =>
          isToday ? 'No check-in' : 'Absent',
        DepartmentAttendanceStatus.terlambat => 'Late',
        DepartmentAttendanceStatus.hadir => 'Present',
        DepartmentAttendanceStatus.cuti => 'Leave',
      };

  Color get color => switch (this) {
        DepartmentAttendanceStatus.belumCheckIn => AppColors.rejected,
        DepartmentAttendanceStatus.terlambat => _lateText,
        DepartmentAttendanceStatus.hadir => AppColors.present,
        // Biru yang sama dengan jenis Annual Leave di modul cuti.
        DepartmentAttendanceStatus.cuti => LeaveType.cutiTahunan.color,
      };

  Color get background => switch (this) {
        DepartmentAttendanceStatus.belumCheckIn => AppColors.rejectedBg,
        DepartmentAttendanceStatus.terlambat => AppColors.orangeBg,
        DepartmentAttendanceStatus.hadir => AppColors.presentBg,
        DepartmentAttendanceStatus.cuti => LeaveType.cutiTahunan.background,
      };

  /// Warna titik kecil di kartu penghitung.
  Color get dotColor => switch (this) {
        DepartmentAttendanceStatus.terlambat => AppColors.orange,
        _ => color,
      };
}
